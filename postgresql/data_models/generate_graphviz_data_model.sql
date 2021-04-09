-- Filename    : generate_graphviz_data_model.sql
-- Description : This function generates a datamodel containing all schemas and all tables
-- Creation    : 08/04/2021 18:46
-- Author      : plu9in
--  |   |                               |                                             |
with partitioned_tables as (
    select
        ns_pr.nspname  partitioned_table_schema
    ,   pr.relname     partitioned_tablename
    ,   ns_ch.nspname  partition_schema
    ,   ch.relname     partition_name
    from pg_inherits inh inner join pg_class        pr on inh.inhparent = pr.oid
                         inner join pg_namespace ns_pr on pr.relnamespace = ns_pr.oid
                         inner join pg_class        ch on inh.inhrelid = ch.oid
                         inner join pg_namespace ns_ch on ch.relnamespace = ns_ch.oid
)
, all_tables as (
    -- We are not interested in partition tables
    -- We can select exactly what we want in the schema.
    -- Here, we don't want pg_catalog, public, information_schema, etc.
    select
        table_catalog       as db_name
    ,   table_schema        as schema_name
    ,   table_name          as table_name
    ,   column_name         as column_name
    ,   data_type           as data_type
    ,   ordinal_position    as column_position
    from
        information_schema.columns ic left join partitioned_tables pt on
            ic.table_name = pt.partition_name
        and ic.table_schema = pt.partitioned_table_schema
    where
        1 = 1
    and pt.partitioned_table_schema is null
    and table_schema not in ('public', 'pg_catalog', 'information_schema')
    order by
        1, 2, 3, ordinal_position
)
, field_definitions as
(
    select
        db_name
    ,   schema_name
    ,   table_name
    ,  array_agg('
           <tr>
               <td align="left" port="'||column_name||'">'||column_name||'</td>
               <td align="left">      '||data_type||'</td>
           </tr>') fields_definition
    from all_tables
    group by db_name, schema_name, table_name
    order by db_name, schema_name, table_name
)
, table_definitions as (
    select
        db_name
    ,   schema_name
    ,   array_agg('
      '||table_name||'[label=<<table bgcolor="#fffffff" border="1" cellborder="0" cellspacing="0">
           <tr><td bgcolor="#99bfdf" colspan="2">'||table_name||'</td></tr>'
                  ||array_to_string(fields_definition, ' ')||'</table>>];'
        ) as table_definition
    from field_definitions
    group by db_name, schema_name
    order by db_name, schema_name
)
, schema_definitions as(
    select
        db_name
    ,   array_agg('
    subgraph cluster_'||schema_name||'{
      node [shape=plaintext fontname="helvetica"]
      label="'||schema_name||'"
      '||array_to_string(table_definition, ' ')||'}') schema_definition
    from table_definitions
    group by db_name
)
select
    'digraph '||db_name||'{
   '||array_to_string(schema_definition, ' ')||'
}'
from schema_definitions
;