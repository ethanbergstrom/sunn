# Automatic Variables
variable "region" {
}

variable "tenancy_ocid" {
}

variable "compartment_ocid" {
}

# Defaulted Variables
variable "devops_compartment_description" {
    default = "Function Deployment Pipeline"
}

variable "functions_compartment_description" {
    default = "Functions"
}
