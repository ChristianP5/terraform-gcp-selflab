locals {
  prefix = "templab"
  buckets_config = {
    "operations_bucket" = {
      name          = "${local.prefix}-operations-bucket"
      location      = "ASIA-SOUTHEAST2"
      storage_class = "STANDARD"
      objects = [
        {
          name    = "operations.txt"
          content = "This is the operations bucket."
        },
        {
          name    = "operation_notes.txt"
          content = "This is the Notes of the operations bucket."
        }
      ]
    }

    "development_bucket" = {
      name          = "${local.prefix}-development-bucket"
      location      = "ASIA-SOUTHEAST2"
      storage_class = "STANDARD"
      objects = [
        {
          name    = "development.txt"
          content = "This is the development bucket."
        },
        {
          name    = "development_notes.txt"
          content = "This is the Notes of the development bucket."
        }
      ]
    }
  }

  buckets = [for bucket in local.buckets_config : bucket.name]
  objects = tomap({ for k, v in local.buckets_config : k => { for object in v.objects : object.name => object.content } })
  buckets_standard_lifecycle_rules = [
    {
      matches_storage_class = ["COLDLINE"]
      size_below_bytes      = null
      action                = "Delete"
    },
    {
      matches_storage_class = ["ARCHIVE"]
      size_below_bytes      = 1000000000
      action                = "Delete"
    }
  ]
}

resource "google_storage_bucket" "primary_buckets" {
  for_each                    = local.buckets_config
  name                        = each.value.name
  location                    = each.value.location
  force_destroy               = true
  uniform_bucket_level_access = true

  dynamic "lifecycle_rule" {
    for_each = local.buckets_standard_lifecycle_rules
    iterator = item
    content {
      condition {
        matches_storage_class = item.value.matches_storage_class
      }
      action {
        type = item.value.action
      }
    }
  }

}


resource "google_storage_bucket_object" "operations_files" {
  for_each = local.objects["operations_bucket"]
  name     = each.key
  content  = each.value
  bucket   = google_storage_bucket.primary_buckets["operations_bucket"].id
}

resource "google_storage_bucket_object" "development_files" {
  for_each = local.objects["development_bucket"]
  name     = each.key
  content  = each.value
  bucket   = google_storage_bucket.primary_buckets["development_bucket"].id
}


# resource "google_storage_bucket_object" "module_file" {
#   name     = "module_file.txt"
#   content  = "This is the module file."
#   bucket   = google_storage_bucket.primary_buckets["development_bucket"].id
# }

module "gcs_object_module" {
  source    = "./modules/gcs_object_module"
  bucket_name = google_storage_bucket.primary_buckets["development_bucket"].name
}

moved {
  from = google_storage_bucket_object.module_file
  to = module.gcs_object_module.google_storage_bucket_object.module_file
}