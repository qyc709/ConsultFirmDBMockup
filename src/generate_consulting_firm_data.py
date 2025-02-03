from generate_initial_source_data import generate_initial_source_data
from datetime import datetime

MONTHS_OF_A_YEAR = 12

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


"""
Generate versions of consulting firm data

:param start_year: output data will start from January of the given year
:param no_initial_load_months: the number of months in the initial version of data
:param no_of_updates: the number of incremental update versions
:param intervals: time intervals of the incremental update

output: versions of 3 types consulting firm data
"""
def generate_consulting_firm_data(start_year, no_initial_load_months, no_of_updates, intervals=1):
    # adding update intervals, default=1

    # prepare the initial source data
    # ensure the data is enough to be separated in the given time intervals
    end_year = start_year + (no_initial_load_months + no_of_updates*intervals)//MONTHS_OF_A_YEAR

    #  generate the source data
    generate_initial_source_data(start_year, end_year)

    # date = get_date_from_number(start_year, no_initial_load_months)


if __name__ == '__main__':
    generate_consulting_firm_data(2020, 6, 3)