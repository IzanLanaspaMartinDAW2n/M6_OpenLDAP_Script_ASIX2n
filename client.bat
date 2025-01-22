@echo off
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
