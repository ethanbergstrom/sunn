# Automatic Variables
variable "region" {
}

variable "tenancy_ocid" {
}

variable "compartment_ocid" {
}

# Defaulted Variables
variable "stack_compartment_description" {
    default = "Enviro Stack"
}

variable "database_compartment_description" {
    default = "Database"
}

variable "devops_compartment_description" {
    default = "Function Deployment Pipeline"
}

variable "functions_compartment_description" {
    default = "Functions"
}
