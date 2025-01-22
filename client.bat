@echo off
:: Comprovar si dsquery està disponible
echo Verificant si 'dsquery' està instal·lat...
where dsquery >nul 2>&1
if errorlevel 1 (
    echo 'dsquery' no està instal·lat. Intentant instal·lar-lo...
    
    :: Verificar si el sistema suporta RSAT i instal·lar
    for /f "tokens=2 delims==" %%i in ('wmic os get version /value ^| find "="') do set WINVER=%%i
    if "%WINVER%" geq "10.0.17763" (
        echo Instal·lant RSAT amb DISM...
        dism /online /add-capability /capabilityname:Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
        if errorlevel 1 (
            echo Error: No s'ha pogut instal·lar RSAT. Comprova la connexió a Internet o els permisos d'administrador.
            pause
            exit /b 1
        )
        echo RSAT instal·lat correctament.
    ) else (
        echo La versió de Windows no suporta aquesta instal·lació automàtica.
        echo Visita https://aka.ms/rsat per descarregar les eines RSAT manualment.
        pause
        exit /b 1
    )
) else (
    echo 'dsquery' està disponible.
)

:: Sol·licitar la IP del servidor LDAP
set /p LDAP_SERVER_IP=Introdueix la IP del servidor LDAP: 

:: Variables
set LDAP_BASE=dc=example,dc=com
set LDAP_ADMIN_DN=cn=admin,%LDAP_BASE%
set LDAP_ADMIN_PASSWORD=adminpassword

:: Verificar connexió al servidor LDAP
echo Verificant la connexió al servidor LDAP...
dsquery * ldap://%LDAP_SERVER_IP% -b %LDAP_BASE% -s sub -d %LDAP_ADMIN_DN% -w %LDAP_ADMIN_PASSWORD% > nul
if errorlevel 1 (
    echo Error: No s'ha pogut connectar al servidor LDAP. Revisa la IP, DN i contrasenya.
    pause
    exit /b 1
)
echo Connexió exitosa al servidor LDAP.

:: Configurar LDAP al sistema
echo Configurant LDAP al sistema...

:: Configuració del registre per a LDAP (exemple genèric)
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /v GINA /t REG_SZ /d Msgina.dll /f
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\LDAP" /v Server /t REG_SZ /d %LDAP_SERVER_IP% /f
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\LDAP" /v BaseDN /t REG_SZ /d %LDAP_BASE% /f

:: Prova d'autenticació amb LDAP
echo Provant autenticació amb LDAP...
dsquery * ldap://%LDAP_SERVER_IP% -b %LDAP_BASE% -s sub -d %LDAP_ADMIN_DN% -w %LDAP_ADMIN_PASSWORD% || (
    echo Error en la prova d'autenticació LDAP.
    pause
    exit /b 1
)

:: Finalització
echo Configuració del client LDAP completada correctament.
pause
