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
  echo "Usage: $SCRIPT -c <string>"
  echo "  where <string> specifies the Parameter for the Density to be processed HD or LD are allowed"
  echo "Usage: $SCRIPT -l <string>"
  echo "  where <string> specifies the Parameter for the Imputationsystem"  
  exit 1
}

### check number of command line arguments
NUMARGS=$#
echo "Number of arguments: $NUMARGS"
if [ $NUMARGS -lt 0 ]  ; then
  usage 'No command line arguments specified'
fi

while getopts :b:d:c:l: FLAG; do
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
          exit 1;
      fi
      ;;
    d) # set option "s"
      export defectcode=$(echo $OPTARG)
      ;;
    c) # set option "c"
      export dichte=$(echo $OPTARG | awk '{print toupper($1)}')
      if [ ${dichte} == "HD" ] || [ ${dichte} == "LD" ]; then
          echo ${dichte} > /dev/null
      else
          usage "Dichte not correct, must be specified: bsw / hol / vms using option -b <string>"
          exit 1
      fi
      ;;
    l) # set option "d"
      export SNPlevel=$(echo $OPTARG)
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


if ! test -s $FIM_DIR/${breed}BTAwholeGenome.haplos/genotypes_imp.txt ;then
   echo "$FIM_DIR/${breed}BTAwholeGenome.haplos/genotypes_imp.txt does not exist or has size zero"
   exit 1
fi
if [ ${dichte} == "HD" ]; then FimDen=1;fi
if [ ${dichte} == "LD" ]; then FimDen=2;fi
getColmnNr CodeResultfile ${REFTAB_SiTeAr} ; colCode=$colNr_
getColmnNr PredictionAlgorhithm ${REFTAB_SiTeAr} ; colPA=$colNr_
getColmnNr IMPbreedsWhereTestSegregates ${REFTAB_SiTeAr} ; colIMPBREED=$colNr_
algorithm=$(awk -v a=${colCode} -v b=${defectcode} -v c=${colIMPBREED} -v d=${breed} -v f=${colPA} '{FS=";"} {if ($a == b && $c ~ d)print $f}' ${REFTAB_SiTeAr})
if [ ${algorithm} == "HAPLOTYPE" ];then
   if ! test -s ${SNP_DIR}/data/mapFiles/${breed}_${defectcode}_associatedHapQUALITAS.lst ; then
      echo "${SNP_DIR}/data/mapFiles/${breed}_${defectcode}_associatedHapQUALITAS.lst does not exist or has size zero"
      exit 1
   fi
   #Defintion der region auf Eben SNPnamen Start und Ende
   SNPb=$(awk '{if(NR == 1) print $1}' ${SNP_DIR}/data/mapFiles/${breed}_${defectcode}_associatedHapQUALITAS.lst)
   SNPe=$(awk '{print $1}' ${SNP_DIR}/data/mapFiles/${breed}_${defectcode}_associatedHapQUALITAS.lst| tail -1)
   #ableiten der Position im GenotypenString
   wbta=$(awk -v s=${SNPb} '{if($1 == s) print $2}' $FIM_DIR/${breed}BTAwholeGenome.haplos/snp_info.txt)
   spos=$(awk -v s=${SNPb} '{if($1 == s) print $3}' $FIM_DIR/${breed}BTAwholeGenome.haplos/snp_info.txt)
   epos=$(awk -v s=${SNPe} '{if($1 == s) print $3}' $FIM_DIR/${breed}BTAwholeGenome.haplos/snp_info.txt)
   echo " "
   echo "${defectcode} ; ${breed} ; $spos ; $epos ; $wbta"
   echo " "
   startpos=$(echo ${spos} | awk '{if($1 < 1000000) print "0"; else print $1-1000000}')
   stoppos=$(echo ${epos} | awk '{print $1+1000000}')
   MaxBTA=$(awk -v ss=${stoppos} -v chr=${wbta}  '{if(NR > 1 && $2 == chr ) print $3}'  $FIM_DIR/${breed}BTAwholeGenome.out/snp_info.txt | tail -1)
   #echo $startpos $stoppos $MaxBTA
