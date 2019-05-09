#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "


##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o nounset
set -o errexit




outtime=$(date +"%d%m%Y")
#######Funktionsdefinition
getColmnNrSemicl () {
# $1: String der Spaltenueberschirft repraesentiert
# $2: csv-File
    colNr_=$(head -1 $2 | tr ';' '\n' | grep -n "^$1$" | awk -F":" '{print $1}')
    if test -z $colNr_ ; then
        echo "FEHLER: Spalte mit den Namen $1 existiert nicht in $2 --> PROGRAMMABBRUCH"
        echo "... oder Trennzeichen in $2 ist nicht das Semikolon (;)"
        exit 1
    fi
}
numCompare() {
#https://stackoverflow.com/questions/8654051/how-to-compare-two-floating-point-numbers-in-bash
#   awk -v n1="$1" -v n2="$2" 'BEGIN {printf "%s " (n1<n2?"<":">=") " %s\n", n1, n2}'
   awk -v n=${1} -v m=${2} 'BEGIN {if(n >= m) print "1"; else print "0"}'
}
##########################

#get Info about SNP from Reftab
getColmnNrSemicl SNP_Name ${ISAGPARENTAGESBOLIST} ; colORG=$colNr_
getColmnNrSemicl SNPName ${ISAGPARENTAGESBOLIST} ; colSCT=$colNr_
getColmnNrSemicl ISAG-Core ${ISAGPARENTAGESBOLIST} ; colCORE=$colNr_
getColmnNrSemicl ISAG-Extra ${ISAGPARENTAGESBOLIST} ; colEXTRA=$colNr_
getColmnNrSemicl Discovery ${ISAGPARENTAGESBOLIST} ; colDISCOVERY=$colNr_
getColmnNrSemicl MS_Imputation ${ISAGPARENTAGESBOLIST} ; colMSIMPUTATION=$colNr_
getColmnNrSemicl Top_A/B_alleles  ${ISAGPARENTAGESBOLIST} ; colALLELES=$colNr_
#echo $colORG $colSCT $colCORE $colEXTRA $colMSIMPUTATION $colALLELES


