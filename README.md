# terraform-skeleton
terraform環境を迅速に作成し、OOP的に構成するための雛形リポジトリ

## 使い方
- jqとtfenvをインストールしてください。
- `account_name` を決定してください。これは、bucket名のprefixになります。
例えば、defaultのterraform backend用s3 bucket名は `${account_name}-terraform` となります。
- deployするために、awsのcredentials.csvをダウンロードしてください。
このとき、`~/.aws/credentials` に設定する必要はありません。
- scripts/create_new_env.sh を実行します。対話的スクリプトなので説明に沿って進めてください。
