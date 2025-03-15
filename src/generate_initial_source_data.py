import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from models.db_model import main as create_db
from database_generator.generators.client import generate_clients
from database_generator.generators.location import generate_locations
from database_generator.generators.title import generate_titles
from database_generator.generators.business_unit import generate_business_units
from database_generator.generators.consultant_title_history import main as generate_consultant_title_history
from database_generator.generators.payroll import generate_payroll
from database_generator.generators.project_deliverable import generate_projects
from spreadsheet_generator.indirect_cost import generate_indirect_costs
from spreadsheet_generator.non_billable_time import generate_non_billable_time_report

INITIAL_CONSULTANTS = 100

def generate_initial_source_data(START_YEAR, END_YEAR):
    # Initialize DB
    create_db()

    # Generate database
    generate_locations()
    generate_business_units()
    generate_clients(358)
    generate_titles()
    generate_consultant_title_history(INITIAL_CONSULTANTS, start_year=START_YEAR, end_year=END_YEAR)
    generate_payroll(END_YEAR)
    generate_projects(START_YEAR, END_YEAR, INITIAL_CONSULTANTS)
    
    # Generate Spreadsheet
    generate_indirect_costs()
    print("database生成结束")

    # Generate non-billable time report
    generate_non_billable_time_report()
    print("spreadsheet生成结束")
