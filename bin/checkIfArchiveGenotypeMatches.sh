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
    echo "brauche den Code fuer den print Befehl: Y or N "
    exit 1
elif [ ${1} == "Y" ]; then
        echo $1 > /dev/null
elif [ ${1} == "N" ]; then
        echo $1 > /dev/null
else
        echo " $1 != Y / N, ich stoppe"
        exit 1
fi
PRINTING=${1}

outtime=$(date +"%x" | awk 'BEGIN{FS="/"}{print $2$1$3}')

#######Funktionsdefinition
getColmnNrSemicl () {
# $1: String der Spaltenueberschirft repraesentiert
# $2: csv-File
    colNr_=$(head -1 $2 | tr ';' '\n' | grep -n "^$1$" | awk -F":" '{print $1}')
    if test -z $colNr_ ; then
        echo "FEHLER: Spalte mit den Namen $1 existiert nicht in $2 --> PROGRAMMABBRUCH"
        echo "... oder Trennzeichen in $2 ist nicht das Semikolon (;)"
        exit 1
    fi
}
##########################

#get Info about SNP from Reftab
getColmnNrSemicl SNP_Name ${ISAGPARENTAGESBOLIST} ; colORG=$colNr_
getColmnNrSemicl SNPName ${ISAGPARENTAGESBOLIST} ; colSCT=$colNr_
getColmnNrSemicl ISAG-Core ${ISAGPARENTAGESBOLIST} ; colCORE=$colNr_
getColmnNrSemicl ISAG-Extra ${ISAGPARENTAGESBOLIST} ; colEXTRA=$colNr_
getColmnNrSemicl Discovery ${ISAGPARENTAGESBOLIST} ; colDISCOVERY=$colNr_
getColmnNrSemicl MS_Imputation ${ISAGPARENTAGESBOLIST} ; colMSIMPUTATION=$colNr_
getColmnNrSemicl Top_A/B_alleles  ${ISAGPARENTAGESBOLIST} ; colALLELES=$colNr_
#echo $colORG $colSCT $colCORE $colEXTRA $colMSIMPUTATION $colALLELES


