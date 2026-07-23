@echo off
setlocal enabledelayedexpansion
chcp 1252 >nul
title Windows Optimization v1.0 (by Marcelo Borasi) 07/26
color 0A

net session >nul 2>&1
if not %errorLevel% == 0 (
    echo [ERROR] Run this file as Administrator / Ejecuta como Administrador.
    echo          Right click -^> "Run as administrator" / Clic derecho -^> "Ejecutar como administrador".
    echo.
    pause
    exit /b 1
)

if not exist "%~dp0App\Apps.ps1" (
    echo [ERROR] Missing App\Apps.ps1 / Falta App\Apps.ps1
    pause
    exit /b 1
)
if not exist "%~dp0App\Services.ps1" (
    echo [ERROR] Missing App\Services.ps1 / Falta App\Services.ps1
    pause
    exit /b 1
)
if not exist "%~dp0App\Performance.ps1" (
    echo [ERROR] Missing App\Performance.ps1 / Falta App\Performance.ps1
    pause
    exit /b 1
)
if not exist "%~dp0App\Cleanup.ps1" (
    echo [ERROR] Missing App\Cleanup.ps1 / Falta App\Cleanup.ps1
    pause
    exit /b 1
)
if not exist "%~dp0App\System.ps1" (
    echo [ERROR] Missing App\System.ps1 / Falta App\System.ps1
    pause
    exit /b 1
)
if not exist "%~dp0App\Health.ps1" (
    echo [ERROR] Missing App\Health.ps1 / Falta App\Health.ps1
    pause
    exit /b 1
)
if not exist "%~dp0App\Network.ps1" (
    echo [ERROR] Missing App\Network.ps1 / Falta App\Network.ps1
    pause
    exit /b 1
)

if not exist "%~dp0Logs"    mkdir "%~dp0Logs"    >nul 2>&1
if not exist "%~dp0Configs" mkdir "%~dp0Configs" >nul 2>&1

rem ==== Deteccion automatica de idioma del sistema ====
set "LANG=ES"
for /f "usebackq delims=" %%L in (`powershell -NoProfile -Command "(Get-UICulture).TwoLetterISOLanguageName"`) do set "SYSLANG=%%L"
if /I "%SYSLANG%"=="es" (set "LANG=ES") else (set "LANG=EN")

rem ==== Verificacion de compatibilidad del sistema operativo ====
for /f "usebackq delims=" %%C in (`powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).Caption"`) do set "OSCAPTION=%%C"
echo %OSCAPTION% | findstr /C:"Windows 10" >nul
if errorlevel 1 (
    cls
    echo =======================================================================
    if "%LANG%"=="ES" (
        echo   ADVERTENCIA DE COMPATIBILIDAD
        echo =======================================================================
        echo.
        echo   Este programa fue diseniado y probado para Windows 10 Pro x64.
        echo   Tu sistema detectado es: %OSCAPTION%
        echo.
        echo   Usarlo en un sistema distinto no fue probado y puede no
        echo   funcionar como se espera, o no funcionar en absoluto.
        echo.
        choice /c SN /n /m "Entendes el riesgo y queres continuar de todos modos? (S/N): "
    ) else (
        echo   COMPATIBILITY WARNING
        echo =======================================================================
        echo.
        echo   This program was designed and tested for Windows 10 Pro x64.
        echo   Your detected system is: %OSCAPTION%
        echo.
        echo   Running it on a different system was not tested and may not
        echo   work as expected, or may not work at all.
        echo.
        choice /c SN /n /m "Understand the risk and continue anyway? (S/N/Y=S): "
    )
    if errorlevel 2 exit /b 0
)

