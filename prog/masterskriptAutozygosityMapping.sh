#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################


if [ -z $1 ]; then
    echo "brauche den Code fuer die Rasse: BSW oder HOL "
    exit 1
elif [ ${1} == "BSW" ]; then
	echo $1 > /dev/null
elif [ ${1} == "HOL" ]; then
	echo $1 > /dev/null
elif [ ${1} == "VMS" ]; then
        echo $1 > /dev/null
else
	echo " $1 != BSW / HOL / VMS, ich stoppe"
	exit 1
fi
if [ -z $2 ]; then
    echo "brauche den Code wer als Kontrolle verwendet werden soll. A fuer ALLE Tiere, D fuer nur definierte Tiere "
    exit 1
elif [ ${2} == "A" ]; then
	echo $1 > /dev/null
elif [ ${2} == "D" ]; then
	echo $1 > /dev/null
else
	echo " $2 != A / D, ich stoppe"
	exit 1
fi


OS=$(uname -s)
if [ $OS != "Linux" ]; then
echo "change to Linus system"
exit 1
fi
if [ $OS = "Linux" ]; then
BTA="WholeGenome" 
fi

#check if parameter vor no of prll jobs was given
if [ -z ${GWAStrait} ] ;then
echo "GWAStrait is missing which is not allowed. Check ${lokal}/parfiles/steuerungsvariablen.ctr.sh"
exit 1
fi


##########################################################################################
# Funktionsdefinition

# Funktion gibt Spaltennummer gemaess Spaltenueberschrift in csv-File zurueck.
# Es wird erwartet, dass das Trennzeichen das Semikolon (;) ist
getColmnNr () {
# $1: String der Spaltenueberschirft repraesentiert
# $2: csv-File
    colNr_=$(head -1 $2 | tr ';' '\n' | grep -n "^$1$" | awk -F":" '{print $1}')
    if test -z $colNr_ ; then
        echo "FEHLER: Spalte mit den Namen $1 existiert nicht in $2 --> PROGRAMMABBRUCH"
        echo "... oder Trennzeichen in $2 ist nicht das Semikolon (;)"
        exit 1
    fi
}

##########################################################################################
##################################
echo "prepare genomewide Genotypes for PLINK ROH now for $1"
if [ ${2} == "A" ]; then
echo "hier wird nur unterstuetzt wenn definierte Kontrollgruppe vorhanden ist"
exit 1
fi
if [ ${2} == "D" ]; then
$BIN_DIR/createGenotypesForAutozygosityMapping.sh ${1} GENOTYPES 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 1"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/createGenotypesForAutozygosityMapping.sh ${1}
        exit 1
fi
fi
echo "----------------------------------------------------"
##################################
echo "Run Homozygosity Mapping using PLINK for ${GWAStrait} and for $1"
$BIN_DIR/homozygosityMapping.sh ${1} 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 2"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/homozygosityMapping.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo "send finishing mail"
$BIN_DIR/sendFinishingMail.sh $PROG_DIR/${SCRIPT} $1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 10"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/sendFinishingMail.sh ${d}
        exit 1
fi
echo "----------------------------------------------------"
#else
#echo "oooops :-( ....Change to a Linux-Server. You are not on a Linux Server, but this is required"
#$BIN_DIR/sendErrorMail.sh $PROG_DIR/${SCRIPT} ${1}
#fi
echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
