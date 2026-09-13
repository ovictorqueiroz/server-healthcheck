#!/bin/bash

# =========================
# CORES
# =========================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\e[1;36m"
RESET="\033[0m"


# =========================
# FUNÇÕES
# =========================

titulo() {
    printf "\n${CYAN}==================== %s ====================${RESET}\n" "$1"
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
# SERVIDOR
# =========================

titulo "INFORMAÇÕES DO SERVIDOR"

printf "${GREEN}Hostname:${RESET} %s\n" "$(hostname)"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    printf "${GREEN}Sistema Operacional:   ${RESET}%s\n" "$PRETTY_NAME"
fi

printf "${GREEN}Kernel:    ${RESET}%s\n" "$(uname -r)"
printf "${GREEN}Arquitetura: ${RESET}%s\n" "$(uname -m)"
printf "${GREEN}Uptime:    ${RESET}%s\n" "$(uptime)"

# =========================
# CPU
# =========================

titulo "CPU":
printf "Load average: %s\n" "$(awk '{print $1, $2, $3}' /proc/loadavg)" 
if verificar_comando nproc coreutils; then 
	printf "CPUs disponíveis: %s\n" "$(nproc)" 
fi

# =========================
# MEMÓRIA
# =========================

titulo "MEMÓRIA RAM"

if verificar_comando free procps; then
    free -h
fi


# =========================
# ESPACO EM DISCO
# =========================

titulo "ESPACO EM DISCO"

if verificar_comando df coreutils; then
    df -h --exclude-type=tmpfs --exclude-type=devtmpfs
fi

# =========================
# USO DE DISCO POR DIRETORIO
# =========================

titulo "CONSUMO DE DISCO POR DIRETORIO"
printf "${YELLOW} ( ! ) ${RESET} Isso pode levar um tempo. Aguarde o processo finalizar.${YELLOW} ( ! ) ${RESET}\n"

if verificar_comando du; then

    arquivo_erros=$(mktemp)

    du -h --max-depth=1 / 2>"$arquivo_erros" | sort -h

    qtd_negados=$(grep -c "Permission denied" "$arquivo_erros")

    echo

    if [ "$qtd_negados" -gt 0 ]; then
        printf "${RED}ATENÇÃO${RESET}: ${YELLOW}[$qtd_negados] ${RESET} diretórios não puderam ser analisados por falta de permissão.\n"
    else
        echo "Nenhum diretório com permissão negada."
    fi

    rm -f "$arquivo_erros"

fi


# =========================
# TOP
# =========================

titulo "PROCESSOS"

if verificar_comando top procps; then
    top -bn1 | head -15
fi


# =========================
# IOSTAT
# =========================

titulo "IOSTAT"

if verificar_comando iostat sysstat; then
    iostat -xz 1 3
fi


# =========================
# REDE
# =========================

titulo "INTERFACE DE REDE"
if verificar_comando ip; then
        ip -br a
fi

titulo "CONECTIVIDADE"

if verificar_comando ping iputils-ping; then
    ping -c 4 -W 2 google.com
fi


# =========================
# OOM
# =========================

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

# =========================
# SERVICOS
# =========================
titulo "SERVICOS"

if verificar_comando systemctl; then
	webserver=$(systemctl list-units --type=service | grep -iE 'httpd|apache|nginx' | awk '{print $1}')
	
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
	
	database=$(systemctl list-units --type=service | grep -iE 'mysql|mariadb|postgresql|postgres|mongod|mongodb' | awk '{print $1}')
	
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
	
	
	phpServices=$(systemctl | grep -E 'php[0-9][0-9]-php|php-5.[3-5]-fpm.service' | awk '{print $1}')

	if [ -z "$phpServices" ]; then
		printf "${YELLOW}Versão Ativa do PHP: Nenhum serviço encontrado ou ativo. ${RESET}\n"
	else
		printf "${GREEN}Versão Ativa do PHP: ${RESET}\n"
		lista_php=( $phpServices)
		for versaoPHP in "${lista_php[@]}"; do
			printf "$versaoPHP\n"
		done
	fi
fi
echo ""
echo "Diagnóstico concluído com sucesso | Desenvolvido por: Victor Alexandre"
