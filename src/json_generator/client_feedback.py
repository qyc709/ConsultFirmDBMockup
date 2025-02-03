import json
import random
from datetime import datetime, timedelta
from transformers import pipeline  # 使用 Hugging Face 的模型
from sqlalchemy.orm import sessionmaker
from models.db_model import Project, engine  # 假设 Project 是你的项目模型
import os

# 初始化 Hugging Face 的文本生成模型，使用更好的模型
text_generator = pipeline("text-generation", model="gpt2")


def generate_text_response(prompt):
    """
    使用 GPT-2 生成自然语言回答，确保内容在 20 到 80 字之间，并去掉标题
    """
    try:
        # 生成文本
        response = text_generator(prompt, max_length=70, temperature=0.7)
        generated_text = response[0]['generated_text'].strip()

        # 去掉标题（假设标题是 prompt 本身）
        generated_text = generated_text.replace(prompt, "").strip()

        # 确保文本长度在 20 到 80 字之间
        if len(generated_text) < 20:
            # 如果太短，重新生成
            response = text_generator(prompt, max_length=60, temperature=0.8)
            generated_text = response[0]['generated_text'].replace(prompt, "").strip()

        return generated_text
    except Exception as e:
        print(f"Error generating text response: {e}")
        return "No response generated."

def get_projects_from_database():
    """
    从数据库中提取项目信息，返回包含 projectID、clientID 和 ActualEndDate 的列表
    """
    Session = sessionmaker(bind=engine)
    session = Session()

    try:
        # 查询数据库中的项目信息
        projects = session.query(Project).all()

        # 提取需要的字段
        project_info = [
            {
                "projectID": project.ProjectID,
                "clientID": project.ClientID,
                "ActualEndDate": project.ActualEndDate.strftime("%Y-%m-%d") if project.ActualEndDate else None
            }
            for project in projects
        ]

        return project_info
    except Exception as e:
        print(f"Error fetching projects from database: {e}")
        return []
    finally:
        session.close()


def generate_feedback(project, feedback_count):
    """
    为单个项目生成 feedback_count 个反馈
    """
    feedbacks = []

    # 检查 ActualEndDate 是否为 None
    if project['ActualEndDate'] is None:
        print(f"Skipping project {project['projectID']} because ActualEndDate is None")
        return feedbacks

    for _ in range(feedback_count):
        # 生成 responseID
        responseID = str(random.randint(10000, 99999))

        # 计算 surveyDate
        actual_end_date = datetime.strptime(project['ActualEndDate'], "%Y-%m-%d")
        surveyDate = actual_end_date + timedelta(days=random.randint(7, 14))

        # 生成前两个问题的评分
        q1_value = random.randint(1, 5)
        q2_value = random.randint(1, 5)

        # 计算 overallSatisfaction，取 q1_value 和 q2_value 之间的随机值
        min_satisfaction = min(q1_value, q2_value)
        max_satisfaction = max(q1_value, q2_value)
        overallSatisfaction = round(random.uniform(min_satisfaction, max_satisfaction), 1)

        # 生成后两个问题的回答
        q3_prompt = "What did you like best about working with us?"
        q4_prompt = "What could we improve on?"

        q3_response = generate_text_response(q3_prompt)
        q4_response = generate_text_response(q4_prompt)

        # 构建反馈 JSON
        feedback = {
            "responseID": responseID,
            "projectID": project['projectID'],
            "clientID": project['clientID'],
            "surveyDate": surveyDate.strftime("%Y-%m-%d"),
            "responses": [
                {
                    "questionID": "Q1",
                    "questionText": "How satisfied are you with the project outcome?",
                    "responseType": "scale",
                    "responseValue": str(q1_value)
                },
                {
                    "questionID": "Q2",
                    "questionText": "Please rate the communication from our team.",
                    "responseType": "scale",
                    "responseValue": str(q2_value)
                },
                {
                    "questionID": "Q3",
                    "questionText": q3_prompt,
                    "responseType": "text",
                    "responseValue": q3_response
                },
                {
                    "questionID": "Q4",
                    "questionText": q4_prompt,
                    "responseType": "text",
                    "responseValue": q4_response
                }
            ],
            "overallSatisfaction": str(overallSatisfaction)
        }
        feedbacks.append(feedback)

    return feedbacks


def generate_client_feedback():
    """
    生成客户反馈 JSON 文件并保存到 example_output/json 目录
    """
    # 从数据库中获取项目信息
    projects = get_projects_from_database()

    # 生成所有项目的反馈
    all_feedbacks = []
    for project in projects:
        # 每个项目生成 2-3 个反馈
        feedback_count = random.randint(2, 3)
        all_feedbacks.extend(generate_feedback(project, feedback_count))

    # 保存到 JSON 文件
    output_dir = os.path.join(os.path.dirname(__file__), "../../example_output/json")
    os.makedirs(output_dir, exist_ok=True)
    output_file = os.path.join(output_dir, "client_feedbacks.json")

    with open(output_file, 'w') as f:
        json.dump(all_feedbacks, f, indent=4)

    print(f"客户反馈 JSON 文件已生成并保存到 {output_file}")


if __name__ == "__main__":
    generate_client_feedback()