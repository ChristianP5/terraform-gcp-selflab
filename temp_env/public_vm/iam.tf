locals {
  effective_roles = [for k, v in var.custom_assign_iam_roles : k if v.scope == "project"]
  # ["roles/editor", "roles/viewer"]

  effective_bindings = { for role in local.effective_roles : role => [for sa_index, sa_object in google_service_account.primary_sa : "serviceAccount:${sa_object.email}" if contains(var.custom_assign_iam_roles[role].effective_vm_index, sa_index)] }
  # {
  #   "roldes/editor" = ["...@...com", "...@...com"],
  #   "roles/viewer"  = ["...@...com"]
  # }
}

resource "google_project_iam_binding" "iam_binding" {
  for_each = local.effective_bindings
  project  = "c-gcp-project"
  role     = each.key

  members = each.value
}