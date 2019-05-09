options(echo=TRUE)

args <- commandArgs(trailingOnly=TRUE)
#args<-c("./","BSW","all","/Volumes/data_projekte/projekte/snp/ProgEvalFimpute/tmp/","/Volumes/data_tmp/projekte/snp/150Kimputing1/fimpute/")
start.time <- Sys.time()
print(args)
print(Sys.time())
truesnp<-read.table(paste(args[4],"TrueGeno.eval.scen.",args[2],".txt",sep=""))
impsnp<-read.table(paste(args[4],"ImpGeno.eval.scen.",args[2],".txt",sep=""))
if (args[3]=="all") {maf<-read.table(paste(args[4],"maf.eval.",args[2],".txt",sep=""),header=TRUE)}else{
  maf<-read.table(paste(args[4],"maf_",args[3],".eval.",args[2],".txt",sep=""),header=TRUE)
}
print(head(maf))
genecontent<-read.table(paste(args[4],"genecont.eval.",args[2],".txt",sep=""))
snpinfo<-read.table(paste(args[5],"MASK",args[2],"BTAwholeGenome.out/snp_info.txt",sep=""),header=TRUE,as.is=TRUE)

colnames(truesnp)<-c("ID",snpinfo[,1])
colnames(impsnp)<-c("ID",snpinfo[,1])
print(Sys.time())
indcorr<-matrix(0,nrow(impsnp),4)
colnames(indcorr)<-c("ID","%Concordance","%Incorrect","Correlation")
iCompSNPV<-matrix(0,nrow(impsnp),nrow(genecontent))
rownames(iCompSNPV)<-truesnp[,1]
colnames(iCompSNPV)<-snpinfo[,1]
#load("Documents/BAM_zwischenfiles/iCompSNPV")

impsnp_c<-t(apply(impsnp[,2:ncol(impsnp)],1,function(x) x-t(genecontent[1:nrow(genecontent),])))
truesnp_c<-t(apply(truesnp[,2:ncol(truesnp)],1,function(x) x-t(genecontent[1:nrow(genecontent),])))
colnames(truesnp_c)<-c(snpinfo[,1])
colnames(impsnp_c)<-c(snpinfo[,1])
rownames(truesnp_c)<-truesnp$ID
rownames(impsnp_c)<-impsnp$ID
miss3<-length(which(impsnp==5))
miss7<-length(which(truesnp==5))

for (i in 1:nrow(impsnp))
{
  truevec<-truesnp[i,2:ncol(truesnp)]
  impvec<-impsnp[i,2:ncol(impsnp)]
  impvec_c<-impsnp_c[i,]
  truevec_c<-truesnp_c[i,]
  #Erstelle SNP-Codes: 1 = SNP korrekt imputiert
  #					 2 = SNP inkorrekt imputiert
  #					 3 = SNP nicht imputiert (=missing im imputierten Genotypenfile)
  #					 6 = SNP am Chip (d.h. bereits genotypisiert)
  #					 7 = SNP missing in True genotypes
  #					 8 = SNP monomorph in True Ref+Val
  
 iCompSNPV[i,which(truevec==impvec)]<-1
 iCompSNPV[i,which(truevec!=impvec)]<-2
 if(miss7!=0){iCompSNPV[i,which(colnames(iCompSNPV)%in%truevec[truevec==5,colnames(truevec)])]<-7}
 if(miss3!=0){iCompSNPV[i,which(colnames(iCompSNPV)%in%impvec[impvec==5,colnames(impvec)])]<-3}
 iCompSNPV[,which(colnames(iCompSNPV)%in%snpinfo[snpinfo[,5]!=0,1])]<-6
  
 # for(j in 1:nrow(genecontent))
 # {
 #   
 #   if (snpinfo[j,5]==0) {if(truevec[1,j]==5){
 #     iCompSNPV[i,j]=7
 #   }else if(truevec[1,j]==impvec[1,j]){
 #     iCompSNPV[i,j]=1 } else if (truevec[1,j]!=impvec[1,j]&impvec[1,j]==5) {
 #   iCompSNPV[i,j]=3} else{
 #     iCompSNPV[i,j]=2}}
 # }
  coun<-iCompSNPV[i,iCompSNPV[i,]<3&iCompSNPV[i,]>0]
  corr<-iCompSNPV[i,iCompSNPV[i,]==1]
  incorr<-iCompSNPV[i,iCompSNPV[i,]==2]
  indcorr[i,1]<-truesnp$ID[i]
  indcorr[i,2]<-(length(corr)/length(coun))*100
  indcorr[i,3]<-(length(incorr)/length(coun))*100
  indcorr[i,4]<-round(cor(impvec_c[which(names(impvec_c)%in%names(coun))],truevec_c[which(names(truevec_c)%in%names(coun))]),6)
print(indcorr[i,])
print(i)
print(Sys.time())
  }

