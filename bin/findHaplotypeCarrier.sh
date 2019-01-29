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
      export defectcode=$(echo $OPTARG)
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
if [ -z "${defectcode}" ]; then
    usage 'Parameter for the polymophism must be specified using option -z <string>'      
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


if ! test -s ${SNP_DIR}/data/mapFiles/${breed}_${defectcode}_associatedHapQUALITAS.lst ; then
   echo "${SNP_DIR}/data/mapFiles/${breed}_${defectcode}_associatedHapQUALITAS.lst does not exist or has size zero"
   exit 1
fi
if ! test -s $FIM_DIR/${breed}BTAwholeGenome.haplos/genotypes_imp.txt ;then
   echo "$FIM_DIR/${breed}BTAwholeGenome.haplos/genotypes_imp.txt does not exist or has size zero"
   exit 1
fi

getColmnNr CodeResultfile ${REFTAB_SiTeAr} ; colCode=$colNr_
getColmnNr PredictionAlgorhithm ${REFTAB_SiTeAr} ; colPA=$colNr_
getColmnNr IMPbreedsWhereTestSegregates ${REFTAB_SiTeAr} ; colIMPBREED=$colNr_
algorithm=$(awk -v a=${colCode} -v b=${defectcode} -v c=${colIMPBREED} -v d=${breed} -v f=${colPA} '{FS=";"} {if ($a == b && $c ~ d)print $f}' ${REFTAB_SiTeAr})

#Defintion der region auf Eben SNPnamen Start und Ende
SNPb=$(awk '{if(NR == 1) print $1}' ${SNP_DIR}/data/mapFiles/${breed}_${defectcode}_associatedHapQUALITAS.lst)
SNPe=$(awk '{print $1}' ${SNP_DIR}/data/mapFiles/${breed}_${defectcode}_associatedHapQUALITAS.lst| tail -1)
#ableiten der Position im GenotypenString
spos=$(awk -v s=${SNPb} '{if($1 == s) print $4}' $FIM_DIR/${breed}BTAwholeGenome.haplos/snp_info.txt)
epos=$(awk -v s=${SNPe} '{if($1 == s) print $4}' $FIM_DIR/${breed}BTAwholeGenome.haplos/snp_info.txt)
snpnamen=$(awk -v ss=${spos} -v ee=${epos} '{if(NR > 1 && $4 >= ss && $4 <= ee) print $1}'  $FIM_DIR/${breed}BTAwholeGenome.haplos/snp_info.txt | tr '\n' ' ' )
haplotypelength=$(echo $epos $spos | awk '{print $1-$2}')
echo " "
echo ${defectcode} ${breed} $spos $epos $haplotypelength
echo " "
getColmnNr CodeResultfile ${REFTAB_SiTeAr} ; colDEF=$colNr_
getColmnNr CountedAllelIsBADone ${REFTAB_SiTeAr} ; colCAI=$colNr_
coding=$(awk -v snps=${defectcode} -v a=${colDEF} -v b=${colCAI} 'BEGIN{FS=";"}{if($a == snps) print $b}' ${REFTAB_SiTeAr})
#ACHTUNG: in der Haplotypenmap muss der Zeilenumbruch in der letzen Zeile fehlen sonst stimmt das rechnen nicht mehr!!!!!!!!!!



sort -T ${SRT_DIR} -t' ' -k3,3n $MAP_DIR/${breed}_${defectcode}_associatedHapQUALITAS.lst | awk '{print $1}' > $TMP_DIR/${defectcode}.txt
#identifikation der neuen Tiere ueber Tierlisten aus der genomweiten Imputation .> pedigreeprobleme sind schon weg && zusaetzlich ausschluss von pedigree imputierten Tieren
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));CD[$1]=$2;}} \
    else {sub("\015$","",$(NF));sD=CD[$1]; \
    if   (sD == "") {print $1" "$2}}}' $HIS_DIR/${breed}.RUN${oldrun}.IMPresult.tierlis $HIS_DIR/${breed}.RUN${run}.IMPresult.tierlis > $TMP_DIR/${breed}.NewFor.${defectcode}.srt


awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | sed 's/ /#/g' | sed 's/\;\;/\;NA\;/g' | tr ';' ' ' | cut -d' ' -f2,3,4,7,9,11 |\
sort -T ${SRT_DIR} -t' ' -k1,1 |\
join -t' ' -o'1.1 1.2 1.3 1.4 1.5 1.6 2.3' -1 1 -2 2 - <(sed 's/\;/ /g' $TMP_DIR/${breed}.Blutanteile.mod | sort -T ${SRT_DIR} -t' ' -k2,2) |\
sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/geno.info.${defectcode}${breed}.srt


sed 's/ //g' $WORK_DIR/animal.overall.info | sed 's/\;\;/\;NA\;/g' | cut -d';' -f2-5,9,11 | tr ';' ' ' > $TMP_DIR/gt.${defectcode}.${breed}.tmp


#Logik: bei Bottom umkodieren zur kompl Base, dann habe ich Allel 1 und 2 in der Illuminareihenfolge als AllelA und AllelB, in der Imputation zählen wir B, d.h. B=2 ACHTUNG sortierung hier anders wie in den ursprünlg programmen
awk '{ sub("\r$", ""); print }' $MAP_DIR/${breed}_${defectcode}_associatedHapQUALITAS.lst | awk '{print $1,$4,NR}' | sort -T ${SRT_DIR} -t' ' -k3,3n >  $TMP_DIR/${defectcode}-haplo12-Codierung.txt


#to do file transposen damit logik behalten werden kann. Neu hier nur der Haplotypenbock Statt das ganze BTA
awk -v st=${spos} -v et=${epos}  '{if(NR > 1) print substr($3,st,((et+1)-st))}' $FIM_DIR/${breed}BTAwholeGenome.haplos/genotypes_imp.txt | sed 's/./& /g' > $TMP_DIR/${breed}Fgt${defectcode}.tmp
#erster transpose macht umstrukturerung von rows in colums und von 1 Zeile pro Tier zu 2 colums pro tier nur Genotypen, sed -f codiert von Fimpute Diplotypencalling in Allelcalling um
cp ${PAR_DIR}/Fimpute.standard.output.allelecoding.lst.sed ${TMP_DIR}/Fimpute.standard.output.allelecoding.lst.sed${defectcode}
$BIN_DIR/awk_transpose.job $TMP_DIR/${breed}Fgt${defectcode}.tmp | sed -f ${TMP_DIR}/Fimpute.standard.output.allelecoding.lst.sed${defectcode} > $TMP_DIR/${breed}Fgt${defectcode}.transposed
#zweiter transpose macht struktur von spaltenweise in zeilenweise zurück, jetzt aber 2 Zeilen pro tier im output
awk '{if(NR > 1) print $1,$1}' $FIM_DIR/${breed}BTAwholeGenome.haplos/genotypes_imp.txt | tr ' ' '\n' > $TMP_DIR/${breed}Fgt${defectcode}.animals
$BIN_DIR/awk_transpose.job $TMP_DIR/${breed}Fgt${defectcode}.transposed  > $TMP_DIR/${breed}Fgt${defectcode}.haplos.tmp
paste -d' ' $TMP_DIR/${breed}Fgt${defectcode}.animals $TMP_DIR/${breed}Fgt${defectcode}.haplos.tmp > $TMP_DIR/${breed}Fgt${defectcode}.haplotypesInRows

#schneiden der SNPs
#inkl umkodoerung auf Nomenklatur in ${defectcode} map 1/2
cat $TMP_DIR/${breed}Fgt${defectcode}.haplotypesInRows | sed 's/B/2/g' | sed 's/A/1/g' | sed 's/ /_/g'  |sed 's/_/ /1' > $TMP_DIR/${breed}SMLLFgt${defectcode}.haplotypesInRows



