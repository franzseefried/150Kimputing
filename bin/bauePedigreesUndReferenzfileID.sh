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
set -o nounset

if [ -z $1 ]; then
    echo "brauche den Code welche Rasse verarbeitet werden soll, 'BSW' oder 'HOL' oder 'VMS'"
    exit 1
elif [ ${1} == "BSW" ] || [ ${1} == "HOL" ] || [ ${1} == "VMS" ]; then


for breed in ${1}; do


    if [ ${breed} == "BSW" ]; then
    awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | grep -v "Es ist kein Tier mit der ID "  | cut -d';' -f3 | awk '{if(substr($1,7,1) == "F" || substr($1,7,1) == "M") print $1}' | awk '{if(substr($1,1,3) == "BSW" || substr($1,1,3) == "JER" || substr($1,1,3) == "XXX") print substr($1,4,16)}' > $WORK_DIR/genotypisiert.itbid.${breed}
	rasse=bv
	(echo logFile /qualstore03/data_zws/pedigree/work/${rasse}/mergeRRTDMAndITBPed_${DatPEDIbvch}.log | sed "s/ \// \'\//g" | sed "s/\.log/\.log\'/g"
	    echo rrtdmPediFile /qualstore03/data_zws/pedigree/work/bv/${DatPEDIbvch}_pedigree_rrtdm_BVJE.dat | sed "s/ \// \'\//g" | sed "s/\.dat/\.dat\'/g"
	    echo itbPediFile /qualstore03/data_zws/pedigree/data/itb/pedig_${breed}.csv   | sed "s/ \// \'\//g" | sed "s/\.csv/\.csv\'/g"
	    echo fehlerhafteRrtdmPediRecFile /qualstore03/data_zws/pedigree/work/bv/FehlerhafteRrrtdmRecs_${DatPEDIbvch}.txt | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
	    echo sexFehlerFile /qualstore03/data_zws/pedigree/work/${rasse}/Geschlechtsfehler.txt  | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
	    echo pediFehlerFile /qualstore03/data_zws/pedigree/work/${rasse}/Pedigreefehler.txt  | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
	    echo altersdiskrepanzenFile /qualstore03/data_zws/pedigree/work/${rasse}/Altersdiskrepanzen.txt  | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
	    echo fehldendeElternFile /qualstore03/data_zws/pedigree/work/${rasse}/FehlendeEltern.txt  | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
	    echo diffRrtdmPediItbPediFile /qualstore03/data_zws/pedigree/work/${rasse}/Diff_RRTDMPedi_ITBPedi.txt  | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
	    echo missingTVDIDCode UUUUUUUUUUUUUU
	    echo listeTiereFuerPedigree ${WORK_DIR}/genotypisiert.itbid.${breed}  | sed "s/ \// \'\//g" | sed "s/\.BSW/\.BSW\'/g"
	    echo idTypInListeTiereFuerPedigree itbid16
	    echo nGenerationen 40
	    echo mergedPediFile /qualstore03/data_zws/pedigree/work/${rasse}/mergedPedi_${DatPEDIbvch}.txt  | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
	    echo includeTiereOhneGeburtsdatum YES) > $TMP_DIR/mergeRRTDMAndITBPed.${breed}.50Kimputing.prm

	$PEDBIN_DIR/mergeRRTDMAndITBPed $TMP_DIR/mergeRRTDMAndITBPed.${breed}.50Kimputing.prm
	rm -f $TMP_DIR/mergeRRTDMAndITBPed.${breed}.50Kimputing.prm

	echo " "
	echo " renum now /qualstore03/data_zws/pedigree/work/${rasse}/mergedPedi_${DatPEDIbvch}.txt"
	(echo logFile  /qualstore03/data_zws/pedigree/work/${rasse}/renumPedi_gs_${rasse}.log | sed "s/ \// \'\//g" | sed "s/\.log/\.log\'/g"
		echo pediFile /qualstore03/data_zws/pedigree/work/${rasse}/mergedPedi_${DatPEDIbvch}.txt | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
		echo missingTVDIDCode UUUUUUUUUUUUUU
		echo skipTiereMitFehlerhaftemGeburtsdatum NO
		echo fehlerhaftePediRecFile /qualstore03/data_zws/pedigree/work/${rasse}/fehlerhaftePediRecs_gs_${rasse}.txt | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
		echo pediFehlerFile /qualstore03/data_zws/pedigree/work/${rasse}/pedigreefehler_imp_${rasse}.txt | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
		echo sexFehlerFile  /qualstore03/data_zws/pedigree/work/${rasse}/geschlechtsfehler_imp_${rasse}.txt | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
		echo altersdiskrepanzenFile /qualstore03/data_zws/pedigree/work/${rasse}/altersdiskrepanzen_imp_${rasse}.txt | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
                echo uGAltersdifferenzElterNk 268
		echo fehldendeElternFile  /qualstore03/data_zws/pedigree/work/${rasse}/fehlendeEltern_imp_${rasse}.txt | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
		echo renumberedPediFile /qualstore03/data_zws/pedigree/work/${rasse}/RenumMergedPedi_${DatPEDIbvch}.txt| sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g" ) > $TMP_DIR/RenumMergedPedi.${breed}.50Kimputing.prm
	$PEDBIN_DIR/renumRRTDMPed $TMP_DIR/RenumMergedPedi.${breed}.50Kimputing.prm
	echo "mache zentrale Umkodierungs-files $WORK_DIR/ped_umcodierung.txt.${breed} und $WRK_DIR/Run${run}.alleIDS_${breed}.txt"
	echo " "
	if ! test -s /qualstore03/data_zws/pedigree/work/${rasse}/RenumMergedPedi_${DatPEDIbvch}.txt; then
	   echo " "
	   echo "/qualstore03/data_zws/pedigree/work/${rasse}/RenumMergedPedi_${DatPEDIbvch}.txt does not exist or has size zero... "
	   echo "${SCRIPT} stopps here for ${breed}"
	   exit 1
	fi
	sed 's/ /_/g' /qualstore03/data_zws/pedigree/work/${rasse}/RenumMergedPedi_${DatPEDIbvch}.txt |\
  	awk '{print substr($0,1,10),substr($0,12,10),substr($0,23,10),substr($0,41,16),substr($0,58,14),substr($0,82,3)}' | sed 's/_//g' > $WORK_DIR/ped_umcodierung.txt.${breed}
	sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed} > $TMP_DIR/ped_umcod.${breed}.srt
	cat  /qualstore03/data_zws/pedigree/work/${rasse}/RenumMergedPedi_${DatPEDIbvch}.txt | tr ' ' '_' |\
	   awk '{print substr($0,39,18),substr($0,82,3)}' | sed 's/_//g' | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 >  $TMP_DIR/breedcodesMixedPedi.${breed}
	(echo "IMPUTEID IMPUTEIDVAT IMPUTEIDMUT SHORTITBID TVDID ARGUSID ITBID  RasseMixedPedi";
	    awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | cut -d';' -f1,2,3 | sed 's/ //g' | tr ';' ' ' | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k2,2 |\
               join -t' ' -e'-' -o'2.1 2.2 2.3 2.4 2.5 1.1 1.3 2.6' -a2 -1 2 -2 5 - $TMP_DIR/ped_umcod.${breed}.srt | sort -T ${SRT_DIR} -T ${SRT_DIR} -u | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k5,5) > $WRK_DIR/Run${run}.alleIDS_${breed}.txt
    fi


    if [ ${breed} == "HOL" ]; then
        awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | grep -v "Es ist kein Tier mit der ID "  | cut -d';' -f3 | awk '{if(substr($1,7,1) == "F" || substr($1,7,1) == "M") print $1}' | awk '{if(substr($1,1,3) != "BSW") print substr($1,4,16)}' > $WORK_DIR/genotypisiert.itbid.${breed}
	rasse=rh
        #es wird gemergte Pedigree aus joinPedi gezogen
	(echo logFile /qualstore03/data_zws/pedigree/work/${rasse}/mergeRRTDMAndITBPed_${DatPEDIshb}.log | sed "s/ \// \'\//g" | sed "s/\.log/\.log\'/g"
	    echo rrtdmPediFile /qualstore03/data_zws/pedigree/work/${rasse}/pedi_shb_shzv.dat | sed "s/ \// \'\//g" | sed "s/\.dat/\.dat\'/g"
	    echo itbPediFile /qualstore03/data_zws/pedigree/data/itb/pedig_${breed}.csv   | sed "s/ \// \'\//g" | sed "s/\.csv/\.csv\'/g"
	    echo fehlerhafteRrtdmPediRecFile /qualstore03/data_zws/pedigree/work/${rasse}/FehlerhafteRrrtdmRecs_${DatPEDIshb}.txt | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
	    echo sexFehlerFile /qualstore03/data_zws/pedigree/work/${rasse}/Geschlechtsfehler.txt  | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
	    echo pediFehlerFile /qualstore03/data_zws/pedigree/work/${rasse}/Pedigreefehler.txt  | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
	    echo altersdiskrepanzenFile /qualstore03/data_zws/pedigree/work/${rasse}/Altersdiskrepanzen.txt  | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
	    echo fehldendeElternFile /qualstore03/data_zws/pedigree/work/${rasse}/FehlendeEltern.txt  | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
	    echo diffRrtdmPediItbPediFile /qualstore03/data_zws/pedigree/work/${rasse}/Diff_RRTDMPedi_ITBPedi.txt  | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
	    echo missingTVDIDCode UUUUUUUUUUUUUU
	    echo listeTiereFuerPedigree ${WORK_DIR}/genotypisiert.itbid.${breed}  | sed "s/ \// \'\//g" | sed "s/\.HOL/\.HOL\'/g"
	    echo idTypInListeTiereFuerPedigree itbid16
	    echo nGenerationen 40
	    echo uGAltersdifferenzElterNk 268
            echo mergedPediFile /qualstore03/data_zws/pedigree/work/${rasse}/mergedPedi_${DatPEDIshb}.txt  | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
	    echo includeTiereOhneGeburtsdatum YES) > $TMP_DIR/mergeRRTDMAndITBPed.${breed}.50Kimputing.prm
	
	$PEDBIN_DIR/mergeRRTDMAndITBPed $TMP_DIR/mergeRRTDMAndITBPed.${breed}.50Kimputing.prm
	rm -f $TMP_DIR/mergeRRTDMAndITBPed.${breed}.50Kimputing.prm
	echo " renum now /qualstore03/data_zws/pedigree/work/${rasse}/mergedPedi_${DatPEDIshb}.txt"
	(echo logFile  /qualstore03/data_zws/pedigree/work/${rasse}/renumPedi_gs_${rasse}.log | sed "s/ \// \'\//g" | sed "s/\.log/\.log\'/g"
		echo pediFile /qualstore03/data_zws/pedigree/work/${rasse}/mergedPedi_${DatPEDIshb}.txt | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
		echo missingTVDIDCode UUUUUUUUUUUUUU
		echo skipTiereMitFehlerhaftemGeburtsdatum NO
		echo fehlerhaftePediRecFile /qualstore03/data_zws/pedigree/work/${rasse}/fehlerhaftePediRecs_gs_${rasse}.txt | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
		echo pediFehlerFile /qualstore03/data_zws/pedigree/work/${rasse}/pedigreefehler_imp_${rasse}.txt | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
		echo sexFehlerFile  /qualstore03/data_zws/pedigree/work/${rasse}/geschlechtsfehler_imp_${rasse}.txt | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
		echo altersdiskrepanzenFile /qualstore03/data_zws/pedigree/work/${rasse}/altersdiskrepanzen_imp_${rasse}.txt | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
		echo uGAltersdifferenzElterNk 268
                echo fehldendeElternFile  /qualstore03/data_zws/pedigree/work/${rasse}/fehlendeEltern_imp_${rasse}.txt | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
		echo renumberedPediFile /qualstore03/data_zws/pedigree/work/${rasse}/RenumMergedPedi_${DatPEDIshb}.txt| sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g" ) > $TMP_DIR/RenumMergedPedi.${breed}.50Kimputing.prm
	$PEDBIN_DIR/renumRRTDMPed $TMP_DIR/RenumMergedPedi.${breed}.50Kimputing.prm
	rm -f $TMP_DIR/RenumMergedPedi.${breed}.50Kimputing.prm
        echo "mache zentrale Umkodierungs-files $WORK_DIR/ped_umcodierung.txt.${breed} und $WRK_DIR/Run${run}.alleIDS_${breed}.txt"
	echo " "
	if ! test -s /qualstore03/data_zws/pedigree/work/${rasse}/RenumMergedPedi_${DatPEDIshb}.txt; then
	   echo " "
	   echo "/qualstore03/data_zws/pedigree/work/${rasse}/RenumMergedPedi_${DatPEDIshb}.txt does not exist or has size zero... "
	   echo "${SCRIPT} stopps here for ${breed}"
	   exit 1
	fi
	sed 's/ /_/g' /qualstore03/data_zws/pedigree/work/${rasse}/RenumMergedPedi_${DatPEDIshb}.txt |\
  	awk '{print substr($0,1,10),substr($0,12,10),substr($0,23,10),substr($0,41,16),substr($0,58,14),substr($0,82,3)}' | sed 's/_//g' > $WORK_DIR/ped_umcodierung.txt.${breed}
	sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed} > $TMP_DIR/ped_umcod.${breed}.srt
	cat  /qualstore03/data_zws/pedigree/work/${rasse}/RenumMergedPedi_${DatPEDIshb}.txt | tr ' ' '_' |\
	   awk '{print substr($0,39,18),substr($0,82,3)}' | sed 's/_//g' | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 >  $TMP_DIR/breedcodesMixedPedi.${breed}
	(echo "IMPUTEID IMPUTEIDVAT IMPUTEIDMUT SHORTITBID TVDID ARGUSID ITBID RasseMixedPedi";
	    awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | cut -d';' -f1,2,3 | sed 's/ //g' | tr ';' ' ' | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k2,2 |\
               join -t' ' -e'-' -o'2.1 2.2 2.3 2.4 2.5 1.1 1.3 2.6' -1 2 -2 5 -a2 - $TMP_DIR/ped_umcod.${breed}.srt | sort -T ${SRT_DIR} -T ${SRT_DIR} -u | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k5,5) > $WRK_DIR/Run${run}.alleIDS_${breed}.txt

    fi
    
    
    if [ ${breed} == "VMS" ]; then