#load("Documents/BAM_zwischenfiles/iCompSNPV")
rownames(maf)<-snpinfo[,1]
maf<-cbind(maf,snpinfo)
maf$Corr<-apply(iCompSNPV,2,function (x) (sum(x==1)/(sum(x==1)+(sum(x==2)))))
maf$Incorr<-apply(iCompSNPV,2,function (x) ((sum(x==2))/(sum(x==1)+(sum(x==2)))))
maf$Corr_abs<-apply(iCompSNPV,2,function (x) (sum(x==1)))
maf$Incorr_abs<-apply(iCompSNPV,2,function (x) ((sum(x==2))))
maf$Genecontent<-genecontent$V1
maf<-maf[-which(rownames(maf)%in%colnames(iCompSNPV[,which(iCompSNPV[1,]==6)])),]
maf$mafgroup<-0
if(min(maf$MAF)==0){maf[maf$MAF==0,]$mafgroup<-1}

maf[maf$MAF>0&maf$MAF<=0.025,]$mafgroup<-2
maf[maf$MAF>0.025&maf$MAF<=0.05,]$mafgroup<-3
maf[maf$MAF>0.05&maf$MAF<=0.075,]$mafgroup<-4
maf[maf$MAF>0.075&maf$MAF<=0.1,]$mafgroup<-5
maf[maf$MAF>0.1&maf$MAF<=0.15,]$mafgroup<-6
maf[maf$MAF>0.15&maf$MAF<=0.2,]$mafgroup<-7
maf[maf$MAF>0.2&maf$MAF<=0.25,]$mafgroup<-8
maf[maf$MAF>0.25&maf$MAF<=0.3,]$mafgroup<-9
maf[maf$MAF>0.3&maf$MAF<=0.35,]$mafgroup<-10
maf[maf$MAF>0.35&maf$MAF<=0.4,]$mafgroup<-11
maf[maf$MAF>0.4&maf$MAF<=0.45,]$mafgroup<-12
maf[maf$MAF>0.45&maf$MAF<=0.5,]$mafgroup<-13


a<-length(which(maf$mafgroup==1))
b<-length(which(maf$mafgroup==2))
c<-length(which(maf$mafgroup==3))
d<-length(which(maf$mafgroup==4))
e<-length(which(maf$mafgroup==5))
f<-length(which(maf$mafgroup==6))
g<-length(which(maf$mafgroup==7))
h<-length(which(maf$mafgroup==8))
i<-length(which(maf$mafgroup==9))
j<-length(which(maf$mafgroup==10))
k<-length(which(maf$mafgroup==11))
l<-length(which(maf$mafgroup==12))
m<-length(which(maf$mafgroup==13))

mafres<-matrix(0,13,3)

