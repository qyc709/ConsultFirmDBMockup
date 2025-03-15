import json
import random
from datetime import datetime, timedelta
from transformers import pipeline  # using Hugging Face model
import sqlite3
import os

# initialize Hugging Face model
text_generator = pipeline("text-generation", model="gpt2")


def generate_text_response(prompt):
    """
    Using GPT-2 to generate natural language response and ensure it is between 20-80 words
    """
    try:
        # generate resonse
        response = text_generator(prompt, max_length=70, temperature=0.7)
        generated_text = response[0]['generated_text'].strip()

        # delete title
        generated_text = generated_text.replace(prompt, "").strip()

        if len(generated_text) < 20:
            # regenerate if the response is too short
            response = text_generator(prompt, max_length=60, temperature=0.8)
            generated_text = response[0]['generated_text'].replace(prompt, "").strip()

        return generated_text
    except Exception as e:
        print(f"Error generating text response: {e}")
        return "No response generated."

def get_projects_from_database():
    """
    Fetch key name if it is related to the database, such as projectID, clientID, actual_end_date
    """
    current_dir = os.getcwd()
    db_path = f'{current_dir}/example_output/versions/database'

    db_file_path = f'{db_path}/consultingFirm_final.db'
    conn = sqlite3.connect(db_file_path)
    cursor = conn.cursor()
    cursor.execute("SELECT projectID, clientID, actual_end_date FROM project")

    projects = cursor.fetchall()

    project_info = []
    for project in projects:
        project_id, client_id, actual_end_date = project
        
        # Format the date if it exists
        formatted_date = None
        if actual_end_date:
            try:
                # Try parsing as ISO format string
                formatted_date = datetime.fromisoformat(actual_end_date).strftime("%Y-%m-%d")
                print(formatted_date)
            except (ValueError, TypeError):
                if isinstance(actual_end_date, (int, float)):
                    # Try parsing as timestamp
                    formatted_date = datetime.fromtimestamp(actual_end_date).strftime("%Y-%m-%d")
        
        project_info.append({
            "projectID": project_id,
            "clientID": client_id,
            "actual_end_date": formatted_date
        })

    # Close the connection
    conn.close()

    return project_info

def generate_feedback(project, feedback_count):
    """
    :param project: feedback for current project
    :param feedback_count: the number of feedback for a single project
    """
    feedbacks = []

    # check if ActualEndDate is None
    if project['actual_end_date'] is None:
        print(f"Skipping project {project['projectID']} because ActualEndDate is None")
        return feedbacks

    for _ in range(feedback_count):
        # generate responseID
        responseID = str(random.randint(10000, 99999))

        # calculate surveyDate
        actual_end_date = datetime.strptime(project['actual_end_date'], "%Y-%m-%d")
        surveyDate = actual_end_date + timedelta(days=random.randint(7, 14))

        # generate rate for q1 and q2
        q1_value = random.randint(1, 5)
        q2_value = random.randint(1, 5)

        # get the overallSatisfaction, a random number between q1 and q2
        min_satisfaction = min(q1_value, q2_value)
        max_satisfaction = max(q1_value, q2_value)
        overallSatisfaction = round(random.uniform(min_satisfaction, max_satisfaction), 1)

        # generate answers for q3 and q4
        q3_prompt = "What did you like best about working with us?"
        q4_prompt = "What could we improve on?"

        q3_response = generate_text_response(q3_prompt)
        q4_response = generate_text_response(q4_prompt)

        # format feedback answer in json
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
    Generate client feedback JSON file and save to "example_output/json"
    """
    # get project information from database
    projects = get_projects_from_database()

    # loop to generate feedback for all project
    all_feedbacks = []
    for project in projects:
        # get the number of feedback, either 2 or 3 feedbacks per project
        feedback_count = random.randint(2, 3)
        all_feedbacks.extend(generate_feedback(project, feedback_count))

    # save the JSON file
    output_dir = os.path.join(os.path.dirname(__file__), "../../example_output/json")
    os.makedirs(output_dir, exist_ok=True)
    output_file = os.path.join(output_dir, "client_feedbacks.json")

    with open(output_file, 'w') as f:
        json.dump(all_feedbacks, f, indent=4)

    print(f"客户反馈 JSON 文件已生成并保存到 {output_file}")


if __name__ == "__main__":
    generate_client_feedback()