:MENU
cls
echo =======================================================================
if "%LANG%"=="ES" (
    echo   WINDOWS OPTIMIZATION v1.0  ^(by Marcelo Borasi^)  07/26
) else (
    echo   WINDOWS OPTIMIZATION v1.0  ^(by Marcelo Borasi^)  07/26
)
echo =======================================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\System.ps1" -Lang %LANG%
echo =======================================================================
echo.
if "%LANG%"=="ES" (
    echo   Impresora, red compartida, audio, Firewall, Defender y
    echo   Windows Update SIEMPRE protegidos, en cualquier opcion.
    echo.
    echo   ACCIONES PRINCIPALES:
    echo   [1] OPTIMIZAR TODO      - hace todos los cambios seguros, automatico
    echo   [2] RESTAURAR TODO      - deshace exactamente lo que hizo la opcion 1
    echo.
    echo   HERRAMIENTAS EXTRA  ^(no hacen falta para que 1 y 2 funcionen^):
    echo   [3] Limpiar temporales  - libera espacio en disco, no borra nada importante
    echo   [4] Ver diagnostico     - solo muestra el estado actual, no cambia nada
    echo   [5] Config. avanzada    - UAC / GPU / servicios extra, uno por uno con su propia confirmacion
    echo.
    echo   [6] Salir
    echo.
    choice /c 123456 /n /m "Selecciona una opcion (1-6): "
) else (
    echo   Printer, LAN sharing, audio, Firewall, Defender and Windows
    echo   Update are ALWAYS protected, no matter which option you pick.
    echo.
    echo   MAIN ACTIONS:
    echo   [1] OPTIMIZE EVERYTHING  - makes all safe changes, automatically
    echo   [2] RESTORE EVERYTHING   - undoes exactly what option 1 did
    echo.
    echo   EXTRA TOOLS  ^(not needed for 1 and 2 to work^):
    echo   [3] Clean temp files     - frees disk space, nothing important is deleted
    echo   [4] View diagnostics     - only shows current status, changes nothing
    echo   [5] Advanced settings    - UAC / GPU / extra services, each with its own confirmation
    echo.
    echo   [6] Exit
    echo.
    choice /c 123456 /n /m "Choose an option (1-6): "
)

if errorlevel 6 goto END
if errorlevel 5 goto ADVANCED_MENU
if errorlevel 4 goto DO_DISKCHECK
if errorlevel 3 goto DO_CLEANUP
if errorlevel 2 goto DO_RESTORE_ALL
if errorlevel 1 goto DO_OPTIMIZE_ALL

:DO_OPTIMIZE_ALL
cls
if "%LANG%"=="ES" (
    echo OPTIMIZAR TODO va a: desinstalar apps innecesarias, OneDrive y Fax;
    echo aplicar tweaks de Copilot/Bing; desactivar telemetria; activar Modo
    echo Juego y Rendimiento Maximo; y analizar tus discos para TRIM y
    echo fragmentacion ^(NO desfragmenta sin preguntarte primero^).
    echo Impresora, red, audio, Firewall, Defender y Update: intocados.
    echo.
    choice /c SN /n /m "Confirmar? (S/N): "
) else (
    echo OPTIMIZE EVERYTHING will: remove unneeded apps, OneDrive and Fax;
    echo apply Copilot/Bing tweaks; disable telemetry; enable Game Mode
    echo and Max Performance; and analyze your disks for TRIM and
    echo fragmentation ^(will NOT defrag without asking first^).
    echo Printer, network, audio, Firewall, Defender, Update: untouched.
    echo.
    choice /c SN /n /m "Confirm? (S/N/Y=S): "
)
if errorlevel 2 goto MENU

if "%LANG%"=="ES" (
    choice /c SN /n /m "Crear un punto de restauracion antes de continuar? (S/N): "
) else (
    choice /c SN /n /m "Create a system restore point first? (S/N/Y=S): "
)
if errorlevel 2 goto RUN_OPTIMIZE
powershell -NoProfile -Command "Checkpoint-Computer -Description 'WinOptimize_Pre' -RestorePointType 'MODIFY_SETTINGS'" 2>nul

:RUN_OPTIMIZE
echo.
echo =======================================================================
if "%LANG%"=="ES" (echo   PASO 1/5 - Aplicaciones, OneDrive y Fax) else (echo   STEP 1/5 - Apps, OneDrive and Fax)
echo =======================================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Apps.ps1" -Action Uninstall
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Apps.ps1" -Action Tweaks
echo.
echo =======================================================================
if "%LANG%"=="ES" (echo   PASO 2/5 - Servicios en segundo plano) else (echo   STEP 2/5 - Background services)
echo =======================================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Services.ps1" -Action DisableSafe
echo.
echo =======================================================================
if "%LANG%"=="ES" (echo   PASO 3/5 - Rendimiento: energia, Modo Juego, discos) else (echo   STEP 3/5 - Performance: power, Game Mode, disks)
echo =======================================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Performance.ps1" -Action Apply

