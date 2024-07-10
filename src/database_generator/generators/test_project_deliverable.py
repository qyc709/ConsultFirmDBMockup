import random
import logging
from scipy.stats import norm
from datetime import date, timedelta
from dateutil.relativedelta import relativedelta
from sqlalchemy.orm import sessionmaker
from sqlalchemy import func
from collections import defaultdict
from decimal import Decimal
from ...db_model import *
from ..utils.test_project_utils import *
from ..utils.consultant_deliverable_utils import *
from config import project_settings, consultant_settings

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def generate_projects(start_year, end_year, initial_consultants):
    yearly_targets = calculate_yearly_project_targets(start_year, end_year, initial_consultants)
    
    Session = sessionmaker(bind=engine)
    session = Session()
    simulation_start_date = date(start_year, 1, 1)
    simulation_end_date = date(end_year, 12, 31)
    print("Generating Project Data...")

    try:
        project_meta = defaultdict(lambda: {
            'team': [],
            'deliverables': defaultdict(lambda: {
                'remaining_hours': 0,
                'consultant_deliverables': [],
                'actual_hours': 0
            }),
            'target_hours': 0,
            'start_date': None
        })

        for current_year in range(start_year, end_year + 1):
            monthly_targets = distribute_monthly_targets(yearly_targets[current_year])
            
            for current_month in range(1, 13):
                month_start = date(current_year, current_month, 1)
                if month_start > simulation_end_date:
                    break

                logging.info(f"Processing {month_start.strftime('%B %Y')}...")

                available_consultants = get_available_consultants(session, month_start)
                active_units = session.query(BusinessUnit).all()

                project_meta = create_new_projects_if_needed(session, month_start, available_consultants, active_units, project_meta, simulation_start_date, monthly_targets)
                
                # Daily simulation within the month
                current_date = month_start
                while current_date.month == current_month:
                    project_meta = start_due_projects(session, current_date, project_meta)
                    if current_date.weekday() < 5:  # Weekday
                        generate_daily_consultant_deliverables(session, current_date, project_meta)
                    update_project_statuses(session, current_date, project_meta, available_consultants)
                    current_date += timedelta(days=1)

                # End of month operations
                month_end = current_date - timedelta(days=1)
                update_existing_projects(session, month_end, available_consultants, project_meta)
                log_consultant_projects(session, month_end)

                session.commit()

            generate_project_expenses(session, project_meta, simulation_end_date)
            session.commit()
            print(f"Project generation for year {current_year} completed successfully.")

    except Exception as e:
        print(f"An error occurred while processing projects: {str(e)}")
        import traceback
        print(traceback.format_exc())
        session.rollback()
    finally:
        session.close()





def calculate_yearly_project_targets(start_year, end_year, initial_consultants):
    yearly_targets = {}
    consultant_count = initial_consultants
    
    for year in range(start_year, end_year + 1):
        growth_rate = consultant_settings.CONSULTANT_YEARLY_GROWTHRATE.get(year, 0.05)  # Default growth rate of 5%
        consultant_count *= (1 + growth_rate)
        
        yearly_targets[year] = math.ceil(consultant_count / 2)
    
    return yearly_targets

def distribute_monthly_targets(yearly_target):
    base_monthly_target = yearly_target // 12
    extra_projects = yearly_target % 12
    
    monthly_targets = [base_monthly_target] * 12
    middle_months = project_settings.PROJECT_MONTH_DISTRIBUTION
    for i in range(extra_projects):
        month = random.choice(middle_months)
        monthly_targets[month] += 1
    
    return monthly_targets


def start_due_projects(session, current_date, project_meta):
    due_projects = session.query(Project).filter(
        Project.Status == 'Not Started',
        Project.ActualStartDate <= current_date
    ).all()

    for project in due_projects:
        project.Status = 'In Progress'
        #logging.info(f"Starting project {project.ProjectID} on {current_date}")

        # Ensure the project team is assigned
        if project.ProjectID in project_meta:
            team_members = project_meta[project.ProjectID]['team']
            for consultant_id in team_members:
                # Check if the consultant is already assigned to the project
                existing_assignment = session.query(ProjectTeam).filter(
                    ProjectTeam.ProjectID == project.ProjectID,
                    ProjectTeam.ConsultantID == consultant_id
                ).first()

                if not existing_assignment:
                    team_member = ProjectTeam(
                        ProjectID=project.ProjectID,
                        ConsultantID=consultant_id,
                        Role='Team Member',
                        StartDate=current_date
                    )
                    session.add(team_member)
                    #logging.info(f"Assigned consultant {consultant_id} to project {project.ProjectID}")

        else:
            logging.warning(f"Project {project.ProjectID} not found in project_meta")

    session.commit()
    return project_meta        

