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


sort -u $WORK_DIR/animal.overall.info -o $WORK_DIR/animal.overall.info



echo "Baue file für TVD->ID Umcodierung"
awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | cut -d';' -f1,2 | sed 's/ //g' | tr ';' ' ' | awk '{print $2,$1}' | sort -u > $WORK_DIR/samplesheet.TVDzuID.umcod

echo "check files now"
for folder in 50K 150K 850K LD80K; do
echo "check files now $folder"
cd $EXT_DIR/${folder}
for labfile in $( ls ); do
    echo $labfile
    awk '{ sub("\r$", ""); print }' ${labfile}  > $TMP_DIR/${labfile}.linux
    #finde Header
	kopfz=$(head -20 $TMP_DIR/${labfile}.linux | cat -n | grep -i Allele1 | awk '{print $1}')
	if [ -z "${kopfz}" ] ; then 
      echo "${labfile} Kopfzeile nicht gefunden: file wird gelöscht. Info per Mail an Barras & Barenco"
      rm -f ${labfile}
    else
    #frage Feldtrenner ab Leerschlag, Semikolon oder Tabulator abgefangen
	n1=$(head -${kopfz} $TMP_DIR/${labfile}.linux | tail -1 | sed 's/ //g' | tr '\t' '#' | tr ';' '#' | tr ',' ' '  | wc -w | awk '{print $1}')
	n2=$(head -${kopfz} $TMP_DIR/${labfile}.linux | tail -1 | sed 's/ //g' | tr ',' '#'  | tr ';' '#' | tr '\t' ' ' | wc -w | awk '{print $1}')
	n3=$(head -${kopfz} $TMP_DIR/${labfile}.linux | tail -1 | sed 's/ //g' | tr '\t' '#' | tr ',' '#' | tr ';' ' '  | wc -w | awk '{print $1}')
	fi

	if [ ${n1} != ${n2} ] || [ ${n1} != ${n3} ] || [ ${n2} != ${n3} ]; then
	    if [ ${n1} -gt 1 ]; then
		spt=","
	    elif [ ${n2} -gt 1 ]; then
		cat $TMP_DIR/${labfile}.linux | tr '\t' ',' > $TMP_DIR/${labfile}.linuxNEU
		chmod 777 $TMP_DIR/${labfile}.linuxNEU
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
	
	
	if [ ${kopfz} -gt 0 ] && [ ${kopfz} -lt 21 ]; then
	    echo "Kopfzeile ist in Zeile ${kopfz}"
	    spalteSNP=$(head -${kopfz} $TMP_DIR/${labfile}.linux    | tail -1 | tr '\t' ',' | tr ${spt} '\n' | sed "s/ //g" |cat -n  | awk '{print $1" "$2}'  | grep -i "snpname"    | cut -d' ' -f1)
	    spalteTIER=$(head -${kopfz} $TMP_DIR/${labfile}.linux   | tail -1 | tr '\t' ',' | tr ${spt} '\n' | sed "s/ //g" |cat -n  | awk '{print $1" "$2}'  | grep -i "sampleid"   | cut -d' ' -f1)
	    if [ -z ${spalteTIER} ] ; then
		spalteTIER=$(head -${kopfz} $TMP_DIR/${labfile}.linux   | tail -1 | tr '\t' ',' | tr ${spt} '\n' | sed "s/ //g" |cat -n  | awk '{print $1" "$2}'  | grep -i "samplename"   | cut -d' ' -f1)
	    fi
	    cat $TMP_DIR/${labfile}.linux | tr '\t' ',' | tr ${spt} ';' | cut -d';' -f${spalteTIER} | awk '{print $1}' | cat -n | awk -v h=${kopfz} '{if($1 > h) print $2}' >  $TMP_DIR/${labfile}.spalteTIER.tmp	    
	    
	    breed=$(head -1 $TMP_DIR/${labfile}.spalteTIER.tmp | cut -b1-3)
	    digits=$(head -1 $TMP_DIR/${labfile}.spalteTIER.tmp | wc -c | awk '{print $1}')
	    nSamplesImFile=$(sort -u $TMP_DIR/${labfile}.spalteTIER.tmp | wc -l | awk '{print $1}')
    	#verteile die neuen Samples auf die Rassefolder an hand der ersten 3 bytes der sampleID + check if INTERBULLID 19 bytes lang ist
	    head -1 $TMP_DIR/${labfile}.spalteTIER.tmp
        #echo $breed $digits ${nSamplesImFile}
	    if [ ${nSamplesImFile} == 1 ]; then
		if [ ${breed} == "BSW" ]; then
		    if [ ${digits} == 20 ]; then
			mv ${labfile} $EXT_DIR/BSW/${folder}/.
        		#hole sampleid fuer getid.sql
			sort -u $TMP_DIR/${labfile}.spalteTIER.tmp >> $TMP_DIR/${run}.allExternSamples.txt
		    else
			echo "oops ${labfile} hat falche SampleID InterbullID zu kurz, Tier wird nicht verarbeitet. Neue Daten besorgen."
			mv ${labfile} $EXT_DIR/refusedSamples/.
		    fi
		elif [ ${breed} == "HOL" ] ; then
		    if [ ${digits} == 20 ]; then
			mv ${labfile} $EXT_DIR/HOL/${folder}/.
		        #hole sampleid fuer getidHOL.sql
			sort -u $TMP_DIR/${labfile}.spalteTIER.tmp >> $TMP_DIR/${run}.allExternSamples.txt
		    else
			echo "oops ${labfile} hat falche SampleID: InterbullID zu kurz, Tier wird nicht verarbeitet. Neue Daten besorgen."
			mv ${labfile} $EXT_DIR/refusedSamples/.
		    fi
		elif [ ${breed} == "RED" ] ; then
		    if [ ${digits} == 20 ]; then
			mv ${labfile} $EXT_DIR/HOL/${folder}/.
		        #hole sampleid fuer getidHOL.sql
			sort -u $TMP_DIR/${labfile}.spalteTIER.tmp >> $TMP_DIR/${run}.allExternSamples.txt
		    else
			echo "oops ${labfile} hat falche SampleID: InterbullID zu kurz, Tier wird nicht verarbeitet. Neue Daten besorgen."
			mv ${labfile} $EXT_DIR/refusedSamples/.
		    fi
		elif [ ${breed} == "SIM" ] ; then
		    if [ ${digits} == 20 ]; then
			mv ${labfile} $EXT_DIR/HOL/${folder}/.
		        #hole sampleid fuer getidHOL.sql
			sort -u $TMP_DIR/${labfile}.spalteTIER.tmp >> $TMP_DIR/${run}.allExternSamples.txt
		    else
			echo "oops ${labfile} hat falche SampleID: InterbullID zu kurz, Tier wird nicht verarbeitet. Neue Daten besorgen."
			mv ${labfile} $EXT_DIR/refusedSamples/.
		    fi
		elif [ ${breed} == "LIM" ] ; then
		    if [ ${digits} == 20 ]; then
			mv ${labfile} $EXT_DIR/VMS/${folder}/.
		        #hole sampleid fuer getidHOL.sql
			sort -u $TMP_DIR/${labfile}.spalteTIER.tmp >> $TMP_DIR/${run}.allExternSamples.txt
		    else
			echo "oops ${labfile} hat falche SampleID: InterbullID zu kurz, Tier wird nicht verarbeitet. Neue Daten besorgen."
			mv ${labfile} $EXT_DIR/refusedSamples/.
		    fi
		elif [ ${breed} == "AAN" ] ; then
		    if [ ${digits} == 20 ]; then
			mv ${labfile} $EXT_DIR/VMS/${folder}/.
		        #hole sampleid fuer getidHOL.sql
			sort -u $TMP_DIR/${labfile}.spalteTIER.tmp >> $TMP_DIR/${run}.allExternSamples.txt
		    else
			echo "oops ${labfile} hat falche SampleID: InterbullID zu kurz, Tier wird nicht verarbeitet. Neue Daten besorgen."
			mv ${labfile} $EXT_DIR/refusedSamples/.
		    fi
		else
		    echo "oops ${labfile} hat keine InterbullID als sampleID oder ist weder Rasse BSW, HOL oder RED. Neue Daten besorgen"
		    mv ${labfile} $EXT_DIR/refusedSamples/.
		fi
	    else
		echo "ooops habe mehrere Samples im file ${labfile}, file wird zu $EXT_DIR/refusedSamples/ kopiert"
		mv ${labfile} $EXT_DIR/refusedSamples/.
	    fi
	    rm -f $TMP_DIR/${labfile}.linuxNEU $TMP_DIR/${labfile}.linux $TMP_DIR/${labfile}.spalteSNP.tmp $TMP_DIR/${labfile}.spalteTIER.tmp $TMP_DIR/${labfile}.spalteALLELA.tmp $TMP_DIR/${labfile}.spalteALLELB.tmp
	    
	fi
