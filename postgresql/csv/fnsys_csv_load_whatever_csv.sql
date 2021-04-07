-- Filename    : fnsys_csv_load_whatever_csv.sql
-- Description : This function loads almost any csv
-- Creation    : 07/04/2021 10:50
-- Author      : plu9in
--  |   |                               |                                             |
DROP FUNCTION IF EXISTS public.fnsys_csv_load_whatever_csv;

CREATE OR REPLACE FUNCTION public.fnsys_csv_load_whatever_csv(
    p_filename text
,   p_tablename text
,   p_delimiter text default ';'
,   debug boolean default false
)
  RETURNS INT AS
$BODY$
DECLARE
    l_cursor                refcursor;
    l_record                record;
    l_sql                   text;
    l_sql_columns           text;

    l_sql_rescue            text;
    l_sql_columns_rescue    text;
    l_order                 text;

    l_first                 integer := 1;
    l_index                 integer := 0;

    error_var1              text;
    error_var2              text;
    error_var3              text;
BEGIN

    drop table if exists tload_csv_2cols cascade;
    create temp table tload_csv_2cols (
	    id bigserial
    ,	line text
    );

    -- The file is loaded in a two column table.
    -- The first column keeps track of line order
    -- The second on contains actual file line content
    execute 'COPY tload_csv_2cols (line) FROM ''/tmp/'||p_filename||'.csv'';';

    drop table if exists tload_csv_columns cascade;
    create temp table tload_csv_columns(
        id              bigserial
    ,   column_name     text
    );

    -- We get the column names supposing that the header is included in the CSV.
    -- If not, there are two cases
    -- 1) The first line contains field contents that can be column's name. In that case, the first line is lost and
    --    will define the name of the table's fields. In that case, we cannot do otherwise because we cannot decide.
    -- 2) The first line contains field contents that cannot be column's name. In that case, the table creation will
    --    fail. That's why we have a rescue definition.
    insert into tload_csv_columns(column_name)
    select
        replace(
            unnest(
                string_to_array(
                    line
                ,   p_delimiter
                )
            )
            , '"'
            , ''
        )
    from
        tload_csv_2cols
    where
        id = 1
    ;

    -- We don't need this table anymore. It is faster to reload the file than to split each line according to line
    -- line structure.
    truncate table tload_csv_2cols;

    -- Cursor with column names.
    OPEN l_cursor FOR SELECT id, column_name from tload_csv_columns order by id;

    -- We generate the script to create the table in which we will copy the file content.
    l_sql := 'create table if not exists public.t'||p_tablename||'(';
    l_sql_columns := '';

    LOOP
        FETCH l_cursor into l_record;
        EXIT WHEN NOT FOUND;
        if l_first <> 1 then
            l_sql := l_sql || ', ';
            l_sql_rescue := l_sql_rescue || ', ';

            l_sql_columns := l_sql_columns || ', ';
            l_sql_columns_rescue := l_sql_columns_rescue || ', ';
        end if;

        l_sql                   := l_sql || l_record.column_name || ' text';
        l_sql_rescue            := l_sql || 'col' || l_index || ' text';

        l_sql_columns           := l_sql_columns || l_record.column_name;
        l_sql_columns_rescue    := l_sql_columns || 'col' || l_index ;

        l_first := 0;
        l_index := l_index + 1;
    END LOOP;
    CLOSE l_cursor;

    l_sql := l_sql || ');';
    l_sql_rescue := l_sql_rescue || ');';

    -- Just in case ...
    execute 'drop table if exists public.t'||p_tablename;

    if debug then raise notice '%', l_sql; end if;

    -- Table creation
    execute l_sql;

    l_order := 'COPY public.t'||p_tablename||'('||l_sql_columns||')
    FROM ''/tmp/'||p_filename||'.csv'' DELIMITER '''||p_delimiter||''' CSV HEADER QUOTE ''"'' NULL '''';';

    if debug then raise notice '%', l_order; end if;

    -- File reload in a table structured as the csv
    execute l_order;

    RAISE NOTICE 'public.t% is loaded.', p_tablename;

    RETURN 0;
EXCEPTION
    WHEN OTHERS THEN
        -- In case of error, we give an other try with the rescue definition ...
        execute 'drop table if exists public.t'||p_tablename;

        if debug then raise notice '%', l_sql_rescue; end if;
        execute l_sql_rescue;

        l_order := 'COPY public.t'||p_tablename||'('||l_sql_columns_rescue||')
        FROM ''/tmp/'||p_filename||'.csv'' DELIMITER '''||p_delimiter||''' CSV HEADER QUOTE ''"'' NULL '''';';

        if debug then raise notice '%', l_order; end if;
        execute l_order;

        RAISE NOTICE 'public.t% is loaded.', p_tablename;

        RETURN 0;
END;
$BODY$
  LANGUAGE plpgsql 
  SECURITY DEFINER
;