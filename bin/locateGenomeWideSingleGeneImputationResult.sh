#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "
##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################


### # function for reporting on console
usage () {
  local l_MSG=$1
  echo "Usage Error: $l_MSG"
  echo "Usage: $SCRIPT -s <string>"
  echo "  where <string> specifies the name of the SNP"
  echo "Usage: $SCRIPT -b <string>"
  echo "  where <string> specifies the breed"
  exit 1
}

### check number of command line arguments
NUMARGS=$#
echo "Number of arguments: $NUMARGS"
if [ $NUMARGS -lt 0 ]  ; then
  usage 'No command line arguments specified'
fi

while getopts :s:b: FLAG; do
  case $FLAG in
    s) # set option "s"
      export snp=$(echo $OPTARG )
      ;;
    b) # set option "b"
      export breed=$(echo $OPTARG )
      if [ ${breed} == "BSW" ]; then
             natfolder=sbzv
      fi
      if [ ${breed} == "HOL" ]; then
             natfolder=swissherdbook
      fi
      if [ ${breed} == "vms" ]; then
             natfolder=mutterkuh
      fi
      ;;
    *) # invalid command line arguments
      usage "Invalid command line argument $OPTARG"
      ;;
  esac
done

if [ -z "${snp}" ]; then
      usage 'SNP not specified, must be specified using option -s <string>'   
fi
if [ -z "${breed}" ]; then
      usage 'Breed not specified, must be specified using option -b <string>'   
fi
set -o nounset
set -o errexit

OS=$(uname -s)
if [ $OS != "Linux" ]; then
echo "oooops :-( ....Change to a Linux-Server. You are not on a Linux Server, but this is required"
$BIN_DIR/sendErrorMail.sh $PROG_DIR/${SCRIPT} ${1}
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

getColmnNr CodeResultfile ${REFTAB_SiTeAr} ; colCode=$colNr_
getColmnNr PredictionAlgorhithm ${REFTAB_SiTeAr} ; colPA=$colNr_
getColmnNr IMPbreedsWhereTestSegregates ${REFTAB_SiTeAr} ; colIMPBREED=$colNr_
getColmnNr CountedAllelIsBADone ${REFTAB_SiTeAr} ; colCAI=$colNr_
getColmnNr BTA ${REFTAB_SiTeAr} ; colBTA=$colNr_
getColmnNr MapBp ${REFTAB_SiTeAr} ; colKOO=$colNr_
algorithm=$(awk -v a=${colCode} -v b=${snp} -v c=${colIMPBREED} -v d=${breed} -v f=${colPA} '{FS=";"} {if ($a == b && $c ~ d)print $f}' ${REFTAB_SiTeAr})
coding=$(awk -v snps=${snp} -v a=${colCode} -v b=${colCAI} 'BEGIN{FS=";"}{if($a == snps) print $b}' ${REFTAB_SiTeAr})
BTA=$(awk -v snps=${snp} -v a=${colCode} -v b=${colBTA} 'BEGIN{FS=";"}{if($a == snps) print $b}' ${REFTAB_SiTeAr})
Bp=$(awk -v snps=${snp} -v a=${colCode} -v b=${colKOO} 'BEGIN{FS=";"}{if($a == snps) print $b}' ${REFTAB_SiTeAr})
re='^[0-9]+$'
if ! [[ $BTA =~ $re ]] ; then 
    echo "Code for Chromosome is not a number"
    $BIN_DIR/sendErrorMailWOarg2.sh ${SCRIPT}
    exit 1
fi
re='^[0-9]+$'
if ! [[ $Bp =~ $re ]] ; then 
    echo "Code for Basepair is not a number"
    $BIN_DIR/sendErrorMailWOarg2.sh ${SCRIPT}
    exit 1
fi

echo "$coding ; $algorithm ; $snp ; $BTA ; $Bp"




#identifikation der neuen Tiere ueber Tierlisten aus der genomweiten Imputation .> pedigreeprobleme sind schon weg && zusaetzlich ausschluss von pedigree imputierten Tieren
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));CD[$1]=$2;}} \
    else {sub("\015$","",$(NF));sD=CD[$1]; \
    if   (sD == "") {print $1" "$2}}}' $HIS_DIR/${breed}.RUN${oldrun}.IMPresult.tierlis $HIS_DIR/${breed}.RUN${run}.IMPresult.tierlis > $TMP_DIR/${breed}.NewFor.${snp}.srt




#nur mit BTA und chromosom, da der SNP in der genomweiten map anderst heisst als in der prediction und hier der aufruf via prediction code laeuft
PosOfSNPtoImputationResult=$(awk -v m=${snp} -v n=${BTA} -v o=${Bp} '{if($2 == n && $3 == o) print $4}' $FIM_DIR/${breed}BTAwholeGenome_FImpute.snpinfo )

if [ -z ${PosOfSNPtoImputationResult} ];then
echo "$snp in genomewide Systen not found: check BTA an basepairs"
exit 1 
fi
echo ${PosOfSNPtoImputationResult}
echo " "