else
   #Defintion der region auf Eben Positionsangabe in REFTAB
   getColmnNr MapBp ${REFTAB_SiTeAr} ; colBP=$colNr_
   getColmnNr BTA ${REFTAB_SiTeAr} ; colCHR=$colNr_
   #ableiten der Position im GenotypenString
   wbta=$(awk -v a=${colCode} -v b=${defectcode} -v c=${colIMPBREED} -v d=${breed} -v f=${colCHR} 'BEGIN{FS=";"}{if ($a == b && $c ~ d)print $f}'  ${REFTAB_SiTeAr})
   spos=$(awk -v a=${colCode} -v b=${defectcode} -v c=${colIMPBREED} -v d=${breed} -v f=${colBP} 'BEGIN{FS=";"}{if ($a == b && $c ~ d)print $f}'  ${REFTAB_SiTeAr})
   epos=$(awk -v a=${colCode} -v b=${defectcode} -v c=${colIMPBREED} -v d=${breed} -v f=${colBP} 'BEGIN{FS=";"}{if ($a == b && $c ~ d)print $f}'  ${REFTAB_SiTeAr})
   echo " "
   echo "${defectcode} ; ${breed} ; $spos ; $epos ; $wbta"
   echo " "
   startpos=$(echo ${spos} | awk '{if($1 < 1000000) print "0"; else print $1-1000000}')
   stoppos=$(echo ${epos} | awk '{print $1+1000000}')
   MaxBTA=$(awk -v ss=${stoppos} -v chr=${wbta}  '{if(NR > 1 && $2 == chr ) print $3}'  $FIM_DIR/${breed}BTAwholeGenome.out/snp_info.txt | tail -1)
   #echo $startpos $stoppos $MaxBTA
fi
if [ ${MaxBTA} -lt ${stoppos} ];then
stoppos=${MaxBTA}
fi
echo "after checking min and max for BTA, parameter are as follows"
echo "${defectcode} ; ${breed} ; $startpos ; $stoppos ; $wbta"
echo " "
##############################################################################################
#Parameter definieren da der code unten vom projekt uebernommen wurde und nicht angapasst wurde
BTA=${wbta}
Haplotyp=${defectcode}
startH=${startpos}
endeH=${stoppos}
density=${dichte}
###################
##################
echo "Parameters are as follows:"
echo "BTA: ${BTA}"
echo "Haplotyp: ${Haplotyp}"
echo "Start Map Bp: ${startH}"
echo "Ende Map Bp: ${endeH}"
echo " "
##################


echo "Programm laeuft..."

if ! test -s ${RES_DIR}/RUN${run}${breed}.${defectcode}.Fimpute.${algorithm} ; then
   echo "$RES_DIR/RUN${run}${breed}.${defectcode}.Fimpute.${algorithm} does not exist or is empty"
   exit 1
fi

echo "dealing with haplotyplist and animal.overall.info and limitation to HD genoyped samples $8 == ${FimDen} "
join -t' ' -o'2.1 1.1 1.1 2.3 2.4 2.2 1.2' -1 1 -2 2 <(awk -v FFIM=${FimDen} '{if($8 == FFIM)print $1,$2}' $RES_DIR/RUN${run}${breed}.${defectcode}.Fimpute.${algorithm} | sort -t' ' -k1,1) <(awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | awk  'BEGIN{FS=";";OFS=";"}{print $1,$2,$3,$4";"}' | sed 's/ //g' |\
 sed 's/\;\;/\;NA\;/g'  | tr ';' ' ' | sort -t' ' -k2,2) > ${TMP_DIR}/${breed}.${Haplotyp}.idanimal.hplstat


echo "selecting SNPs from schips using ARS1.2 mapfiles -> so all SNPs within that region are plotted -> NOT only SNPs included in imputation"
getColmnNr ${SNPlevel} ${REFTAB_CHIPS} ; colDENSITY=$colNr_
getColmnNr QuagCode ${REFTAB_CHIPS} ; colNAME=$colNr_
getColmnNr ARS12Name ${REFTAB_CHIPS} ; colARS=$colNr_
getColmnNr GeneSeekCode ${REFTAB_CHIPS} ; colGENESEEK=$colNr_
CHIPSARS=$(awk -v cc=${colDENSITY} -v dd=${colARS} -v densit=${dichte} 'BEGIN{FS=";"}{if( $cc == densit ) print $dd }' ${REFTAB_CHIPS})
echo $CHIPSARS
CHIPPAIR=$(for ichip in $(echo ${CHIPSARS}); do
  CHIPS=$(awk -v cc=${colARS} -v dd=${colNAME} -v ee=${colGENESEEK} -v ars=${ichip} 'BEGIN{FS=";"}{if( $cc == ars ) print $dd";"ars";"$ee }' ${REFTAB_CHIPS})
  echo $CHIPS
done)
echo $CHIPPAIR



