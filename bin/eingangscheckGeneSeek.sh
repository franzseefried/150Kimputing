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
#function to check competeness of Einganskontrolle
LASTANIcheck () {
existshot=N 
existresult=Y
while [ ${existshot} != ${existresult} ]; do
if test -s ${1}  ; then
RIGHT_NOW=$(date +"%x %r %Z")
existshot=Y
fi  
done
echo "file to check  ${1}  exists ${RIGHT_NOW}, check if it is ready"
shotcheck=same
shotresult=unknown
current=$(date +%s)
while [ ${shotcheck} != ${shotresult} ]; do
 lmod=$(stat -c %Y ${1} )
 RIGHT_NOW=$(date +"%x %r %Z")
 #echo $current $lmod
 if [ ${lmod} > 60 ]; then
    shotresult=same
    echo "${1} is ready now ${RIGHT_NOW}"
 fi 
done
    
}
#LASTANIcheck /qualstore03/data_tmp/50Kimputing/tmp/CH120128940056Qualitas_BOVUHDV03_20161208_FinalReport.txtSNPeingangscheck.out
#check if parameter vor no of prll R jobs was given
if [ -z ${numberOfParallelRJobs} ] ;then
echo numberOfParallelRJobs is missing which is not allowed. Check ${lokal}/parfiles/steuerungsvariablen.ctr.sh
exit 1
fi
sort -T ${SRT_DIR} -T ${SRT_DIR} -u $WORK_DIR/animal.overall.info -o $WORK_DIR/animal.overall.info
awk '{ sub("\r$", ""); print }' $WORK_DIR/animal.overall.info | cut -d';' -f1,2 | sed 's/ //g' | tr ';' ' ' | awk '{print $2,$1}' | sort -T ${SRT_DIR} -T ${SRT_DIR} -u > $WORK_DIR/samplesheet.TVDzuID.umcod


