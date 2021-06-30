# database_utils
This repository contains some functions, sql orders useful for a project or a daily basis database management.

## postgres - csv

##### [fnsys_csv_load_whatever_csv](./postgresql/csv/fnsys_csv_load_whatever_csv.sql)

This function loads all sorts of CSV files without any information on it. It should be created with admin rights in order 
to have access to the server's filesystem. The resulting table is created in the public schema. Its name is 
`public.t<name passed by parameters>`. The field type is text.
The file to be loaded should be in **'/tmp'** directory (linux postgres server)

**example:**

To load /tmp/products.csv into public.ttmp_products
```
select public.fnsys_csv_load_whatever_csv('products', 'tmp_products', debug:= true);
```
## postgres - data models

[generate_graphviz_data_model](./postgresql/data_models/generate_graphviz_data_model.sql)

This query generates a script to give to graphviz. There are still some improvements to make on it.
Once it is generated, you can add the relationships between tables to produce the edges.

## postgres - functions

[fnsys_partitions](./postgresql/functions/fnsys_partitions.sql)

This script creates all the objects necessary to show the proof of concept described below. 

The idea behind this POC is to select on the right physical partition from a function. 
With the created objects from the script fnsys_partitions, you can do things like that :
```
with tmp_table(name, parts) as (
    values 
    ('partition 1', '1')
,   ('partition 2', '2')
)
,   w as (
    select 
        name, fnsys_partitions(part:= parts) as t
    from tmp_table
)
select name, (t::footype).id, (t::footype).code from w
```
Of course, `tmp_table` can be anything you want (a table, a view, etc.). This type of code could be interesting
for BI softwares (like Microstrategy, Tableau, Qlik or others), for example when you have to many partitions to 
map them.

## postgres - session 

##### [detect_locks](./postgresql/sessions/detect_locks.sql)

This query finds locking / locked queries.

##### [kill_session](./postgresql/sessions/kill_session.sql)

This query kills a given session.

## postgres - tables

##### [get_partitioned_tables](./postgresql/tables/get_partitioned_tables.sql)

This query finds all the partition tables and the partition's names.

##### [fnsys_csv_output_in_csv](./postgresql/csv/fnsys_csv_output_in_csv.sql)

This function outputs what you want in a csv. The file is created in **/tmp** directory.
It can be useful when you want to extract some data :
* periodically and automatically;
* on given events
* programmatically but without knowing what you want before end.
* to export them on an other server and you don't want to connect databases together
etc.

**example:**

For example, if we want to extract the result of the following query in a file:
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
,   p_select_clause := '
         table_catalog       as db_name
    ,    table_schema        as schema_name
    ,    table_name          as table_name
    ,    column_name         as column_name
    ,    ordinal_position    as column_position
    ,    count(*) over w     as nb_column_in_table
    ,    count(*) over x     as nb_columns_in_schema'
,   p_from_clause := 'information_schema.columns'
,   p_windowing_clause  := '
        w as (partition by table_catalog, table_schema, table_name)
    ,   x as (partition by table_catalog, table_schema)'
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
So, these functions have to be filtered and their access has to be 
controlled with care.

