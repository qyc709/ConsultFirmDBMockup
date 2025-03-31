from google.cloud import storage
from google.oauth2 import service_account

################################
# paste your key file path here
key_path = ""
################################

credentials = service_account.Credentials.from_service_account_file(key_path)

# Project ID
project_id = "consultingfirmpipeline"
client = storage.Client(credentials=credentials, project=project_id)

# database name
database_name="consultingFirm"

# bucket region
location = "us-west1" # e.g. us-west1