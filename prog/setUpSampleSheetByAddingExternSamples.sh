#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "
# v2 version can handle also that GeneSeek wants to include "Yes" instead of "X" for ordered tests
###########
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###########
set -o nounset
set -o errexit

##########################################################################################
# Funktionsdefinition

# Funktion gibt Spaltennummer gemaess Spaltenueberschrift in csv-File zurueck.
# Es wird erwartet, dass das Trennzeichen das Semikolon (;) ist
getColmnNr () {
# $1: String der Spaltenueberschirft repraesentiert
# $2: csv-File
    colNr_=$(awk '{ sub("\r$", ""); print }' ${2} | awk 'BEGIN{FS=";";OFS=";"}{if(NR == 1) print}' | tr ';' '\n' | awk -v look=${1} '{gsub("#"," ",look);if($0  ~ look) print NR}')
    if test -z $colNr_ ; then
        echo "FEHLER: Spalte mit den Namen $1 existiert nicht in $2 --> PROGRAMMABBRUCH"
        echo "... oder Trennzeichen in $2 ist nicht das Semikolon (;)"
        exit 1
    fi
}

##########################################################################################

#Ziel:
#sampleID;150K;HD;LD;LEER;F250K;
#15 TVD
#16 ZO


#if chip change their name -> correct the records below right here. Wenn leerschlag im header dann muss es hier als # angegeben werden
#finale Idee: rausnehmen ins parameterfile
#get Info about SNP from Samplesheet
getColmnNr "GGP_Bovine50K"         $WRK_DIR/currentSamplesheet/$crossreffile ; colLD=$colNr_
getColmnNr "BOV_uHD_150k_T"        $WRK_DIR/currentSamplesheet/$crossreffile ; colMD=$colNr_
getColmnNr "BOV_HD_T"              $WRK_DIR/currentSamplesheet/$crossreffile ; colHD=$colNr_
getColmnNr "GGP_F250_Tissue-R&D"   $WRK_DIR/currentSamplesheet/$crossreffile ; colFD=$colNr_
getColmnNr "Animal#ID"             $WRK_DIR/currentSamplesheet/$crossreffile ; colTVD=$colNr_
getColmnNr "BarCode"               $WRK_DIR/currentSamplesheet/$crossreffile ; colBCD=$colNr_
getColmnNr "Breeding#organisation" $WRK_DIR/currentSamplesheet/$crossreffile ; colZO=$colNr_
getColmnNr "Sex"                   $WRK_DIR/currentSamplesheet/$crossreffile ; colSX=$colNr_
getColmnNr "ABSTKTR"               $WRK_DIR/currentSamplesheet/$crossreffile ; colAK=$colNr_
getColmnNr "Rasse"                 $WRK_DIR/currentSamplesheet/$crossreffile ; colRS=$colNr_
getColmnNr "Name"                  $WRK_DIR/currentSamplesheet/$crossreffile ; colNM=$colNr_
getColmnNr "Sample#Type"           $WRK_DIR/currentSamplesheet/$crossreffile ; colST=$colNr_
#echo ${colMD} ${colHD} ${colLD} ${colFD} ${colBCD} ${colZO} ${colTVD} ${colAK} ${colRS} ${colNM}

#if ! test -s $WORK_DIR/currentSamplesheet/$crossreffile ;then
echo "das folgende Samplesheet liegt bereit"
ls -trl $WRK_DIR/currentSamplesheet/$crossreffile

#suche headerzeile
startat=$(awk '{ sub("\r$", ""); print }'  $WRK_DIR/currentSamplesheet/$crossreffile | grep -n "GGP_F250_Tissue-R&D" | awk -F":" '{print $1}')
echo " "
echo "check if one TVD has several records for the same chip. this is not allowed since Chip is defined later on depending on No of SNPs per TVD . These samples will be parked later in $LOG_DIR"
echo " "

for hip in ${colMD} ${colHD} ${colLD} ${colFD}; do
nlinesBad=$(awk '{ sub("\r$", ""); print }'  $WRK_DIR/currentSamplesheet/$crossreffile | awk -v colChip=${hip} -v start=${startat} -v colA=${colTVD} 'BEGIN{FS=";"}{if(NR > start && $colA != "" && $colChip != "") print $colChip,$colA}' |\
sort | uniq -c | awk '{if($1 > 1) print}' | wc -l | awk '{print $1}')
if [ ${nlinesBad} -gt 0 ]; then
echo "I have to remove samples since they have more than one record for the same chip in $crossreffile"
echo "The follwing record TVDs deleted and the sampleID will end up later in $LOG_DIR/...UNKNOWN..."
awk '{ sub("\r$", ""); print }' $WRK_DIR/currentSamplesheet/$crossreffile | awk -v colChip=${hip} -v start=${startat} -v colA=${colTVD} 'BEGIN{FS=";"}{if(NR > start && $colA != "" && $colChip != "") print $colChip,$colA}' |\
sort | uniq -c | awk '{if($1 > 1) print}';
badSamples=$(awk '{ sub("\r$", ""); print }' $WRK_DIR/currentSamplesheet/$crossreffile | awk -v colChip=${hip} -v start=${startat} -v colA=${colTVD} 'BEGIN{FS=";"}{if(NR > start && $colA != "" && $colChip != "") print $colChip,$colA}' |\
sort | uniq -c | awk '{if($1 > 1) print $3}')
for j in ${badSamples} ; do
sed -i "s/${j}//g" $WRK_DIR/currentSamplesheet/$crossreffile;
done
else
echo " "
echo "Everything seem to be ok, I do not have several records for the same TVD-chip combination"
echo " "
fi
done

        echo "Skript haengt jetze das file $WRK_DIR/allExternSamples_forAdding.txt ans ${crossreffile}" 

    if ! test -s $WRK_DIR/allExternSamples_forAdding.${run}.txt ; then
       touch $WRK_DIR/allExternSamples_forAdding.${run}.txt
    fi	
    
    

