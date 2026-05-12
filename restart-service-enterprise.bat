@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
TITLE Restart de Servicos - Enterprise

:: =====================================================
::  RESTART DE SERVICOS WINDOWS - ENTERPRISE EDITION
:: =====================================================
::  Recursos:
::   - Multi-servidor
::   - Dry-run
::   - Timeout de espera
::   - Logging
::   - Event Viewer
::   - Validacao de Admin
::   - Tratamento basico de erros
:: =====================================================

:: ============================
:: CONFIGURACOES
:: ============================
SET "LOG_DIR=C:\Logs"
SET "MAX_WAIT=60"
SET "DRY_RUN=0"
SET "EVENT_SOURCE=ServiceRestartScript"

:: ============================
:: VALIDACAO ADMIN
:: ============================
NET SESSION >NUL 2>&1
IF %ERRORLEVEL% NEQ 0 (
    ECHO.
    ECHO [ERRO] Execute este script como Administrador.
    ECHO.
    EXIT /B 10
)

:: ============================
:: PARAMETROS
:: ============================
IF "%~1"=="" GOTO MENU

IF "%~2"=="" (
    ECHO.
    ECHO Uso:
    ECHO restart-service-enterprise.bat SERVIDORES "Servico" [/dryrun]
    ECHO.
    ECHO Exemplo:
    ECHO restart-service-enterprise.bat SRV01,SRV02 "Spooler" /dryrun
    ECHO.
    EXIT /B 1
)

SET "SERVIDORES=%~1"
SET "SERVICO=%~2"

IF /I "%~3"=="/dryrun" (
    SET "DRY_RUN=1"
)

GOTO START

:: ============================
:: MENU INTERATIVO
:: ============================
:MENU
CLS
ECHO ============================================
ECHO   RESTART DE SERVICOS - ENTERPRISE
ECHO ============================================
ECHO.

SET /P SERVIDORES=Informe os servidores (ex: SRV01,SRV02): 
SET /P SERVICO=Informe o nome do servico: 
SET /P CONFIRMA=Executar em modo DRY-RUN? (S/N): 

IF /I "%CONFIRMA%"=="S" (
    SET "DRY_RUN=1"
)

GOTO START

:: ============================
:: FLUXO PRINCIPAL
:: ============================
:START

:: CRIA DIRETORIO DE LOG
IF NOT EXIST "%LOG_DIR%" (
    MKDIR "%LOG_DIR%"
)

:: SANITIZA NOME DO SERVICO
SET "SAFE_SERVICE=%SERVICO: =_%"
SET "SAFE_SERVICE=%SAFE_SERVICE:/=_%"
SET "SAFE_SERVICE=%SAFE_SERVICE:\=_%"

:: GERA LOG
SET "LOG_FILE=%LOG_DIR%\restart_%SAFE_SERVICE%_%DATE:~6,4%-%DATE:~3,2%-%DATE:~0,2%.log"

CALL :LOG "========================================"
CALL :LOG "INICIO DA EXECUCAO"
CALL :LOG "Servidores: %SERVIDORES%"
CALL :LOG "Servico: %SERVICO%"
CALL :LOG "DryRun: %DRY_RUN%"
CALL :LOG "========================================"

ECHO.
ECHO ============================================
ECHO INICIANDO PROCESSAMENTO...
ECHO ============================================
ECHO.

