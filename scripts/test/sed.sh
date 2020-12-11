#!/usr/bin/env bash
set -eo pipefail

trap 'rm -rf "$TEST_DIR"' EXIT
TEST_DIR=$(mktemp -d /tmp/tmp.XXXXXXXXXX)

TERRAFORM_DIR=$(cd $(dirname $0)/../terraform; pwd)
TERRAFORM_TEMPLATE_DIR=$TERRAFORM_DIR/.base_template

find $TERRAFORM_TEMPLATE_DIR -maxdepth 1 -name "*.tf" -exec cp {} $TEST_DIR \;

sed_overwrite () {
  if [ "$(sed --version 1> /dev/null 2> /dev/null; echo $?)" == "0" ]; then
    sed -r -i $*
  else
    sed -E -i "" $*
  fi
}
export -f sed_overwrite

cd $TEST_DIR
find . -name "*.tf" -exec bash -c "sed_overwrite \"s/%BACKEND_S3_BUCKET%/TERRAFORM_BACKEND_S3_BUCKET/g\" {}" \;
find . -name "*.tf" -exec bash -c "sed_overwrite \"s/%BACKEND_S3_KEY%/TERRAFORM_BACKEND_S3_KEY/g\" {}" \;
find . -name "*.tf" -exec bash -c "sed_overwrite \"s/%BACKEND_DYNAMODB_TABLE%/TERRAFORM_BACKEND_DYNAMODB_TABLE/g\" {}" \;
find . -name "*.tf" -exec bash -c "sed_overwrite \"s/%AWS_PROFILE%/TERRAFORM_AWS_PROFILE/g\" {}" \;
find . -name "*.tf" -exec bash -c "sed_overwrite \"s/%AWS_REGION%/TERRAFORM_AWS_REGION/g\" {}" \;
find . -name "*.tf" -exec bash -c "sed_overwrite \"s/%ACCOUNT_NAME%/ACCOUNT_NAME/g\" {}" \;
find . -name "*.tf" -exec bash -c "sed_overwrite \"s/%TERRAFORM_VERSION%/TERRAFORM_VERSION/g\" {}" \;
sed_overwrite "s/^#[[:space:]]//g" $TEST_DIR/backend.tf

cat $TEST_DIR/versions.tf
cat $TEST_DIR/backend.tf



