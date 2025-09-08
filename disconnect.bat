@echo off

REM REM REM REM REM REM RE
REM THIS IS THE FLAGS SECTION
REM SET YOUR FLAGS HERE XXX
REM 0 STANDS FOR FALSE
REM 1 STANDS FOR TRUE
REM FLAG NAMES ARE SELF EXPLANATORY

set FLAG_IS_SPECIAL_CHARACTERS_IN_SSID_OR_PROFILE=0

setlocal enabledelayedexpansion
:test_flags
if %FLAG_IS_SPECIAL_CHARACTERS_IN_SSID_OR_PROFILE%==1 chcp 65001
:display_first_line
cls
    if defined interfacename if "!interfacename!" NEQ "" echo interface ^<!interfacename!^>%tab%%tab%%tab%%tab%^( Scanning is%tab%%tab%%title_append%& echo:%tab%%tab%%tab%%tab%%tab%throttled by Windows API^)&goto picknext
    call :colors  black yellow "scanning interfaces on this computer..."
    echo:
    echo:
    set counters=0
    for /f "tokens=2* delims=:" %%a in ('netsh wlan show interfaces ^|  findstr "Name.*[:]"') do set /a counters+=1 & set "ifacename[!counters!]=%%a"
    if !counters! LEQ 1 for /f %%i in ("%counters%") do set interfacename=!ifacename[%%i]!
    if !counters! GTR 1 (
    set choices=
    echo Select an interface
    for /l %%i in (1,1,!counters!) do echo %%i^) !ifacename[%%i]! & set choices=!choices!%%i
    choice /c !choices!
    for /f "delims=" %%i in ("!errorlevel!") do set interfacename=!ifacename[%%i]!
    )
    for /f "tokens=* delims= " %%a in ("!interfacename!") do set "interfacename=%%a"
    if "!interfacename!" NEQ "" (for /f "delims=" %%i in ("!interfacename!") do echo Found:^<%%i^>.) else (echo: & echo:***No Wireless interface found^!*** & echo: &  PAUSE & GOTO :eof)
:picknext
set shuf_profile=0
set disconnect_times=0
set tot_profiles=0
for /f "delims=" %%i in (connect_profiles_for_disconnect.bat.txt) do set /a tot_profiles+=1
echo Total profiles: %tot_profiles%
:END
set /a shuf_profile+=1
if %shuf_profile% GTR %tot_profiles% set /a shuf_profile=1
ping 192.168.1.254 >NUL&&(echo:connection_test_1_pass & goto nekst)
for /f "tokens=1,* delims=:" %%a in ('type Shuffle_profiles_for_reconnect.txt ^|  findstr /n ".*" ^| findstr /r "^%shuf_profile%[:]"') do (
echo trying profile:%%b
echo on
netsh wlan connect name="%%b" interface="!interfacename!"
@echo off)
ping 192.168.1.254 >NUL&&(echo:connection_test_2_pass & goto nekst)
echo repeating
goto :END
:nekst
echo %time% waiting for input or disconnection...
timeout 200 >NUL
goto picknext
:colors

Set Black1=[40m

Set Red1=[41m

Set Green1=[42m
Set Yellow1=[43m

Set Blue1=[44m

Set Magenta1=[45m
Set white1=[107m
Set Cyan1=[46m

Set Black=[30m
Set Red=[31m
Set Green=[32m
Set Blue=[34m
Set Yellow=[33m
Set Magenta=[35m
Set Cyan=[36m
Set white=[37m

for /f "delims=" %%i in (%3) do echo|set/p=!%~11!!%~2!%%~i[0m
REM powershell -c "write-host -nonewline -backgroundcolor %first% -foregroundcolor %second% \"%~3\""
goto :eof