set "PENDING="
if exist "%~dp0Configs\pending_defrag.txt" (
    set /p PENDING=<"%~dp0Configs\pending_defrag.txt"
)
if not "!PENDING!"=="" (
    echo.
    if "%LANG%"=="ES" (
        choice /c SN /n /m "  Desfragmentar unidades !PENDING! ahora? Puede tardar varios minutos (S/N): "
    ) else (
        choice /c SN /n /m "  Defragment drives !PENDING! now? May take several minutes (S/N/Y=S): "
    )
    if not errorlevel 2 (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Performance.ps1" -Action DefragDrives -Drives "!PENDING!"
    )
)
echo.
echo =======================================================================
if "%LANG%"=="ES" (echo   PASO 4/5 - Salud del sistema: inicio, integridad, driver GPU) else (echo   STEP 4/5 - System health: startup, integrity, GPU driver)
echo =======================================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Health.ps1" -Action StartupReport
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Health.ps1" -Action SfcScan
if exist "%~dp0Configs\sfc_needs_dism.flag" (
    echo.
    if "%LANG%"=="ES" (
        choice /c SN /n /m "  Se encontraron archivos que SFC no pudo reparar. Ejecutar reparacion profunda con DISM ahora? Requiere internet (S/N): "
    ) else (
        choice /c SN /n /m "  SFC found files it could not repair. Run deep repair with DISM now? Requires internet (S/N/Y=S): "
    )
    if not errorlevel 2 (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Health.ps1" -Action DismRepair
    )
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Health.ps1" -Action GpuDriverCheck
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Health.ps1" -Action DirectXCheck
echo.
echo =======================================================================
if "%LANG%"=="ES" (echo   PASO 5/5 - Finalizado) else (echo   STEP 5/5 - Done)
echo =======================================================================
if "%LANG%"=="ES" (echo   Optimizacion completa. Revisa la carpeta Logs para el detalle tecnico.) else (echo   Optimization complete. See the Logs folder for full technical detail.)
goto AFTER_ACTION

:DO_RESTORE_ALL
cls
if "%LANG%"=="ES" (
    echo RESTAURAR TODO deshace exactamente lo que hizo la opcion 1.
    choice /c SN /n /m "Confirmar? (S/N): "
) else (
    echo RESTORE EVERYTHING undoes exactly what option 1 did.
    choice /c SN /n /m "Confirm? (S/N/Y=S): "
)
if errorlevel 2 goto MENU
echo.
echo =======================================================================
if "%LANG%"=="ES" (echo   PASO 1/3 - Reinstalando aplicaciones, OneDrive y Fax) else (echo   STEP 1/3 - Reinstalling apps, OneDrive and Fax)
echo =======================================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Apps.ps1" -Action Install
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Apps.ps1" -Action RevertTweaks
echo.
echo =======================================================================
if "%LANG%"=="ES" (echo   PASO 2/3 - Restaurando servicios) else (echo   STEP 2/3 - Restoring services)
echo =======================================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Services.ps1" -Action Restore
echo.
echo =======================================================================
if "%LANG%"=="ES" (echo   PASO 3/3 - Restaurando rendimiento) else (echo   STEP 3/3 - Restoring performance)
echo =======================================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Performance.ps1" -Action Restore
echo.
if "%LANG%"=="ES" (echo   Restauracion completa finalizada.) else (echo   Restore complete.)
goto AFTER_ACTION

:DO_CLEANUP
cls
if "%LANG%"=="ES" (
    echo Limpia: Temp del usuario y del sistema, cache de miniaturas,
    echo cache de descargas de Windows Update, y cola de informes de error.
    echo NO toca Prefetch ^(mito que empeora el arranque de programas si se borra^)
    echo ni Windows.old ^(se reporta si existe, no se borra automaticamente^).
    echo.
    choice /c SN /n /m "Confirmar limpieza? (S/N): "
) else (
    echo Cleans: user and system Temp, thumbnail cache, Windows Update
    echo download cache, and error report queue.
    echo Does NOT touch Prefetch ^(deleting it slows down app startup, myth^)
    echo or Windows.old ^(reported if present, never auto-deleted^).
    echo.
    choice /c SN /n /m "Confirm cleanup? (S/N/Y=S): "
)
if errorlevel 2 goto MENU
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Cleanup.ps1" -Action Run
echo.
if "%LANG%"=="ES" (
    choice /c SN /n /m "Vaciar tambien la Papelera de Reciclaje? (S/N): "
) else (
    choice /c SN /n /m "Also empty the Recycle Bin? (S/N/Y=S): "
)
if not errorlevel 2 (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Cleanup.ps1" -Action EmptyRecycleBin
)
echo.
pause
goto MENU

:DO_DISKCHECK
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Apps.ps1" -Action DiskCheck
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Performance.ps1" -Action Status
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Health.ps1" -Action StartupReport
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Health.ps1" -Action GpuDriverCheck
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Health.ps1" -Action DirectXCheck
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Network.ps1" -Action Status
echo.
pause
goto MENU

:ADVANCED_MENU
cls
if "%LANG%"=="ES" (
    echo AVANZADO - cada item explica que es, que hace y que puede
    echo perjudicar ANTES de pedirte confirmar. No se aplican con la
    echo opcion 1 a proposito: cada uno tiene un costo real que solo
    echo vos deberias decidir.
    echo.
    echo   [1] Servicios extendidos   - apaga funciones que casi nadie usa en casa
    echo   [2] UAC                    - la ventana de "permitir cambios" de Windows
    echo   [3] HAGS                   - la placa de video organiza sus propias tareas
    echo   [4] DNS rapido             - cambia que servidor traduce las direcciones web
    echo   [5] Volver
    echo.
    choice /c 12345 /n /m "Selecciona (1-5): "
) else (
    echo ADVANCED - each item explains what it is, what it does, and
    echo what it can break BEFORE asking you to confirm. Not applied
    echo by option 1 on purpose: each has a real cost only you should
    echo decide on.
    echo.
    echo   [1] Extended services   - turns off features almost nobody uses at home
    echo   [2] UAC                 - Windows' "allow changes" prompt
    echo   [3] HAGS                - lets the GPU manage its own task scheduling
    echo   [4] Fast DNS            - changes which server translates web addresses
    echo   [5] Back
    echo.
    choice /c 12345 /n /m "Choose (1-5): "
)
if errorlevel 5 goto MENU
if errorlevel 4 goto DNS_MENU
if errorlevel 3 goto HAGS_MENU
if errorlevel 2 goto UAC_MENU
if errorlevel 1 goto DO_EXTENDED

:DNS_MENU
cls
if "%LANG%"=="ES" (
    echo =======================================================================
    echo   DNS RAPIDO ^(CLOUDFLARE^)
    echo =======================================================================
    echo   QUE ES: el DNS es como la "guia telefonica" de internet - traduce
    echo   nombres como google.com a la direccion real del servidor. Por
    echo   defecto usas el DNS de tu proveedor de internet.
    echo.
    echo   QUE HACE: cambia el DNS de tus adaptadores de red activos a
    echo   Cloudflare ^(1.1.1.1^), que suele responder mas rapido y con
    echo   buena politica de privacidad publica.
    echo.
    echo   QUE PUEDE PERJUDICAR: en muy pocos casos, algunas redes
    echo   hogareñas con configuraciones particulares ^(por ejemplo, si
    echo   nombras tus dispositivos por su nombre de red en vez de su
    echo   direccion IP^) pueden tener problemas para encontrarse entre si.
    echo   Se guarda tu configuracion actual para revertirla en cualquier
    echo   momento con la opcion Desactivar.
    echo.
    echo   [1] Activar DNS rapido   [2] Desactivar ^(restaurar original^)   [3] Volver
    choice /c 123 /n /m "Selecciona (1-3): "
) else (
    echo =======================================================================
    echo   FAST DNS ^(CLOUDFLARE^)
    echo =======================================================================
    echo   WHAT IT IS: DNS is like the internet's "phone book" - it
    echo   translates names like google.com into the server's real
    echo   address. By default you use your internet provider's DNS.
    echo.
    echo   WHAT IT DOES: changes your active network adapters' DNS to
    echo   Cloudflare ^(1.1.1.1^), which usually responds faster and has a
    echo   solid public privacy policy.
    echo.
    echo   WHAT IT CAN HURT: in very few cases, some home networks with
    echo   particular setups ^(for example, if you reach devices by network
    echo   name instead of IP address^) may have trouble finding each other.
    echo   Your current settings are saved so you can revert at any time
    echo   with the Disable option.
    echo.
    echo   [1] Enable fast DNS   [2] Disable ^(restore original^)   [3] Back
    choice /c 123 /n /m "Choose (1-3): "
)
if errorlevel 3 goto ADVANCED_MENU
if errorlevel 2 goto DNS_OFF
if errorlevel 1 goto DNS_ON

:DNS_ON
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Network.ps1" -Action FastDnsOn
goto AFTER_ACTION

:DNS_OFF
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Network.ps1" -Action FastDnsOff
goto AFTER_ACTION

:DO_EXTENDED
cls
if "%LANG%"=="ES" (
    echo =======================================================================
    echo   SERVICIOS EXTENDIDOS
    echo =======================================================================
    echo   QUE ES: procesos de Windows adicionales, mas alla de los que ya
    echo   apaga la opcion 1, que casi nadie usa en una PC hogareña de
    echo   escritorio con juegos/diseño/audio/video.
    echo.
    echo   QUE HACE: apaga la Busqueda de Windows, SysMain, el uso compartido
    echo   de red de Windows Media Player, y el servicio biometrico.
    echo.
    echo   QUE PUEDE PERJUDICAR:
    echo     - Busqueda de Windows: la busqueda instantanea en el menu
    echo       Inicio y el Explorador de archivos deja de funcionar.
    echo     - SysMain: efecto variable, en algunos equipos no cambia nada.
    echo     - Uso compartido WMP: si compartis musica o video a un Smart
    echo       TV por DLNA, deja de funcionar.
    echo     - Servicio biometrico: el inicio de sesion con huella digital
    echo       o reconocimiento facial deja de funcionar.
    echo.
    choice /c SN /n /m "Entendes lo anterior y queres continuar? (S/N): "
) else (
    echo =======================================================================
    echo   EXTENDED SERVICES
    echo =======================================================================
    echo   WHAT IT IS: extra Windows processes, beyond what option 1 already
    echo   disables, that almost nobody uses on a home desktop PC for
    echo   gaming/design/audio/video.
    echo.
    echo   WHAT IT DOES: disables Windows Search, SysMain, Windows Media
    echo   Player Network Sharing, and the biometric service.
    echo.
    echo   WHAT IT CAN BREAK:
    echo     - Windows Search: instant search in the Start menu and File
    echo       Explorer stops working.
    echo     - SysMain: variable effect, on some systems nothing changes.
    echo     - WMP Sharing: if you stream music or video to a Smart TV via
    echo       DLNA, it stops working.
    echo     - Biometric service: fingerprint or facial recognition sign-in
    echo       stops working.
    echo.
    choice /c SN /n /m "Do you understand the above and want to continue? (S/N/Y=S): "
)
if errorlevel 2 goto ADVANCED_MENU
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Services.ps1" -Action DisableExtended
goto AFTER_ACTION

:UAC_MENU
cls
if "%LANG%"=="ES" (
    echo =======================================================================
    echo   UAC - CONTROL DE CUENTAS DE USUARIO
    echo =======================================================================
    echo   QUE ES: la ventana gris que aparece y te pide confirmar cuando un
    echo   programa quiere hacer cambios importantes en Windows.
    echo.
    echo   QUE HACE ACTIVARLO: mantiene esa confirmacion pedida siempre
    echo   ^(configuracion de fabrica, RECOMENDADO^).
    echo   QUE HACE DESACTIVARLO: elimina esa confirmacion por completo.
    echo.
    echo   QUE PUEDE PERJUDICAR: con UAC desactivado, cualquier programa
    echo   -incluido un virus o malware- puede hacer cambios de
    echo   administrador en tu sistema SIN avisarte ni pedirte permiso.
    echo   Es una reduccion real de seguridad, no algo cosmetico.
    echo.
    echo   [1] Activar UAC ^(recomendado^)   [2] Desactivar UAC   [3] Volver
    choice /c 123 /n /m "Selecciona (1-3): "
) else (
    echo =======================================================================
    echo   UAC - USER ACCOUNT CONTROL
    echo =======================================================================
    echo   WHAT IT IS: the gray prompt that shows up asking you to confirm
    echo   when a program wants to make important changes to Windows.
    echo.
    echo   WHAT ENABLING DOES: keeps that confirmation prompt always active
    echo   ^(factory default, RECOMMENDED^).
    echo   WHAT DISABLING DOES: removes that confirmation entirely.
    echo.
    echo   WHAT IT CAN HURT: with UAC disabled, any program - including a
    echo   virus or malware - can make administrator-level changes to your
    echo   system WITHOUT warning you or asking permission. This is a real
    echo   security reduction, not a cosmetic one.
    echo.
    echo   [1] Enable UAC ^(recommended^)   [2] Disable UAC   [3] Back
    choice /c 123 /n /m "Choose (1-3): "
)
if errorlevel 3 goto ADVANCED_MENU
if errorlevel 2 goto UAC_OFF
if errorlevel 1 goto UAC_ON

:UAC_ON
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Services.ps1" -Action UacOn
goto AFTER_ACTION

:UAC_OFF
if "%LANG%"=="ES" (
    choice /c SN /n /m "Estas SEGURO de desactivar UAC? Esto reduce la seguridad real de tu PC (S/N): "
) else (
    choice /c SN /n /m "Are you SURE you want to disable UAC? This reduces your PC's real security (S/N/Y=S): "
)
if errorlevel 2 goto ADVANCED_MENU
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Services.ps1" -Action UacOff
goto AFTER_ACTION

:HAGS_MENU
cls
if "%LANG%"=="ES" (
    echo =======================================================================
    echo   HAGS - PROGRAMACION DE GPU ACELERADA POR HARDWARE
    echo =======================================================================
    echo   QUE ES: normalmente Windows organiza por software que tareas
    echo   graficas procesa tu placa de video y en que orden. HAGS le pasa
    echo   ese trabajo a un chip dedicado DENTRO de la propia placa de
    echo   video, si la tiene.
    echo.
    echo   QUE HACE: en teoria, reduce la latencia y mejora la fluidez en
    echo   juegos.
    echo.
    echo   QUE PUEDE PERJUDICAR: en algunas combinaciones de placa y
    echo   driver puede causar cuelgues, parpadeos, o directamente ningun
    echo   cambio notable. Placas NVIDIA anteriores a la serie RTX 20, y
    echo   Radeon anteriores a la RX 5000, no tienen el chip necesario:
    echo   activarlo ahi no rompe nada, pero tampoco cambia nada.
    echo.
    echo   [1] Activar HAGS   [2] Desactivar HAGS   [3] Volver
    choice /c 123 /n /m "Selecciona (1-3): "
) else (
    echo =======================================================================
    echo   HAGS - HARDWARE-ACCELERATED GPU SCHEDULING
    echo =======================================================================
    echo   WHAT IT IS: normally Windows organizes, by software, which
    echo   graphics tasks your GPU processes and in what order. HAGS hands
    echo   that job to a dedicated chip INSIDE the GPU itself, if it has
    echo   one.
    echo.
    echo   WHAT IT DOES: in theory, reduces latency and improves smoothness
    echo   in games.
    echo.
    echo   WHAT IT CAN HURT: on some GPU+driver combinations it can cause
    echo   freezes, flickering, or simply no noticeable change at all. GPUs
    echo   older than NVIDIA RTX 20-series or AMD Radeon RX 5000-series
    echo   lack the required chip: enabling it there breaks nothing, but
    echo   also changes nothing.
    echo.
    echo   [1] Enable HAGS   [2] Disable HAGS   [3] Back
    choice /c 123 /n /m "Choose (1-3): "
)
if errorlevel 3 goto ADVANCED_MENU
if errorlevel 2 goto HAGS_OFF
if errorlevel 1 goto HAGS_ON

:HAGS_ON
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Performance.ps1" -Action HagsOn
goto AFTER_ACTION

:HAGS_OFF
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0App\Performance.ps1" -Action HagsOff
goto AFTER_ACTION

:AFTER_ACTION
echo.
if "%LANG%"=="ES" (
    echo Proceso finalizado. Logs en la carpeta Logs\
    echo.
    choice /c SN /n /m "Reiniciar el equipo ahora? (S/N): "
) else (
    echo Done. Logs are in the Logs\ folder
    echo.
    choice /c SN /n /m "Restart the computer now? (S/N/Y=S): "
)
if errorlevel 2 goto MENU
if "%LANG%"=="ES" (echo Reiniciando en 10 segundos...) else (echo Restarting in 10 seconds...)
shutdown /r /t 10

:END
exit /b 0
