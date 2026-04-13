#!/bin/bash
# =============================================================================
# GCP Commands — datacraft.app Resume Website
# Project: datacraft-anand | Account: anand.swaroop.gcp@gmail.com
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Install Google Cloud SDK (via Homebrew on macOS)
#    Installs the gcloud CLI tool needed to interact with GCP from terminal
# -----------------------------------------------------------------------------
brew install --cask google-cloud-sdk

# -----------------------------------------------------------------------------
# 2. Authenticate with GCP
#    Opens a browser to log in with your Google account
#    Links your terminal session to your GCP account
# -----------------------------------------------------------------------------
gcloud auth login

# -----------------------------------------------------------------------------
# 3. Set the active GCP project
#    All subsequent commands will run against this project
# -----------------------------------------------------------------------------
gcloud config set project datacraft-anand

# -----------------------------------------------------------------------------
# 4. Create a GCS (Google Cloud Storage) bucket
#    --location=US          : bucket hosted in US region
#    --uniform-bucket-level-access : consistent access control across all objects
#    This bucket will store and serve the static website files
# -----------------------------------------------------------------------------
gcloud storage buckets create gs://datacraft-anand \
  --project=datacraft-anand \
  --location=US \
  --uniform-bucket-level-access

# -----------------------------------------------------------------------------
# 5. Configure the bucket as a static website
#    --web-main-page-suffix : default file to serve (index.html)
#    --web-error-page       : page to show on 404 errors
# -----------------------------------------------------------------------------
gcloud storage buckets update gs://datacraft-anand \
  --web-main-page-suffix=index.html \
  --web-error-page=index.html

# -----------------------------------------------------------------------------
# 6. Upload website files to the bucket
#    Uploads index.html and style.css with correct content types
# -----------------------------------------------------------------------------
gsutil cp /Users/anandswaroop/Documents/claude_code_workspace/resume-site/index.html gs://datacraft-anand/
gsutil cp /Users/anandswaroop/Documents/claude_code_workspace/resume-site/style.css gs://datacraft-anand/

# -----------------------------------------------------------------------------
# 7. Make the bucket publicly readable
#    allUsers:objectViewer allows anyone on the internet to view the files
#    This is required for a public website
# -----------------------------------------------------------------------------
gsutil iam ch allUsers:objectViewer gs://datacraft-anand

# -----------------------------------------------------------------------------
# 8. Enable Cloud Domains API
#    Required before registering or managing domains via GCP
#    Done via GCP Console: https://console.developers.google.com/apis/api/domains.googleapis.com/overview?project=datacraft-anand
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# 9. Search for domain availability
#    Checks if datacraft.app and related domains are available for registration
# -----------------------------------------------------------------------------
gcloud domains registrations search-domains datacraft

# -----------------------------------------------------------------------------
# 10. Register domain: datacraft.app
#     --contact-data-from-file : contact info for domain registration (WHOIS)
#     --contact-privacy        : hides personal info from public WHOIS lookup
#     --cloud-dns-zone         : auto-creates a Cloud DNS zone for this domain
#     --project                : GCP project to register the domain under
# -----------------------------------------------------------------------------
gcloud domains registrations register datacraft.app \
  --contact-data-from-file=contact.yaml \
  --contact-privacy=private-contact-data \
  --cloud-dns-zone=datacraft-app \
  --project=datacraft-anand

# -----------------------------------------------------------------------------
# 11. (Next Step) Set up Load Balancer + SSL for HTTPS on custom domain
#     Required to serve datacraft.app over HTTPS with a valid SSL certificate
#     Steps:
#       a. Reserve a static IP
#       b. Create a backend bucket pointing to gs://datacraft-anand
#       c. Create URL map, HTTP proxy, and forwarding rule
#       d. Provision a Google-managed SSL certificate for datacraft.app
# -----------------------------------------------------------------------------
