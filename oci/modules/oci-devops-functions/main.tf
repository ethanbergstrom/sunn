resource "random_string" "topic_name" {
  length  = 10
  special = false
}

resource "random_string" "project_name" {
  length  = 10
  special = false
}

resource "oci_ons_notification_topic" "notification_topic" {
  compartment_id = var.compartment_ocid
  name = random_string.topic_name.result
}

resource "oci_devops_project" "project" {
  compartment_id = var.compartment_ocid
  name = random_string.project_name.result
  notification_config {
    topic_id = oci_ons_notification_topic.notification_topic.id
  }
}

# resource "oci_devops_deploy_environment" "function" {
#   deploy_environment_type = "FUNCTION"
#   project_id = oci_devops_project.project.id
#   function_id = "function1"
# }


# output "dashboard_url" {
#   value = replace("${oci_database_autonomous_database.strava_autonomous_database.connection_urls.0.sql_dev_web_url}admin/_sdw/dashboards/?name=Strava%20Dashboard%20Powered%20by%20Oracle%20REST%20Data%20Services","sql-developer","")
# }

# output "sdw_url" {
#   value = oci_database_autonomous_database.strava_autonomous_database.connection_urls.0.sql_dev_web_url
# }