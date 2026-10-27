@echo off
rem ==========================================================================
rem  build-xbox.bat
rem  Builds Raging Blast 2 Recompiled for an Xbox Series X or S in Developer
rem  Mode, and packages it so it can be installed with the Device Portal.
rem
rem  Put these in ONE folder with no spaces in its path, for example C:\rb2x:
rem    build-xbox.bat                        this script
rem    rexglue-sdk-v0.1.2-xbox-uwp.patch     Xbox changes for the SDK
rem    rb2-xbox-uwp.patch                    Xbox changes for the game
rem    game\                                 your extracted game files,
rem                                          with default.xex directly inside
rem  Then double-click this script. Safe to run again after a failure: it
rem  skips work that is already done. Everything it does is logged to
rem  build-log.txt next to it.
rem ==========================================================================
setlocal EnableExtensions
cd /d "%~dp0"
set "ROOT=%CD%"
set "LOG=%ROOT%\build-log.txt"
set "SDK=%ROOT%\rexglue-sdk"
set "RB2=%ROOT%\rb2"
set "GAME=%ROOT%\game"
set "SDK_PATCH=%ROOT%\rexglue-sdk-v0.1.2-xbox-uwp.patch"
set "RB2_PATCH=%ROOT%\rb2-xbox-uwp.patch"
set "RB2_COMMIT=81b0922e2f6f11d43ddac36d51f99ffbd31fa5d0"
set "OUTDIR=%RB2%\out\build\uwp-amd64-release\uwp\rb2\Release"
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
set "ERRMSG="
rem deploy-xbox.bat sends the app and the game files to the Xbox, so only
rem the app is built (no .msix package).
set "QUICK=1"

title Raging Blast 2 - Xbox build
echo.
echo  Raging Blast 2 Recompiled - Xbox build
echo  ======================================
echo  The first run takes a long time, often an hour or more.
echo  Leave this window open. Your PC may get loud and slow - that is normal.
echo  Details go to build-log.txt in this folder.
echo  Started %DATE% %TIME%

call :main > "%LOG%" 2>&1
if errorlevel 1 goto :failed

if "%QUICK%"=="1" goto :done_quick
echo.
echo  ==========================================================
echo   DONE. Your Xbox package is ready.
echo  ==========================================================
echo  It is in:
echo    %OUTDIR%
echo  Opening that folder now. Next, run deploy-xbox.bat
echo  to install it on your Xbox.
echo  Finished %DATE% %TIME%
start "" explorer "%OUTDIR%"
echo.
pause
exit /b 0

:done_quick
echo.
echo  ==========================================================
echo   DONE. The app is built.
echo  ==========================================================
echo  Now run deploy-xbox.bat to send it to your Xbox and start it.
echo  Finished %DATE% %TIME%
echo.
pause
exit /b 0

:failed
echo.
echo  ==========================================================
echo   SOMETHING WENT WRONG
echo  ==========================================================
if defined ERRMSG echo  %ERRMSG%
if defined ERRMSG >>"%LOG%" echo ERROR: %ERRMSG%
if not defined ERRMSG >>"%LOG%" echo ERROR: the script stopped without a message.
echo.
echo  Last lines of build-log.txt:
echo  ----------------------------------------------------------
powershell -NoProfile -Command "Get-Content -LiteralPath $env:LOG -Tail 25"
echo  ----------------------------------------------------------
echo  If you can't fix it, open an issue on the GitHub page and attach
echo  build-log.txt from this folder.
echo  After a fix you can run this script again; it continues where it stopped.
echo.
pause
exit /b 1


rem ==========================================================================
:main
call :say "Step 1 of 7: Checking your files and tools"
if not "%ROOT%"=="%ROOT: =%" (set "ERRMSG=The path of this folder has spaces in it. Move the folder to a simple place like C:\rb2x and run it again." & exit /b 1)
if not exist "%SDK_PATCH%" (set "ERRMSG=rexglue-sdk-v0.1.2-xbox-uwp.patch is missing. Put it in the same folder as this script. Did you extract the whole zip first?" & exit /b 1)
if not exist "%RB2_PATCH%" (set "ERRMSG=rb2-xbox-uwp.patch is missing. Put it in the same folder as this script. Did you extract the whole zip first?" & exit /b 1)
if not exist "%GAME%\default.xex" (set "ERRMSG=There is no game\default.xex. Make a folder named game next to this script and put your extracted Raging Blast 2 files in it. See the README." & exit /b 1)
where git >nul 2>nul
if errorlevel 1 (set "ERRMSG=Git is not installed. Install it (see the README), then run this again." & exit /b 1)
if not exist "%VSWHERE%" (set "ERRMSG=Visual Studio 2022 is not installed. See the README." & exit /b 1)

