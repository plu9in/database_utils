-- Filename    : FNSYS_PARTITIONS.sql
-- Description : 
-- Example of use:
-- Creation    : 30/06/2021 10:08
-- Createur    : plu9in
--  |   |                               |                                             |
DROP FUNCTION IF EXISTS FNSYS_PARTITIONS;

create table if not exists table_partitions (
    id      bigserial
,   code    bigint
)
partition by range (code)
;

create table if not exists table_partitions_1
PARTITION OF table_partitions FOR VALUES FROM (1) TO (5000);
;

create table if not exists table_partitions_2
PARTITION OF table_partitions FOR VALUES FROM (5000) TO (10000);
;

insert into table_partitions (code)
values
    (10)
,   (20)
,   (5010)
,   (5020)
;

drop type if exists footype cascade;
create type footype as (id bigint, code bigint);

CREATE OR REPLACE FUNCTION FNSYS_PARTITIONS(
    part text
,   debug boolean default false
)
RETURNS setof footype
AS
$BODY$
DECLARE
    l_sql text;
BEGIN
    l_sql := 'select id, code from table_partitions_'||part;
    RETURN QUERY
    execute l_sql;
END;
$BODY$
  LANGUAGE plpgsql
;