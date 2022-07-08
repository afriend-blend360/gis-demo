#!/usr/bin/bash

# Clean data, create db
# Written By: Alexander Friend
# Last Updated: 2022.04.19

# Set paths to cleaned data
export STATES_FIPS_FN=${PWD}/data/clean/state_fips.csv
export DMA_FN=${PWD}/data/clean/dma_describe.csv
export REGION_FN=${PWD}/data/clean/region.csv
export DEMO_FN=${PWD}/data/clean/county_demographic.csv
# export LOAD_TIGER_INTO=${PWD}

# set paths to tools
export UNZIPTOOL=/usr/bin/unzip                   
export WGETTOOL=/usr/bin/wget       
export SHP2PGSQL=/usr/bin/shp2pgsql
export PGBIN=/usr/lib/postgresql/14/bin 
export PSQL=${PGBIN}/psql   

# Set path to save staged tiger/line data
export STAGING_FOLD_DIR=${PWD}/data/gistdata_staging
export TMPDIR=${STAGING_FOLD_DIR}/temp/

# Set values for PostgreSQL database 
export PGUSER=alex
export PGHOST=localhost
export PGPORT=5432
export PGDATABASE=script_test

CREATE_TABLES_FN=${PWD}/scripts/create_tables.sql
LOAD_DB_FN=${PWD}/scripts/load_db.sql
NATION_LOAD_FN=nation_script_load
NATION_LOAD_SCRIPT=${STAGING_FOLD_DIR}/${NATION_LOAD_FN}.sh

mkdir -p ${TMPDIR}

# Creating Database
createdb -h ${PGHOST} -U ${PGUSER} -p ${PGPORT} -e ${PGDATABASE};

# sleep 5

psql -h ${PGHOST} -U ${PGUSER} -p ${PGPORT} -d ${PGDATABASE} -f ${LOAD_DB_FN}
sleep 1 # script seems to crash after this line, waiting for 1 second seems to stop from crashing

# Loading Data
psql -h ${PGHOST} -U ${PGUSER} -p ${PGPORT} -d ${PGDATABASE} -c "\copy states FROM '${STATES_FIPS_FN}' DELIMITER ',' CSV HEADER;"
# echo "Created states table from ${STATES_FIPS_FN}"
psql -h ${PGHOST} -U ${PGUSER} -p ${PGPORT} -d ${PGDATABASE} -c "\copy dma FROM '${DMA_FN}' DELIMITER ',' CSV HEADER;"
# echo "Created dma table from ${DMA_FN}"
psql -h ${PGHOST} -U ${PGUSER} -p ${PGPORT} -d ${PGDATABASE} -c "\copy region FROM '${REGION_FN}' DELIMITER ',' CSV HEADER;"
# echo "Created region table from ${REGION_FN}"
psql -h ${PGHOST} -U ${PGUSER} -p ${PGPORT} -d ${PGDATABASE} -c "\copy demographic FROM '${DEMO_FN}' DELIMITER ',' CSV HEADER;"
# echo "Created demographic table from ${DEMO_FN}"

psql -h ${PGHOST} -U ${PGUSER} -p ${PGPORT} -c "INSERT INTO tiger.loader_platform(
    os, declare_sect, pgbin, wget, unzip_command, psql, path_sep, loader, environ_set_command, county_process_command)
    SELECT '${PGUSER}', declare_sect, pgbin, wget, unzip_command, psql, path_sep, loader, environ_set_command, county_process_command
    FROM tiger.loader_platform WHERE os = 'sh';"


psql -h ${PGHOST} -U ${PGUSER} -p ${PGPORT} -d ${PGDATABASE} -c "UPDATE tiger.loader_variables SET staging_fold='${STAGING_FOLD_DIR}';"

SET_DECLARE_SECT="${STAGING_FOLD_DIR}/temp/; \
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
psql -h ${PGHOST} -U ${PGUSER} -p ${PGPORT} -d ${PGDATABASE} -c "UPDATE tiger.loader_platform SET declare_sect='${SET_DECLARE_SECT}' WHERE os='${PGUSER}';"

psql -h ${PGHOST} -U ${PGUSER} -p ${PGPORT} -d ${PGDATABASE} -c "UPDATE tiger.loader_lookuptables SET load = true WHERE table_name = 'zcta520';"
psql -h ${PGHOST} -U ${PGUSER} -p ${PGPORT} -d ${PGDATABASE} -c "UPDATE tiger.loader_lookuptables SET load = true WHERE load = false AND lookup_name IN ('tract', 'bg', 'tabblock');"

# Create loader script and save to .sh file
psql -h ${PGHOST} -U ${PGUSER} -p ${PGPORT} -d ${PGDATABASE} -c "SELECT Loader_Generate_Nation_Script('${PGUSER}')" -d ${PGDATABASE} -tA > "${NATION_LOAD_SCRIPT}"
echo "Created dataloader script ${NATION_LOAD_SCRIPT}"
sh ${NATION_LOAD_SCRIPT}
