#!/bin/bash
RIGHT_NOW=$(date +"%x %r %Z")
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " " 

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
#define function to chek when parallel jobs are ready

PRLLRUNcheck () {
#echo ${1};
existshot=N
existresult=Y
while [ ${existshot} != ${existresult} ]; do
if test -s ${1}  ; then
RIGHT_NOW=$(date +"%x %r %Z")
existshot=Y
fi
done


echo "file to check  ${1}  exists ${RIGHT_NOW}, check if it is ready"
shotcheck=same
shotresult=unknown
current=$(date +%s)
while [ ${shotcheck} != ${shotresult} ]; do
 lmod=$(stat -c %Y ${1} )
 RIGHT_NOW=$(date +"%x %r %Z")
 #echo $current $lmod
 if [ ${lmod} > 120 ]; then
    shotresult=same
    echo "${1} is ready now ${RIGHT_NOW}"
 fi
done

}

if [ -z $1 ]; then
    echo "brauche den Code fuer die Rasse: BSW oder HOL "
    exit 1
fi
if [ -z $2 ]; then
    echo "brauche den Code ob Genotypen oder phased genotypes gelesen werden sollen: .out fuer Genotypen / .haplos fuer phased genotypes"
    exit 1
fi
set -o errexit
set -o nounset
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
    foldername="haplos"
else
    echo "${2} is not correct, GENOTYPES or HAPLOTYPES are allowed"
    exit 1
fi


breed=$(echo "$1")

cat $WORK_DIR/ped_umcodierung.txt.${breed} | tr ' ' ';' > $TMP_DIR/ped_umcodierung.txt.${breed}.smcl

if [ ${GWASsetofANIS} == "HD" ]; then
  (awk '{if(NR==1) print $1,$3}' $FIM_DIR/${breed}BTAwholeGenome.${foldername}/genotypes_imp.txt  ;
  awk '{if(NR>1 && $2 == 1) print $1,$3}'  $FIM_DIR/${breed}BTAwholeGenome.${foldername}/genotypes_imp.txt  ) | awk '{printf "%-8s%s\n", $1,$2}' > $TMP_DIR/${breed}.genotypes.dat
  if [ ${HFTSNPSET} == "LD" ]; then
    echo "Using HD-genotyped animals on LD-SNP-density was selected"
    rm -f $TMP_DIR/${breed}.genotypes.dat

    echo "cut the SNPs which are in the set of LDsnps."
    awk '{if(NR > 1 && $5 != 0) print $4}' $FIM_DIR/${breed}BTAwholeGenome.out/snp_info.txt > $TMP_DIR/${breed}.selectedColsforGTfile
    echo "ich behalte nur tatsaechlich typisierte Tiere, d.h. Tiere die rein an Hand ihrer typisierten Nachkommen imputiert werden sind ausgeschlossen"
    echo " ";
    awk '{if(NR > 1 && $2 == 1) print $1,$2,$3}' $FIM_DIR/${breed}BTAwholeGenome.${foldername}/genotypes_imp.txt > $TMP_DIR/${breed}.fmptrgb.txt

  #aufteilen auf ${numerOfParallelRjobs}
        noofani=$(wc -l $TMP_DIR/${breed}.fmptrgb.txt | awk '{print $1}') 
  #achtung trick: immer + 0.5 damit immer auf die nachste ganzzahl aufgerundet wird
        nAniPerRun=$(echo ${noofani} ${numberOfParallelRJobs} | awk '{printf "%.0f", ($1/$2)+0.5}')
        n=0;
        z=$(echo ${n} ${nAniPerRun} | awk -v m=${nAniPerRun} '{print 1+($1*m)}')
  #        echo $z $noofani;
        while [ ${noofani} -gt ${z} ] ; do
           echo "now starting ${n} loop";
           startRow=$(echo "1 ${n} ${nAniPerRun}" | awk '{print $1+($2*$3)}')
           endRow=$(echo "${n} 1 ${nAniPerRun}" | awk '{print ($1+$2)*$3}')
           #echo $n $startRow $endRow;
           #cut the SNPs here using an script running in parallel for samples
           nohup ${BIN_DIR}/selectSNPsfromFimputeErgebnis.sh ${breed} ${startRow} ${endRow} ${n} 2>&1 > $LOG_DIR/${SCRIPT}.${breed}.${n}.log  &
           
           #update n and z
           n=$(echo $n | awk '{print $1+1}')
           z=$(echo ${n} ${nAniPerRun} | awk -v m=${nAniPerRun} '{print 1+($1*m)}')
        done

    echo " "
    sleep 7;
    echo "check now if outfiles are ready"
    for np in $(seq 0 $(echo "${numberOfParallelRJobs} 2" | awk '{print $1-$2}')); do
         PRLLRUNcheck $TMP_DIR/${breed}LD.fimpute.ergebnis.${run}.${np}
    done

    echo " "
    echo "collect all files from parallel runs now"
  (awk '{if(NR==1) print $1,$3}' $FIM_DIR/${breed}BTAwholeGenome.${foldername}/genotypes_imp.txt;
    awk '{print $1,$3}' $TMP_DIR/${breed}LD.fimpute.ergebnis.${run}.[0-9]* | sort -T ${SRT_DIR} -u -T $SRT_DIR) | awk '{printf "%-8s%s\n", $1,$2}'  > $TMP_DIR/${breed}.genotypes.dat
  wc -l $TMP_DIR/${breed}.genotypes.dat
