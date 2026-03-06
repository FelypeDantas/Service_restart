@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
TITLE Restart de Servicos - Enterprise

:: ============================
:: CONFIGURACOES
:: ============================
SET LOG_DIR=C:\Logs
SET MAX_WAIT=60
SET DRY_RUN=0
SET EVENT_SOURCE=ServiceRestartScript

:: ============================
:: VALIDA ADMIN
:: ============================
NET SESSION >NUL 2>&1
IF %ERRORLEVEL% NEQ 0 (
    ECHO ERRO: Execute como Administrador.
    EXIT /B 10
)

:: ============================
:: PARAMETROS
:: ============================
IF "%~1"=="" GOTO MENU
IF "%~2"=="" (
    ECHO Uso:
    ECHO restart-service-enterprise.bat SERVIDORES "Servico" [/dryrun]
    EXIT /B 1
)

IF /I "%~3"=="/dryrun" SET DRY_RUN=1

SET SERVIDORES=%~1
SET SERVICO=%~2

:: ============================
:: PREPARA LOG
:: ============================
IF NOT EXIST "%LOG_DIR%" mkdir "%LOG_DIR%"
SET LOG_FILE=%LOG_DIR%\restart_%SERVICO%_%DATE:~6,4%-%DATE:~3,2%-%DATE:~0,2%.log

CALL :LOG "=== INICIO DA EXECUCAO ==="
CALL :LOG "Servidores: %SERVIDORES%"
CALL :LOG "Servico: %SERVICO%"
CALL :LOG "DryRun: %DRY_RUN%"

:: ============================
:: LOOP DE SERVIDORES
:: ============================
FOR %%S IN (%SERVIDORES:,= %) DO (
    CALL :LOG "[%%S] Verificando estado do servico..."

    REM Consulta o estado real do serviço
    FOR /F "tokens=3" %%A IN ('sc "\\%%S" query "%SERVICO%" ^| findstr /C:"STATE"') DO SET STATE=%%A

    IF "!STATE!"=="" (
        CALL :LOG "[%%S] ERRO: Servico nao encontrado"
        ECHO [%%S] ^[ERRO^] Servico nao encontrado
        GOTO NEXT_SERVER
    )

    IF "!STATE!"=="RUNNING" (
        ECHO [%%S] Servico RUNNING
        CALL :LOG "[%%S] Servico RUNNING"

        IF "%DRY_RUN%"=="1" (
            CALL :LOG "[%%S] DRY-RUN: stop/start ignorados"
            ECHO [%%S] Dry-run ativo, reinicio ignorado
        ) ELSE (
            CALL :EVENT "[%%S] Reiniciando servico %SERVICO%"

            sc "\\%%S" stop "%SERVICO%" >> "%LOG_FILE%" 2>&1
            CALL :WAIT %%S STOPPED

            sc "\\%%S" start "%SERVICO%" >> "%LOG_FILE%" 2>&1
            CALL :WAIT %%S RUNNING

            CALL :LOG "[%%S] Servico reiniciado com sucesso"
            ECHO [%%S] Servico reiniciado
        )
    ) ELSE (
        CALL :LOG "[%%S] Estado atual: !STATE!"
        ECHO [%%S] Estado atual: !STATE!
    )

    :NEXT_SERVER
)

CALL :LOG "=== EXECUCAO FINALIZADA ==="
EXIT /B 0

:: ============================
:: MENU INTERATIVO
:: ============================
:MENU
ECHO ================================
ECHO  RESTART DE SERVICOS - ENTERPRISE
ECHO ================================
SET /P SERVIDORES=Informe os servidores (ex: SRV01,SRV02):
SET /P SERVICO=Informe o nome do servico:
SET /P CONFIRMA=Dry run? (S/N):

IF /I "%CONFIRMA%"=="S" SET DRY_RUN=1
GOTO CONTINUE

:CONTINUE
GOTO :EOF

:: ============================
:: FUNCAO: AGUARDA ESTADO
:: ============================
:WAIT
SET SERVER=%1
SET EXPECTED=%2
SET ELAPSED=0

:WAIT_LOOP
FOR /F "tokens=3" %%A IN ('sc "\\%SERVER%" query "%SERVICO%" ^| findstr /C:"STATE"') DO SET CURRENT=%%A

IF "!CURRENT!"=="%EXPECTED%" EXIT /B 0

IF !ELAPSED! GEQ %MAX_WAIT% (
    CALL :LOG "[%SERVER%] TIMEOUT aguardando %EXPECTED%"
    ECHO [%SERVER%] TIMEOUT aguardando %EXPECTED%
    EXIT /B 20
)

TIMEOUT /T 2 >NUL
SET /A ELAPSED+=2
GOTO WAIT_LOOP

:: ============================
:: LOG
:: ============================
:LOG
SET TIMESTAMP=%DATE% %TIME%
ECHO !TIMESTAMP! - %~1
ECHO !TIMESTAMP! - %~1 >> "%LOG_FILE%"
EXIT /B

:: ============================
:: EVENT VIEWER
:: ============================
:EVENT
EVENTCREATE /T INFORMATION /ID 100 /L APPLICATION /SO "%EVENT_SOURCE%" /D "%~1" >NUL 2>&1
EXIT /B
