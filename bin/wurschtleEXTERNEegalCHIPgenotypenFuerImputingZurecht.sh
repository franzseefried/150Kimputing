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


#######################################################################################
if [ -z $1 ]; then
	echo "brauche Info welcher Rasse die Tiere angehoeren: HOL oder BSW oder VMS"
	exit 1
fi
if [ ${1} != "BSW" ] && [ $1 != "HOL" ] && [ $1 != "VMS" ]; then
    echo "brauche alsCode HOL oder BSW oder VMS"
    exit 1
fi

    
for i in 03_V1 20_V1 26_V1 30_V1 50_V1 139_V1 HD_V1 09_V1 50_V2 77_V1 LD_V1 ; do
#for i in 03_V1 20_V1 26_V1 30_V1 50_V1 139_V1 09_V1 50_V2 77_V1 LD_V1;do
    awk '{ sub("\r$", ""); print }' $MAP_DIR/intergenomics/SNPindex_${i}_new_order.txt | sed 's/Dominant Red/Dominant_Red/g' |  awk '{print $1,$2,$3}' | sort -T ${SRT_DIR} -t' ' -k1,1 > $TMP_DIR/MAP${i}.srt
done
	for folder in LD80K 50K 150K 850K; do
    cd ${EXT_DIR}/${1}/${folder}
    for labfile in $( ls ); do
	echo $labfile
	awk '{ sub("\r$", ""); print }' $EXT_DIR/${1}/${folder}/${labfile}  > $TMP_DIR/${labfile}.linux

#suche chip
	nSNP=$(grep -i "num snps" $TMP_DIR/${labfile}.linux | awk '{print $3}')

	
#finde Header
	kopfz=$(head -20 $TMP_DIR/${labfile}.linux | cat -n | grep -i Allele1 | awk '{print $1}')

#frage Feldtrenner ab Leerschlag, Semikolon oder Tabulator abgefangen
	n1=$(head -${kopfz} $TMP_DIR/${labfile}.linux | tail -1 | sed 's/ //g' | tr '\t' '#' | tr ';' '#' | tr ',' ' '  | wc -w | awk '{print $1}')
	n2=$(head -${kopfz} $TMP_DIR/${labfile}.linux | tail -1 | sed 's/ //g' | tr ',' '#'  | tr ';' '#' | tr '\t' ' ' | wc -w | awk '{print $1}')
	n3=$(head -${kopfz} $TMP_DIR/${labfile}.linux | tail -1 | sed 's/ //g' | tr '\t' '#' | tr ',' '#' | tr ';' ' '  | wc -w | awk '{print $1}')
	if [ ${n1} != ${n2} ] || [ ${n1} != ${n3} ] || [ ${n2} != ${n3} ]; then
	    if [ ${n1} -gt 1 ]; then
		spt=","
	    elif [ ${n2} -gt 1 ]; then
		cat $TMP_DIR/${labfile}.linux | tr '\t' ',' > $TMP_DIR/${labfile}.linuxNEU
		mv $TMP_DIR/${labfile}.linuxNEU $TMP_DIR/${labfile}.linux
		spt=","
	    elif [ ${n3} -gt 1 ]; then
		spt=";"
	    else
		echo "unbekannter Feldtrenner :-("
		exit 1
	    fi
	else
	    echo "unbekannter Feldtrenner :-("
	fi


		
