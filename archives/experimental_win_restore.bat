@echo off
REM Restore Neotoma from a database snapshot.
REM by: Simon Goring

setlocal EnableDelayedExpansion

REM Check for help request
if "%1"=="-h" goto :help
if "%1"=="--help" goto :help
if "%1"=="/?" goto :help

REM Set default PostgreSQL connection parameters
set PGPASSWORD=postgres
set PGUSER=postgres
set PGHOST=localhost
set PGPORT=5432
set PGDATABASE=postgres

REM Parse command line arguments
:parse_args
if "%~1"=="" goto :end_parse

set arg=%~1
if "%arg:~0,3%"=="-W=" (
    set PGPASSWORD=%arg:~3%
) else if "%arg:~0,11%"=="--password=" (
    set PGPASSWORD=%arg:~11%
) else if "%arg:~0,3%"=="-d=" (
    set PGDATABASE=%arg:~3%
) else if "%arg:~0,11%"=="--database=" (
    set PGDATABASE=%arg:~11%
) else if "%arg:~0,3%"=="-U=" (
    set PGUSER=%arg:~3%
) else if "%arg:~0,7%"=="--user=" (
    set PGUSER=%arg:~7%
) else if "%arg:~0,3%"=="-p=" (
    set PGPORT=%arg:~3%
) else if "%arg:~0,7%"=="--port=" (
    set PGPORT=%arg:~7%
) else if "%arg:~0,3%"=="-h=" (
    set PGHOST=%arg:~3%
) else if "%arg:~0,7%"=="--host=" (
    set PGHOST=%arg:~7%
) else if "%arg:~0,1%"=="-" (
    echo Unknown option %arg%
    exit /b 1
)

shift
goto :parse_args

:end_parse

REM Check if PostgreSQL is installed
where psql >nul 2>&1
if %errorlevel% neq 0 (
    echo Postgres does not seem to be installed on your computer or is not in PATH.
    exit /b 1
)

REM Get PostgreSQL version
for /f "tokens=*" %%i in ('pg_config --version 2^>nul') do set PG_VERSION=%%i
echo postgres exists.

echo ⛃ Setting up the local Neotoma database:
psql -U %PGUSER% -h %PGHOST% -p %PGPORT% -f dbsetup.sql
if %errorlevel% neq 0 (
    echo Error setting up database
    exit /b 1
)

echo Empty database is now set up.
echo  ▶ Restoring database content:
psql -U %PGUSER% -h %PGHOST% -p %PGPORT% -d postgres -f neotoma_clean.sql
if %errorlevel% neq 0 (
    echo Error restoring database content
    exit /b 1
)

echo done.
goto :end

:help
echo.
echo Usage: %~nx0 [options]
echo.
echo Restore the Neotoma Paleoecology Database Snapshot Locally
echo ---------------------------------------------------------------
echo.
echo Windows:
echo.
echo The script restores the Neotoma snapshot to a local database called
echo "neotoma". It should be noted that this script runs under the user's
echo profile. There are cases where individuals have set up PostgreSQL
echo to run under a different user's account.
echo.
echo Options:
echo   -W=^<password^>     --password=^<password^>     PostgreSQL password
echo   -d=^<database^>     --database=^<database^>     Database name
echo   -U=^<user^>         --user=^<user^>             PostgreSQL user
echo   -p=^<port^>         --port=^<port^>             PostgreSQL port
echo   -h=^<host^>         --host=^<host^>             PostgreSQL host
echo   -h, --help, /?                                Help
echo.
exit /b 70

:end
endlocal