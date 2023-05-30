#!/bin/bash
##============================================================================================================================##
## Script simplificado de startup de servicos JAVA SpringBoot
## 
##
## Inicio: 	31-08-2022 Franklin
## Updated: 16-03-2023
##
##============================================================================================================================##
#
#

BIN_JAVA="$JAVA_HOME/bin/java"
JAR_DIR="/jarFile"
JAR_FILE="$(cd ${JAR_DIR} && ls -1 -- *.jar)"

if [ -z "${JAR_PROFILE}" ]
then

	JAR_OPTS="-Dfile.encoding=utf-8"

else

	JAR_OPTS="--spring.profiles.active=${JAR_PROFILE} -Dfile.encoding=utf-8"

fi

exec 2>&1

echo "$(date) Container ENV"

env

echo ""
echo " $(date)  [info]   Pacotes: ${JAR_FILE} "
echo " $(date)  [info]   Parametros: -Xmx${JAVA_MAX_MEM}M ${JAR_OPTS} "
echo " $(date)  [info]   MD5 pacotes: "
echo ""

cd ${JAR_DIR} || exit
for jar in ${JAR_FILE} ; do md5sum "${jar}" ; done

echo ""

if [ "$(find ${JAR_DIR} -type f -iname "*.jar" | wc -l)" -eq 0 ]
	then

		echo " $(date)  [ATENCAO] Nenhum arquivo jar identificado. Nada a fazer aqui!!"
		exit 2
		
fi

if [ "$(find ${JAR_DIR} -type f -iname "*.jar" | wc -l)" -gt 1 ]
	then

		echo " $(date)  [ATENCAO] Identificado mais de 1 arquivo JAR, atenção para conflitos de porta TCP ou duplicidade de pacote JAR!!! recomendado 1 JAR por container"

fi

for jar in ${JAR_FILE}
do
	echo " $(date)  [info]   Iniciando ${jar} ..."

	${BIN_JAVA}  -Xms32M -Xmx${JAVA_MAX_MEM}M -jar ${JAR_DIR}/"${jar}" ${JAR_OPTS} | tee -a /logs/"${jar}".log &

done
# segura o container em execução por N segundos... util para automatizar restart diario, se não for o caso, utilizar um valor bem alto (meses, anos, etc)
sleep 31536000