#ableiten haplotypenstatus sort -T ${SRT_DIR} uniq -c macht das zählen der allele: 2*0 = 0, 1*1 = 1, 2*1=2, + anschliessend nur die höchte Zahl pro Tier rausschreiben macht das Haplocalling
haplo=$(cut -d' ' -f2 $TMP_DIR/${defectcode}-haplo12-Codierung.txt | tr '\n' ' ' | sed 's/2$/\n/g' | sed 's/ /_/g' | sed 's/_$//g')
cut -d' ' -f2 $TMP_DIR/${defectcode}-haplo12-Codierung.txt | tr '\n' ' ' | sed 's/2$/\n/g' | sed 's/ /_/g' | sed 's/_$//g' > $TMP_DIR/haplo.to.fetch.${breed}${defectcode}
echo $typ $haplo
lastani=0
$BIN_DIR/awk_fetchHaplotypeAndSetHplstat $TMP_DIR/haplo.to.fetch.${breed}${defectcode} $TMP_DIR/${breed}SMLLFgt${defectcode}.haplotypesInRows |\
   sort -T ${SRT_DIR} -t' ' -k1,1 |\
   sort -T ${SRT_DIR} |\
   uniq -c |\
   awk '{print $2,$1*$3}' |\
   sort -T ${SRT_DIR} -t' ' -k1,1 -k2,2nr |\
   while IFS=" "; read a h; do
      if [ ${lastani} != ${a} ]; then
         echo $a $h
      fi
   lastani=${a}
   done | sort -T ${SRT_DIR} -t' ' -k1,1 |\
     join -t' ' -o'2.5 1.2 1.1' -1 1 -2 1 -  <(sort -T ${SRT_DIR} -t' ' -k1,1 $WORK_DIR/ped_umcodierung.txt.${breed}) |\
     sort -T ${SRT_DIR} -t' ' -k1,1 |\
     join -t' ' -o'1.1 1.2 1.3 2.2 2.3 2.4 2.5 2.6 2.7' -1 1 -2 1 -  $TMP_DIR/geno.info.${defectcode}${breed}.srt |\
     awk '{print $1,$2,$3,$4,$5,$6,$7,$8,$9}' | sort -T ${SRT_DIR} -t' ' -k1,1 |\
     join -t' ' -o'1.1 1.2 1.3 1.4 1.6 1.8 1.9 2.2' -a1 -e'-' -1 1 -2 1 - <(sort -T ${SRT_DIR} -t' ' -k1,1 ${HIS_DIR}/${breed}.RUN${run}.IMPresult.tierlis) |\
     sort -T ${SRT_DIR} -t' ' -k1,1 |\
     join -t' ' -o'1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 2.4' -1 1 -2 1 - <(sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/gt.${defectcode}.${breed}.tmp) > $RES_DIR/RUN${run}${breed}.${defectcode}.Fimpute.${algorithm}


if [ ${coding} == "N" ]; then
echo "0 2" >  $TMP_DIR/${breed}.${defectcode}.umkodierung
echo "1 1" >> $TMP_DIR/${breed}.${defectcode}.umkodierung
echo "2 0" >> $TMP_DIR/${breed}.${defectcode}.umkodierung
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));CD[$1]=$2;DD[$1]=$2;}} \
    else {sub("\015$","",$(NF));sD=CD[$2]; \
    if   (sD != "") {print $1" "sD" "$3,$4,$5,$6,$7,$8,$9}}}' $TMP_DIR/${breed}.${defectcode}.umkodierung $RES_DIR/RUN${run}${breed}.${defectcode}.Fimpute.${algorithm} > $TMP_DIR/RUN${run}${breed}.${defectcode}.Fimpute.${algorithm}         
mv $TMP_DIR/RUN${run}${breed}.${defectcode}.Fimpute.${algorithm}  $RES_DIR/RUN${run}${breed}.${defectcode}.Fimpute.${algorithm}
rm -f $TMP_DIR/${breed}.${defectcode}.umkodierung
fi


