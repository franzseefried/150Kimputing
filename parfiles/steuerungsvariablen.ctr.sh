#!/bin/sh

#change GeneSeeks NEWDATA######################################
GeneSeekdata_LD="Qualitas_BOVG50V02_20190104,Qualitas_BOVG50V02_20190102,Qualitas_BOVG50V02_20181226,Qualitas_BOVG50V02_20181220"
GeneSeekdata_F250V1=""
GeneSeekdata_150K="Qualitas_BOVUHDV03_20190104,Qualitas_BOVUHDV03_20181221"
GeneSeekdata_850K="Qualitas_BOV770V01_20181228"
GeneSeekdata_50K=""
GeneSeekdata_80K=""
# dbsystem benoetigt fuer pedigree-export
dbsystem=rapid
#von wo sollen die historischen Genotypen gelesen werden: Archiv "A" oder die binearies aus dem oldrun "B". B is much faster
ReadGenotypes=B
#Runshortcuts
old10run=2018
old9run=2118
old8run=2218
old7run=2318
old6run=2418
old5run=2518
old4run=2618
old3run=2718
old2run=2818
oldrun=2918
#Imputation run MMYY
run=0119
#HDparameter  run shortcuts are as here in LD-Imputation######
#FHDparameter run shortcuts are as here in LD-Imputation######
#Datum Pedigree Abzug SHB und BVCH############################
DatPEDIshb=20190106
DatPEDIbvch=20190106
DatPEDIvms=20181219
DatPEDIjer=20190106
#shzv pedi: Names muss auf .txt enden!!!
pedigreeSHZV=Ped_EGcom-20190104.txt
blutfileSHZV=Rac_EGcom-20190104.txt
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
HDfollows=Y
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
ParCrossVal=YES
#Maildresse zwsteam###########################
MAILZWS="beat.bapst@qualitasag.ch;madeleine.berweger@qualitasag.ch;franz.seefried@qualitasag.ch;sophie.kunz@qualitasag.ch;urs.schuler@qualitasag.ch;mirjam.spengeler@qualitasag.ch;peter.vonrohr@qualitasag.ch;urs.schnyder@qualitasag.ch"
#haplotype segments
runsHHOB="1-25769325-28186000 1-112002445-113573798 2-288663-1812806 4-63656108-73095401 4-45095680-49066662 4-44268015-49483114 5-67939009-69708507 6-1333796-5926377 6-61836407-68986129 8-5306786-7577203 9-83945696-84616331 10-12403519-15518038 11-98921066-104493671 11-100519730-104493671 14-243959-1645654 14-74816570-79273581 16-39981351-52235631 20-59824729-61310753 21-17825892-24537688 23-26021-3975934 24-42144837-50333001 25-7878909-9468764 28-32607986-37174238 29-18998431-24378595 24-18091501-20831872"
runsHHBS="1-7788418-8492480 1-11400789-12200034 1-16942821-18161089 1-142604853-147739141 2-46525216-54763517 2-78767889-86156766 6-75066888-83580060 7-41391178-47015678 7-41450432-47036565 10-33636986-44032729 12-24302230-31767190 13-22364650-27941473 17-68292838-72912770 19-3385283-11898822 20-56060352-63859798 21-2954141-8431692 22-13018309-17298876 23-38833157-41308785 27-19759721-25777617 29-34038221-43984121 POLLED202BPINDEL 629-RYF BELTSNP"
runsSVMBSW="FH2 POLLED202BPINDEL BELTSNP PNPLA8SNP SDMSNP SMASNP ARASNP"
runsHHHO="16-HH6 18-DCM 1-143553801-150040289 3-19884048-29382616 4-32502039-39830409 4-60760468-67374218 4-94623036-101355947 6-10284334-12900652 7-3012704-4080783 7-8299510-11910848 7-18063252-20121357 8-85596091-94009575 9-14528729-18808598 11-79627826-83899253 16-12406183-20840776 17-66606822-72466595 19-18388200-20357327 20-22241467-23338824 20-38982400-40203572 21-60117851-64740700 23-39628508-46408712 25-18712221-27976688"
runsHHSI="1-78633060-79266686 3-79005322-79513079 5-16294719-18842096 5-78726797-80694126 7-84591131-86862817 8-69696997-71639500 14-29716684-34149105 1-78771750-81241376 2-133710809-134782730 4-20226204-21788150 4-107599054-109206944 6-43588288-49848545 6-92595572-95658607 6-109070928-110463724 10-84164135-88427115 11-50172707-54932791 14-14650790-15345454 15-76818709-81195586 17-52227769-54361991 25-12180728-17746692"
runsSVMHOL="Mulefoot-4863 RASGRP2SNP COPASNP "
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
REFTAB_SiTeAr=/qualstorzws01/data_zws/parameterfiles/Reftab_markeridArgus_GeneSeek1seq.txt
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
