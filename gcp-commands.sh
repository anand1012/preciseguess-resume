#!/bin/bash
# =============================================================================
# GCP Commands — preciseguess.com Resume Website
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
# 11. Create second GCS bucket named preciseguess.com (domain name must match)
#     This is required for CNAME-based custom domain hosting via Cloudflare
# -----------------------------------------------------------------------------
gsutil mb -l US gs://preciseguess.com

# -----------------------------------------------------------------------------
# 12. Configure preciseguess.com bucket as static website
# -----------------------------------------------------------------------------
gsutil web set -m index.html -e index.html gs://preciseguess.com

# -----------------------------------------------------------------------------
# 13. Make preciseguess.com bucket publicly readable
# -----------------------------------------------------------------------------
gsutil iam ch allUsers:objectViewer gs://preciseguess.com

# -----------------------------------------------------------------------------
# 14. Enable Cloud DNS API (via GCP Console)
#     Required before creating DNS zones or registering domains
#     https://console.developers.google.com/apis/api/dns.googleapis.com/overview?project=datacraft-anand
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# 15. Create Cloud DNS managed zone for preciseguess.com
#     This zone manages DNS records for the domain
# -----------------------------------------------------------------------------
gcloud dns managed-zones create preciseguess \
  --dns-name=preciseguess.com \
  --description="DNS zone for preciseguess.com" \
  --project=datacraft-anand

# -----------------------------------------------------------------------------
# 16. Register domain: preciseguess.com
#     --contact-data-from-file : registrant contact info (stored in contact.yaml)
#     --contact-privacy        : redacts personal info from public WHOIS
#     --cloud-dns-zone         : links domain to the Cloud DNS zone above
#     --yearly-price           : confirms the registration price ($12.00 USD/yr)
# -----------------------------------------------------------------------------
gcloud domains registrations register preciseguess.com \
  --contact-data-from-file=contact.yaml \
  --contact-privacy=redacted-contact-data \
  --cloud-dns-zone=preciseguess \
  --yearly-price="12.00 USD" \
  --project=datacraft-anand \
  --quiet

# -----------------------------------------------------------------------------
# 17. Update domain nameservers to Cloudflare
#     Cloudflare provides free SSL and CDN in front of GCS bucket
#     Nameservers obtained from Cloudflare dashboard after adding the site
# -----------------------------------------------------------------------------
gcloud domains registrations configure dns preciseguess.com \
  --name-servers="itzel.ns.cloudflare.com,skip.ns.cloudflare.com" \
  --project=datacraft-anand \
  --quiet

# -----------------------------------------------------------------------------
# 18. Deploy website files to GCS with no-cache headers
#     No-cache ensures Cloudflare always fetches the latest version
# -----------------------------------------------------------------------------
gsutil -h "Cache-Control:no-cache, no-store, must-revalidate" \
  cp /Users/anandswaroop/Documents/claude_code_workspace/resume-site/index.html gs://preciseguess.com/
gsutil -h "Cache-Control:no-cache, no-store, must-revalidate" \
  cp /Users/anandswaroop/Documents/claude_code_workspace/resume-site/style.css gs://preciseguess.com/

# -----------------------------------------------------------------------------
# 19. Purge Cloudflare cache via API
#     Called automatically by deploy.sh after every deployment
#     Ensures visitors always see the latest version without manual purging
#     Requires CLOUDFLARE_TOKEN and CLOUDFLARE_ZONE_ID stored in .env file
#     .env is gitignored and never pushed to GitHub or GCP
# -----------------------------------------------------------------------------
source .env
curl -s -X POST \
  "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/purge_cache" \
  -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"purge_everything":true}'

# -----------------------------------------------------------------------------
# 20. Full deploy — one command (see deploy.sh)
#     Uploads to GCS + purges Cloudflare cache + pushes to GitHub
#     Usage: ./deploy.sh
# -----------------------------------------------------------------------------
# bash /Users/anandswaroop/Documents/claude_code_workspace/resume-site/deploy.sh
