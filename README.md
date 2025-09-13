It retries connection using different Wi-Fi Profile names saved in txt file.
(Profile names can be gotten using command `netsh wlan show profiles`)

Example profiles txt file to use (look up profile names using `netsh wlan show profiles`):
```
HOTSPOT 1
WIFI Name 2
```


> [!NOTE]
> 1. Configure txt file name or path containing profile names: `set FLAG_PATH_PROFILES_TXT=profiles.txt` 
> 2. Supports more flags

The script can optionally generate a log file by changing a flag `set FLAG_BASIC_LOGGING=1`:
```
 2025-09-12 17:08:21.54:    Connected
 2025-09-12 20:29:51.55:    Connected
 2025-09-12 20:49:15.33:    Detected disconnection
 2025-09-12 20:56:29.65:    Connected to "HOTSPOT 1" with ip address as 192.168.0.101
```