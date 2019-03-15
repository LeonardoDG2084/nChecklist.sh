#!/bin/bash
############################################
#                                          #
#    CHECKLIST -                           #
#                                          #                                                                                                                            
#                                          #                                                                                                                            
# Programadores:                           #
#   Leonardo D`Angelo Goncalves            #
#   E-mail: leonardodg2084@gmail.com       #
#                                          #
#                                          #
#                                          #
############################################

#################
# Configuracoes #
#################

dirScprt="/opt/scripts/"
dirLog="/opt/log/checklist"                       # Diretorio onde ficarao os checklists
dirArchive="/opt/log/checklist_archive"           # Diretorio onde ficarao os checklists compactados ou rotacionados
dirSup="/opt/cockpit"                             # Diretorio onde serao retidas as info de suporte
bckFile="chkpath.bck"                                   # Arquivo onde ficam os paths para efetuar backup
fmtFile=$(date +"%d-%m-%Y-%H-%M").$(hostname).checklist # Formato do arquivo de saida
tempWebSumFile="$dirLog/tempWebSumFile"                 # Arquivo Web sumario temporario
tempWebCheckFile="$dirLog/tempWebCheckFile"             # Arquivo Web checks temporario
bestPracticeFile="$dirLog/$(hostname)-bp.wp"            # Arquivo de BestPractice
finalWebFile="$dirLog/$(hostname).wp"                   # Arquivo Web Final

# Variavel PATH
export PATH="$PATH:/usr/kerberos/sbin:/usr/kerberos/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/usr/X11R6/bin"

# Variavel ROTATE
rotate="10"

# Total de itens verificados pelo checklist
total="45"

###########
# Funcoes #
###########

##########
# Versao #
##########

version(){
    echo "3.0"
}

function processador(){
   if [ ! `dmidecode 2> /dev/null` ]
   then
        echo "Falha ao acessar o dmidecode"
   else
   dmidecode |sed -ne '/Processor Information/,/Handle/p' |sed -e '/\t\t\t/d' |tr -d '\t'|\
   egrep '(Manufacturer:|Current Speed:|Family:|Socket Designation:)'|sed -e 's/\(MHz\)/\1\n/' -e 's/\(GHz\)/\1\n/'
   nucleos=$(grep processor /proc/cpuinfo |wc -l)
   chips=$(dmidecode |fgrep "Processor Information"|wc -l)
   chipsAtivos=$(dmidecode  |sed -ne '/Processor Information/,/Handle/p' |fgrep 'Current Speed'|grep -v 'Current Speed:.*Unknown'|wc -l 2> /dev/null)

    if [ $chipsAtivos == 0 ]
    then
        chipsAtivos=1
    fi
        nucleosPorProcessador=$(($nucleos/$chipsAtivos))
    fi
}
###########
# Funcoes #
###########

#############################
# Identifica a versao do SO # 
#############################

soversion() {
        if [[ -e /proc/version ]]
        then
                if [[ `grep SUSE /proc/version` ]]
                then
                  SO="SUSE"
                fi
                if [[ `grep Red /proc/version` ]]
                then
                        SO="REDHAT"
                fi
                if [[ `grep ubuntu /proc/version` ]]
                then 
                        SO="UBUNTU"
                fi
        else
                echo -e "[ERRO] Nao foi possivel identificar o SO"
        fi
}

####################################################################
# Funcao para printar na tela o cabecalho do item sendo verificado #
####################################################################
printhdr() {
   
   echo -e "######################" >> $dirLog/$cmd.$fmtFile
   echo -e " $cmd"                  >> $dirLog/$cmd.$fmtFile
   echo -e "######################" >> $dirLog/$cmd.$fmtFile
}


####################################################
# Funcao para printar na tela o fim da verificacao #
####################################################
printbtm() {

   echo -e "######----FIM----######" >> $dirLog/$cmd.$fmtFile
   echo -e ""                        >> $dirLog/$cmd.$fmtFile
}

####################################################################
# Funcao para printar na tela, durante a criacao de um checklist   #
# o status da coleta em forma de barra de progresso.               #
####################################################################

printtitle() {
   # Quantidade de itens na barra de progresso
   spinnerTotal=$total
   # Strings possiveis no spinner
   spinner='-/|/'
   
   # Limpar a linha atual até o final
     echo -ne '\033[K'
   # Toda a vez que $i ficar maior que quatro ele 'reseta'
     i=$(( (i+1) %4 ))
   # Executa o spinner sempre um uma posição fixa do console
     echo -en "\033[28;1f[${spinner:$i:1}]"
  # Executa o item de checklist sempre um uma posição fixa do console
     echo -en "\033[28;4f Coletando: "$chkTitle""
     echo -en '\033[K'
     echo -e "\033[G\033[60C[$count/$total]"
     echo -ne '\033[K'
}

########################################################
# Funcoes para desenhar a caixa do Sumario de hardware #
########################################################

# Desenha a lateral esquerda da caixa
printBoxLeft(){
    echo -en '\e[31;1m ║\e[m'
}

# Desenha a lateral direita da caixa
printBoxRight(){
    echo -e '\e[31;1m║\e[m'
}

# Desenha tanto as divisorias quanto o rodape da caixa
printBoxFooter(){
    echo -e '\e[31;1m ╚═══════════════════════════════════════════════════════════════╝ \e[m'
}

# Desenha o cabecalho da caixa
printBoxHeader(){
  tput clear
  echo -e '\e[31;1m ╔═══════════════════════════════════════╤═══════════════════════╗ \e[m'
  echo -e '\e[31;1m ║ CCCCC H   H EEEEE CCCCC K   K         │                       ║ \e[m'
  echo -e '\e[31;1m ║ C     H   H E     C     K  K          │ Checklist             ║ \e[m'
  echo -e '\e[31;1m ║ C     HHHHH EEEE  C     KKK           │                       ║ \e[m'
  echo -e '\e[31;1m ║ C     H   H E     C     K  K          │ Linux                 ║ \e[m'
  echo -e '\e[31;1m ║ CCCCC H   H EEEEE CCCCC K   K         │ Versao: 3.0           ║ \e[m'
  echo -e '\e[31;1m ╠═══════════════════════════════════════╧═══════════════════════╣ \e[m'
  echo -e '\e[31;1m ║                                                               ║ \e[m'
}

######################################
# Nome: printHdrWeb                  #
#                                    #
# Autor: leonardodg2084@gmail.com        #
#                                    #
# Descrição                          #
#                                    #
# Cabeçalho d arquivo de cada item   #
# para a versao                      #              
######################################



function printHdrWeb
{
      echo "<h3>$1</h3>"                >> $tempWebCheckFile
      echo "Descrição: $2"              >> $tempWebCheckFile
      echo "<pre>"                      >> $tempWebCheckFile
}

######################################
# Nome: printBtm                     #
#                                    #
# Autor: leonardodg2084@gmail.com        #
#                                    #
# Descrição                          # 
#                                    #
# Rodapé do arquiv de cada item      #
# do checklist web                   #
######################################

function printBtmWeb
{
        echo "</pre>" >> $tempWebCheckFile
}

