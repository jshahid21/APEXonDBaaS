
output "URL : APEX (PublicIP)" {
  value = ["https://${data.oci_core_vnic.InstanceVnic.public_ip_address}:${var.com_port}/ords/${var.target_db_name}/"]
}