#umformatieren Samplesheet auf die Zielstruktur
# 1 sampleID
# 2 150K
# 3 HD
# 4 LD
# 6 F250K
#15 TVD
#16 ZO
#17 Name
#19 Rasse
#24 ABSTKTR
#25 Sample Type

	(awk '{ sub("\r$", ""); print }'  $WRK_DIR/currentSamplesheet/$crossreffile |\
	  awk -v start=${startat} -v c1=${colMD} -v c2=${colHD} -v c3=${colLD} -v c4=${colFD} -v s=${colBCD}  -v t=${colTVD} -v zo=${colZO} -v mn=${colNM} -v sr=${colRS}  -v ak=${colAK} -v st=${colST} 'BEGIN{FS=";";OFS=";"}{if (NR == start) print $s,$c1,$c2,$c3,"",$c4,"","","","","","","","",$t,$zo,$mn,"",$sr,"","","","",$ak,$st}'
	 awk '{ sub("\r$", ""); print }'  $WRK_DIR/currentSamplesheet/$crossreffile |\
	  awk -v start=${startat} -v c1=${colMD} -v c2=${colHD} -v c3=${colLD} -v c4=${colFD} -v s=${colBCD}  -v t=${colTVD} -v zo=${colZO} -v mn=${colNM} -v sr=${colRS}  -v ak=${colAK} -v st=${colST} 'BEGIN{FS=";";OFS=";"}{gsub("Yes","X",$c1);gsub("Yes","X",$c2);gsub("Yes","X",$c3);gsub("Yes","X",$c4);if (NR >  start) print $s,$c1,$c2,$c3,"",$c4,"","","","","","","","",$t,$zo,$mn,"",$sr,"","","","",$ak,$st}' |\
      sed 's/\;1\;/\;SBZV\;/g' |\
      sed 's/\;2\;/\;SHSF\;/g' |\
      sed 's/\;3\;/\;SHSF\;/g' |\
      sed 's/\;4\;/\;SHSF\;/g' |\
      sed 's/\;5\;/\;SHSF\;/g' |\
      sed 's/\;6\;/\;VMS\;/g' |\
      awk 'BEGIN{FS=";";OFS=";"}{if($15 ~ "[A-Z]") print}';
     cat $WRK_DIR/allExternSamples_forAdding.${run}.txt;) > $TMP_DIR/crossref.txt
     mv $TMP_DIR/crossref.txt $WRK_DIR/currentSamplesheet/$crossreffile	

    echo "schreibe zentrale Umkodierungsliste jetzt"
    (awk '{ sub("\r$", ""); print }'  $WRK_DIR/currentSamplesheet/$crossreffile |\
    sed 's/\;1\;/\;SBZV\;/g' |\
    sed 's/\;2\;/\;SHSF\;/g' |\
    sed 's/\;3\;/\;SHSF\;/g' |\
    sed 's/\;4\;/\;SHSF\;/g' |\
    sed 's/\;5\;/\;SHSF\;/g' |\
    sed 's/\;6\;/\;VMS\;/g' |\
    awk 'BEGIN{FS=";"}{if($15 ~ "[A-Z]") print}';
    awk '{ sub("\r$", ""); print }'  $WRK_DIR/previousSamplesheets/*.txt |\
    sed 's/\;1\;/\;SBZV\;/g' |\
    sed 's/\;2\;/\;SHSF\;/g' |\
    sed 's/\;3\;/\;SHSF\;/g' |\
    sed 's/\;4\;/\;SHSF\;/g' |\
    sed 's/\;5\;/\;SHSF\;/g' |\
    sed 's/\;6\;/\;VMS\;/g' ;) |\
    awk 'BEGIN{FS=";"}{if($15 ~ "[A-Z]") print}' |\
    sort -u > $WORK_DIR/crossref.txt


	(awk '{ sub("\r$", ""); print }'  $WRK_DIR/currentSamplesheet/$crossreffile |\
    sed 's/\;1\;/\;SBZV\;/g' |\
    sed 's/\;2\;/\;SHSF\;/g' |\
    sed 's/\;3\;/\;SHSF\;/g' |\
    sed 's/\;4\;/\;SHSF\;/g' |\
    sed 's/\;5\;/\;SHSF\;/g' |\
    sed 's/\;6\;/\;VMS\;/g' ;
    awk '{ sub("\r$", ""); print }'  $WRK_DIR/previousSamplesheets/*.txt |\
    sed 's/\;1\;/\;SBZV\;/g' |\
    sed 's/\;2\;/\;SHSF\;/g' |\
    sed 's/\;3\;/\;SHSF\;/g' |\
    sed 's/\;4\;/\;SHSF\;/g' |\
    sed 's/\;5\;/\;SHSF\;/g' |\
    sed 's/\;6\;/\;VMS\;/g' ;) |\
    sort -u |\
    cut -d';' -f15,16 | sed 's/\;$/\;7/g' | tr ';' ' ' | awk '{if($2 == "SBZV") print $1,$2,"BSW"; \
          else if($2 == "SHSF") print  $1,$2,"HOL"; \
          else if($2 == "SHSF") print  $1,$2,"HOL"; \
          else if($2 == "SHSF") print  $1,$2,"HOL"; \
          else if($2 == "SHSF") print  $1,$2,"HOL"; \
          else if($2 == "VMS") print  $1,$2,"VMS"; \
          else print $1,$2,"OTHER"}' > $TMP_DIR/crossref.race
echo " "
echo "${LOG_DIR} is as follows:"
ls -trl ${LOG_DIR}/
echo " "

echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