#Umkodieren
	if [ ${kopfz} -gt 0 ] && [ ${kopfz} -lt 21 ]; then
	    echo "Kopfzeile ist in Zeile ${kopfz}"
	    spalteSNP=$(head -${kopfz} $TMP_DIR/${labfile}.linux    | tail -1 | tr '\t' ',' | tr ${spt} '\n' | sed "s/ //g" |cat -n  | awk '{print $1" "$2}'  | grep -i "snpname"    | cut -d' ' -f1)
	    spalteTIER=$(head -${kopfz} $TMP_DIR/${labfile}.linux   | tail -1 | tr '\t' ',' | tr ${spt} '\n' | sed "s/ //g" |cat -n  | awk '{print $1" "$2}'  | grep -i "sampleid"   | cut -d' ' -f1)
	    if [ -z ${spalteTIER} ]; then
			    spalteTIER=$(head -${kopfz} $TMP_DIR/${labfile}.linux   | tail -1 | tr '\t' ',' | tr ${spt} '\n' | sed "s/ //g" |cat -n  | awk '{print $1" "$2}'  | grep -i "samplename"   | cut -d' ' -f1)
	    fi
	    spalteALLELA=$(head -${kopfz} $TMP_DIR/${labfile}.linux | tail -1 | tr '\t' ',' | tr ${spt} '\n' | sed "s/ //g" |cat -n  | awk '{print $1" "$2}'  | grep -i "allele1-ab" | cut -d' ' -f1)
	    spalteALLELB=$(head -${kopfz} $TMP_DIR/${labfile}.linux | tail -1 | tr '\t' ',' | tr ${spt} '\n' | sed "s/ //g" |cat -n  | awk '{print $1" "$2}'  | grep -i "allele2-ab" | cut -d' ' -f1)
	    spaltebALLELe=$(head -${kopfz} $TMP_DIR/${labfile}.linux | tail -1 | tr ${spt} '\n' | sed "s/ //g" |cat -n  | awk '{print $1" "$2}'  | grep -i "gcscore" | cut -d' ' -f1)
	    if [ -z ${spalteSNP} ] || [ -z ${spalteTIER} ] || [ -z ${spaltebALLELe} ] || [ -z ${spalteALLELA} ] || [ -z ${spalteALLELA} ] || [ -z ${spalteALLELB} ]; then
           echo "ooops one expected column in labfile ${labfile} is missing"
           echo "need to be checked"
           echo "I stop now and you have to delete ${EXT_DIR}/${1}/${folder}"
           ls -trl ${EXT_DIR}/${1}/${folder}/${labfile}
           echo "then restart the script as follows: $BIN_DIR/wurschtleEXTERNEegalCHIPgenotypenFuerImputingZurecht.sh ${1} >> log/wurschtleEXTERNEegalCHIPgenotypenFuerImputingZurecht_${1}.log"
           echo " "
           exit 1
         fi
	    cutting=$(echo "${spalteSNP},${spalteTIER},${spalteALLELA},${spalteALLELB}")
	    echo $cutting
	    #Abfangen Spaltenreihenfolge
	    cat $TMP_DIR/${labfile}.linux | tr '\t' ',' | tr ${spt} ';' | cut -d';' -f${spalteSNP} | awk '{print $1}' | cat -n | awk -v h=${kopfz} '{if($1 > h) print $2}' >  $TMP_DIR/${labfile}.spalteSNP.tmp
	    cat $TMP_DIR/${labfile}.linux | tr '\t' ',' | tr ${spt} ';' | cut -d';' -f${spalteTIER} | awk '{print $1}' | cat -n | awk -v h=${kopfz} '{if($1 > h) print $2}' >  $TMP_DIR/${labfile}.spalteTIER.tmp
	    cat $TMP_DIR/${labfile}.linux | tr '\t' ',' | tr ${spt} ';' | cut -d';' -f${spalteALLELA} | awk '{print $1}' | cat -n | awk -v h=${kopfz} '{if($1 > h) print $2}' >  $TMP_DIR/${labfile}.spalteALLELA.tmp
	    cat $TMP_DIR/${labfile}.linux | tr '\t' ',' | tr ${spt} ';' | cut -d';' -f${spalteALLELB} | awk '{print $1}' | cat -n | awk -v h=${kopfz} '{if($1 > h) print $2}' >  $TMP_DIR/${labfile}.spalteALLELB.tmp
	    paste $TMP_DIR/${labfile}.spalteSNP.tmp $TMP_DIR/${labfile}.spalteTIER.tmp $TMP_DIR/${labfile}.spalteALLELA.tmp $TMP_DIR/${labfile}.spalteALLELB.tmp |\
                  awk '{print $1";"$2";"$3";"$4}' > $TMP_DIR/${labfile}.tmp

	    rm -f $TMP_DIR/${labfile}.linux $TMP_DIR/${labfile}.linuxNEU $TMP_DIR/${labfile}.spalteSNP.tmp $TMP_DIR/${labfile}.spalteTIER.tmp $TMP_DIR/${labfile}.spalteALLELA.tmp $TMP_DIR/${labfile}.spalteALLELB.tmp
	    $BIN_DIR/awk_umkodierungITBIDzuTVD $WORK_DIR/crossref.txt $TMP_DIR/${labfile}.tmp  | tee  $TMP_DIR/${labfile}.tvd | cut -d';' -f2 | sort -T ${SRT_DIR} -u > $WORK_DIR/${labfile}.tiere
	else
	    echo "Habe keinen Header gefunden"
	    exit 1
	fi

	
