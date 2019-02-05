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

#aufbau der zusatzfiles
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



#get Info about SNP from Reftab
getColmnNrSemicl ExtractGenotypesFromChipData ${REFTAB_SiTeAr} ; colEXG=$colNr_
getColmnNrSemicl CodeResultfile ${REFTAB_SiTeAr} ; colCSGI=$colNr_
getColmnNrSemicl BTA ${REFTAB_SiTeAr} ; colGSB=$colNr_
getColmnNrSemicl PredictionAlgorhithm ${REFTAB_SiTeAr} ; colABAASGI=$colNr_
getColmnNrSemicl IMPbreedsWhereTestSegregates ${REFTAB_SiTeAr} ; colIMPBRD=$colNr_
#schau was alles gemacht wurde, ich gehe hier also auf die files und nicht auf das parameterfile REFTAB_SiTeAr
declare -a algis=$(awk -v a=${colABAASGI} -v b=${colCSGI} -v c=${colIMPBRD} -v d=${breed} 'BEGIN{FS=";"}{if($c ~ d) print $a}' ${REFTAB_SiTeAr} | sort -u | grep \[A-Z\] |tr '\n' ' ')
halist=$(cat $TMP_DIR/${breed}.[A-Z]*.selected | tr '\n' ' ')
#echo $halist
#aufbau der regionsliste
Gregions=$(for iha in ${halist[@]}; do basename $RES_DIR/RUN${run}${breed}.${iha}.*[A-Z] | cut -d'.' -f2; done)
#echo $Gregions



filearray=
bezarray=
########################################################################################################################################################
for qq in ${Gregions};do
   getColmnNrSemicl Kennung ${REFTAB_SiTeAr} ; colA=$colNr_
   fileSTART=$(ls ${RES_DIR}/RUN${run}${breed}.${qq}.*[A-Z])
   filearray=$(echo ${filearray} ${fileSTART})
   #ableiten der Bezeichnung fuer den header fuer jeden defekt
   getColmnNrSemicl IMPbreedsWhereTestSegregates ${REFTAB_SiTeAr} ; colC=$colNr_
   getColmnNrSemicl CodeResultfile ${REFTAB_SiTeAr} ; colB=$colNr_
#alt ARGUS bezeichnung im header   bezSTART=$(awk -v Acol=${colA} -v Bcol=${colB} -v inbez=${qq} -v Ccol=${colC} -v brd=${breed} 'BEGIN{FS=";"}{if($Ccol ~ brd && $Bcol == inbez) print $Acol}' ${REFTAB_SiTeAr})
   bezSTART=$(awk -v Acol=${colA} -v Bcol=${colB} -v inbez=${qq} -v Ccol=${colC} -v brd=${breed} 'BEGIN{FS=";"}{if($Ccol ~ brd && $Bcol == inbez) print $Bcol}' ${REFTAB_SiTeAr})
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

mv $TMP_DIR/${breed}.sammelhap.LOOPJOINout.txt $TMP_DIR/${breed}.OUTsammelhap${breed}.LOOPJOINout.txt

#ausschreiben des finalen summary, ausrechnen wieviele regionen + anzahl leading colums + eretzen der missing als "frei" -> 0
nREG=$(echo $Gregions | awk '{print NF+5}')
#echo $nREG ${pp}
(echo ${bezarray};
sed 's/#/0/g' $TMP_DIR/${breed}.OUTsammelhap${breed}.LOOPJOINout.txt) > $RES_DIR/GTpredictionSummary-${breed}-${run}.txt



echo " "
echo "Distribution of Diplo-/Genotypecalls per Locus for ${breed}"
for i in $(seq 6 1 ${nREG}); do awk -v j=${i} '{if(NR == 1)print "#######"$j,"START"}' $RES_DIR/GTpredictionSummary-${breed}-${run}.txt; awk -v j=${i} '{if(NR > 1) print $j}' $RES_DIR/GTpredictionSummary-${breed}-${run}.txt |sort|uniq -c | sort -k2,2n; awk -v j=${i} '{if(NR == 1)print "#######"$j,"ENDE"}' $RES_DIR/GTpredictionSummary-${breed}-${run}.txt; done
echo " "



echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}


