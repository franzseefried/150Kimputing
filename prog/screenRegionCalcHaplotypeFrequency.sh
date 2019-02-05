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
  echo "Usage: $SCRIPT -b <string>"
  echo "  where <string> specifies the breed with options bsw, hol or vms"
  echo "Usage: $SCRIPT -c <string>"
  echo "  where <string> specifies the chromosome giving a numeric code"
  echo "Usage: $SCRIPT -d <string>"
  echo "  where <string> specifies the Parameter for the Haplotype to be processed"
  echo "Usage: $SCRIPT -h <string>"
  echo "  where <string> specifies the Parameter for the Carrier Status of example Animals aplotype to be processed" 
  exit 1
}

### check number of command line arguments
NUMARGS=$#
echo "Number of arguments: $NUMARGS"
if [ $NUMARGS -lt 0 ]  ; then
  usage 'No command line arguments specified'
fi

while getopts :b:c:d:h: FLAG; do
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
    c) # set option "c"
      export chromo=$(echo $OPTARG )
      re='^[0-9]+$'
      if ! [[ $chromo =~ $re ]] ; then 
          echo "Code for Chromosome is not a number"
          exit 1
      else 
          BTA=$(echo ${chromo}| awk '{print $1+0}')
      fi
      ;;
    d) # set option "s"
      export defectcode=$(echo $OPTARG)
      ;;
    h) # set option "h"
      export hc=$(echo $OPTARG | awk '{print toupper($1)}')
      if [ ${hc} == "HETERO" ] || [ ${hc} == "HOMO" ]; then
          echo ${breed} > /dev/null
      else
          usage "Status of carrier animals not correct, must be specified: HETERO / HOMO using option -h <string>"
          exit 1
      fi
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
if [ -z "${chromo}" ]; then
    usage 'Parameter for Chromosome must be specified using option -s <string>'      
fi
### # check that setofanomals is not empty
if [ -z "${defectcode}" ]; then
    usage 'Parameter for the polymophism must be specified using option -z <string>'      
fi
### # check that list of exampleanimals is not empty
if [ -z "${hc}" ]; then
    usage 'Parameter for the exampleanimals must be specified using option -z <string>'
fi
#theoretisch wird keine unterschediung hetero homo benötigt, aber der einfachhheit halber und wg der ueberinstimmung mit dem anderen screen programm wurde dies so beibehalten
if [ ${hc} == "HETERO" ]; then
ls -trl $WRK_DIR/${breed}.${defectcode}.heterozygous.lst
if ! test -s $WRK_DIR/${breed}.${defectcode}.heterozygous.lst ; then
echo "$WRK_DIR/${breed}.${defectcode}.heterozygous.lst does not exist or has size zero"
exit 1
fi
fi
if [ ${hc} == "HOMO" ]; then
ls -trl $WRK_DIR/${breed}.${defectcode}.homozygous.lst
if ! test -s $WRK_DIR/${breed}.${defectcode}.homozygous.lst ; then
echo "$WRK_DIR/${breed}.${defectcode}.homozygous.lst does not exist or has size zero"
exit 1
fi
fi
if ! test -s ${SNP_DIR}/data/mapFiles/${breed}_${defectcode}_associatedHapQUALITAS.lst ; then
   echo "${SNP_DIR}/data/mapFiles/${breed}_${defectcode}_associatedHapQUALITAS.lst does not exist or has size zero"
   exit 1
fi
if ! test -s $FIM_DIR/${breed}BTAwholeGenome.haplos/genotypes_imp.txt ;then
   echo "$FIM_DIR/${breed}BTAwholeGenome.haplos/genotypes_imp.txt does not exist or has size zero"
   exit 1
fi


#Defintion der region auf Eben SNPnamen Start und Ende
SNPb=$(awk '{if(NR == 1) print $1}' ${SNP_DIR}/data/mapFiles/${breed}_${defectcode}_associatedHapQUALITAS.lst)
SNPe=$(awk '{print $1}' ${SNP_DIR}/data/mapFiles/${breed}_${defectcode}_associatedHapQUALITAS.lst| tail -1)
#ableiten der Position im GenotypenString
spos=$(awk -v s=${SNPb} '{if($1 == s) print $4}' $FIM_DIR/${breed}BTAwholeGenome.haplos/snp_info.txt)
epos=$(awk -v s=${SNPe} '{if($1 == s) print $4}' $FIM_DIR/${breed}BTAwholeGenome.haplos/snp_info.txt)
snpnamen=$(awk -v ss=${spos} -v ee=${epos} '{if(NR > 1 && $4 >= ss && $4 <= ee) print $1}'  $FIM_DIR/${breed}BTAwholeGenome.haplos/snp_info.txt | tr '\n' ' ' )
haplotypelength=$(echo $epos $spos | awk '{print $1-$2}')
#echo $spos $epos $haplotypelength
#ACHTUNG: in der Haplotypenmap muss der Zeilenumbruch in der letzen Zeile fehlen sonst stimmt das rechnen nicht mehr!!!!!!!!!!



