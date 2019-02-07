program Evaluate_ImputingAcc_FImpute

implicit none

integer,parameter :: iExitStatus=1


!#########################################################################################

! Parameters for parameter file
integer::iParUnit
character(200)::cParamFile,c1,c2 
character(200)::cNumAnim,cNumMarker,cLogFile
character(200)::cIn_Val_truegeno,cIn_Val_impgeno,cIn_MAF_ALL
character(200)::cIn_MAF,cIn_GeneContent,cIn_SNPInfo
character(200)::cOut_CorrelationFile,cOut_CorrFileMAF,cOut_CorrSNP
character(25) ::cSNP_ID

integer :: k
integer :: iLU,iVT,iVI,iMAF,iMAFALL,iGC,iSI,iC,iSN,iCS
! integer:: iRT,iRI
integer :: iNumAnim,iNumMarker
integer :: iChr,iPos,iChip1,iChip2

integer :: i,j,l,m,s,t,u,v,w,x,y,z,n,o,p,q,qq
integer :: CountLen,CountTotal,CountCorrect,CountIncorrect,CountNotimputed
integer,allocatable :: bta(:),bp(:),snpinfo(:),mafgroup(:)
integer,allocatable :: impGenoV(:,:),impVanRaden(:),trueSnpV(:,:),iCompSNPV(:,:)
integer,allocatable :: impGeno(:,:),trueSnp(:,:),iCompSNP(:,:)

real :: rMAF
real :: CorrectMAF(13),IncorrectMAF(13),NotimputedMAF(13)
real ,allocatable :: CorrectMAFx(:,:),IncorrectMAFx(:,:),NotimputedMAFx(:,:)
real,allocatable   :: correctx(:),incorrectx(:),notimputedx(:),allelex(:),genecont(:),doscont(:)
real,allocatable   :: correctxa(:),incorrectxa(:),notimputedxa(:)
real,allocatable   :: impgeneContV(:,:),truegeneContV(:,:),rFreqA1(:),rFreqA2(:)
real,allocatable   :: impgeneCont(:,:),truegeneCont(:,:)

double precision,allocatable :: maf(:),Correlationsa(:),CorrVec(:,:),Correlationss(:,:),Correlationss1(:)
double precision, allocatable :: Correlationdo(:),maf_all(:),Correlationsax(:)


character(len=300)   :: Mafgrouptext(1:13)
character(len=300) ,allocatable :: snpname(:)
character(len=30) ,allocatable :: id(:)


!#########################################################################################


!---------------------------------------------------------------------------------------------------
! Test Parameter file and save parameters
!---------------------------------------------------------------------------------------------------

! Get parameter filename from command line
call get_command_argument(1,cParamFile)
if(cParamFile=='')then
  write(*,*)'ERROR: Parameter file missing -> END PROGRAM'
  call EXIT(iExitStatus)
endif

! Open Parameter file
iParUnit=getFreeUnit()
open(iParUnit,file=TRIM(cParamFile),status='old',iostat=k)
if(k/=0)then
  write(*,*)'ERROR: Parameter file cParamFile cannot be opened-> END PROGRAM'
  call EXIT(iExitStatus)
endif

! Test if parameters in parameter file are too long
do
  read(iParUnit,*,iostat=k)c1
  if(k/=0)exit
  if(c1(1:1)=='#')cycle
  backspace(iParUnit)
  read(iParUnit,*)c1,c2
  if(LEN_TRIM(c1)>200)then
    write(*,*) 'ERROR: Parameter name is too long (maximal 200 Characters) -> END PROGRAM'
    write(*,*) 'There is a problem with the Parameter: ',c1
    call EXIT(iExitStatus)
  endif
  if(LEN_TRIM(c2)>200)then
    write(*,*) 'ERROR: Parameter name is too long (maximal 200 Characters) -> END PROGRAM'
    write(*,*) 'There is a problem with the Parameter: ',c2
    call EXIT(iExitStatus)
  endif
enddo
rewind(iParUnit)

! Set parameters to default values
call emptyString(cNumAnim)
call emptyString(cNumMarker)
call emptyString(cLogFile)
call emptyString(cIn_Val_truegeno)
call emptyString(cIn_Val_impgeno)
call emptyString(cIn_MAF)
call emptyString(cIn_MAF_ALL)
call emptyString(cIn_GeneContent)
call emptyString(cIn_SNPInfo)
call emptyString(cOut_CorrelationFile)
call emptyString(cOut_CorrFileMAF)
call emptyString(cOut_CorrSNP)