def create_new_projects_if_needed(session, current_date, available_consultants, active_units, project_meta, simulation_start_date, monthly_targets):
    higher_level_consultants = sorted(
        [c for c in available_consultants if c.title_id >= project_settings.HIGHER_LEVEL_TITLE_THRESHOLD],
        key=lambda c: (c.active_project_count, -c.title_id)
    )

    target_for_month = monthly_targets[current_date.month - 1]
    
    std_dev = target_for_month * 0.2
    projects_to_create = max(0, round(norm.rvs(loc=target_for_month, scale=std_dev)))

    projects_this_month = len([p for p in project_meta.values() if p['start_date'].month == current_date.month])
    projects_to_create = max(0, projects_to_create - projects_this_month)

    projects_created = 0
    for consultant in higher_level_consultants:
        if projects_created >= projects_to_create:
            break
        
        if consultant.active_project_count >= project_settings.MAX_PROJECTS_PER_CONSULTANT:
            continue

        project, new_project_meta, target_hours = create_new_project(session, current_date, available_consultants, active_units, simulation_start_date, project_manager=consultant)
        if project:
            project_meta[project.ProjectID] = new_project_meta
            project_meta[project.ProjectID]['target_hours'] = target_hours
            project_meta[project.ProjectID]['start_date'] = project.PlannedStartDate
            projects_created += 1

            '''
            logging.info(f"Created new project: ProjectID {project.ProjectID}, "
                         f"Start Date: {project.PlannedStartDate}, "
                         f"Team Size: {len(new_project_meta['team'])}, "
                         f"Project Manager: {consultant.consultant.ConsultantID}")
            '''

            # Update consultant project counts
            for consultant_id in new_project_meta['team']:
                consultant_info = next(c for c in available_consultants if c.consultant.ConsultantID == consultant_id)
                consultant_info.active_project_count += 1

            # Re-sort available_consultants
            available_consultants = sorted(available_consultants, key=lambda c: (c.active_project_count, -c.title_id))

    logging.info(f"Date: {current_date}, New Projects Created: {projects_created}")
    return project_meta

def create_new_project(session, current_date, available_consultants, active_units, simulation_start_date, project_manager):
    assigned_consultants = assign_consultants_to_project(available_consultants, project_manager)

    assigned_unit_id = assign_project_to_business_unit(session, assigned_consultants, active_units, current_date.year)
    
    project = Project(
        ClientID=random.choice(session.query(Client.ClientID).all())[0],
        UnitID=assigned_unit_id,
        Name=f"Project_{current_date.year}_{random.randint(1000, 9999)}",
        Type=random.choices(project_settings.PROJECT_TYPES, weights=project_settings.PROJECT_TYPE_WEIGHTS)[0],
        Status='Not Started',
        Progress=0,
        EstimatedBudget=None,
        Price=None
    )
    
    session.add(project)
    session.flush()

    team_size = set_project_dates(project, current_date, assigned_consultants, session, simulation_start_date)
    project.PlannedHours = calculate_planned_hours(project, team_size)
    target_hours = calculate_target_hours(project.PlannedHours)
    project.ActualHours = 0
    
    deliverables = generate_deliverables(project, target_hours)
    session.add_all(deliverables)
    session.flush()

    calculate_project_financials(session, project, assigned_consultants, current_date, deliverables)
    
    assign_project_team(session, project, assigned_consultants)
    session.flush()

    project_meta = initialize_project_meta(project, target_hours)

    return project, project_meta, target_hours

def update_existing_projects(session, current_date, available_consultants, project_meta):
    active_projects = session.query(Project).filter(
        Project.Status.in_(['Not Started', 'In Progress']),
        Project.PlannedStartDate <= current_date,
        Project.PlannedEndDate >= current_date
    ).all()

    for project in active_projects:
        if project.Status == 'Not Started' and project.PlannedStartDate <= current_date:
            project.Status = 'In Progress'
            project.ActualStartDate = current_date

        # Update project team if needed
        if project.ProjectID in project_meta:
            update_project_team(session, project, available_consultants, project_meta[project.ProjectID]['team'], current_date)
        else:
            logging.warning(f"Project {project.ProjectID} not found in project_meta")

def generate_daily_consultant_deliverables(session, current_date, project_meta):
    consultant_daily_hours = defaultdict(float)
    
    # Get list of active projects
    active_projects = [
        (project_id, meta) for project_id, meta in project_meta.items()
        if session.query(Project).get(project_id).Status == 'In Progress'
    ]
    
    # Shuffle the active projects to ensure fair allocation
    random.shuffle(active_projects)
    
    for project_id, meta in active_projects:
        project = session.query(Project).get(project_id)
        
        allocated_hours = allocate_work_for_project(session, meta, current_date, consultant_daily_hours)
        
        if allocated_hours > 0:
            project.ActualHours += allocated_hours
            project.Progress = min(100, int((project.ActualHours / meta['target_hours']) * 100))
            #logging.info(f"Allocated {allocated_hours} hours to ProjectID {project_id} on {current_date}")
    
    session.commit()

