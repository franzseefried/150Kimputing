#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT} 
echo " "


##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
if [ ${dbsystem} != "rapid" ]; then
   DEUTZ_DIR=/qualstororatest01/argus_${dbsystem}
fi

### # function for reporting on console
usage () {
  local l_MSG=$1
  echo "Usage Error: $l_MSG"
  echo "Usage: $SCRIPT -b <string>"
  echo "  where <string> specifies the breed with options bsw, hol or vms"
  echo "Usage: $SCRIPT -d <string>"
  echo "  where <string> specifies the Parameter for the Haplotype to be processed"
  echo "Usage: $SCRIPT -v <string>"
  echo "  where <string> specifies the Parameter if an Cross validation should be applied: YES or NO"
  exit 1
}

### check number of command line arguments
NUMARGS=$#
echo "Number of arguments: $NUMARGS"
if [ $NUMARGS -lt 0 ]  ; then
  usage 'No command line arguments specified'
fi

while getopts :b:d:v: FLAG; do
  case $FLAG in
    b) # set option "b"
      export breed=$(echo $OPTARG | awk '{print toupper($1)}')
      if [ ${breed} == "BSW" ] || [ ${breed} == "HOL" ] || [ ${breed} == "VMS" ]; then
          echo ${breed} > /dev/null
          if [ ${breed} == "BSW" ]; then
             natfolder=sbzv
          fi
          if [ ${breed} == "HOL" ]; then
             natfolder=swissherdbook
          fi
          if [ ${breed} == "vms" ]; then
             natfolder=mutterkuh
          fi
      else
          usage "Breed not correct, must be specified: bsw / hol / vms using option -b <string>"
          exit 1
      fi
      ;;
    d) # set option "s"
      export snp=$(echo $OPTARG)
      ;;

    v) # set option "s"
      export crossval=$(echo $OPTARG| awk '{print toupper($1)}')
      ;;

    *) # invalid command line arguments
      usage "Invalid command line argument $OPTARG"
      ;;
  esac
done

### # check that breed is not empty
if [ -z "${breed}" ]; then
      usage 'BREED not specified, must be specified using option -b <string>'   
fi
### # check that setofanomals is not empty
if [ -z "${snp}" ]; then
    usage 'Parameter for the polymophism must be specified using option -z <string>'      
fi
### # check that setofanomals is not empty
if [ -z "${crossval}" ]; then
    usage 'Parameter for the crossvalidation must be specified using option -v <string>'      
fi
set -o nounset
set -o errexit
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



if ! test -s $FIM_DIR/${breed}BTAwholeGenome.out/genotypes_imp.txt ;then
   echo "$FIM_DIR/${breed}BTAwholeGenome.out/genotypes_imp.txt does not exist or has size zero"
   exit 1
fi


if ! test -s $WRK_DIR/${breed}_Referenzgenotypes_${snp}.txt; then
   echo "$WRK_DIR/${breed}_Referenzgenotypes_${snp}.txt does not exist or has size zero"
   exit 1
fi