! Read character information from parameter file
do
  read(iParUnit,*,iostat=k)c1,c2
  if(k/=0)exit
  if(c1(1:1)=='#')cycle
  backspace(iParUnit)
  read(iParUnit,*,iostat=k)c1,c2
  if(TRIM(c1)=='NumAnim')cNumAnim=TRIM(ADJUSTL(c2))
  if(TRIM(c1)=='NumMarker')cNumMarker=TRIM(ADJUSTL(c2))
  if(TRIM(c1)=='LogFile')cLogFile=TRIM(ADJUSTL(c2))
  if(TRIM(c1)=='In_Val_truegeno')cIn_Val_truegeno=TRIM(ADJUSTL(c2))
  if(TRIM(c1)=='In_Val_impgeno')cIn_Val_impgeno=TRIM(ADJUSTL(c2))
  if(TRIM(c1)=='In_MAF')cIn_MAF=TRIM(ADJUSTL(c2))  
  if(TRIM(c1)=='In_MAF_ALL')cIn_MAF_ALL=TRIM(ADJUSTL(c2))
  if(TRIM(c1)=='In_GeneContent')cIn_GeneContent=TRIM(ADJUSTL(c2))
  if(TRIM(c1)=='In_SNPInfo')cIn_SNPInfo=TRIM(ADJUSTL(c2))
  if(TRIM(c1)=='Out_CorrelationFile')cOut_CorrelationFile=TRIM(ADJUSTL(c2))
  if(TRIM(c1)=='Out_CorrFileMAF')cOut_CorrFileMAF=TRIM(ADJUSTL(c2))
  if(TRIM(c1)=='Out_CorrSNP')cOut_CorrSNP=TRIM(ADJUSTL(c2))
enddo

write(*,*)'####################################################################################################'
write(*,*)'##############################   Folgende Parameter wurden gesetzt:   ##############################'
write(*,*)'####################################################################################################'
write(*,*) 'NumAnim				         ',TRIM(cNumAnim)
write(*,*) 'NumMarker			             ',TRIM(cNumMarker)
write(*,*) 'LogFile                        ',TRIM(cLogFile)
write(*,*) 'In_Val_truegeno                ',TRIM(cIn_Val_truegeno)
write(*,*) 'In_Val_impgeno                 ',TRIM(cIn_Val_impgeno)
write(*,*) 'In_MAF                         ',TRIM(cIn_MAF)
write(*,*) 'In_MAF_ALL                     ',TRIM(cIn_MAF_ALL)
write(*,*) 'In_GeneContent                 ',TRIM(cIn_GeneContent)
write(*,*) 'In_SNPInfo                     ',TRIM(cIn_SNPInfo)
write(*,*) 'Out_CorrelationFile            ',TRIM(cOut_CorrelationFile)
write(*,*) 'Out_CorrFileMAF                ',TRIM(cOut_CorrFileMAF)
write(*,*) 'Out_CorrSNP                 ',TRIM(cOut_CorrSNP)

write(*,*)'####################################################################################################'


!#########################################################################################

! Test Parameters - if parameters are missing, exit program
if(TRIM(cNumAnim)=='')then
  write(*,*)'ERROR: Obligatorischer Parameter NumAnim fehlt im Parameterfile --> PROGRAMMABBRUCH'
  call EXIT(iExitStatus)
endif
if(TRIM(cNumMarker)=='')then
  write(*,*)'ERROR: Obligatorischer Parameter NumMarker fehlt im Parameterfile --> PROGRAMMABBRUCH'
  call EXIT(iExitStatus)
endif
if(TRIM(cLogFile)=='')then
  write(*,*)'ERROR: Obligatorischer Parameter LogFile fehlt im Parameterfile --> PROGRAMMABBRUCH'
  call EXIT(iExitStatus)
endif
if(TRIM(cIn_Val_truegeno)=='')then
  write(*,*)'ERROR: Obligatorischer Parameter In_Val_truegeno fehlt im Parameterfile --> PROGRAMMABBRUCH'
  call EXIT(iExitStatus)
endif
if(TRIM(cIn_Val_impgeno)=='')then
  write(*,*)'ERROR: Obligatorischer Parameter In_Val_impgeno fehlt im Parameterfile --> PROGRAMMABBRUCH'
  call EXIT(iExitStatus)
endif
if(TRIM(cIn_MAF)=='')then
  write(*,*)'ERROR: Obligatorischer Parameter cIn_MAF fehlt im Parameterfile --> PROGRAMMABBRUCH'
  call EXIT(iExitStatus)
endif
if(TRIM(cIn_MAF_ALL)=='')then
  write(*,*)'WARNUNG:Parameter cIn_MAF_ALL fehlt im Parameterfile --> KEIN AUSSCHLUSS DER MONOMORPHEN SNPs MÖGLICH'
endif

if(TRIM(cIn_GeneContent)=='')then
  write(*,*)'ERROR: Obligatorischer Parameter In_GeneContent fehlt im Parameterfile --> PROGRAMMABBRUCH'
  call EXIT(iExitStatus)
endif
if(TRIM(cIn_SNPInfo)=='')then
  write(*,*)'ERROR: Obligatorischer Parameter In_SNPInfo fehlt im Parameterfile --> PROGRAMMABBRUCH'
  call EXIT(iExitStatus)
endif
if(TRIM(cOut_CorrelationFile)=='')then
  write(*,*)'ERROR: Obligatorischer Parameter Out_CorrelationFile fehlt im Parameterfile --> PROGRAMMABBRUCH'
  call EXIT(iExitStatus)
endif
if(TRIM(cOut_CorrFileMAF)=='')then
  write(*,*)'ERROR: Obligatorischer Parameter Out_CorrFileMAF fehlt im Parameterfile --> PROGRAMMABBRUCH'
  call EXIT(iExitStatus)
endif
if(TRIM(cOut_CorrSNP)=='')then
  write(*,*)'ERROR: Obligatorischer Parameter Out_CorrSNP fehlt im Parameterfile --> PROGRAMMABBRUCH'
  call EXIT(iExitStatus)
endif

!#########################################################################################

