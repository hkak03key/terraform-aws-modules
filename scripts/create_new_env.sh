#!/usr/bin/env bash
set -eo pipefail

cat << EOS 
=========================================
terraform環境の自動セットアップスクリプト
=========================================
EOS

#=================================
echo "check app exists..."
check_app_exists () {
  if [ $(which $1) ]; then
    echo "$1 exists."
  else
    echo "$1 does not exist. please install."
    exit 1
  fi
}

check_app_exists jq
check_app_exists tfenv
check_app_exists python


TERRAFORM_DIR=$(cd $(dirname $0)/../terraform; pwd)
printf "terraform dir: %s\n\n" "$TERRAFORM_DIR"

if [ $(find $TERRAFORM_DIR -maxdepth 1 -name "*.tf" | wc -l) -ne 0 ]; then 
  echo "[ERROR] $TERRAFORM_DIR/terraform: .tf File exists";
  exit 1
elif [ -d $TERRAFORM_DIR/environments ]; then
  MULTIPLE_ENVS=true
  printf "複数環境を検知しました。\n"
else
  cat << EOS 
----------------------------------
このリポジトリにterraform環境を構築するのは初めてのようです。
複数環境に対応させるディレクトリ構成にしますか？
この場合、terraform/environments/{aws account name} に新規リソースが作成されます。

EOS
  while :
  do
    read -p "(y/n) > " TEMP
      case "$TEMP" in
        [yY]*) MULTIPLE_ENVS=true; break;;
        [nN]*) MULTIPLE_ENVS=false; break;;
        *) continue;;
      esac
  done
fi
printf "multiple envs: %s\n\n" "$MULTIPLE_ENVS"


TERRAFORM_DEFAULT_VERSION=$(tfenv list-remote | grep -v "beta" | grep -v "alpha" | grep -v "rc" | sort -V -r | head -n 1)
cat << EOS 
----------------------------------
今回作成するterraform環境のバージョンを指定してください。

default: $TERRAFORM_DEFAULT_VERSION （最新版）
EOS
read -p "> " TERRAFORM_VERSION

TERRAFORM_VERSION=${TERRAFORM_VERSION:-$TERRAFORM_DEFAULT_VERSION}
printf "terraform version: %s\n\n" "$TERRAFORM_VERSION"



cat << EOS 
----------------------------------
aws account名を指定してください。
これは、backend用s3/dynamodbのリソース名に利用され、variable.tfにも保存されます。
複数環境を本リポジトリで管理する場合は、環境用ディレクトリ名にも利用されます。

使用可能文字: [0-9|a-z|-] （末尾にハイフンを付けないでください）
EOS
sed_exp () {
  if [ "$(sed --version 1> /dev/null 2> /dev/null; echo $?)" == "0" ]; then
    # GNU
    sed -r $*
  else
    # BSD
    sed -E $*
  fi
}
export -f sed_exp

while :
do
  read -p "> " ACCOUNT_NAME
  if [ "$ACCOUNT_NAME" == "" ]; then
    echo "aws account名を指定してください。"
    continue
  elif [ $(echo $ACCOUNT_NAME | sed_exp "s/[0-9|a-z|-]//g" | wc -w) -ne 0 ]; then
    echo "使用できない文字が使用されています。"
    continue
  elif [ $(echo $ACCOUNT_NAME | grep -E "\-$" | wc -w) -ne 0 ]; then
    echo "末尾にハイフンが使用されています。"
    continue
  else
    break
  fi
done
printf "aws account名: %s\n\n" "$ACCOUNT_NAME"


cat << EOS 
----------------------------------
ci/cdで利用するaws profile名を指定してください。
これは、provider.tfとbackend.tfに利用されます。
EOS
read -p "> " TERRAFORM_AWS_PROFILE
printf "aws profile名: %s\n\n" "$TERRAFORM_AWS_PROFILE"


cat << EOS 
----------------------------------
backendリソースを作成しstateファイルをs3にアップロードするために、認証情報が必要です。
手元にcredentials.csvがある場合はそのpathを入力してください。

認証情報を、既に先程指定したprofile名で保存した場合は何も入力せずに続行して下さい。

【注意】terraform用のiam userは強力な権限を持っている可能性が高く、手元の環境に残しておくのは非推奨です。
EOS
read -p "> " AWS_CREDENTIALS_FILE
if [ -z "$AWS_CREDENTIALS_FILE" ]; then
  printf "credentials fileは指定されませんでした。\n先に指定されたaws profile名を参照します。\n\n"
else
  AWS_CREDENTIALS_FILE="${AWS_CREDENTIALS_FILE/#~/$HOME}"
  printf "credentials file: %s\n\n" "$AWS_CREDENTIALS_FILE"
fi


TERRAFORM_DEFAULT_AWS_REGION=ap-northeast-1
cat << EOS 
----------------------------------
aws regionを指定してください。
default: $TERRAFORM_DEFAULT_AWS_REGION
EOS
read -p "> " TERRAFORM_AWS_REGION
TERRAFORM_AWS_REGION=${TERRAFORM_AWS_REGION:-$TERRAFORM_DEFAULT_AWS_REGION}
printf "aws region: %s\n\n" "$TERRAFORM_AWS_REGION"


TERRAFORM_DEFAULT_BACKEND_S3_BUCKET=$ACCOUNT_NAME-terraform
cat << EOS 
----------------------------------
remote stateファイルを保存するs3 bucketを作成します。
bucket名を指定してください。
default: $TERRAFORM_DEFAULT_BACKEND_S3_BUCKET
EOS
read -p "> " TERRAFORM_BACKEND_S3_BUCKET
TERRAFORM_BACKEND_S3_BUCKET=${TERRAFORM_BACKEND_S3_BUCKET:-$TERRAFORM_DEFAULT_BACKEND_S3_BUCKET}
printf "remote state s3 bucket name: %s\n\n" "$TERRAFORM_BACKEND_S3_BUCKET"


