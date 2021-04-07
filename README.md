# sql_utils
This repository contains some functions, sql orders useful on a project

## postgres - csv

### [fnsys_csv_load_whatever_csv](./postgresql/csv/fnsys_csv_load_whatever_csv.sql)

This function loads all sorts of CSV files without any information on it. It should be created with admin rights in order 
to have access to the server's filesystem. The resulting table is created in the public schema. Its name is 
t<name passed in parameters>. The field type is text.
The file to be loaded should be in '/tmp' directory (linux postgres server)

**example:**

To load /tmp/products.csv into public.ttmp_products
```
select public.fnsys_csv_load_whatever_csv('products',	'tmp_products', debug:= true);
```

## postgres - session 

### [detect_locks](./postgresql/sessions/detect_locks.sql)

This query finds locking / locked queries.

### [kill_session](./postgresql/sessions/kill_session.sql)

This query kills a given session.