rem Log every Visual Studio install and which needed parts each one has.
echo Visual Studio installs found:
"%VSWHERE%" -all -products * -format text -property installationPath
echo With the C++ tools:
"%VSWHERE%" -all -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
echo With C++ Clang Compiler for Windows:
"%VSWHERE%" -all -products * -requires Microsoft.VisualStudio.Component.VC.Llvm.Clang -property installationPath
echo With C++ Universal Windows Platform tools:
"%VSWHERE%" -all -products * -requires Microsoft.VisualStudio.ComponentGroup.UWP.VC -property installationPath

rem Prefer a Visual Studio that has everything (C++ tools, Clang, UWP tools),
rem so a newer install missing a part doesn't hide an older complete one.
set "VSDIR="
for /f "usebackq delims=" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 Microsoft.VisualStudio.Component.VC.Llvm.Clang Microsoft.VisualStudio.ComponentGroup.UWP.VC -property installationPath`) do set "VSDIR=%%i"
if not defined VSDIR for /f "usebackq delims=" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 Microsoft.VisualStudio.ComponentGroup.UWP.VC -property installationPath`) do set "VSDIR=%%i"
if not defined VSDIR for /f "usebackq delims=" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VSDIR=%%i"
if not defined VSDIR (set "ERRMSG=Visual Studio has no C++ tools. Add the Desktop development with C++ workload (see the README)." & exit /b 1)
set "VCVARS=%VSDIR%\VC\Auxiliary\Build\vcvarsall.bat"
if not exist "%VCVARS%" (set "ERRMSG=Visual Studio C++ tools look incomplete. Repair Visual Studio in the Visual Studio Installer." & exit /b 1)
echo Using Visual Studio: %VSDIR%
call :say "   Found Visual Studio and Git."

call :say "Step 2 of 7: Downloading the ReXGlue SDK - this can take a while"
if exist "%SDK%\.git" goto :sdk_update
git -c core.longpaths=true clone -c core.autocrlf=false -c core.longpaths=true --recursive --branch v0.1.2 https://github.com/rexglue/rexglue-sdk "%SDK%"
if errorlevel 1 (set "ERRMSG=Downloading the ReXGlue SDK failed. Check your internet, delete the rexglue-sdk folder, and run this again." & exit /b 1)
goto :sdk_patch
:sdk_update
git -c core.longpaths=true -C "%SDK%" submodule update --init --recursive
if errorlevel 1 (set "ERRMSG=Updating the ReXGlue SDK download failed. Check your internet, delete the rexglue-sdk folder, and run this again." & exit /b 1)
:sdk_patch
call :apply_patch "%SDK%" "%SDK_PATCH%"
if errorlevel 1 (set "ERRMSG=The Xbox patch would not apply to the SDK. Delete the rexglue-sdk folder and run this again." & exit /b 1)
rem Later fixes come as extra patch files next to this script, applied in order.
for %%p in ("%ROOT%\rexglue-sdk-fix-*.patch") do (
  call :apply_patch "%SDK%" "%%~fp"
  if errorlevel 1 (set "ERRMSG=A fix patch would not apply to the SDK. Open an issue on the GitHub page with build-log.txt." & exit /b 1)
)

