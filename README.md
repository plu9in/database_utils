# database_utils
This repository contains some functions, sql orders useful for a project or a daily basis database management.

## postgres - csv

### [fnsys_csv_load_whatever_csv](./postgresql/csv/fnsys_csv_load_whatever_csv.sql)

This function loads all sorts of CSV files without any information on it. It should be created with admin rights in order 
to have access to the server's filesystem. The resulting table is created in the public schema. Its name is 
`public.t<name passed by parameters>`. The field type is text.
The file to be loaded should be in **'/tmp'** directory (linux postgres server)

**example:**

To load /tmp/products.csv into public.ttmp_products
```
select public.fnsys_csv_load_whatever_csv('products', 'tmp_products', debug:= true);
```

## postgres - session 

### [detect_locks](./postgresql/sessions/detect_locks.sql)

This query finds locking / locked queries.

### [kill_session](./postgresql/sessions/kill_session.sql)

This query kills a given session.

## postgres - tables

### [get_partitioned_tables](./postgresql/tables/get_partitioned_tables.sql)

This query finds all the partition tables and the partition's names.

### [fnsys_csv_output_in_csv](./postgresql/csv/fnsys_csv_output_in_csv.sql)

This function outputs what you want in a csv. The file is created in **/tmp** directory.

**example:**

For example, if we want to extract the result of this query in a file:
```
select 
     table_catalog        as db_name
,    table_schema         as schema_name
,    table_name           as table_name
,    column_name          as column_name
,    ordinal_position     as column_position
,    count(*) over w      as nb_column_in_table
,    count(*) over x      as nb_columns_in_schema
from 
    information_schema.columns
window w as (partition by table_catalog, table_schema, table_name)
,      x as (partition by table_catalog, table_schema)
order by 
    1, 2, 3, ordinal_position
;
```

We have to call the function like this:

```
select public.fnsys_csv_output_in_csv(
    'tmp_table_fields'
,   p_select_clause := 'table_catalog         as db_name
,    table_schema        as schema_name
,    table_name          as table_name
,    column_name         as column_name
,    ordinal_position    as column_position
,    count(*) over w     as nb_column_in_table
,    count(*) over x     as nb_columns_in_schema'
,   p_from_clause := 'information_schema.columns'
,   p_windowing_clause  := 'w as (partition by table_catalog, table_schema, table_name)
,    x as (partition by table_catalog, table_schema)'
,   p_order_by_clause := '1, 2, 3, ordinal_position'
,   debug := true
);
```

**SECURITY WARNING / USE WITH CARE: This function is dangerous. SQL injection is possible**

**example:** 

This type of query can be done ... or even worse ...

```
copy(
    with w as
    (
        delete from <table> 
        where <cond>
    )
    select 'foobar'
)
to '/tmp/sqlinjection.csv' with CSV header;
```
So, this type of functions have to be filtered and access to them have to be 
controlled with care.
