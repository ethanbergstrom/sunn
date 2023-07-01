resource "oci_kms_vault" "vault" {
    #Required
    compartment_id = var.compartment_ocid
    display_name = var.vault_display_name
    vault_type = "DEFAULT"
}

resource oci_vault_secret githubSecret {
  compartment_id = var.compartment_ocid
  key_id = "ocid1.key.oc1.iad.dvsi563naaa5c.abuwcljrppxnq3f7bvh4kga4hvm6cewbylwzr3l44ikt6hzm7i27cjugc75a"
  secret_content = "<placeholder for missing required attribute>" #Required attribute not found in discovery, placeholder value set to avoid plan failure
  secret_name    = "githubToken"
  vault_id       = "ocid1.vault.oc1.iad.dvsi563naaa5c.abuwcljs6ykzynuvo44qgr5ix5runybqxdviytfuzefr6yoir4dqhtlszoda"
}

