allow_http         = true
allow_https        = true
os                 = "Debian"
allow_custom_ports = ["8081", "8082", "8083", "9090", "9093", "3000", "9100"]
vm_count           = 2
allow_custom_labels = {
  "prom-target" : "node"
}

custom_assign_iam_roles = {
  "roles/compute.viewer" : {
    effective_vm_index : [0]
    scope : "project"
  }
  "roles/storage.viewer": {
    effective_vm_index : [0,1]
    scope : "project"
  }
}