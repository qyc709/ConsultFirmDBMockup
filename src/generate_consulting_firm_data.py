from generate_initial_source_data import generate_initial_source_data
from datetime import datetime
import sqlite3
import os
import pandas as pd
import random 
import string
import json
from json_generator.client_feedback import generate_client_feedback 
from upload_to_gcp.upload_files_to_bucket import upload_files_to_buckets
from upload_to_gcp.upload_db_to_bq import upload_sqlite_to_bigquery


MONTHS_OF_A_YEAR = 12
TABLE_NAMES = ["Location", "Client", "BusinessUnit", "Project", "Deliverable", "Consultant", "Title", "ConsultantTitleHistory", "ConsultantDeliverable", "ProjectExpense", "ProjectTeam", "Payroll", "ProjectBillingRate"]
EXCEL_NAMES = ["indirect_costs", "non_billable_time"]

project_id_mapping = pd.DataFrame({'projectID': [], 'project_tmp_id': []})
deliverable_id_mapping = pd.DataFrame({'deliverableID': [], 'deliverable_tmp_id': []})
cth_id_mapping = pd.DataFrame({'recordID': [], 'ID': []})
cd_id_mapping = pd.DataFrame({'recordID': [], 'ID': []})
pe_id_mapping = pd.DataFrame({'recordID': [], 'ID': []})
payroll_id_mapping = pd.DataFrame({'recordID': [], 'ID': []})

"""
Generate a date by incrementing the month based on the input number.

:param base_year: The base year.
:param no_of_months: the number of months.

:return: The date of the first of a month in the format 'YYYY-MM-DD'.
(e.g. base_year = 2020, no_of_months = 1, return = '2020-02-01')
"""
def get_date_from_number(base_year, no_of_months):

    # Calculate the target month and year
    month = no_of_months % MONTHS_OF_A_YEAR + 1
    year = base_year + no_of_months // MONTHS_OF_A_YEAR
    
    # Create the date
    date = datetime(year, month, 1).strftime('%Y-%m-%d')
    return date


def generate_unique_id(existing_ids):
    while True:
        new_id = ''.join(random.choices(string.ascii_lowercase + string.digits, k=6))
        if new_id not in existing_ids: 
            existing_ids.add(new_id)
            return new_id


def generate_unique_id_with_prefix(existing_ids, prefix):
    while True:
        new_id = prefix + ''.join(random.choices(string.ascii_uppercase + string.digits, k=4))
        if new_id not in existing_ids:  
            existing_ids.add(new_id)
            return new_id
        

