<h1 align="center">⚙️ enterprise-service-restart </h1>

<p align="center">
  Ferramenta de automação para reinício seguro de serviços Windows em múltiplos servidores <br/>
  Controle serviços remotamente com logging, timeout e modo de simulação diretamente pelo terminal.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/status-concluído-green"/>
  <img src="https://img.shields.io/badge/license-MIT-blue"/>
  <img src="https://img.shields.io/badge/windows-batch-yellow"/>
  <img src="https://img.shields.io/badge/interface-CLI-purple"/>
  <img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg"/>
</p>

---

## 🧠 Sobre o Projeto

Este projeto é uma **ferramenta de automação para gerenciamento de serviços Windows** desenvolvida utilizando **Batch Script**.

A ferramenta permite **reiniciar serviços em múltiplos servidores de forma segura**, realizando verificações de estado, registrando logs e evitando falhas comuns durante a operação.

O script utiliza o utilitário `sc`, responsável por interagir com o **Service Control Manager do Windows**, permitindo consultar, iniciar e parar serviços diretamente pela linha de comando. :contentReference[oaicite:0]{index=0}

Principais funcionalidades:

- 🖥️ Reinício automático de serviços em múltiplos servidores
- 🔎 Verificação do estado do serviço antes da operação
- ⏱️ Controle de timeout durante start/stop
- 🧪 Modo **Dry Run** para simulação segura
- 📝 Geração de logs detalhados
- 📊 Registro de eventos no **Event Viewer**
- 🛡️ Validação de execução com privilégios administrativos

Durante a execução, o sistema pode identificar:

- 🟢 Serviços em execução (`RUNNING`)
- 🔴 Serviços parados (`STOPPED`)
- ⏳ Serviços em transição (`START_PENDING` / `STOP_PENDING`)
- ❌ Serviços inexistentes ou inacessíveis
- ⚠️ Falhas de reinicialização

Esse projeto é interessante para estudar:

- automação de administração de sistemas
- gerenciamento de serviços Windows
- scripting com Batch
- controle de processos remotos
- logging e auditoria de operações
- ferramentas CLI para infraestrutura

---

## 🚀 Tecnologias Utilizadas

Este projeto foi desenvolvido utilizando:

- ✅ Windows Batch Script
- ✅ Windows Service Control (`sc`)
- ✅ Event Viewer
- ✅ automação de administração de sistemas
- ✅ execução remota de serviços
- ✅ interface CLI

---

## ⚙️ Funcionalidades

### 🔄 Reinício automatizado de serviços

Reinicia serviços em múltiplos servidores com validação de estado.

Exemplo:

```
restart-service-enterprise.bat SRV01,SRV02 Spooler
```

---

### 🧪 Modo Dry Run (Simulação)

Permite executar o script sem reiniciar serviços.

Útil para validação antes da execução real.

Isso permite integração com:

- sistemas de monitoramento
- auditoria de infraestrutura
- ferramentas de observabilidade

---

## 📦 Como usar

Clone o repositório:

```bash
git clone https://github.com/SEU_USUARIO/enterprise-service-restart.git
cd enterprise-service-restart
```

Execute o script:
```
restart-service-enterprise.bat SERVIDORES "Servico"
```

Exemplo:
```
restart-service-enterprise.bat SRV01,SRV02 Spooler
```

<h2>Requisitos</h2>
<ul>
  <li>Windows 10 ou superior</li>
  <li>Permissões administrativas</li>
  <li>Acesso remoto aos servidores alvo</li>
  <li>Serviço existente nos servidores especificados</li>
</ul>
