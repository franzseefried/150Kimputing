#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT} 
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################
set -o nounset
set -o errexit

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
#noetig da spaeter angefragt wird ob es existiert
rm -f $RES_DIR/${breed}*_haplotype.indx 


###Defintion der Function zum Joinen######################################################
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
fileEINS=$TMP_DIR/${breed}.sammelhap.LOOPJOINout.txt
fi

#echo "$i ; ${fileEINS} ; ${Iarr[i]}"
#echo " "
awk 'BEGIN{FS=" "}{if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));status[$1]=$2;}}  \
    else {sub("\015$","",$(NF));STAT="0";STAT=status[$1]; \
    if(STAT != ""){print $1,$2,STAT} \
    if(STAT == ""){print $1,$2,"#"}}}' ${Iarr[i]} ${fileEINS} | sed 's/ /\;/2' > $TMP_DIR/${breed}.sammelhapT.LOOPJOINout.tmp
mv $TMP_DIR/${breed}.sammelhapT.LOOPJOINout.tmp $TMP_DIR/${breed}.sammelhap.LOOPJOINout.txt
#cat $TMP_DIR/${breed}.sammelhap.LOOPJOINout.txt

done
sed -i 's/\;/ /g' $TMP_DIR/${breed}.sammelhap.LOOPJOINout.txt
}
##########################################################################################
getColmnNrSemicl () {
# $1: String der Spaltenueberschirft repraesentiert
# $2: csv-File
    colNr_=$(head -1 $2 | tr ';' '\n' | awk '{print NR,$1}' | awk -v z=${1} '{if($2 == z) print $1}')
    if test -z $colNr_ ; then
        echo "FEHLER: Spalte mit den Namen $1 existiert nicht in $2 --> PROGRAMMABBRUCH"
        echo "... oder Trennzeichen in $2 ist nicht das Semikolon (;)"
        exit 1
    fi
}
##########################################################################################

#voebereiten der extra files 
if [ ${breed} == "BSW" ]; then
pdg="bv"
datp=${DatPEDIbvch}
fi
if [ ${breed} == "HOL" ]; then
pdg="rh"
datp=${DatPEDIshb}
fi

awk '{ sub("\r$", ""); print }' ${HIS_DIR}/${breed}_SumUpLOG.${run}.csv | cut -d';' -f1-3 | sed 's/ //g' | sed 's/\;\;/\;NA\;/g' | tr ';' ' ' | awk '{print $2,$1";"$3}' |\
sort -T ${SRT_DIR} -t' ' -k1,1 | join -t' ' -o'1.1 1.2' -1 1 -2 1 - <(sort -T ${SRT_DIR} -t' ' -k1,1 $HIS_DIR/${breed}.RUN${run}.IMPresult.tierlis)                                                  > $TMP_DIR/${breed}.sumup.sort.forHSSMRY.txt
awk '{ sub("\r$", ""); print }' ${HIS_DIR}/${breed}_SumUpLOG.${run}.csv | cut -d';' -f2,16 | sed 's/ //g' | sed 's/\;\;/\;NA\;/g' | tr ';' ' '                           > $TMP_DIR/${breed}.chip.sort.forHSSMRY.txt
awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | cut -d';' -f2,5 | sed 's/ //g' | sed 's/\;\;/\;NA\;/g' | tr ';' ' '                                      > $TMP_DIR/${breed}.gebdat.sort.forHSSMRY.txt
awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | cut -d';' -f2,7 | sed 's/ //g' | sed 's/\;\;/\;NA\;/g' | tr ';' ' '                                      > $TMP_DIR/${breed}.info.sort.forHSSMRY.txt
awk '{ sub("\r$", ""); print }' $WRK_DIR/UniBernGenotypes.csv | sed 's/ //g' | tr ';' ' ' | awk '{print $3,$1}'                                                          > $TMP_DIR/${breed}.unibern.sort.forHSSMRY.txt
awk '{print $6,$8,$9}' ${PEDI_DIR}/work/${pdg}/RenumMergedPedi_${datp}.txt | awk '{print $1,$2";"$3}'                                                                    > $TMP_DIR/natped.sort.forHSSMRY.txt
awk '{ sub("\r$", ""); print }' $WRK_DIR/Lager_20140131_Swissgenetics.txt | sed 's/ /_/g' | awk 'BEGIN{FS=";"}{print $2,$8}'                                             > $TMP_DIR/${breed}.Swissgenetics.sort.forHSSMRY.txt
awk '{ sub("\r$", ""); print }' $WRK_DIR/SeqStiere_ZuordnungStatistik.csv | sed 's/ /_/g' | awk 'BEGIN{FS=";"}{print $1,$6}'                                             > $TMP_DIR/${breed}.sequence.sort.forHSSMRY.txt
awk '{ sub("\r$", ""); print }' $WRK_DIR/Lager_20141127_Droegemueller.rebuilt.txt | sed 's/ /_/g' | awk 'BEGIN{FS=";"}{print $9,$1}'                                     > $TMP_DIR/${breed}.droegemueller1.sort.forHSSMRY.txt
awk '{ sub("\r$", ""); print }' $WRK_DIR/Lager_20141127_Droegemueller.rebuilt.txt | sed 's/ /_/g' | awk 'BEGIN{FS=";"}{print $9,$2}'                                     > $TMP_DIR/${breed}.droegemueller2.sort.forHSSMRY.txt
#Liste von Mirjam 1000Bull
awk '{ sub("\r$", ""); print }' $WRK_DIR/1000BullGenomesAnimalListDistRun6-Taurus-20170314.csv | awk 'BEGIN{FS=";"}{print substr($1,1,3),substr($1,4,16),$2}' |sort -T ${SRT_DIR} -t' ' -k2,2 | join -t' ' -o'2.1 1.3' -1 2 -2 2 - <(cut -d';' -f2,3 $WORK_DIR/animal.overall.info | awk 'BEGIN{FS=";";OFS=" "}{print $1,substr($2,4,16)}'| sort -T ${SRT_DIR} -t' ' -k2,2)  > $TMP_DIR/${breed}.1KBull.forHSSMRY.txt
awk '{ sub("\r$", ""); print }' $WRK_DIR/OB_ETH_StiereSequenziert.txt  > $TMP_DIR/${breed}.OB.ETHZ.Pausch.forHSSMRY.txt
#Liste von Mirjam mit den Stieren die fuer CDDR im Rahmen des Consortiums sequenziert werden sollen
awk '{ sub("\r$", ""); print }' $WRK_DIR/CHE_CDDRcons_ForSequencingSelection_available_fin.txt | awk 'BEGIN{FS=";"}{print $2" ForSeqCDDR"}' > $TMP_DIR/${breed}.CHEforSeqCDDR.forHSSMRY.txt