:: LOOP DE SERVIDORES
FOR %%S IN (%SERVIDORES:,= %) DO (

    SET "STATE="
    SET "CURRENT="

    CALL :LOG "[%%S] Verificando servico..."

    :: CONSULTA STATUS
    FOR /F "tokens=3" %%A IN (
        'sc "\\%%S" query "%SERVICO%" ^| findstr /C:"STATE"'
    ) DO (
        SET "STATE=%%A"
    )

    :: SERVICO NAO ENCONTRADO
    IF "!STATE!"=="" (

        CALL :LOG "[%%S] ERRO: Servico nao encontrado"
        ECHO [%%S] [ERRO] Servico nao encontrado
        ECHO.

    ) ELSE (

        CALL :LOG "[%%S] Estado atual: !STATE!"
        ECHO [%%S] Estado atual: !STATE!

        :: SERVICO RUNNING
        IF /I "!STATE!"=="RUNNING" (

            IF "%DRY_RUN%"=="1" (

                CALL :LOG "[%%S] DRY-RUN ativo. Nenhuma acao executada."
                ECHO [%%S] DRY-RUN ativo. Reinicio ignorado.
                ECHO.

            ) ELSE (

                CALL :EVENT "[%%S] Reiniciando servico %SERVICO%"

                :: STOP
                CALL :LOG "[%%S] Parando servico..."
                ECHO [%%S] Parando servico...

                sc "\\%%S" stop "%SERVICO%" >> "%LOG_FILE%" 2>&1

                IF !ERRORLEVEL! NEQ 0 (

                    CALL :LOG "[%%S] ERRO ao enviar comando STOP"
                    ECHO [%%S] [ERRO] Falha ao parar servico
                    ECHO.

                ) ELSE (

                    CALL :WAIT %%S STOPPED

                    IF !ERRORLEVEL! NEQ 0 (

                        CALL :LOG "[%%S] TIMEOUT aguardando STOPPED"
                        ECHO [%%S] [ERRO] Timeout no STOP
                        ECHO.

                    ) ELSE (

                        :: START
                        CALL :LOG "[%%S] Iniciando servico..."
                        ECHO [%%S] Iniciando servico...

                        sc "\\%%S" start "%SERVICO%" >> "%LOG_FILE%" 2>&1

                        IF !ERRORLEVEL! NEQ 0 (

                            CALL :LOG "[%%S] ERRO ao enviar comando START"
                            ECHO [%%S] [ERRO] Falha ao iniciar servico
                            ECHO.

                        ) ELSE (

                            CALL :WAIT %%S RUNNING

                            IF !ERRORLEVEL! NEQ 0 (

                                CALL :LOG "[%%S] TIMEOUT aguardando RUNNING"
                                ECHO [%%S] [ERRO] Timeout no START
                                ECHO.

                            ) ELSE (

                                CALL :LOG "[%%S] Servico reiniciado com sucesso"
                                ECHO [%%S] Servico reiniciado com sucesso
                                ECHO.
                            )
                        )
                    )
                )
            )

        ) ELSE (

            ECHO [%%S] Nenhuma acao executada.
            ECHO.
        )
    )
)

CALL :LOG "========================================"
CALL :LOG "EXECUCAO FINALIZADA"
CALL :LOG "========================================"

ECHO ============================================
ECHO EXECUCAO FINALIZADA
ECHO LOG: %LOG_FILE%
ECHO ============================================
ECHO.

EXIT /B 0

:: ============================
:: FUNCAO WAIT
:: ============================
:WAIT
SET "SERVER=%~1"
SET "EXPECTED=%~2"
SET "ELAPSED=0"

:WAIT_LOOP

SET "CURRENT="

FOR /F "tokens=3" %%A IN (
    'sc "\\%SERVER%" query "%SERVICO%" ^| findstr /C:"STATE"'
) DO (
    SET "CURRENT=%%A"
)

IF /I "!CURRENT!"=="%EXPECTED%" (
    EXIT /B 0
)

IF !ELAPSED! GEQ %MAX_WAIT% (
    EXIT /B 20
)

TIMEOUT /T 2 >NUL
SET /A ELAPSED+=2

GOTO WAIT_LOOP

:: ============================
:: FUNCAO LOG
:: ============================
:LOG
SET "TIMESTAMP=%DATE% %TIME%"
ECHO !TIMESTAMP! - %~1
ECHO !TIMESTAMP! - %~1 >> "%LOG_FILE%"
EXIT /B 0

:: ============================
:: EVENT VIEWER
:: ============================
:EVENT
EVENTCREATE ^
 /T INFORMATION ^
 /ID 100 ^
 /L APPLICATION ^
 /SO "%EVENT_SOURCE%" ^
 /D "%~1" >NUL 2>&1

EXIT /B 0
