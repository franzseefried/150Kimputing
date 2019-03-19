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
START_DIR=pwd

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


set -o nounset
breed=${1}

#idee: wenn das system das erste mal laufen soll muessen alle SNPs in der Map sein. erst waehrend dem ersten lauf werden ja die SNPs gefiltert
#hier mit diesem skript wird angenommen es ha 2 Maps zB 150K und LD47K
#von diesen werden die neuen Positionen und BTA geholt und eine Map "$HIS_DIR/${1}.RUN${fixSNPdatum}snp_info.txt" geschrieben
#Codierung Sex-chromosomen: 33-> Mitochondrial SNP, 32-> XY /pseudoautosomale Region des Y, 31-> Y, 30 -> X,
#Ausnahme Code 34 in HD file von INtergenomics: 34-> Mitochindiral SNPs
#plink mag XY code nicht, darum zuerst Y codieren dann via --split-x, die koordinaten geholt aus den neuen mapfiles die kleinste / grösste Positionsangabe -/+1 genommen, fix gemacht

#Use intergenomics codes here!! > now in parameterfile
#NewChip1=139_V1
#ARS12Name1=139977_GGPHDV3
#NewChip2=48_V1
#ARS12Name2=47843_BOVG50V1

echo "small overview"
join -t' ' -o'1.1 1.2 2.2' -a1 -e'-' -1 1 -2 1 <(awk '{print $1,"HD"}' $MAP_DIR/intergenomics/SNPindex_${NewChip1}_new_order.txt |sort -T ${SRT_DIR} -t' ' -k1,1) <(awk '{print $1,"LD"}' $MAP_DIR/intergenomics/SNPindex_${NewChip2}_new_order.txt | sort -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1) |\
cut -d' ' -f2,3 | sort -T ${SRT_DIR} | uniq -c

echo "hole ARS1.2 koordinates"
#nur autosomale SNP, nur SNP die in der neuen Map1 BTA && Pos haben, 
#wenn LDpos neg und abs(pos) == posHD, dann nimm HDpos
join -t' ' -o'1.1 1.2 2.2' -a1 -e'-' -1 1 -2 1 <(awk '{print $1,"HD"}' $MAP_DIR/intergenomics/SNPindex_${NewChip1}_new_order.txt |sort -T ${SRT_DIR} -t' ' -k1,1) <(awk '{print $1,"LD"}' $MAP_DIR/intergenomics/SNPindex_${NewChip2}_new_order.txt | sort -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1) |\
   sort -T ${SRT_DIR} -t' ' -k1,1 |\
   join -t' ' -o1.1 1.2 1.3 2.2 2.3 -1 1 -2 1 -a1 -e'-' - <(awk 'BEGIN{FS="\t"}{print $2,$1,$4}' $MAP_DIR/UMC_marker_names_180910/9913_ARS1.2_${ARS12Name1}_marker_name_180910.map |sort -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1)|\
   sort -T ${SRT_DIR} -t' ' -k1,1 |\
   join -t' ' -o1.1 1.2 1.3 1.4 1.5 2.2 2.3 -1 1 -2 1 -a1 -e'-' - <(awk 'BEGIN{FS="\t"}{print $2,$1,$4}' $MAP_DIR/UMC_marker_names_180910/9913_ARS1.2_${ARS12Name2}_marker_name_180910.map |sort -T ${SRT_DIR} -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1)|\
   awk '{if($4 != 0 && $5 > 0)print}' |\
   sort -T ${SRT_DIR} -t' ' -k4,4n -k5,5n |\
   tee $TMP_DIR/${breed}.newAimMap.1-33.txt |\
   awk '{if( $4 < 35 ) print}' |\
   awk '{if($7 == "-" || $7 > 0) print $0;if ($7 != "-" && ($5 == ((-1)*$7))) print $1,$2,$3,$4,$5,$4,$5}' > $TMP_DIR/${breed}.newAimMap.txt
   
