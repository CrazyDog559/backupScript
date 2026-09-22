@echo off
setlocal EnableExtensions

REM ============================================================
REM MULTI-FOLDER VERSIONED BACKUP
REM ============================================================

REM ------------------------------------------------------------
REM CONFIGURATION
REM ------------------------------------------------------------

set "DESTROOT="
set "LOGDIR=backupLogs"
set "CONFIG=backup_sources.txt"


REM ------------------------------------------------------------
REM CHECK SOURCE LIST
REM ------------------------------------------------------------

if not exist "%CONFIG%" (
    echo.
    echo ERROR: Source list was not found.
    echo.
    echo Expected:
    echo %CONFIG%
    echo.
    pause
    exit /b 10
)


REM ------------------------------------------------------------
REM CREATE ROOT DIRECTORIES
REM ------------------------------------------------------------

if not exist "%DESTROOT%" mkdir "%DESTROOT%"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"


REM ------------------------------------------------------------
REM CREATE TIMESTAMP
REM ------------------------------------------------------------

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set "TIMESTAMP=%%i"


REM ------------------------------------------------------------
REM CREATE THIS BACKUP VERSION
REM ------------------------------------------------------------

set "DEST=%DESTROOT%\Backup_%TIMESTAMP%"
set "LOGFILE=%LOGDIR%\Backup_%TIMESTAMP%.log"

mkdir "%DEST%"

if errorlevel 1 (
    echo.
    echo ERROR: Could not create:
    echo %DEST%
    echo.
    pause
    exit /b 11
)

REM Enable NTFS compression on the new backup folder
echo Enabling compression...
compact /C "%DEST%" /I /Q >nul




REM ------------------------------------------------------------
REM START LOG
REM ------------------------------------------------------------

echo ========================================================== > "%LOGFILE%"
echo BACKUP STARTED >> "%LOGFILE%"
echo Date: %DATE% >> "%LOGFILE%"
echo Time: %TIME% >> "%LOGFILE%"
echo Destination: %DEST% >> "%LOGFILE%"
echo ========================================================== >> "%LOGFILE%"


REM ------------------------------------------------------------
REM DISPLAY INFORMATION
REM ------------------------------------------------------------

echo.
echo ============================================================
echo MULTI-FOLDER VERSIONED BACKUP
echo ============================================================
echo.
echo Backup folder:
echo %DEST%
echo.
echo Reading sources from:
echo %CONFIG%
echo.


REM ------------------------------------------------------------
REM FAILURE FLAG
REM ------------------------------------------------------------

set "FAILED=0"


REM ------------------------------------------------------------
REM READ EVERY LINE FROM backup_sources.txt.txt
REM
REM Quotes around paths ARE supported.
REM Lines starting with # are ignored.
REM ------------------------------------------------------------

for /f "usebackq eol=# delims=" %%A in ("%CONFIG%") do call :BACKUP_FOLDER "%%~A"


REM ------------------------------------------------------------
REM FINISHED
REM ------------------------------------------------------------

echo.
echo ============================================================

if "%FAILED%"=="1" (
    echo BACKUP FINISHED WITH ERRORS
) else (
    echo ALL BACKUPS COMPLETED SUCCESSFULLY
)

echo ============================================================
echo.
echo Backup location:
echo %DEST%
echo.
echo Log:
echo %LOGFILE%
echo.

if "%FAILED%"=="1" (
    echo BACKUP FINISHED WITH ERRORS >> "%LOGFILE%"
) else (
    echo ALL BACKUPS COMPLETED SUCCESSFULLY >> "%LOGFILE%"
)

echo Finished: %DATE% %TIME% >> "%LOGFILE%"

pause
exit /b


REM ============================================================
REM BACKUP SUBROUTINE
REM ============================================================

:BACKUP_FOLDER

REM Remove outer quotes if present
set "SRC=%~1"


REM ------------------------------------------------------------
REM GET SOURCE FOLDER NAME
REM
REM Example:
REM C:\Users\Downloads
REM becomes:
REM Downloads
REM ------------------------------------------------------------

for %%F in ("%SRC%") do set "NAME=%%~nxF"


REM ------------------------------------------------------------
REM SHOW CURRENT BACKUP
REM ------------------------------------------------------------

echo.
echo ------------------------------------------------------------
echo Source:
echo %SRC%
echo.
echo Destination:
echo %DEST%\%NAME%
echo ------------------------------------------------------------
echo.


REM ------------------------------------------------------------
REM CHECK SOURCE EXISTS
REM ------------------------------------------------------------

if not exist "%SRC%\" (
    echo ERROR: SOURCE DOES NOT EXIST
    echo %SRC%
    echo.

    echo ERROR: Source does not exist: %SRC% >> "%LOGFILE%"

    set "FAILED=1"
    goto :EOF
)


REM ------------------------------------------------------------
REM RUN ROBOCOPY
REM
REM IMPORTANT:
REM This is intentionally ONE LINE.
REM Do not break it onto multiple lines.
REM ------------------------------------------------------------

robocopy "%SRC%" "%DEST%\%NAME%" /E /COPY:DAT /DCOPY:DAT /R:3 /W:5 /XJ /MT:8 /TEE /LOG+:"%LOGFILE%"

set "ROBOCODE=%ERRORLEVEL%"


REM ------------------------------------------------------------
REM CHECK ROBOCOPY RESULT
REM
REM 0-7 = success
REM 8+  = error
REM ------------------------------------------------------------

if %ROBOCODE% GEQ 8 (
    echo.
    echo ERROR BACKING UP:
    echo %SRC%
    echo.
    echo Robocopy exit code: %ROBOCODE%
    echo.

    echo ERROR: %SRC% - Robocopy code %ROBOCODE% >> "%LOGFILE%"

    set "FAILED=1"

) else (

    echo.
    echo SUCCESS:
    echo %SRC%
    echo.

    echo SUCCESS: %SRC% - Robocopy code %ROBOCODE% >> "%LOGFILE%"
)

goto :EOF