def update_project_statuses(session, current_date, project_meta, available_consultants):
    for project_id, meta in project_meta.items():
        project = session.query(Project).get(project_id)
        if project.Status in ['Completed', 'Cancelled']:
            continue

        if project.Status == 'Not Started' and current_date >= project.ActualStartDate:
            project.Status = 'In Progress'
            #logging.info(f"Starting project {project.ProjectID} on {current_date}")

        if project.Status == 'In Progress':
            all_deliverables_completed = True
            total_target_hours = meta['target_hours']
            weighted_progress = 0

            for deliverable_id, deliverable_meta in meta['deliverables'].items():
                deliverable = session.query(Deliverable).get(deliverable_id)

                if deliverable.ActualHours >= deliverable_meta['target_hours']:
                    deliverable.Status = 'Completed'
                    deliverable.SubmissionDate = current_date
                    if project.Type == 'Fixed':
                        deliverable.InvoicedDate = current_date + timedelta(days=random.randint(1, 7))
                elif deliverable.ActualHours > 0:
                    deliverable.Status = 'In Progress'
                    all_deliverables_completed = False
                else:
                    deliverable.Status = 'Not Started'
                    all_deliverables_completed = False

                deliverable_progress = (deliverable.ActualHours / deliverable_meta['target_hours']) * 100
                deliverable_weight = deliverable_meta['target_hours'] / total_target_hours
                weighted_progress += deliverable_progress * deliverable_weight
                deliverable.Progress = min(100, int(deliverable_progress))

            project.Progress = min(100, int(weighted_progress))

            if project.ActualHours == 0 and current_date > project.ActualStartDate + timedelta(days=120):
                project.Status = 'Cancelled'
                logging.warning(f"Project {project.ProjectID} cancelled due to inactivity")
            elif all_deliverables_completed:
                project.Status = 'Completed'
                project.ActualEndDate = current_date
                handle_project_completion(session, project, current_date, project_meta, available_consultants)
            elif current_date > project.PlannedEndDate:
                if project.Progress >= 99:  # Allow completion if very close to finish
                    project.Status = 'Completed'
                    project.ActualEndDate = current_date
                    handle_project_completion(session, project, current_date, project_meta, available_consultants)
                else:
                    pass
                    #logging.warning(f"Project {project.ProjectID} has exceeded its planned end date but is only {project.Progress}% complete")

        #logging.info(f"Updated status for ProjectID {project.ProjectID}: Status {project.Status}, Progress {project.Progress}%, ActualHours {project.ActualHours}")

    session.commit()


def generate_project_expenses(session, project_meta, simulation_end_date):
    for project_id, meta in project_meta.items():
        project = session.query(Project).get(project_id)
        if project.Status not in ['In Progress', 'Completed']:
            continue

        total_consultant_cost = sum(cd.Hours * calculate_hourly_cost(session, cd.ConsultantID, cd.Date.year)
                                    for deliverable_meta in meta['deliverables'].values()
                                    for cd in deliverable_meta['consultant_deliverables'])

        expenses = []
        for deliverable_id, deliverable_meta in meta['deliverables'].items():
            deliverable = session.query(Deliverable).get(deliverable_id)
            
            expense_start_date = deliverable.ActualStartDate or deliverable.PlannedStartDate
            expense_end_date = min(deliverable.SubmissionDate or simulation_end_date,
                                   project.ActualEndDate or simulation_end_date,
                                   simulation_end_date)

            if expense_start_date >= expense_end_date:
                continue

            for category, percentage in project_settings.EXPENSE_CATEGORIES.items():
                is_billable = random.choice([True, False])
                amount = Decimal(total_consultant_cost) * Decimal(percentage) * Decimal(random.uniform(0.8, 1.2))
                amount = round(amount, -2)  # Round to nearest hundred

                if amount > 0:
                    consultant_deliverable_dates = [cd.Date for cd in deliverable_meta['consultant_deliverables']
                                                    if expense_start_date <= cd.Date <= expense_end_date]
                    
                    if consultant_deliverable_dates:
                        expense_date = random.choice(consultant_deliverable_dates)
                    else:
                        # Fallback: use the middle date between start and end
                        expense_date = expense_start_date + (expense_end_date - expense_start_date) / 2
                    
                    expense = ProjectExpense(
                        ProjectID=project.ProjectID,
                        DeliverableID=deliverable.DeliverableID,
                        Date=expense_date,
                        Amount=float(amount),
                        Description=f"{category} expense for {deliverable.Name}",
                        Category=category,
                        IsBillable=is_billable
                    )
                    expenses.append(expense)

        session.add_all(expenses)

    session.commit()


