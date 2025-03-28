from google.cloud import storage
from google.oauth2 import service_account

key_path = ""
# credentials = service_account.Credentials.from_service_account_file(key_path)

# Project ID
project_id = "consultingfirmpipeline"
# client = storage.Client(credentials=credentials, project=project_id)

# bucket region
location = "us-west1" # e.g. us-west1