#AUfbau des arrays mit den files leider funktioniert die Definition des arrays nicht via Abfrage auf das directory
if [ ${breed} == "BSW" ]; then
pops="BV OB"
fi
if [ ${breed} == "HOL" ]; then
pops="HO SI"
fi
if [ ${1} == "VMS" ] ; then
echo "${SCRIPT} laeuft noch nicht fuer ${1}..."
exit 1
fi
echo "${SCRIPT} laeuft fuer ${breed}..."
for pp in ${pops}; do
filearray=
bezarray=
########################################################################################################################################################
#Defintion der BV Regions muss fix erfolgen, da es nirgends her geholt werden kann. Wenn ein Defekt ergänzt wird muss er hier rechts eingetragen werden. und zwar die der Code aus der Hapotypisierung bei Haplotypen. Code Kennung bei SingleGeneImputation
#Achtung unten muss es beim estimate ebenso eingetragen werden!!!!
if [ ${pp} == "BV" ]; then
Gregions="2-85-91 5-21-27 7-40-44 13-43-44 13-51-57 21-19-21 25-11-13 27-22-27 19-BH2 1-7-14 4-54-55 1-10-15 2-86-88 5-59-64 5-70-74 7-42-43 10-35-42 12-24-35 13-22-28 21-2-5 21-18-20 22-14-19 23-39-46 29-35-38 22-wF SMA SDM ARA P BE WE 629-RYF BK1 BK2 BLG"
fi
if [ ${pp} == "OB" ]; then
Gregions="1-28-29 1-FH2 5-72-74 11-104-105 14-12-17 14-46-48 13-22-25 17-55-60 20-65-66 1-25-27 4-44-47 5-65-66 5-67-69 5-79-83 6-64-72 14-10-16 20-58-62 23-27-31 24-RD 629-RYF BE"
fi
if [ ${pp} == "HO" ]; then
Gregions="1-HH2 11-CDH 18-DCM 2-13-15 2-56-60 6-7-14 7-10-18 9-HH5 11-52-56 12-70-77 2-5-7 25-0-8 23-24-32 18-58-62 16-13-23 21-21-23 23-13-23 21-48-56 15-MF HH1 HH3 HH4 CV BL BY P 7-MG 16-HH6 2-12-15 2-57-59 2-7-9 3-18-23 5-61-65 6-4-9 6-12-14 7-1-5 7-6-20 8-92-100 8-25-40 9-89-94 10-7-11 11-50-55 12-66-68 13-14-20 16-20-24 18-58-64 21-19-22 21-41-49 21-58-61 21-67-69 23-36-40 25-0-3 25-27-29 26-55-84 27-17-22 VR e ED BR BK1 BK2 BLG"
fi
if [ ${pp} == "SI" ]; then
Gregions="5-18-19 14-20-22 20-23-24 5-16-20 14-16-17 15-43-47 TP"
fi

