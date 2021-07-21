import json
import boto3
from distutils.util import strtobool
from email.utils import parseaddr
import string
import secrets
import os

def is_valid_mailaddr(string):
    result = parseaddr(string)
    return false if not len(result[1]) else (
        "@" in result[1]
    )

# TODO: unit test
def boto3_func_wrapper_for_truncate(func, kwargs, return_key, marker=None):
    _kwargs = kwargs.copy()
    if marker:
        _kwargs["Marker"] = marker
    response = func(**_kwargs)
    ret = response[return_key]
    if response["IsTruncated"]:
        if type(ret) == list:
            ret.extend(boto3_func_wrapper_for_truncate(func, kwargs, return_key, response["Marker"]))
        elif type(ret) == dict:
            ret.update(boto3_func_wrapper_for_truncate(func, kwargs, return_key, response["Marker"]))
    return ret


def collect_user_info(user_name):
    iam_client = boto3.client("iam")
    ret = {}

    try:
        iam_client.get_user(UserName=user_name)
    except iam_client.exceptions.NoSuchEntityException as e:
        print("user not found")
        return None

    ret["user_name"] = user_name
    kwargs = {"UserName": ret["user_name"]}
    tags = {x["Key"]: x["Value"] for x in boto3_func_wrapper_for_truncate(iam_client.list_user_tags, kwargs, "Tags")}

    mail_address = tags.get("MailAddress") if tags.get("MailAddress") else ret["user_name"]
    if not is_valid_mailaddr(mail_address):
        print("invalid mail address")
        return None

    ret["mail_address"] = mail_address
    ret["next_has_login_profile"] = strtobool(tags.get("LoginProfile")) if tags.get("LoginProfile") else None
    ret["next_has_access_key"] = strtobool(tags.get("AccessKey")) if tags.get("AccessKey") else None
    ret["curr_access_key_ids"] = [x.get("AccessKeyId") for x in boto3_func_wrapper_for_truncate(iam_client.list_access_keys, kwargs, "AccessKeyMetadata")]
    try:
        login_profile = iam_client.get_login_profile(**kwargs)
        ret["curr_has_login_profile"] = True
    except iam_client.exceptions.NoSuchEntityException as e:
        if e.response["Error"]["Message"] == "Login profile for {} not found".format(user_name):
            ret["curr_has_login_profile"] = False
        elif e.response["Error"]["Message"] == "Login Profile for User {} cannot be found.".format(user_name):
            ret["curr_has_login_profile"] = False
        else:
            raise e

    return ret


def configure_credentials(user_name, mail_address, curr_has_login_profile, next_has_login_profile, curr_access_key_ids, next_has_access_key):
    iam_client = boto3.client("iam")
    ret = {
            "user_name": user_name,
            "mail_address": mail_address,
        }

    if next_has_login_profile and (not curr_has_login_profile):
        print("create login_profile")
        size = 24
        chars = string.ascii_uppercase + string.ascii_lowercase + string.digits + "!@#$%^&*()_+-=[]{}|"
        password = "".join(secrets.choice(chars) for x in range(size))
        response = iam_client.create_login_profile(
            UserName = user_name,
            Password = password,
            PasswordResetRequired = True
        )
        ret["login_profile"] = {
                "status": "created",
                "password": password
            }

    elif (next_has_login_profile == False) and curr_has_login_profile:
        print("delete login_profile")
        response = iam_client.delete_login_profile(
            UserName = user_name
        )
        ret["login_profile"] = {
                "status": "deleted"
            }

    if next_has_access_key and (not len(curr_access_key_ids)):
        print("create access_key")
        response = iam_client.create_access_key(
            UserName = user_name
        )
        ret["access_key"] = {
                "status": "created",
                "access_keypair": {
                        "AccessKeyId": response["AccessKey"]["AccessKeyId"],
                        "SecretAccessKey": response["AccessKey"]["SecretAccessKey"]
                    }
                }

    elif (next_has_access_key == False) and len(curr_access_key_ids):
        print("delete access_keys")
        for key in curr_access_key_ids:
            response = iam_client.delete_access_key(
                AccessKeyId = key,
                UserName = user_name
            )
        ret["access_key"] = {
                "status": "deleted"
            }
    return ret


def send_email(source, to, subject, body):
    print("send mail from {} to {}".format(source, to))
    client = boto3.client("ses")

    response = client.send_email(
        Source=source,
        Destination={
            "ToAddresses": [
                to,
            ]
        },
        Message={
            "Subject": {
                "Data": subject,
            },
            "Body": {
                "Text": {
                    "Data": body,
                },
            }
        }
    )
    print(response)
    return response


def send_credentials_email(user_name, mail_address, login_profile=None, access_key=None):
    print("send_credentials_email")
    if (not login_profile) and (not access_key):
        print("not send mail.")
        return None

    account_id = boto3.client("sts").get_caller_identity().get("Account")
    body = """Hello,

Here is your aws credentials information.

aws account ID: {}
iam user name: {}
""".format(account_id, user_name)

    if login_profile:
        body += "------\n\n"
        if login_profile["status"] == "created":
            body += """Your password for console login was created.
password: {}

You can login at https://{}.signin.aws.amazon.com/console
""".format(login_profile["password"], account_id)
        elif login_profile["status"] == "deleted":
            body += "Your password for console login was deleted.\n"
    
    if access_key:
        body += "------\n\n"
        if access_key["status"] == "created":
            body += """Your access key for cli was created.
AccessKeyId: {}
SecretAccessKey: {}\n""".format(access_key["access_keypair"]["AccessKeyId"], access_key["access_keypair"]["SecretAccessKey"])
        elif login_profile["status"] == "deleted":
            body += "Your access key for cli was deleted.\n"

    body += """------\n\nThank you."""
    return send_email(os.environ.get("SEND_MAIL_ADDRESS"), mail_address, "aws credentials imformation", body)

def remove_credentials_info(configure_result):
    if configure_result.get("login_profile") and configure_result["login_profile"].get("password"):
        del configure_result["login_profile"]["password"]
    if configure_result.get("access_key") and configure_result["access_key"].get("access_keypair"):
        del configure_result["access_key"]["access_keypair"]
    return configure_result

def get_username(record):
    curr = record
    for index in ["Sns", "Message", "detail", "requestParameters", "userName"]:
        if type(curr) == str:
            curr = json.loads(curr)
        curr = curr[index]
    return curr

def proc(event):
    ret = []
    for record in event.get("Records"):
        user_name = get_username(record)
        user_info = collect_user_info(user_name)
        print(user_info)
        if not user_info:
            ret.append("invalid mail address.")
            continue

        configure_result = configure_credentials(**user_info)
        send_credentials_email(**configure_result)

        ret.append(remove_credentials_info(configure_result))
    return ret


def lambda_handler(event, context):
    results = proc(event)
    return {
        "statusCode": 200,
        "body": json.dumps(results)
    }

