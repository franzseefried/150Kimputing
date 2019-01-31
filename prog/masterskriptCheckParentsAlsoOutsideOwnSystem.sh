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
    echo "brauche den Code fuer die Rasse: ALL "
    exit 1
elif [ ${1} == "ALL" ]; then
	echo $1 > /dev/null
else
	echo " $1 != BSW / HOL / VMS, ich stoppe"
	exit 1
fi

OS=$(uname -s)
if [ $OS = "Linux" ]; then
ps fax | grep -i FImpute_Linux | awk '{print $1 }'  | while read job; do if [ -z ${job} ] ; then echo "ooops there are Fimpute-Jobs running. They would be killed by the following programms. Change to another Linux-Server"; exit 1 ;fi ; done

##################################
echo Step 1
$BIN_DIR/defineDatasetForAcrossBreedParentsSearch.sh.sh $1 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 1"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/defineDatasetForAcrossBreedParentsSearch.sh.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 1
$BIN_DIR/findeTiereMitVater0undSetzeDUMMYVater.sh $1 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 1"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/findeTiereMitVater0undSetzeDUMMYVater.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 1
$BIN_DIR/findeTiereMitVater0undSetzeDUMMYVater.sh $1 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 1"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/findeTiereMitVater0undSetzeDUMMYVater.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 2
$BIN_DIR/runningPediCHECKusingFimpute.sh -b $1 -p sire 2>&1
echo "----------------------------------------------------"
##################################
echo Step 3
$BIN_DIR/verarbeiteFimputePediCheckIdentifiziereTiereMitUnbekanntemVater.sh $1 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 3"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/verarbeiteFimputePediCheckIdentifiziereTiereMitUnbekanntemVater.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 4
$BIN_DIR/verarbeiteFimputePediCheckAendereVater.sh $1 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 4"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/verarbeiteFimputePediCheckAendereVater.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 5
$BIN_DIR/findeTiereMitMutter0undSetzeDUMMYMutter.sh $1 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 5"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/findeTiereMitMutter0undSetzeDUMMYMutter.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 6
$BIN_DIR/runningPediCHECKusingFimpute.sh -b $1 -p dam 2>&1
echo "----------------------------------------------------"
##################################
echo Step 7
$BIN_DIR/verarbeiteFimputePediCheckIdentifiziereTiereMitUnbekannterMutter.sh $1 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 7"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/verarbeiteFimputePediCheckIdentifiziereTiereMitUnbekannterMutter.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 8
$BIN_DIR/verarbeiteFimputePediCheckAendereMutter.sh $1 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 8"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/verarbeiteFimputePediCheckAendereMutter.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 9
$BIN_DIR/verarbeiteFimputePediCheckLoescheTiereMitUnbekanntemElter.sh $1 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 9"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/verarbeiteFimputePediCheckLoescheTiereMitUnbekanntemElter.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 10
$BIN_DIR/findeTiereMitNonGenotypedSire.sh $1 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 10"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/findeTiereMitNonGenotypedSire.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 11
$BIN_DIR/runningNonGenotypedParentsCHECKusingFimpute.sh -b $1 -p sire 2>&1
echo "----------------------------------------------------"
##################################
echo Step 12
$BIN_DIR/verarbeiteFimputeNGPCheckIdentifiziereUndAendereTiereWoAlternativSireFound.sh $1 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 12"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/verarbeiteFimputeNGPCheckIdentifiziereUndAendereTiereWoAlternativSireFound.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 13
$BIN_DIR/findeTiereMitNonGenotypedDam.sh $1 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 13"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/findeTiereMitNonGenotypedDam.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 14
$BIN_DIR/runningNonGenotypedParentsCHECKusingFimpute.sh -b $1 -p dam 2>&1
echo "----------------------------------------------------"
##################################
echo Step 15
$BIN_DIR/verarbeiteFimputeNGPCheckIdentifiziereUndAendereTiereWoAlternativDamFound.sh $1 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 15"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/verarbeiteFimputeNGPCheckIdentifiziereUndAendereTiereWoAlternativSireFound.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 16
$BIN_DIR/verarbeiteFimputePediCheckLoescheTiereMitMultiMatchingSiresAndOrDams.sh $1 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 16"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/verarbeiteFimputePediCheckLoescheTiereMitMultiMatchingSiresAndOrDams.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
echo Step 17
$BIN_DIR/updatePEDUMCODIERUNFandRENUMMERGEDPEDIforAnimalsWithCHangedPedigrees.sh -b ${1} 2>&1 
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 17"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/updatePEDUMCODIERUNFandRENUMMERGEDPEDIforAnimalsWithCHangedPedigrees.sh $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
if [ ${1} != "VMS" ] && [ ${HDfol} == "Y" ]; then
echo Step 18 *****°°°°°Run HD Imputation via superMasterskript°°°°°*****
cd ${SNP_DIR}/HDimputing
nohup prog/superMasterskript.sh ${1} 2>&1 > log/superMasterskript_${1}.log &
cd ${MAIN_DIR}
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 18"
        $BIN_DIR/sendErrorMail.sh ${SNP_DIR}/HDimputing/prog/masterskriptHDprep.sh $1
        exit 1
fi
echo "----------------------------------------------------"
else
echo " "
echo "No HD imputation will follow"
fi
##################################
echo Step 19
$BIN_DIR/sendFinishingMail.sh $PROG_DIR/masterskriptPedigreePlausi.sh $1 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 19"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/sendFinishingMail.sh $1
        exit 1
fi
echo "----------------------------------------------------"
else
echo "oooops :-( ....Change to a Linux-Server. You are not on a Linux Server, but this is required"
fi

echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
