@echo off
setlocal EnableDelayedExpansion

echo ================================================
echo  ztOS herolight - GitHub Push (Simple)
echo ================================================
echo.

REM --- Check prerequisites ---
where git >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Git not found. Install from: https://git-scm.com/download/win
    pause
    exit /b 1
)

if "%GITHUB_TOKEN%"=="" (
    echo [ERROR] GITHUB_TOKEN not set.
    echo.
    echo Set it like this:
    echo   set GITHUB_TOKEN=ghp_YourTokenHere
    echo.
    echo Get a token from: https://github.com/settings/tokens/new
    echo Make sure to check the 'repo' checkbox.
    pause
    exit /b 1
)

REM --- Remember where we started ---
set "SOURCE_DIR=%CD%"
echo [INFO] Source directory: %SOURCE_DIR%

REM --- Clone the fork ---
echo.
echo [1/4] Cloning your fork...
if exist ztOS-push-temp rmdir /S /Q ztOS-push-temp
git clone https://github.com/Moose1005/ztOS.git ztOS-push-temp
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Clone failed. Check internet and that the fork exists.
    pause
    exit /b 1
)

cd ztOS-push-temp

REM --- Create branch ---
echo.
echo [2/4] Creating herolight-port branch...
git checkout -b herolight-port

REM --- Copy files ---
echo.
echo [3/4] Copying files...
if exist kernel rmdir /S /Q kernel
if exist device rmdir /S /Q device
if exist installer rmdir /S /Q installer
if exist scripts rmdir /S /Q scripts
if exist firmware rmdir /S /Q firmware
if exist docs rmdir /S /Q docs

xcopy /E /I /Y "%SOURCE_DIR%\kernel" kernel >nul
xcopy /E /I /Y "%SOURCE_DIR%\device" device >nul
xcopy /E /I /Y "%SOURCE_DIR%\installer" installer >nul
xcopy /E /I /Y "%SOURCE_DIR%\scripts" scripts >nul
xcopy /E /I /Y "%SOURCE_DIR%\firmware" firmware >nul
xcopy /E /I /Y "%SOURCE_DIR%\docs" docs >nul
if exist "%SOURCE_DIR%\README.md" copy /Y "%SOURCE_DIR%\README.md" README.md >nul

echo [INFO] Files copied.

REM --- Commit ---
echo.
echo [4/4] Committing and pushing...
git add -A
git commit -m "ztOS herolight port: Samsung Galaxy S7 (SM-G930W8) support"

REM --- Push ---
git remote set-url origin https://%GITHUB_TOKEN%@github.com/Moose1005/ztOS.git
git push -u origin herolight-port --force

if %ERRORLEVEL% equ 0 (
    echo.
    echo ================================================
    echo  SUCCESS! Pushed to your fork.
    echo ================================================
    echo.
    echo Open this link to create the Pull Request:
    echo https://github.com/Zerone-Laboratories/ztOS/compare/main...Moose1005:ztOS:herolight-port
    echo.
) else (
    echo.
    echo [ERROR] Push failed.
    echo Common causes:
    echo   - Token expired or missing 'repo' scope
    echo   - Fork doesn't exist at github.com/Moose1005/ztOS
    echo   - Network issue
    echo.
)

cd "%SOURCE_DIR%"
pause