####################################################
# Funcao para verificar a execucao por root (sudo) #
####################################################
checkUID(){
        # Caso o UID de quem chama este scritp seja diferente de 0 (root)
    if [ $UID -ne 0 ]
    then
        echo '[ERRO] Apenas execute este script como root!'
        echo "[ERRO] Tente novamente da seguinte maneira:"
        echo "sudo $0"
        exit 1
    fi
}

#########################################

testDirs(){
    #
    # Teste do diretorio de log #
    #
    if [ ! -d $dirLog ]
    then
            echo "[INFO] Diretorio de log nao existe ou nao encontrado"
            echo "[INFO] Criando diretorio de log"
            mkdir -p $dirLog
            if [ $? != 0 ]
            then
                    echo "[ERRO] Falha ao criar diretorio"
                    exit 1
            fi
    fi
    
    #
    # Teste do diretorio de log compactados #
    #
    if [ ! -d $dirArchive ]
    then
            echo "[INFO] Diretorio de logs compactados nao existe ou nao encontrado"
            echo "[INFO] Criando diretorio de logs compactados"
            mkdir -p $dirArchive
            if [ $? != 0 ]
            then
                    echo "[ERRO] Falha ao criar diretorio"
                    exit 1
            fi
    fi

    #
    # Teste de diretorio de cockpit
    #

    if [ ! -d $dirSup ]
    then
            echo "[INFO] Diretorio de cockpit nao existe ou nao encontrado"
            echo "[INFO] Criando diretorio de cockpit"
            mkdir -p $dirSup
            if [ $? != 0 ]
            then
                    echo "[ERRO] Falha ao criar diretorio"
                    exit 1
            else
                    echo "[INFO] Diretorio de cockpit criado"
                    echo "[INFO] Criando arquivos informativos vazios, favor preenche-los posteriormente."
                    touch $dirSup/preboot.txt 
                    touch $dirSup/posboot.txt 
                    touch $dirSup/cockpit.txt
                    # Conteudo dos arquivos
                    
                    echo "
####################### 
# Informacoes Basicas # 
####################### 
Contingencia do ambiente:
Funcao:
Sistema:
Recursos envolvidos:
Janela de manutencao:
Criticidade:
DR:
Localizacao:
ACN:
#################################################### 
                        " > $dirSup/cockpit.txt
echo " 
#######################
# Atividades Pre-boot #
#######################

Ordem de atuacao dos recursos:
Atividades:

#################################################### 
                        " > $dirSup/preboot.txt

echo "
#######################
# Atividades Pos-boot #
#######################

Ordem de atuacao dos recursos:
Atividades:

#################################################### 
                        " > $dirSup/posboot.txt
                    [ $? != 0 ] && echo "[ERRO] Falha ao criar arquivos" && exit 1
            fi
    fi
}

########
# MOTD #
########

createMotd()
{
if [ -f "$dirScprt/.motd" ]
then
        rm /etc/motd
        cat $dirScprt/.motd > /etc/motd
        cat $dirSup/cockpit.txt | grep -v "^#" >> /etc/motd
fi
}

###################
# Oracle Function #
###################

asmConnect()
{

        ORACLE_SID="$(cat /etc/oratab | grep "+ASM" | cut -d":" -f 1)"
        ORACLE_HOME="$(cat /etc/oratab | grep "+ASM" | cut -d":" -f 2)"
        oraUser=$(ps -elf | grep pmon | grep "+" | awk '{print $3}')

}


