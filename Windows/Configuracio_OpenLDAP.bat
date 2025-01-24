@echo off
setlocal

REM Variables de configuracion
set "PGINA_CONFIG_PATH=C:\Program Files\pGina\pGina.Configuration.exe.config"
set "TEMPLATE_PATH=C:\Script\template.xml"
set "TEMP_CONFIG_FILE=%TEMP%\pgina.config"
set "LDAP_SERVER=ldap://10.0.110.52"
set "LDAP_PORT=389"
set "LDAP_BASE_DN=dc=exemple,dc=com"
set "LDAP_BIND_DN=cn=admin,dc=exemple,dc=com"
set "LDAP_PASSWORD=adminpassword"

REM Verificar si el archivo base existe
if not exist "%TEMPLATE_PATH%" (
    echo Error: No se encuentra el archivo base de configuracion en "%TEMPLATE_PATH%".
    pause
    exit /b 1
)

REM Leer el archivo base y reemplazar variables
echo Generando archivo temporal de configuracion...
(
    for /f "tokens=*" %%A in ('type "%TEMPLATE_PATH%"') do (
        set "line=%%A"
        setlocal enabledelayedexpansion
        set "line=!line:{LDAP_SERVER}=%LDAP_SERVER%!"
        set "line=!line:{LDAP_PORT}=%LDAP_PORT%!"
        set "line=!line:{LDAP_BIND_DN}=%LDAP_BIND_DN%!"
        set "line=!line:{LDAP_PASSWORD}=%LDAP_PASSWORD%!"
        echo !line!>> "%TEMP_CONFIG_FILE%"
        endlocal
    )
)

REM Validar si el archivo temporal fue creado correctamente
if not exist "%TEMP_CONFIG_FILE%" (
    echo Error: No se pudo crear el archivo temporal de configuracion.
    pause
    exit /b 1
)

REM Mostrar contenido del archivo temporal
echo Archivo temporal creado correctamente. Contenido:
type "%TEMP_CONFIG_FILE%"
pause

REM Sobrescribir el archivo de configuracion existente
echo Sobrescribiendo archivo de configuracion en "%PGINA_CONFIG_PATH%"...
copy /Y "%TEMP_CONFIG_FILE%" "%PGINA_CONFIG_PATH%"
if errorlevel 1 (
    echo Error: No se pudo sobrescribir el archivo de configuracion. Verifica permisos.
    del "%TEMP_CONFIG_FILE%"
    pause
    exit /b 1
)

REM Limpiar archivo temporal
del "%TEMP_CONFIG_FILE%"

echo Configuracion completada. pGina está configurado para usar OpenLDAP.
pause
endlocal

