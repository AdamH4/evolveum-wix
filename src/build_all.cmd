@setlocal
@pushd %~dp0

@set _C=Debug
:parse_args
@if /i "%1"=="release" set _C=Release
@if not "%1"=="" shift & goto parse_args

@if "%VCToolsVersion%"=="" call :StartDeveloperCommandPrompt || exit /b

@echo build %_C%

:: Initialize required files/folders

call build_init.cmd

:: DTF

call dtf\dtf.cmd %_C% || exit /b


:: internal

call internal\internal.cmd %_C% || exit /b


:: libs

call libs\libs.cmd %_C% || exit /b


:: api

call api\api.cmd %_C% || exit /b


:: burn

call burn\burn.cmd %_C% || exit /b


:: wix

call wix\wix.cmd %_C% || exit /b


:: Bypass NuGet SDK Resolver vulnerability check for WixToolset.Sdk dev builds (GHSA-rf39-3f98-xr7r).
:: Dev-build versions (0.0.0-build.*) fall in the advisory's affected range. We redirect MSBuild to
:: resolve WixToolset.Sdk from the already-published directory and hide the nupkg so the NuGet SDK
:: Resolver returns "not found" (falls through to DefaultSdkResolver → MSBuildSDKsPath) rather than
:: logging an error and halting SDK resolution.
@for %%f in (..\build\artifacts\WixToolset.Sdk.*.nupkg) do @ren "%%f" "%%~nxf.hidden"
@rd /s/q "%USERPROFILE%\.nuget\packages\wixtoolset.sdk" 2>nul
@set "MSBuildSDKsPath=%CD%\..\build\wix\%_C%\publish"


:: tools

call tools\tools.cmd %_C% || exit /b


:: ext

call ext\ext.cmd %_C% || exit /b


:: setup

call setup\setup.cmd %_C% || exit /b


:: integration tests

call test\test.cmd %_C% || exit /b


:: finalize build

call internal\finalize.cmd %_C% || exit /b


goto LExit

:StartDeveloperCommandPrompt
if not "%WixSkipVsDevCmd%"=="" (
  echo Skipping initializing developer command prompt
  exit /b
)

echo Initializing developer command prompt

if not exist "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" (
  "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
  exit /b 2
)

for /f "usebackq delims=" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -version [17^,19^) -property installationPath`) do (
  if exist "%%i\Common7\Tools\vsdevcmd.bat" (
    call "%%i\Common7\Tools\vsdevcmd.bat" -no_logo
    exit /b
  )
  echo developer command prompt not found in %%i
)

echo No versions of developer command prompt found
exit /b 2

:LExit
@popd
@endlocal
