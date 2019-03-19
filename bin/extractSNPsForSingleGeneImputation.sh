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
START_DIR=$(pwd)


if [ -z $1 ]; then
    echo "brauche den Code welche Rasse verarbeitet werden soll, 'BSW' oder 'HOL' oder 'VMS'"
    exit 1
elif [ ${1} == "BSW" ] || [ ${1} == "HOL" ]  || [ ${1} == "VMS" ]; then

if [ ${1} == "BSW" ]; then
	zofol=$(echo "bvch")
fi
if [ ${1} == "HOL" ]; then
	zofol=$(echo "shb")
fi
if [ ${1} == "VMS" ]; then
        zofol=$(echo "vms")
fi
else 
  echo "unbekannter Systemcode BSW VMS oder HOL erlaubt"
  exit 1
fi


if [ -z $2 ]; then
   echo "brauche den Code für die Chipdichte HD oder LD"
   exit 1
elif [ $2 == "LD" ] || [ $2 == "HD" ]; then
   echo $2 > /dev/null
   dichte=${2}
else
   echo "Der Code fuer die Chipdichte muss LD oder HD sein, ist aber ${2}"
   exit 1
fi

set -o nounset

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
##########################

#get Info about SNP from Reftab
getColmnNrSemicl ExtractGenotypesFromChipData ${REFTAB_SiTeAr} ; colEXG=$colNr_
getColmnNrSemicl CodeResultfile ${REFTAB_SiTeAr} ; colCSGI=$colNr_
getColmnNrSemicl BezeichnungFinalReport ${REFTAB_SiTeAr} ; colGSB=$colNr_
getColmnNrSemicl AlleleBisCountedAlleleInSNParchive ${REFTAB_SiTeAr} ; colABAASGI=$colNr_
getColmnNrSemicl IMPbreedsWhereTestSegregates ${REFTAB_SiTeAr} ; colIMPBRD=$colNr_
#echo $colCSGI $colGSB

