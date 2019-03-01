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
$BIN_DIR/compareGTpredictionWithLastRun.sh -b $RES_DIR/RUN${oldrun}${breed}.${snp}.Fimpute.${algorithm} -c $RES_DIR/RUN${run}${breed}.${snp}.Fimpute.${algorithm}
echo " "
$BIN_DIR/forwardGTpredictionToArgus.sh -b ${breed} -d ${snp}
echo " "




echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
