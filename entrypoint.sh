#!/bin/sh

# Backwards compatibility mapping
if [ -z $FACTORIO_USER ]; then :; else
  INPUT_FACTORIO_USER=$FACTORIO_USER
fi
if [ -z $FACTORIO_PASSWORD ]; then :; else
  INPUT_FACTORIO_PASSWORD=$FACTORIO_PASSWORD
fi

if [ "${GITHUB_REF}" == "${GITHUB_REF#refs/tags/}" ]; then
  echo "This is not a tagged push." 1>&2
  exit 78
fi

TAG="${GITHUB_REF#refs/tags/}"

if ! echo "${TAG}" | grep -qE '^[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+$'; then
  echo "Bad version in tag, needs to be %u.%u.%u" 1>&2
  exit 1
fi

export PACKAGE_NAME=$(jq -r .name info.json)
export PACKAGE_VERSION=$(jq -r .version info.json)
export PACKAGE_FULL_NAME=$PACKAGE_NAME\_$PACKAGE_VERSION
export PACKAGE_FILE="$PACKAGE_FULL_NAME.zip"

if ! [[ ${PACKAGE_VERSION} == "${TAG}" ]]; then
  echo "Tag version (${TAG}) doesn't match info.json version (${PACKAGE_VERSION}) (or info.json is invalid)." 1>&2
  exit 1
fi

if ! grep -q "$PACKAGE_VERSION" changelog.txt; then
  echo "ERROR: Changelog was not compiled." 1>&2
  exit 1
fi

export DIST_DIR=dist

export FILE_PATH=$DIST_DIR/$PACKAGE_FILE

export FILESIZE=$(stat -c "%s" "${FILE_PATH}")

echo ${FILE_PATH} ${FILESIZE}

CSRF=$(curl -sSL \
  -b cookiejar.txt \
  -c cookiejar.txt \
  https://mods.factorio.com/login |
  grep csrf_token |
  sed -r -e 's/.*value="(.*)".*/\1/')

# Authenticate with the credential secrets and the CSRF token, getting a session cookie for the authorized user
curl -sSL \
  -b cookiejar.txt \
  -c cookiejar.txt \
  -F "csrf_token=${CSRF}" \
  -F "username=${INPUT_FACTORIO_USER}" \
  -F "password=${INPUT_FACTORIO_PASSWORD}" \
  -o /dev/null \
  https://mods.factorio.com/login

# Query the mod info, verify the version number we're trying to push doesn't already exist
curl -sSL \
  -b cookiejar.txt \
  -c cookiejar.txt \
  -s "https://mods.factorio.com/api/mods/${PACKAGE_NAME}/full" |
  jq --arg new_version ${PACKAGE_VERSION} -e '.releases[] | select(.version == $new_version)'
STATUS_CODE=$?
if [[ $STATUS_CODE -ne 4 ]]; then
  echo "Release already exists, skipping"
  exit 78
fi

echo "Release doesn't exist for ${PACKAGE_VERSION}, uploading"

# Load the upload form, getting an upload token
UPLOAD_TOKEN=$(curl -sSL \
  -b cookiejar.txt \
  -c cookiejar.txt \
  "https://mods.factorio.com/mod/${PACKAGE_NAME}/downloads/edit" |
  grep token |
  sed -r -e "s/.*token: '(.*)'.*/\1/")

if [[ -z ${UPLOAD_TOKEN} ]]; then
  echo "Couldn't get an upload token, failed"
  exit 1
fi

# Upload the file, getting back a response with details to send in the final form submission to complete the upload
UPLOAD_RESULT=$(curl -sSL \
  -b cookiejar.txt \
  -c cookiejar.txt \
  -F "file=@${FILE_PATH};type=application/x-zip-compressed" \
  "https://direct.mods-data.factorio.com/upload/mod/${UPLOAD_TOKEN}")

# Parse 'em and stat the file for the form fields
CHANGELOG=$(echo "${UPLOAD_RESULT}" | jq -r '@uri "\(.changelog)"')
INFO=$(echo "${UPLOAD_RESULT}" | jq -r '@uri "\(.info)"')
FILENAME=$(echo "${UPLOAD_RESULT}" | jq -r '.filename')
THUMBNAIL=$(echo "${UPLOAD_RESULT}" | jq -r '.thumbnail // empty')

if [[ ${FILENAME} == "null" ]] || [[ -z ${FILENAME} ]]; then
  echo "Upload failed"
  exit 1
fi

echo "Uploaded ${PACKAGE_NAME}_${PACKAGE_VERSION}.zip to ${FILENAME}, submitting as new version"
# Post the form, completing the release
HTTP_RESPONSE=$(curl --write-out "HTTPSTATUS:%{http_code}" \
  -sSL \
  -b cookiejar.txt \
  -c cookiejar.txt \
  -XPOST \
  -d "file=&info_json=${INFO}&changelog=${CHANGELOG}&filename=${FILENAME}&file_size=${FILESIZE}&thumbnail=${THUMBNAIL}" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -o /dev/null \
  "https://mods.factorio.com/mod/${PACKAGE_NAME}/downloads/edit")
HTTP_STATUS=$(echo $HTTP_RESPONSE | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

if [ $HTTP_STATUS -eq 200 ]; then
  echo "Release upload completed"
else
  echo "Failed to upload release"
  exit 1
fi