#loeschen der leeren files:
if ! find ${LAB_DIR}/ -maxdepth 0 -empty | read v; then
    for file in $( find ${LAB_DIR}/*) ; do
        if [ ! -s ${file} ] ; then
           rm -f ${file};
        fi;
    done
fi

#es werden alle vorhandenen Archiv genotypen geprueft, also auch der der neu reingekommen ist. Dies der Einfachheit halber.
cd $LAB_DIR

pids=
for labfile in $(find *) ; do
(
 rm -f $TMP_DIR/genoexpse.CLRT.NSNP.SAMPLEID.${labfile}
 rm -f ${BAT_DIR}/${outtime}.${run}.GenoExPSEsnp.${labfile}

 lbb=$(echo $labfile | cut -b1-3)
 if [ ${lbb} == "BSW" ] || [ ${lbb} == "HOL" ] || [ ${lbb} == "VMS" ]; then
 lbfshort=$(echo $labfile | cut -d'-' -f2 | cut -d'.' -f1)
 else
 lbfshort=$(echo $labfile | cut -d'.' -f1)
 fi
 echo $labfile ${lbfshort}


  nSNP=$(wc -l ${labfile} | awk '{print $1}')
  if [ ${nSNP} -eq 0 ]; then
	rm -f ${labfile}
  else
    echo " "
    echo "MatchArchiveCheck fuer ${labfile}"
    #ani=$(head -1 ${labfile} | awk '{print $2}' )
    #v=$(awk -v animal=${ani} '{if($2 == animal) print }' ${labfile} | wc -l | awk '{print $1}')
    awk -v a=${colORG} -v b=${colCORE} -v c=${colEXTRA} 'BEGIN{FS=";"}{if($b == 1 || $c == 1) print $a,"Y"}' ${ISAGPARENTAGESBOLIST} | awk '{print $1,$2,NR}' > $TMP_DIR/${labfile}.outmap.isagsnplst

  
#rechne callingrate aus. achtung es brauchte eine anpassung in Eingangscheck.R. zur entwickl des skripts
  for j in $(awk '{print $2}' ${labfile} | sort -T ${SRT_DIR} -T ${SRT_DIR} -u -T $SRT_DIR); do
  #idanimal
  IDANIMAL=$(awk -v ID=${j} 'BEGIN{FS=";"}{if($2 == ID) print $1}' $WORK_DIR/animal.overall.info | sed 's/ //g' |  head -1)
  #neue typisierung
    awk 'BEGIN{FS=" "}{ \
         if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));sp[$1]=$2;ss[$1]=$3}} \
         else {sub("\015$","",$(NF));bpT=sp[toupper($1)];spT=ss[toupper($1)]; \
         if   (bpT != "" && bpT == "Y" && spT != "") print toupper($1),$2,$3$4,spT}}' $TMP_DIR/${labfile}.outmap.isagsnplst <(awk -v jj=${j} '{if ($2 == jj) print $0}' ${labfile}) > $TMP_DIR/${labfile}.${IDANIMAL}.initial
    #auffuellen fehlende SNP neue Typisierung
    awk -v indi=${j} 'BEGIN{FS=" "}{ \
         if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));sp[$1]=$2;ss[$1]=$3;mp[$1]=$4}} \
         else {sub("\015$","",$(NF));bpT=sp[$1];spT=ss[$1];mpT=mp[$1]; \
         if   (bpT != "") print $1,bpT,spT,mpT;
         else print $1,indi,"--",$3}}' $TMP_DIR/${labfile}.${IDANIMAL}.initial $TMP_DIR/${labfile}.outmap.isagsnplst > $TMP_DIR/${labfile}.${IDANIMAL}.sekundaer
    gtNEU=$(sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k4,4n $TMP_DIR/${labfile}.${IDANIMAL}.sekundaer | awk '{gsub("AA","0",$3);gsub("AB","1",$3);gsub("BB","2",$3);gsub("--","5",$3); print $3}' | tr '\n' ' ')
   # rm -f $TMP_DIR/${labfile}.${IDANIMAL}.initial $TMP_DIR/${labfile}.${IDANIMAL}.sekundaer
    echo "${IDANIMAL}n ${gtNEU}" > $TMP_DIR/${labfile}.${IDANIMAL}.tertiaer

#hole SNP-Daten aus dem Archiv
  nDA=$(ls -trl $SNP_DIR/dataWide*/*/${IDANIMAL}.lnk | wc -l | awk '{print $1}' )
  #echo $nDA
  if [ ${nDA} -eq 1 ]; then
        errorcounterTIER=0
        snpcounterTIER=0
        #echo "habe 1 Archivfile fuer ${j}"
        fileloc=$(ls -trl  $SNP_DIR/dataWide*/*/${IDANIMAL}.lnk | awk '{print $11}')
        chip=$(echo ${fileloc} | cut -d'/' -f5 | sed 's/dataWide//g')
        #aufbau mapfile
        getColmnNrSemicl QuagCode ${REFTAB_CHIPS}; colCC=${colNr_};
        getColmnNrSemicl IntergenomicsCode ${REFTAB_CHIPS}; colDD=${colNr_};
        intname=$(awk -v cc=${colCC} -v dd=${colDD} -v ee=${chip} 'BEGIN{FS=";"}{if( $cc == ee ) print $dd }' ${REFTAB_CHIPS})
        sed 's/Dominant Red/Dominant_Red/g' $MAP_DIR/intergenomics/SNPindex_${intname}_new_order.txt | awk '{if($3 > 30) print "30",toupper($1),"0",$4;else print $3,toupper($1),"0",$4}' > $TMP_DIR/${IDANIMAL}.${labfile}.map
        #aufbau pedfile
        cat ${fileloc} | sed 's/ /o /1' | sed 's/ / 0 0 9 9 /1' | sed 's/^/1 /g' > $TMP_DIR/${IDANIMAL}.${labfile}.ped
        #schneiden der 200 AbstammungsSNP
        cat $TMP_DIR/${labfile}.outmap.isagsnplst | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 |\
          join -t' ' -o'1.1 1.2 1.3' -1 1 -2 1 - <(sed 's/Dominant Red/Dominant_Red/g' $MAP_DIR/intergenomics/SNPindex_${intname}_new_order.txt | awk '{print toupper($1),"a"}' | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 ) | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k3,3n | awk '{print $1}' | tee $TMP_DIR/${IDANIMAL}.${labfile}.GENOEXPSEmap | awk '{print $1,"B"}' > $TMP_DIR/${IDANIMAL}.${labfile}.map.force.Bcount
        #wc -l $TMP_DIR/${IDANIMAL}.${labfile}.GENOEXPSEmap
        #wc -l $TMP_DIR/${IDANIMAL}.${labfile}.map.force.Bcount
        $FRG_DIR/plink --ped $TMP_DIR/${IDANIMAL}.${labfile}.ped --map $TMP_DIR/${IDANIMAL}.${labfile}.map --allow-no-sex --missing-genotype '0' --missing-phenotype '9' --cow --extract $TMP_DIR/${IDANIMAL}.${labfile}.GENOEXPSEmap  --recodeA --reference-allele $TMP_DIR/${IDANIMAL}.${labfile}.map.force.Bcount --out $TMP_DIR/${IDANIMAL}.${labfile}.GENOEXPSE > /dev/null
        #zuerst umsortieren des gtstrings aus dem archiv
        head -1 $TMP_DIR/${IDANIMAL}.${labfile}.GENOEXPSE.raw | tr ' ' '\n' | sed -s "s/_[A-Z]$//g" | awk '{if(NR > 6) print $1}' | awk '{print $1,NR}' |sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 |\
         join -t' '  -o'1.1 1.2 2.3' -1 1 -2 1 - <(sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${labfile}.outmap.isagsnplst) | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k2,2 |\
         join -t' ' -o'1.1 1.2 1.3 2.1' -1 2 -2 2 - <(tail -1 $TMP_DIR/${IDANIMAL}.${labfile}.GENOEXPSE.raw | tr ' ' '\n' | cut -d'_' -f1 | awk '{if(NR > 6) print $1}' | awk '{print $1,NR}' | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k2,2) |\
         sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k3,3n | awk -v ii=${IDANIMAL} '{print $1,ii,$3,$4}' > $TMP_DIR/${IDANIMAL}.${labfile}.neugenoexpse
        #auffuellen fehlende SNP neue Typisierung
        awk -v indi=${IDANIMAL} 'BEGIN{FS=" "}{ \
             if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));sp[$1]=$2;ss[$1]=$4;mp[$1]=$3}} \
             else {sub("\015$","",$(NF));bpT=sp[$1];spT=ss[$1];mpT=mp[$1]; \
             if   (bpT != "") print $1,bpT,spT,mpT;
             else print $1,indi,"--",$3}}' $TMP_DIR/${IDANIMAL}.${labfile}.neugenoexpse $TMP_DIR/${labfile}.outmap.isagsnplst > $TMP_DIR/${IDANIMAL}.${labfile}.neugenoexpse.full
        gtALT=$(sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k4,4n $TMP_DIR/${IDANIMAL}.${labfile}.neugenoexpse.full | awk '{gsub("AA","0",$3);gsub("AB","1",$3);gsub("BA","1",$3);gsub("BB","2",$3);gsub("--","5",$3);gsub("NA","5",$3); print $3}' | tr '\n' ' ')
        echo "${IDANIMAL}o ${gtALT}" > $TMP_DIR/${labfile}.${IDANIMAL}.quartaer
        #Aufbau des Vergleichfiles. zuerst der neu herienkommende genotyp dann der existierende, nimme alle 200 SNPs obwohl ICAR nur 196 SNPS verwendet
        (cat  $TMP_DIR/${labfile}.${IDANIMAL}.tertiaer; cat $TMP_DIR/${labfile}.${IDANIMAL}.quartaer) | cut -d' ' -f2- > $TMP_DIR/${labfile}.${IDANIMAL}.forAnalysis
        #cat $TMP_DIR/${labfile}.${IDANIMAL}.forAnalysis
        #Identitätskontrolle hier. Genotypen muessen identisch sein. Nimm alle 200 AbstammungsSNPs
        if [[ $(wc -l <$TMP_DIR/${labfile}.${IDANIMAL}.forAnalysis) -eq 2 ]] ; then
	    imax=$(awk '{if(NR == 1) print NF}' $TMP_DIR/${labfile}.${IDANIMAL}.forAnalysis)
        for ((i=1; i<=imax; i++));do 
           #nur wenn alle 2 Genotypen vorhanden sind
           NcllrtSNP=$(awk -v j=${i} '{if(NR <= 2) print $j}' $TMP_DIR/${labfile}.${IDANIMAL}.forAnalysis | grep 5 | wc -l | awk '{print $1}')
           if [ ${NcllrtSNP} -eq 0 ]; then
           snpcounterTIER=$(echo ${snpcounterTIER} | awk '{print $1+1}')
           DELTA=$(awk -v j=${i} '{if(NR <= 2) print $j}' $TMP_DIR/${labfile}.${IDANIMAL}.forAnalysis | tr '\n' ' ' | awk ' function abs(v) {return v < 0 ? -v : v} {print abs($1-$2)}')
           #echo $i $ELTERNdelta
               if [ ${DELTA} -eq 0 ]; then
                  echo "alles ok " > /dev/null
               else
                  if [ ${PRINTING} == "Y" ]; then
                     MARKER=$(awk -v k=${i} '{if($3 == k) print $1}' $TMP_DIR/${labfile}.outmap.isagsnplst)
                     echo "${MARKER} $i FEHLER1"
                  fi
                  errorcounterTIER=$(echo ${errorcounterTIER} | awk '{print $1+1}')
               fi
           fi
       done
       fi 

       if [ ${errorcounterTIER} -gt 1 ]; then
          echo ${IDANIMAL} ${fileloc} ${labfile} ${errorcounterTIER} ${snpcounterTIER} 
          $BIN_DIR/sendAttentionMailAboutMismatchAgainstexistingGenotype.sh ${IDANIMAL} ${labfile} ${fileloc} ${errorcounterTIER} ${snpcounterTIER}
       fi
  fi

  if [ ${nDA} -gt 1 ]; then
        #echo "habe mehr als 1 Archivfile fuer ${j}"
        FFIILLEESS=$(ls -trl  $SNP_DIR/dataWide*/*/${IDANIMAL}.lnk | awk '{print $11}')
        for fileloc in ${FFIILLEESS}; do
             errorcounterTIER=0
             snpcounterTIER=0
             #fileloc=$(ls -trl  $SNP_DIR/dataWide*/*/${IDANIMAL}.lnk | awk '{print $11}')
             chip=$(echo ${fileloc} | cut -d'/' -f5 | sed 's/dataWide//g')
             #aufbau mapfile
             getColmnNrSemicl QuagCode ${REFTAB_CHIPS}; colCC=${colNr_};
             getColmnNrSemicl IntergenomicsCode ${REFTAB_CHIPS}; colDD=${colNr_};
             intname=$(awk -v cc=${colCC} -v dd=${colDD} -v ee=${chip} 'BEGIN{FS=";"}{if( $cc == ee ) print $dd }' ${REFTAB_CHIPS})
             sed 's/Dominant Red/Dominant_Red/g' $MAP_DIR/intergenomics/SNPindex_${intname}_new_order.txt | awk '{if($3 > 30) print "30",toupper($1),"0",$4;else print $3,toupper($1),"0",$4}' > $TMP_DIR/${IDANIMAL}.${labfile}.map
             #aufbau pedfile
             cat ${fileloc} | sed 's/ /o /1' | sed 's/ / 0 0 9 9 /1' | sed 's/^/1 /g' > $TMP_DIR/${IDANIMAL}.${labfile}.ped
             #schneiden der 200 AbstammungsSNP
             cat $TMP_DIR/${labfile}.outmap.isagsnplst | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 |\
               join -t' ' -o'1.1 1.2 1.3' -1 1 -2 1 - <(sed 's/Dominant Red/Dominant_Red/g' $MAP_DIR/intergenomics/SNPindex_${intname}_new_order.txt | awk '{print toupper($1),"a"}' | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 ) | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k3,3n | awk '{print $1}' | tee $TMP_DIR/${IDANIMAL}.${labfile}.GENOEXPSEmap | awk '{print $1,"B"}' > $TMP_DIR/${IDANIMAL}.${labfile}.map.force.Bcount
             #wc -l $TMP_DIR/${IDANIMAL}.${labfile}.GENOEXPSEmap
             #wc -l $TMP_DIR/${IDANIMAL}.${labfile}.map.force.Bcount
             $FRG_DIR/plink --ped $TMP_DIR/${IDANIMAL}.${labfile}.ped --map $TMP_DIR/${IDANIMAL}.${labfile}.map --allow-no-sex --missing-genotype '0' --missing-phenotype '9' --cow --extract $TMP_DIR/${IDANIMAL}.${labfile}.GENOEXPSEmap  --recodeA --reference-allele $TMP_DIR/${IDANIMAL}.${labfile}.map.force.Bcount --out $TMP_DIR/${IDANIMAL}.${labfile}.GENOEXPSE > /dev/null
             #zuerst umsortieren des gtstrings aus dem archiv
             head -1 $TMP_DIR/${IDANIMAL}.${labfile}.GENOEXPSE.raw | tr ' ' '\n' | sed -s "s/_[A-Z]$//g" | awk '{if(NR > 6) print $1}' | awk '{print $1,NR}' |sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 |\
              join -t' '  -o'1.1 1.2 2.3' -1 1 -2 1 - <(sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 $TMP_DIR/${labfile}.outmap.isagsnplst) | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k2,2 |\
              join -t' ' -o'1.1 1.2 1.3 2.1' -1 2 -2 2 - <(tail -1 $TMP_DIR/${IDANIMAL}.${labfile}.GENOEXPSE.raw | tr ' ' '\n' | cut -d'_' -f1 | awk '{if(NR > 6) print $1}' | awk '{print $1,NR}' | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k2,2) |\
              sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k3,3n | awk -v ii=${IDANIMAL} '{print $1,ii,$3,$4}' > $TMP_DIR/${IDANIMAL}.${labfile}.neugenoexpse
             #auffuellen fehlende SNP neue Typisierung
             awk -v indi=${IDANIMAL} 'BEGIN{FS=" "}{ \
                  if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));sp[$1]=$2;ss[$1]=$4;mp[$1]=$3}} \
                  else {sub("\015$","",$(NF));bpT=sp[$1];spT=ss[$1];mpT=mp[$1]; \
                  if   (bpT != "") print $1,bpT,spT,mpT;
                  else print $1,indi,"--",$3}}' $TMP_DIR/${IDANIMAL}.${labfile}.neugenoexpse $TMP_DIR/${labfile}.outmap.isagsnplst > $TMP_DIR/${IDANIMAL}.${labfile}.neugenoexpse.full
             gtALT=$(sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k4,4n $TMP_DIR/${IDANIMAL}.${labfile}.neugenoexpse.full | awk '{gsub("AA","0",$3);gsub("AB","1",$3);gsub("BA","1",$3);gsub("BB","2",$3);gsub("--","5",$3);gsub("NA","5",$3); print $3}' | tr '\n' ' ')
             echo "${IDANIMAL}o ${gtALT}" > $TMP_DIR/${labfile}.${IDANIMAL}.quartaer
             #Aufbau des Vergleichfiles. zuerst der neu herienkommende genotyp dann der existierende, nimm alle 200 SNPs obwohl ICAR nur 196 SNPS verwendet
             (cat  $TMP_DIR/${labfile}.${IDANIMAL}.tertiaer; cat $TMP_DIR/${labfile}.${IDANIMAL}.quartaer) | cut -d' ' -f2- > $TMP_DIR/${labfile}.${IDANIMAL}.forAnalysis
             #Aufbau des Vergleichfiles. zuerst der neu herienkommende genotyp dann der existierende, nimm ICAR nur 196 ICAR SNPS
             #(cat  $TMP_DIR/${labfile}.${IDANIMAL}.tertiaer; cat $TMP_DIR/${labfile}.${IDANIMAL}.quartaer) | cut -d' ' -f2-| cut -d' ' -f1-56,58-140,142-145,147-151,153-200 > $TMP_DIR/${labfile}.${IDANIMAL}.forAnalysis
             #cat $TMP_DIR/${labfile}.${IDANIMAL}.forAnalysis
             #Identitätskontrolle hier. Genotypen muessen identisch sein.
             if [[ $(wc -l <$TMP_DIR/${labfile}.${IDANIMAL}.forAnalysis) -eq 2 ]] ; then
             imax=$(awk '{if(NR == 1) print NF}' $TMP_DIR/${labfile}.${IDANIMAL}.forAnalysis) 
             for ((i=1; i<=imax; i++));do 
                #nur wenn alle 2 Genotypen vorhanden sind
                NcllrtSNP=$(awk -v j=${i} '{if(NR <= 2) print $j}' $TMP_DIR/${labfile}.${IDANIMAL}.forAnalysis | grep 5 | wc -l | awk '{print $1}')
                if [ ${NcllrtSNP} -eq 0 ]; then
                snpcounterTIER=$(echo ${snpcounterTIER} | awk '{print $1+1}')
                DELTA=$(awk -v j=${i} '{if(NR <= 2) print $j}' $TMP_DIR/${labfile}.${IDANIMAL}.forAnalysis | tr '\n' ' ' | awk ' function abs(v) {return v < 0 ? -v : v} {print abs($1-$2)}')
                #echo $i $ELTERNdelta
                    if [ ${DELTA} -eq 0 ]; then
                       echo "alles ok ${i}" > /dev/null
                    else
                       if [ ${PRINTING} == "Y" ]; then
                          MARKER=$(awk -v k=${i} '{if($3 == k) print $1}' $TMP_DIR/${labfile}.outmap.isagsnplst)
                         echo "${MARKER} $i FEHLER1"
                       fi
                    errorcounterTIER=$(echo ${errorcounterTIER} | awk '{print $1+1}')
                    fi
                fi
             done
             fi 
             if [ ${errorcounterTIER} -gt 1 ]; then
                echo ${IDANIMAL} ${fileloc} ${labfile} ${errorcounterTIER} ${snpcounterTIER} 
                $BIN_DIR/sendAttentionMailAboutMismatchAgainstexistingGenotype.sh ${IDANIMAL} ${labfile} ${fileloc} ${errorcounterTIER} ${snpcounterTIER}
             fi
         done
  fi
  done
fi
)&
pid=$!
pids=(${pids[@]} $pid)
done

sleep 20
echo "Here ar the jobids of the stated Jobs"
echo ${pids[@]}
nJobs=$(echo ${pids[@]} | wc -w | awk '{print $1}')
echo "Waiting till Jobs are finished"
while [ $nJobs -gt 0 ]; do
  pids_old=${pids[@]}
  pids=
  nJobs=0
  for pid in ${pids_old[@]}; do
    if kill -0 $pid > /dev/null 2>&1; then # kill -0 $pid ist true falls der Job noch laeuft
      nJobs=$(($nJobs+1))
      pids=(${pids[@]} $pid)
    fi
  done
  sleep 20
done
rm -f $TMP_DIR/*.outmap.isagsnplst
rm -f $TMP_DIR/*.initial
rm -f $TMP_DIR/*.sekundaer
rm -f $TMP_DIR/*.neugenoexpse
rm -f $TMP_DIR/*.neugenoexpse.full
rm -f $TMP_DIR/*.tertiaer
rm -f $TMP_DIR/*.quartaer
rm -f $TMP_DIR/*.forAnalysis
cd ${lokal}
echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