sort -T ${SRT_DIR} -t' ' -k3,3n $MAP_DIR/${breed}_${defectcode}_associatedHapQUALITAS.lst | awk '{print $1}' > $TMP_DIR/${defectcode}.txt
(awk '{if($2 == 2) print $1,"LD"}' $HIS_DIR/${breed}.RUN${run}.IMPresult.tierlis ;
                awk '{if($2 == 1) print $1,"DB"}' $HIS_DIR/${breed}.RUN${run}.IMPresult.tierlis) | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.neu${defectcode}.srt
    (awk '{if($2 == 2) print $1,"LD"}' $HIS_DIR/${breed}.RUN${oldrun}.IMPresult.tierlis;
            awk '{if($2 == 1) print $1,"DB"}' $HIS_DIR/${breed}.RUN${oldrun}.IMPresult.tierlis ) | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}.alt${defectcode}.srt
join -t' ' -o'1.1 1.2' -v1 -1 1 -2 1 $TMP_DIR/${breed}.neu${defectcode}.srt $TMP_DIR/${breed}.alt${defectcode}.srt > $TMP_DIR/${breed}.NewFor.${defectcode}.srt

awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | sed 's/ /#/g' | tr ';' ' ' | cut -d' ' -f2,3,4,7,9,11 |\
sort -T ${SRT_DIR} -t' ' -k1,1 |\
join -t' ' -o'1.1 1.2 1.3 1.4 1.5 1.6 2.5' -1 1 -2 2 - <(sed 's/\;/ /g' $TMP_DIR/${breed}.Blutanteile.txt | sort -T ${SRT_DIR} -t' ' -k2,2) |\
sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/geno.info.${defectcode}${breed}.srt



echo ${defectcode} ${breed} stated calc Haplotype freq amoung list of samples


sed 's/ //g' $WORK_DIR/animal.overall.info | sed 's/\;\;/\;NA\;/g' | cut -d';' -f2-5,9,11 | tr ';' ' ' > $TMP_DIR/gt.${defectcode}.${breed}.tmp


#Logik: bei Bottom umkodieren zur kompl Base, dann habe ich Allel 1 und 2 in der Illuminareihenfolge als AllelA und AllelB, in der Imputation zählen wir B, d.h. B=2 ACHTUNG sortierung hier anders wie in den ursprünlg programmen
awk '{ sub("\r$", ""); print }' $MAP_DIR/${breed}_${defectcode}_associatedHapQUALITAS.lst | awk '{print $1,$4,NR}' | sort -T ${SRT_DIR} -t' ' -k3,3n >  $TMP_DIR/${defectcode}-haplo12-Codierung.txt

#hatte via PLINK Allel B als referenz allel generell gesetzt

#to do file transposen damit logik behalten werden kann. Neu hier nur der Haplotypenbock Statt das ganze BTA
awk -v st=${spos} -v et=${epos}  '{if(NR > 1) print substr($3,st,((et+1)-st))}' $FIM_DIR/${breed}BTAwholeGenome.haplos/genotypes_imp.txt | sed 's/./& /g' > $TMP_DIR/${breed}${BTA}Fgt${defectcode}.tmp
#erster transpose macht umstrukturerung von rows in colums und von 1 Zeile pro Tier zu 2 colums pro tier nur Genotypen, sed -f codiert von Fimpute Diplotypencalling in Allelcalling um
cp ${PAR_DIR}/Fimpute.standard.output.allelecoding.lst.sed ${TMP_DIR}/Fimpute.standard.output.allelecoding.lst.sed${defectcode}
$BIN_DIR/awk_transpose.job $TMP_DIR/${breed}${BTA}Fgt${defectcode}.tmp | sed -f ${TMP_DIR}/Fimpute.standard.output.allelecoding.lst.sed${defectcode} > $TMP_DIR/${breed}${BTA}Fgt${defectcode}.transposed
#zweiter transpose macht struktur von spaltenweise in zeilenweise zurück, jetzt aber 2 Zeilen pro tier im output
awk '{if(NR > 1) print $1,$1}' $FIM_DIR/${breed}BTAwholeGenome.haplos/genotypes_imp.txt | tr ' ' '\n' > $TMP_DIR/${breed}${BTA}Fgt${defectcode}.animals
$BIN_DIR/awk_transpose.job $TMP_DIR/${breed}${BTA}Fgt${defectcode}.transposed  > $TMP_DIR/${breed}${BTA}Fgt${defectcode}.haplos.tmp
paste -d' ' $TMP_DIR/${breed}${BTA}Fgt${defectcode}.animals $TMP_DIR/${breed}${BTA}Fgt${defectcode}.haplos.tmp > $TMP_DIR/${breed}${BTA}Fgt${defectcode}.haplotypesInRows