for qq in ${Gregions};do
getColmnNrSemicl Kennung ${REFTAB_SiTeAr} ; colA=$colNr_
fileSTART=$(ls ${RES_DIR}/RUN${run}${breed}.${qq}.*[A-z])
filearray=$(echo ${filearray} ${fileSTART})
#ableiten der Bezeichnung fuer den header fuer jeden defekt
getColmnNrSemicl IMPbreedsWhereTestSegregates ${REFTAB_SiTeAr} ; colC=$colNr_
if [[ ${fileSTART} =~ "haploCOUNTS" ]]; then
getColmnNrSemicl CodeHaplotyping ${REFTAB_SiTeAr} ; colB=$colNr_
bezSTART=$(awk -v Acol=${colA} -v Bcol=${colB} -v inbez=${qq} -v Ccol=${colC} -v brd=${breed} 'BEGIN{FS=";"}{if($Ccol ~ brd && $Bcol == inbez) print $Acol}' ${REFTAB_SiTeAr})
fi
if [[ ${fileSTART} =~ "singleGeneImputation" ]]; then
getColmnNrSemicl CodeSingleGeneImputation ${REFTAB_SiTeAr} ; colB=$colNr_
bezSTART=$(awk -v Acol=${colA} -v Bcol=${colB} -v inbez=${qq} -v Ccol=${colC} -v brd=${breed} 'BEGIN{FS=";"}{if($Ccol ~ brd && $Acol == inbez) print $Bcol}' ${REFTAB_SiTeAr})
fi
bezarray=$(echo ${bezarray} ${bezSTART})


done
#update arrays anhaengen der extra files die oben vorbereitet worden sind
filearray=$(echo $TMP_DIR/${breed}.sumup.sort.forHSSMRY.txt $TMP_DIR/${breed}.chip.sort.forHSSMRY.txt $TMP_DIR/${breed}.gebdat.sort.forHSSMRY.txt ${filearray} $TMP_DIR/${breed}.info.sort.forHSSMRY.txt $TMP_DIR/${breed}.unibern.sort.forHSSMRY.txt $TMP_DIR/natped.sort.forHSSMRY.txt $TMP_DIR/${breed}.Swissgenetics.sort.forHSSMRY.txt $TMP_DIR/${breed}.sequence.sort.forHSSMRY.txt $TMP_DIR/${breed}.droegemueller1.sort.forHSSMRY.txt $TMP_DIR/${breed}.droegemueller2.sort.forHSSMRY.txt $TMP_DIR/${breed}.1KBull.forHSSMRY.txt $TMP_DIR/${breed}.OB.ETHZ.Pausch.forHSSMRY.txt $TMP_DIR/${breed}.CHEforSeqCDDR.forHSSMRY.txt)
bezarray=$(echo TVD idanimal ITBID ChipDensity GebDat ${bezarray} SireTVD SampleIDCord Rasse CodeAktivInaktiv SwissgeneticsLager Bamfile rnr-UniBern VZG-UniBern 1000BullBreed OB_ETHZ HOLCHECDDRseq)
#filearray=$(echo $TMP_DIR/${breed}.sumup.sort.forHSSMRY.txt $TMP_DIR/${breed}.chip.sort.forHSSMRY.txt )
#echo ${filearray}
#echo " "
#echo ${bezarray}


##join aller files mit der Funktion mit dem array der files als $2
LOOPJOIN ${filearray[*]}

mv $TMP_DIR/${breed}.sammelhap.LOOPJOINout.txt $TMP_DIR/${breed}.OUTsammelhap${pp}.LOOPJOINout.txt

#ausschreiben des finalen summary, ausrechnen wieviele regionen + anzahl leading colums + eretzen der missing als "frei" -> 0
nREG=$(echo $Gregions | awk '{print NF+5}')
#echo $nREG ${pp}
(echo ${bezarray};
sed 's/#/0/g' $TMP_DIR/${breed}.OUTsammelhap${pp}.LOOPJOINout.txt) > $RES_DIR/${breed}-${run}-${pp}_haplotype.smry



