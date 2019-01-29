#!/bin/sh

#change GeneSeeks NEWDATA######################################
GeneSeekdata_LD="Qualitas_BOVG50V02_20190118,Qualitas_BOVG50V02_20190116,Qualitas_BOVG50V02_20190114,Qualitas_BOVG50V02_20190111,Qualitas_BOVG50V02_20190110,Qualitas_BOVG50V02_20190106"
GeneSeekdata_F250V1=""
GeneSeekdata_150K="Qualitas_BOVUHDV03_20190117,Qualitas_BOVUHDV03_20190110"
GeneSeekdata_850K="Qualitas_BOV770V01_20190106"
GeneSeekdata_50K=""
GeneSeekdata_80K=""
# dbsystem benoetigt fuer pedigree-export
dbsystem=rapid
#von wo sollen die historischen Genotypen gelesen werden: Archiv "A" oder die binearies aus dem oldrun "B". B is much faster
ReadGenotypes=A
#Runshortcuts
old10run=2118
old9run=2218
old8run=2318
old7run=2418
old6run=2518
old5run=2618
old4run=2718
old3run=2818
old2run=2918
oldrun=0119
#Imputation run MMYY
run=0219
#HDparameter  run shortcuts are as here in LD-Imputation######
#FHDparameter run shortcuts are as here in LD-Imputation######
#Datum Pedigree Abzug SHB und BVCH############################
DatPEDIshb=20190119
DatPEDIbvch=20190120
DatPEDIvms=20190120
DatPEDIjer=20190120
#shzv pedi: Names muss auf .txt enden!!!
pedigreeSHZV=Ped_EGcom-20190118.txt
blutfileSHZV=Rac_EGcom-20190118.txt
#Maildresse or responsible employee###########################
MAILACCOUNT=franz.seefried@qualitasag.ch
##############################################################
#folgt eine Effektschaetzung Y fuer yes, N fuer no############
EFFESTfollows=N
#Mailversand gegenueber Zuchtverband: normal Y, ausser z.b. in Testruns: N
sendMails=N
#In case GWAS and Homozygosoty mapping is used################
GWAStrait=AllgemeinBlindOB
GWASpop=OB
GWASmaf=0.02
GWASgeno=0.05
GWASmind=0.05
GWAShwe=0.00001
HFTgroup=pgp
MaxLthHTL=200
GWASsetofANIS=HD
HFTSNPSET=HD
#suche G-verwandte zu cases
relshipthreshold=0.25
#HD LD or PD are allowed
AIMSAMPLESIZE=70
#nur HAPDIV: defninert die Anzahl Tiere die selektiert werden sollen
##############################################################
##############################################################
#    Parameters below should not be changed regularly   !!!! #
##############################################################
#Imputationsstrategie: F dann werden fixe snps aus einer alten imputation gelesen (empfohlen fuer routineruns) / S dann werden neue SNP-selektiert
snpstrat=F
#folgt eine HD Imputation Y fuer yes, N fuer no###############
HDfollows=N
#Untergenze Anteil geänderter Genotypen im Vgl zur letzen Imputation. Empfehlung geh nicht hoeher als 0.025
propBad=0.025
#No. of Chipstatus fuer die das aktuelle Imputationsergebnis mit dem letzen vergleichen werden soll: 3 d.h. alle 3 Status werden verglichen, 2 d.h. Status 0+1 wird verglichen, 1 d.h. nur Status 2 wird verglichen
compImp=3
#which animals should be taken 0 for pedigreeimputed animals also, 1 for LD/HD animals only. Betrifft Effektschaetzung und nicht Preciction
minchipstatus=0
#grenze am wann suspekte Verwandtschaft anschlaegt
maxAllowedRelship=0.2
#Grenze Sexcheck Y-chr Test fuer beide Geschlechter urspuengliche Grenze YthrldM war bei 0.769, YthrldF war bei 0.221, dann kamen zu viele falch negative, darum Grenze erhoeht
YthrldM=0.649
YthrldF=0.550
#Grenze Sexcheck PAR Test fuer beide Geschlechter
PARthrld=50
#ISAG200 callrate
ISAGCLRT=0.95
#proportion of samples below ISAGcallrate threshold
BADISAG=0.1
#grenze blutanteil fuer validierung MV genRelMat
blutanteilsgrenze=0.87
#tierset für genom. Verwandtchaftsmatrix Validierung MV (A oder N zulaessig, das neue Skript ist so schnell dass A generell möglich ist)
animalgroup=A
#untergrenze plausibler MV (LD chip geht runter bis 0.07 gemaess VHL ueberprueften Daten"
minplausibleMVrelship=0.07
#untergrenze Fuer Reporting bei Proben mit Inzucht auf MV (LD chip aub ca  0.35 gemaess VHL ueberprueften Daten"
minInbreedOnMVrelship=0.35
#Elemenbereich Genom. Relship Matrix, O fuer offdiagonalen, D fuer Diagonalen
elementzoneTWINS=O
#Threshold gnrm coefficient
gnrmcoeffTWINS=0.90
#sign for sample pair selections EQABOVE fuer >=, BELOW fuer <, dann werden alle Tiere der elementzone selektiert die entweder drueber oder unter der gnrmcoeff liegen
gnrmzone=EQABOVE
#No of parallel R jobs fuer Eingangskontrolle
numberOfParallelRJobs=$(nproc | awk '{print $1-0}')
#No of parallel Haplotyping jobs 
numberOfParallelHAPLOTYPEJobs=10
#No of parallel SingleGeneImputation jobs 
numberOfParallelSIGEIMPJobs=5
#Parameter if Crossvalidation in SVM Prediction should be applied YES / NO allowed
ParCrossVal=NO
#Maildresse zwsteam###########################
MAILZWS="beat.bapst@qualitasag.ch;madeleine.berweger@qualitasag.ch;franz.seefried@qualitasag.ch;sophie.kunz@qualitasag.ch;urs.schuler@qualitasag.ch;mirjam.spengeler@qualitasag.ch;peter.vonrohr@qualitasag.ch;urs.schnyder@qualitasag.ch"
#if you want to start a new SNP System:
#Use intergenomics codes here!!
#HDden aim
NewChip1=139_V1
ARS12Name1=139977_GGPHDV3
#LDden aim
NewChip2=48_V1
ARS12Name2=47843_BOVG50V1