mafres[,1]<-"Anzahl MAF"
mafres[1,2]<-" = 0 :"
mafres[2,2]<-" gt 0 and le 0.025 :"
mafres[3,2]<-" gt 0.025 and le 0.05 :"
mafres[4,2]<-" gt 0.05 and le 0.075 :"
mafres[5,2]<-" gt 0.075 and le 0.1 :"
mafres[6,2]<-" gt 0.1 and le 0.15 :"
mafres[7,2]<-" gt 0.15 and le 0.2 :"
mafres[8,2]<-" gt 0.2 and le 0.25 :"
mafres[9,2]<-" gt 0.25 and le 0.3 :"
mafres[10,2]<-" gt 0.3 and le 0.35 :"
mafres[11,2]<-" gt 0.35 and le 0.4 :"
mafres[12,2]<-" gt 0.4 and le 0.45 :"
mafres[13,2]<-" gt 0.45 and le 0.5 :"

mafres[1,3]<-a
mafres[2,3]<-b
mafres[3,3]<-c
mafres[4,3]<-d
mafres[5,3]<-e
mafres[6,3]<-f
mafres[7,3]<-g
mafres[8,3]<-h
mafres[9,3]<-i
mafres[10,3]<-j
mafres[11,3]<-k
mafres[12,3]<-l
mafres[13,3]<-m


mafres2<-matrix(0,13,4)
mafres2[1,1]<-" MAF gt 0 and le 0:"
mafres2[2,1]<-" MAF gt 0 and le 0.025:"
mafres2[3,1]<-" MAF gt 0.025 and le 0.05:"
mafres2[4,1]<-" MAF gt 0.05 and le 0.075:"
mafres2[5,1]<-" MAF gt 0.075 and le 0.1:"
mafres2[6,1]<-" MAF gt 0.1 and le 0.15:"
mafres2[7,1]<-" MAF gt 0.15 and le 0.2:"
mafres2[8,1]<-" MAF gt 0.2 and le 0.25:"
mafres2[9,1]<-" MAF gt 0.25 and le 0.3:"
mafres2[10,1]<-" MAF gt 0.3 and le 0.35:"
mafres2[11,1]<-" MAF gt 0.35 and le 0.4:"
mafres2[12,1]<-" MAF gt 0.4 and le 0.45:"
mafres2[13,1]<-" MAF gt 0.45 and le 0.5:"

mafcl<-split(maf,maf$mafgroup)
mafres2[which(1:13%in%names(unlist(lapply(mafcl,function(x) sum(x$Corr_abs)/(sum(x$Incorr_abs)+sum(x$Corr_abs)))))),2]<-unlist(lapply(mafcl,function(x) round((sum(x$Corr_abs)/(sum(x$Incorr_abs)+sum(x$Corr_abs))*100),4)))
mafres2[which(!(1:13%in%names(unlist(lapply(mafcl,function(x) sum(x$Corr_abs)/(sum(x$Incorr_abs)+sum(x$Corr_abs))))))),2]<-"-NaN"
mafres2[which(1:13%in%names(unlist(lapply(mafcl,function(x) sum(x$Incorr_abs)/(sum(x$Incorr_abs)+sum(x$Corr_abs)))))),3]<-unlist(lapply(mafcl,function(x) round((sum(x$Incorr_abs)/(sum(x$Incorr_abs)+sum(x$Corr_abs))*100),4)))
mafres2[which(!(1:13%in%names(unlist(lapply(mafcl,function(x) sum(x$Incorr_abs)/(sum(x$Incorr_abs)+sum(x$Corr_abs))))))),3]<-"-NaN"
mafres2[which(!(1:13%in%names(unlist(lapply(mafcl,function(x) sum(x$Incorr_abs)/(sum(x$Incorr_abs)+sum(x$Corr_abs))))))),3]<-"NA"


