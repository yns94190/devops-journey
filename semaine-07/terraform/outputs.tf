output "vcn_id" {
  value = oci_core_vcn.main.id
}

output "subnet_id" {
  value = oci_core_subnet.main.id
}

output "internet_gateway_id" {
  value = oci_core_internet_gateway.main.id
}

output "route_table_id" {
  value = oci_core_route_table.main.id
}

output "security_list_id" {
  value = oci_core_security_list.main.id
}