! Open Log File
iLU=getFreeUnit()
open(iLU,file=TRIM(cLogFile),status='replace',iostat=k)
if(k/=0)then
  write(*,*)'ERROR: Oeffnen von LogFile fehlgeschlagen --> PROGRAMMABBRUCH'
  call EXIT(iExitStatus)
endif

! Write information to log file
write(iLU,*)'####################################################################################################'
write(iLU,*)'##############################   Folgende Parameter wurden gesetzt:   ##############################'
write(iLU,*)'####################################################################################################'
write(iLU,*) 'NumAnim				         ',TRIM(cNumAnim)
write(iLU,*) 'NumMarker			             ',TRIM(cNumMarker)
write(iLU,*) 'LogFile                        ',TRIM(cLogFile)
write(iLU,*) 'In_Val_truegeno                ',TRIM(cIn_Val_truegeno)
write(iLU,*) 'In_Val_impgeno                 ',TRIM(cIn_Val_impgeno)
write(iLU,*) 'In_MAF                         ',TRIM(cIn_MAF)
write(iLU,*) 'In_MAF_ALL                     ',TRIM(cIn_MAF_ALL)
write(iLU,*) 'In_GeneContent                 ',TRIM(cIn_GeneContent)
write(iLU,*) 'In_SNPInfo                     ',TRIM(cIn_SNPInfo)
write(iLU,*) 'Out_CorrelationFile            ',TRIM(cOut_CorrelationFile)
write(iLU,*) 'Out_CorrFileMAF            ',TRIM(cOut_CorrFileMAF)
write(iLU,*) 'Out_CorrSNP                 ',TRIM(cOut_CorrSNP)
write(iLU,*)'####################################################################################################'



! Convert character parameters to integers...
call str2int(cNumAnim,iNumAnim,k)
call str2int(cNumMarker,iNumMarker,k)

! Allocate vectors and matrices...(INT)
allocate(id(iNumAnim))

allocate(impGenoV(iNumAnim,iNumMarker))
allocate(impVanRaden(iNumMarker))
allocate(impGeno(iNumAnim,iNumMarker))

allocate(trueSnpV(iNumAnim,iNumMarker))
allocate(trueSnp(iNumAnim,iNumMarker))

allocate(iCompSNPV(iNumAnim,iNumMarker))
allocate(iCompSNP(iNumAnim,iNumMarker))

allocate(bta(iNumMarker))
allocate(bp(iNumMarker))
allocate(snpinfo(iNumMarker))
allocate(mafgroup(iNumMarker))

! Allocate vectors and matrices...(DOUBLE PRECISION)
allocate(maf(iNumMarker))
allocate(maf_all(iNumMarker))
allocate(rFreqA1(iNumMarker))
allocate(rFreqA2(iNumMarker))


allocate(Correlationsa(iNumAnim))
allocate(Correlationsax(iNumMarker))
allocate(Correlationdo(iNumAnim))
allocate(Correlationss(iNumAnim,13))
allocate(Correlationss1(13))

! Allocate vectors and matrices...(REAL)
!allocate(correctx(iNumAnim))
!allocate(incorrectx(iNumAnim))
!allocate(notimputedx(iNumAnim))

allocate(correctx(iNumMarker))
allocate(incorrectx(iNumMarker))
allocate(notimputedx(iNumMarker))

allocate(correctxa(iNumAnim))
allocate(incorrectxa(iNumAnim))
allocate(notimputedxa(iNumAnim))

allocate(allelex(iNumAnim))
allocate(genecont(iNumMarker))
allocate(doscont(iNumMarker))
allocate(CorrectMAFx(iNumAnim,13))
allocate(IncorrectMAFx(iNumAnim,13))
allocate(NotimputedMAFx(iNumAnim,13))


allocate(impgeneContV(iNumAnim,iNumMarker))
allocate(impgeneCont(iNumAnim,iNumMarker))

allocate(truegeneContV(iNumAnim,iNumMarker))
allocate(truegeneCont(iNumAnim,iNumMarker))

! Allocate vectors and matrices...(CHAR)
allocate(snpname(iNumMarker))


!#########################################################################################


Mafgrouptext(1)="MAF gt 0 and le 0:"
Mafgrouptext(2)="MAF gt 0 and le 0.025:"
Mafgrouptext(3)="MAF gt 0.025 and le 0.05:"
Mafgrouptext(4)="MAF gt 0.05 and le 0.075:"
Mafgrouptext(5)="MAF gt 0.075 and le 0.1:"
Mafgrouptext(6)="MAF gt 0.1 and le 0.15:"
Mafgrouptext(7)="MAF gt 0.15 and le 0.2:"
Mafgrouptext(8)="MAF gt 0.2 and le 0.25:"
Mafgrouptext(9)="MAF gt 0.25 and le 0.3:"
Mafgrouptext(10)="MAF gt 0.3 and le 0.35:"
Mafgrouptext(11)="MAF gt 0.35 and le 0.4:"
Mafgrouptext(12)="MAF gt 0.4 and le 0.45:"
Mafgrouptext(13)="MAF gt 0.45 and le 0.5:"


!INPUT FILES
! LogFile = iLU
! In_Val_truegeno = iVT
! In_Val_impgeno = iVI
! In_MAF = iMAF
! In_MAF_ALL=iMAFALL
! In_GeneContent = iGC
! In_DosContent = iDC
! In_SNPInfo = iSI
! Out_CorrelationFile = iC
! Out_CorrFileMAF=iSN

