getTables <- function(schema) {
    sql <- paste0("
        SELECT c.relname as name,  c.reltuples::bigint AS rows,
            d.description AS desc,
            pg_catalog.pg_get_userbyid(c.relowner) as owner
        FROM pg_catalog.pg_class c
        LEFT JOIN pg_catalog.pg_namespace n
        ON n.oid = c.relnamespace
        LEFT JOIN pg_description AS d
        ON d.objoid= c.oid
        WHERE c.relkind ='r'
        AND n.nspname !~ '^pg_toast'
        AND n.nspname = '", schema, "'
        ORDER BY 1,2;")

    library(RPostgreSQL)
    pg <- dbConnect(PostgreSQL(), host="localhost", port=5432)
    pg_iangow_me <- dbGetQuery(pg, sql)
    dbDisconnect(pg)

    pg <- dbConnect(PostgreSQL(), host="localhost", port=5433)
    pg_hack <- dbGetQuery(pg, sql)
    dbDisconnect(pg)

    merged <- merge(pg_iangow_me, pg_hack, by="name",  all=TRUE,
                    suffixes = c("_mp", "_local"))
    return(merged)
}

temp <- getTables("targeted")
subset(temp, desc_mp!=desc_local | is.na(desc_mp) |  is.na(desc_local))
temp