done
done



cd ${MAIN_DIR}
externalBreedsIncoming=$(cut -b1-3 $TMP_DIR/${run}.allExternSamples.txt | sort -u | tr '\n' ' ' )
#if ! test ${externalBreedsIncoming}; then
echo "Start now famous wurschtleEXTERNEegalCHIPgenotypenFuerImputingZurecht.sh"
for exB in ${externalBreedsIncoming} ; do
if [ ${exB} == "RED" ] || [ ${exB} == "SIM" ]; then
eB=HOL
elif [ ${exB} == "BSW" ]; then
eB=BSW 
elif [ ${exB} == "AAN" ] || [ ${exB} == "LIM" ]; then
eB=VMS 
else
eB=$(echo ${exB})
fi
$BIN_DIR/wurschtleEXTERNEegalCHIPgenotypenFuerImputingZurecht.sh ${eB} > $LOG_DIR/wurschtleEXTERNEegalCHIPgenotypenFuerImputingZurecht_${eB}.log
echo " ";
echo "Attention: check $LOG_DIR/wurschtleEXTERNEegalCHIPgenotypenFuerImputingZurecht_${eB}.log since it has its own logfile"
echo " ";
done
#else
#echo "habe keine externen files zum verarbeiten"
#fi
cd $MAIN_DIR

echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
