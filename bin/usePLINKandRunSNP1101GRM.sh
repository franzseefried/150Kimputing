#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

#############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o errexit
set -o nounset


####ACHTUNG: es gibt probleme wenn zu viele Tiere drin sind in higher/lower.animals.${breed}!!!!!!
# Kommandozeilenargumenten einlesen und pruefen
if test -z $1; then
  echo "FEHLER: Kein Argument erhalten. Diesem Shell-Script muss ein Rassenkuerzel mitgegeben werden! --> PROGRAMMABBRUCH"
  exit 1
fi
breed=$(echo $1 | awk '{print toupper($1)}')

if [ ${breed} != "BSW" ] && [ ${breed} != "HOL" ] && [ ${breed} != "VMS" ]; then
  echo "FEHLER: Diesem shell-Script wurde ein unbekanntes Rassenkuerzel uebergeben! (BSW / HOL / VMS sind zulaessig) --> PROGRAMMABBRUCH"
  exit 1
fi



#prep für GCTA, trennen nach Rasse und behalte nur LD-SNPs geregelt ueber callrate snp --geno 0.01
$BIN_DIR/awk_grepLDSNP $WORK_DIR/${breed}Typisierungsstatus${run}.txt <(join -t' ' -o'2.5 2.1 1.3 1.4 1.5' -e'-' -1 2 -2 5 <(cat $TMP_DIR/${breed}.Blutanteile.txt | tr ';' ' ' | sort -T ${SRT_DIR} -t' ' -k2,2) <(sort -T ${SRT_DIR} -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed}) | sed 's/ /\;/2') | tr ';' ' ' | awk '{print $2,$1,$3,$4,$5}'  > $TMP_DIR/obsianteil.${breed}.srt

#liste fuer die berechnung der allelfrequenzen
if [ ${breed} == "BSW" ]; then
awk -v blood=${blutanteilsgrenze} '{if($3 >  blood) print $1}' $TMP_DIR/obsianteil.${breed}.srt > $SMS_DIR/higher.animals.${breed}
awk -v blood=${blutanteilsgrenze} '{if($4 >= blood) print $1}' $TMP_DIR/obsianteil.${breed}.srt > $SMS_DIR/lower.animals.${breed}
fi
if [ ${breed} == "HOL" ]; then
awk -v blood=${blutanteilsgrenze} '{if($3 >  blood) print $1}' $TMP_DIR/obsianteil.${breed}.srt > $SMS_DIR/higher.animals.${breed}
awk -v blood=${blutanteilsgrenze} '{if($5 >= blood) print $1}' $TMP_DIR/obsianteil.${breed}.srt > $SMS_DIR/lower.animals.${breed}
fi
if [ ${breed} == "VMS" ]; then
awk -v blood=${blutanteilsgrenze} '{if($3 >  blood) print $1}' $TMP_DIR/obsianteil.${breed}.srt > $SMS_DIR/higher.animals.${breed}
awk -v blood=${blutanteilsgrenze} '{if($5 >= blood) print $1}' $TMP_DIR/obsianteil.${breed}.srt > $SMS_DIR/lower.animals.${breed}
fi

#liste fuer die zuordnung der Tiere beim erstellen der GRM 
if [ ${breed} == "BSW" ]; then
awk -v blood=${blutanteilsgrenze} '{if($3 >  0.5) print $1}' $TMP_DIR/obsianteil.${breed}.srt > $SMS_DIR/grm.higher.animals.${breed}
awk -v blood=${blutanteilsgrenze} '{if($4 >= 0.5) print $1}' $TMP_DIR/obsianteil.${breed}.srt > $SMS_DIR/grm.lower.animals.${breed}
fi
if [ ${breed} == "HOL" ]; then
awk -v blood=${blutanteilsgrenze} '{if($3 >  0.5) print $1}' $TMP_DIR/obsianteil.${breed}.srt > $SMS_DIR/grm.higher.animals.${breed}
awk -v blood=${blutanteilsgrenze} '{if($5 >= 0.5) print $1}' $TMP_DIR/obsianteil.${breed}.srt > $SMS_DIR/grm.lower.animals.${breed}
fi
if [ ${breed} == "VMS" ]; then
awk -v blood=${blutanteilsgrenze} '{if($3 >  0.5) print $1}' $TMP_DIR/obsianteil.${breed}.srt > $SMS_DIR/grm.higher.animals.${breed}
awk -v blood=${blutanteilsgrenze} '{if($5 >= 0.5) print $1}' $TMP_DIR/obsianteil.${breed}.srt > $SMS_DIR/grm.lower.animals.${breed}
fi


