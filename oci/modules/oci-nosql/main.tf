resource "oci_nosql_table" "database" {
    compartment_id = var.compartment_ocid
    name = "database"
    # Examples: https://docs.oracle.com/en/database/other-databases/nosql-database/22.3/java-driver-table/create-table.html
    # Key design: https://docs.oracle.com/en/database/other-databases/nosql-database/22.3/java-driver-table/primary-keys.html
    # Index design: https://docs.oracle.com/en/database/other-databases/nosql-database/22.3/java-driver-table/creating-indexes.html
    ddl_statement = "CREATE TABLE IF NOT EXISTS enviro(createdAt TIMESTAMP, heading FLOAT, accelerometer STRING, temperature FLOAT, pressure FLOAT, rgb STRING, lux INTEGER, PRIMARY KEY (createdAt));"
    table_limits {
        max_read_units = "25"
        max_write_units = "25"
        max_storage_in_gbs = "5"
    }
}