join -t' ' -o'2.5 1.3 2.1 1.2' -1 1 -2 1 <(awk -v PosLoc=${PosOfSNPtoImputationResult} '{print $1,$2,substr($3,PosLoc,1)}' $FIM_DIR/${breed}BTAwholeGenome.out/genotypes_imp.txt | sort -T ${SRT_DIR} -t' ' -k1,1) <(sort -T ${SRT_DIR} -t' ' -k1,1 $WORK_DIR/ped_umcodierung.txt.${breed} ) |\
sort -T ${SRT_DIR} -t' ' -k1,1 |\
join -t' ' -o'1.1 1.2 1.3 2.2 2.3 2.4 1.4' -1 1 -2 1 - <(awk 'BEGIN{FS=";"}{print $2,$3,$7,$11}' $WORK_DIR/animal.overall.info | sort -T ${SRT_DIR} -t' ' -k1,1) |\
sort -T ${SRT_DIR} -t' ' -k1,1 |\
join -t' ' -o'1.1 1.2 1.3 1.4 1.5 1.6 2.5 1.7' -1 1 -2 2 - <(sed 's/\;/ /g' $TMP_DIR/${breed}.Blutanteile.mod | sort -T ${SRT_DIR} -t' ' -k2,2) |\
sort -T ${SRT_DIR} -t' ' -k1,1 |\
join -t' ' -o'1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 2.2' -1 1 -2 1	 - <(awk 'BEGIN{FS=";"}{print $2,$5}' $WORK_DIR/animal.overall.info | sort -T ${SRT_DIR} -t' ' -k1,1) |\
sort -T ${SRT_DIR} -t' ' -k1,1  > $RES_DIR/RUN${run}${breed}.${snp}.Fimpute.${algorithm}  

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
#$BIN_DIR/compareGTpredictionWithLastRun.sh -b $RES_DIR/RUN${oldrun}${breed}.${snp}.Fimpute.${algorithm} -c $RES_DIR/RUN${run}${breed}.${snp}.Fimpute.${algorithm}
echo " "


#Hole Info aus Reftab fuer Argus Codierung; Ziel "TVD;AuspraegungARGUS"
heute=$(date '+%Y%m%d')
getColmnNr PredictionAlgorhithm ${REFTAB_SiTeAr} ; colPA=$colNr_
getColmnNr CodeResultfile ${REFTAB_SiTeAr} ; colCode=$colNr_
getColmnNr MarkerID ${REFTAB_SiTeAr} ; colMARKER=$colNr_
getColmnNr Kennung ${REFTAB_SiTeAr} ; colKenn=$colNr_
getColmnNr Testtyp ${REFTAB_SiTeAr} ; colType=$colNr_
getColmnNr IMPbreedsWhereTestSegregates ${REFTAB_SiTeAr} ; colIMPBREED=$colNr_
#echo "${colCode} ; ${defectcode} ; ${colIMPBREED} ; ${breed}"
idd=$(awk -v a=${colCode} -v b=${snp} -v c=${colIMPBREED} -v d=${breed} -v f=${colMARKER} '{FS=";"} {if ($a == b && $c ~ d)print $f}' ${REFTAB_SiTeAr})
bezarg=$(awk -v a=${colCode} -v b=${snp} -v c=${colIMPBREED} -v d=${breed} -v e=${colKenn} '{FS=";"} {if ($a == b && $c ~ d)print $e}' ${REFTAB_SiTeAr})
#beztyp=$(awk -v a=${colCode} -v b=${defectcode} -v c=${colIMPBREED} -v d=${breed} -v e=${colType} '{FS=";"} {if ($a == b && $c ~ d)print $e}' ${REFTAB_SiTeAr})
if test -s ${SNP_DIR}/einzelgen/argus/glossar/${snp}${algorithm}Interpretation.txt ;then
HaLabel=$(cat ${SNP_DIR}/einzelgen/argus/glossar/${snp}${algorithm}Interpretation.txt)
else
HaLabel=$(echo ${snp})
fi

#dummy maessig Haplotypen code im filenamen verwendet
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));CD[$1]=$2;}} \
    else {sub("\015$","",$(NF));sD=CD[$1]; \
    if   (sD != "") {print $1" "sD}}}' $RES_DIR/RUN${run}${breed}.${snp}.Fimpute.${algorithm} $TMP_DIR/${breed}.NewFor.${snp}.srt |\
    awk -v label=${HaLabel} '{if($2 == 0) print $1";"label"F"; else if ($2 == 1) print $1";"label"C"; else if ($2 == 2) print $1";"label"S"; else print $1";OOOPS"}' > ${SNP_DIR}/einzelgen/argus/import/${breed}/${idd}.${bezarg}.${heute}.CH.Haplotypen.ImportGenmarker.dat

echo "Wir haben folgende Verteilung der ${snp} Genotypen im Ergebnisfile ${SNP_DIR}/einzelgen/argus/import/${breed}/${idd}.${bezarg}.${heute}.CH.Haplotypen.ImportGenmarker.dat:"
cut -d';' -f2 ${SNP_DIR}/einzelgen/argus/import/${breed}/${idd}.${bezarg}.${heute}.CH.Haplotypen.ImportGenmarker.dat | sort -T ${SRT_DIR} | uniq -c

echo "copy to Folder der anderen Einzelgenergebnisse fuer ${natfolder}"

if [ ${breed} == "HOL" ] && [ ${idd} == 179 ]; then
echo "code CDH depending on pedigree"
$BIN_DIR/codeCDHresultsUsingPedigree.sh  2>&1
else
#bisher wird nix in ARGUS importiert daher auskommentiert
if [ ${idd} != "XXX" ]; then
echo 1 > /dev/null
#cp ${SNP_DIR}/einzelgen/argus/import/${breed}/${idd}.${bezarg}.${heute}.CH.Haplotypen.ImportGenmarker.dat ${DEUTZ_DIR}/${natfolder}/dsch/in/${run}/.
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
rm -f $TMP_DIR/${breed}.NewFor.${snp}.srt 




echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
