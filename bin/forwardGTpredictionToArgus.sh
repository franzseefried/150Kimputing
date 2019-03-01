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




#Hole Info aus Reftab fuer Argus Codierung; Ziel "TVD;AuspraegungARGUS"
heute=$(date '+%Y%m%d')
getColmnNr PredictionAlgorhithm ${REFTAB_SiTeAr} ; colPA=$colNr_
getColmnNr CodeResultfile ${REFTAB_SiTeAr} ; colCode=$colNr_
getColmnNr MarkerID ${REFTAB_SiTeAr} ; colMARKER=$colNr_
getColmnNr Kennung ${REFTAB_SiTeAr} ; colKenn=$colNr_
getColmnNr Testtyp ${REFTAB_SiTeAr} ; colType=$colNr_
getColmnNr IMPbreedsWhereTestSegregates ${REFTAB_SiTeAr} ; colIMPBREED=$colNr_
getColmnNr FwdGTpredictionToARGUS ${REFTAB_SiTeAr} ; colFORWARDARGUS=$colNr_

idd=$(awk -v a=${colCode} -v b=${snp} -v c=${colIMPBREED} -v d=${breed} -v f=${colMARKER} '{FS=";"} {if ($a == b && $c ~ d)print $f}' ${REFTAB_SiTeAr})
forwardToArgus=$(awk -v a=${colCode} -v b=${snp} -v c=${colIMPBREED} -v d=${breed} -v f=${colFORWARDARGUS} '{FS=";"} {if ($a == b && $c ~ d)print $f}' ${REFTAB_SiTeAr})
bezarg=$(awk -v a=${colCode} -v b=${snp} -v c=${colIMPBREED} -v d=${breed} -v e=${colKenn} '{FS=";"} {if ($a == b && $c ~ d)print $e}' ${REFTAB_SiTeAr})
algorithm=$(awk -v a=${colCode} -v b=${snp} -v c=${colIMPBREED} -v d=${breed} -v f=${colPA} '{FS=";"} {if ($a == b && $c ~ d)print $f}' ${REFTAB_SiTeAr})

#beztyp=$(awk -v a=${colCode} -v b=${snp} -v c=${colIMPBREED} -v d=${breed} -v e=${colType} '{FS=";"} {if ($a == b && $c ~ d)print $e}' ${REFTAB_SiTeAr})


#identifikation der neuen Tiere ueber Tierlisten aus der genomweiten Imputation .> pedigreeprobleme sind schon weg && zusaetzlich ausschluss von pedigree imputierten Tieren
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));CD[$1]=$2;}} \
    else {sub("\015$","",$(NF));sD=CD[$1]; \
    if   (sD == "") {print $1" "$2}}}' $HIS_DIR/${breed}.RUN${oldrun}.IMPresult.tierlis $HIS_DIR/${breed}.RUN${run}.IMPresult.tierlis > $TMP_DIR/${breed}.NewFor.${snp}.srt


echo "${snp} ; ${breed} ; ${algorithm} ; ${idd} ; ${forwardToArgus}"



#umkodierung zu argus. relevant fuer alle wo dier ergebnisse bis zum zeuchter gehen
#zum herausfinden sql: SELECT VG.VARGENNOM, VG.VARGENABREVIATION, TRV.VCOD_AUSPRAEGUNG ,VG.idvariant FROM TR_VARIANTGENETIQUE TRV  JOIN VARIANTGENETIQUE VG ON TRV.VCOD_VARIANT_ID = VG.IDVARIANT hier auf die auspraegungen schauen
#diese muessen uerbersetzt werden in ${SNP_DIR}/einzelgen/argus/glossar/${snp}.${algorithm}.Interpretation.txt
#wenn kein ${SNP_DIR}/einzelgen/argus/glossar/${snp}.${algorithm}.Interpretation.txt existiert wird der GTshortcut genommen 
if [ ${forwardToArgus} == "Y"  ] && [ ! -s ${SNP_DIR}/einzelgen/argus/glossar/${snp}.${algorithm}.Interpretation.txt ]; then echo "ERROR: GTprediction should be forwarded to ARGUS but no Reference Table ${SNP_DIR}/einzelgen/argus/glossar/${snp}.${algorithm}.Interpretation.txt exists";echo " "; exit 1; fi
if test -s ${SNP_DIR}/einzelgen/argus/glossar/${snp}.${algorithm}.Interpretation.txt ;then
   awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));CD[$1]=$2;}} \
    else {sub("\015$","",$(NF));sD=CD[$1]; \
    if   (sD != "") {print $1" "sD}}}' $RES_DIR/RUN${run}${breed}.${snp}.Fimpute.${algorithm} $TMP_DIR/${breed}.NewFor.${snp}.srt > ${TMP_DIR}/${breed}.${idd}.${bezarg}.${heute}.CH.Haplotypen.ImportGenmarker.dat
   awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));CD[$1]=$2;}} \
    else {sub("\015$","",$(NF));sD=CD[$2]; \
    if   (sD != "") {print $1";"sD}}}' ${SNP_DIR}/einzelgen/argus/glossar/${snp}.${algorithm}.Interpretation.txt ${TMP_DIR}/${breed}.${idd}.${bezarg}.${heute}.CH.Haplotypen.ImportGenmarker.dat > ${SNP_DIR}/einzelgen/argus/import/${breed}/${idd}.${bezarg}.${heute}.CH.Haplotypen.ImportGenmarker.dat
    rm -f ${TMP_DIR}/${breed}.${idd}.${bezarg}.${heute}.CH.Haplotypen.ImportGenmarker.dat${TMP_DIR}/${breed}.${idd}.${bezarg}.${heute}.CH.Haplotypen.ImportGenmarker.dat
    echo " ";
    echo "Wir haben folgende Verteilung der ${snp} Genotypen im ARGUS Importfile ${SNP_DIR}/einzelgen/argus/import/${breed}/${idd}.${bezarg}.${heute}.CH.Haplotypen.ImportGenmarker.dat:"
    cut -d';' -f2 ${SNP_DIR}/einzelgen/argus/import/${breed}/${idd}.${bezarg}.${heute}.CH.Haplotypen.ImportGenmarker.dat | sort -T ${SRT_DIR} | uniq -c
