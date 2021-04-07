-- Filename    : detect_locks.sql
-- Description : This function detects locks on a postgres database
-- Creation    : 07/04/2021 10:17
-- Author      : plu9in
--  |   |                               |                                             |
with lock_view as (
    select distinct
        RANK() OVER w                                                       as rk
    ,   locked_stats.pid                                                    as locked_session_pid
    ,   locking_stats.pid                                                   as locking_session_pid
    ,   now()-locking_stats.query_start                                     as locking_duration
    ,   now()-locked_stats.query_start                                      as locked_duration
    ,   to_char(locking_stats.backend_start,'YYYYMMDD HH24:MI:SS')          as locking_session_starting_time
    ,   to_char(locking_stats.query_start,'YYYYMMDD HH24:MI:SS')            as locking_query_starting_time
    ,   locked_stats.datname                                                as database_name
    ,   locked_namespace.nspname                                            as locked_object_schema
    ,   locked_name_and_type.relname                                        as locked_object_name
    ,   case
            when locked_name_and_type.relkind in ('t','r') then 'table'
            when locked_name_and_type.relkind = 'i'        then 'index'
            when locked_name_and_type.relkind = 's'        then 'sequence'
            when locked_name_and_type.relkind = 'v'        then 'view'
            else locked_name_and_type.relkind::text
        end                                                                 as locked_object_type
    ,   locking_stats.usename                                               as locking_username
    ,   locking_stats.client_addr                                           as locking_client_address
    ,   locking_stats.query                                                 as locking_query
    ,   locked_stats.pid                                                    as locked_session_pid
    ,   locked_stats.usename                                                as locked_username
    ,   locked_stats.client_addr                                            as locked_client_address
    ,   locked_stats.query                                                  as locked_query
    ,   to_char(locked_stats.query_start,'YYYYMMDD HH24:MI:SS')             as locked_query_starting_time
    ,   to_char(locked_stats.backend_start,'YYYYMMDD HH24:MI:SS')           as locked_session_starting_time
    from
                   pg_locks lock1
        inner join pg_locks lock2 on
            lock1.pid = lock2.pid
        inner join pg_stat_activity locked_stats on
            lock1.pid = locked_stats.pid
        inner join pg_class locked_name_and_type on
            lock2.relation = locked_name_and_type.oid
        inner join pg_namespace locked_namespace on
            locked_name_and_type.relnamespace = locked_namespace.oid
        inner join pg_locks lock3 on
            lock2.relation = lock3.relation
        and lock2.pid <> lock3.pid
        inner join pg_stat_activity locking_stats on
            lock3.pid = locking_stats.pid
    where
        locked_stats.query_start >= locking_stats.query_start
    and lock1.granted is false
    and lock2.relation::regclass is not null
    and locked_namespace.nspname not in ('pg_catalog','pg_toast','information_schema')
    and locked_namespace.nspname not like 'pg_temp_%'
    and lock3.granted is true
    window w as (
        partition by
            locked_stats.pid
        order by
            locking_stats.query_start desc
        range between
            unbounded preceding
        and unbounded following
    )
)
SELECT
    *
FROM
    lock_view
WHERE
    rk = 1
ORDER BY
    locked_duration
,   locked_query_starting_time
;

