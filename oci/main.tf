resource "random_uuid" "devops_compartment_name" {
}

resource "random_uuid" "functions_compartment_name" {
}

resource "oci_identity_compartment" "devops_compartment" {
    compartment_id = var.compartment_ocid
    name = random_uuid.devops_compartment_name.result
    description = var.devops_compartment_description
}

resource "oci_identity_compartment" "functions_compartment" {
    compartment_id = var.compartment_ocid
    name = random_uuid.functions_compartment_name.result
    description = var.functions_compartment_description
}

module "oci-devops-functions" {
  source = "./modules/oci-devops-functions"
  compartment_ocid = oci_identity_compartment.devops_compartment.id
}

module "oci-functions" {
  source = "./modules/oci-functions"
  compartment_ocid = oci_identity_compartment.functions_compartment.id
}

# output "dashboard_url" {
#   value = replace("${oci_database_autonomous_database.strava_autonomous_database.connection_urls.0.sql_dev_web_url}admin/_sdw/dashboards/?name=Strava%20Dashboard%20Powered%20by%20Oracle%20REST%20Data%20Services","sql-developer","")
# }

# output "sdw_url" {
#   value = oci_database_autonomous_database.strava_autonomous_database.connection_urls.0.sql_dev_web_url
# }