TERRAFORM_DEFAULT_BACKEND_S3_KEY=terraform.state
cat << EOS 
----------------------------------
remote stateファイル名を指定してください。
default: $TERRAFORM_DEFAULT_BACKEND_S3_KEY
EOS
read -p "> " TERRAFORM_BACKEND_S3_KEY
TERRAFORM_BACKEND_S3_KEY=${TERRAFORM_BACKEND_S3_KEY:-$TERRAFORM_DEFAULT_BACKEND_S3_KEY}
printf "remote state s3 object name: %s\n\n" "$TERRAFORM_BACKEND_S3_KEY"


TERRAFORM_DEFAULT_BACKEND_DYNAMODB_TABLE=$ACCOUNT_NAME-terraform-lock
cat << EOS 
----------------------------------
remote stateの排他処理に必要となるdynamodb tableを作成します。
table名を指定してください。
default: $TERRAFORM_DEFAULT_BACKEND_DYNAMODB_TABLE
EOS
read -p "> " TERRAFORM_BACKEND_DYNAMODB_TABLE
TERRAFORM_BACKEND_DYNAMODB_TABLE=${TERRAFORM_BACKEND_DYNAMODB_TABLE:-$TERRAFORM_DEFAULT_BACKEND_DYNAMODB_TABLE}
printf "remote state dynamodb table: %s\n\n" "$TERRAFORM_BACKEND_DYNAMODB_TABLE"


#=================================
echo "install and activate terraform $TERRAFORM_VERSION..."
tfenv install $TERRAFORM_VERSION
tfenv use $TERRAFORM_VERSION


#=================================
TERRAFORM_TEMPLATE_DIR=$TERRAFORM_DIR/.base_template
TERRAFORM_NEW_ENV_DIR=$TERRAFORM_DIR$(if "${MULTIPLE_ENVS}"; then echo "/environments/$ACCOUNT_NAME"; else echo ""; fi)


#=================================
echo "put template to $TERRAFORM_NEW_ENV_DIR..."
if [ ! -d $TERRAFORM_NEW_ENV_DIR ]; then
  mkdir -p $TERRAFORM_NEW_ENV_DIR
fi

if [ $(find $TERRAFORM_NEW_ENV_DIR -maxdepth 1 -name "*.tf" | wc -l) -ne 0 ]; then 
  echo "[ERROR] $TERRAFORM_NEW_ENV_DIR: .tf File exists";
  exit 1
fi

find $TERRAFORM_TEMPLATE_DIR -maxdepth 1 -name "*.tf" -exec cp {} $TERRAFORM_NEW_ENV_DIR \;


#=================================
echo "replace .tf string..."
# stateはlocalやvarを参照できないため、スクリプトを直接文字列置換する必要がある

cd $TERRAFORM_NEW_ENV_DIR

sed_overwrite () {
  if [ "$(sed --version 1> /dev/null 2> /dev/null; echo $?)" == "0" ]; then
    # GNU
    sed -r -i $*
  else
    # BSD
    sed -E -i "" $*
  fi
}

export -f sed_overwrite

find . -maxdepth 1 -name "*.tf" -exec bash -c "sed_overwrite \"s/%BACKEND_S3_BUCKET%/$TERRAFORM_BACKEND_S3_BUCKET/g\" {}" \;
find . -maxdepth 1 -name "*.tf" -exec bash -c "sed_overwrite \"s/%BACKEND_S3_KEY%/$TERRAFORM_BACKEND_S3_KEY/g\" {}" \;
find . -maxdepth 1 -name "*.tf" -exec bash -c "sed_overwrite \"s/%BACKEND_DYNAMODB_TABLE%/$TERRAFORM_BACKEND_DYNAMODB_TABLE/g\" {}" \;
find . -maxdepth 1 -name "*.tf" -exec bash -c "sed_overwrite \"s/%AWS_PROFILE%/$TERRAFORM_AWS_PROFILE/g\" {}" \;
find . -maxdepth 1 -name "*.tf" -exec bash -c "sed_overwrite \"s/%AWS_REGION%/$TERRAFORM_AWS_REGION/g\" {}" \;
find . -maxdepth 1 -name "*.tf" -exec bash -c "sed_overwrite \"s/%ACCOUNT_NAME%/$ACCOUNT_NAME/g\" {}" \;
find . -maxdepth 1 -name "*.tf" -exec bash -c "sed_overwrite \"s/%TERRAFORM_VERSION%/$TERRAFORM_VERSION/g\" {}" \;


#=================================
echo "create backend resources..."

if [ ! -z "$AWS_CREDENTIALS_FILE" ]; then
  echo "  read credentials file..."
  
  CRED_JSON=$(cat $AWS_CREDENTIALS_FILE | python -c "import sys, json; print( json.dumps({k: v for k, v in zip(*(l.rstrip().split(',') for l in sys.stdin.readlines()))}));")
  # deployで利用するのでexport
  export AWS_ACCESS_KEY_ID=$(echo $CRED_JSON | jq -r '."Access key ID"')
  export AWS_SECRET_ACCESS_KEY=$(echo $CRED_JSON | jq -r '."Secret access key"')
  export AWS_DEFAULT_REGION=$TERRAFORM_AWS_REGION
fi

echo "  deploy..."
terraform init
terraform apply


#=================================
echo "enable remote backend..."
# comment in
sed_overwrite "s/^#[[:space:]]//g" $TERRAFORM_NEW_ENV_DIR/backend.tf

terraform fmt
terraform init
terraform plan

echo "end."