#        echo " "
#        echo "definiere Liste mit den Tieren zu denen das Pedigree aufgebaut werden soll.... seit CDB geht es wegen der Datenmenge nicht mehr als wildcard"
        
	awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | grep -v "Es ist kein Tier mit der ID "  | cut -d';' -f3 | awk '{if(substr($1,7,1) == "F" || substr($1,7,1) == "M") print $1}' | awk '{if(substr($1,1,3) != "BSW" && substr($1,1,3) != "HOL") print substr($1,4,16)}' > $WORK_DIR/genotypisiert.itbid.${breed}
        rasse=vms
	
	echo " "	
	echo "nur renumerieren, kein ITB Pedigree"
	echo " "
	echo "renum now /qualstore03/data_zws/pedigree/data/${rasse}/${DatPEDIvms}_pedigree_rrtdm_VMS.dat"
	(echo logFile  /qualstore03/data_zws/pedigree/work/${rasse}/renumPedi_gs_${rasse}.log | sed "s/ \// \'\//g" | sed "s/\.log/\.log\'/g"
		echo pediFile /qualstore03/data_zws/pedigree/data/${rasse}/${DatPEDIvms}_pedigree_rrtdm_VMS.dat | sed "s/ \// \'\//g" | sed "s/\.dat/\.dat\'/g"
		echo missingTVDIDCode UUUUUUUUUUUUUU
		echo skipTiereMitFehlerhaftemGeburtsdatum NO
		echo fehlerhaftePediRecFile /qualstore03/data_zws/pedigree/work/${rasse}/fehlerhaftePediRecs_gs_${rasse}.txt | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
		echo pediFehlerFile /qualstore03/data_zws/pedigree/work/${rasse}/pedigreefehler_imp_${rasse}.txt | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
		echo sexFehlerFile  /qualstore03/data_zws/pedigree/work/${rasse}/geschlechtsfehler_imp_${rasse}.txt | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
		echo altersdiskrepanzenFile /qualstore03/data_zws/pedigree/work/${rasse}/altersdiskrepanzen_imp_${rasse}.txt | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
		echo fehldendeElternFile  /qualstore03/data_zws/pedigree/work/${rasse}/fehlendeEltern_imp_${rasse}.txt | sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g"
		echo listeTiereFuerPedigree ${WORK_DIR}/genotypisiert.itbid.${breed}   | sed "s/ \// \'\//g" | sed "s/\.VMS/\.VMS\'/g"
		echo idTypInListeTiereFuerPedigree itbid16
                echo nGenerationen 40
                echo uGAltersdifferenzElterNk 268
		echo renumberedPediFile /qualstore03/data_zws/pedigree/work/${rasse}/RenumMergedPedi_${DatPEDIvms}.txt| sed "s/ \// \'\//g" | sed "s/\.txt/\.txt\'/g" ) > $TMP_DIR/RenumMergedPedi.${breed}.50Kimputing.prm
	$PEDBIN_DIR/renumRRTDMPed $TMP_DIR/RenumMergedPedi.${breed}.50Kimputing.prm
	rm -f $TMP_DIR/RenumMergedPedi.${breed}.50Kimputing.prm
        echo "mache zentrale Umkodierungs-files $WORK_DIR/ped_umcodierung.txt.${breed} und $WRK_DIR/Run${run}.alleIDS_${breed}.txt"
	echo " "
	if ! test -s /qualstore03/data_zws/pedigree/work/${rasse}/RenumMergedPedi_${DatPEDIvms}.txt; then
	   echo " "
	   echo "/qualstore03/data_zws/pedigree/work/${rasse}/RenumMergedPedi_${DatPEDIvms}.txt does not exist or has size zero... "
	   echo "${SCRIPT} stopps here for ${breed}"
	   exit 1
	fi

	sed 's/ /_/g' /qualstore03/data_zws/pedigree/work/${rasse}/RenumMergedPedi_${DatPEDIvms}.txt |\
  	awk '{print substr($0,1,10),substr($0,12,10),substr($0,23,10),substr($0,41,16),substr($0,58,14),substr($0,82,3)}' | sed 's/_//g' > $WORK_DIR/ped_umcodierung.txt.${breed}
	sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k5,5 $WORK_DIR/ped_umcodierung.txt.${breed} > $TMP_DIR/ped_umcod.${breed}.srt
	cat  /qualstore03/data_zws/pedigree/work/${rasse}/RenumMergedPedi_${DatPEDIvms}.txt | tr ' ' '_' |\
	   awk '{print substr($0,39,18),substr($0,82,3)}' | sed 's/_//g' | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 >  $TMP_DIR/breedcodesMixedPedi.${breed}
	(echo "IMPUTEID IMPUTEIDVAT IMPUTEIDMUT SHORTITBID TVDID ARGUSID ITBID  RasseMixedPedi";
	    awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | cut -d';' -f1,2,3 | sed 's/ //g' | tr ';' ' ' | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k2,2 |\
               join -t' ' -e'-' -o'2.1 2.2 2.3 2.4 2.5 1.1 1.3 2.6' -a2 -1 2 -2 5 - $TMP_DIR/ped_umcod.${breed}.srt | sort -T ${SRT_DIR} -T ${SRT_DIR} -u | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k5,5) > $WRK_DIR/Run${run}.alleIDS_${breed}.txt
    fi
    
$BIN_DIR/checkPedigreeProcessLogfiles.sh ${breed}
    
    
done
else
    echo "falsche Rasse, ich stoppe :("
    exit 1
fi

echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}