##################################################
#Do NOT change:
#HD Imputation run
hdrun=${HDoldrun}
fhdrun=${FHDoldrun}
#CrossReferenzfiles:
crossreffileOLD=Samplesheet_${old10run}.txt
crossreffileMV=Samplesheet_${oldrun}.txt
crossreffile=Samplesheet_${run}.txt
REFTAB_FiRepTest=/qualstorzws01/data_zws/snp/einzelgen/argus/glossar/GeneSeekSingleTestsInFinalReport.txt
REFTAB_SiTeAr=/qualstorzws01/data_zws/snp/150Kimputing/parfiles/ReftabGenmarkerArgus.txt
REFTAB_CHIPS=/qualstorzws01/data_zws/parameterfiles/CDCBchipCodes1seq.lst
ISAGPARENTAGESBOLIST=/qualstorzws01/data_zws/parameterfiles/GenoEx-PSE_SNP_List_Details_withOwnSNPnames.csv
CLLRT=0.948
HTRT=0.45
GCSCR=0.12
fixSNPdatum=2118
HDfixSNPdatum=0116
VETDIAGfile=/qualstorzws01/data_zws/snp/150Kimputing/work/VETDIAGNOSTIK/Abort_${run}.csv
SSNPSiGeTe=/qualstorzws01/data_zws/parameterfiles/Reftab_SNPs-GenMarker.txt
#################################################################
#Main-Directories do not change
ARC_DIR=/qualstorzws01/data_archiv/zws/ogc
ARCH_DIR=/qualstorzws01/data_archiv/SNP
DEUTZ_DIR=/qualstore01/argus
MAIN_DIR=/qualstorzws01/data_zws/snp/150Kimputing
WRKF_DIR=/qualstorzws01/data_tmp/zws/snp/150Kimputing
SNP_DIR=/qualstorzws01/data_zws/snp
PEDI_DIR=/qualstorzws01/data_zws/pedigree
##################################################################
#sub-directories do not change
#ARGUS_DIR=${MAIN_DIR}/argus
BAT_DIR=${DEUTZ_DIR}/qualitas/batch/in
BIN_DIR=${MAIN_DIR}/bin
BIGPAR_DIR=/qualstorzws01/data_zws/parameterfiles/
BCP_DIR=/qualstorzws01/data_archiv/zws/150Kimputing
BVCH_DIR=${DEUTZ_DIR}/sbzv/dsch/in
CHCK_DIR=${ARCH_DIR}/checks
DIFR_DIR=${ARCH_DIR}/df
DATA_DIR=${SNP_DIR}/data
EINZELGEN_DIR=${SNP_DIR}/einzelgen/argus/import/Finalreportresults
EXTIN_DIR=${SNP_DIR}/EXTERNESNP
EXTINA_DIR=${EXTIN_DIR}/auftraege
EXTIND_DIR=${EXTIN_DIR}/datain
EXT_DIR=${SNP_DIR}/data/extern
FBK_DIR=/qualstorzws01/data_archiv/zws/ogc/repositoryFBK
FIM_DIR=${WRKF_DIR}/fimpute
FRG_DIR=${MAIN_DIR}/frg
GAL_DIR=/qualstorzws01/data_zws/gal/data
GCA_DIR=${WRKF_DIR}/gcta
GEDE_DIR=${SNP_DIR}/genotypeDelivery
GSE_DIR=${WRKF_DIR}/gensel
GNA_DIR=${WRKF_DIR}/genabel
GWAS_DIR=${MAIN_DIR}/gwas
HADI_DIR=${MAIN_DIR}/hapdiv
HOM_DIR=${MAIN_DIR}/homa
HDD_DIR=${SNP_DIR}/HDimputing/work
FHDD_DIR=${SNP_DIR}/FHDimputing/work
HD_DIR=/qualstorzws01/data_tmp/zws/snp/HDimputing/work
HDHIS_DIR=${SNP_DIR}/HDimputing/imphistory
HIS_DIR=${MAIN_DIR}/imphistory
IN_DIR=${SNP_DIR}/data/intern
ITL_DIR=${ARCH_DIR}/format705International
LDDATA_DIR=${SNP_DIR}/dataLD
LAB_DIR=${MAIN_DIR}/newsnpfiles
LOG_DIR=${MAIN_DIR}/log
LOGRBAL_DIR=${ARCH_DIR}/Ballele_LogR
LIS_DIR=${SNP_DIR}/lists
LIMS_DIR=/qualstorzws01/data_zws/snp/einzelgen/work
LDLIS_DIR=${SNP_DIR}/listsLD
MAP_DIR=${SNP_DIR}/data/mapFiles
PAR_DIR=${MAIN_DIR}/parfiles
PED_DIR=${PEDI_DIR}/data
PEDBIN_DIR=${PEDI_DIR}/bin/linux
PEDWORK_DIR=${PEDI_DIR}/data
PDF_DIR=${MAIN_DIR}/pdf
PROG_DIR=${MAIN_DIR}/prog
RES_DIR=${MAIN_DIR}/result
SMS_DIR=${WRKF_DIR}/snp1101
SHB_DIR=${DEUTZ_DIR}/swissherdbook/dsch/in
SMP_DIR=${ARCH_DIR}/samplemaps
SRT_DIR=/qualstorzws01/data_tmp
STR_DIR=${ARCH_DIR}/Illumina
TMP_DIR=${WRKF_DIR}/tmp
VMS_DIR=${DEUTZ_DIR}/mutterkuh/dsch/in
WRK_DIR=${MAIN_DIR}/work
WORK_DIR=${WRKF_DIR}/work
ZOMLD_DIR=${MAIN_DIR}/zomld
