#!/bin/bash
RIGHT_NOW=$(date +"%x %r %Z")
echo $RIGHT_NOW 

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################


if [ -z $1 ]; then
    echo "brauche den Code fuer die Rasse: BSW oder HOL "
    exit 1
fi
if [ -z $2 ]; then
    echo "brauche den Code ob Genotypen oder phased genotypes gelesen werden sollen: .out fuer Genotypen / .haplos fuer phased genotypes"
    exit 1
fi
if [ ${1} == "BSW" ]; then
pdfol=bv
datped=${DatPEDIbvch}
fi
if [ ${1} == "HOL" ]; then
pdfol=rh
datped=${DatPEDIshb}
fi
if [ ${1} == "VMS" ]; then
pdfol=vms
datped=${DatPEDIvms}
fi


if [ ${2} == "GENOTYPES" ]; then
    foldername="out"
elif [ ${2} == "HAPLOTYPES" ]; then
    echo "$2 was given as paramater which is not supproted here"
    exit 1
else
    echo "${2} is not correct, GENOTYPES or HAPLOTYPES are allowed"
    exit 1
fi


breed=$(echo "$1")

cat $WORK_DIR/ped_umcodierung.txt.${breed} | tr ' ' ';' > $TMP_DIR/ped_umcodierung.txt.${breed}.smcl

if [ ${GWASsetofANIS} == "HD" ]; then
(awk '{if(NR==1) print $1,$3}' $FIM_DIR/${breed}BTAwholeGenome.${foldername}/genotypes_imp.txt  ;
awk '{if(NR>1 && $2 == 1) print $1,$3}'  $FIM_DIR/${breed}BTAwholeGenome.${foldername}/genotypes_imp.txt  ) | awk '{printf "%-8s%s\n", $1,$2}' > $TMP_DIR/${breed}.genotypes.dat
elif [ ${GWASsetofANIS} == "LD" ]; then
(awk '{if(NR==1) print $1,$3}' $FIM_DIR/${breed}BTAwholeGenome.${foldername}/genotypes_imp.txt  ;
awk '{if(NR>1 && $2 > 0) print $1,$3}'  $FIM_DIR/${breed}BTAwholeGenome.${foldername}/genotypes_imp.txt  ) | awk '{printf "%-8s%s\n", $1,$2}' > $TMP_DIR/${breed}.genotypes.dat
elif [ ${GWASsetofANIS} == "PD" ]; then
(awk '{if(NR==1) print $1,$3}' $FIM_DIR/${breed}BTAwholeGenome.${foldername}/genotypes_imp.txt  ;
awk '{if(NR>1 && $2 >= 0) print $1,$3}'  $FIM_DIR/${breed}BTAwholeGenome.${foldername}/genotypes_imp.txt  ) | awk '{printf "%-8s%s\n", $1,$2}' > $TMP_DIR/${breed}.genotypes.dat
else
echo "${GWASsetofANIS} was set , which is wrong since only HD LD or PD are allowed"
fi


(echo "SNPID Chr Pos";
   cat $FIM_DIR/${breed}BTAwholeGenome.${foldername}/snp_info.txt | sed -n '2,$p') | awk '{printf "%-50s%-5s%-10s\n", $1,$2,$3}' > $TMP_DIR/${breed}.snpinfo.dat
    

   cat $FIM_DIR/${breed}Fimpute.ped_siredamkorrigiert_NGPsiredamkorrigiert | sed -n '2,$p' | awk '{print $1";"$2";"$3";"$4}' > $TMP_DIR/${breed}.pedi.tmp

MissingYoB=$(date +"%x" | cut -d'/' -f3)

