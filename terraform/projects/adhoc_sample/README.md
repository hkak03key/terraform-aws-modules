# adhoc-sample
## 概要
adhocにクエリを叩くためのsample project。

### s3 bucket
ショットでデータを出すのに利用する `${var.account_name}-adhoc-sample-workfiles` バケットと、adhocなETL領域である `${var.account_name}-adhoc-sample-etl` バケットが存在する。
workfilesバケット上のオブジェクトは32日で失効する。

### databricks role
databricksで利用するIAM roleとして `${var.account_name}-adhoc-sample-databricks-role` を作成している。
databricksに登録するcross account用roleにpass role可能なroleとして `${var.account_name}-*-databricks-role` を追加しておくこと。

### readsh user
redashで利用するIAM userとして、 `${var.account_name}-adhoc-sample-redash-user` を作成している。

## 備考
その性質上、責任分界点が曖昧な権限になりがちである。
「他projectから読んではならないデータ」をこのprojectで扱わないこと。
また、bizに定常的に貢献できるようなsystemになった場合は、別途projectを切りproduct化することが望ましい。