else
   HaLabel=$(echo ${snp})
   awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));CD[$1]=$2;}} \
    else {sub("\015$","",$(NF));sD=CD[$1]; \
    if   (sD != "") {print $1" "sD}}}' $RES_DIR/RUN${run}${breed}.${snp}.Fimpute.${algorithm} $TMP_DIR/${breed}.NewFor.${snp}.srt |\
    awk -v label=${HaLabel} '{if($2 == 0) print $1";"label"F"; else if ($2 == 1) print $1";"label"C"; else if ($2 == 2) print $1";"label"S"; else print $1";OOOPS"}' > ${SNP_DIR}/einzelgen/argus/import/${breed}/${idd}.${bezarg}.${heute}.CH.Haplotypen.ImportGenmarker.dat
fi





###############
#spezialfall CDH
if [ ${breed} == "HOL" ] && [ ${idd} == 179 ]; then
   echo "code CDH depending on pedigree"
   $BIN_DIR/codeCDHresultsUsingPedigree.sh  2>&1
else
   if [ ${forwardToArgus} == "Y"  ]; then
     echo "   ARGUS Copy : ${snp} ; ${breed} ; ${algorithm} ; ${idd} ; ${forwardToArgus}"
     cp ${SNP_DIR}/einzelgen/argus/import/${breed}/${idd}.${bezarg}.${heute}.CH.Haplotypen.ImportGenmarker.dat ${DEUTZ_DIR}/${natfolder}/dsch/in/${run}/.
     ls -trl ${DEUTZ_DIR}/${natfolder}/dsch/in/${run}/${idd}.${bezarg}.${heute}.CH.Haplotypen.ImportGenmarker.dat 
     echo " "
     if [ ${breed} == "HOL" ]; then
        echo "ftp upload for SHZV"
        $BIN_DIR/ftpUploadOf1File.sh -f ${idd}.${bezarg}.${heute}.CH.Haplotypen.ImportGenmarker.dat -o ${SNP_DIR}/einzelgen/argus/import/${breed} -z Einzelgen
     fi
   else
     echo " "
     echo "No ARGUS Copy : ${snp} ; ${breed} ; ${algorithm} ; ${idd} ; ${forwardToArgus}"
     echo " "
   fi
fi





#print to screen new homozygous samples
nhomos=$(awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));CD[$1]=$2;DD[$1]=$8;}} \
    else {sub("\015$","",$(NF));sD=CD[$1];tD=DD[$1]; \
    if   (sD != "") {print $1" "sD" "tD}}}' $RES_DIR/RUN${run}${breed}.${snp}.Fimpute.${algorithm} $TMP_DIR/${breed}.NewFor.${snp}.srt | awk '{if($2 == 2) print}' | wc -l | awk '{print $1}' )
if [ ${nhomos} -gt 0 ]; then
    echo "Attention following lines reply homozygous samples amoung new samples:"
    echo "TVD GT Density";
    awk 'BEGIN{FS=" ";OFS=" "}{ \
       if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));CD[$1]=$2;DD[$1]=$8;}} \
       else {sub("\015$","",$(NF));sD=CD[$1];tD=DD[$1]; \
       if   (sD != "") {print $1" "sD" "tD}}}' $RES_DIR/RUN${run}${breed}.${snp}.Fimpute.${algorithm} $TMP_DIR/${breed}.NewFor.${snp}.srt | awk '{if($2 == 2) print}' | sort -t' ' -k3,3n
    echo " "
fi

rm -f $TMP_DIR/${breed}.NewFor.${snp}.srt


echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT} 