#update pedigree with YoB
awk '{print substr($0,1,10)";"substr($0,73,4)}' ${PEDI_DIR}/work/${pdfol}/UpdatedRenumMergedPedi_${datped}.txt | sed 's/ //g' > $TMP_DIR/${breed}.uppd.tmp
(echo "ID SireID DamID Gender YoB";
awk -v MYOB=${MissingYoB} 'BEGIN{FS=";"}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));bp[$1]=$2;}} \
    else {sub("\015$","",$(NF));bpS=bp[$1]; \
    if   (bpS != "" && bpS != 9999) {print $1" "$2" "$3" "$4" "bpS} \
    else             {print $1" "$2" "$3" "$4" "MYOB}}}' $TMP_DIR/${breed}.uppd.tmp $TMP_DIR/${breed}.pedi.tmp) | awk '{printf "%-10s%-10s%-10s%-10s%-10s\n", $1,$2,$3,$4,$5}' > $TMP_DIR/${breed}.pedi.dat

	
sed -n '2,$p' $FIM_DIR/${breed}BTAwholeGenome.${foldername}/genotypes_imp.txt | awk '{if($2 != 0) print $1,$3}'  > $TMP_DIR/${breed}LD50K.result.snp1101

sort -T ${SRT_DIR} -t' ' -k1,1 $WORK_DIR/ped_umcodierung.txt.${breed} > $TMP_DIR/${breed}.pdumcd.srt.snp1101
  	#mit zaehler
  	awk '{print $1" f"}' $TMP_DIR/${breed}LD50K.result.snp1101 | cat -n | awk '{print $1,$2,$3}' | sort -T ${SRT_DIR} -t' ' -k2,2 |\
  	   join -t' ' -o'1.1 1.2 2.2 2.3 2.4' -e'0' -1 2 -2 1 - $TMP_DIR/${breed}.pdumcd.srt.snp1101 |\
  	   sort -T ${SRT_DIR} -t' ' -k1,1n | awk '{print $2,$3,$4,substr($5,4,1)}' |\
  	   awk '{if($4 == "F") print "1",$1,$2,$3,"2 9"; else print "1",$1,$2,$3,"1 9"}' >  $TMP_DIR/${breed}.LD50Kfimpute.tmp.snp1101

echo "reduce to BS / OB / SI / HO animals"
awk '{print $1,$1}' $TMP_DIR/${breed}.genotypes.dat | tr ' ' ';' > $TMP_DIR/${breed}.LD50Kfimpute.anml
cat $WORK_DIR/ped_umcodierung.txt.${breed} | tr ' ' ';' > $TMP_DIR/ped_umcodierung.txt.${breed}.anml
if [ ${GWASpop} == "OB" ] || [ $GWASpop == "SI" ]; then
awk 'BEGIN{FS=";";OFS=" "}{ \
  if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));PC[$2]=$3;}} \
  else {sub("\015$","",$(NF));PCI="0";PCI=PC[$5]; \
  if   (PCI != "" && PCI > 0.6) {print $0}}}' ${TMP_DIR}/${breed}.Blutanteile.txt $TMP_DIR/ped_umcodierung.txt.${breed}.anml | tr ';' ' ' > $TMP_DIR/ped_umcodierung.txt.${breed}.llams
  join -t' ' -o'1.1 1.2' -1 2 -2 1 <(sort -T ${SRT_DIR} -t' ' -k2,2 $TMP_DIR/${breed}.LD50Kfimpute.tmp.snp1101) <(sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/ped_umcodierung.txt.${breed}.llams) > $TMP_DIR/${breed}.snp1101.tail.pop.ani.lst
fi
if [ ${GWASpop} == "BV" ] || [ $GWASpop == "HO" ]; then
awk 'BEGIN{FS=";";OFS=" "}{ \
  if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));PC[$2]=$3;}} \
  else {sub("\015$","",$(NF));PCI="0";PCI=PC[$5]; \
  if   (PCI != "" && PCI < 0.4) {print $0}}}' ${TMP_DIR}/${breed}.Blutanteile.txt $TMP_DIR/ped_umcodierung.txt.${breed}.smcl | tr ';' ' ' > $TMP_DIR/ped_umcodierung.txt.${breed}.small
  join -t' ' -o'1.1 1.2' -1 2 -2 1 <(sort -T ${SRT_DIR} -t' ' -k2,2 $TMP_DIR/${breed}.LD50Kfimpute.tmp.snp1101) <(sort -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/ped_umcodierung.txt.${breed}.small) > $TMP_DIR/${breed}.snp1101.tail.pop.ani.lst
