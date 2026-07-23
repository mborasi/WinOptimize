=======================================================
  WINDOWS OPTIMIZATION v1.0 (by Marcelo Borasi) - 07/26
  MANUAL DE USO / USER MANUAL  -  README / LEAME
=======================================================

Este documento esta en DOS IDIOMAS. La version en espanol esta primero,
la version en ingles empieza mas abajo (buscar "ENGLISH VERSION").
This document is in TWO LANGUAGES. Spanish version first, English
version starts further below (search for "ENGLISH VERSION").


###############################################################################
#                                                                             #
#                          VERSION EN ESPANOL                                #
#                                                                             #
###############################################################################

-------------------------------------------------------------------------------
1. QUE ES ESTE PROGRAMA
-------------------------------------------------------------------------------
Windows Optimization es un conjunto de scripts para Windows 10 Pro x64
pensado para uso hogareño/gaming, que automatiza tareas de optimizacion
que normalmente se hacen a mano desde el Panel de Control, Configuracion
y el Editor del Registro. Todo queda registrado en archivos de log y es
reversible con la opcion "Restaurar Todo".

Lo que hace, en resumen:
  - Quita aplicaciones de Windows que no se usan (Cortana, Xbox Bar, Skype,
    Solitario, Contactos, Mapas, El Tiempo, Feedback Hub, Paint 3D, Visor 3D,
    Get Started, Mi Office, Peliculas y TV, Groove Music) y OneDrive.
  - Deshabilita la funcion opcional de Fax y Escaner.
  - Desactiva Copilot y los resultados/sugerencias de Bing en el buscador
    de Inicio (incluye el icono de la barra de tareas).
  - Desactiva servicios de telemetria y diagnostico que no aportan nada
    en un uso hogareño (Registro remoto, Mapas, Fax, Informe de errores,
    hosts de diagnostico, etc.).
  - Activa el plan de energia "Rendimiento Maximo", el Modo Juego de
    Windows, y ajusta los efectos visuales a "mejor rendimiento".
  - Verifica y activa TRIM en unidades SSD/NVMe.
  - Detecta tus discos (SSD, NVMe, HDD) automaticamente y, si un HDD
    tiene fragmentacion alta, te lo avisa y pregunta si queres
    desfragmentarlo (nunca lo hace sin preguntar, y nunca desfragmenta
    un SSD).
  - Genera un reporte de programas que arrancan con Windows (solo
    informativo, no desactiva nada por vos).
  - Verifica la integridad de los archivos del sistema (SFC) y los
    repara automaticamente si encuentra danos; si SFC no puede
    solucionarlo, te ofrece una reparacion mas profunda (DISM).
  - Informa la antiguedad del driver de tu placa de video y te avisa
    si conviene revisarlo (no lo actualiza automaticamente).
  - Ofrece limpieza opcional de archivos temporales (Temp de usuario y
    de sistema, cache de miniaturas, cache de descargas de Windows
    Update, cola de informes de error) y de la Papelera de Reciclaje.
  - Muestra un panel con informacion de tu equipo (version de Windows,
    sistema de archivos, RAM, GPU, discos) cada vez que abris el programa.

Lo que NUNCA toca, bajo ninguna opcion:
  - Impresora (cola de impresion).
  - Red local y recursos compartidos (archivos e impresoras en red).
  - Descubrimiento de dispositivos en red (para que la impresora y los
    recursos compartidos sigan siendo visibles desde otras PCs de la casa).
  - Audio de Windows.
  - Firewall de Windows.
  - Windows Defender.
  - Windows Update.

-------------------------------------------------------------------------------
2. REQUISITOS Y COMPATIBILIDAD
-------------------------------------------------------------------------------
  - Diseñado y probado en: Windows 10 Pro x64.
  - Windows 10 Home x64: deberia funcionar en la gran mayoria de las
    funciones (mismos servicios y aplicaciones). Unica excepcion
    conocida: el plan de energia "Rendimiento Maximo" puede no estar
    disponible en Home; si no se puede activar, el programa usa
    automaticamente "Alto rendimiento" en su lugar, sin generar error.
  - Windows 10 Enterprise/Education x64: deberia funcionar igual que
    Pro, no probado especificamente.
  - Windows 10 de 32 bits (x86): no probado. Es una version en
    desuso en hardware moderno.
  - Versiones de Windows 10 anteriores a la actualizacion 1809
    (2018): algunos ajustes (Modo Juego, Copilot) pueden no tener
    efecto por no existir esas funciones en esa version, pero no
    generan error.
  - Windows 11, Windows Server: NO compatible, no fue diseñado para
    estos sistemas.
  - El programa detecta tu version de Windows al iniciar y te avisa
    si no es la version para la que fue probado, dandote la opcion
    de continuar bajo tu propio riesgo o cancelar.
  - Requiere permisos de Administrador y PowerShell habilitado
    (viene por defecto en Windows 10).
  - Los archivos deben mantenerse juntos en su estructura de
    carpetas original (ver punto 3).

