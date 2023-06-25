resource "random_uuid" "application_name" {
}

resource "oci_core_vcn" "function_vcn" {
  compartment_id = var.compartment_ocid
  cidr_blocks = [var.vcn_cidr_block]
}

resource "oci_core_network_security_group" "function_security_group" {
  compartment_id = var.compartment_ocid
  vcn_id = oci_core_vcn.function_vcn.id
}

resource "oci_core_internet_gateway" "function_gateway" {
  compartment_id = var.compartment_ocid
  vcn_id = oci_core_vcn.function_vcn.id
}

resource "oci_core_default_route_table" "function_default_route" {
  manage_default_resource_id = oci_core_vcn.function_vcn.default_route_table_id

  route_rules {
    description = "Default Route"
	  destination = "0.0.0.0/0"
	  network_entity_id = oci_core_internet_gateway.function_gateway.id
  }
}

resource "oci_core_subnet" "function_subnet" {
  compartment_id = var.compartment_ocid
  vcn_id = oci_core_vcn.function_vcn.id
  # Use the entire VCN
  cidr_block = var.vcn_cidr_block
}

resource "oci_functions_application" "function_application" {
  compartment_id = var.compartment_ocid
  display_name = random_uuid.application_name.result
  subnet_ids = [oci_core_subnet.function_subnet.id]
  # Set env vars for all functions
  config = var.config
}

resource "oci_functions_function" "enviroStore" {
  application_id = oci_functions_application.function_application.id
  display_name   = "enviroStore"
  memory_in_mbs  = "128"
}

resource "oci_functions_function" "enviroRetrieve" {
  application_id = oci_functions_application.function_application.id
  display_name   = "enviroRetrieve"
  memory_in_mbs  = "128"
}
