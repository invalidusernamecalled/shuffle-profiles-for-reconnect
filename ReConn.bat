@echo off & setlocal enabledelayedexpansion


REM ALL LINES STARTING WITH "REM" ARE COMMENTS AND NOT CODE

REM THIS IS THE FLAGS SECTION , set FLAGS  0 == FALSE, 1 == TRUE
REM FLAG NAMES (VARIABLES) have been named explicitly to state their purpose
REM all flags must have some DEFAULT VALUE. DO NOT DELETE FLAG variables.
REM JUST CHANGE THEIR VALUES


REM set the profiles.txt file name/location containing list of Wi-Fi profiles on each line (whitespace sensitive)
REM See 2 examples below 
REM set "FLAG_PATH_PROFILES_TXT=C:\folder A\folder 1\profile.txt"
REM set FLAG_PATH_PROFILES_TXT=reconnect.txt

set FLAG_PATH_PROFILES_TXT=Shuffle_profiles_for_reconnect.txt

REM enable basic logging when disconnected and connected 0 (false) or 1 (true)
set FLAG_BASIC_LOGGING=0

REM log file location for saving logs
REM See 2 examples below
REM set "BASIC_LOG_FILE=C:\folder 3\folder\log.txt"
REM set BASIC_LOG_FILE=logs_try_to_reconnect_bat.txt

set BASIC_LOG_FILE=logs_try_to_reconnect_bat.txt

REM do you want it to remember last successful connection's profile name 1 (true) or 0 (false)
set FLAG_REMEMBER_AND_TRY_SUCCESSFUL_PROFILES_FIRST=1

REM ::set if SSIDs have special characters (or leave as default)
set FLAG_IS_SPECIAL_CHARACTERS_IN_SSID_OR_PROFILE=0

REM ::set if you need different addresses for checking connection vs disconnection. (eg. checking for disconnection could use a local gateway depending on needs)
set FLAG_SEPARATE_ADDRESSES_FOR_CHECKING_CONNECTION_DISCONNECTION=1

Rem //flag_gateway_address_to_check can be set to a dns server or external website (like 1.1.1.1) if you wish to check for internet connection instead of router's connection 
REM ::this is the default and only address you need to configure if have SEPARATE_ADDRESSES_FOR_CHECKING_CONNECTION_DISCONNECTION=0
set FLAG_GATEWAY_ADDRESS_TO_CHECK=1.1.1.1

REM ::this is the address used for disconnection if SEPARATE_ADDRESSES_FOR_CHECKING_CONNECTION_DISCONNECTION is set to 1
set FLAG_GATEWAY_TO_CHECK_FOR_DISCONNECTION=192.168.1.254

REM ::Timeout between retries during disconnection
set FLAG_TIMEOUT_BETWEEN_RETRIES=10

REM ::Timeout between checking for disconnected state
set FLAG_TIMEOUT_TO_CHECK_FOR_DISCONNECTION=200

REM enable disable debug mode, useful for developer
set FLAG_DEBUG_MODE=0

:test_flags
if %FLAG_SEPARATE_ADDRESSES_FOR_CHECKING_CONNECTION_DISCONNECTION%==0 set FLAG_GATEWAY_TO_CHECK_FOR_DISCONNECTION=%FLAG_GATEWAY_ADDRESS_TO_CHECK%
if %FLAG_IS_SPECIAL_CHARACTERS_IN_SSID_OR_PROFILE%==1 chcp 65001
if %FLAG_DEBUG_MODE%==1 ( echo:Special Ssid Consideration==^(%FLAG_IS_SPECIAL_CHARACTERS_IN_SSID_OR_PROFILE%^)[0 or 1]
echo:Gateway address to check==^(%FLAG_GATEWAY_ADDRESS_TO_CHECK%^)[ip address/domain]
echo:Timeout between retries==^(%FLAG_TIMEOUT_BETWEEN_RETRIES%^)[seconds]
echo:Timeout to check disconnection==^(%FLAG_TIMEOUT_TO_CHECK_FOR_DISCONNECTION%^)[seconds]
timeout 100)
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
set ran_connection=0
:picknext
set success_trial=1
set shuf_profile=0
set tot_profiles=0
for /f "delims=" %%i in ('type "%FLAG_PATH_PROFILES_TXT%"') do set /a tot_profiles+=1
echo Total profiles: %tot_profiles%
:END
echo|set /p=..%FLAG_TIMEOUT_BETWEEN_RETRIES% sec & timeout %FLAG_TIMEOUT_BETWEEN_RETRIES% >NUL
ping -n 1 %FLAG_GATEWAY_ADDRESS_TO_CHECK% | find /i "ttl=" >NUL&&(echo:1:checking & set check_once=1&  goto nekst) || echo:
set /a shuf_profile+=1
if %shuf_profile% GTR %tot_profiles% set /a shuf_profile=1
for /f "tokens=1,* delims=:" %%a in ('type "%FLAG_PATH_PROFILES_TXT%" ^|  findstr /n ".*" ^| findstr /r "^%shuf_profile%[:]"') do (
echo|set/p=trying profile[%shuf_profile%]:    "%%b"
echo on
set ran_connection=1
set ran_index=%shuf_profile%
netsh wlan connect name="%%b" interface="!interfacename!"
@echo off)