fi


elif [ ${GWASsetofANIS} == "LD" ]; then
  if [ ${HFTSNPSET} == "HD" ]; then
    (awk '{if(NR==1) print $1,$3}' $FIM_DIR/${breed}BTAwholeGenome.${foldername}/genotypes_imp.txt  ;
     awk '{if(NR>1 && $2 > 0) print $1,$3}'  $FIM_DIR/${breed}BTAwholeGenome.${foldername}/genotypes_imp.txt  ) | awk '{printf "%-8s%s\n", $1,$2}' > $TMP_DIR/${breed}.genotypes.dat
  fi
  if [ ${HFTSNPSET} == "LD" ]; then
    echo "Using HD & LD-genotyped animals on LD-SNP-density was selected"
    rm -f $TMP_DIR/${breed}.genotypes.dat

    echo "cut the SNPs which are in the set of LDsnps."
    awk '{if(NR > 1 && $5 != 0) print $4}' $FIM_DIR/${breed}BTAwholeGenome.out/snp_info.txt > $TMP_DIR/${breed}.selectedColsforGTfile
    echo "ich behalte nur tatsaechlich typisierte Tiere, d.h. Tiere die rein an Hand ihrer typisierten Nachkommen imputiert werden sind ausgeschlossen"
    echo " ";
    awk '{if(NR > 1 && $2 > 0) print $1,$2,$3}' $FIM_DIR/${breed}BTAwholeGenome.${foldername}/genotypes_imp.txt > $TMP_DIR/${breed}.fmptrgb.txt

  #aufteilen auf ${numerOfParallelRjobs}
        noofani=$(wc -l $TMP_DIR/${breed}.fmptrgb.txt | awk '{print $1}') 
  #achtung trick: teile durch Anzahl Parallele Jobs Minus 1 damit unten mit 30 Jobs alles genau aufgeht
        nAniPerRun=$(echo ${noofani} ${numberOfParallelRJobs} | awk '{printf "%.0f", $1/($2-1)}')
        n=0;
        z=$(echo ${n} ${nAniPerRun} | awk -v m=${nAniPerRun} '{print 1+($1*m)}')
  #        echo $z $noofani;
        while [ ${noofani} -gt ${z} ] ; do
           echo "now starting ${n} loop";
           startRow=$(echo "1 ${n} ${nAniPerRun}" | awk '{print $1+($2*$3)}')
           endRow=$(echo "${n} 1 ${nAniPerRun}" | awk '{print ($1+$2)*$3}')
           #echo $n $startRow $endRow;
           #cut the SNPs here using an script running in parallel for samples
           nohup ${BIN_DIR}/selectSNPsfromFimputeErgebnis.sh ${breed} ${startRow} ${endRow} ${n} 2>&1 > $LOG_DIR/${SCRIPT}.${breed}.${n}.log  &
           
           #update n and z
           n=$(echo $n | awk '{print $1+1}')
           z=$(echo ${n} ${nAniPerRun} | awk -v m=${nAniPerRun} '{print 1+($1*m)}')
        done

    echo " "
    sleep 7;
    echo "check now if outfiles are ready"
    for np in $(seq 0 $(echo "${numberOfParallelRJobs} 2" | awk '{print $1-$2}')); do
         PRLLRUNcheck $TMP_DIR/${breed}LD.fimpute.ergebnis.${run}.${np}
    done

    echo " "
    echo "collect all files from parallel runs now"
   (awk '{if(NR==1) print $1,$3}' $FIM_DIR/${breed}BTAwholeGenome.${foldername}/genotypes_imp.txt;
    awk '{print $1,$3}' $TMP_DIR/${breed}LD.fimpute.ergebnis.${run}.[0-9]* | sort -T ${SRT_DIR} -u -T $SRT_DIR) | awk '{printf "%-8s%s\n", $1,$2}'  > $TMP_DIR/${breed}.genotypes.dat
   wc -l $TMP_DIR/${breed}.genotypes.dat
  fi

