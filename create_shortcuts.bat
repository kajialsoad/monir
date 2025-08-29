@echo off
chcp 65001 >nul
echo 🔗 Creating Desktop Shortcuts for Git Upload Scripts
echo =====================================================
echo.

:: Get current directory
set "SCRIPT_DIR=%~dp0"

:: Get desktop path
for /f "tokens=3*" %%i in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v Desktop 2^>nul') do set "DESKTOP=%%j"

if "%DESKTOP%"=="" (
    set "DESKTOP=%USERPROFILE%\Desktop"
)

echo 📁 Desktop path: %DESKTOP%
echo 📁 Script directory: %SCRIPT_DIR%
echo.

:: Create shortcut for git_upload.bat
echo 🔗 Creating shortcut for Full Git Upload...
powershell -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DESKTOP%\Git Upload (Full).lnk'); $Shortcut.TargetPath = '%SCRIPT_DIR%git_upload.bat'; $Shortcut.WorkingDirectory = '%SCRIPT_DIR%'; $Shortcut.Description = 'Full featured git upload with error handling'; $Shortcut.Save()"

:: Create shortcut for quick_upload.bat
echo 🔗 Creating shortcut for Quick Git Upload...
powershell -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DESKTOP%\Git Quick Upload.lnk'); $Shortcut.TargetPath = '%SCRIPT_DIR%quick_upload.bat'; $Shortcut.WorkingDirectory = '%SCRIPT_DIR%'; $Shortcut.Description = 'Quick git upload with auto timestamp'; $Shortcut.Save()"

:: Create shortcut for git_manager.ps1
echo 🔗 Creating shortcut for Git Manager (PowerShell)...
powershell -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DESKTOP%\Git Manager.lnk'); $Shortcut.TargetPath = 'powershell.exe'; $Shortcut.Arguments = '-ExecutionPolicy Bypass -File \"%SCRIPT_DIR%git_manager.ps1\"'; $Shortcut.WorkingDirectory = '%SCRIPT_DIR%'; $Shortcut.Description = 'Advanced git manager with PowerShell'; $Shortcut.Save()"

echo.
echo ✅ Shortcuts created successfully!
echo.
echo 🖥️  Desktop shortcuts created:
echo    • Git Upload (Full).lnk
echo    • Git Quick Upload.lnk
echo    • Git Manager.lnk
echo.
echo 💡 You can now access git upload tools directly from your desktop!
echo.
pause