#kleine Kontrolle auf der Konsole ob alle umkodierungen funktioniert haben:
	fgrep "#####" $TMP_DIR/${labfile}.tvd | sed 's/ //g' | tr ';' ' ' | awk '{print $2,$3}' | sort -T ${SRT_DIR} -u
	kontr=$(fgrep "#####" $TMP_DIR/${labfile}.tvd  | cut -d';' -f2 | sort -T ${SRT_DIR} -u | wc -l | awk '{print $1}')
	
	if [ ${kontr} != 0 ]; then
	    echo "Umkodierung unvollstaendig $labfile"
	    exit 1
	else
	    echo "Umkodierung vollstaendig"
	    echo "Tier %badGCS" > $CHCK_DIR/${run}/gcscore.check.${labfile}
	    echo "Tier %Callingrate" > $CHCK_DIR/${run}/callingrate.check.${labfile}
	    echo "Tier %Heterozygotie" > $CHCK_DIR/${run}/heterorate.check.${labfile}
            echo "Tier AnzahlSNPs" > $CHCK_DIR/${run}/nSNPs.check.${labfile}
	    echo "Tier" > $WORK_DIR/${labfile}.tiereTOremove
	    
#########################################################
	    echo "GC calculation gestartet"
	    spaltebALLELe=$(head -${kopfz} $TMP_DIR/${labfile}.linux | tail -1 | tr ${spt} '\n' | sed "s/ //g" |cat -n  | awk '{print $1" "$2}'  | grep -i "gcscore" | cut -d' ' -f1)
	    cutting2=$(echo "${spalteTIER},${spaltebALLELe}")
	    g=$(wc -l $TMP_DIR/${labfile}.linux | awk '{print $1}')
	    h=$(echo $g $kopfz | awk '{print $2-$1}')
	    tail ${h} $TMP_DIR/${labfile}.linux | tr '\t' ',' | tr ${spt} ';' | cut -d';' -f${cutting2} | awk 'BEGIN{FS=";"}{print $1";"$2}' > $WORK_DIR/1stgcscore.forR
	    $BIN_DIR/awk_umkodierungSAMPLEidIDanimalgeneseek $WORK_DIR/crossref.txt $WORK_DIR/1stgcscore.forR | sed 's/ //g' | tr ';' ' ' > $WORK_DIR/2ndgcscore.forR ;
	    rm -f $WORK_DIR/1stgcscore.forR;
	    cut -d' ' -f1  $WORK_DIR/2ndgcscore.forR | sort -T ${SRT_DIR} -u |\
           while read muni; do
		awk -v moggel=${muni} '{if ($1 == moggel) print $1,$2}' $WORK_DIR/2ndgcscore.forR > $WORK_DIR/gcscore.forR
		nSNP=$(cat $WORK_DIR/gcscore.forR | wc -l | awk '{print $1}' )
	     #0.11 an Hand IFN Routine identifiziert
	    awk '{if($2 ~ "[0-9]") print}' $WORK_DIR/gcscore.forR > $WORK_DIR/sdgcscore.forR
	    sdgcscore=$(Rscript $BIN_DIR/ExternerGCcheckSD.R ${PAR_DIR}/steuerungsvariablen.ctr.sh $WORK_DIR/sdgcscore.forR | awk '{print $2}') 
            if [ ${sdgcscore} -lt 4 ];then
	        echo "${muni} 0.99 OOOPS"  >> $CHCK_DIR/${run}/gcscore.check.${labfile}
	        echo "${muni} hat nur Streuung ${sdgcscore} und damit extrem wenig Streuung im GCscore, Verdacht auf Datenmanipulation"
	        echo "${muni}"  >> $WORK_DIR/${labfile}.tiereTOremove
	    else
		awk '{if($2 < 0.4 ) print $1,$2}' $WORK_DIR/gcscore.forR | wc -l | awk -v nom=${muni} '{print nom,$1}' |\
                 awk -v n=${nSNP} -v gc=${GCSCR} '{if(($2/n) > gc) print $1,($2/n)*100" OOOPS";else print $1,($2/n)*100 }' >> $CHCK_DIR/${run}/gcscore.check.${labfile}
		awk '{if($2 < 0.4 ) print $1,$2}' $WORK_DIR/gcscore.forR | wc -l | awk -v nom=${muni} '{print nom,$1}' | awk -v n=${nSNP} '{if(($2/n) > 0.11) print "OOOPS Tier "$1" hat schlechten GCS: "($2/n)*100  }'
		awk '{if($2 < 0.4 ) print $1,$2}' $WORK_DIR/gcscore.forR | wc -l | awk -v nom=${muni} '{print nom,$1}' | awk -v n=${nSNP} '{if(($2/n) > 0.11) print $1 }' >> $WORK_DIR/${labfile}.tiereTOremove
        fi
        done
	    