createChecklist(){
    checkUID
    echo > $tempWebCheckFile
    testDirs

   ############
   # Hardware #
   ############

   cmd=hardware
   
   # Aqui vamos obter as informacoes do servidor
   # para preencher no sumario de hardware apresentado ao gerar um checklist
   #########################################################################
   
   # Precisamos determinar se este servidor eh um zLinux
   # Apenas maquinas zLinux possuem o /proc/sysinfo
   [ -f /proc/sysinfo ] && mainframe=1
   
   # Para obter dados para as maquinas zLinux:
   if [ -n "$mainframe" ]
   then
        modelCpu=$(cat /proc/cpuinfo | grep ^vendor_id | head -n1 | awk '{print $NF}')
        nrCpuCore=$(cat /proc/cpuinfo | grep ^# | head -n1 | awk '{print $NF}')
        nrNic=$(ls -l /sys/devices/qeth | grep ^d | wc -l)
        nrFc="0"
        vendorId="IBM"
        TYPE=$(cat /proc/sysinfo | grep ^Type: | awk '{print $NF}')
        LPAR=$(cat /proc/sysinfo | grep ^LPAR\ Name: | awk '{print $NF}')
        VM=$(cat /proc/sysinfo | grep ^VM00\ Name: | awk '{print $NF}')
        control=$(cat /proc/sysinfo | grep Control | awk '{print substr($0, index($0,$4)) }' | awk '{print $1,$2}')
   # Para obetr dados para as maquinas nao zLinux:
   else
        modelCpu=$(cat /proc/cpuinfo | grep -m 1 "model name" |  cut -d":" -f 2 | sed 's/^\ //' | tr -s ' ' ' ')
        nrCpuCore=$(cat /proc/cpuinfo | grep processor | wc -l)
        nrNic=$(lspci | grep "Ethernet" | wc -l 2> /dev/null)
        nrFc=$(lspci | grep "Fibre" | wc -l 2> /dev/null)
        # Caso tenhamos o comando dmedecode
        if [[ $(dmidecode 2> /dev/null) ]]
        then
            # Atribuir as seguintes varaiveis o resultado dos seguintes comandos.
            vendorId=$(dmidecode | grep "System Information" -A1 | tail -n1 | cut -d: -f2 | sed 's/\ //' 2> /dev/null)
                    # Caso o resultado do comando seja vazio atribuir N/A
                    [ -z " " ] && vendorId="N/A"
            typeId=$(dmidecode | grep "System Information" -A2 | tail -n1 | cut -d: -f2 | sed 's/\ //' 2> /dev/null)
                    [ -z "$typeId" ] && typeId="N/A"
            serialId=$(dmidecode | grep "System Information" -A4 | tail -n1 | cut -d: -f2 | sed 's/\ //' 2> /dev/null)
                    [ -z "$serialIdId" ] && serialId="N/A"
        # Caso nao tenhamos o comando dmidecode
        else
            vendorId="N/A"
            typeID="N/A"
            serialId="N/A"
        fi
   fi
   
   # Os dados abaixo podem ser obtidos igualmente em maquinas zLinux ou Intel.

   memTotal=$(cat /proc/meminfo | grep MemTotal | cut -d":" -f 2 | awk '{print $1,$2}')
   memFree=$(cat /proc/meminfo | grep MemFree | cut -d":" -f 2 | awk '{print $1,$2}')
   swapTotal=$(cat /proc/meminfo | grep SwapTotal | cut -d":" -f 2 | awk '{print $1,$2}')
   swapFree=$(cat /proc/meminfo | grep SwapFree | cut -d":" -f 2 | awk '{print $1,$2}')
   memActive=$(cat /proc/meminfo | grep Active | cut -d":" -f 2 | head -n1 | awk '{print $1,$2}')
   memInactive=$(cat /proc/meminfo | grep Inactive | cut -d":" -f 2 | head -n1 | awk '{print $1,$2}')
   runlevel=$(runlevel | awk '{print $NF}')
   date=$(date)
   dateUtc=$(date -u)
   uptime=$(uptime | cut -d, -f1 | tr -s ' ' ' ' | sed 's/\ //')
   uname=$(uname -rsm)
   
   # Checklist Web - Gerador de sumario e cabecalho
   ##########################################################
   echo '
                [table style=1]
                <table border="0">
                <tbody>
                <tr align="center" valign="middle">
                <td style="text-align: center;" rowspan="2" align="center" valign="middle">
                <img src="http://infocentre.tivit.corp/wp-content/uploads/TIVIT.png" alt="TIVIT" class="size-full wp-image-32627" height="26" width="180" />
                </td>
                <td style="text-align: center;" rowspan="2">
                <strong>Documentação de configurações
                de Servidores Linux<br</strong>
                </td>
                <td style="text-align: center;">
                <strong>Classificação</strong>
                </td>
                <td style="text-align: center;">
                <strong>IC ACN</strong>
                </td>
                <td style="text-align: center;">
                <strong>Nome do IC</strong>
                </td>
                </tr>
                <tr align="center" valign="middle">
                <td style="text-align: center;">Setorial</td>
                <td>
                <small>( <strong>
                <span style="color: #ff0000;">
                </span>
                </strong> ) SIM ( ) NÃO</small>
                </td>
                <td style="text-align: center;"> $(hostname)</td>
                </tr>
                </tbody>
                </table>
                <p>
                [/table]</p>
                <p>[box title="Descritivo"]</p>
                <p>Este documento, descreve as principais configurações do servidor. Este documento é gerado de forma automatica. Favor não alterar este documento, as alterações feitas serão perdidas.</p>
                <p>[/box]</p>
                <p>[box title="Objetivo"]</p>
                <p>Neste documento é possível saber as configurações atuais do servidor.</p>
                <p>[/box]</p>
                <p>[box title="Aplicação"]</p>
                <p>Com as configurações aqui apresentadas neste documento é possível restaurar as configurações do servidor em caso de perda e consultar as configurações do servidor sem ser necessario o acesso ao mesmo.</p>
                <p>[/box]</p>'                                               >  $tempWebSumFile
                echo "[toc]"                                                 >> $tempWebSumFile
                echo "<h3>Hostname: $(hostname)</h3>"                        >> $tempWebSumFile
                echo "<h3>Principais Informações:</h3>"                      >> $tempWebSumFile
                echo "[table style=\"1\"]"                                   >> $tempWebSumFile
                echo "<table>"                                               >> $tempWebSumFile
                echo "<tbody>"                                               >> $tempWebSumFile

   ########################################
   #     Printar o sumario de hardware    #
   ########################################
   
   # Desenha o cabecalho
   printBoxHeader
    
   # Atribui ao seguinte vetor todas as variaveis que contem os dados
   # a serem printados no sumario
   variableArray=(memTotal memFree swapTotal swapFree memActive memInactive runlevel nrFc nrNic date dateUtc uptime uname vendorId serialId modelCpu nrCpuCore typeId)

   # Instancia a variavel contadora do vetor com valor zero
   arrayCounter=0
    
   # Posicao da linha apos desenhar o cabecalho
   # TODO: Tornar esta atribuicao dinamica ao
   # inves de hardcoded como esta
   firstPositionAfterHeader=7
    
   # Loop para corre pelo vetor em todas as
   # suas posicoes sequencialmente
   while [ $arrayCounter -lt ${#variableArray[*]} ]
   do
        # A seguinte variavel de escopo local recebe
        # o valor da posicao do vetor.
        thisVariable=${variableArray[$arrayCounter]}
    
        # A seguinte variavel recebe o valor da variavel que estava
        # contida na posicao do vetor.
        # O uso do eval se faz necessario para que haja
        # atribuicao indireta do valor da variavel.
        eval localVar=\$$thisVariable
        
        # Desenha a lateral esquerda da caixa para cada item neste loop.
        printBoxLeft
        
        # Caso o valor da variavel seja um dos valores previstos abaixo
        # criar a variavel de rotulo com o rotulo
        # do valor a ser printado.
        case $thisVariable in
            memTotal)       thisLabel="Memoria Total:\t";;
            memFree)        thisLabel="    '->Livre:\t\t";;
            swapTotal)      thisLabel="Swap Total:\t\t";;
            swapFree)       thisLabel="    '->Livre:\t\t";;
            memActive)      thisLabel="Memoria Ativa:\t";;
            memInactive)    thisLabel="   '->Inativa:\t";;
            runlevel)       thisLabel="Runlevel:\t\t";;
            nrFc)           thisLabel="Qtd de HBAs:\t\t";;
            nrNic)          thisLabel="Qtd de NICs:\t\t";;
            date)           thisLabel="Data atual:\t\t";;
            dateUtc)        thisLabel="Data UTC:\t\t";;
            uptime)         thisLabel="System Uptime:\t";;
            uname)          thisLabel="Uname:\t\t";;
            vendorId)       thisLabel="Vendor:\t\t";;
            serialId)       thisLabel="serialId:\t\t";;
            modelCpu)       thisLabel="Modelo da CPU:\t";;
            nrCpuCore)      thisLabel="Qtd Nucleos:\t\t";;
            typeId)         thisLabel="Tipo/Modelo:\t\t";;
        esac
        
        # Ja que no mainframe nao da pra pegar serialId,
        # entao vamos printar infos mais uteis em seu lugar
        if [ -n "$mainframe" -a "$thisVariable" = "serialId" ]
        then
            echo -en "zLinux info:\tLPAR $LPAR, VM $VM, Control Program $control."
        else
            # Printar o rotulo juto de seu respectivo valor
            echo -en "$thisLabel$localVar"
            # Saida do sumario para o arquivo web
            echo "<tr><td>$(echo $thisLabel | cut -d: -f1):</td><td>$localVar</td></tr>" >> $tempWebSumFile
        fi
        
        # Mover o cursor, na linha atual, para -> 65 colunas para esquerda
        tput cup $firstPositionAfterHeader 65
        
        # Desenhar a lateral direita da caixa
        printBoxRight
        
        # Incrementar a posicao da linha em +1
        firstPositionAfterHeader=$(($firstPositionAfterHeader+1))
    
    # Incrementar o contador do vetor em +1    
    arrayCounter=$(($arrayCounter+1))
    done
   
    # Checklist Web - Fecha a tabela sumario web
    #################################
    echo "</tbody>" >> $tempWebSumFile
    echo "</table>" >> $tempWebSumFile
    echo "[/table]" >> $tempWebSumFile
         
    # Desenhar o rodape da caixa
    printBoxFooter
            
    # Printar uma linha em branco
    echo ""
    
    # Saia logo
    # exit

   cmd=cockpit
   chkTitle="Cockpit"
   printHdrWeb $cmd "$chkTitle"
   cat $dirSup/cockpit.txt >> $tempWebCheckFile
   printBtmWeb

   cmd=preboot
   chkTitle="Pre boot"
   printHdrWeb $cmd "$chkTitle"
   cat $dirSup/preboot.txt >> $tempWebCheckFile
   printBtmWeb

   cmd=posboot
   chkTitle="Pos boot"
   printHdrWeb $cmd "$chkTitle"
   cat $dirSup/posboot.txt >> $tempWebCheckFile
   printBtmWeb


   #############
   # Chkconfig #
   #############

   cmd=chkconfig
   chkTitle="Servicos Ativos/Inativos"
   export count=1
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   if [ -e /sbin/chkconfig ]
   then
   chkconfig --list | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   fi
   printbtm
   printBtmWeb

   #########
   # Hosts #
   #########

   cmd=etc-hosts
   chkTitle="Informacao de hosts"
   count=2
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   if [ -e "/etc/hosts" ]
   then
         cat /etc/hosts | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   fi
   printbtm
   printBtmWeb

   ###############
   # Resolv.conf #
   ###############

   cmd=etc-resolv
   chkTitle="Configuracao do client DNS"
   count=3
   printtitle
   printhdr
   printHdrWeb $cmd ""$chkTitle""
   if [ -e "/etc/resolv.conf" ]
   then
   cat /etc/resolv.conf | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   fi
   printbtm
   printBtmWeb

   ####################
   # Devices do Linux #
   ####################

   cmd=lspci
   chkTitle="Informacao de device"
   count=4
   printtitle
   printhdr
   printHdrWeb $cmd ""$chkTitle""
   lspci -v  2> /dev/null | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   lspci -vv 2> /dev/null | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   printbtm
   printBtmWeb

   ############
   # Modprope #
   ############

   cmd=modprobe
   chkTitle="Configuracao do modprobe"
   count=5
   printtitle
   printhdr
   if [ -e "/etc/modprobe.conf" ]
   then
           cat /etc/modprobe.conf >> $dirLog/$cmd.$fmtFile
   fi
   printbtm
   
   ###########
   # Inittab #
   ###########

   cmd=inittab
   chkTitle="Informacao de inittab "
   count=5
   printtitle
   printhdr
   if [ -e "/etc/inittab" ]
   then
        cat /etc/inittab >> $dirLog/$cmd.$fmtFile 
   fi
   printbtm

   #######
   # NTP #
   #######

   cmd=ntp
   chkTitle="Informacao de NTP "
   count=6
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   if [ -e "/etc/ntp.conf" ]
   then
        cat /etc/ntp.conf |grep server |grep -v "^#" | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   fi
   printbtm
   printBtmWeb

   ##########
   # Sysctl #
   ##########

   cmd=sysctl
   chkTitle="Parametros de Kernel"
   count=7
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   sysctl -a 2>/dev/null | sort | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   printbtm
   printBtmWeb

   ###########
   # Netstat #
   ###########

   cmd=netstat
   chkTitle="Portas UDP e TCP ativas"
   count=8
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   netstat -ntlp | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   printbtm
   printBtmWeb

   #########
   # Uname #
   #########

   cmd=uname
   chkTitle="Uname"
   count=9
   printtitle
   printhdr
   uname -a >> $dirLog/$cmd.$fmtFile
   printbtm

   ###########
   # Network #
   ###########

   cmd=network
   chkTitle="Informacao de rede e rotas estaticas"
   count=10
   printtitle
   printhdr     
   soversion
   printHdrWeb $cmd "$chkTitle"
   if [ $SO = "REDHAT" ]
   then
        cat /etc/sysconfig/network | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
        echo -e ""                 | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   fi
   if [ $SO = "SUSE" ]
   then
      cat /etc/sysconfig/network/routes | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
      echo -e ""                        | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   fi
   printbtm
   printBtmWeb
 
   #####################
   # Fila de impressao #
   #####################

   cmd=lpstat
   chkTitle="Informacao de fila de impressao "
   count=11
   printtitle
   printhdr   
   printHdrWeb $cmd "$chkTitle"
   if [ `lpstat 2> /dev/null` ]
   then
       lpstat -v | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   fi
   printbtm
   printBtmWeb

   ########
   # tape #
   ########

   cmd=tape
   chkTitle="Informacao de tape"
   count=12
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   cat /proc/scsi/IBM*  2>/dev/null | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   printbtm
   printBtmWeb

   #######
   # RPM #
   #######

   cmd=rpm
   chkTitle="Pacotes RPM"
   count=13
   printtitle
   printhdr
   if [ -e "/bin/rpm" ]
   then
         rpm -qa --queryformat='(%{installtime:date}) %{NAME}-%{VERSION}.%{RELEASE}.%{ARCH}.rpm \n'| sort -b -k8,8 >> $dirLog/$cmd.$fmtFile 
   fi
   printbtm

   ##################################
   # Release do Sistema Operacional #
   ##################################

   cmd=lsb_release
   chkTitle="Versao do Sistema Operacional"
   count=14
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   cat /etc/*release | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   printbtm
   printBtmWeb
   

   ########################
   # FileSystens montados #
   ########################

   cmd=df
   chkTitle="Filesystems ativos"
   count=15
   printtitle
   printhdr   
   printHdrWeb $cmd "$chkTitle"
   df -mTP | sort | grep -v "$(df -mTP|head -1)" | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   printbtm
   printBtmWeb

   ###################
   # Tabela de Rotas #
   ###################

   cmd=route
   chkTitle="Tabelas de rotas ativas"
   count=16
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   route -n | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   printbtm
   printBtmWeb

   #########
   # FSTAB #
   #########

   cmd=fstab
   chkTitle="Tabela de filesystems"
   count=17
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   if [ -e "/etc/fstab" ]
   then    
        cat /etc/fstab | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   fi
   printbtm
   printBtmWeb

   ########################
   # Configuracao de Rede #
   ########################

   cmd=ifconfig
   chkTitle="Interfaces de rede ativas"
   count=18
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   ip addr show | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   printbtm
   printBtmWeb

   ####################
   # Tabela de discos #
   ####################

   cmd=fdisk
   chkTitle="Tabela de discos"
   count=19
   printtitle
   printhdr
   fdisk -l 2>/dev/null >> $dirLog/$cmd.$fmtFile
   printbtm

   ####################
   # Lista de modulos #
   ####################

   cmd=lsmod
   chkTitle="Lista de Modulos ativos"
   count=20
   printtitle
   printhdr   
   lsmod | awk '{print $1}'| sort >> $dirLog/$cmd.$fmtFile
   printbtm

   #######
   # PVS #
   #######

   cmd=pvs
   chkTitle="Lista de PVs"
   count=21
   printtitle
   printhdr
   pvs 2>/dev/null >> $dirLog/$cmd.$fmtFile
   printbtm

   #######
   # VGS #
   #######

   cmd=vgs
   chkTitle="Lista de VGs"
   count=22
   printtitle
   printhdr   
   printHdrWeb $cmd "$chkTitle"
   vgs 2>/dev/null | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   printbtm
   printBtmWeb

   #######
   # LVS #
   #######

   cmd=lvs
   chkTitle="Lista de LVs"
   count=23
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   lvs 2>/dev/null | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   printbtm
   printBtmWeb

   ########
   # GRUB #
   ########

   cmd=grub
   chkTitle="Configuracao do GRUB"
   count=24
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   if [ -f "/boot/grub/menu.lst" ]
   then
       cat /boot/grub/menu.lst | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   fi
   printbtm
   printBtmWeb

   ########
   # Rede #
   ########

   cmd=link
   chkTitle="Informacoes de Link de ethernet"
   count=25
   printtitle
   printhdr
   for i in $(ip addr show | grep "^[0-9]:" | awk '{print $2}' | tr -d : | grep -v lo)
   do  
        ethtool $i | grep -E "Setting|Link" >> $dirLog/$cmd.$fmtFile
   done 
   printbtm

   ########
   # Last #
   ########

   cmd=last
   chkTitle="Last"
   count=26
   printtitle
   printhdr 
   last >> $dirLog/$cmd.$fmtFile
   printbtm

   ###########
   # Crontab #
   ###########

   cmd=crontab
   chkTitle="Crontab"
   count=27
   printtitle
   printhdr   
   printHdrWeb $cmd "$chkTitle"
        soversion
        if [ $SO = "REDHAT" ]
        then
           for i in `ls /var/spool/cron/`
           do
                echo -e "\n Crontab do Usuario $i \n\n"                 | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
                cat /var/spool/cron/$i                                  | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
           done
           echo -e ""                                                   | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
        fi
        if [ $SO = "SUSE" ]
        then
           for i in `ls /var/spool/cron/tabs/`
           do
                echo -e "\n Crontab do Usuario $i \n\n"                 | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
                cat /var/spool/cron/tabs/$i                             | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
           done
           echo -e ""                                                   | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
        fi
   printbtm
   printBtmWeb

   #######
   # PAM #
   #######

   cmd=pam
   chkTitle="Pam"
   count=28
   printtitle
   printhdr
   for file in /etc/pam.d/* 
   do 
      echo -e "####################################"            >> $dirLog/$cmd.$fmtFile
      echo "$file"                                              >> $dirLog/$cmd.$fmtFile
      echo -e "####################################"            >> $dirLog/$cmd.$fmtFile
      echo -e " "                                               >> $dirLog/$cmd.$fmtFile
      cat $file 2>/dev/null                                     >> $dirLog/$cmd.$fmtFile
      echo -e " "                                               >> $dirLog/$cmd.$fmtFile
   done
   printbtm

   #######
   # NFS #
   #######

   cmd=exports
   chkTitle="NFS - Server"
   count=29
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   if [ -f /etc/exports ]
   then
        cat /etc/exports                                        | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   fi
   printbtm
   printBtmWeb

   #############
   # Multipath #
   #############

   cmd=multipath
   chkTitle="Multipath"
   count=30
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   if [[ `multipath -d 2> /dev/null` ]]
   then
        multipath -v3 -ll                                       | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   fi
   printbtm
   printBtmWeb

   #######
   # SDD #
   #######

   cmd=sdd
   chkTitle="SDD"
   count=31
   printtitle
   printhdr
   if [[ `datapath 2> /dev/null` ]]
   then
        datapath query essmap                                   >> $dirLog/$cmd.$fmtFile
        echo -e "\n"                                            >> $dirLog/$cmd.$fmtFile
        datapath query device                                   >> $dirLog/$cmd.$fmtFile
        echo -e "\n"                                            >> $dirLog/$cmd.$fmtFile
        datapath query adapter                                  >> $dirLog/$cmd.$fmtFile
   fi
   printbtm

   ##############
   # rawdevices #
   ##############

   cmd=rawdevices
   chkTitle="RAW Devices"
   count=32
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   cat /etc/sysconfig/rawdevices 2> /dev/null                   | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   printbtm
   printBtmWeb

   ############
   # Messages #
   ############

   cmd=messages
   chkTitle="Informacoes do messages"
   count=33
   printtitle
   printhdr
   tail -500 /var/log/messages                                  >> $dirLog/$cmd.$fmtFile
   printbtm

   #########
   # Dmesg #
   #########

   cmd=dmesg
   chkTitle="Dmesg"
   count=34
   printtitle
   printhdr   
   dmesg                                                        >> $dirLog/$cmd.$fmtFile
   printbtm

   #############
   # Processos #
   #############

   cmd=processos
   chkTitle="Processos"
   count=35
   printtitle
   printhdr
   ps aux                                                       >> $dirLog/$cmd.$fmtFile
   printbtm

   #########
   # Fibra #
   #########

   cmd=Link
   chkTitle="Link das Interfaces"
   count=36
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   nulo=$(lspci | grep -i fibre)
   if [$? -eq "0"]
   then
       echo "State" | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
       find /sys/ -name "*state*" -exec cat {} \;  2>&1 /dev/null | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
       #echo "Speed" | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile 
       #find /sys/ -name "*speed*" -exec cat {} \;  2>&1 /dev/null | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   fi
   printbtm 
   printBtmWeb
  
   ########
   # WWPN #
   ########
   
   cmd=wwpn
   chkTitle="WWPN das HBAs"
   count=38
   printtitle  
   printhdr
   printHdrWeb $cmd "$chkTitle"
   nulo=$(lspci | grep -i fibre)
   if [ $? -eq "0" ]
   then
     find /sys -name port_name -print -exec cat {} \; | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   fi
   printbtm
   printBtmWeb

   #############
   # Inquirity #
   #############

   cmd=inq
   chkTitle="Inquirity"
   count=39
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   if [[ `inq 2> /dev/null` ]]
   then
        inq -no_dots -f_powerpath 2> /dev/null  | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   fi
   printbtm
   printBtmWeb

   ##############
   # Discos ASM #
   ##############

   cmd=oracleasm
   chkTitle="Oracle ASM"
   count=40
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   if [[ `inq 2> /dev/null` ]] 
   then
        for i in $(oracleasm listdisks) ; do line=$(oracleasm querydisk -p $i | grep emcpower) ; pseudo=$( echo "$line" | awk '{print $1}' | sed s/1://) ; inqId=$(inq -dev "$pseudo" | grep "/dev" | awk '{print $5}' | sed s/://) ; inqSym=$(inq -dev "$pseudo" -sym_wwn | grep "^WWN" | awk '{print $2}' ) ; echo "$line SYM=\"$inqSym\" EMCID=\"$inqId\"" ; done | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   fi
   printbtm
   printBtmWeb
 
   #############
   # Smbstatus #
   #############

   cmd=smbstatus
   chkTitle="Status do samba"
   count=41
   printtitle
   printhdr
   smbstatus 2>/dev/null >> $dirLog/$cmd.$fmtFile
   printbtm

   ############
   # ASM LSDG #
   ############

   cmd=asmlsdg
   chkTitle="Status dos ASM Disk Group "
   count=42
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   asmUser=$(ps -elf | grep pmon | grep asm | awk '{print $3}') ; su - $asmUser -c "asmcmd lsdg" | awk '{print $1"\t"$7"\t"$8"\t"$13}' | column -t 2>/dev/null | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   printBtmWeb
   printbtm

   ############
   # Testparm #
   ############

   cmd=testparm
   chkTitle="Configuracao do samba"
   count=43
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   testparm -s 2> /dev/null | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   printbtm
   printBtmWeb

   ############
   # ASM ACFS #
   ############

   cmd=asmacfs
   chkTitle="Registro de filesystem ACFS"
   count=44
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   acfsutil registry 2>/dev/null | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   printBtmWeb
   printbtm

   #############
   # PowerPath #
   #############

   cmd=powerpath
   chkTitle="Power Path Discos"
   count=45
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   powermt display 2>/dev/null | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   printBtmWeb
   printbtm 

   #######
   # arp #
   #######

   cmd=arp
   chkTitle="Lista de Enderecos ARP"
   count=46
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   arp -a | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   printBtmWeb
   printbtm

   ###########
   # dmsetup #
   ###########

   cmd=dmsetup
   chkTitle="Lista de device-mapper"
   count=47
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   dmsetup ls | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   dmsetup info | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   dmsetup table | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   printBtmWeb
   printbtm

   #########
   # hostid #
   #########

   cmd=hostid
   chkTitle="Id unico do servidor"
   count=48
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   hostid | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   printBtmWeb
   printbtm

   ##########
   # ipcs -a#
   ##########

   cmd=ipsc_a
   chkTitle="iipcs - semaforos e shared memory"
   count=49
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   ipcs -a | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   printBtmWeb
   printbtm

   ############
   # iscsiadm #
   ############

   cmd=iscsiadm
   chkTitle="Devices iSCSI"
   count=50
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   iscsiadm -m session --info | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   printBtmWeb
   printbtm

   ########
   # lsof #
   ########

   cmd=lsof
   chkTitle="iLista de arquivos abertos "
   count=51
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   lsof | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   printBtmWeb
   printbtm 

   ##########
   # lsscsi #
   ##########

   cmd=ls
   chkTitle="Lista de dispositivos scsi"
   count=52
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   lsscsi -c -l -k | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   lsscsi -H -v -d -g | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   lsscsi -v -d -g | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   printBtmWeb
   printbtm
  
   ###########
   # udevadm #
   ###########

   cmd=udevadm
   chkTitle="UDEV"
   count=53
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   udevadm info --export-db | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   printBtmWeb
   printbtm 

   ###########
   # cpuinfo #
   ###########

   cmd=cpuinfo
   chkTitle="CPU Info"
   count=54
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   cat /proc/cpuinfo | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   printBtmWeb
   printbtm

   ###########
   # meminfo #
   ###########

   cmd=meminfo
   chkTitle="Informacoes de memoria"
   count=54
   printtitle
   printhdr
   printHdrWeb $cmd "$chkTitle"
   cat /proc/meminfo | tee -a $dirLog/$cmd.$fmtFile >> $tempWebCheckFile
   printBtmWeb
   printbtm


   # Escrita nos arquivos do checklist WEB

   cat $tempWebSumFile > $finalWebFile
   cat $tempWebCheckFile >> $finalWebFile
   
   # Funcao de configuracao do MOTD do servidor
   createMotd

   # Funcao de BestPractice 
   BestPractice
   
   # Ao final do checklist sera automaticamente feito o rotate 
   rotateChecklist 
}

###########################
# Comparacao de checklist #
###########################
compareChecklist(){
    checkUID
    testDirs
    echo "Comparacao de checklists:"
    echo "========================="
    echo ""
    echo "Escolha o checklist MAIS ANTIGO"
    select i in $(ls -t $dirLog/*.checklist | cut -d"." -f 2 | uniq)
    do
            if [ -z $i ]
            then
                    echo "[ERRO] Opcao invalida selecione uma opcao valida"
                    exit 1
            else
                    echo "Primeiro checklist escolhido: $i"
                    break
            fi
    
    done
    echo "Escolha checklist MAIS NOVO"
    select j in $(ls -t $dirLog/*.checklist | cut -d"." -f 2 | uniq)
    do
            if [ -z $i ]
            then
                    echo "[ERRO] Opcao invalida selecione uma opcao valida"
                    exit 1
            else
                    echo "Segundo checklist escolhido: $i"
                    break
            fi
    break
    done
    if [ $i = $j ]
    then
            echo "[ERRO] As duas datas sao iguais ou nao ha numero suficiente de checklists"
            exit 1
    fi
    
    for chkFile in ifconfig rpm lsb_release df route fstab fdisk lsmod pvs vgs lvs grub link crontab exports multipath rawdevices chkconfig fibra testparm pam inq oracleasm
    do
            chkItem1=$chkFile.$i.*.checklist
            chkItem2=$chkFile.$j.*.checklist
            echo "------------------------------------------------------------------"
            echo "Comparando $chkItem1 -> $chkItem2"
            echo "------------------------------------------------------------------"
            echo ""
            if [ "$chkFile" = "df" ]
            then
                # Carregar o primeiro df em um array
                #Indice do array
                K=0
                while read line
                do
                    lineDev=$(echo "$line" | grep ^/)
                    if [ -n "$lineDev" ]
                    then
                        arrayFirstDf[$K]="$line"
                        K=$(($K+1))
                    fi
                done < $dirLog/$chkItem1
                totalFirstDf=$(($K-1))
                
                # Comparar primeiro Array com o segundo
                # df usando os LVs como chave primaria
                # e o ponto de montagem como chave secundaria
                X=0 
                result=0
                while [ $X -le $totalFirstDf ]
                do
                    thisLv="$(echo "${arrayFirstDf[$X]}" | awk '{print $1}')"
                    thisMountPoint="$(echo "${arrayFirstDf[$X]}" | awk '{print $NF}')"
                    foundLv=$(cat $dirLog/$chkItem2 | awk -v THISLV="$thisLv" '{if($1 == THISLV) print $1}')
                    foundMountPoint=$(cat $dirLog/$chkItem2 | awk -v THISMOUNTPOINT="$thisMountPoint" '{if($NF == THISMOUNTPOINT) print $NF}')
                    #echo "teste"
                    #echo "$thisLv e $thisMountPoint" 
                    #echo "$foundLv e $foundMountPoint" 
                    #echo "Fim"
                    #echo Variavel "$foundLv"
                    if [ -z "$foundLv" ]
                    then
                        echo "[ERRO]O LV $thisLv ==> $thisMountPoint nao esta montado."
                        result=$(($result+1))
                    fi
                    if [ -z "$foundMountPoint" ] 
                    then
                         echo "[ERRO]Mount Point $thisLv ==> $thisMountPoint nao esta montado."
                        result=$(($result+1))
                    fi
                X=$(($X+1))
                done
                
                # Analisar o contador de erros
                if [ $result -ne 0 ]
                then
                    echo -e ""
                    echo -e "\e[31;5;1m Checklist - NOK \e[m"
                    echo -e ""
                else
                    echo -e ""
                    echo -e "\e[32;5;1m Checklist - OK \e[m"
                    echo -e ""
        
                fi
                
            else        
                diff $dirLog/$chkItem1 $dirLog/$chkItem2 | grep -E "^<|^>" | sed 's/^</[ANTES] /' | sed 's/^>/[DEPOIS]/' 
                diff $dirLog/$chkItem1 $dirLog/$chkItem2 1> /dev/null
                if [ $? -ne 0 ]
                then
                        echo -e ""
                        echo -e "\e[31;5;1m Checklist - NOK \e[m"
                        echo -e ""
                else
                        echo -e ""
                        echo -e "\e[32;5;1m Checklist - OK \e[m"
                        echo -e ""
        
                fi
            fi
    done
}

######################################
# Nome: bpBond                       #
#                                    #
# Autor: leonardodg2084@gmail.com        #
#                                    #
# Descricao                          #
#                                    #
# Verifica se há algum link do bond  #
# inativo                            #
######################################


bpBond()
{
        nulo=$(lsmod | grep bonding)
        if [ $? -eq 0 ]
        then
                for i in $(ls /proc/net/bonding/bond*) ; do cat $i | grep "MII Status" | grep -v up 1> /dev/null  ; done
                if [ $? = 1 ]
                then
                        return 0
                else
                        return 1
                fi
        else
                return 2
        fi
}
######################################
# Nome: bpntp                        #
#                                    #
# Autor: leonardodg2084@gmail.com        #
#                                    #
# Descricao                          #
#                                    #
# Verifica se existe configuracao de #
# NTP e valida a configuracao        #
######################################

bpNtp()
{
        ps -eo ruser | grep ntp 2>&1 > /dev/null 
        if [ $? = 0 ]
        then
                # Verifica se há configuracao de servidores
                cat /etc/ntp.conf | grep '^server' 2>&1 > /dev/null
                if [ $? = 0 ]
                then
                        # Verifica se os servidores configurados chegam nos servidores "377"
                        /usr/sbin/ntpq -p | grep 377 2>&1 > /dev/null
                        if [ $? = 0 ]
                        then
                                return 0
                        else
                                return 1
                        fi
                else
                        return 1
                 fi
        else
                return 1
        fi
}

######################################
# Nome: bpPuppet                     #
#                                    #
# Autor: leonardodg2084@gmail.com        #
#                                    #
# Descricao                          #
#                                    #
# Verifica se o serviço do puppet    #
# esta ativo e configurado para      #
# inicio no boot                     #
######################################

bpPuppet()
{
        # Se o pacote estiver instalado ele irá checar se o processo esta ativo.
        $(rpm -qa | grep puppet 2>&1 > /dev/null)
        if [ $? -eq 1 ]
        then
                return 2
        else
                # Verifica se o processo do puppet esta ativo
                $(ps -C puppet 2>&1 > /dev/null)
                if [ $? -eq 1 ]
                then
                        return 1
                else
                        return 0
                fi
        fi
}

######################################
# Nome: bpVmwareTool                 #
#                                    #
# Autor: leonardodg2084@gmail.com        #
#                                    #
# Descricao                          #
#                                    #
# Verifica se o servidor é virtual e #
# se o mesmo esta com o VmwareTools  #
# instalado                          #
######################################

bpVmwareTool(){

        # Determinando se o servidor é virtual
        nulo=$(dmidecode | grep "System Information" -A2 | tail -n1 | cut -d: -f2 | sed 's/\ //' | grep VM)
        if [ $? -eq 0 ]
        then
                # Determina se o VMware Tools esta executando
                nulo=$(ps faux | grep -P '(vmware|vmtoolsd)' | grep -v grep)
                if [ $? -eq 0 ]
                then
                        return 0
                else
                        return 1
                fi
        else
                return 2

        fi
}

######################################
# Nome: bpNfsSoft                    #
#                                    #
# Autor: leonardodg2084@gmail.com    #
#                                    #
# Descricao                          #
#                                    #
# Verifica se há montagem nfs e      #
# e valida se o o mesmo esta montado #
# com a opcao de soft                #
######################################

bpNfsSoft()
{
        # Verifica se existe filesystem nfs
        nulo=$(/bin/mount | grep "nfs")
        if [ $? = 1 ]
        then
                return 2
        else
                for i in $(/bin/mount | grep " nfs ") 
                do
                        echo $i | grep soft 2>&1 /dev/null
                        if [ $? = 0 ]
                        then
                                continue 
                        else
                                return 1
                        fi
                done
        fi

}

######################################
# Nome: bpVmNet                      # 
#                                    #
# Autor: leonardodg2084@gmail.com    #
#                                    #
# Descricao                          #
#                                    #
# Determina se existe alguma         #
# interface com o driver PCNET       #
# ou VMNEXT2, esses 2 drivers nao    #
# sao performaticos                  # 
######################################

bpVmNet()
{
    # Determinando se o servidor é virtual
    nulo=$(dmidecode | grep "System Information" -A2 | tail -n1 | cut -d: -f2 | sed 's/\ //' | grep VM)
    if [ $? -eq 0 ]
    then
          # Caso a interface seja PCnet32
          nulo=$(lspci | grep -i eth | grep -i PCnet32)
          if [ $? = 0 ]
          then
                return 1
          fi
          # Caso a interface seja VMXNET3
          nulo=$(lspci | grep -i eth | grep -i VMXNET3)
          if [ $? = 0 ]
          then
                return 1
          fi
          # Caso a interface seja VMXNET2
          nulo=$(lspci | grep -i eth | grep -i VMXNET)
          if [ $? = 0 ]
          then
                return 0
          fi
    else
          return 2
    fi

}

##########################
# Funcao de BestPractice #
##########################

BestPractice()
{
        testDirs
        # Executa as funcoes
        rm -f $bestPracticeFile
        echo "[INFO] Executando as funcoes de Best Practice"
        for i in bpBond bpNtp bpPuppet bpNfsSoft bpVmwareTool bpVmNet
        do
                $i
                echo -n "$?;" >> $bestPracticeFile
        done
        chown icentre:users $bestPracticeFile
        if [ "$opt" == "b" ]
            then 
            i=0
            # Armazena o conteudo da variavel IFS
            bpItemArrayValue=($(cat $bestPracticeFile | tr ";" "\n"))
            while [ $i -lt ${#bpItemArrayValue[@]} ]
            do
              case ${bpItemArrayValue[$i]} in
              0) V[$i]="   OK   ";;
              1) V[$i]=" Not OK ";;
              2) V[$i]="   N/A  ";;
              esac
              i=$(($i+1))
            done

            echo "┌──────────────────────┬────────┐ ┌──────────────────────┬────────┐"
            echo "│  BP Item description │ Status │ │  BP Item description │ Status │"
            echo "╞══════════════════════╪════════╡ ╞══════════════════════╪════════╡"
            echo "│     Bond Status      │${V[00]}│ │    Vmware Tools      │${V[04]}│"
            echo "├──────────────────────┼────────┤ ├──────────────────────┼────────┤"
            echo "│     NTP Config       │${V[01]}│ │ VM Ethernet VMNEXT3  │${V[05]}│"
            echo "├──────────────────────┼────────┤ ├──────────────────────┼────────┤"
            echo "│    Puppet Status     │${V[02]}│ │                      │        │"
            echo "├──────────────────────┼────────┤ ├──────────────────────┼────────┤"
            echo "│   NFS Soft Config    │${V[03]}│ │                      │        │"
            echo "├──────────────────────┼────────┤ ├──────────────────────┼────────┤"
            echo "│                      │        │ │                      │        │"
            echo "├──────────────────────┼────────┤ ├──────────────────────┼────────┤"
            echo "│                      │        │ │                      │        │"
            echo "├──────────────────────┼────────┤ ├──────────────────────┼────────┤"
            echo "│                      │        │ │                      │        │"
            echo "├──────────────────────┼────────┤ ├──────────────────────┼────────┤"
            echo "│                      │        │ │                      │        │"
            echo "├──────────────────────┼────────┤ ├──────────────────────┼────────┤"
            echo "│                      │        │ │                      │        │"
            echo "├──────────────────────┼────────┤ ├──────────────────────┼────────┤"
            echo "│                      │        │ │                      │        │"
            echo "├──────────────────────┼────────┤ ├──────────────────────┼────────┤"
            echo "│                      │        │ │                      │        │"
            echo "├──────────────────────┼────────┤ ├──────────────────────┼────────┤"
            echo "│                      │        │ │                      │        │"
            echo "└──────────────────────┴────────┘ └──────────────────────┴────────┘"
        fi
}

######################
# Backup de Arquivos #
######################

backupChecklist(){
    checkUID
    testDirs
    cmd="backup"
    echo "[INFO] Backup de checklists:"
    echo "====================="
    echo ""
    tar -czvT $bckFile -f $(hostname)-$cmd.$fmtFile.tar.gz
}


######################
# Exibe os Checklist #
######################

viewChecklist(){
    checkUID
    testDirs
    echo "Visualizacao de checklists:"
    echo "==========================="
    echo ""
    echo "Escolha a data do checklist a ser visualizado"
    select i in `ls -t $dirLog/*.checklist | cut -d"." -f 2 | uniq `
    do
            if [ -z '$i' ]
            then
                    echo "Opcao invalida selecione uma opcao valida"
                    exit 1
            else
                    echo "Checklist escolhido: $i"
                    cat $dirLog/*$i* | less
                    exit 0
            fi
    done
}

########################
# Deleta os checklists #
########################

delete(){
    checkUID
    testDirs
    echo "Remocao de checklists:"
    echo "======================"
    echo ""
    select i in `ls -t $dirLog/*.checklist | cut -d"." -f 2 | uniq `
    do
            if [ -z $i ]
            then
                    echo "[ERRO] Opcao invalida ou checklist nao encontrado selecione uma opcao valida"
                    exit 1
            else
                    echo "Checklist escolhido: $i"
                    rm -rf $dirLog/*$i*.checklist
                    exit 0
            fi
    done
}

######################
# Compacta checklist #
######################

zipChecklist(){
    checkUID
    testDirs
    cmd="nChecklist"
    echo "Compactacao de checklists:"
    echo "========================="
    echo ""
    select i in $(ls -t $dirLog/*.checklist | cut -d "." -f 2 | uniq)
    do
            if [ -z $i ]
            then
                    echo "[ERRO] Opcao invalida ou checklist nao encontrado selecione uma opcao valida"
                    exit 1
            else
                    echo "Checklist escolhido: $i"
                    tar -czf $dirArchive/$(hostname)-$cmd.$i.tar.gz $dirLog/*$i*
                    echo "tar -czf $dirArchive/$(hostname)-$cmd.$i.tar.gz $dirLog/*$i*"
                    exit 0
            fi
    done
}

#######################
# Rotaciona checklist #
#######################
rotateChecklist(){
    checkUID
    testDirs
    called="$1"
    if [ -n "$called" ]
    then
        echo "Rotacao de checklists:"
        echo "======================"
        echo ""
    fi
    maxRotate=$(($rotate + 1))
    qtdCheck=$(ls -t $dirLog/*.checklist | cut -d "." -f 2 | uniq | wc -l)
            if [ $qtdCheck -le $rotate ]
            then
                    echo -e "\n\n"
                    echo -e "[INFO] Nao ha checklists para rotacionar"
                    echo -e " "
                    exit 1
            else
                    while [ $qtdCheck -gt $rotate ]
                    do
                            echo -e "$maxRotate" | `echo $0` -z &> /dev/null 
                            echo -e "$maxRotate" | `echo $0` -d &> /dev/null  
                            qtdCheck=$(ls -t $dirLog/*.checklist | cut -d "." -f 2 | uniq | wc -l)
                            echo -e "\n\n"
                            echo $checklistRotate
                            echo "[INFO] Checklist rotacionado "
                            checklistRotate="[INFO] CHECKLIST: $(ls -t $dirLog/*.checklist | cut -d "." -f 2 | uniq | head -n $maxRotate | tail -1) Rotacionado para o diretorio $dirArchive com sucesso"
                            echo -e " "
                    done
            fi
}





#######################################################################################################################################

#############
# ChangeLog #
#############
changelog(){

    echo "V2.0  - 2015-04-30 - Grandes mudanças, BestPractice Verbose, e novo Sumario"
    echo "V1.10 - 2015-03-31 - Algoritmo do ASMlib obtem inforacoes do symvol e remocao do Herobine"
    echo "V1.9  - 2015-03-23 - Correcao de bugs do motd e rotacao do checklist, remocao do Herobine"
    echo "V1.8  - 2015-03-12 - Adicionado hostname na funcao backup do checklist e melhorado a obtencao do WWN"
    echo "V1.7  - 2015-01-12 - Melhorias nos checks de BestPractice"
    echo "V1.6  - 2014-12-09 - Correcao de bug na execucao do bestpractice"
    echo "V1.5  - 2014-08-27 - Correcao de bug na checagem do ntpd"
    echo "V1.4  - 2014-08-26 - Adicao de funcoes de bestpractice"
    echo "V1.3  - 2014-05-13 - Melhora na coleta de dados das HBAs"
    echo "V1.0  - 2014-01-02 - Criacao do script (leonardo.angelo@tivit.com.br)"
}

########
# Help #
########
helpme(){
    echo -e "\e[32;2;1m"
    echo "################################"
    echo "# Selecione uma ou mais opcoes #"
    echo "################################"
    echo -e "\e[m"
    echo "-------------------------------------------------------------------------------------"
    echo "-m = Cria um novo checklist"
    echo "-q = Mesmo que -m, porem sem verbose."
    echo "-v = Visualiza um checklist especifico"
    echo "-c = Compara 2 checklists utilizando 2 datas"
    echo "-b = Executa as funcoes de BestPractice"
    echo "-V = Exibe a versao do checklist"
    echo "-C = Exibe o changelog do checklist"
    echo "-B = Cria um tar com base nos caminhos contidos no arquivo 'chkpath.bck'"
    echo "     Deve estar no mesmo nivel do checklist"
    echo "-z = Cria um arquivo ZIP com um checklist de uma determinada data "
    echo "-r = Rotaciona os checklist apartir da quantidade de posicoes definidos na variavel"
    echo "     ROTATE que consta no script de checklist |Qtd atual= 10|"
    echo "-d = Deleta um checklist de uma data escolhida"
    echo "-h = Exibe esta mensagem de ajuda."
    echo " "
    echo " Exemplos de uso "
    echo " "
    echo " $0 -m (Cria um checklist das informações atuais do servidor) "
    echo "-------------------------------------------------------------------------------------"
    echo -e "\n"
}

# Chegou a hora de tratar flags da maneira certa!!
[ -z "$1" ] && helpme && exit 1
while getopts ":CVbcdhmqrvz" opt; do
    case "$opt" in
    "C") changelog ;;
    "V") version ;;
    "B") backupChecklist ;;
    "c") compareChecklist ;;
    "d") delete ;;
    "h") helpme ;;
    "m") createChecklist ;;
    "q") createChecklist &> /dev/null ;;
    "r") rotateChecklist called ;;
    "v") viewChecklist ;;
    "z") zipChecklist ;;
    "b") BestPractice ;;
    \?) echo "Opcao invalida: -$optArg" >&2 && helpme >&2 && exit 1 ;;
    esac
done
