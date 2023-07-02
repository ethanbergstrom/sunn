resource "random_string" "topic_name" {
  length  = 10
  special = false
}

resource "random_string" "project_name" {
  length  = 10
  special = false
}

resource "oci_kms_vault" "vault" {
    #Required
    compartment_id = var.compartment_ocid
    display_name = "Test Vault"
    vault_type = "DEFAULT"
}

resource "oci_kms_key" "master_key" {
  #Required
  compartment_id      = var.compartment_ocid
  display_name        = "Master Key"
  management_endpoint = oci_kms_vault.vault.management_endpoint

  key_shape {
    #Required
    algorithm = "AES"
    length    = 32
  }
}

resource oci_vault_secret githubSecret {
  compartment_id = var.compartment_ocid
  key_id = oci_kms_key.master_key.id
  secret_name    = "githubToken"
  vault_id       = oci_kms_vault.vault.id
  secret_content {
    #Required
    content_type = "BASE64"

    #Optional
    content = "PHZhcj4mbHQ7YmFzZTY0X2VuY29kZWRfc2VjcmV0X2NvbnRlbnRzJmd0OzwvdmFyPg=="
  }
}

resource "oci_ons_notification_topic" "notification_topic" {
  compartment_id = var.compartment_ocid
  name = random_string.topic_name.result
}

resource "random_string" "enviroStoreRepoName" {
  length  = 5
  numeric  = false
  special = false
  upper = false
}

resource "random_string" "enviroRetrieveRepoName" {
  length  = 5
  numeric  = false
  special = false
  upper = false
}

resource oci_artifacts_container_repository EnviroStoreRepo {
  compartment_id = var.compartment_ocid
  display_name   = random_string.enviroStoreRepoName.result
}

resource oci_artifacts_container_repository EnviroRetrieveRepo {
  compartment_id = var.compartment_ocid
  display_name   = random_string.enviroRetrieveRepoName.result
}

resource "oci_devops_project" "project" {
  compartment_id = var.compartment_ocid
  name = random_string.project_name.result
  notification_config {
    topic_id = oci_ons_notification_topic.notification_topic.id
  }
}

data "oci_objectstorage_namespace" "ns" {}

resource oci_devops_deploy_artifact EnviroStoreArtifact {
  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
  deploy_artifact_source {
    deploy_artifact_source_type = "OCIR"
    image_digest = ""
    # image_uri    = "us-ashburn-1.ocir.io/idyr2jfufjre/EnviroStoreRepo:0.0.1"
    image_uri    = "${var.region}.ocir.io/${data.oci_objectstorage_namespace.ns.namespace}/${random_string.enviroStoreRepoName.result}"
  }
  deploy_artifact_type = "DOCKER_IMAGE"
  display_name         = "EnviroStoreRepo"
  project_id = oci_devops_project.project.id
}

resource oci_devops_deploy_artifact EnviroRetrieveArtifact {
  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
  deploy_artifact_source {
    deploy_artifact_source_type = "OCIR"
    image_digest = ""
    # image_uri    = "us-ashburn-1.ocir.io/idyr2jfufjre/EnviroRetrieveRepo:0.0.1"
    image_uri    = "${var.region}.ocir.io/${data.oci_objectstorage_namespace.ns.namespace}/${random_string.enviroRetrieveRepoName.result}"
  }
  deploy_artifact_type = "DOCKER_IMAGE"
  display_name         = "EnviroRetrieveRepo"
  project_id = oci_devops_project.project.id
}

resource oci_devops_build_pipeline buildPipeline {
#   build_pipeline_parameters {
#   }
  project_id = oci_devops_project.project.id
}

resource oci_devops_connection githubConnection {
  access_token = oci_vault_secret.githubSecret.id
  connection_type = "GITHUB_ACCESS_TOKEN"
  display_name = "GitHub"
  project_id = oci_devops_project.project.id
}

resource oci_devops_build_pipeline_stage buildImageStage {
  build_pipeline_id = oci_devops_build_pipeline.buildPipeline.id
  build_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_build_pipeline.buildPipeline.id
    }
  }
  build_pipeline_stage_type = "BUILD"
  build_runner_shape_config {
    build_runner_type = "DEFAULT"
  }
  build_source_collection {
    items {
      branch          = "oci"
      connection_id   = oci_devops_connection.githubConnection.id
      connection_type = "GITHUB"
      name            = "SourceRepo"
      repository_url = "https://github.com/ethanbergstrom/enviro.git"
    }
  }
  display_name = "BuildStage"
  image = "OL7_X86_64_STANDARD_10"
  primary_build_source = "SourceRepo"
}

