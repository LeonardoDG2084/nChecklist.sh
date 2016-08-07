# nChecklist.sh

Autor: Leonardo D'Angelo Gonçalves

Projeto de Checklist Linux

Esse script tem como objetivo obter configuraçôes especificas do sistema operacional, como configuração de rede, rotas, pacotes, etc... para consulta futura ou comparar com outro checklist ja executado anteriormente.

Seguem algumas caracteristicas do checklist

 - Geração de checklist.
 - Compactação de checklist para backup em um outro servidor.
 - Archiving de checklists já gerados visando economia de espaço.
 - Comparação de checklists com o objetivo de verificar as diferenças.


Instalação

1 - Alterar as seguintes variaveis dentro do script

dirScprt="/opt/scripts/"                          # Diretorio onde deve ficar o script.
dirLog="/opt/log/checklist"                       # Diretorio onde ficarao os checklists.
dirArchive="/opt/log/checklist_archive"           # Diretorio onde ficarao os checklists compactados ou rotacionados.
dirSup="/opt/cockpit"                             # Diretorio de informação do servidor.

2 - Adicionar permissão de Execução

3 - ./nChecklist.sh -m

===============================================================


Seguem algumas informações capturadas

- ifconfig
- route
- exports (NFS)
- multipath
- powerpath
- grub
- Estado de links das interfaces
- Crontab de todos os usuarios
- dmesg
- messages
- processos (ps aux)
- Last
- LVM (pvs, vgs e lvs)
- Filesystens (df)
- fdisk
- lsmod
- Rawdevices
- pam
- smbstatus
- lsb_release
- lpstat
- tapes
- netstat
- uname
- lspci
- Hosts
- resolv.conf
- chkconfig

Sistemas Operacionais suportados

- RedHat 5 e 6
- SLES 10, 11 e 12

Breve:

- Ubuntu
- RedHat 7