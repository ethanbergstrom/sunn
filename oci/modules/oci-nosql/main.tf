resource "oci_nosql_table" "database" {
    compartment_id = var.compartment_ocid
    name = "database"
    ddl_statement = "CREATE TABLE enviro (id INTEGER GENERATED ALWAYS AS IDENTITY, createdAt TIMESTAMP, heading FLOAT, accelerometer STRING, temperature FLOAT, pressure FLOAT, rgb STRING, lux INTEGER, KEY (id));"
    table_limits {
        max_read_units = "25"
        max_write_units = "25"
        max_storage_in_gbs = "5" 
    }
}