for chip in LD 50K 80K 150K 850K F250V1;do
cd $IN_DIR/${chip}
#delete empty files falls vorhanden
if ! find $IN_DIR/${chip}/ -maxdepth 0 -empty | read v; then
       for file in $( find $IN_DIR/${chip}/* ) ; do
            if [ ! -s ${file} ] ; then
               rm -f ${file};
            fi;
        done
fi
for labfile in $( ls ); do
echo $labfile
#delete eingangscheckfiles if they exist
rm -f $TMP_DIR/*${labfile}SNPeingangscheck.out


echo "Umnennen Name Dominant Red-SNP"
awk '{ sub("\r$", ""); print }' $IN_DIR/${chip}/${labfile}  | sed 's/Dominant Red/Dominant_Red/g' > $TMP_DIR/${labfile}.linux


kopfz=$(head -20 $TMP_DIR/${labfile}.linux | cat -n | grep -i Allele1 | awk '{print $1}')
if [ ${kopfz} -gt 0 ] && [ ${kopfz} -lt 21 ]; then
    echo "${labfile} hat Kopfzeile in Zeile ${kopfz}"
    spalteSNP=$(head    -${kopfz} $TMP_DIR/${labfile}.linux | tail -1 | tr '\t' '\n' | sed "s/ //g" |cat -n  | awk '{print $1" "$2}'  | grep -i "snpname"    | cut -d' ' -f1)
    spalteTIER=$(head   -${kopfz} $TMP_DIR/${labfile}.linux | tail -1 | tr '\t' '\n' | sed "s/ //g" |cat -n  | awk '{print $1" "$2}'  | grep -i "sampleid"   | cut -d' ' -f1)
    spaltebALLELe=$(head -${kopfz} $TMP_DIR/${labfile}.linux | tail -1 | tr '\t' '\n' | sed "s/ //g" |cat -n  | awk '{print $1" "$2}'  | grep -i "gcscore" | cut -d' ' -f1)
    spalteALLELA=$(head -${kopfz} $TMP_DIR/${labfile}.linux | tail -1 | tr '\t' '\n' | sed "s/ //g" |cat -n  | awk '{print $1" "$2}'  | grep -i "allele1-ab" | cut -d' ' -f1)
    spalteALLELB=$(head -${kopfz} $TMP_DIR/${labfile}.linux | tail -1 | tr '\t' '\n' | sed "s/ //g" |cat -n  | awk '{print $1" "$2}'  | grep -i "allele2-ab" | cut -d' ' -f1)
    spalteBALLE=$(head -${kopfz} $TMP_DIR/${labfile}.linux | tail -1 | tr '\t' '\n' | sed "s/ //g" |cat -n  | awk '{print $1" "$2}'  | grep -i "ballelefreq" | cut -d' ' -f1)
    spalteLOGR=$(head -${kopfz} $TMP_DIR/${labfile}.linux | tail -1 | tr '\t' '\n' | sed "s/ //g" |cat -n  | awk '{print $1" "$2}'  | grep -i "logrratio" | cut -d' ' -f1)
    cutting=$(echo "${spalteSNP},${spalteTIER},${spaltebALLELe},${spalteALLELA},${spalteALLELB}")
    if [ -z ${spalteSNP} ] || [ -z ${spalteTIER} ] || [ -z ${spaltebALLELe} ] || [ -z ${spalteALLELA} ] || [ -z ${spalteALLELA} ] || [ -z ${spalteALLELB} ] || [ -z ${spalteBALLE} ] || [ -z ${spalteLOGR} ]; then
      echo "ooops one expected column in labfile ${labfile} is missing"
      echo "need to be checked"
      echo "I stop now"
      exit 1
    fi
    echo $cutting
#check if samples in labfile have plausible chip data. This chech was introduced here after one sample was shipped twice within one orderID
echo "checke an Hand der Anzahl SNP den Chip fuer jedes Tier in ${labfile}"
  awk -v krow=${kopfz} 'BEGIN{FS="\t"}{if(NR > krow)print $2}' $TMP_DIR/${labfile}.linux  | sort -T ${SRT_DIR} -T ${SRT_DIR} |uniq -c | awk '{print $1,$2}' |\
  while IFS=" "; read v animal; do
  if [ ${v} -eq 54609 ]; then
     schip=50KV2
  elif [ ${v} -eq 54001 ]; then
     schip=50KV1
  elif [ ${v} -gt 2900 ] && [ ${v} -lt 6001 ]; then
     schip=03KV1
  elif [ ${v} -gt 8700 ] && [ ${v} -lt 8801 ]; then
     schip=09KV1
  elif [ ${v} -gt 8800 ] && [ ${v} -lt 19001 ]; then
     schip=09KV2
  elif [ ${v} -gt 19000 ] && [ ${v} -lt 26001 ]; then
     schip=20KV1
  elif [ ${v} -gt 6000 ] && [ ${v} -lt 8701 ]; then
     schip=LDV1
  elif [ ${v} -gt 26000 ] && [ ${v} -lt 30001 ]; then
     schip=26KV1
  elif [ ${v} -gt 30000 ] && [ ${v} -lt 36001 ]; then
     schip=30KV1
  elif [ ${v} -gt 36000 ] && [ ${v} -lt 50001 ]; then
     schip=47KV1
  elif [ ${v} -gt 70000 ] && [ ${v} -lt 80000 ]; then
     schip=77KV1
  elif [ ${v} -gt 138000 ] && [ ${v} -lt 150000 ]; then
     schip=150KV1
  elif [ ${v} -gt 221114 ] && [ ${v} -lt 221116 ]; then
     schip=F250V1
  elif [ ${v} -gt 700000 ] && [ ${v} -lt 800000 ]; then
     schip=777KV1
  else
     echo "ooops komischer chip: ${v} SNP and ${animal}"
     exit 1
  fi
done

     echo "check if sample-snp connections are ALL uniq"
     #alt: nuni=$(awk -v krow=${kopfz} 'BEGIN{FS="\t"}{if(NR > krow) print $1,$2}' $TMP_DIR/${labfile}.linux  | sort -T ${SRT_DIR} -T ${SRT_DIR} |uniq -c | awk '{print $1,$2}' | awk '{if($1 > 1) print}' | wc -l | awk '{print $1}')
     awk -v krow=${kopfz} 'BEGIN{FS="\t"}{if(NR > krow) print $1,$2}' $TMP_DIR/${labfile}.linux > $TMP_DIR/${labfile}.uniqtest
     $BIN_DIR/unique.sh $TMP_DIR/${labfile}.uniqtest
     err=$(echo $?)
     if [ ${err} -gt 0 ]; then
        echo "OOOPS Fehler uniq.sh -> Programmabbruch wg duplicate SNP-Sample Connections"
        exit 1
     fi


     awk -v c=${spalteSNP} -v d=${spalteTIER} -v e=${spaltebALLELe} -v f=${spalteALLELA} -v g=${spalteALLELB}   'BEGIN{FS="\t";OFS=";"}{print $c,$d,$e,$f,$g}' $TMP_DIR/${labfile}.linux |\
        awk -v h=${kopfz} '{if(NR > h) print $1,$2,$3,$4,$5,$6}' >  $TMP_DIR/${labfile}.tmp
#schreiben einer crossrefliste fuer genoexpse abstammungskontrolle link von sampleID zu TVD via filename
    awk -v g=${labfile} 'BEGIN{FS=";"}{ \
      if(FILENAME==ARGV[1]){if(NR>0){sub("\015$","",$(NF));sp[$1]=$15;}} \
      else {sub("\015$","",$(NF));bpT=sp[$2]; \
      if   (bpT != "") print $2";"bpT";"g}}' $WORK_DIR/crossref.txt $TMP_DIR/${labfile}.tmp | sort -T ${SRT_DIR} -T ${SRT_DIR} -u -T $SRT_DIR > $CHCK_DIR/${run}/${labfile}.linklist.genoexPSE
    $BIN_DIR/awk_umkodierungSAMPLEidIDanimalgeneseek_GGPLDv3 $WORK_DIR/crossref.txt $TMP_DIR/${labfile}.tmp  | sed 's/ //g' | tee  $TMP_DIR/${labfile}.tvd | cut -d';' -f2 | sort -T ${SRT_DIR} -T ${SRT_DIR} -u -T ${SRT_DIR} > $TMP_DIR/${labfile}.tiere

   #weglegen B-Allele und LogR ins Archiv
    cat $TMP_DIR/${labfile}.linux | tr '\t' ';' |\
    awk -v cc=${spalteSNP} -v dd=${spalteTIER} -v ee=${spalteBALLE} -v ff=${spalteLOGR} 'BEGIN{FS=";"}{print $cc";"$dd";"$ee";"$ff}' |\
    cat -n |  awk -v h=${kopfz} '{if($1 > h) print $2,$3,$4,$5}' >  $TMP_DIR/${labfile}.ballogr

    $BIN_DIR/awk_umkodierungSAMPLEidIDanimalgeneseek_GGPLDv3 $WORK_DIR/crossref.txt $TMP_DIR/${labfile}.ballogr  | sed 's/ //g' | tr ';' ' ' > ${TMP_DIR}/${labfile}.Ballele_LogR
    $BIN_DIR/awk_umkodierungTVDzuidanimal $WORK_DIR/samplesheet.TVDzuID.umcod ${TMP_DIR}/${labfile}.Ballele_LogR > ${LOGRBAL_DIR}/${labfile}.Ballele_LogR
    rm -f ${TMP_DIR}/${labfile}.Ballale_LogR
else
    echo "Habe keinen Header gefunden"
    exit 1
fi


#Kontrolle ob alle umkodierungen funktioniert haben:
if grep -q "#####"  $TMP_DIR/${labfile}.tvd; then
    echo "Umkodierung unvollstaendig"
    echo "es hat Laborergebnisse zu denen wir keine Refernz im Samplesheet haben, diese werden parkiert in $LOG_DIR/${labfile}.tvd_UNKNOWNSAMPLES "
    #echo "run on konsole:" fgrep \"#####\" $TMP_DIR/${labfile}.tvd \| head"
    #exit 1
    grep  "######" $TMP_DIR/${labfile}.tvd > $LOG_DIR/${labfile}.tvd_UNKNOWNSAMPLES    
    grep  -v "######" $TMP_DIR/${labfile}.tvd > $TMP_DIR/${labfile}.tvd_KNOWN
    mv $TMP_DIR/${labfile}.tvd_KNOWN $TMP_DIR/${labfile}.tvd
    nover=$(wc -l $TMP_DIR/${labfile}.tvd | awk '{print $1}')
    grep  -v "######" $TMP_DIR/${labfile}.tiere > $TMP_DIR/${labfile}.tiere_KNOWN
    mv $TMP_DIR/${labfile}.tiere_KNOWN $TMP_DIR/${labfile}.tiere
else
    echo "Umkodierung vollstaendig"
fi
    echo "Tier %badGCS" > $CHCK_DIR/${run}/gcscore.check.${labfile}
    echo "Tier %Callingrate" > $CHCK_DIR/${run}/callingrate.check.${labfile}
    echo "Tier %Heterozygotie" > $CHCK_DIR/${run}/heterorate.check.${labfile}
    echo "Tier AnzahlSNPs" > $CHCK_DIR/${run}/nSNPs.check.${labfile} 
    echo "Tier" > $TMP_DIR/${labfile}.tiereTOremove
nover=$(wc -l $TMP_DIR/${labfile}.tvd | awk '{print $1}')

if [ ${nover} -gt 0 ]; then
#########################################################
echo "GC calculation , callrate und heterozygotie werden jetzt gerechnet"
nanimal=$(awk 'END{print NR}' $TMP_DIR/${labfile}.tiere )
#echo ${nanimal}
runs_ani=$(cat $TMP_DIR/${labfile}.tiere | tr '\n' ' ' )
pids=
nJobs=0
for muni in ${runs_ani[@]}; do
#echo $muni
  while [ $nJobs -ge $numberOfParallelRJobs ]; do
    pids_old=${pids[@]}
    pids=
    nJobs=0
    for pid in ${pids_old[@]}; do
      if kill -0 $pid > /dev/null 2>&1; then # kill -0 $pid ist true falls der Job noch laeuft
        nJobs=$(($nJobs+1))
        pids=(${pids[@]} $pid)
      fi
    done
    sleep 10
  done
  nohup ${BIN_DIR}/calcSampleParameters.sh -t ${muni} -l ${labfile} -d ${MAIN_DIR} > $LOG_DIR/${muni}.${labfile}.eingangscheck.log 2>&1 &
  pid=$!
#  echo $pid
  pids=(${pids[@]} $pid)
  nJobs=$(($nJobs+1))
done



#check if all animals have been analyzed
for allanicheck in ${runs_ani}; do
LASTANIcheck $TMP_DIR/${allanicheck}${labfile}SNPeingangscheck.out
done

for outfile in $(ls $TMP_DIR/*${labfile}SNPeingangscheck.out); do
muni=$(basename $outfile | awk '{print substr($1,1,14)}')

#echo $muni ${labfile}
    if [ $(echo $labfile | awk '$1 ~ "BOVF250V1" {print NF};  $1 !~ "BOVF250V1" {print "0"}') -gt 0 ] ; then
    head -1 ${outfile} | tail -1 | sed "s/^/${muni} /g" | awk -v c=${CLLRT} '{if($2 < (c - 0.05)) print  $1,$2" OOOPS"; else print $1,$2}' >> $CHCK_DIR/${run}/callingrate.check.${labfile}
    else 
    head -1 ${outfile} | tail -1 | sed "s/^/${muni} /g" | awk -v c=${CLLRT} '{if($2 < c) print  $1,$2" OOOPS"; else print $1,$2}' >> $CHCK_DIR/${run}/callingrate.check.${labfile}
    fi    
    head -2 ${outfile} | tail -1 | sed "s/^/${muni} /g" | awk -v c=${HTRT} '{if($2 > c) print  $1,$2" OOOPS"; else print $1,$2}' >> $CHCK_DIR/${run}/heterorate.check.${labfile}
    if [ $(echo $labfile | awk '$1 ~ "BOVF250V1" {print NF};  $1 !~ "BOVF250V1" {print "0"}') -gt 0 ] ; then
    head -3 ${outfile} | tail -1 | sed "s/^/${muni} /g" | awk -v c=${GCSCR} '{if($2 > (c + 0.2)) print  $1,$2" OOOPS"; else print $1,$2}' >> $CHCK_DIR/${run}/gcscore.check.${labfile}
    else
    head -3 ${outfile} | tail -1 | sed "s/^/${muni} /g" | awk -v c=${GCSCR} '{if($2 > c) print  $1,$2" OOOPS"; else print $1,$2}' >> $CHCK_DIR/${run}/gcscore.check.${labfile}
    fi
    head -4 ${outfile} | tail -1 | sed "s/^/${muni} /g" | awk '{print $1,$2}' >> $CHCK_DIR/${run}/nSNPs.check.${labfile}
    if [ $(echo $labfile | awk '$1 ~ "BOVF250V1" {print NF};  $1 !~ "BOVF250V1" {print "0"}') -gt 0 ] ; then
    head -1 ${outfile} | tail -1 | sed "s/^/${muni} /g" | awk -v c=${CLLRT} '{if($2 < (c - 0.05)) print  $1}' >> $TMP_DIR/${labfile}.tiereTOremove
    else
    head -1 ${outfile} | tail -1 | sed "s/^/${muni} /g" | awk -v c=${CLLRT} '{if($2 < c) print  $1}' >> $TMP_DIR/${labfile}.tiereTOremove
    fi
    head -2 ${outfile} | tail -1 | sed "s/^/${muni} /g" | awk -v c=${HTRT} '{if($2 > c) print  $1}' >> $TMP_DIR/${labfile}.tiereTOremove
    if [ $(echo $labfile | awk '$1 ~ "BOVF250V1" {print NF};  $1 !~ "BOVF250V1" {print "0"}') -gt 0 ] ; then
    head -3 ${outfile} | tail -1 | sed "s/^/${muni} /g" | awk -v c=${GCSCR} '{if($2 > (c + 0.2)) print  $1}' >> $TMP_DIR/${labfile}.tiereTOremove
    else
    head -3 ${outfile} | tail -1 | sed "s/^/${muni} /g" | awk -v c=${GCSCR} '{if($2 > c) print  $1}' >> $TMP_DIR/${labfile}.tiereTOremove
    fi
done 

cn=$(grep " OOOPS" $CHCK_DIR/${run}/*.check.${labfile} | wc -l  | awk '{print $1}' )
if [ ${cn} -gt 0 ]; then
    echo "Es hat Tiere in ${labfile} die mindestens einen check nicht erfuellen:"
    grep " OOOPS" $CHCK_DIR/${run}/*.check.${labfile} | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1 
else
    echo "Alle Tiere in ${labfile} sind gut :-D"
fi

#########################################################
echo "Loesche Tiere die Callrate, GCSore oder Heterozygotie nicht erfuellen"
$BIN_DIR/awk_keepGoodSamplesOnly <(cat  $TMP_DIR/${labfile}.tiereTOremove | sort -T ${SRT_DIR} -T ${SRT_DIR} -u | awk '{print $1" r"}' | sort -T ${SRT_DIR} -T ${SRT_DIR} -t' ' -k1,1) <(awk 'BEGIN{FS=";"}{print $1,$2,$4,$5}' $TMP_DIR/${labfile}.tvd | sort -T ${SRT_DIR} -t' ' -k2,2) |\
        tee $LAB_DIR/${labfile}.tvd.toWorkWith | cut -d' ' -f2 | sort -T ${SRT_DIR} -T ${SRT_DIR} -u -T ${SRT_DIR} > $TMP_DIR/${labfile}.tiere.toWorkWith
fi

#########################################################
echo "check no of SNPs being uniq within labfile"
SNPnUNIQ=$(awk '{if(NR > 1) print $2}' $CHCK_DIR/${run}/nSNPs.check.${labfile} | sort -T ${SRT_DIR} -T ${SRT_DIR} -u -T $SRT_DIR | wc -l | awk '{print $1}' )
if [ ${SNPnUNIQ} != 1 ]; then
echo " "
echo "OOOPS $labfile includes samples which differ interms of No. of SNPs. This is not allowed: reject labfile and order new one in the lab"
$BIN_DIR/sendAttentionMailAboutNoSNPsCheck.sh ${labfile}
fi

#########################################################
rm -f $WORK_DIR/${labfile}*
#rm -f $TMP_DIR/*${labfile}*
rm -f $IN_DIR/${chip}/${labfile}
rm -f $TMP_DIR/${labfile}.linux
rm -f $TMP_DIR/*${labfile}*ABforR
rm -f $TMP_DIR/*${labfile}*GCforR
rm -f $TMP_DIR/*${labfile}*SNPeingangscheck.out
done
done

cd ${lokal}    
echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
