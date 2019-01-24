#!/bin/bash
RIGHT_NOW=$(date +"%x %r %Z")
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " " 



##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
#set -o nounset
#set -o errexit
if [ -z $1 ]; then
    echo "brauche den Code fuer die Rasse: BSW oder HOL oder VMS "
    exit 1
elif [ ${1} == "BSW" ]; then
        echo $1 > /dev/null
elif [ ${1} == "HOL" ]; then
        echo $1 > /dev/null
elif [ ${1} == "VMS" ]; then
        echo $1 > /dev/null
else
        echo " $1 != BSW / HOL / VMS, ich stoppe"
        exit 1
fi


breed=${1}
if [ ${breed} == "BSW" ]; then outzo="BSW;JER"; fi
if [ ${breed} == "HOL" ]; then outzo="HOL;RED;MON;SIM"; fi
if [ ${breed} == "VMS" ]; then outzo="LIM;AAN;XXX;DXT;ERI"; fi

###Defintion der Function zum Joinen############################
#funktion zum joinen. gejoint wird auf Feld 1, feldtrenner = Leerschlag, alle Record von File 1 werden beibehalten, hinzu kommt $2 vom file2
LOOPJOIN () {
#check no of arguments (files)
if [ "$#" -le 1 ]; then
    echo $#
    echo "Illegal number of parameters"
    exit 1
fi
#define array mit den files, via print all given arguments
#Iarr=(a.txt b.txt c.txt d.txt)
Iarr=($@)

#test of alle files existieren
#for i in ${Iarr[*]} ; do
#if ! test -s ${i}; then echo "${i} does not exist or has sitze zero"; exit 1; fi
#done

#quasi join via awk array
for i in $(seq 1 $(echo ${#Iarr[*]} | awk '{print $1-1}') ); do 

if [ ${i} == 1 ]; then
fileEINS=$(echo ${Iarr[i-1]})
else
fileEINS=$TMP_DIR/${breed}.sumuplog.LOOPJOINout.txt
fi

#echo "$i ; ${fileEINS} ; ${Iarr[i]}"
#echo " "
awk 'BEGIN{FS=" "}{if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));status[$1]=$2;}}  \
    else {sub("\015$","",$(NF));STAT="0";STAT=status[$1]; \
    if(STAT != ""){print $1,$2,STAT} \
    if(STAT == ""){print $1,$2,"#"}}}' ${Iarr[i]} ${fileEINS} | sed 's/ /\;/2' > $TMP_DIR/${breed}.sumuplog.LOOPJOINout.tmp
mv $TMP_DIR/${breed}.sumuplog.LOOPJOINout.tmp $TMP_DIR/${breed}.sumuplog.LOOPJOINout.txt
#cat $TMP_DIR/${breed}.sumuplogLD.LOOPJOINout.txt

done
sed -i 's/\;/ /g' $TMP_DIR/${breed}.sumuplog.LOOPJOINout.txt
}




#AUfbau des arrays mit den files
#ls $TMP_DIR/smpg${breed}/* | sort -T ${SRT_DIR} -t'#' -k2,2n
filearray=$(ls $TMP_DIR/smpg${breed}/* | sort -T ${SRT_DIR} -t'#' -k2,2n)
#echo $filearray
echo " "


################################################################################
#Daten sammeln
awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info  | grep -v "kein Tier mit der ID" |\
    sed "s/ \{1,\}/#/g" |\
    awk 'BEGIN{FS=";";OFS=" "}{print $2,$1";"$3";"substr($3,1,3)}' |\
    sort -T ${SRT_DIR} -t';' -k1,1 > $TMP_DIR/${breed}logfile.sumup.srt


#update filearray set for LD
fid=$(echo $TMP_DIR/${breed}logfile.sumup.srt ${filearray[@]})
#echo ${fid[*]}

#join aller files mit der Funktion mit dem array der files als $2
LOOPJOIN ${fid[*]}

mv $TMP_DIR/${breed}.sumuplog.LOOPJOINout.txt $TMP_DIR/${breed}.OUTsumuplog.LOOPJOINout.txt



#ausschreiben alles sammeln inkl umdrehen spalte 1 und spalte 2
(echo "idanimal;TVD;ITBID;ImputationsRasse;IMPresultALT;IMPresultNEU;Pedigree;MultiVATERmatch;MultiMUTTERmatch;OhneVATERmatch;OhneMUTTERmatch;VaterPedigree;VaterSNP;MutterPedigree;MutterSNP;ChipCurrentIMPTier;ChipCurrentIMPVaterPedigree;ChipCurrentIMPMutterPedigree;ChipCurrentIMPMVPedigree;VVsuspekt;MVsuspekt;ExterneSNP;SNPTwin;GenomicF;PedigreeF"
sed 's/\;/ /g' $TMP_DIR/${breed}.OUTsumuplog.LOOPJOINout.txt | awk '{x=$1; $1=$2; $2=x; print}' |\
  awk -v outo=${outzo} '{if(outo ~ $4) print $0}' |\
  awk '{if($7 == "#") $7="+"; print $0}' |\
  tr ' ' ';' |\
  sed 's/#//g' |\
  sed 's/&//g' |\
  sort -T ${SRT_DIR} -t';' -k1,1 -k2,2 ) > $HIS_DIR/${breed}_SumUpLOG.${run}.csv


head $HIS_DIR/${breed}_SumUpLOG.${run}.csv
echo " "
rm -f $TMP_DIR/${breed}logfile.sumup.srt 
rm -f $TMP_DIR/${breed}.OUTsumuplog.LOOPJOINout.txt



echo " "
RIGHT_END=$(date +"%x %r %Z")
echo $RIGHT_END Ende ${SCRIPT}