else
  echo "${GWASsetofANIS} was set , which is wrong since only HD LD or PD are allowed"
fi
echo "after cutting density and snpset"
wc -l $TMP_DIR/${breed}.genotypes.dat

	
sed -n '2,$p' $FIM_DIR/${breed}BTAwholeGenome.${foldername}/genotypes_imp.txt | awk '{if($2 != 0) print $1,$3}'  > $TMP_DIR/${breed}LD50K.result.snp1101

sort -T ${SRT_DIR} -t' ' -k1,1 $WORK_DIR/ped_umcodierung.txt.${breed} > $TMP_DIR/${breed}.pdumcd.srt.snp1101
  	#mit zaehler
  	awk '{print $1" f"}' $TMP_DIR/${breed}LD50K.result.snp1101 | cat -n | awk '{print $1,$2,$3}' | sort -T ${SRT_DIR} -t' ' -k2,2 |\
  	   join -t' ' -o'1.1 1.2 2.2 2.3 2.4' -e'0' -1 2 -2 1 - $TMP_DIR/${breed}.pdumcd.srt.snp1101 |\
  	   sort -T ${SRT_DIR} -t' ' -k1,1n -T $SRT_DIR | awk '{print $2,$3,$4,substr($5,4,1)}' |\
  	   awk '{if($4 == "F") print "1",$1,$2,$3,"2 9"; else print "1",$1,$2,$3,"1 9"}' >  $TMP_DIR/${breed}.LD50Kfimpute.tmp.snp1101
#aufbau Genotypenfile
echo "reduce to BS / OB / SI / HO animals"
awk '{print $1,$1}' $TMP_DIR/${breed}.genotypes.dat | tr ' ' ';' > $TMP_DIR/${breed}.LD50Kfimpute.anml
cat $WORK_DIR/ped_umcodierung.txt.${breed} | tr ' ' ';' > $TMP_DIR/ped_umcodierung.txt.${breed}.anml
if [ ${GWASpop} == "OB" ] || [ $GWASpop == "SI" ]; then
   awk 'BEGIN{FS=";";OFS=" "}{ \
     if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));PC[$2]=$3;}} \
     else {sub("\015$","",$(NF));PCI="0";PCI=PC[$5]; \
     if   (PCI != "" && PCI > 0.70) {print $0}}}' ${TMP_DIR}/${breed}.Blutanteile.txt $TMP_DIR/ped_umcodierung.txt.${breed}.anml | tr ';' ' ' > $TMP_DIR/ped_umcodierung.txt.${breed}.llams
     join -t' ' -o'1.1 1.2' -1 2 -2 1 <(sort -T ${SRT_DIR} -t' ' -k2,2 -T $SRT_DIR $TMP_DIR/${breed}.LD50Kfimpute.tmp.snp1101) <(sort -T ${SRT_DIR} -t' ' -k1,1 -T $SRT_DIR $TMP_DIR/ped_umcodierung.txt.${breed}.llams) > $TMP_DIR/${breed}.snp1101.tail.pop.ani.lst
