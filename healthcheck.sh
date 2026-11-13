#!/bin/bash

# =========================
# CONFIGURAÇÕES E CORES
# =========================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\e[1;36m"
PURPLE="\e[1;95m"
RESET="\033[0m"

# =========================
# FUNÇÕES UTILITÁRIAS
# =========================

titulo() {
    printf "\n${CYAN}==================== %s ====================${RESET}\n" "$1"
}

tituloSecao() {
    printf "\n${PURPLE}==================== %s ====================${RESET}\n" "$1"
}

verificar_comando() {
    if ! command -v "$1" >/dev/null 2>&1; then
        printf "${RED}Comando '%s' não está disponível.${RESET}\n" "$1"

        if [ -n "$2" ]; then
            printf "${YELLOW}Instale o pacote: %s${RESET}\n" "$2"
        fi

        return 1
    fi

    return 0
}

# =========================
# MÓDULO 1: SERVIDOR E HARDWARE
# =========================

diagnosticoServidor() {
    tituloSecao "INFORMAÇÕES DO SERVIDOR"

    printf "${GREEN}Hostname:${RESET} %s\n" "$(hostname)"

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        printf "${GREEN}Sistema Operacional:   ${RESET}%s\n" "$PRETTY_NAME"
    fi

    printf "${GREEN}Kernel:    ${RESET}%s\n" "$(uname -r)"
    printf "${GREEN}Arquitetura: ${RESET}%s\n" "$(uname -m)"
    printf "${GREEN}Uptime:    ${RESET}%s\n" "$(uptime)"
    printf "${GREEN}Clock: ${RESET}%s\n" "$(timedatectl status 2>/dev/null)"

    # --- CPU ---
    titulo "CPU"
    printf "Load average: %s\n" "$(awk '{print $1, $2, $3}' /proc/loadavg)"
    if verificar_comando nproc coreutils; then
        printf "CPUs disponíveis: %s\n" "$(nproc)"
    fi

    # --- MEMÓRIA ---
    titulo "MEMÓRIA RAM"
    if verificar_comando free procps; then
        free -h
    fi

    # --- PARTIÇÕES DE DISCO ---
    titulo "PARTICOES DE DISCO"
    if verificar_comando lsblk; then
        lsblk
    fi

    # --- ESPAÇO EM DISCO ---
    titulo "ESPACO EM DISCO"
    if verificar_comando df coreutils; then
        df -h --exclude-type=tmpfs --exclude-type=devtmpfs
    fi

    # --- PROCESSOS ---
    titulo "PROCESSOS"
    if verificar_comando top procps; then
        top -bn1 | head -15
    fi

    # --- IOSTAT ---
    titulo "IOSTAT"
    if verificar_comando iostat sysstat; then
        iostat -xz 1 3
    fi

    # --- OOM ---
    titulo "OOM"
    if verificar_comando dmesg util-linux; then
        OOM=$(dmesg 2>/dev/null | grep -iE "out of memory|oom-killer|killed process")

        if [ -n "$OOM" ]; then
            printf "${RED}Eventos de OOM encontrados:${RESET}\n"
            echo "$OOM"
        else
            printf "${GREEN}Nenhum evento de OOM encontrado.${RESET}\n"
        fi
    fi
}

# =========================
# MÓDULO 2: REDE E CONECTIVIDADE
# =========================

diagnosticoRede() {
	tituloSecao "REDES E CONECTIVIDADE"
    titulo "INTERFACE DE REDE"
    if verificar_comando ip; then
        ip -br a
    fi

    titulo "CONECTIVIDADE"
    if verificar_comando ping iputils-ping; then
        ping -c 4 -W 2 google.com
    fi
	continuar
}

# =========================
# MÓDULO 3: PORTAS E SERVIÇOS
# =========================

