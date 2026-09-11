Todos que trabalham com suporte ou administrando redes já passou por isso.

O cliente liga falando:
:telephone_receiver::rage: -Meu site está fora do ar!
Nesses cenários, o primeiro troubleshoot é verificar a saúde da máquina. `top`, `df -h`, `free -h` e muitos outros comandos para diagnóstico.
Pensando nisso, com um pouco de bash e muita IA :sweat_smile:, eu criei um script para rodar em Ambientes Linux para rodar todos esses comandos, e mais alguns outros, numa tacada só!

O que o Script nos retorna?

**Informações do Servidor:** Detalhes de Hostname, Sistema Operacional, Kernel, Arquitetura e Uptime. 
**CPU:** Mostra o load average e a quantidade de CPUs disponíveis. 
**Memória RAM:** Exibe o consumo atual e memória livre do sistema. 
**Espaço em Disco:** Lista a utilização das partições principais e faz uma varredura do consumo de disco por diretório na raiz (isso pode levar algum tempo). 
**Processos:** Captura o topo da lista de processos atuais (os 15 principais via top). 
**IOSTAT:** Traz estatísticas de leitura e gravação em disco para identificar gargalos. 
**Rede:** Lista as interfaces de rede e realiza um teste de ping básico. 
**OOM (Out of Memory):** Varre os logs do sistema (dmesg) procurando eventos onde processos foram "mortos" por falta de memória. 
**Serviços:** No momento, verifica automaticamente o status do Servidor Web (Apache/Nginx), Bancos de Dados (MySQL, PostgreSQL, MongoDB) e as versões ativas do PHP.
