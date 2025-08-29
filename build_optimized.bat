@echo off
echo ========================================
echo    MultiSpace Cloner - Optimized Build
echo ========================================
echo.

echo [1/5] Cleaning previous build...
flutter clean
if %errorlevel% neq 0 (
    echo Error: Flutter clean failed
    pause
    exit /b 1
)

echo [2/5] Getting dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo Error: Flutter pub get failed
    pause
    exit /b 1
)

echo [3/5] Running quick analysis...
flutter analyze --no-fatal-infos
if %errorlevel% neq 0 (
    echo Warning: Analysis found issues, but continuing...
)

echo [4/5] Building optimized APK...
flutter build apk --release --shrink --obfuscate --split-debug-info=build/debug-info
if %errorlevel% neq 0 (
    echo Error: APK build failed
    pause
    exit /b 1
)

echo [5/5] Build completed successfully!
echo.
echo APK Location: build\app\outputs\flutter-apk\app-release.apk
echo APK Size: 
for %%A in (build\app\outputs\flutter-apk\app-release.apk) do echo %%~zA bytes

echo.
echo ========================================
echo    Build completed successfully!
echo ========================================
echo.
echo You can now install the APK on your Android device.
echo.
pause
