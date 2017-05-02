library("RPostgreSQL")

pg1 <- dbConnect(PostgreSQL(), host="localhost", port=5432)
pg2 <- dbConnect(PostgreSQL(), host="localhost", port=5433)

schemas_sql <- "
    SELECT n.nspname AS name
    FROM pg_catalog.pg_namespace n
    WHERE n.nspname !~ '^pg_' AND n.nspname <> 'information_schema'
    ORDER BY 1"
schemas_1 <- dbGetQuery(pg1, schemas_sql)[, 1]
schemas_2 <- dbGetQuery(pg2, schemas_sql)[, 1]

schemas_common <- intersect(schemas_1, schemas_2)

get_tables <- function(conn, schema) {

    tables_sql <- paste0("
        SELECT n.nspname as schema,
            c.relname as name,
            description AS comment
        FROM pg_catalog.pg_class c
        LEFT JOIN pg_description AS d
        ON d.objoid = c.oid
        LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relkind IN ('r','s','')
        AND n.nspname !~ '^pg_toast'
        AND n.nspname ~ '^(", schema, ")$'
        ORDER BY 1,2;")

    dbGetQuery(conn, tables_sql)
}

compare_schemas  <- function(schema, conn1, conn2) {
    tabs_1 <- get_tables(conn1, schema)
    tabs_1$table_exists <- TRUE

    tabs_2 <- get_tables(conn2, schema)
    tabs_2$table_exists <- TRUE

    temp <- merge(tabs_1, tabs_2, by=c("name", "schema"), suffixes = c("_1", "_2"), all=TRUE)
    subset(temp, comment_1 != comment_2 | is.na(comment_1) )
}
compare_schemas_alt <- function(schema) {
    compare_schemas(schema, pg1, pg2)
}
# comparison <- do.call("rbind", lapply(schemas_common, compare_schemas_alt))
# comparison$table_exists_1 <- !is.na(comparison$table_exists_1)
# comparison$table_exists_2 <- !is.na(comparison$table_exists_2)