resource oci_devops_build_pipeline_stage deliverArtifactStage {
  build_pipeline_id = oci_devops_build_pipeline.buildPipeline.id
  build_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_build_pipeline_stage.buildImageStage.id
    }
  }
  build_pipeline_stage_type = "DELIVER_ARTIFACT"
  deliver_artifact_collection {
    items {
      artifact_id   = oci_devops_deploy_artifact.EnviroStoreArtifact.id
      artifact_name = "EnviroStoreOutput"
    }
    items {
      artifact_id   = oci_devops_deploy_artifact.EnviroRetrieveArtifact.id
      artifact_name = "EnviroRetrieveOutput"
    }
  }
  display_name = "DeliverArtifact"
}

resource oci_logging_log_group devopsLogGroup {
  compartment_id = var.compartment_ocid
  display_name = "DevOpsLogGroup"
}

resource oci_logging_log devopsLog {
  configuration {
    # compartment_id = oci_artifacts_container_configuration.export_container_configuration.id
    source {
      category    = "all"
      resource    = oci_devops_project.project.id
      service     = "devops"
      source_type = "OCISERVICE"
    }
  }
  display_name = "DevOpsLog"
  is_enabled         = "true"
  log_group_id       = oci_logging_log_group.devopsLogGroup.id
  log_type           = "SERVICE"
  retention_duration = "30"
}

resource "oci_identity_dynamic_group" "devopsDynGroup" {
  compartment_id = var.tenancy_ocid
  name           = "devopsDynGroup"
  # Dynamic groups require a description
  description    = "Dynamic group to define the scope of Enviro DevOps Project resources"
  # matching_rule  = "ANY {instance.compartment.id = '${data.oci_identity_compartments.compartments1.compartments[0].id}'}"
  matching_rule = "All {resource.compartment.id = '${var.compartment_ocid}', Any {resource.type = 'devopsdeploypipeline', resource.type = 'devopsbuildpipeline', resource.type = 'devopsrepository', resource.type = 'devopsconnection', resource.type = 'devopstrigger'}}"
}

resource "oci_identity_policy" "devopsPolicy" {
  name           = "devopsPolicy"
  # Policies require a description
  description    = "Provide the necessary permissions for the Enviro DevOps Project to complete its pipeline steps"
  compartment_id = var.compartment_ocid

  statements = [
    "Allow dynamic-group id ${oci_identity_dynamic_group.devopsDynGroup.id} to manage devops-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.devopsDynGroup.id} to manage functions-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.devopsDynGroup.id} to manage generic-artifacts in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.devopsDynGroup.id} to manage repos in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.devopsDynGroup.id} to use ons-topics in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group id ${oci_identity_dynamic_group.devopsDynGroup.id} to read secret-family in compartment id ${var.compartment_ocid}",
  ]
}

# Do initial run to populate the repository with images
resource "oci_devops_build_run" "initial_build_run" {
  #Required
  build_pipeline_id = oci_devops_build_pipeline.buildPipeline.id
  # Ensure it runs after DeliverArtifact stage is in place, Logging is enabled, and necessarily permissions are granted
  depends_on = [oci_logging_log.devopsLog,oci_devops_build_pipeline_stage.deliverArtifactStage,oci_identity_policy.devopsPolicy]
}

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
  config = {
    "TABLE_NAME" = "enviro"
    "COMPARTMENT_OCID" = var.compartment_ocid
  }
}

# locals {
#   imageArtifacts = oci_devops_build_run.initial_build_run.build_outputs[*].delivered_artifacts[*].items
# }

# locals {
#   artifactNames = local.imageArtifacts[*].output_artifact_name
# }

# locals {
#   enviroStoreIndex = index(local.artifactNames, "EnviroStoreOutput")
#   enviroRetrieveIndex = index(local.artifactNames, "EnviroRetrieveOutput")
# }

# locals {
#   enviroStoreURI = local.imageArtifacts[local.enviroStoreIndex].image_uri
#   enviroRetrieveURI = local.imageArtifacts[local.enviroRetrieveIndex].image_uri
# }

resource "oci_functions_function" "enviroStore" {
  application_id = oci_functions_application.function_application.id
  display_name   = "enviroStore"
  memory_in_mbs  = "128"
  # image = local.enviroStoreURI
  image = "${oci_devops_build_run.initial_build_run.build_outputs[0].delivered_artifacts[0].items[0].image_uri}:latest"
}

resource "oci_functions_function" "enviroRetrieve" {
  application_id = oci_functions_application.function_application.id
  display_name   = "enviroRetrieve"
  memory_in_mbs  = "128"
  # image = local.enviroRetrieveURI
  image = "${oci_devops_build_run.initial_build_run.build_outputs[0].delivered_artifacts[0].items[1].image_uri}:latest"
}

# Create the Deployment Environments from the functions generated

# Create the Deployment Pipeline with the Environments and Artifacts

# Append the Triger Deploy build step to the Build pipeline
