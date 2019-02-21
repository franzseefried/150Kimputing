#!/bin/bash
RIGHT_NOW=$(date +"%x %r %Z")
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

cd /qualstore03/data_zws/snp/150Kimputing
##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################

cp /qualstore03/data_tmp/zws/snp/50Kimputing/work/animal.overall.info work/.
cp /qualstore03/data_tmp/zws/snp/50Kimputing/work/crossref.txt work/.
cp /qualstore03/data_tmp/zws/snp/50Kimputing/tmp/crossref.race work/.
cp /qualstore03/data_zws/snp/50Kimputing/work/allExternSamples_forAdding.${run}.txt work/.

rm -f work/currentSamplesheet/*
rm -f work/previousSamplesheets/*
cp /qualstore03/data_zws/snp/50Kimputing/work/50Kimputing/work/currentSamplesheet/* work/currentSamplesheet/.
cp /qualstore03/data_zws/snp/50Kimputing/work/50Kimputing/work/previousSamplesheets/* work/previousSamplesheets/.





echo " "
RIGHT_END=$(date )
echo $RIGHT_END Ende ${SCRIPT}