#########################################################
	    echo "Rechne Callingrate und Heterozygotie"
	    awk 'BEGIN{FS=";"}{print $2}' $TMP_DIR/${labfile}.tvd | sort -T ${SRT_DIR} -u |\
           while read line; do
		notcalled=$(awk -v munele=${line} 'BEGIN{FS=";"}{if($2 == munele && $3 == "-" ) print }' $TMP_DIR/${labfile}.tvd | wc -l | awk '{print $1}')
		nsnp=$(awk -v munele=${line} 'BEGIN{FS=";"}{if($2 == munele) print }' $TMP_DIR/${labfile}.tvd | wc -l | awk '{print $1}')
    		echo $line $notcalled $nsnp | awk -v animo=${line} -v cl=${CLLRT} '{if (($2/$3) > (1-cl)) print animo,(1-($2/$3))" OOOPS"; else print animo,(1-($2/$3))}' >>  $CHCK_DIR/${run}/callingrate.check.${labfile}
		echo $line $notcalled $nsnp | awk -v animo=${line} -v cl=${CLLRT} '{if (($2/$3) > (1-cl)) print "OOOOPS Tier "animo" ist schlecht gecalled: "(1-($2/$3))}'
		echo $line $notcalled $nsnp | awk -v animo=${line} -v cl=${CLLRT} '{if (($2/$3) > (1-cl)) print animo}' >> $WORK_DIR/${labfile}.tiereTOremove
		nhet=$(awk -v munele=${line} 'BEGIN{FS=";"}{if($2 == munele && $3$4 == "AB" ) print }' $TMP_DIR/${labfile}.tvd | wc -l | awk '{print $1}')
		echo $line $nhet $nsnp | awk -v ht=${HTRT} '{ if($2/$3 > ht) print $1,($2/$3)" OOOPS"; else print $1,($2/$3)}' >> $CHCK_DIR/${run}/heterorate.check.${labfile}
		echo $line $nhet $nsnp | awk -v ht=${HTRT} '{ if($2/$3 > ht) print $1}' >> $WORK_DIR/${labfile}.tiereTOremove
        #fixes schreiben der anzahl SNPs da unten diese chips gebaut werden
        if [ ${nsnp}  -gt 54609 ] && [ ${nsnp}  -lt 130000  ]; then
           echo $line 30105 >> $CHCK_DIR/${run}/nSNPs.check.${labfile}
        fi
        if [ ${nsnp}  -gt 129999 ] && [ ${nsnp}  -lt 150000  ]; then
           echo $line 139480 >> $CHCK_DIR/${run}/nSNPs.check.${labfile}
        fi
        if [ ${nsnp}  -gt 700000 ]; then
           echo $line 777962 >> $CHCK_DIR/${run}/nSNPs.check.${labfile}
        fi
        if [ ${nsnp}  -gt 53000 ] && [ ${nsnp}  -lt 54610  ]; then
           echo $line 54609 >> $CHCK_DIR/${run}/nSNPs.check.${labfile}
        fi
        if [ ${nsnp}  -lt 53001 ] && [ ${nsnp}  -gt 1000  ]; then
           echo $line 30105 >> $CHCK_DIR/${run}/nSNPs.check.${labfile}
        fi
	    done
	    
