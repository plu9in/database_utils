-- Filename    : fnsys_csv_generate_database_definition.sql
-- Description : This function generates a json file with database definition
-- Creation    : 08/04/2021 11:41
-- Createur    : lug_pie
--  |   |                               |                                             |
DROP FUNCTION IF EXISTS public.fnsys_csv_generate_database_definition;

CREATE OR REPLACE FUNCTION public.fnsys_csv_generate_database_definition(
    p_filename    text
,   debug boolean default false
)
  RETURNS INT
  AS
$BODY$
DECLARE
    l_order text := '
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
            order by
                1, 2, 3, ordinal_position
        )
        , fields_in_table as (
            select
                db_name
            ,   schema_name
            ,   table_name
            ,   array_agg(
                    json_build_object(
                        column_name
                    ,   json_build_object(
                              ''data_type''
                            , data_type
                            , ''column_position''
                            , column_position
                        )
                    )
                ) as column_definition
            from
                all_tables
            group by
                db_name
            ,   schema_name
            ,   table_name
            order
                by 1, 2, 3
        )
        , tables_in_schema as (
            select
                db_name
            ,   schema_name
            ,   array_agg(
                    json_build_object(
                          table_name
                        , column_definition
                    )
                ) as table_definition
            from
                fields_in_table
            group by
                db_name
            ,   schema_name
            order
                by 1, 2
        )
        , schemas_in_database as (
            select
                db_name
            ,   array_agg(
                    json_build_object(
                        schema_name
                    ,   table_definition
                    )
                ) as schema_definition
            from
                tables_in_schema
            group by
                db_name
            order
                by 1
        )
        select
            json_build_object(
                db_name
            ,   schema_definition
            )
        from
            schemas_in_database
    ';
BEGIN

    drop table if exists tfile_content_2cols cascade;
    create temp table tfile_content_2cols (
        id bigserial
    ,   line text
    );


    RETURN 0;
END;
$BODY$
  LANGUAGE plpgsql 
  --SECURITY DEFINER
;