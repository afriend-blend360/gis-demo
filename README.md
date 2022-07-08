# Getting Started

Start a PSQL terminal by 

```shell
$ psql
psql (14.4 (Ubuntu 14.4-1.pgdg22.04+1))
Type "help" for help.

postgres=#
```

Exit PSQL terminal by:

```shell
postgres=# \q
$ 
```

List databases with:

```shell
postgres=# \l
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
-----------+----------+----------+-------------+-------------+-----------------------
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 test      | alex     | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
(4 rows)
```

# New Database

You can create a new database from within psql:

```shell
postgres=# CREATE DATABASE demo_test;
CREATE DATABASE
postgres=# \l
                                  List of databases
    Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
------------+----------+----------+-------------+-------------+-----------------------
 demo_test  | alex     | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 postgres   | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 template0  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
            |          |          |             |             | postgres=CTc/postgres
 template1  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
            |          |          |             |             | postgres=CTc/postgres
 test       | alex     | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 

```

you can also call psql from CLI with:

```shell
alex@alex-XPS-15:~$ createdb -h localhost -U alex -p 5432 -e demo_test2;
SELECT pg_catalog.set_config('search_path', '', false);
CREATE DATABASE demo_test2;
alex@alex-XPS-15:~$ psql
psql (14.4 (Ubuntu 14.4-1.pgdg22.04+1))
Type "help" for help.

postgres=# \l
                                  List of databases
    Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
------------+----------+----------+-------------+-------------+-----------------------
 demo_test | alex     | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 demo_test2 | alex     | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 postgres   | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 template0  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
            |          |          |             |             | postgres=CTc/postgres
 template1  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
            |          |          |             |             | postgres=CTc/postgres
 test       | alex     | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
(6 rows)
```

You can change to a new database by:

```shell
postgres=# \c demo_test
You are now connected to database "demo_test" as user "alex".
demo_test1=#
```

# PostGIS

To set up PostGIS you need to run the following:

```shell
$ psql
psql (14.4 (Ubuntu 14.4-1.pgdg22.04+1))
Type "help" for help.

postgres=# CREATE EXTENSION POSTGIS;
postgres=# CREATE EXTENSION fuzzystrmatch;
postgres=# CREATE EXTENSION postgis_tiger_geocoder; --this one is optional if you want to use the rules based standardizer (pagc_normalize_address)
postgres=# CREATE EXTENSION address_standardizer;
```

To confirm your install is working correctly, run this sql in your database:

```shell
SELECT  na.address, na.streetname,na.streettypeabbrev, na.zip
FROM    normalize_address('1 Devonshire Place, Boston, MA 02109') AS na;
```

Which should output

```shell
 address | streetname | streettypeabbrev | zip
---------+------------+------------------+-------
     1   | Devonshire | Pl               | 02109
```

Create a new record in tiger.loader_platform table with the paths of your executables and server. So for example to create a profile called *alex* that follows sh convention. You would do:

```shell
INSERT INTO     tiger.loader_platform(os, declare_sect, pgbin, wget, unzip_command, psql,path_sep, loader, environ_set_command, county_process_command)
SELECT          'alex', declare_sect, pgbin, wget, unzip_command, psql, path_sep,
loader, environ_set_command, county_process_command
FROM tiger.loader_platform
WHERE os = 'sh';
```

For windows:

```shell
INSERT INTO     tiger.loader_platform(os, declare_sect, pgbin, wget, unzip_command, psql,path_sep, loader, environ_set_command, county_process_command)
SELECT          'alex', declare_sect, pgbin, wget, unzip_command, psql, path_sep,
loader, environ_set_command, county_process_command
FROM tiger.loader_platform
WHERE os = 'windows';
```

And then edit the paths in the declare_sect column to those that fit Debbie’s pg, unzip,shp2pgsql, psql, etc path locations.
If you don’t edit this loader_platform table, it will just contain common case locations of items and you’ll have to
edit the generated script after the script is generated

```shell
$ export PGUSER=alex
$ export PGHOST=localhost
$ export PGPORT=5432
$ export PGDATABASE=demo_test1
$ export UNZIPTOOL=/usr/bin/unzip                   
$ export WGETTOOL=/usr/bin/wget       
$ export SHP2PGSQL=/usr/bin/shp2pgsql
$ export PGBIN=/usr/lib/postgresql/14/bin 
$ export PSQL=${PGBIN}/psql   
$ export STAGING_FOLD_DIR=${PWD}/data/gistdata_staging
$ SET_DECLARE_SECT="${STAGING_FOLD_DIR}/temp/; \
 UNZIPTOOL=${UNZIPTOOL}; \
 WGETTOOL=${WGETTOOL}; \
 export PGBIN=${PGBIN} \
 export PGPORT=${PGPORT}; \
 export PGHOST=${PGHOST}; \
 export PGUSER=${PGUSER}; \
 export PGDATABASE=${PGDATABASE}; \
 PSQL=${PGBIN}/psql; \
 SHP2PGSQL=${SHP2PGSQL}; \
 cd ${STAGING_FOLD_DIR}"
$ psql -h ${PGHOST} -U ${PGUSER} -p ${PGPORT} -d ${PGDATABASE} -c "UPDATE tiger.loader_platform SET declare_sect='${SET_DECLARE_SECT}' WHERE os='${PGUSER}';"
```

```shell
$ psql -h localhost -U alex -p 5432 -d demo_test -c "UPDATE tiger.loader_platform SET declare_sect='$/gistdata/temp/' WHERE os='alex';"
```

To enable zip code 5-digit tabluation areas and other areas:

```shell
demo_test1=# UPDATE tiger.loader_lookuptables SET load = true WHERE table_name = 'zcta510';
demo_test1=# UPDATE tiger.loader_lookuptables SET load = true WHERE load = false AND lookup_name IN ('tract', 'bg', 'tabblock');
```
Create a folder called `gisdata` on root of server or your local pc if you have a fast network connection to the server. This folder is where the tiger files will be downloaded to and processed. If you are not happy with having the folder on the root of the server, or simply want to change to a different folder for staging, then edit the field staging_fold in the `tiger.loader_variables table.`

```shell
$ mkdir /gistdata/
```

Create a folder called `temp` in the `gisdata` folder or wherever you designated the staging_fold to be. This will be the folder where the loader extracts the downloaded tiger data.

```shell
$ mkdir /gistdata/temp
```

Then run the Loader_Generate_Nation_Script SQL function make sure to use the name of your custom profile and copy the script to a .sh or .bat file. So for example to build the nation load:

```shell
$ psql -c "SELECT Loader_Generate_Nation_Script('debbie')" -d demo_test -tA > /gisdata/nation_script_load.sh
$ sh nation_script_load.sh
```