echo|set/p=. [waiting %FLAG_TIMEOUT_BETWEEN_RETRIES% sec do not bypass]&timeout %FLAG_TIMEOUT_BETWEEN_RETRIES% >NUL
ping -n 1 %FLAG_GATEWAY_ADDRESS_TO_CHECK% | find /i "ttl=" >NUL&&(echo:2:checking_after_connection_attempt & set check_once=1& goto nekst) || echo:

if %ran_connection% GEQ 1 if defined success_profile_index for /f "tokens=1,* delims=:" %%a in ('type "%FLAG_PATH_PROFILES_TXT%" ^|  findstr /n ".*" ^| findstr /r "^%success_profile_index%[:]"') do (
echo|set/p=trying last success profile[%success_profile_index%]:    "%%b"
echo on
set ran_index=%success_profile_index%
netsh wlan connect name="%%b" interface="!interfacename!"
@echo off)

ping -n 1 %FLAG_GATEWAY_ADDRESS_TO_CHECK% | find /i "ttl=" >NUL&&(echo:3:checking_after_connection_attempt &set check_once=1&  goto nekst) || set ran_connection=0

echo:repeating
goto :END
:nekst
if %check_once%==1 set check_once=0 & for /f "tokens=1,* delims=:" %%i in ('netsh wlan show interfaces ^| findstr /ir "Name.*[:] State.*[:] ssid.*[:]"') do (for /f "tokens=1 delims= " %%b in ("%%i") do if /i "%%b"=="state" for /f "tokens=* delims= " %%a in ("%%j") do if /i "%%a"=="connected" if defined ran_index ping -n 1 %FLAG_GATEWAY_ADDRESS_TO_CHECK% | find /i "ttl=" >NUL&&echo SET success_profile = %ran_index% & set success_profile_index=%ran_index%)
if %FLAG_BASIC_LOGGING%==1 (call :get_ip_address)
if %FLAG_BASIC_LOGGING%==1 for /f "tokens=1,* delims=:" %%a in ('type "%FLAG_PATH_PROFILES_TXT%" ^|  findstr /n ".*" ^| findstr /r "^%success_profile_index%[:]"') do (echo: %date% %time%:    Connected to "%%a" with ip address as %ip_address%)>>"%BASIC_LOG_FILE%"
echo  ^(%time%^)                      waiting for input or disconnection
echo|set/p=[                .
:peet
timeout %FLAG_TIMEOUT_TO_CHECK_FOR_DISCONNECTION% >NUL
ping -n 1 %FLAG_GATEWAY_TO_CHECK_FOR_DISCONNECTION% | find /i "ttl=" >NUL&&(echo|set/p=.&goto peet)
if %FLAG_BASIC_LOGGING%==1 (echo: %date% %time%:    Detected disconnection) >>"%BASIC_LOG_FILE%"
goto end
:get_ip_address
set ip_address=
for /f "tokens=1,2,3 delims=: " %%i in ('netsh interface ipv4 show config name^="!interfacename!" ^| findstr /ir "ip address[:]"') do (if /i "%%i %%j"=="ip address" set ip_address=%%k)
if "%ip_address%"=="" set ip_address=[Error:unable_to_get_ip_address]

exit /b

echo GO TO HELL

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


