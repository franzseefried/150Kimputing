#!/bin/bash
RIGHT_NOW=$(date +"%x %r %Z")
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
if [ ${breed} == "BSW" ]; then outzo=SBZV; outfolder=sbzv;fi
if [ ${breed} == "HOL" ]; then outzo=SHSF; outfolder=swissherdbook;fi
if [ ${breed} == "VMS" ]; then outzo=VMS; outfolder=mutterkuh;fi

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
fileEINS=$TMP_DIR/${breed}.sammellog.LOOPJOINout.txt
fi

#echo "$i ; ${fileEINS} ; ${Iarr[i]}"
#echo " "
awk 'BEGIN{FS=" "}{if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));status[$1]=$2;}}  \
    else {sub("\015$","",$(NF));STAT="0";STAT=status[$1]; \
    if(STAT != ""){print $1,$2,STAT} \
    if(STAT == ""){print $1,$2,"#"}}}' ${Iarr[i]} ${fileEINS} | sed 's/ /\;/2' > $TMP_DIR/${breed}.sammellogLD.LOOPJOINout.tmp
mv $TMP_DIR/${breed}.sammellogLD.LOOPJOINout.tmp $TMP_DIR/${breed}.sammellog.LOOPJOINout.txt
#cat $TMP_DIR/${breed}.sammellogLD.LOOPJOINout.txt

done
sed -i 's/\;/ /g' $TMP_DIR/${breed}.sammellog.LOOPJOINout.txt
}




