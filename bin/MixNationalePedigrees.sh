#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "



#######################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
#######################################################
set -o errexit
set -o nounset
if [ -z ${1} ]; then
    echo "Brauche den Code fuer die Rasse: entweder BSW oder HOL oder VMS"
    exit 1
elif [ ${1} == "BSW" ] || [ ${1} == "HOL" ] ; then
set -o nounset
breed=${1}

    if [ ${breed} == "HOL" ]; then
	echo "Mischen SHZV SHB pedigree"
	#verlinken neuestes pesee file von SHZV
	if [ ! "$(ls -A /qualstore03/data_zws/prod/data/shzv/)" ]; then 
		echo habe kein File vom SHZV mit den Waegungen
		exit 1
	else
		rm -f /qualstore03/data_zws/prod/data/shzv/getest.IMP.ho 
		filenew=$(ls -trl /qualstore03/data_zws/prod/data/shzv/PES_EGCOM-*txt  | tail -1 | awk '{print $9}')
		echo $filenew
		ln -s ${filenew} /qualstore03/data_zws/prod/data/shzv/getest.IMP.ho 
	fi	
	
	/qualstore03/data_zws/pedigree/prog/runJoinPedi.sh ${DatPEDIshb}_pedigree_rrtdm_SHB.dat ${DatPEDIshb}_Blood_pedigree_rrtdm_SHB.dat ${pedigreeSHZV} ${blutfileSHZV} getest.rw getest.IMP.ho
    err=$(echo $?)
    if [ ${err} -gt 0 ]; then
            echo "ooops Fehler /qualstore03/data_zws/pedigree/prog/runJoinPedi.sh"
            $BIN_DIR/sendErrorMail.sh /qualstore03/data_zws/pedigree/prog/runJoinPedi.sh ${breed}
            exit 1
    fi


	if test -s  /qualstore03/data_zws/pedigree/work/rh/pedi_shb_shzv.dat ; then
	    heute=$(date | awk '{print $3$2}')
	    datumjoin=$(ls -trl /qualstore03/data_zws/pedigree/work/rh/pedi_shb_shzv.dat | awk '{print $7$6}')
	    if [ ${datumjoin} != ${heute} ] ; then
		echo ooops Zeitstempel des gejointen Pedigrees ist nicht von heute
		exit 1
	    else
		echo "Juhuuuu ^__^ gemeinsamesPediFile erstellt:      /qualstore03/data_zws/pedigree/work/rh/pedi_shb_shzv.dat"
		
		echo "Mail an ZO: /qualstore03/data_zws/pedigree/work/rh/Diff_ITBIDs_zwischenSHBundSHZV.csv"
		echo "Mail an ZO: /qualstore03/data_zws/pedigree/work/rh/Diff_TVDIDs_zwischenSHBundSHZV.csv"
		echo "Mail an ZO: /qualstore03/data_zws/pedigree/work/rh/IDsInSHBPediDieAliasIDsSindBeiItb.csv"
		echo "Mail an ZO: /qualstore03/data_zws/pedigree/work/rh/IDsInSHZVPediDieAliasIDsSindBeiItb.csv"
		echo "   Jeweils mit der Bitte um Bearbeitung. Es hat auch noch weitere Dateien mit Inhalt fuer die ZO in /qualstore03/data_zws/pedigree/work/rh"
	    fi
	else
	    echo "oops Gejointes Pedigree gibts nicht :-("
	fi
	rm -f /qualstore03/data_zws/prod/data/shzv/getest.IMP.ho
    fi
    
    
    
    if [ ${breed} == "BSW" ]; then
	echo "concateneate BVCH und JER pedigree da keine Tiere doppelt vorkommen da Daten von BRUNANET"
	(cat ${PED_DIR}/bvch/${DatPEDIbvch}_pedigree_rrtdm_BVCH.dat;
	   cat ${PED_DIR}/jer/${DatPEDIjer}_pedigree_rrtdm_JER.dat) > ${PEDI_DIR}/work/bv/${DatPEDIbvch}_pedigree_rrtdm_BVJE.dat
	(cat ${PED_DIR}/bvch/${DatPEDIbvch}_Blood_pedigree_rrtdm_BVCH.dat;
	   cat ${PED_DIR}/jer/${DatPEDIjer}_Blood_pedigree_rrtdm_JER.dat) > ${PEDI_DIR}/work/bv/${DatPEDIbvch}_Blood_pedigree_rrtdm_BVJE.dat
	(cat ${PED_DIR}/bvch/${DatPEDIbvch}_NameDame_pedigree_rrtdm_BVCH.dat;
	   cat ${PED_DIR}/jer/${DatPEDIjer}_NameDame_pedigree_rrtdm_JER.dat) > ${PEDI_DIR}/work/bv/${DatPEDIbvch}_NameDame_pedigree_rrtdm_BVJE.dat
	fi
	
	$BIN_DIR/checkPedigreeProcessLogfiles.sh ${breed}
	
else
   echo "${1} wurde and Argument mitgegeben. Dafuer mixe ich keine nationalen Pedigrees"
fi

echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