"""
Generate a single version of consulting firm database

:param date: last date of data in the required version
:param version: version number or name

output: sqlite .db file under /example_output/database
"""
def generate_db_version(date, version, output_path):

    # get path to read the original database
    current_dir = os.getcwd()
    sql_path = f'{current_dir}/src/db_versions_sql'

    conn = sqlite3.connect(f'{output_path}/database/consulting_firm.db')

    # create new version of sqlite db file
    db_name = f"consultingFirm_{version}.db"

    output_database_path = f"{output_path}/versions/database"
    if not os.path.exists(output_database_path):
        os.mkdir(output_database_path)
    
    db_version_path = f'{output_database_path}/{db_name}'

    print(db_version_path)

    # check if there exists a db with the same file name
    # if exists, delete the database
    if os.path.exists(db_version_path):
        os.remove(db_version_path)

    # connect to the new version of db
    conn_new = sqlite3.connect(db_version_path)
    cursor_new = conn_new.cursor() 

    # run db DDL for the new version
    with open(f"{sql_path}/consulting_firm_schema.sql", 'r') as file:
        schema = file.read()
    
    cursor_new.executescript(schema) 
    conn_new.commit()

    # insert separated data into the new version
    for table in TABLE_NAMES:
        # print(table)
        filename = table + '.sql'

        with open(f"{sql_path}/{filename}", 'r') as file:
            sql = file.read()

        new_table = pd.read_sql(sql, conn, params=(date,))

        existing_ids = set()
        if table == 'Project':
            global project_id_mapping
            # create a list of existing projectID
            existing_ids = set(project_id_mapping['projectID'])
            # map the old id to new id if exists
            new_table = new_table.merge(project_id_mapping, on='project_tmp_id', how='left')
            # create new projectID for new project
            new_table['projectID'] = new_table['projectID'].apply(lambda x: x if pd.notna(x) else generate_unique_id_with_prefix(existing_ids, 'PROJ-'))

            # update the id mapping table
            project_id_mapping = new_table[['project_tmp_id', 'projectID']]
            # drop old id column
            new_table = new_table.drop(['project_tmp_id'], axis=1)  
            
        elif table == 'Deliverable':
            global deliverable_id_mapping
            existing_ids = set(deliverable_id_mapping['deliverableID'])
            new_table = new_table.merge(deliverable_id_mapping, on='deliverable_tmp_id', how='left')
            new_table['deliverableID'] = new_table['deliverableID'].apply(lambda x: x if pd.notna(x) else generate_unique_id_with_prefix(existing_ids, 'DEL-'))

            # map old with the new project id
            new_table = new_table.merge(project_id_mapping, on='project_tmp_id', how='left')

            # update id mapping table and delete old id columns
            deliverable_id_mapping = new_table[['deliverable_tmp_id', 'deliverableID']]
            new_table = new_table.drop(['deliverable_tmp_id', 'project_tmp_id'], axis=1)  

        elif table == 'ConsultantTitleHistory':
            global cth_id_mapping
            existing_ids = set(cth_id_mapping['recordID'])
            new_table = new_table.merge(cth_id_mapping, on='ID', how='left')
            new_table['recordID'] = new_table['recordID'].apply(lambda x: x if pd.notna(x) else generate_unique_id(existing_ids))

            cth_id_mapping = new_table[['ID', 'recordID']]
            new_table = new_table.drop(['ID'], axis=1)  

        elif table == 'ConsultantDeliverable':
            global cd_id_mapping
            existing_ids = set(cd_id_mapping['recordID'])
            new_table = new_table.merge(cd_id_mapping, on='ID', how='left')
            new_table['recordID'] = new_table['recordID'].apply(lambda x: x if pd.notna(x) else generate_unique_id(existing_ids))

            # map old with the new project id
            new_table = new_table.merge(deliverable_id_mapping, on='deliverable_tmp_id', how='left')

            cd_id_mapping = new_table[['ID', 'recordID']]
            new_table = new_table.drop(['ID', 'deliverable_tmp_id'], axis=1) 

        elif table == 'ProjectExpense':
            global pe_id_mapping
            existing_ids = set(pe_id_mapping['recordID'])
            new_table = new_table.merge(pe_id_mapping, on='ID', how='left')
            new_table['recordID'] = new_table['recordID'].apply(lambda x: x if pd.notna(x) else generate_unique_id(existing_ids))

            # map old with the new project id
            new_table = new_table.merge(deliverable_id_mapping, on='deliverable_tmp_id', how='left')
            new_table = new_table.merge(project_id_mapping, on='project_tmp_id', how='left')

            pe_id_mapping = new_table[['ID', 'recordID']]
            new_table = new_table.drop(['ID', 'deliverable_tmp_id', 'project_tmp_id'], axis=1)

        elif table == 'Payroll':
            global payroll_id_mapping
            existing_ids = set(payroll_id_mapping['recordID'])
            new_table = new_table.merge(payroll_id_mapping, on='ID', how='left')
            new_table['recordID'] = new_table['recordID'].apply(lambda x: x if pd.notna(x) else generate_unique_id(existing_ids))

            payroll_id_mapping = new_table[['ID', 'recordID']]
            new_table = new_table.drop(['ID'], axis=1)  

        elif table in ['ProjectTeam', "ProjectBillingRate"]:
            # mao old with new projectID
            new_table = new_table.merge(project_id_mapping, on='project_tmp_id', how='left')

            # drop old id column
            new_table = new_table.drop(['project_tmp_id'], axis=1) 
        
        new_table.to_sql(table, conn_new, if_exists='append', index=False)

