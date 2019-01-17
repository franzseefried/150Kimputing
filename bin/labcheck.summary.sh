#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "
#######################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
#######################################################
set -o nounset
set -o errexit

minPerYear=$(echo "60 24 30 12" | awk '{print "-"$1*$2*$3*$4}')
#echo $minPerYear
for canalysis in callingrate heterorate gcscore; do
    if [ ${canalysis} == "callingrate" ]; then limit=${CLLRT};ulimit=0.6;olimit=1.0;fi
    if [ ${canalysis} == "heterorate" ]; then limit=${HTRT};ulimit=0.0;olimit=1.0;fi
    if [ ${canalysis} == "gcscore" ]; then limit=${GCSCR};ulimit=0.0;olimit=1.0;fi
    for chip in Qualitas_BOVG50V01_ Qualitas_BOVG50V02_ Qualitas_BOVUHDV03_ Qualitas_BOV770V01_ Qualitas_BOVF250V1_ ;do
       FILES=${CHCK_DIR}/${run}/${canalysis}*${chip}*
       FILES=$(echo $FILES)
       #wenn es ueberhaupt files gibt
       case $FILES in FOO\*) echo "No files found" ;; esac
       rm -f $TMP_DIR/canalysis.txt
	   for i in $(ls -trl /qualstore03/data_archiv/SNP/checks/????/${canalysis}.*${chip}* | awk '{print $9}'); do 
           run=$(echo $i | cut -d'/' -f6)
           filename=$(echo $i | cut -d'/' -f7 | cut -d'.' -f3) 
           #echo $run $filename
           #wenn file juenger als 1 Jahr
           if test "`find ${i} -mmin ${minPerYear}`"; then
              nlines=$(wc -l ${i} | awk '{print $1}')
              if [ ${nlines} -gt 9 ]; then
                echo ${i}
                awk -v r=${run} -v f=${filename} '{if(NR > 1) print $1,$2,r"_"f}' ${i} >> $TMP_DIR/canalysis.txt
              fi
          fi
      done
    Rscript $BIN_DIR/labcheck.boxplot.R $RES_DIR/${canalysis}.${chip}.boxplot.last12Months.pdf ${limit} ${ulimit} ${olimit} $TMP_DIR/canalysis.txt >/dev/null
    done
done

echo " "
echo " "
echo "check:"
ls -trl $RES_DIR/*.boxplot.*
rm -f $TMP_DIR/canalysis.txt
echo " "
echo " "
cd ${lokal}
echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