-------------------------------------------------------------------------------
3. ESTRUCTURA DE ARCHIVOS (no mover ni renombrar nada por separado)
-------------------------------------------------------------------------------
  WinOptimize\
  |-- WinOptimize.bat        <- ESTE es el unico archivo que abris
  |-- README.txt             <- este manual
  |-- App\                   <- scripts internos (no tocar)
  |-- Logs\                  <- se crea sola, detalle tecnico de cada accion
  |-- Configs\                <- se crea sola, guarda el estado original de tu PC

-------------------------------------------------------------------------------
4. COMO SE USA
-------------------------------------------------------------------------------
  1. Hace doble clic derecho sobre "WinOptimize.bat" y elegi
     "Ejecutar como administrador". Si lo abris sin permisos de
     administrador, el programa te lo va a pedir y se va a cerrar.
  2. El programa detecta el idioma de tu Windows automaticamente
     (espanol o ingles) y muestra el menu correspondiente.
  3. Arriba del menu vas a ver un panel con datos de tu equipo
     (Windows, RAM, GPU, discos) - es solo informativo.
  4. Elegi una opcion del menu:

     [1] OPTIMIZAR TODO
         Hace todos los cambios de la seccion 1 en un solo paso (5
         pasos automaticos). Te va a preguntar, antes de empezar, si
         queres crear un punto de restauracion del sistema
         (RECOMENDADO decir que si la primera vez que lo usas). Si
         detecta un disco HDD con fragmentacion alta, te va a
         preguntar si queres desfragmentarlo. Si la verificacion de
         archivos de sistema (SFC) encuentra danos que no puede
         reparar sola, te va a preguntar si queres una reparacion
         mas profunda (DISM, requiere internet).

     [2] RESTAURAR TODO
         Deshace exactamente lo que hizo la opcion [1], devolviendo
         cada servicio, cada configuracion y cada aplicacion al
         estado REAL que tenia tu PC antes de la primera vez que
         usaste el programa (no a un valor generico).

     [3] Limpiar temporales
         Libera espacio en disco borrando archivos que Windows
         regenera solo. Opcional, no hace falta para que [1] y [2]
         funcionen. Al final pregunta si tambien queres vaciar la
         Papelera de Reciclaje.

     [4] Ver diagnostico
         Solo lectura. Te muestra el estado actual de discos, GPU,
         plan de energia y Modo Juego, sin cambiar nada.

     [5] Configuracion avanzada
         Ajustes con algun tipo de compromiso (trade-off) que
         preferimos que decidas vos explicitamente. El programa te
         muestra la explicacion completa de cada uno antes de
         pedirte que confirmes:

           - Servicios extendidos
             Que es: procesos adicionales de Windows que casi nadie
             usa en una PC hogareña.
             Que hace: apaga Busqueda de Windows, SysMain, uso
             compartido de red de Windows Media Player, y el
             servicio biometrico.
             Que puede perjudicar: la busqueda instantanea del menu
             Inicio/Explorador deja de funcionar; el streaming DLNA
             a un Smart TV deja de funcionar; el login con huella o
             reconocimiento facial deja de funcionar.

           - UAC (Control de Cuentas de Usuario)
             Que es: la ventana que pide confirmar cuando un
             programa quiere hacer cambios importantes en Windows.
             Que hace: activarlo mantiene esa proteccion
             (recomendado); desactivarlo la elimina por completo.
             Que puede perjudicar: con UAC desactivado, cualquier
             programa -incluido malware- puede hacer cambios de
             administrador sin avisarte. Reduccion real de
             seguridad, no cosmetica.

           - HAGS (aceleracion de GPU por hardware)
             Que es: le permite a tu placa de video organizar sus
             propias tareas graficas con un chip dedicado, en vez
             de que Windows lo haga por software.
             Que hace: en teoria reduce la latencia y mejora la
             fluidez en juegos.
             Que puede perjudicar: en algunas combinaciones de
             placa+driver puede causar cuelgues o parpadeos. Placas
             anteriores a NVIDIA RTX 20-series o AMD RX 5000-series
             no tienen el chip necesario: activarlo ahi no rompe
             nada, pero tampoco cambia nada.

           - DNS rapido (Cloudflare)
             Que es: el "traductor" que convierte nombres de sitios
             web en direcciones reales de internet. Por defecto se
             usa el de tu proveedor.
             Que hace: lo cambia a Cloudflare (1.1.1.1), que suele
             responder mas rapido.
             Que puede perjudicar: en muy pocos casos, redes
             hogareñas con configuraciones particulares pueden tener
             problemas para que los dispositivos se encuentren entre
             si por nombre de red. Se guarda tu configuracion
             original para revertirla en cualquier momento.

         NO hace falta entrar aca para que el programa funcione bien.

     [6] Salir

  5. Al terminar cualquier accion, el programa te pregunta si queres
     reiniciar la PC. ALGUNOS CAMBIOS (Fax, tweaks de Copilot/Bing,
     Modo Juego, efectos visuales) solo se ven completos despues de
     reiniciar. Se recomienda decir que si cuando lo pregunte.

