#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT} 
echo " "


##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o errexit

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

##############################################################


#Zielmap enthaelt schon nur noch die LD-SNP die auch auf dem HD chip drauf sind
#Programm schreibt neue Map für sas Imputing, d.h. die map aus writeNewAimMap.sh wird hier uerberschrieben
#2 Chips hier
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
getColmnNrSemicl IntergenomicsCode ${REFTAB_CHIPS} ; colITGX=$colNr_
getColmnNrSemicl QuagCode ${REFTAB_CHIPS} ; colQUG=$colNr_
#echo $colITGX $colQUG
HDchipZiel=$(awk -v cc=${colQUG} -v dd=${colITGX} -v nc=${NewChip1} 'BEGIN{FS=";"}{if( $dd == nc ) print $cc }' ${REFTAB_CHIPS})


#Use QUagcode codes here!! > now in parameterfile
echo "selected chip for masking was ${HDchipZiel}"
echo "ATTENTION: defined in $PAR_DIR/steuerungsvariablen.ctr.sh"
echo "I use Routine Fimpute data and select the snps from there. I don't go back to the archive and set up everything de novo"
echo " "



if [ -z $1 ]; then
    echo "brauche den Code fuer die Rasse: BSW oder HOL "
    exit 1
elif [ $1 == 'BSW' ] || [ $1 == 'HOL' ] || [ $1 == 'VMS' ] ; then
    
    set -o nounset
    breed=$(echo "$1")

    
    echo "identify youngest HD genotyped samples from both tail populations"
    #prep für GCTA, trennen nach Rasse und behalte nur LD-SNPs geregelt ueber callrate snp --geno 0.01
    #falls der realse zielchi genommen werden soll hier auskommentieren, weiter unten ebenso
    join -t' ' -o'2.2 2.1 2.3 2.4 2.5' -1 1 -2 2 <(awk '{if($2 == 1) print $1,$2}' $FIM_DIR/${breed}BTAwholeGenome_FImpute.geno | sort -T ${SRT_DIR} -t' ' -k1,1) <(join -t' ' -o'2.5 2.1 1.3 1.4 1.5' -e'-' -1 2 -2 5 <(cat $TMP_DIR/${breed}.Blutanteile.txt | tr ';' ' ' | sort -T ${SRT_DIR} -t' ' -k2,2) <(sort -T ${SRT_DIR} -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed})|sort -T ${SRT_DIR} -t' ' -k2,2 ) >  $TMP_DIR/MASKobsianteil.${breed}.srt
    
    #liste fuer die berechnung der allelfrequenzen
    if [ ${breed} == "BSW" ]; then
    ls -trl /qualstore03/data_zws/snp/dataWide${HDchipZiel}/bvch/* | awk '{print $9}' | cut -d'.' -f1 | cut -d'/' -f7 | awk '{print $1,$1}' | sort -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -o'2.1' -1 1 -2 6 - <(sort -T ${SRT_DIR} -t' ' -k6,6 $WRK_DIR/Run${run}.alleIDS_${breed}.txt ) > $TMP_DIR/${breed}.zielchip.samples
    awk -v blood=${blutanteilsgrenze} '{if($3 >  blood) print $0}' $TMP_DIR/MASKobsianteil.${breed}.srt | sort -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -1 1 -2 1 -o'1.1 1.2 1.3 1.4 1.5'  - <(awk '{print $1,$1}' $TMP_DIR/${breed}.zielchip.samples | sort -T ${SRT_DIR} -t' ' -k1,1 ) > $TMP_DIR/MASKhigher.animals.${breed}
    awk -v blood=${blutanteilsgrenze} '{if($4 >= blood) print $0}' $TMP_DIR/MASKobsianteil.${breed}.srt | sort -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -1 1 -2 1 -o'1.1 1.2 1.3 1.4 1.5'  - <(awk '{print $1,$1}' $TMP_DIR/${breed}.zielchip.samples | sort -T ${SRT_DIR} -t' ' -k1,1 ) > $TMP_DIR/MASKlower.animals.${breed}
    fi
    if [ ${breed} == "HOL" ]; then
    ls -trl /qualstore03/data_zws/snp/dataWide${HDchipZiel}/shb/* | awk '{print $9}' | cut -d'.' -f1 | cut -d'/' -f7 | awk '{print $1,$1}' | sort -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -o'2.1' -1 1 -2 6 - <(sort -T ${SRT_DIR} -t' ' -k6,6 $WRK_DIR/Run${run}.alleIDS_${breed}.txt ) > $TMP_DIR/${breed}.zielchip.samples
    awk -v blood=${blutanteilsgrenze} '{if($3 >  blood) print $0}' $TMP_DIR/MASKobsianteil.${breed}.srt | sort -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -1 1 -2 1 -o'1.1 1.2 1.3 1.4 1.5'  - <(awk '{print $1,$1}' $TMP_DIR/${breed}.zielchip.samples | sort -T ${SRT_DIR} -t' ' -k1,1 ) > $TMP_DIR/MASKhigher.animals.${breed}
    awk -v blood=${blutanteilsgrenze} '{if($5 >= blood) print $0}' $TMP_DIR/MASKobsianteil.${breed}.srt | sort -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -1 1 -2 1 -o'1.1 1.2 1.3 1.4 1.5'  - <(awk '{print $1,$1}' $TMP_DIR/${breed}.zielchip.samples | sort -T ${SRT_DIR} -t' ' -k1,1 ) > $TMP_DIR/MASKlower.animals.${breed}
    fi
    if [ ${breed} == "VMS" ]; then
    ls -trl /qualstore03/data_zws/snp/dataWide${HDchipZiel}/vms/* | awk '{print $9}' | cut -d'.' -f1 | cut -d'/' -f7 | awk '{print $1,$1}' | sort -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -o'2.1' -1 1 -2 6 - <(sort -T ${SRT_DIR} -t' ' -k6,6 $WRK_DIR/Run${run}.alleIDS_${breed}.txt ) > $TMP_DIR/${breed}.zielchip.samples
    awk -v blood=${blutanteilsgrenze} '{if($3 >  blood) print $0}' $TMP_DIR/MASKobsianteil.${breed}.srt | sort -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -1 1 -2 1 -o'1.1 1.2 1.3 1.4 1.5'  - <(awk '{print $1,$1}' $TMP_DIR/${breed}.zielchip.samples | sort -T ${SRT_DIR} -t' ' -k1,1 ) > $TMP_DIR/MASKhigher.animals.${breed}
    awk -v blood=${blutanteilsgrenze} '{if($5 >= blood) print $0}' $TMP_DIR/MASKobsianteil.${breed}.srt | sort -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -1 1 -2 1 -o'1.1 1.2 1.3 1.4 1.5'  - <(awk '{print $1,$1}' $TMP_DIR/${breed}.zielchip.samples | sort -T ${SRT_DIR} -t' ' -k1,1 ) > $TMP_DIR/MASKlower.animals.${breed}
    fi


    rm -f  $TMP_DIR/selectedMASK.animals.${breed}
    for i in higher lower; do
       calcFive=$(wc -l $TMP_DIR/MASK${i}.animals.${breed} | awk '{printf "%8.0f\n", $1*0.1}' | awk '{print $1}' )
       nALL=$(wc -l $TMP_DIR/MASK${i}.animals.${breed} | awk '{print $1}')
       threshold=$(echo $nALL $calcFive | awk '{print $1-$2}')
       echo "tailpop: ${i} / NoMasked: ${calcFive} / NoOriginal: $threshold / NoALL: $nALL"
       sort -T ${SRT_DIR} -t' ' -k1,1n $TMP_DIR/MASK${i}.animals.${breed} | awk -v n=${threshold} '{if(NR > n) print}' >> $TMP_DIR/selectedMASK.animals.${breed}
    done

    awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));GZW[$1]=$2;}} \
    else {sub("\015$","",$(NF));STAT="0";EBV=GZW[$1]; \
    if   (EBV == "") {print $0}}}' $TMP_DIR/selectedMASK.animals.${breed} $FIM_DIR/${breed}BTAwholeGenome_FImpute.geno > $FIM_DIR/MASK${breed}BTAwholeGenome_FImpute.geno

    awk 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));GZW[$1]=$2;}} \
    else {sub("\015$","",$(NF));STAT="0";EBV=GZW[$1]; \
    if   (EBV != "") {print $0}}}' $TMP_DIR/selectedMASK.animals.${breed} $FIM_DIR/${breed}BTAwholeGenome_FImpute.geno > $TMP_DIR/MASK${breed}BTAwholeGenome_FImpute.gts
    echo "cut the SNPs which are in the set of LDsnps."
    
    awk '{if(NR > 1 && $5 != 0) print $4}' $FIM_DIR/${breed}BTAwholeGenome_FImpute.snpinfo > $TMP_DIR/${breed}.selectedColsforGTfile

#delete files if they exist
    rm -f $TMP_DIR/${breed}LD.fimpute.MASKED.${run}.[0-9]*
#aufteilen auf ${numerOfParallelRjobs}
    noofani=$(wc -l $TMP_DIR/selectedMASK.animals.${breed} | awk '{print $1}') 
#achtung trick: immer + 0.5 damit immer auf die nachste ganzzahl aufgerundet wird
    nAniPerRun=$(echo ${noofani} ${numberOfParallelRJobs} | awk '{printf "%.0f", ($1/$2)+0.5}')
    echo "&&&&&"
    echo $nAniPerRun ${numberOfParallelRJobs} 
    wc -l $TMP_DIR/selectedMASK.animals.${breed}
    echo "&&&&&"
    n=0;
    z=$(echo ${n} ${nAniPerRun} | awk -v m=${nAniPerRun} '{print 1+($1*m)}')
#   echo $z $noofani;
    while [ ${noofani} -gt ${z} ] ; do
       echo "now starting ${n} loop";
       startRow=$(echo "1 ${n} ${nAniPerRun}" | awk '{print $1+($2*$3)}')
       endRow=$(echo "${n} 1 ${nAniPerRun}" | awk '{print ($1+$2)*$3}')
       echo $n $startRow $endRow;
       #cut the SNPs here using an script running in parallel for samples
       nohup ${BIN_DIR}/selectSNPsforMASKING.sh ${breed} ${startRow} ${endRow} ${n} 2>&1 > $LOG_DIR/${SCRIPT}.${breed}.${n}.log  &
           
       #update n and z
       n=$(echo $n | awk '{print $1+1}')
       z=$(echo ${n} ${nAniPerRun} | awk -v m=${nAniPerRun} '{print 1+($1*m)}')
    done

    echo "sleeping now for sec=60 "
    sleep 60;
    echo "check now if outfiles are ready"
    echo ${numberOfParallelRJobs}
    for np in $(ls -trl ${TMP_DIR}/${breed}LD.fimpute.MASKED.[0-9]*| awk '{print $9}' | cut -d'.' -f5 | sort -T ${SRT_DIR} -n); do
         echo ${np}
         PRLLRUNcheck $TMP_DIR/${breed}LD.fimpute.MASKED.${run}.${np}
    done

    echo " "
    echo "collect all files from parallel runs now"
    cat $TMP_DIR/${breed}LD.fimpute.MASKED.${run}.[0-9]*  >> $FIM_DIR/MASK${breed}BTAwholeGenome_FImpute.geno

    echo "Look at the masked genotypefile: "
    awk '{print $2,length($3)}' $FIM_DIR/MASK${breed}BTAwholeGenome_FImpute.geno |sort -T ${SRT_DIR} | uniq -c
    echo "Look at the original genotypefile: "
    awk '{print $2,length($3)}' $FIM_DIR/${breed}BTAwholeGenome_FImpute.geno |sort -T ${SRT_DIR} | uniq -c
    echo " "
else
    echo  "Rasse muss entweder BSW oder HOL sein... Prozess wird gestoppt"
fi




echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