! Open In_Val_truegeno
iVT=getFreeUnit()
open(iVT,file=TRIM(cIn_Val_truegeno),status='old',iostat=k)
if(k/=0)then
  write(*,*)'ERROR: Oeffnen von true Validierungsgenotypen fehlgeschlagen --> PROGRAMMABBRUCH',iVT,k,TRIM(cIn_Val_truegeno)
  call EXIT(iExitStatus)
endif

! Open In_Val_impgeno
iVI=getFreeUnit()
open(iVI,file=TRIM(cIn_Val_impgeno),status='old',iostat=k)
if(k/=0)then
  write(*,*)'ERROR: Oeffnen von imputierte Validierungsgentoypen fehlgeschlagen --> PROGRAMMABBRUCH',iVI,k,TRIM(cIn_Val_impgeno)
  call EXIT(iExitStatus)
endif

! Open In_MAF
iMAF=getFreeUnit()
open(iMAF,file=TRIM(cIn_MAF),status='old',iostat=k)
if(k/=0)then
  write(*,*)'ERROR: Oeffnen von MAF File fehlgeschlagen --> PROGRAMMABBRUCH',iMAF,k,TRIM(cIn_MAF)
  call EXIT(iExitStatus)
endif
! Open In_MAF_ALL
iMAFALL=getFreeUnit()
open(iMAFALL,file=TRIM(cIn_MAF_ALL),status='old',iostat=k)
if(k/=0)then
  write(*,*)'WARNUNG: Oeffnen von MAF ALL File fehlgeschlagen --> Programm läuft',iMAFALL,k,TRIM(cIn_MAF_ALL)
endif

! Open In_GeneContent
iGC=getFreeUnit()
open(iGC,file=TRIM(cIn_GeneContent),status='old',iostat=k)
if(k/=0)then
  write(*,*)'ERROR: Oeffnen von Gene Content File fehlgeschlagen --> PROGRAMMABBRUCH',iGC,k,TRIM(cIn_GeneContent)
  call EXIT(iExitStatus)
endif

! Open In_SNPInfo
iSI=getFreeUnit()
open(iSI,file=TRIM(cIn_SNPInfo),status='old',iostat=k)
if(k/=0)then
  write(*,*)'ERROR: Oeffnen von SNPInfo File fehlgeschlagen --> PROGRAMMABBRUCH',iSI,k,TRIM(cIn_SNPInfo)
  call EXIT(iExitStatus)
endif

! Open Out_CorrelationFile
iC=getFreeUnit()
open(iC,file=TRIM(cOut_CorrelationFile),status='replace',iostat=k)
if(k/=0)then
  write(*,*)'ERROR: Oeffnen von Korrelation Datei (output) fehlgeschlagen --> PROGRAMMABBRUCH',iC,k,TRIM(cOut_CorrelationFile)
  call EXIT(iExitStatus)
endif

! Open Out_CorrelationFile
iSN=getFreeUnit()
open(iSN,file=TRIM(cOut_CorrFileMAF),status='replace',iostat=k)
if(k/=0)then
  write(*,*)'ERROR: Oeffnen von Korrelation MAF Datei (output) fehlgeschlagen --> PROGRAMMABBRUCH',iSN,k,TRIM(cOut_CorrFileMAF)
  call EXIT(iExitStatus)
endif

! Open Out_CorrelationSNP
iCS=getFreeUnit()
open(iCS,file=TRIM(cOut_CorrSNP),status='replace',iostat=k)
if(k/=0)then
  write(*,*)'ERROR: Oeffnen von Korrelation SNP Datei (output) fehlgeschlagen --> PROGRAMMABBRUCH',iCS,k,TRIM(cOut_CorrSNP)
  call EXIT(iExitStatus)
endif


!#########################################################################################

!Read imputed and real genotypes of validation animals
do i=1,iNumAnim
  read(iVI,*,iostat=m) id(i),impGenoV(i,:)
  if(m/=0) then
    write (*,*) 'Fehler beim Lesen von imputierte Genotyppen (Validation Tier)', m
  endif
  read(iVT,*,iostat=m) id(i),trueSnpV(i,:)
  if(m/=0) then
    write (*,*) 'Fehler beim Lesen von echte Genotypen (Validation Tier)', m
  endif
enddo 

!Read SNP information (header)
read(iSI,*,iostat=m) cSNP_ID,iChr,iPos,iChip1,iChip2

!Read Minor Allele frequencies (header)
read(iMAF,*,iostat=m) rMAF
read(iMAFALL,*,iostat=m) rMAF

do i=1,iNumMarker
  read(iSI,*,iostat=m) snpname(i),bta(i),bp(i),iChip1,snpinfo(i)
  if(m/=0) then
       write (*,*) 'Fehler beim lesen SNP info'
    endif
  read(iMAF,*,iostat=m) maf(i) 
  if(m/=0) then
    write (*,*) 'Fehler beim lesen minor allele frequencies',m,i,maf(i)
  endif
read(iMAFALL,*,iostat=m) maf_all(i) 
  if(m/=0) then
    write (*,*) 'Fehler beim lesen minor allele frequencies all',m,i,maf_all(i)
  endif
  read(iGC,*,iostat=m) genecont(i)
  if(m/=0) then 
    write (*,*) 'Fehler beim lesen genecontent'
  endif
