@echo off
setlocal

set FLOATING_PROJECT=C:\Users\LSM\Documents\Code\TailxConnect\talix_desktop_floating_ball
set TARGET_DIR=C:\Users\LSM\OneDrive - Lenovo\Documents\PGB\win\release\floating
set BUILD_OUTPUT=%FLOATING_PROJECT%\build\windows\x64\runner\Release

echo [1/4] Changing to project directory...
cd /d "%FLOATING_PROJECT%"
if errorlevel 1 ( echo ERROR: Project not found && pause && exit /b 1 )

echo [2/4] Cleaning old build...
call flutter clean
if errorlevel 1 ( echo ERROR: flutter clean failed && pause && exit /b 1 )

echo [3/4] Building Windows Release...
call flutter build windows --release
if errorlevel 1 ( echo ERROR: Build failed && pause && exit /b 1 )

if not exist "%BUILD_OUTPUT%" ( echo ERROR: Output not found && pause && exit /b 1 )

echo [4/4] Copying files...
echo   - Closing running floating ball (if any)...
taskkill /F /IM talix_desktop_floating_ball.exe >nul 2>&1
timeout /t 1 /nobreak >nul

if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"
xcopy "%BUILD_OUTPUT%\*" "%TARGET_DIR%\" /E /Y /I
if errorlevel 1 ( echo ERROR: Copy failed && pause && exit /b 1 )

echo.
echo Done!
echo Source: %BUILD_OUTPUT%
echo Target: %TARGET_DIR%
pause
endlocal
