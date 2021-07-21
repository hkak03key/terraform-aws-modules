import aws_iam_user_credentials_manager as src
from moto import mock_iam, mock_sts
import boto3
import secrets
import string

valid_mailaddrs = [
    "test@sample.co.jp",
    "test+abc@gg.com",
]
invalid_mailaddrs = [
    "testsample.com",
    "test+abcgg.com",
]

def test_is_valid_mailaddr():
    for addr in valid_mailaddrs:
        assert src.is_valid_mailaddr(addr)
    for addr in invalid_mailaddrs:
        assert not src.is_valid_mailaddr(addr)

@mock_iam
def test_collect_user_info_mail_addr():
    iam_client = boto3.client("iam")

    iam_client.create_user(UserName=valid_mailaddrs[0])
    assert valid_mailaddrs[0] == src.collect_user_info(valid_mailaddrs[0])["mail_address"]

    # # comment out because tag_user() is not defined on moto
    # iam_client.tag_user(
    #     UserName=valid_mailaddrs[0],
    #     Tags=[
    #         {
    #             "Key": "MailAddress",
    #             "Value": valid_mailaddrs[1],
    #         },
    #     ]
    # )
    # assert valid_mailaddrs[1] == src.collect_user_info(valid_mailaddrs[0])["mail_address"]

    # # comment out because tag_user() is not defined on moto
    # iam_client.tag_user(
    #     UserName=valid_mailaddrs[0],
    #     Tags=[
    #         {
    #             "Key": "MailAddress",
    #             "Value": invalid_mailaddrs[0],
    #         },
    #     ]
    # )
    # assert None == src.collect_user_info(valid_mailaddrs[0])

    iam_client.create_user(UserName=invalid_mailaddrs[0])
    assert None == src.collect_user_info(invalid_mailaddrs[0])

    # # comment out because tag_user() is not defined on moto
    # iam_client.tag_user(
    #     UserName=invalid_mailaddrs[0],
    #     Tags=[
    #         {
    #             "Key": "MailAddress",
    #             "Value": invalid_mailaddrs[1],
    #         },
    #     ]
    # )
    # assert None == src.collect_user_info(invalid_mailaddrs[0])

    # # comment out because tag_user() is not defined on moto
    # iam_client.tag_user(
    #     UserName=invalid_mailaddrs[0],
    #     Tags=[
    #         {
    #             "Key": "MailAddress",
    #             "Value": valid_mailaddrs[1],
    #         },
    #     ]
    # )
    # assert valid_mailaddrs[1] == src.collect_user_info(invalid_mailaddrs[0])["mail_address"]

# @mock_iam
# def test_create_dummy_user():
#     user_info = {
#         "user_name": valid_mailaddrs[0],
#         "mail_address": valid_mailaddrs[1],
#     }
#     _create_dummy_user(user_name, mail_address, curr_has_login_profile, curr_access_key)
#     

@mock_iam
class DummyIamUser():
    def __init__(self, user_name, mail_address, curr_has_login_profile, next_has_login_profile, curr_has_access_key, next_has_access_key):
        self._iam_client = boto3.client("iam")
        self.user_name = user_name
        self.mail_address = mail_address
        self.curr_has_login_profile = curr_has_login_profile
        self.next_has_login_profile = next_has_login_profile
        self.curr_has_access_key = curr_has_access_key
        self.next_has_access_key = next_has_access_key
        self.curr_access_key_ids = []

    def __enter__(self):
        self._iam_client.create_user(UserName=self.user_name)
        if self.curr_has_login_profile:
            size = 24
            chars = string.ascii_uppercase + string.ascii_lowercase + string.digits + "!@#$%^&*()_+-=[]{}|"
            password = "".join(secrets.choice(chars) for x in range(size))
            self._iam_client.create_login_profile(
                UserName = self.user_name,
                Password = password,
                PasswordResetRequired = True
            )

        if self.curr_has_access_key:
            self.curr_access_key_ids = [
                self._iam_client.create_access_key(
                    UserName = self.user_name
                )["AccessKey"]["AccessKeyId"]]

        return self

    def __exit__(self, exception_type, exception_value, traceback):
        self._iam_client.delete_user(UserName=self.user_name)

    def create_user_info(self):
        return {
            "user_name": self.user_name,
            "mail_address": self.mail_address,
            "curr_has_login_profile": self.curr_has_login_profile,
            "next_has_login_profile": self.next_has_login_profile,
            "curr_access_key_ids": self.curr_access_key_ids,
            "next_has_access_key": self.next_has_access_key,
        }

