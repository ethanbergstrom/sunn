resource "random_uuid" "stack_compartment_name" {
}

resource "oci_identity_compartment" "stack_compartment" {
    compartment_id = var.compartment_ocid
    name = random_uuid.stack_compartment_name.result
    description = var.stack_compartment_description
}

module "oci-nosql" {
  source = "./modules/oci-nosql"
  compartment_ocid = oci_identity_compartment.stack_compartment.id
}

module "oci-devops-functions" {
  source = "./modules/oci-devops-functions"
  compartment_ocid = oci_identity_compartment.stack_compartment.id
}

# module "oci-functions" {
#   source = "./modules/oci-functions"
#   compartment_ocid = oci_identity_compartment.stack_compartment.id
# }

# output "dashboard_url" {
#   value = replace("${oci_database_autonomous_database.strava_autonomous_database.connection_urls.0.sql_dev_web_url}admin/_sdw/dashboards/?name=Strava%20Dashboard%20Powered%20by%20Oracle%20REST%20Data%20Services","sql-developer","")
# }

# output "sdw_url" {
#   value = oci_database_autonomous_database.strava_autonomous_database.connection_urls.0.sql_dev_web_url
# }