cat $TMP_DIR/${breed}${BTA}Fgt${defectcode}.haplotypesInRows | sed 's/B/2/g' | sed 's/A/1/g' | sed 's/ /_/g'  |sed 's/_/ /1' > $TMP_DIR/${breed}${BTA}SMLLFgt${defectcode}.haplotypesInRows



#read list with carriers
if [ ${hc} == "HETERO" ]; then
     join -t' ' -o'1.1' -1 5 -2 1 <(sort -T ${SRT_DIR} -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed}) <(awk '{print $1,"C"}' $WRK_DIR/${breed}.${defectcode}.heterozygous.lst | sort -T ${SRT_DIR} -t' ' -k1,1) > $TMP_DIR/${breed}.${defectcode}.hafran.tmp
fi    
if [ ${hc} == "HOMO" ]; then
     join -t' ' -o'1.1' -1 5 -2 1 <(sort -T ${SRT_DIR} -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed}) <(awk '{print $1,"C"}' $WRK_DIR/${breed}.${defectcode}.homozygous.lst | sort -T ${SRT_DIR} -t' ' -k1,1) > $TMP_DIR/${breed}.${defectcode}.hafran.tmp
fi    
rm -f $TMP_DIR/${breed}${BTA}SMLLFgt${defectcode}.frqAnalysis    


#reduce to screening animals
join -t' ' -o'1.1 1.2' -1 1 -2 1 <(sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}${BTA}SMLLFgt${defectcode}.haplotypesInRows) <(sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}.${defectcode}.hafran.tmp) | sed 's/_//g' | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/${breed}${BTA}SMLLFgt${defectcode}.haplotypesInRows.${hc}

#calc Frq fuer jeden Haplotyp# zaehle haplotypen wg frq uneten
nani=$(wc -l $TMP_DIR/${breed}${BTA}SMLLFgt${defectcode}.haplotypesInRows.${hc})
echo "Habe ${nani} ${hc} Bsp-Animals"
#define lengthregion
nSNP=$(awk '{if(NR == 1) print length($2)}' $TMP_DIR/${breed}${BTA}SMLLFgt${defectcode}.haplotypesInRows.${hc})
echo "Habe ${nSNP} SNP im Ausgangsfenster"
#schiebe fenster von vorne nach hinten und selektiere Haplotypen die so oft vorkommen wie es Bsp-Tiere hat
#write into summary, da es mehr als inen solchen Hapotyp geben kann, v.a. sehr kurze, der längste müsste der gesuchte sein
rm -f $TMP_DIR/${breed}${BTA}SMLLFgt${defectcode}.frqAnalysis


#berechnung der Frequenz der haplotypen
#k=laenge des blocks, kuerzester block 2 SNP
for k in $(seq ${nSNP} -1 2); do
    #i=start des blocks
    for i in $(seq 1 1 ${i}); do
        #echo $k $i
        awk -v z=${k} -v y=${i} '{print substr($2,y,z)}' $TMP_DIR/${breed}${BTA}SMLLFgt${defectcode}.haplotypesInRows.${hc} | sort -T ${SRT_DIR} -u |\
        while read haplotype; do
          nH=$(awk -v z=${k} -v y=${i} -v x=${haplotype} '{if(substr($2,y,z) == x)print}' $TMP_DIR/${breed}${BTA}SMLLFgt${defectcode}.haplotypesInRows.${hc} | wc -l | awk '{print $1}')
          echo ${nH} ${nani} | awk '{printf "%1.3f"  ,$1/$2}' | awk -v haplo=${haplotype} -v kk=${k} -v ii=${i} '{print $1,kk,ii,length(haplo),haplo}' >> $TMP_DIR/${breed}${BTA}SMLLFgt${defectcode}.frqAnalysis
        done 
    done
    i=$(echo $i | awk '{print $1+1}')
done

if test -s $TMP_DIR/${breed}${BTA}SMLLFgt${defectcode}.frqAnalysis; then
    (echo "HaplotypeFreq Blockstart Blockende LaengeHaplotyp Haplotyp";
    sort -T ${SRT_DIR} -t' ' -k4,4nr -k1,1nr $TMP_DIR/${breed}${BTA}SMLLFgt${defectcode}.frqAnalysis)> $TMP_DIR/${breed}${BTA}SMLLFgt${defectcode}.FREQSTAT.txt
    echo " "
    echo "show records of result-summary here"
    cat  $TMP_DIR/${breed}${BTA}SMLLFgt${defectcode}.FREQSTAT.txt
    echo " "
    echo "hole die Haplotypen mit p(>0.5) aus dem Summary"
    awk '{if($1 >= 0.5) print $0}'  $TMP_DIR/${breed}${BTA}SMLLFgt${defectcode}.FREQSTAT.txt | sort -T ${SRT_DIR} -t' ' -k1,1n -k4,4n
fi





echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT} 