fi

(head -1 $FIM_DIR/${breed}BTAwholeGenome.${foldername}/genotypes_imp.txt ;
awk 'BEGIN{FS=" ";OFS=" "}{ \
   if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));PC[$2]=$1;}} \
   else {sub("\015$","",$(NF));PCI="0";PCI=PC[$1]; \
   if   (PCI != "") {print $0}}}' $TMP_DIR/${breed}.snp1101.tail.pop.ani.lst $TMP_DIR/${breed}.genotypes.dat ) | awk '{print $1,$2}' > $TMP_DIR/${breed}.genotypes.dattmp



#erganezen von sire dam sex phenotype
awk 'BEGIN{FS=" ";OFS=" "}{ \
   if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));ps[$1]=$2;pd[$1]=$3;pb[$1]=substr($4,4,1);}} \
   else {sub("\015$","",$(NF));PCI=ps[$1];DCI=pd[$1];BCI=pb[$1]; \
   if   (PCI != "") {print "1",$1,PCI,DCI,BCI,$2}}}' $WORK_DIR/ped_umcodierung.txt.${breed}.updated $TMP_DIR/${breed}.genotypes.dattmp | sed 's/ M / 1 /1' | sed 's/ F / 2 /1' > $TMP_DIR/${breed}.genotypes.ped
   

   
#reduktion auf die cases == 2 & controls == 1. erganzen von dummy phänotyp
(awk '{print $1,$1,"2"}' $GWAS_DIR/${breed}_${GWAStrait}_affectedAnimals.txt; 
 awk '{print $1,$1,"1"}' $GWAS_DIR/${breed}_${GWAStrait}_controlAnimals.txt) | sort -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -o'2.1 1.2 1.3' -1 1 -2 5 - <(sort -T ${SRT_DIR} -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed}.updated) > $TMP_DIR/${breed}.${GWAStrait}.keep
awk 'BEGIN{FS=" ";OFS=" "}{ \
   if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));ps[$1]=$2;ph[$1]=$3;}} \
   else {sub("\015$","",$(NF));PCI=ps[$2];PHE=ph[$2]; \
   if   (PCI != "" && PHE != "") {print $1,$2,$3,$4,$5,PHE,$6}}}' $TMP_DIR/${breed}.${GWAStrait}.keep $TMP_DIR/${breed}.genotypes.ped > $TMP_DIR/${breed}.${GWAStrait}.genotypes.pedtmp



#finale files hier:
paste -d' ' <(awk '{print $1,$2,$3,$4,$5,$6}' $TMP_DIR/${breed}.${GWAStrait}.genotypes.pedtmp) <(awk '{print $7}' $TMP_DIR/${breed}.${GWAStrait}.genotypes.pedtmp | sed 's/0/A A /g' | sed 's/1/A B /g' | sed 's/2/B B /g'  | sed 's/ $//g')  > $TMP_DIR/${breed}.${GWAStrait}.genotypes.ped
cat $FIM_DIR/${breed}BTAwholeGenome.${foldername}/snp_info.txt | sed -n '2,$p' | awk '{print $2,$1,"0",$3}' > $TMP_DIR/${breed}.${GWAStrait}.genotypes.map



wc -l $TMP_DIR/${breed}.${GWAStrait}.genotypes.ped
echo " "


echo "Basta cosi"
RIGHT_END=$(date +"%x %r %Z")
echo $RIGHT_END

