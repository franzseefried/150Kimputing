#!/bin/bash
SCRIPT=`basename ${BASH_SOURCE[0]}`
RIGHT_NOW=$(date)
echo RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################


if [ -z $1 ]; then
    echo "brauche den Code fuer die Rasse: BSW oder HOL oder VMS "
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
    echo "brauche die Strategie:"
    echo "ALLANIMALS: -----> alle haplotypen werden gegen alle verglichen"
    echo "SINGLEANIMAL: ---> ein bestimtes Tier und dessen 2 haplotypen werden gegen alle haplotypen verglichen"
    exit 1
fi
today=$(date '+%Y%m%d')

if [ ${2} == "SINGLEANIMAL" ]; then
if [ -z $3 ]; then
    echo "brauche die TVD Nummer des zu pruefenden Tieres"
    exit 1
fi
TVDANIMAL=${3}

IDIMPUTING=$(awk -v t=${TVDANIMAL} '{if($5 == t) print $1}' $WRK_DIR/Run${run}.alleIDS_${1}.txt)
fi

#check Server
ort=$(uname -a | awk '{print $1}' )
if  [ ${ort} == "Darwin" ]; then
   echo "oooops :-( ....Change to a Linux-Server. You are not on a Linux Server, but this is required"
   $BIN_DIR/sendErrorMail.sh $SCRIPT $1
elif [ ${ort} == "Linux" ]; then
   maschine=$(uname -a | awk '{print $2}'  | cut -d'.' -f1)
   if [ ${maschine} != "castor" ]; then
       echo "Due to R version issues and parallel computation you have to change to castor";
       $BIN_DIR/sendErrorMail.sh $SCRIPT $1
       exit 1
   fi
fi
##################################
echo "Run stringdist R for GPsearch $1"
wcl=$(wc -l $TMP_DIR/${1}.GPsearch.Fgt.animals | awk '{print $1}' )
if [ ${2} == "SINGLEANIMAL" ]; then
    #struktur outfile: header mit den idanimals, allg matrix mit den distances
    rm -f $TMP_DIR/${1}.GPsearch.${TVDANIMAL}.${run}.txt
	Rscript $BIN_DIR/GPsearch_stringdist-hamming-parallel.R ${wcl} $TMP_DIR/${1}.GPsearch.FgtN.haplotypesInRows ${TMP_DIR}/${1}.GPsearch.Fgt.animals $TMP_DIR/${1}.GPsearch.${TVDANIMAL}.${run}.txt ${2} ${IDIMPUTING}
fi
if [ ${2} == "ALLANIMALS" ]; then
	Rscript $BIN_DIR/GPsearch_stringdist-hamming-parallel.R ${wcl} $TMP_DIR/${1}.GPsearch.FgtN.haplotypesInRows ${TMP_DIR}/${1}.GPsearch.Fgt.animals $TMP_DIR/${1}.GPsearch.ALL.${run}.txt ${2}
fi
#single animal R code non parallel if needed for double checking parallelized code:
#Rscript $BIN_DIR/GPsearch_stringdist-hamming-singleAnimal.R ${wcl} $TMP_DIR/${1}.GPsearch.FgtN.haplotypesInRows $TMP_DIR/${1}.GPsearch.Fgt.animals ${TMP_DIR}/${1}.GPsearch.hamming.singleAnimal.txt ${IDIMPUTING} SINGLEANIMAL
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 1"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/GPsearch_stringdist-hamming-parallel.R $1
        exit 1
fi
echo "----------------------------------------------------"
##################################
if [ ${2} == "SINGLEANIMAL" ]; then
echo "Go back and create a list sorted by distance for each candidate haplotype, + set limitations: as defined during initial steps:"
echo "hamming: 500 - 900 for parent - offspring connections"
echo "hamming: 850 - 1400 for GP - grandchild connections"
#attention file has header
rm -f $RES_DIR/${TVDANIMAL}.${1}.hammingdistance.SetOfAni.${run}.txt
for hpltyp in 2 3;do
   $BIN_DIR/awk_transpose.job $TMP_DIR/${1}.GPsearch.${TVDANIMAL}.${run}.txt |sort -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -o'2.5 1.2 1.3 2.4' -1 1 -2 1 - <(sort -T ${SRT_DIR} -t' ' -k1,1 $WRK_DIR/Run${run}.alleIDS_${1}.txt ) | awk -v hh=${hpltyp} '{if($hh <= 1400) print "Haplotype"hh-1,$1,$hh,$4}'| sort -T ${SRT_DIR} -t' ' -k1,1 -k3,3n >> $RES_DIR/${TVDANIMAL}.${1}.hammingdistance.SetOfAni.${run}.txt
done
sort -T ${SRT_DIR} -t' ' -k1,1 -k3,3n $RES_DIR/${TVDANIMAL}.${1}.hammingdistance.SetOfAni.${run}.txt -o $RES_DIR/${TVDANIMAL}.${1}.hammingdistance.SetOfAni.${run}.txt;
echo "results have been written to $RES_DIR/${TVDANIMAL}.${1}.hammingdistance.SetOfAni.${run}.txt"
fi
if [ ${2} == "ALLANIMALS" ]; then
   echo "go and check the big result file"
fi
##################################
echo "send finishing mail"
$BIN_DIR/sendFinishingMail.sh $SCRIPT $1 2>&1
err=$(echo $?)
if [ ${err} -gt 0 ]; then
        echo "ooops Fehler 2"
        $BIN_DIR/sendErrorMail.sh $BIN_DIR/sendFinishingMail.sh $1
        exit 1
fi
echo "----------------------------------------------------"

echo " "
RIGHT_END=$(date)
echo RIGHT_END Ende ${SCRIPT}