#Definition des Bereichs. Ausgehend von der Position in der referenzliste +/- 3 Mb
#get Info about SNP from Reftab
getColmnNr CodeResultfile ${REFTAB_SiTeAr} ; colCode=$colNr_
getColmnNr PredictionAlgorhithm ${REFTAB_SiTeAr} ; colPA=$colNr_
getColmnNr IMPbreedsWhereTestSegregates ${REFTAB_SiTeAr} ; colIMPBREED=$colNr_
getColmnNr CountedAllelIsBADone ${REFTAB_SiTeAr} ; colCAI=$colNr_
getColmnNr BTA ${REFTAB_SiTeAr} ; colBTA=$colNr_
getColmnNr MapBp ${REFTAB_SiTeAr} ; colBp=$colNr_
getColmnNr SVMAlgorithm ${REFTAB_SiTeAr} ; colKRN=$colNr_
algorithm=$(awk -v a=${colCode} -v b=${snp} -v c=${colIMPBREED} -v d=${breed} -v f=${colPA} '{FS=";"} {if ($a == b && $c ~ d)print $f}' ${REFTAB_SiTeAr})
coding=$(awk -v snps=${snp} -v a=${colCode} -v b=${colCAI} 'BEGIN{FS=";"}{if($a == snps) print $b}' ${REFTAB_SiTeAr})
BTA=$(awk -v snps=${snp} -v a=${colCode} -v b=${colBTA} 'BEGIN{FS=";"}{if($a == snps) print $b}' ${REFTAB_SiTeAr})
Bp=$(awk -v snp=${snp} -v a=${colCode} -v b=${colBp} 'BEGIN{FS=";"}{if($a == snp) print $b}' ${REFTAB_SiTeAr})
ikernel=$(awk -v snp=${snp} -v a=${colCode} -v b=${colKRN} 'BEGIN{FS=";"}{if($a == snp) print $b}' ${REFTAB_SiTeAr})

if [ -z ${BTA} ] || [ -z ${Bp} ] || [ -z ${ikernel} ];then
echo "entweder BTA oder Bp oder kernel sind leer. das darf nicht sein. check ${REFTAB_SiTeAr}"
exit 1
fi
re='^[0-9]+$'
if ! [[ $BTA =~ $re ]] ; then 
    echo "Code for Chromosome is not a number"
    exit 1
fi
re='^[0-9]+$'
if ! [[ $Bp =~ $re ]] ; then 
    echo "Code for Basepair is not a number"
    exit 1
fi
startpos=$(echo ${Bp} | awk '{if($1 < 3000000) print "0"; else print $1-3000000}')
stoppos=$(echo ${Bp} | awk '{print $1+3000000}')
MaxBTA=$(awk -v ss=${stoppos} -v chr=${BTA}  '{if(NR > 1 && $2 == chr ) print $3}'  $FIM_DIR/${breed}BTAwholeGenome.out/snp_info.txt | tail -1)
#echo $startpos $stoppos $MaxBTA
if [ ${MaxBTA} -lt ${stoppos} ];then
stoppos=${MaxBTA}
fi
#echo $startpos $stoppos $MaxBTA

#ausrechen der SNPs in dem Bereich
spos=$(awk -v ss=${startpos} -v chr=${BTA} '{if(NR > 1 && $2 == chr && $3 < ss) print $4}'  $FIM_DIR/${breed}BTAwholeGenome.out/snp_info.txt | tail -1)
epos=$(awk -v ss=${stoppos} -v chr=${BTA}  '{if(NR > 1 && $2 == chr && $3 >= ss) print $4}'  $FIM_DIR/${breed}BTAwholeGenome.out/snp_info.txt | head -1)
snpnamen=$(awk -v ss=${spos} -v ee=${epos} '{if(NR > 1 && $4 >= ss && $4 <= ee) print $1}'  $FIM_DIR/${breed}BTAwholeGenome.out/snp_info.txt | tr '\n' ' ' )

#identifikation der neuen Tiere ueber Tierlisten aus der genomweiten Imputation .> pedigreeprobleme sind schon weg && zusaetzlich ausschluss von pedigree imputierten Tieren
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));CD[$1]=$2;}} \
    else {sub("\015$","",$(NF));sD=CD[$1]; \
    if   (sD == "") {print $1" "$2}}}' $HIS_DIR/${breed}.RUN${oldrun}.IMPresult.tierlis $HIS_DIR/${breed}.RUN${run}.IMPresult.tierlis > $TMP_DIR/${breed}.NewFor.${snp}.srt


echo "${snp} ; ${breed} ; ${ikernel}"




