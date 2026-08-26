variable "scenario" {
  type        = number
  description = <<-EOT
  This specifies the Scenario that will be used when loading the Infrastructure
  1 : NVA and ILB on a separate VPC Network than the Workload VMs, configured with VPC Network Peering
  2 : NVA and ILB is on the same VPC Network as the Workload VMs
  EOT
}