echo " "
echo "Distribution of Diplo-/Genotypecalls per Locus for ${pp}"
for i in $(seq 6 1 ${nREG}); do cut -d' ' -f$i $RES_DIR/${breed}-${run}-${pp}_haplotype.smry |sort|uniq -c; echo " "; done
echo " "




echo "Estimate EBVs"
if [ ${pp} == "BV" ]; then
GregionsH=" 2-85-91 5-21-27 7-40-44 13-43-44 13-51-57 21-19-21 25-11-13 27-22-27 19-BH2 1-7-14 4-54-55 1-10-15 2-86-88 5-59-64 5-70-74 7-42-43 10-35-42 12-24-35 13-22-28 21-2-5 21-18-20 22-14-19 23-39-46 29-35-38 22-wF 629-RYF"
GregionsS="BELTSNP SMASNP SDMSNP ARASNP POLLED202BPINDEL PNPLA8SNP CSN2_AB CSN2_A1A2 BLG_AA"
fi
if [ ${pp} == "OB" ]; then
GregionsH="1-28-29 1-FH2 5-72-74 11-104-105 14-12-17 14-46-48 13-22-25 17-55-60 20-65-66 1-25-27 4-44-47 5-65-66 5-67-69 5-79-83 6-64-72 14-10-16 20-58-62 23-27-31 24-RD 629-RYF"
GregionsS="BELTSNP"
fi
if [ ${pp} == "HO" ]; then
GregionsH="1-HH2 11-CDH 18-DCM 2-13-15 2-56-60 6-7-14 7-10-18 9-HH5 11-52-56 12-70-77 2-5-7 25-0-8 23-24-32 18-58-62 16-13-23 21-21-23 23-13-23 21-48-56 15-MF 7-MG 16-HH6 2-12-15 2-57-59 2-7-9 3-18-23 5-61-65 6-4-9 6-12-14 7-1-5 7-6-20 8-92-100 8-25-40 9-89-94 10-7-11 11-50-55 12-66-68 13-14-20 16-20-24 18-58-64 21-19-22 21-41-49 21-58-61 21-67-69 23-36-40 25-0-3 25-27-29 26-55-84 27-17-22"
GregionsS="HH1SNP HH3SNP HH4SNP CVMSNP BLADSNP FANCI3.3KBDEL POLLED80KBDEL MC1R COPASNP MC1R3581 MC1REBR2 CSN2_AB CSN2_A1A2 BLG_AA"
fi
if [ ${pp} == "SI" ]; then
GregionsH="5-18-19 14-20-22 20-23-24 5-16-20 14-16-17 15-43-47"
GregionsS="RASGRP2SNP"
fi
#hier CodeHaplotyping eintragen.
for ll in ${GregionsH}; do
$BIN_DIR/estimateEBVsingleLoci.sh -b ${breed} -d ${ll} -p ${pp}
done
grep ChipCurrentIMPTier ${RES_DIR}/${breed}-${run}-${pp}_haplotype.indx 
for ll in ${GregionsS}; do
$BIN_DIR/estimateEBVsingleGene.sh -b ${breed} -d ${ll} -p ${pp}
done

grep ChipCurrentIMPTier ${RES_DIR}/${breed}-${run}-${pp}_haplotype.indx 
echo "Calc Genetic Load Index"
$BIN_DIR/calcGeneticIndex.sh -b ${breed} -p ${pp}
#cat $BIN_DIR/plotTrendGeneticIndex.R | sed "s/XXXXXXXXXX/${breed}/g" | sed "s/YYYYYYYYYY/${run}/g" | sed "s/ZZZZZZZZZZ/${pp}/g" > $TMP_DIR/plTrGeIn${breed}.R
#chmod 777 $TMP_DIR/plTrGeIn${breed}.R
#Rscript $TMP_DIR/plTrGeIn${breed}.R 2>&1
cat $BIN_DIR/ggplotTrendGeneticIndex.R | sed "s/XXXXXXXXXX/${breed}/g" | sed "s/YYYYYYYYYY/${run}/g" | sed "s/ZZZZZZZZZZ/${pp}/g" > $TMP_DIR/plTrGeIn${breed}.R
chmod 777 $TMP_DIR/plTrGeIn${breed}.R
Rscript $TMP_DIR/plTrGeIn${breed}.R 2>&1

done


echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}