# read excel and filter by date then save
def filter_and_save_excel_files(date, version, output_path):

    date_int = int(date[:7].replace("-", ""))  # Convert 'YYYY-MM' to 'YYYYMM' for comparison

    for file_base in EXCEL_NAMES:

        original_file_path = f"{output_path}/spreadsheets/{file_base}.xlsx"
        print(original_file_path)

        # Ensure the original file exists before trying to read
        if not os.path.exists(original_file_path):
            continue  # Skip if the file doesn't exist

        # Read the Excel file
        df = pd.read_excel(original_file_path)

        # Ensure 'YearMonth' column exists
        if 'YearMonth' in df.columns:
            # Convert 'YearMonth' column to integer format for comparison
            df['YearMonth'] = df['YearMonth'].astype(str).str.replace("-", "").astype(int)

            # Filter rows where YearMonth < date_int
            df_filtered = df[df['YearMonth'] < date_int]

            if not df_filtered.empty:  # Only save if there are filtered rows
                # Create new filename with version appended
                new_filename = f"{file_base}_{version}.xlsx"

                output_ss_path = f"{output_path}/versions/spreadsheets"
                if not os.path.exists(output_ss_path):
                    os.mkdir(output_ss_path)

                new_file_path = f'{output_ss_path}/{new_filename}'

                # Save the filtered data
                df_filtered.to_excel(new_file_path, index=False)



"""
Generate a single version of client feedback json file

:param date: last date of data in the required version
:param version: version number or name
:param json_path: file path to the full version json file

output: {version}.json file under /example_output/json
"""
def generate_json_version(date, version, output_path):
    end_date = datetime.strptime(date, '%Y-%m-%d')

    file_path = f"{output_path}/json/client_feedbacks.json"

    output_js_path = f"{output_path}/versions/json"
    if not os.path.exists(output_js_path):
        os.mkdir(output_js_path)

    output_json_path = f"{output_js_path}/client_feedbacks_{version}.json"

    with open(file_path, 'r') as file:
        data = json.load(file)

    filtered_data = []

    for record in data:
        try:
            survey_date = datetime.strptime(record['surveyDate'], '%Y-%m-%d') 

            if survey_date < end_date:
                filtered_data.append(record)
        except(KeyError, ValueError) as e:
            print('f"Skipping record - Error: {e}"')

    sorted_data = sorted(filtered_data, key=lambda x: datetime.strptime(x['surveyDate'], '%Y-%m-%d'))

    with open(output_json_path, 'w') as file:
        json.dump(sorted_data, file, indent=4)



"""
Generate versions of consulting firm data

:param start_year: output data will start from January of the given year
:param no_initial_load_months: the number of months in the initial version of data
:param no_of_updates: the number of incremental update versions
:param intervals: time intervals of the incremental update

output: versions of 3 types consulting firm data
"""
def generate_consulting_firm_data(start_year, initial_no_of_months, no_of_updates, intervals=1):
    # adding update intervals, default=1

    # prepare the initial source data
    # ensure the data is enough to be separated in the given time intervals
    end_year = start_year + (initial_no_of_months + no_of_updates*intervals)//MONTHS_OF_A_YEAR

    # # generate the source data
    generate_initial_source_data(start_year, end_year)

    current_dir = os.getcwd()
    output_path = f'{current_dir}/example_output'

    if not os.path.exists(f"{output_path}/versions"):
        os.mkdir(f"{output_path}/versions")

    # generate incremental update versions of database
    for i in range(no_of_updates):

        if i == 0:
            version = 'initial'
            date = get_date_from_number(start_year, initial_no_of_months)
        elif i + 1 == no_of_updates:
            version = 'final'
            date = get_date_from_number(start_year, initial_no_of_months + i + 1)
        else:
            version = i + 1
            date = get_date_from_number(start_year, initial_no_of_months + i + 1)

        generate_db_version(date, version, output_path)
        filter_and_save_excel_files(date, version, output_path)

    # Generate json file
    generate_client_feedback()
    print("✅ JSON Generation Completed")

    for i in range(no_of_updates):
        if i == 0:
            version = 'initial'
            date = get_date_from_number(start_year, initial_no_of_months)
        elif i + 1 == no_of_updates:
            version = 'final'
            date = get_date_from_number(start_year, initial_no_of_months + i + 1)
        else:
            version = i + 1
            date = get_date_from_number(start_year, initial_no_of_months + i + 1)

        generate_json_version(date, version, output_path)

    upload_files_to_buckets()

    upload=True
    version_to_upload="initial"

    if upload and version_to_upload:
        db_dir = f"{output_path}/versions/database"
        upload_sqlite_to_bigquery(version_to_upload, db_dir)

    

if __name__ == '__main__':
    generate_consulting_firm_data(2024, 6, 5)