#Blutanteile zur Sicherheit dass nur BSW Tiere gecallt werden
awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | sed 's/ /#/g' | sed 's/\;\;/\;NA\;/g' | tr ';' ' ' | cut -d' ' -f2,3,4,7,9,11 |\
sort -T ${SRT_DIR} -t' ' -k1,1 |\
join -t' ' -o'1.1 1.2 1.3 1.4 1.5 1.6 2.3 2.4 2.5' -1 1 -2 2 - <(sed 's/\;/ /g' $TMP_DIR/${breed}.Blutanteile.mod | sort -T ${SRT_DIR} -t' ' -k2,2) |\
sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/geno.info.${snp}${breed}.srt


sed 's/ //g' $WORK_DIR/animal.overall.info | sed 's/\;\;/\;NA\;/g' | cut -d';' -f2-5,9,11 | tr ';' ' ' > $TMP_DIR/gt.${snp}.${breed}.tmp


#zusammenpasten der beiden Chromosomen und eliminieren von Tieren die nicht zu 100% gecallt sind
nSNP=$(awk '{if(NR == 1) print (NF-3)*2}' $TMP_DIR/${breed}${BTA}Fgt${snp}.haplotypesInRows)
grep -v "\- " $TMP_DIR/${breed}${BTA}Fgt${snp}.haplotypesInRows | grep -v "\-$"  > $TMP_DIR/${breed}${snp}.haplotypesInRows



Rscript $BIN_DIR/SVMbasedGenotypePrediction.R ${breed} ${snp} ${ikernel} $TMP_DIR/${breed}${snp}.haplotypesInRows $TMP_DIR/${breed}${snp}.SVM.predictedGenotypes.txt



echo " "
if [ ${crossval} == "YES" ] ;then
echo "Run cross validation now"
rm -f $TMP_DIR/LeaveOneOut_${breed}${snp}*
Rscript $BIN_DIR/SVMbasedGenotypePredictionCV.R  ${breed} ${snp} ${ikernel} $TMP_DIR/${breed}${snp}.haplotypesInRows $TMP_DIR
echo " "
for kerneltype in linear radial sigmoid polynomial; do
echo "evaluate cros validation ${kerneltype} kernel"
echo "n SVMpredictedGenotype TrueGenotype flag"
awk '{if($3 == 1) print}' $TMP_DIR/LeaveOneOut_${breed}${snp}${kerneltype}.txt | sort -T ${SRT_DIR} | uniq -c
echo " "
echo " "
done
fi

#schreiben der finalen Ergebnisisten. Achtung pedigreeimputierte Tiere sind nicht in animal.overall.info und gehen darum verloren + einschraenkung auf Butanteile
sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}${snp}.SVM.predictedGenotypes.txt |\
   join -t' ' -o'2.5 1.2 1.1' -1 1 -2 1 -  <(sort -T ${SRT_DIR} -t' ' -k1,1 $WORK_DIR/ped_umcodierung.txt.${breed}) |\
   sort -T ${SRT_DIR} -t' ' -k1,1 |\
   join -t' ' -o'1.1 1.2 1.3 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9' -1 1 -2 1 -  $TMP_DIR/geno.info.${snp}${breed}.srt |\
   awk '{if(($9+$10+$11) > 0.875) print $1,$2,$3,$4,$5,$6,$7,$8,$9}' | sort -T ${SRT_DIR} -t' ' -k1,1 |\
   join -t' ' -o'1.1 1.2 1.3 1.4 1.6 1.8 1.9 2.2' -a1 -e'-' -1 1 -2 1 - <(sort -T ${SRT_DIR} -t' ' -k1,1 ${HIS_DIR}/${breed}.RUN${run}.IMPresult.tierlis) |\
   sort -T ${SRT_DIR} -t' ' -k1,1 |\
   join -t' ' -o'1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 2.4' -1 1 -2 1 - <(sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/gt.${snp}.${breed}.tmp) > $RES_DIR/RUN${run}${breed}.${snp}.Fimpute.${algorithm}