enddo

!#########################################################################################
!Erstelle SNP-Codes: 1 = SNP korrekt imputiert
!					 2 = SNP inkorrekt imputiert
!					 3 = SNP nicht imputiert (=missing im imputierten Genotypenfile)
!					 6 = SNP am Chip (d.h. bereits genotypisiert)
!					 7 = SNP missing in True genotypes
!					 8 = SNP monomorph in True Ref+Val
!if(iScenario==1) then
!write (*,*) "Monomorphe SNPs ausschliessen"
!do i=1,iNumAnim
!    do j=1,iNumMarker
!     if(maf_all(j)/=0) then
!        if (snpinfo(j)==0) then
!             if(trueSnpV(i,j)==5) then
!                iCompSNPV(i,j)=7
!             else
!                if(trueSnpV(i,j)==impGenoV(i,j)) then
!                   iCompSNPV(i,j)=1
!                elseif (trueSnpV(i,j)/=impGenoV(i,j).and.impGenoV(i,j)==5) then
!                    iCompSNPV(i,j)=3
!                else
!                    iCompSNPV(i,j)=2
!                endif
!             endif
!        else
!           iCompSNPV(i,j)=6
!        endif 
!     else
!     iCompSNPV(i,j)=8
!     endif
!     write(iC,*) i, iCompSNPV(i,j)
!    enddo
!enddo
!
!else
!#########################################################################################
!Erstelle SNP-Codes: 1 = SNP korrekt imputiert
!					 2 = SNP inkorrekt imputiert
!					 3 = SNP nicht imputiert (=missing im imputierten Genotypenfile)
!					 6 = SNP am Chip (d.h. bereits genotypisiert)
!					 7 = SNP missing in True genotypes
!					 8 = SNP monomorph in True Ref+Val
write(*,*) "Monomorphe SNPs behalten"
do i=1,iNumAnim
    do j=1,iNumMarker
        if (snpinfo(j)==0) then
             if(trueSnpV(i,j)==5) then
                iCompSNPV(i,j)=7
             else
                if(trueSnpV(i,j)==impGenoV(i,j)) then
                   iCompSNPV(i,j)=1
                elseif (trueSnpV(i,j)/=impGenoV(i,j).and.impGenoV(i,j)==5) then
                    iCompSNPV(i,j)=3
                else
                    iCompSNPV(i,j)=2
                endif
             endif
        else
           iCompSNPV(i,j)=6
        endif 
    enddo
enddo
!endif
!


!#########################################################################################  KORREKTUR FUER GENE CONTENT
! true and imputed genotypes get corrected for mean genecontent



! Korrigiere gar nicht fuer gene content
!do i=1,iNumAnim
!  do j=1,iNumMarker
!    impgeneContV(i,j)=impGenoV(i,j)
!    truegeneContV(i,j)=trueSnpV(i,j)
!  enddo
!enddo
   

 ! Korrigiere nach Mulder/Bouwman etc.
do i=1,iNumAnim
  do j=1,iNumMarker
    impgeneContV(i,j)=impGenoV(i,j)-genecont(j)
    truegeneContV(i,j)=trueSnpV(i,j)-genecont(j)
  enddo
enddo


!#########################################################################################
! CONCORDANCE RESULTS (ANIMAL BASIS): CORRECT - INCORRECT - NOT IMPUTED
do i=1,iNumAnim
correctxa(i)=(real(count(iCompSNPV(i,:)==1))/real(count(iCompSNPV(i,:)<6)))*100
incorrectxa(i)=(real(count(iCompSNPV(i,:)==2))/real(count(iCompSNPV(i,:)<6)))*100
!write(*,*) i,id(i),correctx(i),incorrectx(i)
enddo
!#########################################################################################
! Calculate Correlations
write(*,*) '##############################################################################'
write(*,*) '                   CORRELATION FOR EACH ANIMAL                                '
write(*,*) '          calculates the correlation for each animal separately               '
write(*,*) '##############################################################################'

write(iC,*) 'ID                          %Concordance  %Incorrect  Correlation'

do i=1,iNumAnim
 CountLen=0
 do j=1,iNumMarker
     if (iCompSNPV(i,j)<6) then
          Countlen=Countlen+1
     endif
 enddo
  allocate(CorrVec(CountLen,2))
  
  CountLen=0
  do j=1,iNumMarker
     if (iCompSNPV(i,j)<6) then
          Countlen=Countlen+1
          CorrVec(CountLen,1)=truegeneContV(i,j)
          CorrVec(CountLen,2)=impgeneContV(i,j)    
     endif
  enddo
  if (CountLen>5) then
    call Pearson(CorrVec(:,1),CorrVec(:,2),CountLen,Correlationsa(i))
  else
     Correlationsa=-99.0
  endif
  deallocate(CorrVec)
write(20,'(a30,2(3x,f5.2),f8.3)') id(i),correctx(i),incorrectx(i),Correlationsa(i)
!write(*,*) id(i),correctxa(i),incorrectxa(i),Correlationsa(i)
write(iC,*) id(i),correctxa(i),incorrectxa(i),Correlationsa(i)
enddo

  

