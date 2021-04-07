-- Filename    : fnsys_get_partitioned_tables.sql
-- Description : This function returns a cursor with partitioned tables and partitions
-- Creation    : 07/04/2021 17:48
-- Author      : plu9in
--  |   |                               |                                             |
DROP FUNCTION IF EXISTS public.fnsys_get_partitioned_tables;

CREATE OR REPLACE FUNCTION public.fnsys_get_partitioned_tables(
    debug boolean default false
)
  RETURNS refcursor AS
$BODY$
DECLARE
    refcur_code_application refcursor;
BEGIN
    open refcur_code_application for
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

    RETURN refcur_code_application;
END;
$BODY$
  LANGUAGE plpgsql 
;