#AUfbau des arrays mit den files
#ls $TMP_DIR/smllg${breed}/* | sort -T ${SRT_DIR} -t'#' -k2,2n
filearray=$(ls $TMP_DIR/smllg${breed}/* | sort -T ${SRT_DIR} -t'#' -k2,2n)
#echo $filearray
#echo " "


################################################################################
#LD umdrehen feld 1 /feld 2 wg fkt.
(cat $TMP_DIR/${breed}LDcrossref.collecttrack.srt ;
    cat $TMP_DIR/${breed}LDcrossrefOLD.collecttrack.srt ) | awk '{print $2,$1";"$3";"$4";"$5";"$6";"$7}' > $TMP_DIR/${breed}.basis.LDsammellog.owngenotypeorders.${run}


#update filearray set for LD
fid=$(echo $TMP_DIR/${breed}.basis.LDsammellog.owngenotypeorders.${run} ${filearray[@]})
#echo ${fid[*]}

#join aller files mit der Funktion mit dem array der files als $2
LOOPJOIN ${fid[*]}

mv $TMP_DIR/${breed}.sammellog.LOOPJOINout.txt $TMP_DIR/${breed}.OUTsammellogLD.LOOPJOINout.txt
#awk '{print NF}' $TMP_DIR/${breed}.OUTsammellogLD.LOOPJOINout.txt | sort -T ${SRT_DIR} -u

################################################################################
#F250K umdrehen feld 1 /feld 2 wg fkt.
(cat $TMP_DIR/${breed}F250Kcrossref.collecttrack.srt ;
    cat $TMP_DIR/${breed}F250KcrossrefOLD.collecttrack.srt ) | awk '{print $2,$1";"$3";"$4";"$5";"$6";"$7}' > $TMP_DIR/${breed}.basis.F250Ksammellog.owngenotypeorders.${run}

#update filearray set for HD
fid=$(echo $TMP_DIR/${breed}.basis.F250Ksammellog.owngenotypeorders.${run} ${filearray[@]})
#echo ${fid[*]}

#join aller files mit der Funktion mit dem array der files als $2
LOOPJOIN ${fid[*]}

mv $TMP_DIR/${breed}.sammellog.LOOPJOINout.txt $TMP_DIR/${breed}.OUTsammellogF250K.LOOPJOINout.txt
#awk '{print NF}' $TMP_DIR/${breed}.OUTsammellogF250K.LOOPJOINout.txt | sort -T ${SRT_DIR} -u
	

################################################################################
#777K umdrehen feld 1 /feld 2 wg fkt.
(cat $TMP_DIR/${breed}777Kcrossref.collecttrack.srt ;
    cat $TMP_DIR/${breed}777KcrossrefOLD.collecttrack.srt ) | awk '{print $2,$1";"$3";"$4";"$5";"$6";"$7}' > $TMP_DIR/${breed}.basis.777Ksammellog.owngenotypeorders.${run}

#update filearray set for HD
fid=$(echo $TMP_DIR/${breed}.basis.777Ksammellog.owngenotypeorders.${run} ${filearray[@]})
#echo ${fid[*]}

#join aller files mit der Funktion mit dem array der files als $2
LOOPJOIN ${fid[*]}

mv $TMP_DIR/${breed}.sammellog.LOOPJOINout.txt $TMP_DIR/${breed}.OUTsammellog777K.LOOPJOINout.txt
#awk '{print NF}' $TMP_DIR/${breed}.OUTsammellog777K.LOOPJOINout.txt | sort -T ${SRT_DIR} -u


################################################################################
#50K umdrehen feld 1 /feld 2 wg fkt.
(cat $TMP_DIR/${breed}HDcrossref.collecttrack.srt ;
    cat $TMP_DIR/${breed}HDcrossrefOLD.collecttrack.srt ) | awk '{print $2,$1";"$3";"$4";"$5";"$6";"$7}' > $TMP_DIR/${breed}.basis.HDsammellog.owngenotypeorders.${run}

#update filearray set for HD
fid=$(echo $TMP_DIR/${breed}.basis.HDsammellog.owngenotypeorders.${run} ${filearray[@]})
#echo ${fid[*]}

#join aller files mit der Funktion mit dem array der files als $2
LOOPJOIN ${fid[*]}

mv $TMP_DIR/${breed}.sammellog.LOOPJOINout.txt $TMP_DIR/${breed}.OUTsammellogHD.LOOPJOINout.txt
#awk '{print NF}' $TMP_DIR/${breed}.OUTsammellogHD.LOOPJOINout.txt | sort -T ${SRT_DIR} -u


################################################################################
#Routinekanal externe LD
awk -v outo=${outzo} '{print $1,"-;3228;"outo";-;-;NEU"}' $TMP_DIR/${breed}.NEWexterneSNPLD.${run}.lst > $TMP_DIR/${breed}.ex.LDsammellog.routineexterne.${run}


#update filearray set for LDex
fid=$(echo $TMP_DIR/${breed}.ex.LDsammellog.routineexterne.${run} ${filearray[@]})
#echo ${fid[*]}

#join aller files mit der Funktion mit dem array der files als $2
LOOPJOIN ${fid[*]}

mv $TMP_DIR/${breed}.sammellog.LOOPJOINout.txt $TMP_DIR/${breed}.OUTsammellogLDexR.LOOPJOINout.txt
#awk '{print NF}' $TMP_DIR/${breed}.OUTsammellogLDexR.LOOPJOINout.txt | sort -T ${SRT_DIR} -u


################################################################################
#Routinekanal externe HD
awk -v outo=${outzo} '{print $1,"-;4024;"outo";-;-;NEU"}' $TMP_DIR/${breed}.NEWexterneSNPHD.${run}.lst > $TMP_DIR/${breed}.ex.HDsammellog.routineexterne.${run}

#update filearray set for HDex
fid=$(echo $TMP_DIR/${breed}.ex.HDsammellog.routineexterne.${run} ${filearray[@]})
#echo ${fid[*]}

#join aller files mit der Funktion mit dem array der files als $2
LOOPJOIN ${fid[*]}

mv $TMP_DIR/${breed}.sammellog.LOOPJOINout.txt $TMP_DIR/${breed}.OUTsammellogHDexR.LOOPJOINout.txt
#awk '{print NF}' $TMP_DIR/${breed}.OUTsammellogLDexR.LOOPJOINout.txt | sort -T ${SRT_DIR} -u


################################################################################
#Pedigreeimputierte
join -t' ' -o'1.1 1.2' -v1 -1 1 -2 1 <(sort -T ${SRT_DIR} -t' ' -k1,1 $HIS_DIR/${breed}.RUN${run}.IMPresult.tierlis  ) <(sort -T ${SRT_DIR} -t' ' -k1,1 $HIS_DIR/${breed}.RUN${oldrun}.IMPresult.tierlis) |\
awk -v outo=${outzo}  '{if($2 == 0) print $1,"-;P;"outo";-;-;NEU"}' > $TMP_DIR/${breed}.pd.PDsammellog.pediimputed.${run}


#update filearray set for PDI
fid=$(echo $TMP_DIR/${breed}.pd.PDsammellog.pediimputed.${run} ${filearray[@]})
#echo ${fid[*]}

#join aller files mit der Funktion mit dem array der files als $2
LOOPJOIN ${fid[*]}

mv $TMP_DIR/${breed}.sammellog.LOOPJOINout.txt $TMP_DIR/${breed}.OUTsammellogPD.LOOPJOINout.txt
#awk '{print NF}' $TMP_DIR/${breed}.OUTsammellogPD.LOOPJOINout.txt | sort -T ${SRT_DIR} -u


######################################################################
#jetzt muessen die Ergebnisse aus den Laborchecks eingefuegt werden
for i in callingrate heterorate gcscore; do
for den in HD LD 777K F250K; do
awk -v jj=${j} 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));PC[$1]=$4;}} \
    else {sub("\015$","",$(NF));PCI="0";PCI=PC[$2]; \
    if   (PCI != "") {print $1,$2,$3,$4,$5,$6,$7,$8,$9";"PCI,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29} \
    else             {print $1,$2,$3,$4,$5,$6,$7,$8,$9";NULL",$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29}}}' $TMP_DIR/chcks${breed}/${breed}join.${i}.check.srt $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt > $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txtADDED
mv $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txtADDED $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt
#awk '{print NF}' $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt | sort -T ${SRT_DIR} -u
#awk '{if(NF==27) print}' $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt |head
#echo " "
#awk '{if(NF==29) print}' $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt |head
done
done 


for i in callingrate heterorate gcscore; do
for den in HDexR LDexR; do
#setze dummy maessig alle checks auf OK
awk -v jj=${j} 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));PC[$1]=$4;}} \
    else {sub("\015$","",$(NF));PCI="0";PCI=PC[$1]; \
    if   (PCI != "") {print $1,$2,$3,$4,$5,$6,$7,$8,$9";"PCI,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29} \
    else             {print $1,$2,$3,$4,$5,$6,$7,$8,$9";+",$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29}}}' $TMP_DIR/chcks${breed}/${breed}join.${i}.check.srt $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt > $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txtADDED
mv $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txtADDED $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt
#awk '{print NF}' $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt | sort -T ${SRT_DIR} -u
#awk '{if(NF==27) print}' $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt |head
#echo " "
#awk '{if(NF==29) print}' $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt |head
done
done


for i in callingrate heterorate gcscore; do
den=PD;
awk -v jj=${j} 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));PC[$1]=$4;}} \
    else {sub("\015$","",$(NF));PCI="0";PCI=PC[$1]; \
    if   (PCI != "") {print $1,$2,$3,$4,$5,$6,$7,$8,$9";"PCI,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29} \
    else             {print $1,$2,$3,$4,$5,$6,$7,$8,$9";#",$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29}}}' $TMP_DIR/chcks${breed}/${breed}join.${i}.check.srt $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt > $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txtADDED
mv $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txtADDED $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt
#awk '{print NF}' $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt | sort -T ${SRT_DIR} -u
#awk '{if(NF==27) print}' $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt |head
#echo " "
#awk '{if(NF==29) print}' $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt |head
done


#dazuholen der ITBID
for den in  HDexR LDexR PD HD LD 777K F250K; do
awk -v jj=${j} 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));PC[$1]=$4;}} \
    else {sub("\015$","",$(NF));PCI="0";PCI=PC[$1]; \
    if   (PCI != "") {print $1,$2,PCI,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29} \
    else             {print $1,$2,"#",$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29}}}' $TMP_DIR/${breed}join.animalinfo.join $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt > $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txtADDED
mv $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txtADDED $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt
#awk '{print NF}' $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt | sort -T ${SRT_DIR} -u
#awk '{if(NF==27) print}' $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt |head
#echo " "
#awk '{if(NF==29) print}' $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt |head
done


#dazuholen der AuftragsID SNP_BGA_ID SNP-basierte Abstammungskontrolle
for den in  HDexR LDexR PD HD LD 777K F250K; do
awk -v jj=${j} 'BEGIN{FS=" ";OFS=" "}{ \
    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));PC[$1]=$2;}} \
    else {sub("\015$","",$(NF));PCI="0";PCI=PC[$2]; \
    if   (PCI != "") {print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,PCI} \
    else             {print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,"#"}}}' $TMP_DIR/${breed}_SNP_BGA_ID.srt $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt > $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txtADDED
mv $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txtADDED $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt
#awk '{print NF}' $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt | sort -T ${SRT_DIR} -u
#awk '{if(NF==27) print}' $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt |head
#echo " "
#awk '{if(NF==29) print}' $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt |head
done



#dazuholen der ShortcutRunOfDataEntry  sobald ARGUS so weit ist und ab zeile 301 bis 309 raus nehmen
#for den in  HDexR LDexR PD HD LD 777K F250K; do
#awk -v jj=${j} 'BEGIN{FS=" ";OFS=" "}{ \
#    if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));PC[$1]=$2;}} \
#    else {sub("\015$","",$(NF));PCI="0";PCI=PC[$2]; \
#    if   (PCI != "") {print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,$31,PCI} \
#    else             {print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,$31,"#"}}}' $TMP_DIR/${breed}_ShortcutRunOfDataEntry.txt $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt > $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txtADDED
#mv $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txtADDED $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt
##awk '{print NF}' $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt | sort -T ${SRT_DIR} -u
##awk '{if(NF==27) print}' $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt |head
##echo " "
##awk '{if(NF==29) print}' $TMP_DIR/${breed}.OUTsammellog${den}.LOOPJOINout.txt |head
#done


#ausschreiben alles sammeln inkl umdrehen spalte 1 und spalte 2
#(echo "sampleID;TVD;ITBID;ChipID;ZO;Name;Rasse;Versand;IMPresultALT;IMPresultNEU;Callrate;Heterozygotie;GCScore;Pedigree;MultiVATERmatch;MultiMUTTERmatch;OhneVATERmatch;OhneMUTTERmatch;VaterPedigree;VaterSNP;MutterPedigree;MutterSNP;ChipCurrentIMPTier;ChipCurrentIMPVaterPedigree;ChipCurrentIMPMutterPedigree;ChipCurrentIMPMVPedigree;MVsuspekt;ExterneSNP;PedigreeImputation;SNPTwin;SuspektSex;CHIPADRESSE;VVsuspekt;SAK_BGA;ShortcutRunOfDataEntry"
#for files in $TMP_DIR/${breed}.OUTsammellogLD.LOOPJOINout.txt $TMP_DIR/${breed}.OUTsammellogHD.LOOPJOINout.txt $TMP_DIR/${breed}.OUTsammellogF250K.LOOPJOINout.txt $TMP_DIR/${breed}.OUTsammellog777K.LOOPJOINout.txt $TMP_DIR/${breed}.OUTsammellogHDexR.LOOPJOINout.txt $TMP_DIR/${breed}.OUTsammellogLDexR.LOOPJOINout.txt  $TMP_DIR/${breed}.OUTsammellogPD.LOOPJOINout.txt; do
#sed 's/\;/ /g' ${files} | awk '{x=$1; $1=$2; $2=x; print}' | awk -v outo=${outzo} '{if($5 == outo) print $0}' | awk '{if($9 == "#") $9="-" ;if($10 == "#") $10="-" ;if($14 == "#") $14="+" ; print $0}' |  tr ' ' ';' | sed 's/#//g' | sed 's/&//g'
#done |\
#  awk 'BEGIN{FS=";";OFS=";"}{if($4 == "P") print $1,$2,$3,$4,$5,$6,$7,$8,"","+",$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,$31,$32,$33,$34,$35; else print $0}' |\
#  sort -T ${SRT_DIR} -t';' -k8,8 -k2,2 -k1,1 ) > $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv


(echo "sampleID;TVD;ITBID;ChipID;ZO;Name;Rasse;Versand;IMPresultALT;IMPresultNEU;Callrate;Heterozygotie;GCScore;Pedigree;MultiVATERmatch;MultiMUTTERmatch;OhneVATERmatch;OhneMUTTERmatch;VaterPedigree;VaterSNP;MutterPedigree;MutterSNP;ChipCurrentIMPTier;ChipCurrentIMPVaterPedigree;ChipCurrentIMPMutterPedigree;ChipCurrentIMPMVPedigree;MVsuspekt;ExterneSNP;PedigreeImputation;SNPTwin;SuspektSex;CHIPADRESSE;VVsuspekt;SAK_BGA"
for files in $TMP_DIR/${breed}.OUTsammellogLD.LOOPJOINout.txt $TMP_DIR/${breed}.OUTsammellogHD.LOOPJOINout.txt $TMP_DIR/${breed}.OUTsammellogF250K.LOOPJOINout.txt $TMP_DIR/${breed}.OUTsammellog777K.LOOPJOINout.txt $TMP_DIR/${breed}.OUTsammellogHDexR.LOOPJOINout.txt $TMP_DIR/${breed}.OUTsammellogLDexR.LOOPJOINout.txt  $TMP_DIR/${breed}.OUTsammellogPD.LOOPJOINout.txt; do
sed 's/\;/ /g' ${files} | awk '{x=$1; $1=$2; $2=x; print}' | awk -v outo=${outzo} '{if($5 == outo) print $0}' | awk '{if($9 == "#") $9="-" ;if($10 == "#") $10="-" ;if($14 == "#") $14="+" ; print $0}' |  tr ' ' ';' | sed 's/#//g' | sed 's/&//g'
done |\
  awk 'BEGIN{FS=";";OFS=";"}{if($4 == "P") print $1,$2,$3,$4,$5,$6,$7,$8,"","+",$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,$31,$32,$33,$34; else print $0}' |\
  sort -T ${SRT_DIR} -t';' -k8,8 -k2,2 -k1,1 ) > $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv


nCols=$(awk 'BEGIN{FS=";"}{print NF}' $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv | sort -T ${SRT_DIR} -u | wc -l)
if [ ${nCols} != 1 ]; then echo "OOOPS: ...not all record in $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv  have identical no of columns. Check immediately!!!!"; exit 1; fi


if [ ${breed} == "HOL" ] ; then
echo "Upload to ftp for SHZV + Copy to $DEUTZ_DIR/zws fuer ARGUS JOBID 225 (BRUNANET) bzw. 226 (Redonline)"
sed -i 's/$/\;/g' $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv;
$BIN_DIR/ftpUploadOf1File.sh -f ${breed}_SammelLOG-${run}.csv -o ${ZOMLD_DIR} -z ImputierungHolstein
if [ ${sendMails} == "Y" ]; then
$BIN_DIR/sendMailToDataRecipient.sh ${breed} ${breed}_SammelLOG-${run}.csv
else
echo "Mailversand was defined as ${sendMails}"
fi
cp $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv $DEUTZ_DIR/${outfolder}/dsch/in/.
if [ ${sendMails} == "Y" ]; then
$BIN_DIR/sendMailToInhouseDataRecipient.sh ${breed} ${breed}_SammelLOG-${run}.csv
else
echo "Mailversand was defined as ${sendMails}"
fi
else
sed -i 's/$/\;/g' $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv;
cp $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv $DEUTZ_DIR/${outfolder}/dsch/in/.
if [ ${breed} == "VMS" ]; then
echo "Extra copy due to Evolener which are in VMS System to Swissherdbook"
cp $ZOMLD_DIR/${breed}_SammelLOG-${run}.csv $DEUTZ_DIR/swissherdbook/dsch/in/.
fi
if [ ${sendMails} == "Y" ]; then
$BIN_DIR/sendMailToInhouseDataRecipient.sh ${breed} ${breed}_SammelLOG-${run}.csv
else
echo "Mailversand was defined as ${sendMails}"
fi
fi




echo " "
RIGHT_END=$(date +"%x %r %Z")
echo $RIGHT_END Ende ${SCRIPT}
