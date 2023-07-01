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

resource oci_artifacts_container_repository EnviroStoreRepo {
  compartment_id = var.compartment_ocid
  display_name   = "EnviroStoreRepo"
}

resource oci_artifacts_container_repository EnviroRetrieveRepo {
  compartment_id = var.compartment_ocid
  display_name   = "EnviroRetrieveRepo"
}


resource "oci_devops_project" "project" {
  compartment_id = var.compartment_ocid
  name = random_string.project_name.result
  notification_config {
    topic_id = oci_ons_notification_topic.notification_topic.id
  }
}

resource oci_devops_deploy_artifact EnviroStoreArtifact {
  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
  deploy_artifact_source {
    deploy_artifact_source_type = "OCIR"
    image_digest = ""
    image_uri    = "us-ashburn-1.ocir.io/idyr2jfufjre/EnviroStoreRepo:0.0.1"
  }
  deploy_artifact_type = "DOCKER_IMAGE"
  display_name         = "EnviroStoreArtifact"
  freeform_tags = {
  }
  project_id = oci_devops_project.project.id
}

resource oci_devops_deploy_artifact EnviroRetrieveArtifact {
  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
  deploy_artifact_source {
    deploy_artifact_source_type = "OCIR"
    image_digest = ""
    image_uri    = "us-ashburn-1.ocir.io/idyr2jfufjre/EnviroRetrieveRepo:0.0.1"
  }
  deploy_artifact_type = "DOCKER_IMAGE"
  display_name         = "EnviroRetrieveRepo"
  freeform_tags = {
  }
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

# Do initial run to populate the repository with images
resource "oci_devops_build_run" "initial_build_run" {
    #Required
    build_pipeline_id = oci_devops_build_pipeline.buildPipeline.id
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

locals {
  imageArtifacts = oci_devops_build_run.initial_build_run.build_outputs[*].delivered_artifacts[*].items[*]
  artifactNames = toset(local.imageArtifacts[*].output_artifact_name)
  enviroStoreIndex = index(local.artifactNames, "EnviroStoreOutput")
  enviroRetrieveIndex = index(local.artifactNames, "EnviroRetrieveOutput")
  enviroStoreURI = local.imageArtifacts[local.enviroStoreIndex].image_uri
  enviroRetrieveURI = local.imageArtifacts[local.enviroRetrieveIndex].image_uri
}

resource "oci_functions_function" "enviroStore" {
  application_id = oci_functions_application.function_application.id
  display_name   = "enviroStore"
  memory_in_mbs  = "128"
  image = local.enviroStoreURI
}

resource "oci_functions_function" "enviroRetrieve" {
  application_id = oci_functions_application.function_application.id
  display_name   = "enviroRetrieve"
  memory_in_mbs  = "128"
  image = local.enviroRetrieveURI
}

# Create the Deployment Environments from the functions generated

# Create the Deployment Pipeline with the Environments and Artifacts

# Append the Triger Deploy build step to the Build pipeline
