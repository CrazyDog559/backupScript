@echo off
setlocal EnableExtensions

REM ============================================================
REM VERSIONED LOCAL BACKUP SCRIPT
REM Creates a NEW backup folder every time the script runs
REM ============================================================


REM ============================================================
REM CONFIGURATION
REM ============================================================

REM Folder you want to back up
set "SOURCE=C:Desktop\testInput"

REM Parent folder where all backup versions will be stored
set "DESTROOT=C:Desktop\testBackup"

REM Folder where backup logs will be stored
set "LOGDIR=C:Desktop\backupLogs"


REM ============================================================
REM CREATE TIMESTAMP
REM ============================================================

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do (
    set "TIMESTAMP=%%i"
)


REM ============================================================
REM CREATE UNIQUE BACKUP DESTINATION
REM ============================================================

set "DEST=%DESTROOT%\Backup_%TIMESTAMP%"
set "LOGFILE=%LOGDIR%\Backup_%TIMESTAMP%.log"


REM ============================================================
REM CHECK SOURCE
REM ============================================================

if not exist "%SOURCE%" (
    echo.
    echo ERROR: Source directory does not exist.
    echo.
    echo Source:
    echo %SOURCE%
    echo.
    pause
    exit /b 10
)


REM ============================================================
REM CREATE BACKUP ROOT
REM ============================================================

if not exist "%DESTROOT%" (
    mkdir "%DESTROOT%"
)

if errorlevel 1 (
    echo.
    echo ERROR: Could not create backup directory.
    pause
    exit /b 11
)


REM ============================================================
REM CREATE LOG DIRECTORY
REM ============================================================

if not exist "%LOGDIR%" (
    mkdir "%LOGDIR%"
)

if errorlevel 1 (
    echo.
    echo ERROR: Could not create log directory.
    pause
    exit /b 12
)


REM ============================================================
REM CREATE THIS BACKUP VERSION
REM ============================================================

mkdir "%DEST%"

if errorlevel 1 (
    echo.
    echo ERROR: Could not create versioned backup folder.
    echo.
    echo Destination:
    echo %DEST%
    pause
    exit /b 13
)


REM ============================================================
REM START LOG
REM ============================================================

echo ========================================================== >> "%LOGFILE%"
echo BACKUP STARTED >> "%LOGFILE%"
echo ========================================================== >> "%LOGFILE%"
echo Date:        %DATE% >> "%LOGFILE%"
echo Time:        %TIME% >> "%LOGFILE%"
echo Source:      %SOURCE% >> "%LOGFILE%"
echo Destination: %DEST% >> "%LOGFILE%"
echo ========================================================== >> "%LOGFILE%"
echo. >> "%LOGFILE%"


REM ============================================================
REM DISPLAY INFORMATION
REM ============================================================

echo.
echo ============================================================
echo VERSIONED BACKUP
echo ============================================================
echo.
echo Source:
echo %SOURCE%
echo.
echo New backup version:
echo %DEST%
echo.
echo Backup starting...
echo.


REM ============================================================
REM RUN ROBOCOPY
REM ============================================================

robocopy "%SOURCE%" "%DEST%" ^
    /E ^
    /COPY:DAT ^
    /DCOPY:DAT ^
    /R:3 ^
    /W:5 ^
    /XJ ^
    /MT:8 ^
    /TEE ^
    /LOG+:"%LOGFILE%"

set "ROBOCODE=%ERRORLEVEL%"


REM ============================================================
REM CHECK ROBOCOPY RESULT
REM ============================================================

echo. >> "%LOGFILE%"
echo Robocopy exit code: %ROBOCODE% >> "%LOGFILE%"


REM Robocopy codes 0-7 are considered successful.
REM Codes 8 or higher indicate a failure.

if %ROBOCODE% GEQ 8 (
    echo.
    echo ============================================================
    echo BACKUP FAILED
    echo ============================================================
    echo.
    echo Robocopy error code: %ROBOCODE%
    echo.
    echo Check log:
    echo %LOGFILE%
    echo.

    echo BACKUP FAILED >> "%LOGFILE%"
    echo Finished: %DATE% %TIME% >> "%LOGFILE%"

    pause
    exit /b %ROBOCODE%
)


REM ============================================================
REM SUCCESS
REM ============================================================

echo.
echo ============================================================
echo BACKUP COMPLETED SUCCESSFULLY
echo ============================================================
echo.
echo Backup version:
echo %DEST%
echo.
echo Log:
echo %LOGFILE%
echo.

echo. >> "%LOGFILE%"
echo ========================================================== >> "%LOGFILE%"
echo BACKUP SUCCESSFUL >> "%LOGFILE%"
echo Finished: %DATE% %TIME% >> "%LOGFILE%"
echo ========================================================== >> "%LOGFILE%"

pause
exit /b 0