rm -f $TMP_DIR/*.singleGeneImputationPreparation.tmp

breed=${1}

#idUmcodierung idanimal zu PediID
awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | awk 'BEGIN{FS=";"}{print $1";"$2}' | sed 's/ //g' | tr ';' ' '  > $TMP_DIR/umcd.lst1

#scuche welche Tests aus dem Archiv geholt werden sollen
TestsToBeExtracted=$(awk -v a=${colEXG} -v b=${colGSB} -v c=${colIMPBRD} -v d=${breed} 'BEGIN{FS=";"}{if($a == "Y" && $c ~ d) print $b}' ${REFTAB_SiTeAr} )

echo "####################"
echo $TestsToBeExtracted
echo "####################"


#define chiploop
colDENSITY=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep ${IMPUTATIONFLAG} | awk '{print $1}')
colNAME=$(head -1 ${REFTAB_CHIPS} | tr ';' '\n' | cat -n | grep QuagCode | awk '{print $1}')


CHIPS=$(awk -v cc=${colDENSITY} -v dd=${colNAME} -v densit=${dichte} 'BEGIN{FS=";"}{if( $cc == densit ) print $dd }' ${REFTAB_CHIPS})
lgtC=$(echo ${CHIPS} | wc -w | awk '{print $1}')
if [ ${lgtC} -eq 0 ]; then
  echo "keie Chips angegeben in ${REFTAB_CHIPS} in Kolonne  ${IMPUTATIONFLAG} "
  exit 1
fi

cd $START_DIR

#extract some SNPs which are later used for single gene imputation take first chip-SNP as dummy so that each chip has at east one SNP to be selected
#SNPs fro selction are in $WRK_DIR/SingleSelectedSNPs.txt
for chip in ${CHIPS} ; do
  if test -s $TMP_DIR/${breed}.${chip}.bed; then
    echo " "
    echo "$chip specific snp selection test if the SNP is part of the assay"
    for sssnp in ${TestsToBeExtracted}; do
       ncheck=$(awk -v ss=${sssnp} '{if($2 == ss) print}' $WORK_DIR/${breed}.${chip}.map | wc -l | awk '{print $1}')
       echo $sssnp $ncheck
       if [ ${ncheck} == 1 ]; then
          echo ${sssnp} | awk '{print $1,"B"}' | tee $TMP_DIR/${breed}.${chip}.SingleSelectedSNPs.force.Bcount | awk '{print $1}' > $TMP_DIR/${breed}.${chip}.SingleSelectedSNPs.lst
          cat $TMP_DIR/${breed}.${chip}.SingleSelectedSNPs.lst
          $FRG_DIR/plink --bfile $TMP_DIR/${breed}.${chip} --missing-genotype '0' --extract $TMP_DIR/${breed}.${chip}.SingleSelectedSNPs.lst --cow --nonfounders --noweb --recodeA --reference-allele $TMP_DIR/${breed}.${chip}.SingleSelectedSNPs.force.Bcount --out $TMP_DIR/${breed}.${chip}.SingleSelectedSNPs
          
          #umkodieren id zu TVD fuer einzelgenimputing
          awk 'BEGIN{FS=" "}{ \
            if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));bp[$1]=$5}} \
            else {sub("\015$","",$(NF));bpS=bp[$2]; \
            if   (bpS != "" && $7 != "NA") {print bpS,$7}}}' ${WORK_DIR}/ped_umcodierung.txt.${breed} $TMP_DIR/${breed}.${chip}.SingleSelectedSNPs.raw > $TMP_DIR/${breed}.${sssnp}.${chip}.singleGeneImputationPreparation.lst 
          
         echo " "
       else
          echo " ${sssnp} / ${sssnp} is not part of the ${chip} assay"
       fi
       done
  else
    CHIPS=$(echo $CHIPS | awk  -v pihc=${chip} '{for(i = 1; i <= NF; i=i+1) if($i != pihc) print $i}');
  fi
done


#union datasets 
for chip in ${CHIPS} ; do
  if test -s $TMP_DIR/${breed}.${chip}.bed; then
    for sssnp in ${TestsToBeExtracted}; do
       isBdesiredAllele=$(awk -v a=${colGSB} -v b=${colABAASGI} -v name=${sssnp} 'BEGIN{FS=";"}{if($a == name) print $b}' ${REFTAB_SiTeAr})      
       if test -s $TMP_DIR/${breed}.${sssnp}.${chip}.singleGeneImputationPreparation.lst ; then
        #Umkodieren, je nach dem ob B Allel das desired allele ist
          if [ ${isBdesiredAllele} == "N" ]; then
             awk '{if($2 == 2) print $1,"0"; else if ($2 == 0) print $1,"2"; else print $0}' $TMP_DIR/${breed}.${sssnp}.${chip}.singleGeneImputationPreparation.lst >> $TMP_DIR/${breed}.${sssnp}.singleGeneImputationPreparation.tmp
          else
             awk '{print $0}' $TMP_DIR/${breed}.${sssnp}.${chip}.singleGeneImputationPreparation.lst >> $TMP_DIR/${breed}.${sssnp}.singleGeneImputationPreparation.tmp
          fi
       sort -T ${SRT_DIR} -u $TMP_DIR/${breed}.${sssnp}.singleGeneImputationPreparation.tmp -o $TMP_DIR/${breed}.${sssnp}.singleGeneImputationPreparation.tmp
       fi
       done
  else
    CHIPS=$(echo $CHIPS | awk  -v pihc=${chip} '{for(i = 1; i <= NF; i=i+1) if($i != pihc) print $i}');
  fi
done
         


#uniq und remove samples with suspicious genotype calls
for sssnp in ${TestsToBeExtracted}; do
       if test -s $TMP_DIR/${breed}.${sssnp}.singleGeneImputationPreparation.tmp; then
       awk '{print $1}' $TMP_DIR/${breed}.${sssnp}.singleGeneImputationPreparation.tmp | sort | uniq -c | awk '{if($1 != 1) print $2,$2}'  > $TMP_DIR/${breed}.${sssnp}.samples.suspekt
       awk 'BEGIN{FS=" "}{ \
            if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));bp[$1]=$2}} \
            else {sub("\015$","",$(NF));bpS=bp[$1]; \
            if   (bpS == "") {print $0}}}' $TMP_DIR/${breed}.${sssnp}.samples.suspekt $TMP_DIR/${breed}.${sssnp}.singleGeneImputationPreparation.tmp | sort -T ${SRT_DIR} -u >> $WRK_DIR/${breed}.${sssnp}.lst
       fi
for sssnp in ${TestsToBeExtracted}; do
      if test -s $WRK_DIR/${breed}.${sssnp}.lst; then
      sort $WRK_DIR/${breed}.${sssnp}.lst | uniq -c | awk '{if($1 == 1) print $2,$3}' > $TMP_DIR/${breed}.${sssnp}.lst
      mv $TMP_DIR/${breed}.${sssnp}.lst $WRK_DIR/${breed}.${sssnp}.lst
      fi
      done
done

cd $lokal

echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
