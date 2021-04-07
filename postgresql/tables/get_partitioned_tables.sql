-- Filename    : get_partitioned_tables.sql
-- Description : This function finds all the partitioned tables in the database
-- Creation    : 07/04/2021 17:41
-- Author      : plu9in
--  |   |                               |                                             |
select
    ns_pr.nspname   partitioned_table_schema
,   pr.relname      partitioned_tablename
,   ns_ch.nspname   partition_schema
,   ch.relname      partition_name
from pg_inherits inh inner join pg_class        pr on inh.inhparent = pr.oid
                     inner join pg_namespace ns_pr on pr.relnamespace = ns_pr.oid
                     inner join pg_class        ch on inh.inhrelid = ch.oid
                     inner join pg_namespace ns_ch on ch.relnamespace = ns_ch.oid
;