@mock_iam
def test_check_has_login_profile():
    iam_client = boto3.client("iam")

@mock_iam
def test_dummy_iam_user():
    iam_client = boto3.client("iam")
    with DummyIamUser(**{
        "user_name": valid_mailaddrs[0],
        "mail_address": valid_mailaddrs[1],
        "curr_has_login_profile": 0,
        "next_has_login_profile": 0,
        "curr_has_access_key": 0,
        "next_has_access_key": 0,
    }) as user:
        user_info = user.create_user_info()
        try:
            iam_client.get_login_profile(**{"UserName": user.user_name})
        except iam_client.exceptions.NoSuchEntityException as e:
            assert e.response["Error"]["Message"] == "Login profile for {} not found".format(user.user_name)
        acccess_key_ids = [x.get("AccessKeyId") for x in src.boto3_func_wrapper_for_truncate(iam_client.list_access_keys, {"UserName": user.user_name}, "AccessKeyMetadata")]
        user_info = user.create_user_info()
        assert user_info["curr_access_key_ids"] == acccess_key_ids
        assert not user_info["next_has_login_profile"]
        assert not user_info["next_has_access_key"]

    with DummyIamUser(**{
        "user_name": valid_mailaddrs[0],
        "mail_address": valid_mailaddrs[1],
        "curr_has_login_profile": 0,
        "next_has_login_profile": 1,
        "curr_has_access_key": 0,
        "next_has_access_key": 1,
    }) as user:
        user_info = user.create_user_info()
        assert user_info["next_has_login_profile"]
        assert user_info["next_has_access_key"]

    with DummyIamUser(**{
        "user_name": valid_mailaddrs[0],
        "mail_address": valid_mailaddrs[1],
        "curr_has_login_profile": 0,
        "next_has_login_profile": 0,
        "curr_has_access_key": 1,
        "next_has_access_key": 0,
    }) as user:
        user_info = user.create_user_info()
        acccess_key_ids = [x.get("AccessKeyId") for x in src.boto3_func_wrapper_for_truncate(iam_client.list_access_keys, {"UserName": user.user_name}, "AccessKeyMetadata")]
        assert len(user_info["curr_access_key_ids"])
        assert set(user_info["curr_access_key_ids"]) == set(acccess_key_ids)

    with DummyIamUser(**{
        "user_name": valid_mailaddrs[0],
        "mail_address": valid_mailaddrs[1],
        "curr_has_login_profile": 1,
        "next_has_login_profile": 0,
        "curr_has_access_key": 0,
        "next_has_access_key": 0,
    }) as user:
        assert iam_client.get_login_profile(**{"UserName": user.user_name})