-------------------------------------------------------------------------------
5. LOGS Y CONFIGURACION GUARDADA
-------------------------------------------------------------------------------
  Dentro de la carpeta "Logs" vas a encontrar el detalle tecnico
  completo de cada accion (apps.log, services.log, performance.log,
  cleanup.log), con fecha y hora. Sirve para revisar que se hizo o
  para diagnosticar si algo no salio como esperabas.

  Dentro de la carpeta "Configs" el programa guarda, la primera vez
  que usas la opcion [1], una "foto" del estado real que tenia tu PC
  antes de tocar nada. Esa foto es la que se usa para la opcion [2].
  NO borres los archivos de "Configs" si en algun momento pensas usar
  "Restaurar Todo" - sin ellos, el programa no sabe a que estado
  volver.

-------------------------------------------------------------------------------
6. RECAUDOS DEL USUARIO (leer antes de usar)
-------------------------------------------------------------------------------
  - Usa este programa unicamente en Windows 10 Pro x64. No fue
    probado en Windows 11, Windows Server, ni en Windows 10 Home o
    en arquitectura de 32 bits.
  - Se recomienda ENFATICAMENTE crear un punto de restauracion del
    sistema (el programa te lo ofrece) antes de la primera
    ejecucion de "Optimizar Todo".
  - Se recomienda tener un respaldo (backup) de tus archivos
    importantes antes de usar cualquier herramienta que modifique
    configuraciones del sistema operativo, como buena practica
    general, independientemente de este programa en particular.
  - Si tu PC es una notebook, conectala a la corriente antes de usar
    la opcion [1]: el plan de energia "Rendimiento Maximo" prioriza
    velocidad por sobre duracion de bateria.
  - Revisa los logs despues de cada ejecucion si queres confirmar
    exactamente que se hizo en tu equipo.
  - Las opciones dentro de "Configuracion avanzada" (punto 4, opcion
    [5]) tienen efectos secundarios reales y conocidos (ver detalle
    en el menu del programa). Usalas solo si entendes y aceptas esos
    efectos secundarios.
  - No modifiques manualmente los archivos dentro de la carpeta
    "App" ni los archivos JSON dentro de "Configs" - podrias romper
    la capacidad del programa de restaurar tu sistema correctamente.

