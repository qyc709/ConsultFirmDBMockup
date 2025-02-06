from generate_initial_source_data import generate_initial_source_data
from datetime import datetime
import sqlite3
import os
import pandas as pd
import random 
import string

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

:param base_year: The base year (e.g., 2020).
:param base_month: The base month (e.g., 1 for January).
:param number: The number to increment the month by.
:return: A string in the format 'YYYY-MM-DD'.
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
def generate_db_version(date, version):

    # get path to read the original database
    current_dir = os.getcwd()
    db_path = f'{current_dir}/example_output/database'
    sql_path = f'{current_dir}/src/db_versions_sql'

    conn = sqlite3.connect(f'{db_path}/consulting_firm.db')

    # create new version of sqlite db file
    db_name = f"consultingFirm_{version}.db"
    db_version_path = f'{db_path}/{db_name}'

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
def filter_and_save_excel_files(date, version):
    current_dir = os.getcwd()
    excel_path = f'{current_dir}/example_output/spreadsheets'

    date_int = int(date[:7].replace("-", ""))  # Convert 'YYYY-MM' to 'YYYYMM' for comparison

    for file_base in EXCEL_NAMES:
        original_file_path = os.path.join(excel_path, f"{file_base}.xlsx")

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
                new_file_path = os.path.join(excel_path, new_filename)

                # Save the filtered data
                df_filtered.to_excel(new_file_path, index=False)


"""
Generate versions of consulting firm data

:param start_year: output data will start from January of the given year
:param no_initial_load_months: the number of months in the initial version of data
:param no_of_updates: the number of incremental update versions
:param intervals: time intervals of the incremental update

output: versions of 3 types consulting firm data
"""
def generate_consulting_firm_database(start_year, initial_no_of_months, no_of_updates, intervals=1):
    # adding update intervals, default=1

    # prepare the initial source data
    # ensure the data is enough to be separated in the given time intervals
    end_year = start_year + (initial_no_of_months + no_of_updates*intervals)//MONTHS_OF_A_YEAR

    # generate the source data
    generate_initial_source_data(start_year, end_year)

    # generate initial version of database
    date = get_date_from_number(start_year, initial_no_of_months)
    generate_db_version(date, 'initial')
    filter_and_save_excel_files(date, 'initial')

    # generate incremental update versions of database
    for i in range(no_of_updates):
        date = get_date_from_number(start_year, initial_no_of_months + i + 1)
        generate_db_version(date, i + 1)
        filter_and_save_excel_files(date, i + 1)

if __name__ == '__main__':
    generate_consulting_firm_database(2020, 6, 4)