#loeschen der leeren files:
if ! find ${LAB_DIR}/ -maxdepth 0 -empty | read v; then
    for file in $( find ${LAB_DIR}/*) ; do
        if [ ! -s ${file} ] ; then
           rm -f ${file};
        fi;
    done
fi


cd $LAB_DIR
filearry=$(find *)

pids=
for labfile in $(find *) ; do
(
 rm -f $TMP_DIR/genoexpse.CLRT.NSNP.SAMPLEID.${labfile}
 rm -f ${BAT_DIR}/${outtime}.${run}.GenoExPSEsnp.${labfile}

 lbb=$(echo $labfile | cut -b1-3)
 if [ ${lbb} == "BSW" ] || [ ${lbb} == "HOL" ] || [ ${lbb} == "VMS" ]; then
 lbfshort=$(echo $labfile | cut -d'-' -f2 | cut -d'.' -f1)
 else
 lbfshort=$(echo $labfile | cut -d'.' -f1)
 fi
 #echo $labfile ${lbfshort}

#for labfile in $(ls BSW*toWorkWith) ; do
  nSNP=$(wc -l ${labfile} | awk '{print $1}')
  if [ ${nSNP} -eq 0 ]; then
	rm -f ${labfile}
  else
    echo " "
    echo "GenoexPSE fuer ${labfile}"
    #ani=$(head -1 ${labfile} | awk '{print $2}' )
    #v=$(awk -v animal=${ani} '{if($2 == animal) print }' ${labfile} | wc -l | awk '{print $1}')
    awk -v a=${colORG} -v b=${colCORE} -v c=${colEXTRA} 'BEGIN{FS=";"}{if($b == 1 || $c == 1) print $a,"Y"}' ${ISAGPARENTAGESBOLIST} | awk '{print $1,$2,NR}' > $TMP_DIR/${labfile}.outmap.isagsnplst

  
#rechne callingrate aus. achtung es brauchte eine anpassung in Eingangscheck.R. zur entwickl des skripts
  for j in $(awk '{print $2}' ${labfile} | sort -T ${SRT_DIR} -T ${SRT_DIR} -u -T $SRT_DIR); do
  nSNP=$(awk -v jj=${j} '{if($1 == jj) print $2}' $CHCK_DIR/${run}/nSNPs.check.*)
  CLRT=$(awk -v jj=${j} '{if($1 == jj) print $2}' $CHCK_DIR/${run}/callingrate* | awk '{if($1 <= 1) printf "%3.1f\n", $1*100; else printf "%3.1f\n", $1}')
  #idanimal
  IDANIMAL=$(awk -v ID=${j} 'BEGIN{FS=";"}{if($2 == ID) print $1}' $WORK_DIR/animal.overall.info | sed 's/ //g' |  head -1)
#hole sampleID. bei externen SNP soll die SNPID leer sein. Alexa 26.09.17
  if test -s $CHCK_DIR/${run}/*${lbfshort}.*.linklist.genoexPSE; then
  SAMPLEID=$(awk -v JD=${j} 'BEGIN{FS=";"}{if($2 == JD) print $1}' $CHCK_DIR/${run}/*${lbfshort}.*.linklist.genoexPSE)
  else
  SAMPLEID=
  fi
  echo "${j};${IDANIMAL};${nSNP};${CLRT};${labfile};${SAMPLEID}" >> $TMP_DIR/genoexpse.CLRT.NSNP.SAMPLEID.${labfile}
  done


#reduziere Labfile auf die SNPs in der ISAG Abstammungskontrolle
#notloesung: Interbull SNP liste hat SNPnamen nur mit capital letters
   awk 'BEGIN{FS=" "}{ \
      if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));sp[$1]=$2;ss[$1]=$3}} \
      else {sub("\015$","",$(NF));bpT=sp[toupper($1)];spT=ss[toupper($1)]; \
      if   (bpT != "" && bpT == "Y" && spT != "") print toupper($1),$2,$3$4,spT}}' $TMP_DIR/${labfile}.outmap.isagsnplst ${labfile} | tee $TMP_DIR/${labfile}.genoexpse | awk '{print $2}' | sort -T ${SRT_DIR} -T ${SRT_DIR} -u > $TMP_DIR/${labfile}.genoexpse.samples


#auffuellen der fehlenden SNPs zur Sicherheit 
   for muni in $(cat $TMP_DIR/${labfile}.genoexpse.samples); do
      awk -v indi=${muni} '{if($2 == indi) print $0}' $TMP_DIR/${labfile}.genoexpse > $TMP_DIR/${labfile}.genoexpse.${muni}
      
      awk -v indi=${muni} 'BEGIN{FS=" "}{ \
         if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));sp[$1]=$2;ss[$1]=$3;mp[$1]=$4}} \
         else {sub("\015$","",$(NF));bpT=sp[$1];spT=ss[$1];mpT=mp[$1]; \
         if   (bpT != "") print $1,bpT,spT,mpT;
         else print $1,indi,"--",$3}}' $TMP_DIR/${labfile}.genoexpse.${muni} $TMP_DIR/${labfile}.outmap.isagsnplst
      rm $TMP_DIR/${labfile}.genoexpse.${muni}
   done > $TMP_DIR/${labfile}.genoexpse.full

wc -l $TMP_DIR/${labfile}.genoexpse.samples
wc -l $TMP_DIR/${labfile}.genoexpse
wc -l $TMP_DIR/${labfile}.genoexpse.full
echo " "
echo " "
   
   for tier in $(cat $TMP_DIR/${labfile}.genoexpse.samples); do

      #(
      id=$(awk -v m=${tier} 'BEGIN{FS=";"}{if($1 == m) print $2}' $TMP_DIR/genoexpse.CLRT.NSNP.SAMPLEID.${labfile} )
      ANZSNP=$(awk -v m=${tier} 'BEGIN{FS=";"}{if($1 == m) print $3}' $TMP_DIR/genoexpse.CLRT.NSNP.SAMPLEID.${labfile} )
      CALL=$(awk -v m=${tier} 'BEGIN{FS=";"}{if($1 == m) print $4}' $TMP_DIR/genoexpse.CLRT.NSNP.SAMPLEID.${labfile} )
      SNPID=$(awk -v m=${tier} 'BEGIN{FS=";"}{if($1 == m) print $6}' $TMP_DIR/genoexpse.CLRT.NSNP.SAMPLEID.${labfile} )
      gt=$(awk -v tierchen=${tier} '{if ($2 == tierchen) print $1,$3,$4}' $TMP_DIR/${labfile}.genoexpse.full | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k3,3n | awk '{gsub("AA","0",$2);gsub("AB","1",$2);gsub("BB","2",$2);gsub("--","5",$2); print $2}' | tr '\n' ' ' | sed 's/ //g')
	  nGENOSNP=$(echo $gt | wc -c | awk '{print $1-1}' )
      notcall=$(echo $gt | sed 's/[0-2]//g' | wc -c | awk '{print $1-1}' )
      #callrate 95 Prozent siehe Praesi vanDoormal Tallin 2017
      if [ ${notcall} -gt 10 ]; then
        #echo "habe zu tiefe Callrate von ${notcall} von ${tier} in string von ${labfile}, nicht geeignet fuer GenoExPSE Abstammungskontrolle"; 
        #wird abgefangen in ARGUS laut Karin Frey 26.09.17
        echo "${id};${SNPID};${gt};${ANZSNP};${CALL}" >> ${BAT_DIR}/${outtime}.${run}.GenoExPSEsnp.${labfile}
      else
        echo "${id};${SNPID};${gt};${ANZSNP};${CALL}" >> ${BAT_DIR}/${outtime}.${run}.GenoExPSEsnp.${labfile}
      fi      
            #rm -f ${TMP_DIR}/${tier}.${labfile}
      #)&
    done 
  fi
)&
pid=$!
pids=(${pids[@]} $pid)
done

sleep 20
echo "Here ar the jobids of the stated Jobs"
echo ${pids[@]}
nJobs=$(echo ${pids[@]} | wc -w | awk '{print $1}')
echo "Waiting till Jobs are finished"
while [ $nJobs -gt 0 ]; do
  pids_old=${pids[@]}
  pids=
  nJobs=0
  for pid in ${pids_old[@]}; do
    if kill -0 $pid > /dev/null 2>&1; then # kill -0 $pid ist true falls der Job noch laeuft
      nJobs=$(($nJobs+1))
      pids=(${pids[@]} $pid)
    fi
  done
  sleep 20
done

echo " "
echo "check if files are ready and build one big file for database and replace genesseekID by auftragsID"
for ifile in ${filearry}; do 
if test -s ${BAT_DIR}/${outtime}.${run}.GenoExPSEsnp.${ifile}; then
awk 'BEGIN{FS=";"}{ \
      if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));sp[$1]=$21}} \
      else {sub("\015$","",$(NF));bpT=sp[$2]; \
      if   (bpT != "" ) print $1";"bpT";"$3";"$4";"$5
      else              print $1";;"$3";"$4";"$5}}' $WORK_DIR/crossref.txt ${BAT_DIR}/${outtime}.${run}.GenoExPSEsnp.${ifile} 
rm -f ${BAT_DIR}/${outtime}.${run}.GenoExPSEsnp.${ifile}
fi
done > ${BAT_DIR}/${outtime}.${run}.GenoExPSEsnp

cd ${MAIN_DIR}

#check if there are records without callrate or nSNPs
nSUS=$(awk 'BEGIN{FS=";"}{if($4 == "" || $5 == "") print}' ${BAT_DIR}/${outtime}.${run}.GenoExPSEsnp | wc -l | awk '{print $1}')
if [ ${nSUS} != 0 ]; then
echo "There are ${nSUS} record where callrate or nSNPs is empty.... check"
$BIN_DIR/sendAttentionMailAboutChipcallrateInGenoexPSEMissing.sh ${BAT_DIR}/${outtime}.${run}.GenoExPSEsnp ${nSUS} 
fi
echo " "
echo "Outfile ${BAT_DIR}/${outtime}.${run}.GenoExPSEsnp was written:"
head ${BAT_DIR}/${outtime}.${run}.GenoExPSEsnp
echo " "
echo "Anzahl records"
wc -l ${BAT_DIR}/${outtime}.${run}.GenoExPSEsnp
echo " "
echo " "
echo "the worst 10 ones in Callrate:"
sort -T ${SRT_DIR} -T ${SRT_DIR} -t';' -k5,5nr ${BAT_DIR}/${outtime}.${run}.GenoExPSEsnp | tail
echo " "
echo " "
echo "Calc SampleCallrates"
rm -f ${TMP_DIR}/${outtime}.${run}.GenoExPSEsnp.SAMPLEclrt
Rscript $BIN_DIR/calcSAMPLEcallratesGenoExPSE.R ${BAT_DIR}/${outtime}.${run}.GenoExPSEsnp ${HIS_DIR}/${outtime}.${run}.GenoExPSEsnp.SAMPLEclrt
echo " "
echo " "
nl=$(wc -l ${HIS_DIR}/${outtime}.${run}.GenoExPSEsnp.SAMPLEclrt | awk '{print $1}')
nb=$(awk -v isag=${ISAGCLRT} '{if(($4 / 100) < isag) print $0}' ${HIS_DIR}/${outtime}.${run}.GenoExPSEsnp.SAMPLEclrt | wc -l | awk '{print $1}')
#echo "hallo;${nl};${nb}"
if [ ${nb} -gt 0 ]; then
propB=$(echo $nl $nb | awk '{print $2/$1}')
#echo "${nl};${nb};${propB};${BADISAG}"
checkIsBigger=$(numCompare ${propB} ${BADISAG})
if [ ${checkIsBigger} -eq 1 ]; then
reporB=$(echo ${propB} | awk '{print $1*100}')
echo " "
echo "&&&&&&&&&&&&&&&&&&&"
echo "Attention: you have a proprotion of ${reporB} % of the samples in ${BAT_DIR}/${outtime}.${run}.GenoExPSEsnp having ISAG200callrate below ${ISAGCLRT}. Threshold for reporting was set at ${BADISAG}"
$BIN_DIR/sendAttentionMailAboutSampleCallrateGenoexpse.sh ${BAT_DIR}/${outtime}.${run}.GenoExPSEsnp ${reporB} ${ISAGCLRT} 
echo "&&&&&&&&&&&&&&&&&&&"
echo " "
fi
fi
echo "Calc SNPCallrates"
#select one labfile ISAG SNPfile since all are the same and identical
isagmap=$(ls -trl $TMP_DIR/*.outmap.isagsnplst | head -1 | awk '{print $9}')
rm -f ${TMP_DIR}/${outtime}.${run}.GenoExPSEsnp.SNPclrt
Rscript $BIN_DIR/calcSNPcallratesGenoExPSE.R ${BAT_DIR}/${outtime}.${run}.GenoExPSEsnp ${isagmap} ${HIS_DIR}/${outtime}.${run}.GenoExPSEsnp.SNPclrt
echo " "
echo " "
nb=$(awk -v isag=${ISAGCLRT} '{if(($2 / 100) < isag) print $0}' ${HIS_DIR}/${outtime}.${run}.GenoExPSEsnp.SNPclrt | wc -l | awk '{print $1}')
#echo $nb
if [ ${nb} -gt 0 ]; then
echo " "
echo "&&&&&&&&&&&&&&&&&&&"
echo "Attention: you have a subset of ${nb} SNPs with callrate below ${ISAGCLRT} in ${BAT_DIR}/${outtime}.${run}.GenoExPSEsnp "
$BIN_DIR/sendAttentionMailAboutSNPCallrateGenoexpse.sh ${BAT_DIR}/${outtime}.${run}.GenoExPSEsnp ${nb} ${ISAGCLRT} 
echo "&&&&&&&&&&&&&&&&&&&"
echo " "
fi

cd ${lokal}
echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