$FRG_DIR/plink --bfile $TMP_DIR/${breed}merged_ --cow --geno 0.01 --recodeA --reference-allele $TMP_DIR/${breed}LDFIFTYK.force.Bcount --make-bed -out $TMP_DIR/${breed}.LDsnps.forSNP1101.LDsnp
$FRG_DIR/plink --bfile $TMP_DIR/${breed}.LDsnps.forSNP1101.LDsnp --cow --mind 0.5 --recodeA --reference-allele $TMP_DIR/${breed}LDFIFTYK.force.Bcount --out $TMP_DIR/${breed}.LDsnps.forSNP1101


echo " "
echo "Baue Genotypenfile jetzt fuer ${1}"
(echo "ID Call..." ;
   sed 's/ /#/1' $TMP_DIR/${breed}.LDsnps.forSNP1101.raw | sed -n '2,$p' | sed 's/ /#/1' | sed 's/ /#/4' | cut -d'#' -f2,4 | sed 's/ //g' | sed 's/NA/5/g' | tr '#' ' ' | awk '{print $1,$2}') > $SMS_DIR/${breed}.SNP1101FImpute.geno
echo " "

echo "copy Pedfile von Fimpute"
cp $FIM_DIR/${breed}Fimpute.ped $SMS_DIR/${breed}.SNP1101FImpute.ped

echo " "
echo "make Mapfile"
(echo "SNPID Chr Pos";
awk '{if(NR == 1) print }' $TMP_DIR/${breed}.LDsnps.forSNP1101.raw | cut -d' ' -f7- | tr ' ' '\n' | cat -n | awk '{print $2,$1}' | sed 's/_B / /g' | sort -T ${SRT_DIR} -t' ' -k1,1 |\
join -t' ' -o'1.1 1.2 2.2 2.3' -1 1 -2 1 - <(sort -T ${SRT_DIR} -t' ' -k1,1 ${FIM_DIR}/${breed}BTAwholeGenome_FImpute.snpinfo) | sort -T ${SRT_DIR} -t' ' -k2,2n | awk '{print $1,$3,$4}') > $SMS_DIR/${breed}.SNP1101FImpute.snplst


cd $SMS_DIR
echo " "
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^run Allele frequency calculation for base population of ${breed}"
cat $PAR_DIR/SNP1101_AFC.ctr | sed "s/WWWWWWWWWW/${breed}/g" > $SMS_DIR/${breed}.AFC.use
rm -rf $SMS_DIR/${breed}-AFC
mkdir -p $SMS_DIR/${breed}-AFC
$FRG_DIR/snp1101 $SMS_DIR/${breed}.AFC.use
echo " "
echo "remove header from allele frq file for ${breed}"
for i in lower higher; do
cp $SMS_DIR/${breed}-AFC/afreq_${i}.txt $SMS_DIR/${breed}-AFC/afreq_${i}.wiHeader
awk '{if(NR > 1) print}' $SMS_DIR/${breed}-AFC/afreq_${i}.wiHeader > $SMS_DIR/${breed}-AFC/afreq_${i}.txt
done
echo " "

pids=
for RMtype in G P; do 
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^run ${RMtype}RM calculation for ${breed}"
cat $PAR_DIR/SNP1101_${RMtype}RM.ctr | sed "s/WWWWWWWWWW/${breed}/g" > $SMS_DIR/${breed}.${RMtype}RM.use
rm -rf $SMS_DIR/${breed}-${RMtype}RM
mkdir -p $SMS_DIR/${breed}-${RMtype}RM
cd $SMS_DIR
(
$FRG_DIR/snp1101 $SMS_DIR/${breed}.${RMtype}RM.use 2>&1 > $LOG_DIR/${breed}.${RMtype}RM.SMP1101.log
)&
pid=$!
pids=(${pids[@]} $pid)
cd ${MAIN_DIR}
pwd
date
done

echo "Here ar the jobids of the stated SNP1101-Jobs"
echo ${pids[@]}
echo " "
nJobs=$(echo ${pids[@]} | wc -w | awk '{print $1}')
echo "Waiting till Relationship-Matrixes are set up"
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
  sleep 60
done

echo "Relationship-Matrixes are ready now:"
ls -trl $SMS_DIR/${breed}-PRM/amtx_kin1.txt
ls -trl $SMS_DIR/${breed}-GRM/gmtx_kin1.txt



echo " "
RIGHT_NOW=$(date )
echo $RIGHT_NOW Ende ${SCRIPT}