echo " "
#$BIN_DIR/compareGTpredictionWithLastRun.sh -b $RES_DIR/RUN${oldrun}${breed}.${defectcode}.Fimpute.${algorithm} -c $RES_DIR/RUN${run}${breed}.${defectcode}.Fimpute.${algorithm}
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
idd=$(awk -v a=${colCode} -v b=${defectcode} -v c=${colIMPBREED} -v d=${breed} -v f=${colMARKER} '{FS=";"} {if ($a == b && $c ~ d)print $f}' ${REFTAB_SiTeAr})
bezarg=$(awk -v a=${colCode} -v b=${defectcode} -v c=${colIMPBREED} -v d=${breed} -v e=${colKenn} '{FS=";"} {if ($a == b && $c ~ d)print $e}' ${REFTAB_SiTeAr})
#beztyp=$(awk -v a=${colCode} -v b=${defectcode} -v c=${colIMPBREED} -v d=${breed} -v e=${colType} '{FS=";"} {if ($a == b && $c ~ d)print $e}' ${REFTAB_SiTeAr})
if test -s ${SNP_DIR}/einzelgen/argus/glossar/${defectcode}${algorithm}Interpretation.txt ;then
HaLabel=$(cat ${SNP_DIR}/einzelgen/argus/glossar/${defectcode}${algorithm}Interpretation.txt)
else
HaLabel=$(echo ${defectcode})
fi

awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));CD[$1]=$2;}} \
    else {sub("\015$","",$(NF));sD=CD[$1]; \
    if   (sD != "") {print $1" "sD}}}' $RES_DIR/RUN${run}${breed}.${defectcode}.Fimpute.${algorithm} $TMP_DIR/${breed}.NewFor.${defectcode}.srt |\
    awk -v label=${HaLabel} '{if($2 == 0) print $1";"label"F"; else if ($2 == 1) print $1";"label"C"; else if ($2 == 2) print $1";"label"S"; else print $1";OOOPS"}' > ${SNP_DIR}/einzelgen/argus/import/${breed}/${idd}.${bezarg}.${heute}.CH.Haplotypen.ImportGenmarker.dat

echo "Wir haben folgende Verteilung der ${defectcode} Genotypen im Ergebnisfile ${SNP_DIR}/einzelgen/argus/import/${breed}/${idd}.${bezarg}.${heute}.CH.Haplotypen.ImportGenmarker.dat:"
cut -d';' -f2 ${SNP_DIR}/einzelgen/argus/import/${breed}/${idd}.${bezarg}.${heute}.CH.Haplotypen.ImportGenmarker.dat | sort -T ${SRT_DIR} | uniq -c

echo "copy to Folder der anderen Einzelgenergebnisse fuer ${natfolder}"

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
    if   (sD != "") {print $1" "sD" "tD}}}' $RES_DIR/RUN${run}${breed}.${defectcode}.Fimpute.${algorithm} $TMP_DIR/${breed}.NewFor.${defectcode}.srt | awk '{if($2 == 2) print}' | wc -l | awk '{print $1}' )
if [ ${nhomos} -gt 0 ]; then
echo "Attention following lines reply homozygous samples amoung new HD samples:"
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));CD[$1]=$2;DD[$1]=$8;}} \
    else {sub("\015$","",$(NF));sD=CD[$1];tD=DD[$1]; \
    if   (sD != "") {print $1" "sD" "tD}}}' $RES_DIR/RUN${run}${breed}.${defectcode}.Fimpute.${algorithm} $TMP_DIR/${breed}.NewFor.${defectcode}.srt | awk '{if($2 == 2) print}' | sort -t' ' -k3,3n
echo " "
echo "check if these are of interest"
echo " "
fi
#rm -f $TMP_DIR/${defectcode}.txt
#rm -f $TMP_DIR/${breed}.NewFor.${defectcode}.srt
#rm -f $TMP_DIR/geno.info.${defectcode}${breed}.srt
#rm -f $TMP_DIR/gt.${defectcode}.${breed}.tmp
#rm -f $TMP_DIR/${defectcode}-haplo12-Codierung.txt
#rm -f $TMP_DIR/${breed}Fgt${defectcode}.tmp
#rm -f $TMP_DIR/${breed}Fgt${defectcode}.transposed
#rm -f $TMP_DIR/${breed}Fgt${defectcode}.animals
#rm -f $TMP_DIR/${breed}Fgt${defectcode}.haplos.tmp
#rm -f $TMP_DIR/${breed}Fgt${defectcode}.haplotypesInRows
#rm -f $TMP_DIR/${breed}SMLLFgt${defectcode}.haplotypesInRows
#rm -f $TMP_DIR/haplo.to.fetch.${breed}${defectcode}


echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT} 

