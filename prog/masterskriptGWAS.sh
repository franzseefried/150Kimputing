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
echo "prepare genomewide Genotypes for SNP1101 now for $1"
$BIN_DIR/GWASgenoFilePreparationForSNP1101.sh ${1} GENOTYPES 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 1"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/GWASgenoFilePreparationForSNP1001.sh ${1}
        exit 1
fi
if [ ${DEFCNTRGRP} == "Y" ]; then
$BIN_DIR/GWASreduceGTfileToCasesAndDefinedControls.sh ${1} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 1"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/GWASreduceGTfileToCasesAndDefinedControls.sh ${1}
        exit 1
fi
fi
echo "----------------------------------------------------"
##################################
echo "prepare PedigreeFile for SNP1101 now for $1"
$BIN_DIR/GWASpedigreeFilePreparationForSNP1101.sh ${1} GENOTYPES 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 2"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/GWASpedigreeFilePreparationForSNP1101.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo "prepare SNPmap file for SNP1101 now DEFCNTRGRPfor $1"
$BIN_DIR/GWASsnpMapFilePreparationForSNP1101.sh ${1} GENOTYPES 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 2"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/GWASsnpMapFilePreparationForSNP1101.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo "prepare Phenotypefile for SNP1101 now for $1"
$BIN_DIR/GWASphenotypeFilePreparationForSNP1101.sh ${1} GENOTYPES 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 2"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/GWASphenotypeFilePreparationForSNP1101.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo "Run GWAS MME using SNP1101 for ${GWAStrait} and for $1"
$BIN_DIR/runGWASSNP1101.sh ${1} ${GWAStrait} 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 2"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/runGWASSNP1101.sh ${1}
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo "List GWAS result from SNP1101"
$BIN_DIR/GWASlistTop100SNPsfromGWAS.sh ${1} ${GWAStrait} 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 3"
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
echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
