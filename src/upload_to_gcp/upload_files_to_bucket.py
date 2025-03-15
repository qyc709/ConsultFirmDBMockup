from .gcp_setup import *
from google.cloud.exceptions import NotFound
import os

def create_bucket(bucket_name, client, location):
    try:
        client.get_bucket(bucket_name)
        print(f"Bucket {bucket_name} already exists")
    except NotFound:
        # Create the bucket
        client.create_bucket(
            bucket_name, 
            location=location
        )
        print(f"Bucket {bucket_name} created in {location}")


def upload_to_gcs(bucket_name, client, source_file_path, destination_blob_name):
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(destination_blob_name)
    blob.upload_from_filename(source_file_path)
    
    print(f"File {source_file_path} uploaded to gs://{bucket_name}/{destination_blob_name}")



def upload_files(bucket_name, directory):
    # create new bucket for spreadsheets
    create_bucket(bucket_name, client, location) 

    file_names = [file_name for file_name in os.listdir(directory)]

    for file_name in file_names:
        source_file_path = f"{directory}/{file_name}"
        destination_blob_name = file_name

        upload_to_gcs(bucket_name, client, source_file_path, destination_blob_name)


def upload_files_to_buckets():

    ss_bucket_name = "consulting_firm_spreadsheets"
    json_bucket_name = "consulting_firm_json"

    current_dir = os.getcwd()
    spreadsheets_path = f"{current_dir}/example_output/versions/spreadsheets"
    json_path = f"{current_dir}/example_output/versions/json"

    upload_files(ss_bucket_name, spreadsheets_path) # upload spreadsheets
    upload_files(json_bucket_name, json_path) # upload json
