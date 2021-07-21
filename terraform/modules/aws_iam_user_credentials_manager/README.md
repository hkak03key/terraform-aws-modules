# aws iam user credentials manager
## 概要
iam userのtagの状態によって自動でcredentialsを発行・削除します。

## 前提条件
- cloudtrailがonであり、且つ、cloudwatch logに配信していること

## 送信メールアドレスの設定
moduleのvariable "email_address" に有効なメールアドレスを設定してください。
moduleがdeployされると確認メールが飛ぶので、sesを有効化してください。

## credentialsの作成・削除のための設定
### 送信先情報
作成結果はメールで送信します。
そのため、以下の条件を満たさない場合は、本moduleは動作しません。
- `tag "MailAddress"` が設定されている場合は、値に有効なメールアドレスが設定されている
- `tag "MailAddress"` が設定されていない場合は、iam user名に有効なメールアドレスが設定されている

### コンソールログイン用パスワード
コンソールログイン用パスワードの発行可否は、 `tag "LoginProfile"` で制御します。
tagの値はbool値を取ることとします。
文字列からbool値の変換はpythonの関数 `distutils.util.strtobool()`で行っています。
tagが設定されていない場合は動作しません。

### アクセスキー
アクセスキーの発行可否は、 `tag "AccessKey"` で制御します。
tagの値はbool値を取ることとします。
文字列からbool値の変換はpythonの関数 `distutils.util.strtobool()`で行っています。
tagが設定されていない場合は動作しません。

## events発火条件と動作
1. 新規のユーザが作成された時
  - 該当するAWS event
    - CreateUser
  - 動作
    - コンソールログイン用パスワード、アクセスキーともに発行するかを評価します。
1. credentialsをリセットしたい時
  - 該当するAWS event
    - DeleteLoginProfile
    - DeleteAccessKey
  - 動作
    - 削除されたcredentialsの種類に対して再発行を行います。
1. credentialsの作成条件を変更したい時
  - 該当するAWS event
    - TagUser
    - UntagUser
  - 動作
    - 作成条件を変更されたcredentialsの種類に対して発行・削除を行います。

## 制限
以下のリソースはus-east-1 regionに作成されます。
- cloudwatch event
- sns

これらのリソースはIAMの変更を検知し、lambdaを発火させるために必要で。
