-- Filename    : fnsys_csv_output_in_csv.sql
-- Description : This function outputs a table in csv
-- Creation    : 07/04/2021 18:04
-- Author    : plu9in
-- #################################################################################################
-- WARNING : This function can reveal some secrets from the db. Use it with care.
-- #################################################################################################
DROP FUNCTION IF EXISTS public.fnsys_csv_output_in_csv;

CREATE OR REPLACE FUNCTION public.fnsys_csv_output_in_csv(
    p_filename          text
,   p_delimiter         text default ';'
,   p_with_header       boolean default true
,   p_select_clause     text default ''
,   p_from_clause       text default ''
,   p_where_clause      text default ''
,   p_windowing_clause  text default ''
,   p_group_by_clause   text default ''
,   p_order_by_clause   text default ''
,   debug boolean default false
)
  RETURNS INT
  AS
$BODY$
DECLARE
    l_copy_order        text := 'copy (%s) to ''/tmp/%s.csv'' with CSV DELIMITER ''%s'' %s;';
    l_select_clause     text := format('select %s ', p_select_clause);
    l_from_clause       text := format('from %s ', p_from_clause);
    l_where_clause      text := format('where %s ', p_where_clause);
    l_windowing_clause  text := format('window %s ', p_windowing_clause);
    l_group_by_clause   text := format('group by %s ', p_group_by_clause);
    l_order_by_clause   text := format('order by %s ', p_order_by_clause) ;

    l_csv_header        text := 'HEADER';

    l_space             char := ' ';
    l_sql               text;

BEGIN
    -- Construct the order
    if l_select_clause<> '' then
	    l_sql := l_select_clause;

	    if p_from_clause <> '' then
	        l_sql := l_sql || l_from_clause ;
	    end if;

	    if p_where_clause <> '' then
	        l_sql := l_sql || l_where_clause;
	    end if;

	    if p_windowing_clause <> '' then
	        l_sql := l_sql || l_windowing_clause;
	    end if;

	    if p_group_by_clause <> '' then
	        l_sql := l_sql || l_group_by_clause;
	    end if;

	    if p_order_by_clause <> '' then
	        l_sql := l_sql || l_order_by_clause;
	    end if;

	    if debug then raise notice 'generated order to fill csv file: %', l_sql; end if;

	    if not p_with_header then
	        l_csv_header := '';
	    end if;

	    l_copy_order := format(l_copy_order, l_sql, p_filename, p_delimiter, l_csv_header);
	    if debug then
	        raise notice '%', l_copy_order;
	    end if;

	    execute l_copy_order;
	end if;

    RETURN 0;
END;
$BODY$
  LANGUAGE plpgsql
  SECURITY DEFINER
;