#dazuholen der Referenztiere mit bekanntem wahrem Genotyp:
sort -T ${SRT_DIR} -t' ' -k1,1 $WRK_DIR/${breed}_Referenzgenotypes_${snp}.txt |\
   join -t' ' -o'1.1 1.2 2.1' -1 1 -2 5 -  <(sort -T ${SRT_DIR} -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed}) |\
   sort -T ${SRT_DIR} -t' ' -k1,1 |\
   join -t' ' -o'1.1 1.2 1.3 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9' -1 1 -2 1 -  $TMP_DIR/geno.info.${snp}${breed}.srt |\
   awk '{if(($9+$10+$11) > 0.875) print $1,$2,$3,$4,$5,$6,$7,$8,$9}' | sort -T ${SRT_DIR} -t' ' -k1,1 |\
   join -t' ' -o'1.1 1.2 1.3 1.4 1.6 1.8 1.9 2.2' -a1 -e'-' -1 1 -2 1 - <(sort -T ${SRT_DIR} -t' ' -k1,1 ${HIS_DIR}/${breed}.RUN${run}.IMPresult.tierlis) |\
   sort -T ${SRT_DIR} -t' ' -k1,1 |\
   join -t' ' -o'1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 2.4' -1 1 -2 1 - <(sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/gt.${snp}.${breed}.tmp) >> $RES_DIR/RUN${run}${breed}.${snp}.Fimpute.${algorithm}
sort -T ${SRT_DIR} -t' ' -k1,1 $RES_DIR/RUN${run}${breed}.${snp}.Fimpute.${algorithm} -o $RES_DIR/RUN${run}${breed}.${snp}.Fimpute.${algorithm}



if [ ${coding} == "N" ]; then
echo "0 2" >  $TMP_DIR/${breed}.${snp}.umkodierung
echo "1 1" >> $TMP_DIR/${breed}.${snp}.umkodierung
echo "2 0" >> $TMP_DIR/${breed}.${snp}.umkodierung
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));CD[$1]=$2;DD[$1]=$2;}} \
    else {sub("\015$","",$(NF));sD=CD[$2]; \
    if   (sD != "") {print $1" "sD" "$3,$4,$5,$6,$7,$8,$9}}}' $TMP_DIR/${breed}.${snp}.umkodierung $RES_DIR/RUN${run}${breed}.${snp}.Fimpute.${algorithm} > $TMP_DIR/RUN${run}${breed}.${snp}.Fimpute.${algorithm}         
mv $TMP_DIR/RUN${run}${breed}.${snp}.Fimpute.${algorithm}  $RES_DIR/RUN${run}${breed}.${snp}.Fimpute.${algorithm}
rm -f $TMP_DIR/${breed}.${snp}.umkodierung
fi


echo " "
$BIN_DIR/compareGTpredictionWithLastRun.sh -b $RES_DIR/RUN${oldrun}${breed}.${snp}.Fimpute.${algorithm} -c $RES_DIR/RUN${run}${breed}.${snp}.Fimpute.${algorithm}
echo " "



#Hole Info aus Reftab fuer Argus Codierung; Ziel "TVD;AuspraegungARGUS"
heute=$(date '+%Y%m%d')
getColmnNr PredictionAlgorhithm ${REFTAB_SiTeAr} ; colPA=$colNr_
getColmnNr CodeResultfile ${REFTAB_SiTeAr} ; colCode=$colNr_
getColmnNr MarkerID ${REFTAB_SiTeAr} ; colMARKER=$colNr_
getColmnNr Kennung ${REFTAB_SiTeAr} ; colKenn=$colNr_
getColmnNr Testtyp ${REFTAB_SiTeAr} ; colType=$colNr_
getColmnNr IMPbreedsWhereTestSegregates ${REFTAB_SiTeAr} ; colIMPBREED=$colNr_
#echo "${colCode} ; ${snp} ; ${colIMPBREED} ; ${breed}"
idd=$(awk -v a=${colCode} -v b=${snp} -v c=${colIMPBREED} -v d=${breed} -v f=${colMARKER} '{FS=";"} {if ($a == b && $c ~ d)print $f}' ${REFTAB_SiTeAr})
bezarg=$(awk -v a=${colCode} -v b=${snp} -v c=${colIMPBREED} -v d=${breed} -v e=${colKenn} '{FS=";"} {if ($a == b && $c ~ d)print $e}' ${REFTAB_SiTeAr})
#beztyp=$(awk -v a=${colCode} -v b=${snp} -v c=${colIMPBREED} -v d=${breed} -v e=${colType} '{FS=";"} {if ($a == b && $c ~ d)print $e}' ${REFTAB_SiTeAr})
if test -s ${SNP_DIR}/einzelgen/argus/glossar/${snp}${algorithm}Interpretation.txt ;then
HaLabel=$(cat ${SNP_DIR}/einzelgen/argus/glossar/${snp}${algorithm}Interpretation.txt)
else
HaLabel=$(echo ${snp})
fi


awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));CD[$1]=$2;}} \
    else {sub("\015$","",$(NF));sD=CD[$1]; \
    if   (sD != "") {print $1" "sD}}}' $RES_DIR/RUN${run}${breed}.${snp}.Fimpute.${algorithm} $TMP_DIR/${breed}.NewFor.${snp}.srt |\
    awk -v label=${HaLabel} '{if($2 == 0) print $1";"label"F"; else if ($2 == 1) print $1";"label"C"; else if ($2 == 2) print $1";"label"S"; else print $1";OOOPS"}' > ${SNP_DIR}/einzelgen/argus/import/${breed}/${idd}.${bezarg}.${heute}.CH.Haplotypen.ImportGenmarker.dat



###############
#spezialfall CDHcat 
if [ ${breed} == "HOL" ] && [ ${idd} == 179 ]; then
echo "code CDH depending on pedigree"
$BIN_DIR/codeCDHresultsUsingPedigree.sh  2>&1
else
if [ ${idd} != "XXX" ]; then
cp ${SNP_DIR}/einzelgen/argus/import/${breed}/${idd}.${bezarg}.${heute}.CH.Haplotypen.ImportGenmarker.dat ${DEUTZ_DIR}/${natfolder}/dsch/in/${run}/.
echo " "
if [ ${breed} == "HOL" ]; then
echo "ftp upload for SHZV"
$BIN_DIR/ftpUploadOf1File.sh -f ${idd}.${bezarg}.${heute}.CH.Haplotypen.ImportGenmarker.dat -o ${SNP_DIR}/einzelgen/argus/import/${breed} -z Einzelgen
fi
fi
fi





#print to screen samples homozygous
nhomos=$(awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));CD[$1]=$2;DD[$1]=$8;}} \
    else {sub("\015$","",$(NF));sD=CD[$1];tD=DD[$1]; \
    if   (sD != "") {print $1" "sD" "tD}}}' $RES_DIR/RUN${run}${breed}.${snp}.Fimpute.${algorithm} $TMP_DIR/${breed}.NewFor.${snp}.srt | awk '{if($2 == 2) print}' | wc -l | awk '{print $1}' )
if [ ${nhomos} -gt 0 ]; then
echo "Attention following lines reply homozygous samples amoung new HD samples:"
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));CD[$1]=$2;DD[$1]=$8;}} \
    else {sub("\015$","",$(NF));sD=CD[$1];tD=DD[$1]; \
    if   (sD != "") {print $1" "sD" "tD}}}' $RES_DIR/RUN${run}${breed}.${snp}.Fimpute.${algorithm} $TMP_DIR/${breed}.NewFor.${snp}.srt | awk '{if($2 == 2) print}' | sort -t' ' -k3,3n
echo " "
echo "check if these are of interest"
echo " "
fi

rm -f $TMP_DIR/${breed}${snp}.haplotypesInRows
rm -f $TMP_DIR/${breed}.NewFor.${snp}.srt
rm -f $TMP_DIR/gt.${snp}.${breed}.tmp
rm -f $TMP_DIR/geno.info.${snp}${breed}.srt


echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT} 

