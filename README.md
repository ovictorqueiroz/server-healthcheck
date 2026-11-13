# 🚀 Linux Healthcheck Script: Diagnóstico Rápido de Servidores

Todos que trabalham com suporte ou administrando redes já passaram por isso.
O cliente liga falando: 📞😡 *- Meu site está fora do ar!*

Nesses cenários, o primeiro troubleshoot é verificar a saúde da máquina. Rodamos `top`, `df -h`, `free -h` e muitos outros comandos repetitivos para diagnosticar a raiz do problema. 

Pensando nisso, criei este script para rodar em ambientes Linux. Ele executa todos esses comandos vitais — e mais alguns —, entregando os resultados de forma estruturada, com *syntax highlight* (cores) e em etapas, numa tacada só!

## 🛠️ O que o Script nos retorna?

A nova versão é modular e conta com um **fluxo interativo**. Você roda o diagnóstico principal e o script pergunta se deseja se aprofundar na rede ou nos serviços:

### Módulo 1: Servidor e Hardware (Automático)
- **Informações do Servidor:** Detalhes de Hostname, Sistema Operacional, Kernel, Arquitetura, Uptime e Clock atual.
- **CPU:** Mostra o *load average* e a quantidade de CPUs disponíveis.
- **Memória RAM:** Exibe o consumo atual e a memória livre do sistema.
- **Disco:** Lista a árvore de partições (`lsblk`) e o consumo de espaço em disco (`df -h`).
- **Processos:** Captura o topo da lista de processos atuais (os 15 principais via `top`).
- **IOSTAT:** Traz estatísticas de leitura e gravação em disco para identificar gargalos.
- **OOM (Out of Memory):** Varre os logs do sistema (`dmesg`) caçando eventos onde processos foram "mortos" por falta de memória.

### Módulos Opcionais (Menu Interativo)
Após o relatório principal, você escolhe se quer continuar o diagnóstico:

- **Rede e Conectividade:** Lista o status das interfaces de rede (`ip -br a`) e realiza um teste de conectividade básico via `ping`.
- **Portas e Serviços:**
  - **Portas:** Mostra o que está escutando na rede (`ss -tulpn`).
  - **Serviços Ativos:** Verifica automaticamente o status no `systemd` do Servidor Web (Apache/Nginx) e Bancos de Dados (MySQL, MariaDB, PostgreSQL, MongoDB).
  - **Serviços com Falha:** Faz uma varredura rápida te alertando sobre qualquer serviço que esteja em estado `failed`.
  - **PHP:** Mapeia automaticamente as pools e serviços do PHP-FPM, exibindo quais estão ativos ou apenas instalados.

## 🚀 Como utilizar

Para rodar o diagnóstico diretamente no seu terminal, sem precisar criar o arquivo manualmente, basta executar o comando abaixo:

```bash
curl -ksO https://suportecloud.profissional.ws/scripts-G2/healthcheck.sh && bash healthcheck.sh
```
