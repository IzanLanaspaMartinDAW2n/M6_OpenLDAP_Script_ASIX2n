@echo off
setlocal

REM Defineix la URL de descàrrega de pGina
set "PGINA_URL=https://github.com/pgina/pgina/releases/download/v3.1.8.0/pGinaSetup-3.1.8.0.exe"

REM Defineix el directori de descàrrega i el nom del fitxer
set "DOWNLOAD_DIR=C:\Descargas"
set "PGINA_FILE=%DOWNLOAD_DIR%\pGinaSetup-3.1.8.0.exe"

REM Crear el directori si no existeix
if not exist "%DOWNLOAD_DIR%" (
    mkdir "%DOWNLOAD_DIR%"
)

REM Descarregar pGina
echo Descarregant pGina en %DOWNLOAD_DIR%...
powershell -Command "try { Invoke-WebRequest -Uri '%PGINA_URL%' -OutFile '%PGINA_FILE%' -ErrorAction Stop; Write-Host 'Descàrrega completa.' } catch { Write-Host 'Error descarregant el fitxer: $_'; exit 1 }"

REM Verificar si el fitxer es va descarregar correctament
if not exist "%PGINA_FILE%" (
    echo Error: No s'ha pogut descarregar el fitxer des de %PGINA_URL%.
    echo Verifica la teva connexió a Internet o la URL.
    pause
    exit /b 1
)

REM Instal·lar pGina
echo Instal·lant pGina...
start "" "%PGINA_FILE%"  REM Executar sense modificador

REM Netejar
echo Netejant fitxers temporals...
del "%PGINA_FILE%"

echo Instal·lació completada.
pause
endlocal