for ij in $(echo ${CHIPPAIR});do
  echo ${ij};
  qname=$(echo   ${ij} | cut -d';' -f1);
  arsname=$(echo ${ij} | cut -d';' -f2);
  gsname=$(echo  ${ij} | cut -d';' -f3);
  echo ${qname} ${arsname}  ${gsname}
  if [ ! -z "${qname}" ] && [ ! -z "${arsname}" ] && [ ! -z "${gsname}" ]; then
     echo "${qname} ; ${arsname} ; ${gsname} ; ${ij}";
     echo " "
     awk '{if($4 > 0) print "ALL",$2,$1,$4;if (((-1)*$4) > 0) print "ALL",$2,$1,(-1)*$4}' $MAP_DIR/UMC_marker_names_180910/9913_ARS1.2_${arsname}_marker_name_180910.map |\
     awk '{gsub("34","MT",$3);gsub("33","MT",$3);gsub("32","Y",$3);gsub("31","Y",$3);gsub("30","X",$3); print $1,$2,$3,$4}' |\
     awk -v bb=${BTA} -v bp=${startH} -v bpp=${endeH} '{if($3 == bb && $4 != "NA" && $4 >= bp && $4 <= bpp) print}' |sort -k4,4n > ${TMP_DIR}/${breed}.${defectcode}.${qname}.selected.SNP.lst
     echo " "
     if ! test -s ${TMP_DIR}/${breed}.${defectcode}.${qname}.selected.SNP.lst; then
       echo "you have no SNPs in you selection. Check boundaries and chromosomes"
     else
       echo "reduziere Ballele and LogRRatio aud die SNPs in der selektierten Region"
       ${BIN_DIR}/awk_keepSelectedSNPs ${TMP_DIR}/${breed}.${defectcode}.${qname}.selected.SNP.lst ${LOGRBAL_DIR}/*${gsname}*FinalReport.txt.Ballele_LogR | awk '{if($4 !~ "[A-Z]" && $4 !~ "[a-z]" && $3 !~ "[A-Z]" && $3 !~ "[a-z]") print}'   > ${TMP_DIR}/${breed}.${defectcode}.${qname}.BalleleLogR.selectedSNP


       ${BIN_DIR}/awk_umkodierungIDanimalzuTVDundHoleHaplostat ${TMP_DIR}/${breed}.${Haplotyp}.idanimal.hplstat  ${TMP_DIR}/${breed}.${defectcode}.${qname}.BalleleLogR.selectedSNP > ${TMP_DIR}/${breed}.${defectcode}.${qname}.BalleleLogRR.selectedSNP.TVD.haplostat


      
       for plotarg in LogRR BAlleleF; do
          echo "Rskirpt to calculate mean ${plotarg} nach Haplostat"      
          Rscript ${BIN_DIR}/ggplotLogRRBAlleleF.R ${BTA} ${Haplotyp} ${startH} ${endeH} ${TMP_DIR}/${breed}.${defectcode}.${qname}.BalleleLogRR.selectedSNP.TVD.haplostat ${TMP_DIR}/${breed}.${defectcode}.${qname}.selected.SNP.lst ${RES_DIR}/${plotarg}.${breed}.${defectcode}.${qname}.selectedSNP.TVD.haplostat_${defectcode}.txt.out ${PDF_DIR}/${plotarg}.${breed}.${defectcode}.${qname}.${startH}-${endeH}.pdf ${plotarg}
          awk '{print NR,$0}' ${TMP_DIR}/${breed}.${defectcode}.${qname}.selected.SNP.lst > ${TMP_DIR}/${breed}.${defectcode}.${qname}.selected.SNP.${startH}_${endeH}_${Haplotyp}.lst 
          echo "write summary for ${plotarg}: ${RES_DIR}/${plotarg}.${breed}.${defectcode}.${qname}.selectedSNP.TVD.haplostat_${Haplotyp}.smry"
          (echo "SNP BTA POS MeanBalleleGT0 MeanBalleleGT1 MeanBalleleGT2 DiffMeanGT1-GT0";
              join -t' ' -o'1.1 2.4 2.5 1.2 1.3 1.4' -1 1 -2 3 <(sort -t' ' -k1,1 ${RES_DIR}/${plotarg}.${breed}.${defectcode}.${qname}.selectedSNP.TVD.haplostat_${defectcode}.txt.out  ) <(sort -t' ' -k3,3 ${TMP_DIR}/${breed}.${defectcode}.${qname}.selected.SNP.${startH}_${endeH}_${Haplotyp}.lst  ) |sort -t' ' -k3,3n |awk '{print $0,$5-$4}') >  ${RES_DIR}/${plotarg}.${breed}.${defectcode}.${qname}.selectedSNP.TVD.haplostat_${Haplotyp}.smry
       done

     fi
   fi
done
rm -f ${TMP_DIR}/${breed}.${defectcode}.*.selected.SNP.lst
rm -f ${TMP_DIR}/${breed}.${Haplotyp}.idanimal.hplstat
rm -f ${TMP_DIR}/${breed}.${defectcode}.*.BalleleLogR.selectedSNP
rm -f ${TMP_DIR}/${breed}.${defectcode}.*.BalleleLogRR.selectedSNP.TVD.haplostat
rm -f ${TMP_DIR}/${breed}.${defectcode}.*.selected.SNP.${startH}_${endeH}_${Haplotyp}.lst 

echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}