fi
if [ ${GWASpop} == "BV" ] || [ $GWASpop == "HO" ]; then
   awk 'BEGIN{FS=";";OFS=" "}{ \
     if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));PC[$2]=$3;}} \
     else {sub("\015$","",$(NF));PCI="0";PCI=PC[$5]; \
     if   (PCI != "" && PCI < 0.3) {print $0}}}' ${TMP_DIR}/${breed}.Blutanteile.txt $TMP_DIR/ped_umcodierung.txt.${breed}.smcl | tr ';' ' ' > $TMP_DIR/ped_umcodierung.txt.${breed}.small
     join -t' ' -o'1.1 1.2' -1 2 -2 1 <(sort -T ${SRT_DIR} -t' ' -k2,2 -T $SRT_DIR $TMP_DIR/${breed}.LD50Kfimpute.tmp.snp1101) <(sort -T ${SRT_DIR} -t' ' -k1,1 -T $SRT_DIR $TMP_DIR/ped_umcodierung.txt.${breed}.small) > $TMP_DIR/${breed}.snp1101.tail.pop.ani.lst
fi

(head -1 $FIM_DIR/${breed}BTAwholeGenome.${foldername}/genotypes_imp.txt ;
awk 'BEGIN{FS=" ";OFS=" "}{ \
   if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));PC[$2]=$1;}} \
   else {sub("\015$","",$(NF));PCI="0";PCI=PC[$1]; \
   if   (PCI != "") {print $0}}}' $TMP_DIR/${breed}.snp1101.tail.pop.ani.lst $TMP_DIR/${breed}.genotypes.dat ) | awk '{printf "%-8s%s\n", $1,$2}' > $TMP_DIR/${breed}.genotypes.txt
mv $TMP_DIR/${breed}.genotypes.txt $TMP_DIR/${breed}.genotypes.dat
echo "after tail-population remain: "
wc -l $TMP_DIR/${breed}.genotypes.dat   


#sonderschleife analyse lethale haplotypen
if  [ ${2} == "HAPLOTYPES" ]; then
  echo "ausschluss von Tieren die wegen einem speziellen Grund typisiert worden sind. z.B. homozygote FH2 Tiere"
  awk 'BEGIN{FS=" ";OFS=" "}{ \
     if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));PC[$5]=$1;}} \
     else {sub("\015$","",$(NF));PCI="0";PCI=PC[$1]; \
     if   (PCI != "") {print $1,PCI}}}' $WORK_DIR/ped_umcodierung.txt.${breed} $WRK_DIR/AnimalsWithSpecificGenotypingBackground.txt > $TMP_DIR/AnimalsWithSpecificGenotypingBackground.tmp
  (head -1 $FIM_DIR/${breed}BTAwholeGenome.${foldername}/genotypes_imp.txt ;
   awk 'BEGIN{FS=" ";OFS=" "}{ \
     if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));PC[$2]=$1;}} \
     else {sub("\015$","",$(NF));PCI="0";PCI=PC[$1]; \
     if   (PCI == "") {print $0}}}' $TMP_DIR/AnimalsWithSpecificGenotypingBackground.tmp $TMP_DIR/${breed}.genotypes.dat ) | awk '{printf "%-8s%s\n", $1,$2}' > $TMP_DIR/${breed}.genotypes.txt
   mv $TMP_DIR/${breed}.genotypes.txt $TMP_DIR/${breed}.genotypes.dat
fi
echo " "
echo "Final statictics and if infile was HAPLOTYPES animals with specific Genotyping Background were removed "
wc -l $TMP_DIR/${breed}.genotypes.dat


rm -f $TMP_DIR/ped_umcodierung.txt.${breed}.smcl
rm -f $TMP_DIR/${breed}.selectedColsforGTfile
rm -f $TMP_DIR/${breed}.fmptrgb.txt
rm -f $TMP_DIR/${breed}.pedi.tmp
rm -f $TMP_DIR/${breed}.uppd.tmp
rm -f $TMP_DIR/${breed}LD50K.result.snp1101
rm -f $TMP_DIR/${breed}.pdumcd.srt.snp1101
rm -f $TMP_DIR/${breed}.LD50Kfimpute.tmp.snp1101
rm -f $TMP_DIR/${breed}.LD50Kfimpute.anml
rm -f $TMP_DIR/ped_umcodierung.txt.${breed}.anml
rm -f $TMP_DIR/ped_umcodierung.txt.${breed}.llams
rm -f $TMP_DIR/${breed}.snp1101.tail.pop.ani.lst
rm -f $TMP_DIR/ped_umcodierung.txt.${breed}.small
rm -f $TMP_DIR/AnimalsWithSpecificGenotypingBackground.tmp

echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
