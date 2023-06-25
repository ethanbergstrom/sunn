variable "compartment_ocid" {
}

variable "vcn_cidr_block" {
    default = "192.168.0.0/16"
}

variable "config" {
  type = map(string) 
  default = {
    "TABLE_NAME" = "enviro"
    "COMPARTMENT_OCID" = var.compartment_ocid
  }
}