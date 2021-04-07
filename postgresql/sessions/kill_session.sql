-- Filename    : kill_session.sql
-- Description : This query kills a session given its pid
-- Creation    : 07/04/2021 14:50
-- Author      : plu9in
--  |   |                               |                                             |
select
    pg_terminate_backend(pid)
from
    pg_stat_activity
where
    pid = :session_pid_to_kill
;