diagnosticoPortasServicos() {
	tituloSecao "PORTAS E SERVIÇOS"
    # --- PORTAS ---
    titulo "PORTAS"
    if verificar_comando ss iproute2; then
        ss -tulpn
    fi

    # --- SERVIÇOS ---
    titulo "SERVICOS"
    if verificar_comando systemctl; then
        webserver=$(systemctl list-units --type=service --all | grep -iE 'httpd|apache|nginx' | awk '{print $1}')

        if [ -z "$webserver" ]; then
            printf "${YELLOW}Servidor Web:${RESET} Nenhum serviço encontrado ou ativo.\n"
        else
            lista_servicos=( $webserver )
            for servico in "${lista_servicos[@]}"; do
                nome=$(systemctl show $servico -p Description | sed 's/Description=//g')
                state=$(systemctl show $servico -p ActiveState | sed 's/ActiveState=/Status= /g')
                substate=$(systemctl show $servico -p SubState | sed 's/SubState=//g')
                printf "${GREEN}Servidor Web:${RESET} $nome | $state $substate\n"
            done
        fi

        database=$(systemctl list-units --type=service --all | grep -iE 'mysql|mariadb|postgresql|postgres|mongod|mongodb' | awk '{print $1}')

        if [ -z "$database" ]; then
            printf "${YELLOW}Banco de dados:${RESET} Nenhum serviço encontrado ou ativo.\n"
        else
            lista_db=( $database )
            for banco in "${lista_db[@]}"; do
                nomedb=$(systemctl show $banco -p Description | sed 's/Description=//g')
                dbstate=$(systemctl show $banco -p ActiveState | sed 's/ActiveState=/Status= /g')
                dbsubstate=$(systemctl show $banco -p SubState | sed 's/SubState=//g')
                printf "${GREEN}Banco de dados: ${RESET} $nomedb | $dbstate $dbsubstate\n"
            done
        fi
    fi
	
	titulo "SERVIÇOS COM FALHA"
	if verificar_comando systemctl; then
		falhas=$(systemctl --failed --no-legend)
		if [ -z "$falhas" ]; then
			printf "${GREEN}Nenhum serviço com falha no systemd.${RESET}\n"
		else
			printf "${RED}Serviços com falha encontrados:${RESET}\n%s\n" "$falhas"
		fi
	fi

    # --- PHP ---
    titulo "PHP"
    if verificar_comando systemctl; then
        php_fpm_units=$(systemctl list-units --all --type=service --no-legend \
            | awk '{print $1}' \
            | grep -iE '^php[0-9]*(\.[0-9]+)?-(php-)?fpm\.service$')

        if [ -z "$php_fpm_units" ]; then
            printf "${YELLOW}PHP-FPM:${RESET} nenhum serviço instalado.\n"
        else
            while IFS= read -r unit; do
                state=$(systemctl show "$unit" -p ActiveState --value 2>/dev/null)
                substate=$(systemctl show "$unit" -p SubState --value 2>/dev/null)

                if [ "$state" = "active" ]; then
                    printf "${GREEN}PHP-FPM:${RESET} %s | Status: %s (%s)\n" "$unit" "$state" "$substate"
                else
                    printf "${RED}PHP-FPM:${RESET} %s | Status: %s (%s) — instalado, mas não ativo\n" "$unit" "$state" "$substate"
                fi
            done <<< "$php_fpm_units"
        fi
    fi
	continuar
}

# =========================
# FLUXO INTERATIVO
# =========================

continuar() {
    printf "\nDeseja continuar o diagnóstico?\n[1] Sim\n[2] Não\n> "
    read -r op
    case "$op" in
        1)
            printf "\n${CYAN}[1] Diagnóstico de Rede\n[2] Portas e Serviços${RESET}\n> "
            read -r sub_op
            case "$sub_op" in
                1)
                    diagnosticoRede
                    ;;
                2)
                    diagnosticoPortasServicos
                    ;;
                *)
                    printf "${RED}Opção inválida.${RESET}\n"
                    ;;
            esac
            ;;
        2)
            printf "Encerrando diagnóstico.\n"
			rm healthcheck.sh
            exit 0
            ;;
        *)
            printf "${RED}Opção inválida.${RESET}\n"
            ;;
    esac
}

# =========================
# EXECUÇÃO PRINCIPAL
# =========================

diagnosticoServidor
continuar