!!#########################################################################################
!! CONCORDANCE RESULTS (MARKER BASIS): CORRECT - INCORRECT - NOT IMPUTED
write(*,*) '##############################################################################'
write(*,*) '                   CORRELATION FOR EACH MARKER                                '
write(*,*) '          calculates the concordance for each marker separately               '
write(*,*) '##############################################################################'
write(iCS,*) 'BTA  Pos  SNPn  %Concordance  %Incorrect  Genecontent  SNPName'


do i=1,iNumMarker
  if (iCompSNPV(1,i)/=6) then
     correctx(i)=(real(count(iCompSNPV(:,i)==1))/real(count(iCompSNPV(:,i)<6)))*100
     incorrectx(i)=(real(count(iCompSNPV(:,i)==2))/real(count(iCompSNPV(:,i)<6)))*100
!     write(*,*) i,bta(i),bp(i),correctx(i),incorrectx(i),real(count(iCompSNPV(:,i)==1)),real(count(iCompSNPV(:,i)<6))
     write(iCS,*) bta(i),bp(i),i,correctx(i),incorrectx(i),genecont(i),snpname(i)
  endif
enddo
!
!!#########################################################################################
!!! Calculate Correlations
!write(*,*) '##############################################################################'
!write(*,*) '                   CORRELATION FOR EACH MARKER                                '
!write(*,*) '          calculates the correlation for each marker separately               '
!write(*,*) '##############################################################################'
!
!do j=1,iNumMarker
! CountLen=0
! do i=1,iNumAnim
!     if (iCompSNPV(i,j)<6) then
!          Countlen=Countlen+1
!     endif
! enddo
!  allocate(CorrVec(CountLen,2))
!  
!  CountLen=0
!  do i=1,iNumAnim
!     if (iCompSNPV(i,j)<6) then
!          Countlen=Countlen+1
!          CorrVec(CountLen,1)=truegeneContV(i,j)
!          CorrVec(CountLen,2)=impgeneContV(i,j)    
!     endif
!  enddo
!  if (CountLen>5) then
!    if(maf(j)==0) then
!      Correlationsa=500
!    else
!      call Pearson(CorrVec(:,1),CorrVec(:,2),CountLen,Correlationsax(j))
!    endif
!  else
!     Correlationsa=-99.0
!  endif
!  deallocate(CorrVec)
!!write(20,'(a30,2(3x,f5.2),f8.3)') bta(j),bp(j),j,correctx(j),incorrectx(j),Correlationsa(j)
!!write(*,*) snpname(j),bta(j),bp(j),j,correctx(j),incorrectx(j),Correlationsa(j)
!write(iCS,*) bta(j),bp(j),j,correctx(j),incorrectx(j),Correlationsax(j), genecont(j),snpname(j)
!enddo

  







! SET MINOR ALLELE FREQUENCY Groups FOR EACH SNP
mafgroup=0
write(*,*) 'Setting minor allele frequency groups (mafgroups)...'
do i=1,iNumMarker
  if (maf(i)==0) mafgroup(i)=1
  if (maf(i)>0.and.maf(i)<=0.025) mafgroup(i)=2
  if (maf(i)>0.025.and.maf(i)<=0.05) mafgroup(i)=3
  if (maf(i)>0.05.and.maf(i)<=0.075) mafgroup(i)=4
  if (maf(i)>0.075.and.maf(i)<=0.1) mafgroup(i)=5
  if (maf(i)>0.1.and.maf(i)<=0.15) mafgroup(i)=6
  if (maf(i)>0.15.and.maf(i)<=0.2) mafgroup(i)=7
  if (maf(i)>0.2.and.maf(i)<=0.25) mafgroup(i)=8
  if (maf(i)>0.25.and.maf(i)<=0.3) mafgroup(i)=9
  if (maf(i)>0.3.and.maf(i)<=0.35) mafgroup(i)=10
  if (maf(i)>0.35.and.maf(i)<=0.4) mafgroup(i)=11
  if (maf(i)>0.4.and.maf(i)<=0.45) mafgroup(i)=12
  if (maf(i)>0.45.and.maf(i)<=0.5) mafgroup(i)=13
enddo 

s=0;t=0;u=0;v=0;w=0;x=0;y=0;z=0;n=0;o=0;p=0;q=0;qq=0

write(*,*) 'Counting the number of observations in each minor allele frequency bin...'
do i=1,iNumMarker
  if (iCompSNPV(1,i)<6) then
	if (mafgroup(i)==1) then
    qq=qq+1
  elseif (mafgroup(i)==2) then
    s=s+1
   elseif (mafgroup(i)==3) then
    t=t+1
   elseif (mafgroup(i)==4) then
    u=u+1
   elseif (mafgroup(i)==5) then  
    v=v+1
   elseif (mafgroup(i)==6) then
    w=w+1
   elseif (mafgroup(i)==7) then
    x=x+1
   elseif (mafgroup(i)==8) then
    y=y+1
   elseif (mafgroup(i)==9) then
    z=z+1
   elseif (mafgroup(i)==10) then
    n=n+1
   elseif (mafgroup(i)==11) then
    o=o+1
   elseif (mafgroup(i)==12) then
    p=p+1
   elseif (mafgroup(i)==13) then
    q=q+1
   endif 
   endif
enddo