impvec_c2<-impsnp_c
rownames(impvec_c2)<-impsnp[,1]
truevec_c2<-truesnp_c
rownames(truevec_c2)<-truesnp[,1]
mafres2[,4]<-NA
for (a in unique(as.numeric(names(mafcl))))
{
  mafbetw<-as.data.frame(mafcl[as.numeric(names(mafcl)) == a ])
  impvec_c3<-impvec_c2[,which(colnames(impvec_c2)%in%rownames(mafbetw))]
  truevec_c3<-truevec_c2[,which(colnames(truevec_c2)%in%rownames(mafbetw))]
  
imp<-as.vector(t(as.matrix(impvec_c3)))
true<-as.vector(t(as.matrix(truevec_c3)))
correl<-round(cor(imp,true),6)
mafres2[a,4]<-correl
print(correl)
print(Sys.time())

}
colnames(mafres2)<-c("MAFGroup","%Concordance","%Incorrect","Correlation")
write.table(indcorr,paste(args[1],args[2],".eval.",args[3],".Ind_correlations.txt",sep=""),
            col.names = TRUE,row.names = FALSE,quote=FALSE)
k<-c(" ")
write.table(k,paste(args[1],args[2],".eval.",args[3],".MAF_correlations.txt",sep=""),
            col.names = FALSE,row.names = FALSE,quote=FALSE,sep=" ")
write.table(mafres,paste(args[1],args[2],".eval.",args[3],".MAF_correlations.txt",sep=""),
            col.names = FALSE,row.names = FALSE,quote=FALSE,sep=" ",append=TRUE)
write.table(k,paste(args[1],args[2],".eval.",args[3],".MAF_correlations.txt",sep=""),
            col.names = FALSE,row.names = FALSE,quote=FALSE,sep=" ",append=TRUE)

write.table(mafres2,paste(args[1],args[2],".eval.",args[3],".MAF_correlations.txt",sep=""),
            col.names = TRUE,row.names = FALSE,quote=FALSE,append=TRUE,sep="\t")
print(head(mafres2))
snp<-maf[,c(3,4,5,7,8,11,2)]
colnames(snp)<-c("BTA","Pos","SNPn","%Concordance","%Incorrect", "Genecontent","SNPName")

write.table(snp,paste(args[1],args[2],".eval.",args[3],".SNP_correlations.txt",sep=""),
            col.names = TRUE,row.names = FALSE,sep=" ",quote=FALSE)


end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken


#truegeneContV<-truesnp_c
#impgeneContV<-impsnp_c
#Correlationss1<-as.vector(length(13))
#CorrectMAF<-as.vector(length(13))
#IncorrectMAF<-as.vector(length(13))
#NotimputedMAF<-as.vector(length(13))
#for (l in 2:13)
#{  
#CountLen=0
#CountTotal=0
#CountCorrect=0
#CountInCorrect=0
#CountNotImputed=0
#for(i in 1:172)
#{
#  print(i)
#for(j in 1:114733)
#{
#if (maf$mafgroup[j]==l){
#if (iCompSNPV[i,j]<6) {
#CountLen=CountLen+1
#CountTotal=CountTotal+1
#}
#if (iCompSNPV[i,j]==1) {     
#CountCorrect=CountCorrect+1} else if (iCompSNPV[i,j]==2) {
#CountIncorrect=CountInCorrect+1 } else if (iCompSNPV[i,j]==3) {  
#CountNotImputed=CountNotImputed+1
#}
#}
#}
#}
#print(Sys.time())
#CorrVec<-matrix(NA,CountLen,2)
#CountLen=0
#for(i in 1:172)
#{
#  print(i)
#  for(j in 1:114733)
#  {
#if (maf$mafgroup[j]==l) {
#if (iCompSNPV[i,j]<6) {
#CountLen=CountLen+1
#CorrVec[CountLen,1]=truegeneContV[i,j]
#CorrVec[CountLen,2]=impgeneContV[i,j]
#}
#}   
#}
#}
#print(CountLen)
#if (CountLen>100) {
#  Correlationss1[l]<-cor(CorrVec[,1],CorrVec[,2])
#  print(Correlationss1[l])}else {
#Correlationss1[l]=-99.0 }
#CorrectMAF[l]=(CountCorrect/CountTotal)*100
#IncorrectMAF[l]=(CountIncorrect/CountTotal)*100
#NotimputedMAF[l]=(CountNotImputed/CountTotal)*100    
#print(l)
#}
#