call :say "Step 3 of 7: Downloading Raging Blast 2 Recompiled"
if exist "%RB2%\.git" goto :rb2_patch
git clone -c core.autocrlf=false https://github.com/WistfulHopes/RB2 "%RB2%"
if errorlevel 1 (set "ERRMSG=Downloading RB2 failed. Check your internet, delete the rb2 folder, and run this again." & exit /b 1)
git -C "%RB2%" checkout -q %RB2_COMMIT%
if errorlevel 1 (set "ERRMSG=Could not select the right RB2 version. Delete the rb2 folder and run this again." & exit /b 1)
:rb2_patch
call :apply_patch "%RB2%" "%RB2_PATCH%"
if errorlevel 1 (set "ERRMSG=The Xbox patch would not apply to RB2. Delete the rb2 folder and run this again." & exit /b 1)
for %%p in ("%ROOT%\rb2-fix-*.patch") do (
  call :apply_patch "%RB2%" "%%~fp"
  if errorlevel 1 (set "ERRMSG=A fix patch would not apply to RB2. Open an issue on the GitHub page with build-log.txt." & exit /b 1)
)
rem The code generator only needs default.xex; the full game files are
rem packaged straight from the game folder later.
if not exist "%RB2%\assets" mkdir "%RB2%\assets"
copy /y "%GAME%\default.xex" "%RB2%\assets\default.xex" >nul
if errorlevel 1 (set "ERRMSG=Could not copy default.xex into the rb2 folder." & exit /b 1)

call :pc_phase
if errorlevel 1 exit /b 1
call :xbox_phase
if errorlevel 1 exit /b 1

if "%QUICK%"=="1" goto :check_layout
if not exist "%OUTDIR%\*.msix" (set "ERRMSG=The build finished but no .msix package was made." & exit /b 1)
exit /b 0
:check_layout
if not exist "%OUTDIR%\layout\rb2.exe" (set "ERRMSG=The build finished but the app files are missing." & exit /b 1)
exit /b 0


rem ==========================================================================
rem Steps 4-5 use the normal PC build tools.
:pc_phase
setlocal
set "ERRMSG="
call "%VCVARS%" x64
if not defined VCToolsInstallDir (set "ERRMSG=Could not start the Visual Studio build tools." & goto :pc_end)
call :use_clang
if errorlevel 1 goto :pc_end

call :say "Step 4 of 7: Building the SDK for PC - the longest step"
cd /d "%SDK%"
cmake --preset win-amd64
if errorlevel 1 (set "ERRMSG=Setting up the PC SDK build failed." & goto :pc_end)
cmake --build --preset win-amd64-release
if errorlevel 1 (set "ERRMSG=Building the PC SDK failed." & goto :pc_end)
cmake --install out/build/win-amd64 --config Release
if errorlevel 1 (set "ERRMSG=Installing the PC SDK failed." & goto :pc_end)

call :say "Step 5 of 7: Turning the Xbox 360 game code into C++"
if exist "%RB2%\generated\.codegen-done" (echo Game code already generated.& goto :pc_end)
set "REXSDK=%SDK%\out\install\win-amd64"
cd /d "%RB2%"
cmake --preset win-amd64-release
if errorlevel 1 (set "ERRMSG=Setting up the RB2 code generation failed." & goto :pc_end)
cmake --build --preset win-amd64-release --target rb2_codegen
if errorlevel 1 (set "ERRMSG=Generating the game code failed. Make sure game\default.xex is from Raging Blast 2." & goto :pc_end)
if not exist "%RB2%\generated\sources.cmake" (set "ERRMSG=Generating the game code did not produce any code." & goto :pc_end)
echo done> "%RB2%\generated\.codegen-done"
:pc_end
endlocal & set "ERRMSG=%ERRMSG%"
if defined ERRMSG exit /b 1
exit /b 0


rem ==========================================================================
rem Steps 6-7 use the UWP (Xbox app) build tools.
:xbox_phase
setlocal
set "ERRMSG="
call "%VCVARS%" x64 uwp
if not defined VCToolsInstallDir (set "ERRMSG=Could not start the Visual Studio build tools for Xbox apps." & goto :xbox_end)
if not exist "%VCToolsInstallDir%lib\x64\store" (set "ERRMSG=The C++ Universal Windows Platform tools are missing. Add them in the Visual Studio Installer (see the README)." & goto :xbox_end)
call :use_clang
if errorlevel 1 goto :xbox_end

call :say "Step 6 of 7: Building the SDK for Xbox"
cd /d "%SDK%"
set "FRESH="
if not exist "%SDK%\out\build\uwp-amd64\build.ninja" set "FRESH=--fresh"
cmake --preset uwp-amd64 %FRESH%
if errorlevel 1 (set "ERRMSG=Setting up the Xbox SDK build failed." & goto :xbox_end)
cmake --build --preset uwp-amd64-release
if errorlevel 1 (set "ERRMSG=Building the Xbox SDK failed." & goto :xbox_end)
cmake --install out/build/uwp-amd64 --config Release
if errorlevel 1 (set "ERRMSG=Installing the Xbox SDK failed." & goto :xbox_end)