#########################################################
	    echo "Loesche Tiere die Callrate, GCSore oder Heterozygotie nicht erfuellen"
	    cat $WORK_DIR/${labfile}.tiereTOremove | sort -T ${SRT_DIR} -u | awk '{print $1," r"}' | sort -T ${SRT_DIR} -t' ' -k1,1  >  $WORK_DIR/${labfile}.tiereTOremove.uniq
	    cat $TMP_DIR/${labfile}.tvd | tr ';' ' ' | sort -T ${SRT_DIR} -t' ' -k2,2 | join -t' ' -o'1.1 1.2 1.3 1.4' -1 2 -2 1 -v1 -  $WORK_DIR/${labfile}.tiereTOremove.uniq |\
        sort -T ${SRT_DIR} -t' ' -k2,2 -k1,1 | tee $TMP_DIR/${labfile}.tvd.toWorkWith | cut -d' ' -f2 | sort -T ${SRT_DIR} -u > $WORK_DIR/${labfile}.tiere.toWorkWith
	    rm -f $TMP_DIR/${labfile}.tvd
	fi



#neu Mai 26. 2015
#im Fall von HD, 150K oder 80K bei Seite legen der vollstaendigen Daten
	nnSNPs=$(wc -l $TMP_DIR/${labfile}.tvd.toWorkWith | awk '{print $1}')
	tvdid=$(awk '{if(NR == 1) print $2}' $TMP_DIR/${labfile}.tvd.toWorkWith)
	    if [ ${nnSNPs}  -gt 54609 ] && [ ${nnSNPs}  -lt 130000  ]; then
	    	echo "Echo weglegen ${nnSNPs}; GGPLDv3 aus GGPHD fuer ${labfile}"
			$BIN_DIR/awk_umkodierungTVDzuidanimal $WORK_DIR/samplesheet.TVDzuID.umcod $TMP_DIR/${labfile}.tvd.toWorkWith | sed 's/ -/ Z/g' | sed 's/\.//g' | sed 's/-//g' | sed 's/_//g' | sed 's/ Z/ -/g' > /qualstore03/data_archiv/SNP/Illumina/80K/NewRoutineFiles_starting_fromMay2015/${1}_SNPs_${labfile}.gt
		    awk '{if($3 == "") print $1,$2,"- -"; else print $1,$2,$3,$4}' $TMP_DIR/${labfile}.tvd.toWorkWith |\
		      sort -T ${SRT_DIR} -t' ' -k1,1 |\
              join -t' ' -o'2.1 1.2 1.3 1.4' -1 1 -2 1 -a2 - $TMP_DIR/MAP30_V1.srt | awk -v tt=${tvdid} '{if($2 == "") print $1,tt" - -"; else print $1,$2,$3,$4}' | sort -T ${SRT_DIR} -t' ' -k2,2 -k1,1 > $LAB_DIR/${1}-${labfile}.tvd.toWorkWith.builtGGPLDv3
			mv ${EXT_DIR}/${1}/${folder}/${labfile} ${STR_DIR}/80K/extern/.
		rm -f ${STR_DIR}/80K/extern/${labfile}.gz    
                gzip ${STR_DIR}/80K/extern/${labfile}
	    	rm -f $WORK_DIR/${labfile}*
		fi
	    if [ ${nnSNPs}  -gt 129999 ] && [ ${nnSNPs}  -lt 150000  ]; then
	    	echo "Echo weglegen ${nnSNPs}; UHD fuer ${labfile}"
			$BIN_DIR/awk_umkodierungTVDzuidanimal $WORK_DIR/samplesheet.TVDzuID.umcod $TMP_DIR/${labfile}.tvd.toWorkWith | sed 's/ -/ Z/g' | sed 's/\.//g' | sed 's/-//g' | sed 's/_//g' | sed 's/ Z/ -/g' > /qualstore03/data_archiv/SNP/Illumina/150K/NewRoutineFiles_starting_fromMay2015/${1}_SNPs_${labfile}.gt
    		awk '{if($3 == "") print $1,$2,"- -"; else print $1,$2,$3,$4}' $TMP_DIR/${labfile}.tvd.toWorkWith |\
    		  sort -T ${SRT_DIR} -t' ' -k1,1 |\
              join -t' ' -o'2.1 1.2 1.3 1.4' -1 1 -2 1 -a2 - $TMP_DIR/MAP139_V1.srt | awk -v tt=${tvdid} '{if($2 == "") print $1,tt" - -"; else print $1,$2,$3,$4}' | sort -T ${SRT_DIR} -t' ' -k2,2 -k1,1 > $LAB_DIR/${1}-${labfile}.tvd.toWorkWith.built150K
            mv ${EXT_DIR}/${1}/${folder}/${labfile} ${STR_DIR}/150K/extern/.
	        rm -f ${STR_DIR}/150K/extern/${labfile}.gz	
                gzip ${STR_DIR}/150K/extern/${labfile}
	    	rm -f $WORK_DIR/${labfile}*
		fi
		if [ ${nnSNPs}  -gt 700000 ]; then
    		echo "Echo weglegen ${nnSNPs}; HD fuer ${labfile}"
    		$BIN_DIR/awk_umkodierungTVDzuidanimal $WORK_DIR/samplesheet.TVDzuID.umcod $TMP_DIR/${labfile}.tvd.toWorkWith | sed 's/ -/ Z/g' | sed 's/\.//g' | sed 's/-//g' | sed 's/_//g' | sed 's/ Z/ -/g' > /qualstore03/data_archiv/SNP/Illumina/HD/NewRoutineFiles_starting_fromFeb2014/${1}_SNPs_${labfile}.gt
   		    awk '{if($3 == "") print $1,$2,"- -"; else print $1,$2,$3,$4}' $TMP_DIR/${labfile}.tvd.toWorkWith |\
   		    sort -T ${SRT_DIR} -t' ' -k1,1 |\
               join -t' ' -o'2.1 2.2 1.2 1.3 1.4' -1 1 -2 1 -a2 - $TMP_DIR/MAPHD_V1.srt | awk -v tt=${tvdid} '{if($3 == "") print $1,$2,tt" - -"}' | awk '{if($2 != "NA") print $1,$3,$4,$5}' | sort -T ${SRT_DIR} -t' ' -k2,2 -k1,1 > $LAB_DIR/${1}-${labfile}.tvd.toWorkWith.builtHD
	    	mv ${EXT_DIR}/${1}/${folder}/${labfile} ${STR_DIR}/HD/extern/.
                rm -f ${STR_DIR}/HD/extern/${labfile}.gz
		gzip ${STR_DIR}/HD/extern/${labfile}
	    	rm -f $WORK_DIR/${labfile}*
	    fi
	    if [ ${nnSNPs}  -gt 53000 ] && [ ${nnSNPs}  -lt 54610  ]; then
	    	echo "Echo weglegen ${nnSNPs}; 50K fuer ${labfile}"
	    	if [ ${1} == "BSW" ]; then
	    	  outfolder=bvch
	    	fi
	    	if [ ${1} == "HOL" ]; then
	    	  outfolder=shb
	    	fi
		    awk '{if($3 == "") print $1,$2,"- -"; else print $1,$2,$3,$4}'  $TMP_DIR/${labfile}.tvd.toWorkWith |\
		    sort -T ${SRT_DIR} -t' ' -k1,1 |\
               join -t' ' -o'2.1 1.2 1.3 1.4' -1 1 -2 1 -a2  - $TMP_DIR/MAP50_V2.srt | awk -v tt=${tvdid} '{if($2 == "") print $1,tt" - -"; else print $1,$2,$3,$4}' | sort -T ${SRT_DIR} -t' ' -k2,2 -k1,1 > $LAB_DIR/${1}-${labfile}.tvd.toWorkWith.built50KV2
 		    mv ${EXT_DIR}/${1}/${folder}/${labfile} ${STR_DIR}/50K/extern/.
		    rm -f ${STR_DIR}/50K/extern/${labfile}.gz
                    gzip ${STR_DIR}/50K/extern/${labfile}
	    	rm -f $WORK_DIR/${labfile}*
		fi	
		if [ ${nnSNPs}  -lt 53001 ] && [ ${nnSNPs}  -gt 1000 ]; then
    		echo "Echo weglegen ${nnSNPs}; GGPLDv3 fuer ${labfile}"
    		#$BIN_DIR/awk_umkodierungTVDzuidanimal $WORK_DIR/samplesheet.TVDzuID.umcod $TMP_DIR/${labfile}.tvd.toWorkWith | sed 's/ -/ Z/g' | sed 's/\.//g' | sed 's/-//g' | sed 's/_//g' | sed 's/ Z/ -/g' > /qualstore03/data_archiv/SNP/Illumina/HD/NewRoutineFiles_starting_fromFeb2014/${1}_SNPs_${labfile}.gt
   		    awk '{if($3 == "") print $1,$2,"- -"; else print $1,$2,$3,$4}' $TMP_DIR/${labfile}.tvd.toWorkWith |\
               sort -T ${SRT_DIR} -t' ' -k1,1 |\
               join -t' ' -o'2.1 1.2 1.3 1.4' -1 1 -2 1 -a2  - $TMP_DIR/MAP30_V1.srt | awk -v tt=${tvdid} '{if($2 == "") print $1,tt" - -"; else print $1,$2,$3,$4}' | sort -T ${SRT_DIR} -t' ' -k2,2 -k1,1 > $LAB_DIR/${1}-${labfile}.tvd.toWorkWith.builtGGPLDv3
	    	mv ${EXT_DIR}/${1}/${folder}/${labfile} ${STR_DIR}/LD/extern/.
                rm -f ${STR_DIR}/LD/extern/${labfile}.gz
		gzip ${STR_DIR}/LD/extern/${labfile}
	    	rm -f $WORK_DIR/${labfile}*
	    fi
            if  [ ${nnSNPs}  -lt 1000 ]; then
                echo "habe keine SNPs im file $TMP_DIR/${labfile}.tvd.toWorkWith da die Daten wg einer Plausikontrolle durchgefallen sind"
	    rm -f $WORK_DIR/${labfile}*
            fi
# join mit der Overallmap, dabei auswahl der SNPs über $1, die overallmap wurde gebaut mit hdimputing/macheKreuztabelle_SNPchips.sh. 50K Daten werden nicht auf LD reduziert alles andere schon

	    rm -f ${EXT_DIR}/${1}/${folder}/${labfile}*
	done
    done



echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