#check if there are SNPs with identical positions & BTAs but different names, remove them
awk '{print $4"_"$5}' $TMP_DIR/${breed}.newAimMap.txt | sort -T ${SRT_DIR} | uniq -c | awk '{if($1 != 1) print $2}' | sort -T ${SRT_DIR} > $TMP_DIR/${breed}.identicalPos.txt
awk '{print $1,$4"_"$5}' $TMP_DIR/${breed}.newAimMap.txt |sort -T ${SRT_DIR}  -t' ' -k2,2 | join -t' ' -o'1.1 1.1' -1 2 -2 1 - $TMP_DIR/${breed}.identicalPos.txt > $TMP_DIR/${breed}.identicalPos.Names.txt
nB=$(wc -l $TMP_DIR/${breed}.identicalPos.Names.txt | awk '{print $1}')
if [ ${nB} -gt 0 ]; then echo "you are removing ${nB} SNPs having different names but identical positions / BTAs"; fi
awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));SNP[$1]=$2}} \
    else {sub("\015$","",$(NF));MARKER=SNP[$1];\
    if   (MARKER == "") {print $0}}}' $TMP_DIR/${breed}.identicalPos.Names.txt $TMP_DIR/${breed}.newAimMap.txt > $TMP_DIR/${breed}.newAimMap.txt2
mv $TMP_DIR/${breed}.newAimMap.txt2 $TMP_DIR/${breed}.newAimMap.txt
   
echo "SNPID Chr BPPos chip_1 chip_2" | awk '{printf "%-53s%+6s%+10s%+15s%+10s\n", $1,$2,$3,$4,$5}' > $HIS_DIR/${1}.RUN${fixSNPdatum}snp_info.txt
echo "SNPID Chr BPPos chip_1 chip_2" | awk '{printf "%-53s%+6s%+10s%+15s%+10s\n", $1,$2,$3,$4,$5}' > $HIS_DIR/${1}.RUN${fixSNPdatum}snp_info.autosomal.txt

   awk '{if($5 != "-") print $0}' $TMP_DIR/${breed}.newAimMap.txt | awk '{print $1,NR}' > $TMP_DIR/${breed}.HD.newmap.txt
   awk '{if($7 != "-") print $0}' $TMP_DIR/${breed}.newAimMap.txt | awk '{print $1,NR}' > $TMP_DIR/${breed}.LD.newmap.txt
   join -t' ' -o'1.1 1.2 1.3 1.4 1.5 1.6 1.7 2.2' -1 1 -2 1 <(sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}.newAimMap.txt) <(sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}.HD.newmap.txt) |\
   sort -T ${SRT_DIR} -t' ' -k1,1 |\
   join -t' ' -o'1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 2.2' -a1 -e'0' -1 1 -2 1 - <(sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${breed}.LD.newmap.txt) |\
   sort -T ${SRT_DIR} -t' ' -k4,4n -k5,5n |\
   awk '{gsub("34","MT",$4);gsub("33","MT",$4);gsub("32","Y",$4);gsub("31","Y",$4);gsub("30","X",$4); print $1,$2,$3,$4,$5,$6,$7,$8,$9}' |\
   awk '{printf "%-53s%+6s%+10s%+15s%+10s\n", $1,$4,$5,$8,$9}' >> $HIS_DIR/${1}.RUN${fixSNPdatum}snp_info.txt
   
   awk '{if(NR > 1 && $2 ~ "[0-9]") printf "%-53s%+6s%+10s%+15s%+10s\n", $1,$2,$3,$4,$5}' $HIS_DIR/${1}.RUN${fixSNPdatum}snp_info.txt >> $HIS_DIR/${1}.RUN${fixSNPdatum}snp_info.autosomal.txt



awk '{if(NR > 1) print $2,$1,"0",$3}' $HIS_DIR/${1}.RUN${fixSNPdatum}snp_info.txt | sort -T ${SRT_DIR} -t' ' -k2,2 > $TMP_DIR/OVERALL.${breed}.zielmap

rm -f $TMP_DIR/${breed}.identicalPos.txt
rm -f $TMP_DIR/${breed}.identicalPos.Names.txt
rm -f $TMP_DIR/${breed}.newAimMap.txt2
rm -f $TMP_DIR/${breed}.HD.newmap.txt
rm -f $TMP_DIR/${breed}.LD.newmap.txt





echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
