moved {
  from = google_compute_instance.nva_instances["a"]
  to   = google_compute_instance.internet_inbound_nva_instances["a"]
}

moved {
  from = google_compute_instance.nva_instances["b"]
  to   = google_compute_instance.internet_inbound_nva_instances["b"]
}