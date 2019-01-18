#!/bin/bash 
SCRIPT=`basename ${BASH_SOURCE[0]}`
RIGHT_NOW=$(date)
echo $RIGHT_NOW Start ${SCRIPT}
date


##############################################################
lokal=$(pwd | awk '{print $1}')
source  /qualstore03/data_zws/snp/50Kimputing/parfiles/steuerungsvariablen.ctr.sh
###############################################################

if [ -z $1 ]; then
    echo "brauche den Code welches Tier gemeldet werden soll"
    exit 1
fi
TVD=$(awk -v ID=${1} 'BEGIN{FS=";"}{if($1 == ID) print $2}'  $WORK_DIR/animal.overall.info | head -1)
zo=$(awk -v T=${TVD} 'BEGIN{FS=";"}{if($2 == T) print substr($3,1,3)}' $WORK_DIR/animal.overall.info | head -1)
echo ${TVD} ${zo}
if [ ${zo} == "BSW" ] || [ ${zo} == "JER" ];then
	#mails=$(echo "michaela.glarner@braunvieh.ch katrin.haab@braunvieh.ch franz.seefried@qualitasag.ch madeleine.berweger@qualitasag.ch mirjam.spengeler@qualitasag.ch")
	mails=$(echo "franz.seefried@qualitasag.ch madeleine.berweger@qualitasag.ch mirjam.spengeler@qualitasag.ch")
elif [ ${zo} == "HOL" ];then
#	mails=$(echo "alex.barenco@swissherdbook.ch eric.barras@holstein.ch genotype@holstein.ch franz.seefried@qualitasag.ch madeleine.berweger@qualitasag.ch mirjam.spengeler@qualitasag.ch")
	mails=$(echo "franz.seefried@qualitasag.ch madeleine.berweger@qualitasag.ch mirjam.spengeler@qualitasag.ch")
elif [ ${zo} == "SIM" ];then
	#mails=$(echo "alex.barenco@swissherdbook.ch franz.seefried@qualitasag.ch madeleine.berweger@qualitasag.ch mirjam.spengeler@qualitasag.ch")
	mails=$(echo "franz.seefried@qualitasag.ch madeleine.berweger@qualitasag.ch mirjam.spengeler@qualitasag.ch")
elif [ ${zo} == "AAN" ] || [ ${zo} == "DXT" ] || [ ${zo} == "LIM" ];then
	#mails=$(echo "svenja.strasser@mutterkuh.ch franz.seefried@qualitasag.ch madeleine.berweger@qualitasag.ch mirjam.spengeler@qualitasag.ch")
	mails=$(echo "franz.seefried@qualitasag.ch madeleine.berweger@qualitasag.ch mirjam.spengeler@qualitasag.ch")
else
	#mails=$(echo "alex.barenco@swissherdbook.ch eric.barras@holstein.ch genotype@holstein.ch michaela.glarner@braunvieh.ch katrin.haab@braunvieh.ch svenja.strasser@mutterkuh.ch franz.seefried@qualitasag.ch madeleine.berweger@qualitasag.ch mirjam.spengeler@qualitasag.ch")
	mails=$(echo "franz.seefried@qualitasag.ch madeleine.berweger@qualitasag.ch mirjam.spengeler@qualitasag.ch")
fi

if [ -z $2 ]; then
    echo "brauche den Code fuer das neue labfile"
    exit 1
fi
if [ -z $3 ]; then
    echo "brauche den Code fuer das Vergleichsfile aus dem Archiv"
    exit 1
fi
if [ -z $4 ]; then
    echo "brauche die Anzahl an Missmatching genotypes"
    exit 1
fi
if [ -z $5 ]; then
    echo "brauche die Anzahl an SNPs die verglichen wurden"
    exit 1
fi
#mail 
for person in ${mails} ; do
echo "To: ${person}
From: ${person}
Subject: Attention: new genotype of Sample (idanimal) ${1} suspekt

Dear colleague,

Der neue Genotyp stimmt schlecht mit dem existierenden Archivgenotyp ueberein.

Basierend auf den bereits vorhandenen Genotypen ist der neue Genotyp von ${2} suspekt, er wurde jedoch verarbeitet und im Archiv abgelegt, im Fall Tieren mit meheren Typisierungen mit unterschiedlichen Chipdichten ist dies kritisch da Genotypen gemischt werden

-> fsf Bescheid geben wenn moeglich noch for dem Start des superMasterskript.sh

neues Labfile:
${2}
Archivfile:
${3}

Summary of comparison given here:
No. of Missmatching Genotypes (noncalled genotypes excluded):
${4}
No. of analyzed Genotypes (representing callrate between both genotypes using 200 ISAG GenoExPSE SNPs), (note: should not be too low!!!):
${5}


echo " "
Kind regards, Qualitas AG, Switzerland" | ssmtp ${person}

done





date
RIGHT_NOW=$(date)
echo $RIGHT_NOW ENDE ${SCRIPT}

