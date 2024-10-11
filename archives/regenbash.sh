#!/bin/bash
# Restore Neotoma from a database snapshot.
# by: Simon Goring

DOC_REQUEST=70

if [ "$1" = "-h"  -o "$1" = "--help" ]     # Request help.
then
  echo; echo "Usage: $0 [dump-file-path]"; echo
  sed --silent -e '/DOCUMENTATIONXX$/,/^DOCUMENTATIONXX$/p' "$0" |
  sed -e '/DOCUMENTATIONXX$/d'; exit $DOC_REQUEST; fi


: <<DOCUMENTATIONXX
Restore the Neotoma Paleoecology Database Snapshot Locally
---------------------------------------------------------------

Mac & Linux:

The commandline parameter provides the path to the "dump" file that
is used to restore the Neotoma snapshot to a local database called
"neotoma". It should be noted that this script runs under the user's
profile. There are cases where individuals have set up PostgreSQL
to run under a different user's account.

sudo -U postgres bash regenbash.sh 

DOCUMENTATIONXX

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export PGPASSWORD=postgres
export PGUSER=postgres
export PGHOST=localhost
export PGPORT=5432
export PGDATABASE=postgres

for i in "$@"; do
  case $i in
    -W=*|--password=*)
      PGPASSWORD="${i#*=}"
      shift # past argument=value
      ;;
    -d=*|--database=*)
      PGDATABASE="${i#*=}"
      shift # past argument=value
      ;;
    -U=*|--user=*)
      PGUSER="${i#*=}"
      shift # past argument=value
      ;;
    -p=*|--port=*)
      PGPORT="${i#*=}"
      shift # past argument=value
      ;;
    -h=*|--host=*)
      PGHOST="${i#*=}"
      shift # past argument=value
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 1
      ;;
    *)
      ;;
  esac
done


if [[ $(which psql) ]]; then
    PG_VERSION=$(pg_config --version)
    echo "postgres exists."
else
    echo "Postgres does not seem to be installed on your computer."
    exit 1
fi

if [[ $(psql -U ${PGUSER} -h ${PGHOST} -p ${PGPORT} -c "SELECT oid, extname, extversion FROM pg_extension;" | grep vector) ]]; then
  echo done.
else
  echo "Installing pgvector:"
  git clone https://github.com/pgvector/pgvector.git /tmp/
  cd /tmp/pgvector
  make
  make install
  cd $SCRIPT_DIR
fi

echo create db
psql -U ${PGUSER} -h ${PGHOST} -p ${PGPORT} -f dbsetup.sql
echo now restore:
pg_restore -U $PGUSER -h $PGHOST -p $PGPORT -c --no-owner --no-privileges -d neotoma neotoma_clean.dump
echo done.