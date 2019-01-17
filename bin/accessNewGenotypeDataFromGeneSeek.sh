#!/bin/bash
RIGHT_NOW=$(date )
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

#######################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
#######################################################
set -o nounset
#set -o errexit

#loeschen der files falls diese noch vorhanden sind
for chip in F250V1 150K 50K 80K 850K LD; do
  cd $IN_DIR/${chip}
  if ! find $IN_DIR/${chip}/ -maxdepth 0 -empty | read v; then
        echo "delete file in $IN_DIR/${chip}/ since they exist"
        ls -trl 
        for file in $( find $IN_DIR/${chip}/* ) ; do
            if [ ! -s ${file} ] ; then
               rm -f ${file};
            else
               rm -f ${file};
            fi;
        done
   else
      echo "habe keine files in $IN_DIR/${chip}/"
   fi
done


echo "folgende Ordner liegen bereit:"
for chip in F250V1 150K 50K 80K 850K LD; do
echo "^^^^^^^^^^^^^^^^^^^^${chip}"
ls -trl $DATA_DIR/intern/${chip}
echo " "
if [ ${chip} == "850K" ]; then
  outfolder=HD
else
  outfolder=$(echo ${chip})
fi
cc=$(echo "GeneSeekdata_${chip}")
ordners=$(awk -v dd=${cc} 'BEGIN{FS="="}{if($1 == dd) print $2}' ${lokal}/parfiles/steuerungsvariablen.ctr.sh | sed 's/\"//g' | tr ',' ' ' )
nordners=$(echo ${ordners} | wc -w | awk '{print $1}')
if [ ! -z ${nordners} ] ; then
if [ ${nordners} -gt 0 ] ; then
for newdata in $(echo ${ordners}) ; do
echo "++++++++++++++++++ ${newdata} is given in ${lokal}/parfiles/steuerungsvariablen.ctr.sh for ${chip}"
cd $IN_DIR/${chip}
pwd
HOST='geneseek.sharefileftp.com'
USER='u9c9e548a1'
PASSWD='Furggelenstock1655'
datei1='Sample_Map.zip'
datei2=${newdata}_FinalReport.zip
datei3=${newdata}_LocusXDNA.zip
datei4=${newdata}_LocusSummary.zip
datei5=${newdata}_DNAReport.zip
datei6='SNP_Map.zip'
ftp -n $HOST <<end_skript
quote USER $USER
quote PASS $PASSWD
cd Qualitas
cd ${newdata}
binary
get ${datei1}
get ${datei2}
get ${datei3}
get ${datei4}
get ${datei5}
get ${datei6}
quit
end_skript

for sdatei in ${datei1} ${datei2} ${datei3} ${datei4} ${datei5} ${datei6}; do
if ! test -s ${sdatei} ; then
     echo " "
     echo "${sdatei} is empty or does not exist!!!!!!!!!"
     echo " "
fi
done
echo " "
if test -s ${datei1}; then unzip ${datei1};fi
echo "Verschieben der Sample_Map + FinalReport ins Archiv"
if test -s Sample_Map.txt ; then 
mv Sample_Map.txt /qualstore03/data_archiv/SNP/samplemaps/${newdata}_Sample_Map.txt;
echo " "
echo "Count no. of records for information:"
wc -l  /qualstore03/data_archiv/SNP/samplemaps/${newdata}_Sample_Map.txt
echo " "
fi
if test -d /qualstore03/data_archiv/SNP/Illumina/${outfolder}/ownGeneSeekRoutine/${newdata} ;then
   rm -rf /qualstore03/data_archiv/SNP/Illumina/${outfolder}/ownGeneSeekRoutine/${newdata}
   mkdir /qualstore03/data_archiv/SNP/Illumina/${outfolder}/ownGeneSeekRoutine/${newdata}
else
   mkdir /qualstore03/data_archiv/SNP/Illumina/${outfolder}/ownGeneSeekRoutine/${newdata}
fi
if test -s ${datei1}; then mv ${datei1} /qualstore03/data_archiv/SNP/Illumina/${outfolder}/ownGeneSeekRoutine/${newdata}/. ;fi
if test -s ${datei2}; then cp ${datei2} /qualstore03/data_archiv/SNP/Illumina/${outfolder}/ownGeneSeekRoutine/${newdata}/. ;fi
if test -s ${datei3}; then mv ${datei3} /qualstore03/data_archiv/SNP/Illumina/${outfolder}/ownGeneSeekRoutine/${newdata}/. ;fi
if test -s ${datei4}; then mv ${datei4} /qualstore03/data_archiv/SNP/Illumina/${outfolder}/ownGeneSeekRoutine/${newdata}/. ;fi
if test -s ${datei5}; then mv ${datei5} /qualstore03/data_archiv/SNP/Illumina/${outfolder}/ownGeneSeekRoutine/${newdata}/. ;fi
if test -s ${datei6}; then mv ${datei6} /qualstore03/data_archiv/SNP/Illumina/${outfolder}/ownGeneSeekRoutine/${newdata}/. ;fi
if test -s ${datei2}; then 
unzip ${datei2}
rm -f ${datei2}
fi
cd /qualstore03/data_archiv/SNP/Illumina/${outfolder}/ownGeneSeekRoutine
tar -cvzf ${newdata}.tar.gz ${newdata}
rm -rf ${newdata}
echo " "
echo "${newdata} was archived"
ls -trl /qualstore03/data_archiv/SNP/Illumina/${outfolder}/ownGeneSeekRoutine/${newdata}.tar.gz
echo " "

cd $IN_DIR/${chip}
done
else
echo "------------------ ${chip} is given empty in ${lokal}/parfiles/steuerungsvariablen.ctr.sh "
fi
else
echo "------------------ ${chip} is NULL in ${lokal}/parfiles/steuerungsvariablen.ctr.sh "
fi
done
echo " "
echo "ftp finished"
echo " "
echo "folgende Labfiles liegen bereit:"
for chip in F250V1 150K 50K 80K 850K LD; do
echo ${chip}
ls -trl $DATA_DIR/intern/${chip}
done


echo " "
echo "have fun playing and rolling any single genotype ----- fsf"
echo " "

echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}
