# Neotoma Anonymized Backups 

This repository generates a container service for Neotoma that copies the Neotoma database into a container and overwrites sensitive data. The container then uploads the data to an S3 bucket where it can be available publically.

The compressed file (XXXX) includes a small README and a script to re-build the database in a local Postgres instance.

The following installation instructions were tested on PostgreSQL version 16, using script regenbash.sh (mac and linux).
Alternatively, the commands can be entered directly in the command line. PostgreSQL must already be installed.

## Postgres Extensions Used:

* [pg_trgm](https://www.postgresql.org/docs/current/pgtrgm.html)
* [intarray](https://www.postgresql.org/docs/9.1/intarray.html)
* [unaccent](https://www.postgresql.org/docs/current/unaccent.html)
* External: [postgis](https://postgis.net/)
* External: [vector/pgvector](https://github.com/pgvector/pgvector)

These extensions are used to improve functionality within the Neotoma Database. External tools such as `postgis` and `pgvector` must be installed prior to creation within the Postgres server. We include the bash script 

1. Unzip the snapshot file:

	gunzip neotoma_ndb_only_2024-03-18.sql.gz

2. Restore database using regenbash.sh.  For help, use: bash regenbash.sh --help

	bash regenbash.sh neotoma_ndb_only_2024-03-18.sql

	The script performs the following actions. A password prompt will appear at each step:
	
		The database "neotoma" is first dropped if it exists;
		The new "neotoma" is created;
		Extenesions are installled;
		The snapshot file (neotoma_ndb_only_2024-03-18.sql) is loaded into the new database.

3. Alternatively, instead of using the script, the commands can be entered directly via command line:

	dropdb neotoma -h localhost -U username
	createdb neotoma -h localhost -U username
	psql -h localhost -d neotoma -U username -c "CREATE EXTENSION postgis;"
	psql -h localhost -d neotoma -U username -c "CREATE EXTENSION pg_trgm;"
	psql -h localhost -d neotoma -U username -f neotoma_ndb_only_2024-03-18.sql



4. To view database using command line interactive terminal:

	psql neotoma username

	Meta-command \d ("describe") will list all the tables in the publice schema. To view the schema (ndb) and tables in the database,
	expand the search path by entering the command:

		SET search_path TO 'ndb', public;


	
	


	

