#!/bin/bash
RIGHT_NOW=$(date)
SCRIPT=`basename ${BASH_SOURCE[0]}`
echo $RIGHT_NOW Start ${SCRIPT}
echo " "

##############################################################
lokal=$(pwd | awk '{print $1}')
source  ${lokal}/parfiles/steuerungsvariablen.ctr.sh
###############################################################



if [ -z $1 ]; then
    echo "brauche den Code welche Rasse verarbeitet werden soll, 'BSW' oder 'HOL' oder 'VMS'"
    exit 1
fi
if [ -z $2 ]; then
	echo "brauche den Code fuer das Merkmal, z.B. UKV fuer Unterkierferverkürzung"
	exit 1
fi
set -o errexit
set -o nounset
breed=${1}
trait=${2}
echo ${breed}  ${trait}
##################################################


rm -rf ${GWAS_DIR}/GWASoutput${breed}_${trait}_ssr/
mkdir ${GWAS_DIR}/GWASoutput${breed}_${trait}_ssr/
#parameterfle schreiben fuer snp11'1
(echo "title";
echo "       \"GWAS ${breed} ${trait}\";";
echo "";
echo "pedfile";
echo "       \"${TMP_DIR}/${breed}.pedi.dat\"";
echo "       prune off";
echo "       skip 1;";
echo "";
echo "gfile";
echo "       \"${TMP_DIR}/${breed}.genotypes.dat\"";
echo "       skip 1;";
echo "";
echo "mapfile";
echo "       \"${TMP_DIR}/${breed}.snpinfo.dat\"";
echo "       skip 1;";
echo "";
echo "traitfile";
echo "       name \"${trait}\"";
echo "       file \"${TMP_DIR}/${breed}.phenotypes.dat\"";
echo "       est 1";
echo "       h2 0.02";
echo "       skip 1;";
echo "";
echo "trait_stat";
echo "       plot;";
echo "";
echo "threshold";
echo "       maf_range 0.01 0.5;";
echo "";
echo "kinship";
echo "       matrix";
echo "       method vanraden";
echo "       method_diag vanraden";
echo "       name \"kin1\";";
echo ""
echo "gwas ssr";
echo "       kinship name \"kin1\"";
echo "       aireml";
echo "       sig 0.01, 0.05";
echo "       mca gwise bonf";
echo "       plot manhattan";
echo "       plot qq;";
echo "";
echo "nthread";
echo "       ${numberOfParallelMEHDIJobs};";
echo "";
echo "output_folder";
echo "       \"${GWAS_DIR}/GWASoutput${breed}_${trait}_ssr\";";) > $TMP_DIR/${breed}.${trait}.use

$FRG_DIR/snp1101 $TMP_DIR/${breed}.${trait}.use

#awk '{if(NR > 1 && $6 != "-" && $6 != "-nan") print $1,$1"_"$2,$2,"A1","A2",$3,$4,$5,$6}'  $GWAS_DIR/GWASoutput${breed}_${trait}_ssr/gwas_ssr_${trait}_p.txt > $GWAS_DIR/${breed}.${trait}.snp1101mme.fplot.fimpute.ergebnis
rm -f $GWAS_DIR/GWASoutput${breed}_${trait}_ssr/gmtx_kin1.bin
rm -f $GWAS_DIR/GWASoutput${breed}_${trait}_ssr/amtx_kin1.bin
rm -f $TMP_DIR/${breed}.${trait}.use
#plotting now done inside ssnp110 with gnuplot
#cat $BIN_DIR/plotSNP1101GWASresult_fimpute.ergebnis.R | sed "s/WWWWWWWWWW/${breed}/g" | sed "s/XXXXXXXXXX/${BTA}/g" | sed "s/YYYYYYYYYY/${trait}/g" > $TMP_DIR/${breed}.${BTA}.${trait}.SNP1101plotGWASresult.fimpute.ergebnis.doit
#chmod 777 $TMP_DIR/${breed}.${BTA}.${trait}.SNP1101plotGWASresult.fimpute.ergebnis.doit
#Rscript $TMP_DIR/${breed}.${BTA}.${trait}.SNP1101plotGWASresult.fimpute.ergebnis.doit 


rm -rf ${GWAS_DIR}/GWASoutput${breed}_${trait}_lrg/
mkdir ${GWAS_DIR}/GWASoutput${breed}_${trait}_lrg/
(echo "title";
echo "       \"GWAS ${breed} ${trait}\";";
echo "";
echo "pedfile";
echo "       \"${TMP_DIR}/${breed}.pedi.dat\"";
echo "       prune off";
echo "       skip 1;";
echo "";
echo "gfile";
echo "       \"${TMP_DIR}/${breed}.genotypes.dat\"";
echo "       skip 1;";
echo "";
echo "mapfile";
echo "       \"${TMP_DIR}/${breed}.snpinfo.dat\"";
echo "       skip 1;";
echo "";
echo "traitfile";
echo "       name \"${trait}\"";
echo "       file \"${TMP_DIR}/${breed}.phenotypes.dat\"";
echo "       est 1";
echo "       h2 0.02";
echo "       skip 1;";
echo "";
echo "trait_stat";
echo "       plot;";
echo "";
echo "threshold";
echo "       maf_range 0.01 0.5;";
echo "";
echo "kinship";
echo "       matrix";
echo "       method vanraden";
echo "       method_diag vanraden";
echo "       name \"kin1\";";
echo ""
echo "gwas gqls";
echo "       kinship name \"kin1\"";
echo "       sig 0.01, 0.05";
echo "       mca gwise bonf";
echo "       plot manhattan";
echo "       plot qq;";
echo "";
echo "nthread";
echo "       30;";
echo "";
echo "output_folder";
echo "       \"${GWAS_DIR}/GWASoutput${breed}_${trait}_lrg\";";) > $TMP_DIR/${breed}.${trait}.use

$FRG_DIR/snp1101 $TMP_DIR/${breed}.${trait}.use

#awk '{if(NR > 1 && $6 != "-" && $6 != "-nan") print $1,$1"_"$2,$2,"A1","A2",$3,$4,$5,$6}'  $GWAS_DIR/SNP1101output${breed}_${trait}_lrg/gwas_gqls_${trait}_p.txt > $GWAS_DIR/${breed}.${trait}.snp1101lrg.fplot.fimpute.ergebnis

#cat $BIN_DIR/plotSNP1101LRGGWASresult_fimpute.ergebnis.R | sed "s/WWWWWWWWWW/${breed}/g" | sed "s/XXXXXXXXXX/${BTA}/g" | sed "s/YYYYYYYYYY/${trait}/g" > $TMP_DIR/${breed}.${BTA}.${trait}.SNP1101LRGplotGWASresult.fimpute.ergebnis.doit
rm -f $TMP_DIR/${breed}.${trait}.use
rm -f $GWAS_DIR/GWASoutput${breed}_${trait}_lrg/gmtx_kin1.bin
rm -f $GWAS_DIR/GWASoutput${breed}_${trait}_lrg/amtx_kin1.bin
#chmod 777 $TMP_DIR/${breed}.${BTA}.${trait}.SNP1101LRGplotGWASresult.fimpute.ergebnis.doit
#Rscript $TMP_DIR/${breed}.${BTA}.${trait}.SNP1101LRGplotGWASresult.fimpute.ergebnis.doit 


echo " "
RIGHT_END=$(date)
echo $RIGHT_END Ende ${SCRIPT}

