[![NSF-1948926](https://img.shields.io/badge/NSF-1948926-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1948926)
[![NSF-2410961](https://img.shields.io/badge/NSF-2410961-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=2410961)

[![lifecycle](https://img.shields.io/badge/lifecycle-in--development-green.svg)]()

# Neotoma Anonymized Backups

This repository generates a container service for Neotoma that copies the [Neotoma Paleoecology Database](https://neotomadb.org) into a Docker container and overwrites sensitive data using a random `md5` hash. The bash script running in the container then uploads the data to a Neotoma AWS S3 bucket where the snapshot is made publically available through a URL that is shared on the Neotoma website.

The compressed file (`neotoma_clean_{DATETIME}.tr.gz`) includes a [bash script](archives/regenbash.sh) that will re-build the database in a user's local Postgres instance. Currently the bash script only runs for Mac and Linux. There is an experimental [Windows batch script](archives/experimental_win_restore.bat) that can be used with caution.

We welcome any user contributions see the [contributors guide](CONTRIBUTING.md).

## Restoring the Database

The most recent snapshot of the Neotoma Database will always be tagged as `neotoma_clean_latest` in the compressed file, but the actual SQL file used to restore the database will be named with the date the snapshot was taken. Generally, the snapshots will be taken every month. If there is a need for a more recent snapshot, please contact the database administrators to request a newer snapshot.

### Postgres Extensions Used

The Docker container uses Postgres 15, and the current RDS database version is PostgreSQL v15.14. The local database requires the following extensions to be installed before you can restore Neotoma locally:

* [pg_trgm](https://www.postgresql.org/docs/current/pgtrgm.html): Helps with full-text searching of publications.
* [intarray](https://www.postgresql.org/docs/9.1/intarray.html)
* [unaccent](https://www.postgresql.org/docs/current/unaccent.html): Helps with searches for terms that may include accents (sitenames, contact names).
* External: [postgis](https://postgis.net/): Helps manage spatial data.

These extensions are used to improve functionality within the Neotoma Database. The `pg_grgm`, `intarray`, and `unaccent` extensions are included with PostgreSQL. External tools such as `postgis` must be installed prior to creation within the Postgres server.

The [regenbash.sh](archives/regenbash.sh) script automates some of the creation of the extensions within the restored database.

### Restoring from the Cloud

The *most recent* version of the clean database is always uploaded as a `.tar.gz` file to Neotoma S3 cloud storage. You can download it directly by clicking the badge below. Note that this download is over 2 Gigs in size.

[![Download Snapshot](https://img.shields.io/badge/Download-Neotoma--Snapshot-orange.svg)](https://neotoma-remote-store.s3.us-east-2.amazonaws.com/neotoma_clean_latest.tar.gz)

Once the file is downloaded, you can extract it locally. The file archive contains the following files (the terminal date for the sql file may differ):

* dbsetup.sql
* experimental_win_restore.bat
* regenbash.sh
* neotoma_clean_2025-07-01.sql

Once you execute `regenbash.sh` (Mac/Linux) or `experimental_win_restore.bat` (Windows) the database will be restored from the text file to your local database within a database `neotoma` at which point you can use the database from whichever database management system you'd like to use.

## AWS Infrastructure

The backup itself is generated through AWS. There are two steps, the first is packaging the Docker image and sending it to ECR, the second is initiating the Batch job, which will run the scripts in the Docker container.

![AWS Configuration](/assets/AWS_scrub_database_infrastructure.svg)

All files (with the exception of files that directly expose secrets) are available in this repository. All secrets are contained in a `parameters.yaml` file in the `./infrastructure` folder. We provide a [`parameters-template.yaml`](./infrastructure/parameters-template.json) file for convenience, so that users can see which key-value pairs are needed for full implementation of the workflow.

### Docker Configuration

The Docker [configuration file](batch.Dockerfile) sets up a container with PostgreSQL 15 and PostGIS. The Docker container sets up the system, creates a connection to a containerized Postgres database, and then uses `pg_dump` to create a plaintext SQL dump of the remote Neotoma database that is restored within the container. To sanitize the database of sensitive data we execute the script [`app/scrubbed_database.sh`](app/scrubbed_database.sh). The SQL statements write over rows in the Data Stewards tables as well as the Contacts tables.

The Docker container is built and deployed to the AWS ECR using the script [`build-and-push.sh`](build-and-push.sh). For this script to work, the user must have the AWS CLI installed, and have permissions to access Neotoma AWS services.

### AWS Infrastructure Builder

The scripts [`deploy.sh`](deploy.sh) and [`update.sh`](update.sh) are used to deploy the [Batch Infrastructure](infrastructure/batch-infrastructure.yaml) configuration to CloudFormation, which will then be used to define the AWS Batch run when a job is submitted.

Within the infrastructure file there is a defined `ScheduleRule`, which uses the EventBridge [`cron()`](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-scheduled-rule-pattern.html) scheduler to execute the backup snapshot at 2am on the first day of each month.  Single instances of the job can also be executed using [`test_job.sh`](test_job.sh).

## Final Overview

With this repository, we implement a monthly backup system using AWS infrastructure to provide Neotoma users with a sanitized version of the database for local use on their personal systems.
