@echo off
echo Quick Git Upload
echo ==================

:: Quick check for git
git --version >nul 2>&1
if errorlevel 1 (
    echo Git not found
    pause
    exit /b 1
)

:: Quick upload with timestamp
echo Adding changes...
git add .

echo Committing...
for /f "tokens=1-3 delims=/ " %%a in ('date /t') do set mydate=%%c-%%a-%%b
for /f "tokens=1-2 delims=: " %%a in ('time /t') do set mytime=%%a:%%b
git commit -m "Quick update - %mydate% %mytime%"

echo Pushing...
git push

if errorlevel 0 (
    echo Upload successful!
) else (
    echo Upload failed!
)

echo.
echo Press any key to close...
pause >nul