
# #---------------------------------
# # datalake_sample
# module "datalake_sample" {
#   source      = "./projects/datalake_sample"
#   account_name = var.account_name
# }

# #---------------------------------
# # adhoc
# module "adhoc_sample" {
#   source      = "../../projects/adhoc_sample"
#   account_name = var.account_name
#   external_policies = {
#     databricks_role = [
#       module.datalake_sample.s3_read_bucket_iam_policies[""],
#     ]
#     redash_user = [
#       module.datalake_sample.s3_read_bucket_iam_policies[""],
#     ]
#   }
# }

