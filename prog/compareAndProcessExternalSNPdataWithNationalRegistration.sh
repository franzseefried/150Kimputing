#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

###########
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###########
#set -o nounset
#set -o errexit
if [ ${dbsystem} != "rapid" ]; then
   DEUTZ_DIR=/qualstororatest01/argus_${dbsystem}
fi

ort=$(uname -a | awk '{print $1}' )
if [ ${ort} == "Darwin" ]; then
    echo "change entweder zu eiger, titlis, beverin oder castor"
    exit 1
elif [ ${ort} == "Linux" ]; then
  maschine=$(uname -a | awk '{print $2}'  | cut -d'.' -f1)
else
  echo "oops komisches Betriebssystem ich stoppe"
  exit 1
fi

echo "delete single external samples that have data being delivered but that have already Imputation result"
cd ${EXTIND_DIR};
for i in $(ls *.txt); do
r=$(head -20 ${i} | tail -1 | awk '{print substr($2,4,16)}');
echo $i $r;
done | while IFS=" "; read a snp; do
#in animal.overall.info sind nur Tiere dirn die entweder beriets im SNP-System sind oder im neuen Samplesheet sind 
t=$(awk -v g=${snp} 'BEGIN{FS=";"}{if(substr($3,4,16) == g) print $2}' ${WRK_DIR}/animal.overall.info.${oldrun} | cut -b1-100);
snpden=$(fgrep ${t} ${HIS_DIR}/*.RUN${oldrun}.IMPresult.tierlis | cut -d' ' -f2 | head -1)
if [ ! -z ${snpden} ]; then
if [ ${snpden} > 0 ]; then
echo "${a} is deleted since sample ${snp} has already an Imputation result with chipdensity ${snpden}";
rm -f ${a}
$BIN_DIR/sendInformationMailHOL.sh ${a} ${snp} ${snpden}
fi
fi
done
#delete empty files
for file in $( ls * ) ; do
    if [ ! -s ${file} ] ; then
        echo "file ${file} is empty and deleted";
        rm -f ${file};
    fi;
done

cd ${MAIN_DIR}

	

echo "Verschaffe mir den Ueberblick was fuer SNP-Daten abgegeben wurden"
cd $EXTIND_DIR
rm -f $EXTIN_DIR/DAexterneSNP.auftragcsv.csv
rm -f $TMP_DIR/externeSNPauftraege.uniq.txt 

for labfile in $( ls ); do
    	
awk '{ sub("\r$", ""); print }' ${labfile}  > $TMP_DIR/${labfile}.linux
#finde Header
kopfz=$(head -20 $TMP_DIR/${labfile}.linux | cat -n | grep -i Allele1 | awk '{print $1}')
#echo $labfile $kopfz
if [ -z "${kopfz}" ] ; then 
echo "${labfile} Kopfzeile nicht gefunden: file wird gelöscht. Info per Mail an Barras & Barenco"
rm -f ${labfile}
else
#frage Feldtrenner ab Leerschlag, Semikolon oder Tabulator abgefangen
n1=$(head -${kopfz} $TMP_DIR/${labfile}.linux | tail -1 | sed 's/ //g' | tr '\t' '#' | tr ';' '#' | tr ',' ' '  | wc -w | awk '{print $1}')
n2=$(head -${kopfz} $TMP_DIR/${labfile}.linux | tail -1 | sed 's/ //g' | tr ',' '#'  | tr ';' '#' | tr '\t' ' ' | wc -w | awk '{print $1}')
n3=$(head -${kopfz} $TMP_DIR/${labfile}.linux | tail -1 | sed 's/ //g' | tr '\t' '#' | tr ',' '#' | tr ';' ' '  | wc -w | awk '{print $1}')
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
      #echo "unbekannter Feldtrenner :-( in $labfile"
      #exit 1
      echo "${labfile} hat unbekannten Feldtrenner: file wird gelöscht. Info per Mail an Barras & Barenco"
      rm -f ${labfile}
   fi
else
   #echo "unbekannter Feldtrenner :-( $labfile"
   #exit 1
   echo "${labfile} hat unbekannten Feldtrenner: file wird gelöscht. Info per Mail an Barras & Barenco"
   rm -f ${labfile}
fi
		
	
	
if [ ${kopfz} -gt 0 ] && [ ${kopfz} -lt 21 ]; then
#echo "Kopfzeile ist in Zeile ${kopfz}"
spalteTIER=$(head -${kopfz} $TMP_DIR/${labfile}.linux   | tail -1 | tr '\t' ',' | tr ${spt} '\n' | sed "s/ //g" |cat -n  | awk '{print $1" "$2}'  | grep -i "sampleid"   | cut -d' ' -f1)
if [ -z ${spalteTIER} ] ; then
spalteTIER=$(head -${kopfz} $TMP_DIR/${labfile}.linux   | tail -1 | tr '\t' ',' | tr ${spt} '\n' | sed "s/ //g" |cat -n  | awk '{print $1" "$2}'  | grep -i "samplename"   | cut -d' ' -f1)
fi
cutting=$(echo "${spalteTIER}")
#echo $cutting
#Abfangen Spaltenreihenfolge
cat $TMP_DIR/${labfile}.linux | tr '\t' ',' | tr ${spt} ';' | cut -d';' -f${spalteTIER} | awk '{print $1}' | cat -n | awk -v h=${kopfz} '{if($1 > h) print $2}' >  $TMP_DIR/${labfile}.spalteTIER.tmp
#abfangen anzahl tiere im file
nAni=$(sort -u $TMP_DIR/${labfile}.spalteTIER.tmp | wc -l | awk '{print $1}' )
if [ ${nAni} == 1 ]; then
ANIMAL=$(sort -u $TMP_DIR/${labfile}.spalteTIER.tmp | awk '{print $1}' )
ANIMALO=$(sort -u $TMP_DIR/${labfile}.spalteTIER.tmp | awk '{print $1}' | cut -b4-19 )
#test if animal is in Auftrag CSV von SHZV / SHB
nsnp=$(wc -l $TMP_DIR/${labfile}.spalteTIER.tmp | awk '{print $1}')
#echo $labfile $ANIMALO $nIN $nsnp $nSHB
checkITBid=$(echo $ANIMAL | awk '{if(length($1) == 19) print "Y"; else print "N"}')
if [ ${checkITBid} == "Y" ]; then
echo $ANIMAL >> $TMP_DIR/externeSNPauftraege.uniq.txt  
echo "$labfile $ANIMALO $ANIMAL $nsnp" | tr ' ' '\;' >> $EXTIN_DIR/DAexterneSNP.auftragcsv.csv
else
echo "$labfile hat ungueltige ITBID: ${ANIMAL} , file mit den Genotypen wird geloescht"
rm -f $labfile
fi
else
echo "$labfile $ANIMALO hat $nIN Samples im file"
echo "check manually and separate them, so that each animal has its own file"
fi	
fi
fi		
done

sort -u $TMP_DIR/externeSNPauftraege.uniq.txt -o $TMP_DIR/externeSNPauftraege.uniq.txt
echo "Ueberblick vorhanden, habe nun so viele externe SNP-Daten"
wc -l $TMP_DIR/externeSNPauftraege.uniq.txt
echo " "

echo "Mache nun den Check welche ITBIDs im nationalen Pedigree drin ist"
echo " "
cat -n $TMP_DIR/externeSNPauftraege.uniq.txt |\
	awk '{print $1,$2}' |\
    while IFS=" "; read a line; do
	check=$(echo $line | cut -b4-19)
	breed=$(echo $line | cut -b1-3)
	if [ ${breed} == "BSW" ]; then
		fgrep $check /qualstore03/data_zws/pedigree/data/bvch/${DatPEDIbvch}_pedigree_rrtdm_BVCH.dat  > $TMP_DIR/${line}.natipedi
	elif [ ${breed} == "HOL" ]; then
		fgrep $check /qualstore03/data_zws/pedigree/data/shb/${DatPEDIshb}_pedigree_rrtdm_SHB.dat  > $TMP_DIR/${line}.natipedi
	elif [ ${breed} == "RED" ]; then
		fgrep $check /qualstore03/data_zws/pedigree/data/shb/${DatPEDIshb}_pedigree_rrtdm_SHB.dat  > $TMP_DIR/${line}.natipedi
	elif [ ${breed} == "SIM" ]; then
		fgrep $check /qualstore03/data_zws/pedigree/data/shb/${DatPEDIshb}_pedigree_rrtdm_SHB.dat  > $TMP_DIR/${line}.natipedi
	else
		fgrep $check /qualstore03/data_zws/pedigree/data/vms/${DatPEDIvms}_pedigree_rrtdm_VMS.dat  > $TMP_DIR/${line}.natipedi
	fi
	s=$(wc -l $TMP_DIR/${line}.natipedi | awk '{print $1}')
	if [ ${s} -eq 1 ]; then
		tvdpedi=$(awk '{print substr($0,58,14)}' $TMP_DIR/${line}.natipedi)
		bytetvd=$(echo ${tvdpedi} | sed 's/ //g' | wc -c | awk '{print $1}' )	
		if [ ${bytetvd} -eq 15 ]; then
			echo "${line};ArgusOK;${tvdpedi}"
		else
			echo "${line};ArgusOK;${tvdpedi};ooops TVD nicht 14 stellig"
		fi
	elif [ ${s} -eq 0 ]; then
		tvdpedi=$(echo "-")
		echo "${line};ArgusMISSING;${tvdpedi}"
	else
		tvdpedi=$(echo "ooops")
		echo "${line};RedonlineOOOPS;${tvdpedi}"	
	fi
	rm -f  $TMP_DIR/${line}.natipedi
	done  > $TMP_DIR/externeSNPauftraege.ARGUSpedicheck.txt
echo " "
echo "pedicheck done"
echo "Anzahl records"
wc -l $TMP_DIR/externeSNPauftraege.ARGUSpedicheck.txt
echo "Aufteilung ARGUS vorhanden JA / NEIN"
cut -d';' -f2 $TMP_DIR/externeSNPauftraege.ARGUSpedicheck.txt | sort | uniq -c
echo " "

echo "Process and move files now (old processAuftraegeZOsWithExistingSNPdata.sh)"
echo " "

if test -s $EXTIN_DIR/DAexterneSNP.auftragcsv.csv; then
echo " reduziere auf die die Eintrag in nationalem Pedigree haben"
	awk '{ sub("\r$", ""); print }'	$EXTIN_DIR/DAexterneSNP.auftragcsv.csv | sort -t';' -k3,3 | join -t';' -o'1.3 1.1 1.3 1.4 2.2 2.3' -1 3 -2 1 - <(sort -t';' -k1,1 $TMP_DIR/externeSNPauftraege.ARGUSpedicheck.txt) | sort -u > $TMP_DIR/response.uniq.txt

	cat $TMP_DIR/response.uniq.txt | tr ';' ' ' |\
	  awk '{if($5 == "ArgusOK") print $1,$2,$3,$4,$5,$6}' > $TMP_DIR/response.process.txt
else
	echo " ooops $EXTIN_DIR/DAexterneSNP.auftragcsv.csv existiert nicht. Bitte pruefen Skript stoppt hier"
	exit 1	

fi

np=$(wc -l $TMP_DIR/response.process.txt | awk '{print $1}')
if [ ${np} -gt 0 ]; then
	echo "folgende Chips liegen vor:"
    awk '{print $4}' $TMP_DIR/response.process.txt | sort | uniq -c | awk '{print $1"x",$2" Chip"}'
    echo " "
	echo "process 50K"
	awk '{if($4 > 54000 && $4 < 54610) print $2}' $TMP_DIR/response.process.txt |\
	   while read file; do
	   	  mv $EXTIND_DIR/$file $EXT_DIR/50K/.
	   done
   	echo "process 150K"
	awk '{if($4 > 129999 && $4 < 150000) print $2}' $TMP_DIR/response.process.txt |\
	   while read file; do
	   	  mv $EXTIND_DIR/$file $EXT_DIR/150K/.
	   done
   	echo "process 850K"
	awk '{if($4 > 700000) print $2}' $TMP_DIR/response.process.txt |\
	   while read file; do
	   	  mv $EXTIND_DIR/$file $EXT_DIR/850K/.
	   done
	echo "process LD "
	awk '{if($4 < 54001 ) print $2}' $TMP_DIR/response.process.txt |\
	   while read file; do
	   	  mv $EXTIND_DIR/$file $EXT_DIR/LD80K/.
	   done
	echo "process 80K"
	awk '{if($4 > 54609 && $4 < 130000) print $2}' $TMP_DIR/response.process.txt |\
	   while read file; do
	   	  mv $EXTIND_DIR/$file $EXT_DIR/LD80K/.
	   done
	#echo "process alle komischen ChipsLD + 80K"
	#awk '{if($4 != 54609 || $4 != 54001 || $4 != 76999 || $4 != 138892 || $4 != 777962) print $2}' $TMP_DIR/response.process.txt |\
	#   while read file; do
	#   	  mv $EXTIND_DIR/$file $EXT_DIR/unknownChips/.
	#   done
 

	(awk '{if($4 > 54000 && $4 < 54610 && substr($3,1,3) == "BSW") print $3";X;;;;;;;;;;;;;"$6";SBZV;;;;;;;;"}' $TMP_DIR/response.process.txt;
	 awk '{if($4 > 54000 && $4 < 54610 && substr($3,1,3) == "HOL") print $3";X;;;;;;;;;;;;;"$6";SHSF;;;;;;;;"}' $TMP_DIR/response.process.txt;
 	 awk '{if($4 > 54000 && $4 < 54610 && substr($3,1,3) == "RED") print $3";X;;;;;;;;;;;;;"$6";SHSF;;;;;;;;"}' $TMP_DIR/response.process.txt;
 	 awk '{if($4 > 54000 && $4 < 54610 && substr($3,1,3) == "SIM") print $3";X;;;;;;;;;;;;;"$6";SHSF;;;;;;;;"}' $TMP_DIR/response.process.txt;
 	 awk '{if($4 > 54000 && $4 < 54610 && substr($3,1,3) != "HOL" && substr($3,1,3) != "BSW" && substr($3,1,3) != "SIM" && substr($3,1,3) != "RED") print $3";X;;;;;;;;;;;;;"$6";VMS;;;;;;;;"}' $TMP_DIR/response.process.txt
	 awk '{if($4 > 129999 && $4 < 150000 && substr($3,1,3) == "BSW") print $3";X;;;;;;;;;;;;;"$6";SBZV;;;;;;;;"}' $TMP_DIR/response.process.txt;
	 awk '{if($4 > 129999 && $4 < 150000 && substr($3,1,3) == "HOL") print $3";X;;;;;;;;;;;;;"$6";SHSF;;;;;;;;"}' $TMP_DIR/response.process.txt;
 	 awk '{if($4 > 129999 && $4 < 150000 && substr($3,1,3) == "RED") print $3";X;;;;;;;;;;;;;"$6";SHSF;;;;;;;;"}' $TMP_DIR/response.process.txt;
 	 awk '{if($4 > 129999 && $4 < 150000 && substr($3,1,3) == "SIM") print $3";X;;;;;;;;;;;;;"$6";SHSF;;;;;;;;"}' $TMP_DIR/response.process.txt;
 	 awk '{if($4 > 129999 && $4 < 150000 && substr($3,1,3) != "HOL" && substr($3,1,3) != "BSW" && substr($3,1,3) != "SIM" && substr($3,1,3) != "RED") print $3";X;;;;;;;;;;;;;"$6";VMS;;;;;;;;"}' $TMP_DIR/response.process.txt;
 	 awk '{if($4 > 700000 && substr($3,1,3) == "BSW") print $3";;X;;;;;;;;;;;;"$6";SBZV;;;;;;;;"}' $TMP_DIR/response.process.txt;
	 awk '{if($4 > 700000 && substr($3,1,3) == "HOL") print $3";;X;;;;;;;;;;;;"$6";SHSF;;;;;;;;"}' $TMP_DIR/response.process.txt;
	 awk '{if($4 > 700000 && substr($3,1,3) == "RED") print $3";;X;;;;;;;;;;;;"$6";SHSF;;;;;;;;"}' $TMP_DIR/response.process.txt;
	 awk '{if($4 > 700000 && substr($3,1,3) == "SIM") print $3";;X;;;;;;;;;;;;"$6";SHSF;;;;;;;;"}' $TMP_DIR/response.process.txt;
	 awk '{if($4 > 700000 && substr($3,1,3) != "HOL" && substr($3,1,3) != "BSW" && substr($3,1,3) != "SIM" && substr($3,1,3) != "RED") print $3";;X;;;;;;;;;;;;"$6";VMS;;;;;;;;"}' $TMP_DIR/response.process.txt;
	 awk '{if($4 < 54001 && substr($3,1,3) == "BSW") print $3";;;X;;;;;;;;;;;"$6";SBZV;;;;;;;;"}' $TMP_DIR/response.process.txt;
	 awk '{if($4 < 54001 && substr($3,1,3) == "HOL") print $3";;;X;;;;;;;;;;;"$6";SHSF;;;;;;;;"}' $TMP_DIR/response.process.txt;
 	 awk '{if($4 < 54001 && substr($3,1,3) == "RED") print $3";;;X;;;;;;;;;;;"$6";SHSF;;;;;;;;"}' $TMP_DIR/response.process.txt;
 	 awk '{if($4 < 54001 && substr($3,1,3) == "SIM") print $3";;;X;;;;;;;;;;;"$6";SHSF;;;;;;;;"}' $TMP_DIR/response.process.txt;
 	 awk '{if($4 < 54001 && substr($3,1,3) != "HOL" && substr($3,1,3) != "BSW" && substr($3,1,3) != "SIM" && substr($3,1,3) != "RED") print $3";;;X;;;;;;;;;;;"$6";VMS;;;;;;;;"}' $TMP_DIR/response.process.txt;
	 awk '{if($4 > 54609 && $4 < 130001 && substr($3,1,3) == "BSW") print $3";;;X;;;;;;;;;;;"$6";SBZV;;;;;;;;"}' $TMP_DIR/response.process.txt;
	 awk '{if($4 > 54609 && $4 < 130001 && substr($3,1,3) == "HOL") print $3";;;X;;;;;;;;;;;"$6";SHSF;;;;;;;;"}' $TMP_DIR/response.process.txt
 	 awk '{if($4 > 54609 && $4 < 130001 && substr($3,1,3) == "RED") print $3";;;X;;;;;;;;;;;"$6";SHSF;;;;;;;;"}' $TMP_DIR/response.process.txt
 	 awk '{if($4 > 54609 && $4 < 130001 && substr($3,1,3) == "SIM") print $3";;;X;;;;;;;;;;;"$6";SHSF;;;;;;;;"}' $TMP_DIR/response.process.txt
 	 awk '{if($4 > 54609 && substr($3,1,3) != "HOL" && substr($3,1,3) != "BSW" && substr($3,1,3) != "SIM" && substr($3,1,3) != "RED") print $3";;;X;;;;;;;;;;;"$6";VMS;;;;;;;;"}' $TMP_DIR/response.process.txt)	> $WRK_DIR/allExternSamples_forAdding.${run}.txt
	echo " "

	#echo "sending now InfoMail an Juerg Moll zum Abrechnen der externen SNPs Imputing: $WRK_DIR/allExternSamples_forAdding.${run}.txt" 
    #    sendingInfo=$(cut -d';' -f1 $WRK_DIR/allExternSamples_forAdding.${run}.txt | tr '\n' '#')
    #    $BIN_DIR/sendInformationMailMOLL.sh ${sendingInfo}
    
    
    #print header Marinas files auch wenn keine Dritttypis vorhanden sind
       echo "ITB-Nr;TvdNr;;RasseCode" > $WRK_DIR/Dritttypisierungen.${run}.csv
       
    if test -s $WRK_DIR/allExternSamples_forAdding.${run}.txt; then
       echo "schreibe file fuer marina und deren abrechnung"
       awk 'BEGIN{FS=";";OFS=";"}{print $1,$15,$16}' $WRK_DIR/allExternSamples_forAdding.${run}.txt > $TMP_DIR/Dritttypisierungen.${run}.csv
       externalBreedsIncoming=$(cut -b1-3 $TMP_DIR/Dritttypisierungen.${run}.csv | sort -u | tr '\n' ' ' )
       for exB in ${externalBreedsIncoming} ; do
       if [ ${exB} == "RED" ] || [ ${exB} == "SIM" ] || [ ${exB} == "HOL" ] ; then
          eB=HOL
          natpdrg=/qualstore03/data_zws/pedigree/data/shb/${DatPEDIshb}_pedigree_rrtdm_SHB.dat
       elif [ ${exB} == "BSW" ]; then 
          eB=$(echo ${exB})
          natpdrg=/qualstore03/data_zws/pedigree/data/bvch/${DatPEDIbvch}_pedigree_rrtdm_BVCH.dat
       else
          eB=$(echo ${exB})
          natpdrg=/qualstore03/data_zws/pedigree/data/vms/${DatPEDIvms}_pedigree_rrtdm_VMS.dat
       fi
      
       awk '{print substr($0,58,14)";"substr($0,83,2)}' ${natpdrg} > $TMP_DIR/natpd.abrechnung.dat
       awk 'BEGIN{FS=";";OFS=";"}{ \
         if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));CD[$1]=$2;}} \
         else {sub("\015$","",$(NF));sD=CD[$2]; \
         if   (sD != "") {print $0,sD}}}' $TMP_DIR/natpd.abrechnung.dat $TMP_DIR/Dritttypisierungen.${run}.csv >> $WRK_DIR/Dritttypisierungen.${run}.csv
       done
    fi
	mv $WRK_DIR/Dritttypisierungen.${run}.csv ${DEUTZ_DIR}/qualitas/batch/out/.
	$BIN_DIR/sendInformationMailMarina.sh ${DEUTZ_DIR}/qualitas/batch/out/Dritttypisierungen.${run}.csv
	echo " "
else 
	echo "habe keine externen files zum verarbeiten, next Skripts are prog/setUpSampleSheetByAddingExternSamples.sh + designFor.infofile.sh + masterskriptHandleNewSNPdata.sh "
fi
rm -f $TMP_DIR/*.linux
rm -f $TMP_DIR/*.linuxNEU
rm -f $TMP_DIR/*.spalteTIER.tmp
rm -f $TMP_DIR/*.natipedi
rm -f $TMP_DIR/response.process.txt
rm -f $TMP_DIR/natpd.abrechnung.dat
rm -f $TMP_DIR/Dritttypisierungen.${run}.csv
echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
