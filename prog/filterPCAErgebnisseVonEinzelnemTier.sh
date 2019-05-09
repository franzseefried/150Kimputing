#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################


if [ -z $1 ]; then
    echo "brauche den Code fuer die Rasse: BSW oder HOL oder VMS"
    exit 1
elif [ -z $2 ]; then
    echo "brauche TVD des Tieres"
    exit 1
elif [ $1 == 'BSW' ] || [ $1 == 'HOL' ]  || [ $1 == 'VMS' ] ; then
    echo " "
#hole idanimal
    ani=$(echo ${2}  | sed 's/\.//g')
    breed=${1}
    muni=${ani}

    if [ ! -z ${muni} ] ; then
	pcaLD=$(cat $RES_DIR/${breed}LD.PCA.scores.txt | awk -v animo=${muni} 'BEGIN{FS=";"}{if($13 == animo) print $3";"$4}')
	if [ ! -z ${pcaLD} ] ; then
	    echo "Tier $ani ist LD typisiert und hat folgende PCA-Scores PCA1;PCA2:"
	    echo $pcaLD
	    echo "check on plot in $RES_DIR/${breed}LDpcaPlotMitBlut.pdf"
	    echo " "
	else
	    pcaFIFTYK=$(cat $RES_DIR/${breed}HD.PCA.scores.txt |  awk -v animo=${muni} 'BEGIN{FS=";"}{if($13 == animo) print $3";"$4}')
	    if [ ! -z ${pcaFIFTYK} ]; then
		echo "Tier $ani ist 50K-typisiert und hat folgende PCA-Scores PCA1;PCA2:"
		echo $pcaFIFTYK 
		echo "check on plot in $RES_DIR/${breed}HDpcaPlotMitBlut.pdf"
		echo " "
	    else
		echo "ooops Tier $ani ist nict in PCA, hat aber Pedigree-Record. please check"
	    fi
	fi
    else
	echo $ani ist nicht in den Daten von ${breed}
    fi




fi


echo " "
RIGHT_NOW=$(date )
echo $RIGHT_NOW Ende ${SCRIPT}
