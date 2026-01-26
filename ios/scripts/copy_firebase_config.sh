#!/bin/bash

# Script to copy the correct GoogleService-Info.plist based on the build configuration
# This script should be added as a Build Phase in Xcode (Run Script)

echo "Checking build configuration: ${CONFIGURATION}"

# Determine the flavor from the configuration name
# Configuration names are like: Debug-prod, Release-prod, Debug-uat, Release-uat
if [[ "${CONFIGURATION}" == *"-uat"* ]] || [[ "${CONFIGURATION}" == *"uat"* ]]; then
    FLAVOR="uat"
elif [[ "${CONFIGURATION}" == *"-prod"* ]] || [[ "${CONFIGURATION}" == *"prod"* ]]; then
    FLAVOR="prod"
else
    # Default to prod for standard Debug/Release configurations
    FLAVOR="prod"
fi

echo "Using flavor: ${FLAVOR}"

# Path to the flavor-specific GoogleService-Info.plist
PLIST_SOURCE="${PROJECT_DIR}/config/${FLAVOR}/GoogleService-Info.plist"
PLIST_DESTINATION="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"

echo "Copying from: ${PLIST_SOURCE}"
echo "Copying to: ${PLIST_DESTINATION}"

if [ -f "${PLIST_SOURCE}" ]; then
    cp "${PLIST_SOURCE}" "${PLIST_DESTINATION}"
    echo "Successfully copied GoogleService-Info.plist for ${FLAVOR}"
else
    echo "error: GoogleService-Info.plist not found at ${PLIST_SOURCE}"
    exit 1
fi
