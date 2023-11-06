#!/bin/bash

# Set your database connection parameters
DB_NAME=postgres
DB_USER=postgres
DB_PASS=postgres
DB_HOST=localhost # Or use 'host.docker.internal' if the DB is on the host outside of Docker
DB_PORT=5432

function load_shapefile {
    local SHAPEFILE_PATH=$1
    local SHP_BASENAME=$2
    local TABLE_NAME=$3
    docker run \
        --rm \
        -v "$(dirname "${SHAPEFILE_PATH}")":/data \
        --network="host" \
        ghcr.io/osgeo/gdal:alpine-small-latest \
        ogr2ogr -f "PostgreSQL" PG:"dbname='${DB_NAME}' host='${DB_HOST}' port='${DB_PORT}' user='${DB_USER}' password='${DB_PASS}'" \
        /data/"${SHP_BASENAME}".shp -nln "${TABLE_NAME}" -overwrite -nlt PROMOTE_TO_MULTI -fieldTypeToString All -lco GEOMETRY_NAME=geom
}

case $1 in 
    install)
        pip install -r requirements.txt
        mkdir -p pg 
        mkdir -p duckdb
        ;;
    download)
        rm -rf zoning
        rm -rf pluto
        curl -O https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/nyc_mappluto_23v3_unclipped_shp.zip
        curl -O https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/nycgiszoningfeatures_202309shp.zip
        unzip nycgiszoningfeatures_202309shp.zip -d zoning
        unzip nyc_mappluto_23v3_unclipped_shp.zip -d pluto
        rm -f *.zip
        ;;
    create) 
        # Make sure the volume option (-v) comes before the container name (--name)
        mkdir -p pg
        docker run \
            -v "$(pwd)"/pg:/var/lib/postgresql/data \
            --name postgres \
            -e POSTGRES_DB="$DB_NAME" \
            -e POSTGRES_USER="$DB_USER" \
            -e POSTGRES_PASSWORD="$DB_PASS" \
            -p "$DB_PORT":5432 \
            --network="host" \
            -d postgis/postgis
    ;;
    load) 
        shift;
        SHAPEFILE_PATH=$1
        TABLE_NAME=$2
        load_shapefile $SHAPEFILE_PATH $TABLE_NAME
    ;;
    load_all)
        load_shapefile $(pwd)/zoning zoning/nycgiszoningfeatures_202309shp/nyzd zoningdistricts
        load_shapefile $(pwd)/pluto pluto/MapPLUTO_UNCLIPPED pluto
    ;;
    *)
        echo "Usage: $0 {create|load}"
    ;;
esac