call :say "Step 7 of 7: Building and packaging Raging Blast 2 for Xbox"
set "REXSDK_UWP=%SDK%\out\install\uwp-amd64"
set "GAME_CMAKE=%GAME:\=/%"
cd /d "%RB2%"
set "FRESH="
if not exist "%RB2%\out\build\uwp-amd64-release\build.ninja" set "FRESH=--fresh"
cmake --preset uwp-amd64-release %FRESH% "-DRB2_UWP_GAME_FILES=%GAME_CMAKE%"
if errorlevel 1 (set "ERRMSG=Setting up the Xbox game build failed." & goto :xbox_end)
set "BUILD_TARGET=rb2_package"
if "%QUICK%"=="1" set "BUILD_TARGET=rb2"
cmake --build --preset uwp-amd64-release --target %BUILD_TARGET%
if errorlevel 1 (set "ERRMSG=Building or packaging the Xbox game failed." & goto :xbox_end)
:xbox_end
endlocal & set "ERRMSG=%ERRMSG%"
if defined ERRMSG exit /b 1
exit /b 0


rem ==========================================================================
rem Puts Clang 18 or newer first on PATH: a separately installed LLVM if
rem there is one, otherwise the one that comes with Visual Studio.
:use_clang
set "LLVMBIN="
if exist "%VSDIR%\VC\Tools\Llvm\x64\bin\clang.exe" set "LLVMBIN=%VSDIR%\VC\Tools\Llvm\x64\bin"
if exist "%ProgramFiles%\LLVM\bin\clang.exe" set "LLVMBIN=%ProgramFiles%\LLVM\bin"
if defined LLVMBIN set "PATH=%LLVMBIN%;%PATH%"
echo Clang folder chosen: %LLVMBIN%
echo where clang:
where clang
clang --version
set "CLANGVER="
for /f "tokens=3" %%v in ('clang --version 2^>nul ^| findstr /b /c:"clang version"') do set "CLANGVER=%%v"
if not defined CLANGVER (set "ERRMSG=The Clang compiler was not found. Add C++ Clang Compiler for Windows in the Visual Studio Installer (see the README)." & exit /b 1)
set "CLANGMAJOR="
for /f "delims=." %%m in ("%CLANGVER%") do set "CLANGMAJOR=%%m"
if %CLANGMAJOR% LSS 18 (set "ERRMSG=Clang %CLANGVER% is too old - version 18 or newer is needed. Update Visual Studio 2022 in the Visual Studio Installer." & exit /b 1)
echo Using clang %CLANGVER% from %LLVMBIN%
echo where cmake / ninja:
where cmake
where ninja
where cmake >nul 2>nul
if errorlevel 1 (set "ERRMSG=CMake was not found. Add C++ CMake tools for Windows in the Visual Studio Installer." & exit /b 1)
where ninja >nul 2>nul
if errorlevel 1 (set "ERRMSG=Ninja was not found. Add C++ CMake tools for Windows in the Visual Studio Installer." & exit /b 1)
exit /b 0


rem ==========================================================================
rem Applies a patch unless it is already applied. Arguments: repo folder,
rem patch file. A marker file in the repo's .git folder records each applied
rem patch, because a later fix patch can change the same lines, after which
rem git can no longer tell that the earlier patch is in place.
:apply_patch
set "MARKDIR=%~1\.git\rb2x-applied"
set "MARK=%MARKDIR%\%~nx2"
if exist "%MARK%" goto :apply_patch_done
git -C "%~1" apply -R --check "%~2" >nul 2>nul
if not errorlevel 1 goto :apply_patch_mark
git -C "%~1" apply --whitespace=nowarn "%~2"
if errorlevel 1 exit /b 1
echo Applied patch: %~nx2
:apply_patch_mark
if not exist "%MARKDIR%" mkdir "%MARKDIR%"
echo done> "%MARK%"
:apply_patch_done
echo Patch in place: %~nx2
exit /b 0


rem ==========================================================================
rem Shows a progress line in the window and writes it to the log.
:say
echo.
echo ==== %~1
>con echo.
>con echo  %~1
exit /b 0
