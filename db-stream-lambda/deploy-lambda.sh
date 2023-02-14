#
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

#!/usr/bin/env bash
###########################################################################################
# Purpose: This script packages the Lambda source code by:
#          1. Installing the python packages to a /lib directory
#          2. Compressing the files into a zip file
#          3. Optional - Uploading the zip file to an S3 bucket
# Usage:   ./deploy-lambda.sh \
#           --file_name [zip_file_name] \
#           --bucket [s3_bucket] \
#           --src_dir [src_dir]
# Example: ./deploy-lambda.sh \
#           --file_name db-stream-lambda.zip \
#           --bucket lambda-source-s3-bucket \
#           --src_dir ~/scp-exemption-solution/code/db-stream-lambda/src
###########################################################################################

usage="$(basename "$0") [-h] <--file_name s> [--bucket s] <--src_folder s> ---script to package lambda zip and upload to s3

where:
    -h  show this help text
    --file_name  <required> Lambda zip file
    --bucket  [optional] S3 bucket name for lambda source
    --src_dir <required> Lambda source directory"

if [[ $1 == "-h" ]]; then
  echo "$usage"
  exit 1
fi

file_name=${file_name:-none}
bucket=${bucket:-none}
src_dir=${src_dir:-none}

# read input parameters
while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare "$param"="$2"
        # echo $1 $2 // Optional to see the parameter:value result
   fi

  shift
done

if [ "$file_name" != "none" ] && [ "$src_dir" != "none" ]; then

  HERE="${PWD}" # absolute path to this file's folder
  DIST_FOLDER="$HERE/dist" # dist folder for the zip file if bucket is not provided
  TMP_FOLDER=~/tmp/sra-lambda-src # will be cleaned
  SRC_FOLDER=$src_dir

  # create /lib folder and install python packages
  mktemp -d $TMP_FOLDER # create the temp folder
  cp -r $SRC_FOLDER/* $TMP_FOLDER # copy lambda source to temp source folder
  pip3 install -t $TMP_FOLDER -r $TMP_FOLDER/requirements.txt

  # prepare the dist folder
  mktemp -d "$DIST_FOLDER" # create dist folder, if it doesn't exist
  cd "$DIST_FOLDER" || exit # change directory into dist folder
  rm -f "$file_name" # remove zip file, if exists

  # create zip file in the dist folder
  cd "$TMP_FOLDER" || exit # changed directory to temp folder
  zip -r -q "$DIST_FOLDER/$file_name" . -x .DS_Store # zip source with packages
  cd "$DIST_FOLDER" || exit  # change directory to dist folder

  echo "Removing $TMP_FOLDER"
  rm -rf $TMP_FOLDER

  if [[ "$bucket" != "none" ]]; then

    # upload the lambda zip file to S3
    aws s3api put-object --bucket "$bucket" --key "$file_name" --body "$file_name" &>response # upload zip file to S3
    cd "$HERE" || exit # return to the packaging directory

    echo "Lambda zip file: $file_name uploaded to $bucket"
    echo "Removing $DIST_FOLDER"
    rm -rf "$DIST_FOLDER"

  fi

else

  echo "$usage"

fi

exit 0