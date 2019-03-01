#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################


#lokale Variable do not change!!!
if [ -z $1 ]; then
    echo "brauche den Code welche Rasse verarbeitet werden soll, 'BSW' oder 'HOL' oder 'VMS'"
    exit 1
fi
if [ -z $2 ]; then
	echo "brauche den Code fuer das Merkmal, z.B. UKV fuer Unterkierferverkürzung"
	exit 1
fi
breed=${1}
trait=${2}
echo ${breed}  ${trait}
##################################################


echo "single SNP regression:"
(echo "Chr SNP bp ReferenceAllele OtherAllele Freq b se P";
awk '{if(NR > 1) printf "%-3s%-12s%-1s%.3f%-1s%.3f%-1s%.3f%-1s%.30f \n", $1,$2," ",$3," ",$4," ",$5," ",$6}' $GWAS_DIR/GWASoutput${breed}_${trait}_ssr/gwas_ssr_${trait}_p.txt |sed "s/ \{1,\}/ /g" | sort -T ${SRT_DIR} -t' ' -k6,6n | head -50 )

echo " "
echo "logistic regression"
(echo "Chr SNP bp ReferenceAllele OtherAllele Freq b se P";
awk '{if(NR > 1) printf "%-3s%-12s%-1s%.3f%-1s%.3f%-1s%.3f%-1s%.30f \n", $1,$2," ",$3," ",$4," ",$5," ",$6}' $GWAS_DIR/GWASoutput${breed}_${trait}_lrg/gwas_gqls_${trait}_p.txt |sed "s/ \{1,\}/ /g" | sort -T ${SRT_DIR} -t' ' -k6,6n | head -50 )

echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}