@mock_iam
def test_configure_credentials():
    iam_client = boto3.client("iam")

    with DummyIamUser(**{
        "user_name": valid_mailaddrs[0],
        "mail_address": valid_mailaddrs[1],
        "curr_has_login_profile": 0,
        "next_has_login_profile": 0,
        "curr_has_access_key": 0,
        "next_has_access_key": 0,
    }) as user:
        user_info = user.create_user_info()
        result = src.configure_credentials(**user_info)

        for i in ["user_name", "mail_address"]:
            assert result[i] == user_info[i]
        assert not "login_profile" in result
        assert not "access_key" in result

    with DummyIamUser(**{
        "user_name": valid_mailaddrs[0],
        "mail_address": valid_mailaddrs[1],
        "curr_has_login_profile": 0,
        "next_has_login_profile": 1,
        "curr_has_access_key": 0,
        "next_has_access_key": 0,
    }) as user:
        user_info = user.create_user_info()
        result = src.configure_credentials(**user_info)

        assert not "access_key" in result
        assert result["login_profile"]["status"] == "created"
        assert type(result["login_profile"]["password"]) == str

    with DummyIamUser(**{
        "user_name": valid_mailaddrs[0],
        "mail_address": valid_mailaddrs[1],
        "curr_has_login_profile": 0,
        "next_has_login_profile": 0,
        "curr_has_access_key": 0,
        "next_has_access_key": 1,
    }) as user:
        user_info = user.create_user_info()
        result = src.configure_credentials(**user_info)

        assert not "login_profile" in result
        assert result["access_key"]["status"] == "created"
        assert type(result["access_key"]["access_keypair"]["AccessKeyId"]) == str
        assert type(result["access_key"]["access_keypair"]["SecretAccessKey"]) == str

    with DummyIamUser(**{
        "user_name": valid_mailaddrs[0],
        "mail_address": valid_mailaddrs[1],
        "curr_has_login_profile": 1,
        "next_has_login_profile": 1,
        "curr_has_access_key": 1,
        "next_has_access_key": 1,
    }) as user:
        user_info = user.create_user_info()
        result = src.configure_credentials(**user_info)

        assert not "login_profile" in result
        assert not "access_key" in result

    with DummyIamUser(**{
        "user_name": valid_mailaddrs[0],
        "mail_address": valid_mailaddrs[1],
        "curr_has_login_profile": 1,
        "next_has_login_profile": 1,
        "curr_has_access_key": None,
        "next_has_access_key": None,
    }) as user:
        user_info = user.create_user_info()
        result = src.configure_credentials(**user_info)

        assert not "login_profile" in result
        assert not "access_key" in result

    with DummyIamUser(**{
        "user_name": valid_mailaddrs[0],
        "mail_address": valid_mailaddrs[1],
        "curr_has_login_profile": 1,
        "next_has_login_profile": 0,
        "curr_has_access_key": 0,
        "next_has_access_key": 0,
    }) as user:
        user_info = user.create_user_info()
        result = src.configure_credentials(**user_info)

        assert result["login_profile"]["status"] == "deleted"
        assert not "password" in result["login_profile"]

    with DummyIamUser(**{
        "user_name": valid_mailaddrs[0],
        "mail_address": valid_mailaddrs[1],
        "curr_has_login_profile": 0,
        "next_has_login_profile": 0,
        "curr_has_access_key": 1,
        "next_has_access_key": 0,
    }) as user:
        user_info = user.create_user_info()
        result = src.configure_credentials(**user_info)

        assert result["access_key"]["status"] == "deleted"
        assert not "access_keypair" in result["access_key"]


def test_remove_credentials_info():
    base_configure_result = {
            "user_name": "user_name",
            "mail_address": "mail_address"
        }

    configure_result = base_configure_result.copy()
    result = src.remove_credentials_info(configure_result)
    assert "user_name" in result
    assert "mail_address" in result

    configure_result = base_configure_result.copy()
    configure_result["login_profile"] = {
            "status": "created",
            "password": "password"
        }
    configure_result["access_key"] = {
            "status": "created",
            "access_keypair": {
                "AccessKeyId": "acccess_key_id",
                "SecretAccessKey": "secret_access_key"
            }
        }
    result = src.remove_credentials_info(configure_result)
    assert "user_name" in result
    assert "mail_address" in result
    assert "login_profile" in result
    assert not "password" in result["login_profile"]
    assert "access_key" in result
    assert not "access_keypair" in result["access_key"]

    configure_result = base_configure_result.copy()
    configure_result["login_profile"] = {
            "status": "deleted",
        }
    configure_result["access_key"] = {
            "status": "deleted",
        }
    result = src.remove_credentials_info(configure_result)
    assert "user_name" in result
    assert "mail_address" in result
    assert "login_profile" in result
    assert not "password" in result["login_profile"]
    assert "access_key" in result
    assert not "access_keypair" in result["access_key"]