write (*,*)
write (*,'(a40,i7,f7.3)')"Anzahl MAF = 0 :",qq,(real(qq)/real(iNumMarker))
write (*,'(a40,i7,f7.3)')"Anzahl MAF gt 0 and le 0.025 :",s,(real(s)/real(iNumMarker))
write (*,'(a40,i7,f7.3)')"Anzahl MAF gt 0.025 and le 0.05 :",t,(real(t)/real(iNumMarker))
write (*,'(a40,i7,f7.3)')"Anzahl MAF gt 0.05 and le 0.075 :",u,(real(u)/real(iNumMarker))
write (*,'(a40,i7,f7.3)')"Anzahl MAF gt 0.075 and le 0.1 :",v,(real(v)/real(iNumMarker))
write (*,'(a40,i7,f7.3)')"Anzahl MAF gt 0.1 and le 0.15 :",w,(real(w)/real(iNumMarker))
write (*,'(a40,i7,f7.3)')"Anzahl MAF gt 0.15 and le 0.2 :",x,(real(x)/real(iNumMarker))
write (*,'(a40,i7,f7.3)')"Anzahl MAF gt 0.2 and le 0.25 :",y,(real(y)/real(iNumMarker))
write (*,'(a40,i7,f7.3)')"Anzahl MAF gt 0.25 and le 0.3 :",z,(real(z)/real(iNumMarker))
write (*,'(a40,i7,f7.3)')"Anzahl MAF gt 0.3 and le 0.35 :",n,(real(n)/real(iNumMarker))
write (*,'(a40,i7,f7.3)')"Anzahl MAF gt 0.35 and le 0.4 :",o,(real(o)/real(iNumMarker))
write (*,'(a40,i7,f7.3)')"Anzahl MAF gt 0.4 and le 0.45 :",p,(real(p)/real(iNumMarker))
write (*,'(a40,i7,f7.3)')"Anzahl MAF gt 0.45 and le 0.5 :",q,(real(q)/real(iNumMarker))
write (*,*)

write (iSN,*)
write (iSN,*)"Anzahl MAF = 0 :",qq
write (iSN,*)"Anzahl MAF gt 0 and le 0.025 :",s
write (iSN,*)"Anzahl MAF gt 0.025 and le 0.05 :",t
write (iSN,*)"Anzahl MAF gt 0.05 and le 0.075 :",u
write (iSN,*)"Anzahl MAF gt 0.075 and le 0.1 :",v
write (iSN,*)"Anzahl MAF gt 0.1 and le 0.15 :",w
write (iSN,*)"Anzahl MAF gt 0.15 and le 0.2 :",x
write (iSN,*)"Anzahl MAF gt 0.2 and le 0.25 :",y
write (iSN,*)"Anzahl MAF gt 0.25 and le 0.3 :",z
write (iSN,*)"Anzahl MAF gt 0.3 and le 0.35 :",n
write (iSN,*)"Anzahl MAF gt 0.35 and le 0.4 :",o
write (iSN,*)"Anzahl MAF gt 0.4 and le 0.45 :",p
write (iSN,*)"Anzahl MAF gt 0.45 and le 0.5 :",q
write (iSN,*)
write (iSN,*)"MAFGroup  %Concordance  %Incorrect  Correlation"
!Calculate correlation only within maf-group
 write(*,*)
 write(*,*) '#######################################################################################'
 write(*,*) '           CORRELATIONS - CORRECT - INCORRECT - NOT IMPUTED ACCORDING TO MAF           '

  do l=1,13
  CountLen=0
  CountTotal=0
  CountCorrect=0
  CountInCorrect=0
  CountNotImputed=0
    do i=1,iNumAnim
         do j=1,iNumMarker
             if (mafgroup(j)==l) then
                if (iCompSNPV(i,j)<6) then
                      CountLen=CountLen+1
                      CountTotal=CountTotal+1
                endif
                if (iCompSNPV(i,j)==1) then     
                   CountCorrect=CountCorrect+1
                elseif (iCompSNPV(i,j)==2) then
                   CountIncorrect=CountIncorrect+1
                elseif (iCompSNPV(i,j)==3) then   
                   CountNotImputed=CountNotImputed+1
                endif
             endif
         enddo
    enddo 
  allocate(CorrVec(CountLen,2))
  CountLen=0
    do i=1,iNumAnim
          do j=1,iNumMarker
            if (mafgroup(j)==l) then
               if (iCompSNPV(i,j)<6) then
                      CountLen=CountLen+1
                      CorrVec(CountLen,1)=truegeneContV(i,j)
                      CorrVec(CountLen,2)=impgeneContV(i,j)
               endif
            endif   
          enddo
    enddo 
    if (CountLen>100) then
      call Pearson(CorrVec(:,1),CorrVec(:,2),CountLen,Correlationss1(l))
    else
       Correlationss1(l)=-99.0
    endif
    deallocate(CorrVec)
    CorrectMAF(l)=(real(CountCorrect)/real(CountTotal))*100
    IncorrectMAF(l)=(real(CountIncorrect)/real(CountTotal))*100
    NotimputedMAF(l)=(real(CountNotImputed)/real(CountTotal))*100    
enddo


do i=1,13
     write (*,*) trim(Mafgrouptext(i)),CorrectMAF(i),&
                                &IncorrectMAF(i),Correlationss1(i)
    write (iSN,*) trim(Mafgrouptext(i)),CorrectMAF(i),&
                                &IncorrectMAF(i),Correlationss1(i)	