-------------------------------------------------------------------------------
7. DESCARGO DE RESPONSABILIDAD / LIMITACION DE RESPONSABILIDAD
-------------------------------------------------------------------------------
  Este software se entrega "TAL COMO ESTA" ("AS IS"), sin garantia
  de ningun tipo, expresa o implicita, incluyendo pero no limitado a
  garantias de funcionamiento ininterrumpido, ausencia de errores,
  o idoneidad para un proposito particular.

  El uso de este programa es de exclusiva responsabilidad del
  usuario. El autor, Marcelo Borasi, NO SE HACE RESPONSABLE por:
    - Perdida de datos, archivos o configuraciones.
    - Mal funcionamiento del sistema operativo, de hardware, de
      controladores (drivers), de juegos, de software de terceros,
      o de cualquier dispositivo conectado al equipo (incluyendo
      impresoras, discos externos, redes locales).
    - Incompatibilidades con software antivirus, de seguridad, o
      con politicas corporativas/empresariales.
    - Cualquier dano directo, indirecto, incidental o consecuente
      que resulte del uso, mal uso, o imposibilidad de uso de este
      programa.
    - Cambios introducidos por actualizaciones de Windows que
      puedan alterar, revertir o entrar en conflicto con las
      configuraciones aplicadas por este programa despues de su
      ejecucion.

  Al ejecutar este programa, el usuario declara haber leido y
  aceptado este descargo de responsabilidad, y asume por su cuenta
  y riesgo cualquier consecuencia derivada de su uso.

  Este programa NO esta afiliado a Microsoft Corporation, NVIDIA
  Corporation, ni Advanced Micro Devices (AMD). Windows, Xbox,
  OneDrive y Copilot son marcas registradas de Microsoft
  Corporation. NVIDIA y GeForce son marcas de NVIDIA Corporation.
  AMD y Radeon son marcas de Advanced Micro Devices, Inc. Se
  mencionan unicamente con fines descriptivos/tecnicos.

-------------------------------------------------------------------------------
8. AUTOR Y DONACIONES
-------------------------------------------------------------------------------
  Autor: Marcelo Borasi
  Version: Windows Optimization v1.0
  Fecha: 07/26

  Si este programa te resulto util y queres apoyar su desarrollo,
  cualquier donacion via PayPal es bienvenida (opcional, nunca
  obligatoria):

  PayPal: https://www.paypal.com/ncp/payment/UPWB5GE266VXG

  Gracias por usar Windows Optimization.


###############################################################################
#                                                                             #
#                            ENGLISH VERSION                                 #
#                                                                             #
###############################################################################

-------------------------------------------------------------------------------
1. WHAT THIS PROGRAM DOES
-------------------------------------------------------------------------------
Windows Optimization is a set of scripts for Windows 10 Pro x64,
built for home/gaming use, that automates optimization tasks
normally done by hand through Control Panel, Settings, and the
Registry Editor. Everything is logged, and everything is reversible
using the "Restore Everything" option.

