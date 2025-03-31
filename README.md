# Setup
`pip install -r requirements.txt`

# Run Data Generation
PowerShell: `python src\generate_consulting_firm_data.py`

Linux Shell: `python src/generate_consulting_firm_data.py`

# Database Design
https://dbdiagram.io/d/ConsultingFirmDBUpdate-66832ca99939893daec2ffec



# GCP Setup

1. Create Account $\rightarrow$ IAM & Admin $\rightarrow$ Create service account  $\rightarrow$ Grant Access "BigQuery Admin" & "Storage Admin" in the second step

2. Service accounts page  $\rightarrow$  Actions  $\rightarrow$ Manage keys  $\rightarrow$ Add key  $\rightarrow$ Download JSON 

3. Setting up Billing Account

4. Add the JSON File key under path `src/upload_to_gcp/keys/`, then copy the file path and fill in the `gcp_setup.py` file