enddo


!! PRINT RESULTS TO Screen
! write(*,*)
! write(*,*) '#######################################################################################'
! write(*,*) '           CORRELATIONS - CORRECT - INCORRECT - NOT IMPUTED ACCORDING TO MAF           '
! do l=1,13
!     write (*,'(a30,f8.2,3(3x,f7.3))') trim(Mafgrouptext(l)),Correlationss1(i,l),CorrectMAFx(j),&
!         &IncorrectMAFx(j),NotimputedMAFx(j),j,i
! enddo
! write(*,*) 
! 
! 
!! PRINT RESULTS TO File
! write(iSN,*)
! write(iSN,*) '#######################################################################################'
! write(iSN,*) '           CORRELATIONS - CORRECT - INCORRECT - NOT IMPUTED ACCORDING TO MAF           '
! do j=1,13
!     write (iSN,'(a30,f8.2,3(3x,f7.3))') trim(Mafgrouptext(j)),Correlationss1(j),CorrectMAFx(j),&
!         &IncorrectMAFx(j),NotimputedMAFx(j)
! enddo
! write(iSN,*) 




contains



!***************************************************************************************************
integer function getFreeUnit()
!***************************************************************************************************
! Funktion, die eine freie UNIT (im Bereich zwischen 30 und 79) zurueck gibt, auf der ein File     *
! geoeffnet werden kann                                                                            *
!--------------------------------------------------------------------------------------------------*
! IN:  Nichts                                                                                      *
! OUT: Freie UNIT                                                                                  *
!--------------------------------------------------------------------------------------------------*
! Function erstellt am 17.10.2012 von Urs Schuler, Qualitas AG                                     *
! Aenderungen: 14.04.2015 von Chris Baes, HAFL/Qualitas AG                                         *
!                                                                                                  *
!***************************************************************************************************

implicit none

integer::i
logical::l1

do i=1,100
  inquire(29+i,OPENED=l1)
  if(l1)then
    if(i==100)stop 'FEHLER (in getFreeUnit function): Keine freie UNIT im Bereich zwischen 30 und 179 --> PROGRAMMABBRUCH'
    cycle
  else
    getFreeUnit=29+i; exit
  endif
enddo

end function getFreeUnit


!***************************************************************************************************
subroutine emptyString(cString)
!***************************************************************************************************
! Subroutine, die einen String leer zurück gibt                                                    *
!--------------------------------------------------------------------------------------------------*
! IN:  String                                                                                      *
! OUT: Empty String                                                                                *
!--------------------------------------------------------------------------------------------------*
! Function erstellt von Urs Schuler, Qualitas AG                                     			   *                        
!                                                                                                  *
!***************************************************************************************************

character(*),intent(inout)::cString
integer::i

if(LEN(cString)<1)then
  write(*,*)'ERROR (in emptyString): String length <1 -> END PROGRAM'; stop
endif

do i=1,LEN(cString)
  cString(i:i)=' '
enddo

end subroutine emptyString


!***************************************************************************************************
subroutine str2int(String,Int,stat)
!***************************************************************************************************
! Subroutine, die einen String zu einem Integer macht                                           *
!-----------------------------------------------------------------------------------------------*
! IN:  String                                                                                   *
! OUT: Int,stat                                                                                 *
!-----------------------------------------------------------------------------------------------*
! Function erstellt von Chris Baes, HAFL/Qualitas AG                                     		*                        
!                                                                                               *
!************************************************************************************************

character(len=*),intent(in) :: String
integer,intent(out)         :: Int
integer,intent(out)         :: stat

read(String,*,iostat=stat)  Int
    
end subroutine str2int
  
  
  
  
  
!###################################################################################################
subroutine Pearson (x,y,n,r)
!***************************************************************************************************
! Subroutine, die Korrelationen berechnet                                           *
!-----------------------------------------------------------------------------------------------*
! IN:  String                                                                                   *
! OUT: Int,stat                                                                                 *
!-----------------------------------------------------------------------------------------------*
! Subroutine erstellt von Birgit Gredler, Qualitas AG                                     		*                        
!                                                                                               *
!************************************************************************************************

implicit none
integer n
double precision prob,r,z,x(n),y(n),TINY
parameter (tiny=1.e-20)
integer j
double precision ax,ay,df,sxx,sxy,syy,t,xt,yt
!double precision betai

ax=0.0
ay=0.0
DO j=1,n
        ax=ax+x(j)
        ay=ay+y(j)
END DO
ax=ax/n
ay=ay/n
sxx=0.
syy=0.
sxy=0.
DO j=1,n
        xt=x(j)-ax
        yt=y(j)-ay
        sxx=sxx+xt**2
        syy=syy+yt**2
        sxy=sxy+xt*yt
END DO
r=sxy/(SQRT(sxx*syy)+TINY)
z=0.5*LOG(((1.+r)+TINY)/((1.-r)+TINY))
df=n-2
t=r*SQRT(df/(((1.-r)+TINY)*((1.+r)+TINY)))
!prob=betai(0.5*df,0.5,df/(df+t**2))
!prob=erfcc(ABS(z*SQRT(n-1.))/1.4142136)
prob=0
return

end subroutine Pearson


  
  
!************************************************************************************************

end program Evaluate_ImputingAcc_FImpute

!************************************************************************************************
