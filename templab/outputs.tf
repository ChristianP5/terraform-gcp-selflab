# output "buckets" {
#   value = local.buckets
# }

# output "objects" {
#   value = local.objects
# }

output "secret_value" {
  value = data.google_secret_manager_secret_version_access.secret_value.secret_data
  sensitive = true
}