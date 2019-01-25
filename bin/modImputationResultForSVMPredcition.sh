#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT} 
echo " "


##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o errexit

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

while getopts :b:d: FLAG; do
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
algorithm=$(awk -v a=${colCode} -v b=${snp} -v c=${colIMPBREED} -v d=${breed} -v f=${colPA} '{FS=";"} {if ($a == b && $c ~ d)print $f}' ${REFTAB_SiTeAr})
coding=$(awk -v snps=${snp} -v a=${colCode} -v b=${colCAI} 'BEGIN{FS=";"}{if($a == snps) print $b}' ${REFTAB_SiTeAr})
BTA=$(awk -v snps=${snp} -v a=${colCode} -v b=${colBTA} 'BEGIN{FS=";"}{if($a == snps) print $b}' ${REFTAB_SiTeAr})
Bp=$(awk -v snp=${snp} -v a=${colCode} -v b=${colBp} 'BEGIN{FS=";"}{if($a == snp) print $b}' ${REFTAB_SiTeAr})
if [ -z ${BTA} ] || [ -z ${Bp} ];then
echo "entweder BTA iod Bp sind leer. das darf nicht sein. check ${REFTAB_SiTeAr}"
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

echo "$coding ; $algorithm ; $snp ; $BTA ; $Bp"
startpos=$(echo ${Bp} | awk '{if($1 < 3000000) print "0"; else print $1-3000000}')
stoppos=$(echo ${Bp} | awk '{print $1+3000000}')
MinBTA=$(awk -v ss=${stoppos} -v chr=${BTA}  '{if(NR > 1 && $2 == chr ) print $3}'  $FIM_DIR/${breed}BTAwholeGenome.out/snp_info.txt | head -1)
MaxBTA=$(awk -v ss=${stoppos} -v chr=${BTA}  '{if(NR > 1 && $2 == chr ) print $3}'  $FIM_DIR/${breed}BTAwholeGenome.out/snp_info.txt | tail -1)
echo "Region borders defined     ${snp} ${breed}      : $startpos ${Bp} $stoppos" 
echo "Min Max borders checked as ${snp} ${breed}      : $MinBTA ${Bp} $MaxBTA"
if [ ${startpos} -lt ${MinBTA} ];then
startpos=${MinBTA}
fi
if [ ${MaxBTA} -lt ${stoppos} ];then
stoppos=${MaxBTA}
fi
echo "Region borders defined after min max checking          : $startpos $stoppos" 

#ausrechen der SNPs in dem Bereich
spos=$(awk -v ss=${startpos} -v chr=${BTA} '{if(NR > 1 && $2 == chr && $3 <= ss) print $4}'  $FIM_DIR/${breed}BTAwholeGenome.out/snp_info.txt | tail -1)
epos=$(awk -v ss=${stoppos} -v chr=${BTA}  '{if(NR > 1 && $2 == chr && $3 >= ss) print $4}'  $FIM_DIR/${breed}BTAwholeGenome.out/snp_info.txt | head -1)
snpnamen=$(awk -v ss=${spos} -v ee=${epos} '{if(NR > 1 && $4 >= ss && $4 <= ee) print $1}'  $FIM_DIR/${breed}BTAwholeGenome.out/snp_info.txt | tr '\n' ' ' )
#echo "$spos ; $epos ; $snpnamen"

sed 's/ //g' $WORK_DIR/animal.overall.info | sed 's/\;\;/\;NA\;/g' | cut -d';' -f2-5,9,11 | tr ';' ' ' > $TMP_DIR/gt.${snp}.${breed}.tmp


#hole genotypen aus imputationsergebnis: gelesen wird immer das genomweite IMPergebnis, benoetigt wird der BTAcode dennoch wegen dem chromosom in der genomweiten map
awk '{if(NR > 1) print $1,$3}' $FIM_DIR/${breed}BTAwholeGenome.out/genotypes_imp.txt  > $TMP_DIR/${breed}${BTA}Fgt${snp}.first


#dazuholen der genotypen der Referenztiere
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));RYF[$5]=$1;}} \
    else {sub("\015$","",$(NF));STAT="0";BLUEEM=RYF[$1]; \
    if   (BLUEEM != "") {print $1,"T",BLUEEM,$2}}}' $WORK_DIR/ped_umcodierung.txt.${breed} $WRK_DIR/${breed}_Referenzgenotypes_${snp}.txt > $TMP_DIR/${breed}_Referenzgenotypes_${snp}.txt



awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));RYF[$3]=$4;}} \
    else {sub("\015$","",$(NF));STAT="0";BLUEEM=RYF[$1]; \
    if   (BLUEEM != "") {print $1,"T",BLUEEM,$2} \
    else                {print $1,"V","3",$2}}}' $TMP_DIR/${breed}_Referenzgenotypes_${snp}.txt $TMP_DIR/${breed}${BTA}Fgt${snp}.first > $TMP_DIR/${breed}${BTA}Fgt${snp}.scnd



#trennen in einzelne SNP + einfuegen des header. RYFcode als aliasBezeichnung fuer den referenzgenotyp damit das selbe R Script verwendet werden kann
header=$(echo "animal TrainValidStatus RYFcode ${snpnamen}") 
awk -v st=${spos} -v et=${epos} '{if(NR > 1) print substr($4,st,((et+1)-st))}' $TMP_DIR/${breed}${BTA}Fgt${snp}.scnd | sed 's/./& /g' | sed 's/[3-9]/\-/g' > $TMP_DIR/${breed}${BTA}Fgt${snp}.tmp
awk -v st=${spos} -v et=${epos} '{if(NR > 1) print $1,$2,$3}'                  $TMP_DIR/${breed}${BTA}Fgt${snp}.scnd                                       > $TMP_DIR/${breed}${BTA}Fgt${snp}.animals
(echo ${header};
paste -d' ' $TMP_DIR/${breed}${BTA}Fgt${snp}.animals $TMP_DIR/${breed}${BTA}Fgt${snp}.tmp) | sed "s/ $//g" > $TMP_DIR/${breed}${BTA}Fgt${snp}.haplotypesInRows



rm -f $TMP_DIR/gt.${snp}.${breed}.tmp
rm -f $TMP_DIR/${breed}${BTA}Fgt${snp}.first
rm -f $TMP_DIR/${breed}_Referenzgenotypes_${snp}.txt
rm -f $TMP_DIR/${breed}${BTA}Fgt${snp}.scnd
rm -f $TMP_DIR/${breed}${BTA}Fgt${snp}.tmp
rm -f $TMP_DIR/${breed}${BTA}Fgt${snp}.animals




echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT} 

