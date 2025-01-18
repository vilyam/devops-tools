#!/usr/bin/env bash

# --- gcloud-profile.sh ---
#
# Usage:
#   ./gcloud-profile.sh <PROFILE_NAME>
#
# Example:
#   ./gcloud-profile.sh dev
#
# When you have multiple organizations, 
# you have pain switching between them in gcloud for sure.
# This script activates the given gcloud configuration
# and then replaces the default application credentials
# with the profile-specific credentials.

ADC_DIR="$HOME/.config/gcloud/adc"

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <PROFILE_NAME>"
  echo ""
  echo "Available profiles:"

  gcloud config configurations list --format="value(name)"
  exit 1
fi

PROFILE=$1

# 1. Determine source and destination paths
ADC_SRC="${ADC_DIR}/${PROFILE}_application_default_credentials.json"
ADC_DEST="$HOME/.config/gcloud/application_default_credentials.json"

# 2. Check if the profile-specific credentials file exists
if [ ! -f "$ADC_SRC" ]; then
  echo "ERROR: The file '$ADC_SRC' does not exist."
  echo "Please ensure that a file named '${PROFILE}_application_default_credentials.json'"
  echo "exists under '$ADC_DIR'."
  echo ""
  echo "please do:"
  echo ""
  echo "  gcloud auth application-default login"
  echo ""
  echo "and then:"
  echo ""
  echo "  cp $HOME/.config/gcloud/application_default_credentials.json $ADC_SRC"
  echo ""
  exit 1
fi

# 3. Copy the profile's application default credentials into place
echo "Copying ${ADC_SRC} to ${ADC_DEST} ..."
cp "$ADC_SRC" "$ADC_DEST"

# 4. Activate the gcloud configuration for this profile
echo "Activating gcloud profile: $PROFILE ..."
gcloud config configurations activate "$PROFILE"

# 5. Retrieve the current (active) project from the newly activated profile
PROJECT="$(gcloud config get-value project --quiet)"
if [ -z "$PROJECT" ]; then
  echo "ERROR: Could not determine the active project. Please ensure the project is set in the '$PROFILE' config."
  exit 1
fi

echo "Current active project is: $PROJECT"

# 6. Set the quota project for the newly copied Application Default Credentials
echo "Setting quota project to '$PROJECT' for the ADC credentials..."
gcloud auth application-default set-quota-project "$PROJECT" --quiet

echo "Successfully switched gcloud profile to '$PROFILE' and updated ADC credentials."
