#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

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

#umformatieren Samplesheet auf die Zielstruktur
# 1 sampleID
# 2 150K
# 3 HD
# 4 LD
# 6 F250K
#14 Sex
#15 TVD
#16 ZO
#17 Name
#19 Rasse
#24 ABSTKTR
#25 Sample Type



#define if there are new original samplesheets in the directory
cd $WRK_DIR/currentSamplesheet/
declare -a filearray=$(find . -type f -name "Sample_Submission_QUALITAS_*" -exec basename {} \;)
echo " "
#wenn es originale files hat:
if [ ${#filearray} -gt 0 ]; then
	echo "the followoing original samplesheets are there"
	echo ${filearray}
    #echo ${#filearray[@]}
    ## Save the 1st element as itemN
    itemN=$(echo ${filearray} | awk '{if(NR == 1) print $1}')
    #echo ${itemN}

    for ifile in $(echo "${filearray[@]}"); do
        #echo $ifile $itemN
        echo " "
        getColmnNr "GGP_Bovine50K"         ${ifile} ; colLD=$colNr_
        getColmnNr "BOV_uHD_150k_T"        ${ifile} ; colMD=$colNr_
        getColmnNr "BOV_HD_T"              ${ifile} ; colHD=$colNr_
        getColmnNr "GGP_F250_Tissue-R&D"   ${ifile} ; colFD=$colNr_
        getColmnNr "Animal#ID"             ${ifile} ; colTVD=$colNr_
        getColmnNr "BarCode"               ${ifile} ; colBCD=$colNr_
        getColmnNr "Breeding#organisation" ${ifile} ; colZO=$colNr_
        getColmnNr "Sex"                   ${ifile} ; colSX=$colNr_
        getColmnNr "ABSTKTR"               ${ifile} ; colAK=$colNr_
        getColmnNr "Rasse"                 ${ifile} ; colRS=$colNr_
        getColmnNr "Name"                  ${ifile} ; colNM=$colNr_
        getColmnNr "Sample#Type"           ${ifile} ; colST=$colNr_
        #echo ${colMD} ${colHD} ${colLD} ${colFD} ${colBCD} ${colZO} ${colTVD} ${colAK} ${colRS} ${colNM} ${colST}
        
        echo "das folgende originale Samplesheet wird verarbeitet (Anzahl Zeilen)"
        nrec=$(wc -l ${ifile} |awk '{print $1}')
        printout=$(ls -trl ${ifile};echo ${nrec})
        echo ${printout} 
    
        #suche headerzeile
        startat=$(awk '{ sub("\r$", ""); print }'  ${ifile} | grep -n "GGP_F250_Tissue-R&D" | awk -F":" '{print $1}')
        echo " "
        #headerzeile schreiben aus dem ersten samplesheet nur
        if [ ${ifile} == ${itemN} ] ; then
            awk '{ sub("\r$", ""); print }'  ${ifile} |\
                awk -v start=${startat} \
                    -v c1=${colMD} \
                    -v c2=${colHD} \
                    -v c3=${colLD} \
                    -v c4=${colFD} \
                    -v s=${colBCD} \
                    -v x=${colSX} \
                    -v t=${colTVD} \
                    -v zo=${colZO} \
                    -v mn=${colNM} \
                    -v sr=${colRS} \
                    -v ak=${colAK} \
                    -v st=${colST} 'BEGIN{FS=";";OFS=";"}{if (NR == start) print $s,$c1,$c2,$c3,"",$c4,"","","","","","","",$x,$t,$zo,$mn,"",$sr,"","","","",$ak,$st}' > $crossreffile
        fi
        awk '{ sub("\r$", ""); print }'  ${ifile} |\
            awk -v start=${startat} \
                -v c1=${colMD} \
                -v c2=${colHD} \
                -v c3=${colLD} \
                -v c4=${colFD} \
                -v s=${colBCD} \
                -v x=${colSX} \
                -v t=${colTVD} \
                -v zo=${colZO} \
                -v mn=${colNM} \
                -v sr=${colRS} \
                -v ak=${colAK} \
                -v st=${colST} 'BEGIN{FS=";";OFS=";"}{if (NR > start) print $s,$c1,$c2,$c3,"",$c4,"","","","","","","",$x,$t,$zo,$mn,"",$sr,"","","","",$ak,$st}' >> $crossreffile
    rm -f ${ifile}
    done
    echo "Combining finished: $crossreffile was created:"
    nrec=$(wc -l $crossreffile |awk '{print $1}')
    printout=$(ls -trl $crossreffile;echo ${nrec})
    echo $printout
    echo " "
    echo "Small statitics about your created samplesheet:"
    echo "Breeding organisation: 1 -> BVCH, 4 -> SHB , 5-> HOS, 6-> VMS:"
    cut -d';' -f16 $crossreffile | sort | uniq -c
    echo " "
    echo "Sex:"
    cut -d';' -f14 $crossreffile | sort | uniq -c
    echo " "
    echo "Rasse:"
    cut -d';' -f19 $crossreffile | sort | uniq -c
    echo " "
    echo "Abstammungskontrolle:"
    cut -d';' -f24 $crossreffile | sort | uniq -c
	echo " "
    echo "Sample Type:"
    cut -d';' -f25 $crossreffile | sort | uniq -c
else
    echo "Having no initial Samplesheets which is NOT Suspicious..."
fi

cd ${MAIN_DIR}
echo " "

echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
