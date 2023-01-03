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

# Terraform will take 5 minutes after destroying an application due to a known service issue.
# please refer: https://docs.cloud.oracle.com/iaas/Content/Functions/Tasks/functionsdeleting.htm
resource "oci_functions_application" "function_application" {
  compartment_id = var.compartment_ocid
  display_name = random_uuid.application_name.result
  subnet_ids = [oci_core_subnet.function_subnet.id]

#   config                     = var.config
#   syslog_url                 = var.syslog_url
#   network_security_group_ids = [oci_core_network_security_group.function_security_group.id]
#   image_policy_config {
# 	#Required
# 	is_policy_enabled = var.application_image_policy_config_is_policy_enabled

# 	#Optional
# 	key_details {
# 	  #Required
# 	  kms_key_id = var.kms_key_ocid
# 	}
#   }
#   trace_config {
# 	domain_id  = var.application_trace_config.domain_id
# 	is_enabled = var.application_trace_config.is_enabled
#   }
}

# resource "oci_functions_function" "test_function" {
#   #Required
#   application_id = oci_functions_application.function_application.id
#   display_name   = "function1"
#   image          = var.image
#   memory_in_mbs  = "128"

#   #Optional
# #   config             = var.config
# #   image_digest       = var.function_image_digest
# #   timeout_in_seconds = "30"
# #   trace_config {
# # 	is_enabled = var.function_trace_config.is_enabled
# #   }

# #   provisioned_concurrency_config {
# # 	strategy = "CONSTANT"
# # 	count = 40
# #   }
# }

# # resource "time_sleep" "wait_function_provisioning" {
# #   depends_on      = [oci_functions_function.test_function]

# #   create_duration = "5s"
# # }

# resource "oci_functions_invoke_function" "test_invoke_function" {
#   depends_on           = [time_sleep.wait_function_provisioning]
#   fn_intent            = "httprequest"
#   fn_invoke_type       = "sync"
#   function_id          = oci_functions_function.test_function.id
#   invoke_function_body = var.invoke_function_body
# }

# resource "oci_functions_invoke_function" "test_invoke_function_source_path" {
#   depends_on             = [time_sleep.wait_function_provisioning]
#   fn_intent              = "httprequest"
#   fn_invoke_type         = "sync"
#   function_id            = oci_functions_function.test_function.id
#   input_body_source_path = var.invoke_function_body_source_path
# }

# resource "oci_functions_invoke_function" "test_invoke_function_detached" {
#   depends_on           = [time_sleep.wait_function_provisioning]
#   fn_intent            = "httprequest"
#   fn_invoke_type       = "detached"
#   function_id          = oci_functions_function.test_function.id
#   invoke_function_body = var.invoke_function_body
# }

# resource "oci_functions_invoke_function" "test_invoke_function_encoded_body" {
#   depends_on                          = [time_sleep.wait_function_provisioning]
#   fn_intent                           = "cloudevent"
#   fn_invoke_type                      = "sync"
#   function_id                         = oci_functions_function.test_function.id
#   invoke_function_body_base64_encoded = base64encode(var.invoke_function_body)
# }

# resource "oci_functions_invoke_function" "test_invoke_function_encoded_body_detached" {
#   depends_on                          = [time_sleep.wait_function_provisioning]
#   fn_intent                           = "httprequest"
#   fn_invoke_type                      = "detached"
#   function_id                         = oci_functions_function.test_function.id
#   invoke_function_body_base64_encoded = base64encode(var.invoke_function_body)
# }

# resource "oci_functions_invoke_function" "test_invoke_function_encoded_content" {
#   depends_on            = [time_sleep.wait_function_provisioning]
#   fn_intent             = "httprequest"
#   fn_invoke_type        = "sync"
#   function_id           = oci_functions_function.test_function.id
#   base64_encode_content = true
# }

# output "test_invoke_function_content" {
#   value = oci_functions_invoke_function.test_invoke_function.content
# }

# output "test_invoke_function_source_path_content" {
#   value = oci_functions_invoke_function.test_invoke_function_source_path.content
# }

# output "test_invoke_function_encoded_body" {
#   value = oci_functions_invoke_function.test_invoke_function_encoded_body.content
# }

# output "test_invoke_function_encoded_content" {
#   value = base64decode(
# 	oci_functions_invoke_function.test_invoke_function_encoded_content.content,
#   )
# }
