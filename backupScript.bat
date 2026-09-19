@echo off
setlocal EnableExtensions

REM ============================================================
REM VERSIONED NETWORK BACKUP SCRIPT
REM Creates a NEW backup folder on the shared drive every run
REM ============================================================


REM ============================================================
REM CONFIGURATION
REM ============================================================

REM Folder on THIS computer that you want to back up
set "SOURCE=C:\Users\Desktop\testInput"

REM Shared network folder
REM CHANGE BACKUP-PC and Backups to your actual PC/share names
set "DESTROOT=\\BACKUP-PC\Backups"

REM Logs are stored locally on this computer
set "LOGDIR=C:\Users\Desktop\backupLogs"


REM ============================================================
REM CREATE TIMESTAMP
REM ============================================================

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do (
    set "TIMESTAMP=%%i"
)

REM Each run gets its own folder
set "DEST=%DESTROOT%\Backup_%TIMESTAMP%"

REM Each run gets its own log
set "LOGFILE=%LOGDIR%\Backup_%TIMESTAMP%.log"


REM ============================================================
REM CREATE LOCAL LOG DIRECTORY
REM ============================================================

if not exist "%LOGDIR%" (
    mkdir "%LOGDIR%"
)

if errorlevel 1 (
    echo.
    echo ERROR: Could not create log directory.
    echo %LOGDIR%
    echo.
    pause
    exit /b 10
)


REM ============================================================
REM CHECK SOURCE
REM ============================================================

if not exist "%SOURCE%\" (
    echo.
    echo ============================================================
    echo ERROR: SOURCE FOLDER DOES NOT EXIST
    echo ============================================================
    echo.
    echo Source:
    echo %SOURCE%
    echo.
    pause
    exit /b 11
)


REM ============================================================
REM CHECK NETWORK SHARE
REM ============================================================

echo.
echo Checking network share...
echo %DESTROOT%
echo.

if not exist "%DESTROOT%\" (
    echo ============================================================
    echo ERROR: NETWORK SHARE IS NOT AVAILABLE
    echo ============================================================
    echo.
    echo Could not access:
    echo %DESTROOT%
    echo.
    echo Check:
    echo - The other computer is turned on
    echo - Both computers are connected to the network
    echo - The folder is shared
    echo - You have permission to access the share
    echo - The computer/share names are correct
    echo.
    pause
    exit /b 12
)


REM ============================================================
REM CREATE NEW VERSIONED BACKUP FOLDER
REM ============================================================

echo Creating:
echo %DEST%
echo.

mkdir "%DEST%" >nul 2>&1

if errorlevel 1 (
    echo ============================================================
    echo ERROR: COULD NOT CREATE BACKUP FOLDER
    echo ============================================================
    echo.
    echo Destination:
    echo %DEST%
    echo.
    echo Check your write permissions on the shared folder.
    echo.
    pause
    exit /b 13
)


REM ============================================================
REM START LOG
REM ============================================================

echo ========================================================== >> "%LOGFILE%"
echo NETWORK BACKUP STARTED >> "%LOGFILE%"
echo ========================================================== >> "%LOGFILE%"
echo Date:        %DATE% >> "%LOGFILE%"
echo Time:        %TIME% >> "%LOGFILE%"
echo Source:      %SOURCE% >> "%LOGFILE%"
echo Destination: %DEST% >> "%LOGFILE%"
echo ========================================================== >> "%LOGFILE%"
echo. >> "%LOGFILE%"


REM ============================================================
REM DISPLAY BACKUP INFORMATION
REM ============================================================

echo.
echo ============================================================
echo VERSIONED NETWORK BACKUP
echo ============================================================
echo.
echo Source:
echo %SOURCE%
echo.
echo Network destination:
echo %DEST%
echo.
echo Log:
echo %LOGFILE%
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
    /Z ^
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

REM Robocopy:
REM 0-7 = Successful / acceptable
REM 8+  = Failure

if %ROBOCODE% GEQ 8 (
    echo.
    echo ============================================================
    echo BACKUP FAILED
    echo ============================================================
    echo.
    echo Robocopy error code:
    echo %ROBOCODE%
    echo.
    echo Incomplete backup may exist at:
    echo %DEST%
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
echo Backup saved to:
echo %DEST%
echo.
echo Log saved to:
echo %LOGFILE%
echo.

echo. >> "%LOGFILE%"
echo ========================================================== >> "%LOGFILE%"
echo BACKUP SUCCESSFUL >> "%LOGFILE%"
echo Finished: %DATE% %TIME% >> "%LOGFILE%"
echo ========================================================== >> "%LOGFILE%"

pause
exit /b 0