Summary of what it does:
  - Removes unused Windows apps (Cortana, Xbox Bar, Skype,
    Solitaire, Contacts, Maps, Weather, Feedback Hub, Paint 3D,
    3D Viewer, Get Started, My Office, Movies & TV, Groove Music)
    and OneDrive.
  - Disables the optional Fax and Scan feature.
  - Disables Copilot and Bing results/suggestions in the Start
    search box (including the taskbar icon).
  - Disables telemetry and diagnostic services that add nothing
    in a home setup (Remote Registry, Maps, Fax, Error Reporting,
    diagnostic hosts, etc.).
  - Enables the "Ultimate Performance" power plan, Windows Game
    Mode, and sets visual effects to "best performance".
  - Checks and enables TRIM on SSD/NVMe drives.
  - Auto-detects your disks (SSD, NVMe, HDD) and, if an HDD has
    high fragmentation, warns you and asks whether to defragment
    it (never does it without asking, and never defragments an
    SSD).
  - Generates a report of programs that start with Windows
    (informational only, doesn't disable anything for you).
  - Checks system file integrity (SFC) and automatically repairs
    any damage found; if SFC can't fix it, offers a deeper repair
    (DISM).
  - Reports your GPU driver's age and flags it if it's worth
    checking for an update (doesn't update it automatically).
  - Offers optional cleanup of temporary files (user and system
    Temp, thumbnail cache, Windows Update download cache, error
    report queue) and the Recycle Bin.
  - Shows a system info panel (Windows version, file system, RAM,
    GPU, disks) every time you open the program.

What it NEVER touches, under any option:
  - Printer (print spooler).
  - Local network and shared resources (network files/printers).
  - Network device discovery (so the printer and shared resources
    stay visible from other PCs on the home network).
  - Windows Audio.
  - Windows Firewall.
  - Windows Defender.
  - Windows Update.

-------------------------------------------------------------------------------
2. REQUIREMENTS AND COMPATIBILITY
-------------------------------------------------------------------------------
  - Designed and tested on: Windows 10 Pro x64.
  - Windows 10 Home x64: should work for the large majority of
    features (same services and apps). One known exception: the
    "Ultimate Performance" power plan may not be available on Home;
    if it can't be enabled, the program automatically falls back to
    "High Performance" instead, without raising an error.
  - Windows 10 Enterprise/Education x64: should work the same as
    Pro, not specifically tested.
  - Windows 10 32-bit (x86): not tested. This is a largely
    discontinued edition on modern hardware.
  - Windows 10 versions older than the 1809 update (2018): some
    tweaks (Game Mode, Copilot) may have no effect since those
    features don't exist on that version, but they won't cause
    errors.
  - Windows 11, Windows Server: NOT compatible, not designed for
    these systems.
  - The program detects your Windows version at startup and warns
    you if it's not the version it was tested for, letting you
    choose to continue at your own risk or cancel.
  - Requires Administrator permissions and PowerShell enabled
    (default on Windows 10).
  - Keep the files together in their original folder structure
    (see section 3).

-------------------------------------------------------------------------------
3. FILE STRUCTURE (do not move or rename anything individually)
-------------------------------------------------------------------------------
  WinOptimize\
  |-- WinOptimize.bat        <- THIS is the only file you open
  |-- README.txt             <- this manual
  |-- App\                   <- internal scripts (do not touch)
  |-- Logs\                  <- created automatically, technical detail per action
  |-- Configs\                <- created automatically, stores your PC's original state

-------------------------------------------------------------------------------
4. HOW TO USE IT
-------------------------------------------------------------------------------
  1. Right-click "WinOptimize.bat" and choose "Run as
     administrator". If opened without admin rights, the program
     will tell you and close.
  2. The program auto-detects your Windows display language
     (Spanish or English) and shows the matching menu.
  3. Above the menu you'll see a panel with your system's info
     (Windows, RAM, GPU, disks) - informational only.
  4. Pick an option:

     [1] OPTIMIZE EVERYTHING
         Applies all the changes from section 1 in a single step (5
         automatic stages). Before starting, it asks whether to
         create a system restore point (RECOMMENDED to say yes the
         first time you use it). If it detects an HDD with high
         fragmentation, it will ask whether to defragment it. If the
         system file check (SFC) finds damage it can't repair on its
         own, it will ask whether you want a deeper repair (DISM,
         requires internet).

     [2] RESTORE EVERYTHING
         Undoes exactly what option [1] did, returning every
         service, setting and app to the REAL state your PC had
         before you first used the program (not a generic default).

     [3] Clean temp files
         Frees disk space by deleting files Windows regenerates on
         its own. Optional, not required for [1] and [2] to work.
         Afterward it asks whether to also empty the Recycle Bin.

     [4] View diagnostics
         Read-only. Shows the current state of disks, GPU, power
         plan and Game Mode, without changing anything.

     [5] Advanced settings
         Settings with a real trade-off that we intentionally
         leave for you to decide. The program shows the full
         explanation of each one before asking you to confirm:

           - Extended services
             What it is: extra Windows processes almost nobody
             uses on a home PC.
             What it does: disables Windows Search, SysMain,
             Windows Media Player Network Sharing, and the
             biometric service.
             What it can break: instant search in the Start
             menu/Explorer stops working; DLNA streaming to a
             Smart TV stops working; fingerprint or facial
             recognition sign-in stops working.

           - UAC (User Account Control)
             What it is: the prompt that asks for confirmation
             when a program wants to make important changes to
             Windows.
             What it does: enabling keeps that protection
             (recommended); disabling removes it entirely.
             What it can hurt: with UAC disabled, any program -
             including malware - can make administrator-level
             changes without warning you. A real security
             reduction, not a cosmetic one.

           - HAGS (hardware-accelerated GPU scheduling)
             What it is: lets your GPU organize its own graphics
             tasks using a dedicated chip, instead of Windows doing
             it by software.
             What it does: in theory, reduces latency and improves
             smoothness in games.
             What it can hurt: on some GPU+driver combinations it
             can cause freezes or flickering. GPUs older than
             NVIDIA RTX 20-series or AMD RX 5000-series lack the
             required chip: enabling it there breaks nothing, but
             also changes nothing.

           - Fast DNS (Cloudflare)
             What it is: the "translator" that converts website
             names into real internet addresses. By default you
             use your provider's.
             What it does: switches it to Cloudflare (1.1.1.1),
             which usually responds faster.
             What it can hurt: in very few cases, home networks
             with particular setups may have trouble finding
             devices by network name. Your original settings are
             saved so you can revert at any time.

         You never need to go in here for the program to work well.

     [6] Exit

  5. After any action finishes, the program asks whether to
     restart the PC. SOME CHANGES (Fax, Copilot/Bing tweaks, Game
     Mode, visual effects) only show up fully after a restart.
     It's recommended to say yes when asked.

-------------------------------------------------------------------------------
5. LOGS AND SAVED CONFIGURATION
-------------------------------------------------------------------------------
  Inside the "Logs" folder you'll find the full technical detail of
  every action (apps.log, services.log, performance.log,
  cleanup.log), with date and time. Useful to review what was done
  or to troubleshoot if something didn't go as expected.

  Inside the "Configs" folder, the first time you use option [1],
  the program saves a "snapshot" of your PC's real state before
  touching anything. That snapshot is what option [2] uses. DO NOT
  delete the files inside "Configs" if you may ever want to use
  "Restore Everything" - without them, the program has no state to
  return to.

-------------------------------------------------------------------------------
6. USER PRECAUTIONS (read before using)
-------------------------------------------------------------------------------
  - Use this program only on Windows 10 Pro x64. It was not tested
    on Windows 11, Windows Server, Windows 10 Home, or 32-bit
    architectures.
  - It is STRONGLY recommended to create a system restore point
    (the program offers this) before the first run of "Optimize
    Everything".
  - It is recommended to keep a backup of your important files
    before using any tool that modifies operating system settings,
    as general good practice, independent of this specific program.
  - If your PC is a laptop, plug it in before using option [1]:
    the "Ultimate Performance" power plan prioritizes speed over
    battery life.
  - Review the logs after each run if you want to confirm exactly
    what was done on your machine.
  - The options inside "Advanced settings" (section 4, option [5])
    have real, known side effects (see detail in the program's
    menu). Use them only if you understand and accept those side
    effects.
  - Do not manually edit the files inside the "App" folder or the
    JSON files inside "Configs" - doing so could break the
    program's ability to correctly restore your system.

-------------------------------------------------------------------------------
7. DISCLAIMER / LIMITATION OF LIABILITY
-------------------------------------------------------------------------------
  This software is provided "AS IS", without warranty of any kind,
  express or implied, including but not limited to warranties of
  uninterrupted operation, error-free performance, or fitness for a
  particular purpose.

  Use of this program is the sole responsibility of the user. The
  author, Marcelo Borasi, IS NOT RESPONSIBLE for:
    - Loss of data, files, or configurations.
    - Malfunction of the operating system, hardware, drivers,
      games, third-party software, or any device connected to the
      computer (including printers, external drives, local
      networks).
    - Incompatibilities with antivirus or security software, or
      with corporate/enterprise policies.
    - Any direct, indirect, incidental, or consequential damages
      resulting from the use, misuse, or inability to use this
      program.
    - Changes introduced by Windows updates that may alter, revert,
      or conflict with the settings applied by this program after
      it runs.

  By running this program, the user acknowledges having read and
  accepted this disclaimer, and assumes, at their own risk, any
  consequence arising from its use.

  This program is NOT affiliated with Microsoft Corporation, NVIDIA
  Corporation, or Advanced Micro Devices (AMD). Windows, Xbox,
  OneDrive, and Copilot are registered trademarks of Microsoft
  Corporation. NVIDIA and GeForce are trademarks of NVIDIA
  Corporation. AMD and Radeon are trademarks of Advanced Micro
  Devices, Inc. They are mentioned solely for descriptive/technical
  purposes.

-------------------------------------------------------------------------------
8. AUTHOR AND DONATIONS
-------------------------------------------------------------------------------
  Author: Marcelo Borasi
  Version: Windows Optimization v1.0
  Date: 07/26

  If this program was useful to you and you'd like to support its
  development, any donation via PayPal is welcome (optional, never
  required):

  PayPal: https://www.paypal.com/ncp/payment/UPWB5GE266VXG

  Thank you for using Windows Optimization.

===============================================================================
                              END OF DOCUMENT / FIN DEL DOCUMENTO
===============================================================================
