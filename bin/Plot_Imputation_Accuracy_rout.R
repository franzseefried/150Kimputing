options(echo=TRUE)

# load requiered packages
#=======================
suppressPackageStartupMessages(if(! require("stringr")) {
  install.packages("stringr", repos="https://stat.ethz.ch/CRAN/")
  require("stringr")
})
suppressPackageStartupMessages(if(! require("reshape")) {
  install.packages("reshape", repos="https://stat.ethz.ch/CRAN/")
  require("reshape")
})
suppressPackageStartupMessages(if(! require("ggplot2")) {
  install.packages("ggplot2", repos="https://stat.ethz.ch/CRAN/")
  require("ggplot2")
})

suppressPackageStartupMessages(if(! require("qqman")) {
  install.packages("qqman", repos="https://stat.ethz.ch/CRAN/")
  require("qqman")
})

args <- commandArgs(trailingOnly=TRUE)
print(args)

anim<-list()
#Suche Anim files

  if(file.exists(paste(args[4],sep=""))) {
    anim[[1]]<-read.table(paste(args[4]))
  }else {
    print("No animal file provided!!!")
  }

ags<-args[1:3]
print(ags)
scens<-unlist(lapply(str_split(ags,"/"), tail, n = 1L))
print(scens)
ge_files<-list()
hi_files<-list()
lo_files<-list()

for(i in 1)
{
ge_files[[i]]<-read.table(paste(ags[i],"Ind_correlations.txt",sep=""))  
ge_files[[i]]$Scen<-tail(unlist(str_split(ags[i],"/")),n=1)  
ge_files[[i]]$MAF<-"GE"
}


df_ge<-do.call(rbind,ge_files)
dim(df_ge)
mi<-1
for(i in 2)
{
  if(file.exists(paste(ags[i],"Ind_correlations.txt",sep=""))) {
  hi_files[[mi]]<-read.table(paste(ags[i],"Ind_correlations.txt",sep=""))  
  hi_files[[mi]]$Scen<-tail(unlist(str_split(ags[i],"/")),n=1)  
  hi_files[[mi]]$MAF<-"HI"
  mi<-mi+1
  } else {print(paste("No Higher file for scenario",i,"provided",sep=" "))}
}
if(length(hi_files)!=0){
df_hi<-do.call(rbind,hi_files)
df_ge<-rbind(df_ge,df_hi)
}
dim(df_ge)
mi<-1
for(i in 3)
{
  if(file.exists(paste(ags[i],"Ind_correlations.txt",sep=""))) {
    lo_files[[mi]]<-read.table(paste(ags[i],"Ind_correlations.txt",sep=""))  
    lo_files[[mi]]$Scen<-tail(unlist(str_split(ags[i],"/")),n=1)  
    lo_files[[mi]]$MAF<-"LO"
    mi<-mi+1
  } else {print(paste("No Lower file for scenario",i,"provided",sep=" "))}
}
if(length(lo_files)!=0){
  df_lo<-do.call(rbind,lo_files)
  print(dim(df_lo))
  df_ge<-rbind(df_ge,df_lo)
}
dim(df_ge)
compl<-df_ge
head(compl)
dim(compl)
colnames(compl)<-c("Inds","Conc","Error","Corr","Scen","MAF")
compl$Conc<-compl$Conc/100
melted_compl<-melt(compl,id.vars=c("Inds","MAF"),measure.vars = c("Corr","Conc"))
melted_compl$Scen<-paste(melted_compl$MAF,melted_compl$variable)
dim(melted_compl)
melted_compl<-melted_compl[!((melted_compl$MAF=="LO"&melted_compl$variable=="Conc")|(melted_compl$MAF=="HI"&melted_compl$variable=="Conc")),]
melted_compl$breed<-0
length(anim)
n<-1
for( a in 1:length(anim))
{
  if(!is.null(anim[[a]])&&anim[[a]]=="empty"){n<-n+1}
  if(length(anim)>0&&!is.null(anim[[a]])&&anim[[a]]!="empty"){
    print(a)
  anim[[a]]$breed<-ifelse(anim[[a]]$V3>0.87,"HI","LO")
  melted_compl$breed[which(melted_compl$Inds%in%anim[[a]]$V1)]<-anim[[a]]$breed
  n<-n+1}
}

table(melted_compl$breed)

pdf(paste(args[6],"/ImputationAccuracyplots.pdf", sep = ""))
head(melted_compl)
dim(melted_compl)

ggplot(data=melted_compl[!((melted_compl$breed=="HI"&melted_compl$MAF=="LO")|(melted_compl$breed=="LO"&melted_compl$MAF=="HI")),],aes(x=Scen,y=value,fill=variable,color=MAF))+geom_boxplot()+theme_bw()+
  xlab("Szenario")+ylab("Imputation Accuracy")+ggtitle("All Scenarios; breed specific")+scale_fill_manual(values=c("yellow","green")) +
   stat_summary(fun.y=mean, colour="black", geom="text", show.legend = FALSE, 
                  aes( label=round(..y.., digits=5)))

ggplot(data=melted_compl,aes(x=Scen,y=value,fill=variable,color=MAF))+geom_boxplot()+theme_bw()+
  xlab("Szenario")+ylab("Imputation Accuracy")+ggtitle("All Scenarios")+scale_fill_manual(values=c("yellow","green")) +
stat_summary(fun.y=mean, colour="black", geom="text", show.legend = FALSE, 
             aes( label=round(..y.., digits=5)))


ggplot(data=melted_compl[melted_compl$MAF=="GE",],aes(x=Scen,y=value,fill=variable))+geom_boxplot()+theme_bw()+
  xlab("Szenario")+ylab("Imputation Accuracy")+ggtitle("MAF GE")+scale_fill_manual(values=c("yellow","green")) +
  stat_summary(fun.y=mean, colour="black", geom="text", show.legend = FALSE, 
               aes( label=round(..y.., digits=5)))


ggplot(data=melted_compl[melted_compl$MAF=="GE"&melted_compl$variable=="Corr",],aes(x=Scen,y=value,fill=variable,color=MAF))+geom_boxplot()+theme_bw()+
  xlab("Szenario")+ylab("Imputation Accuracy")+scale_fill_manual(values=c("yellow","green"))+
  stat_summary(fun.y=mean, colour="black", geom="text", show.legend = FALSE, 
               aes( label=round(..y.., digits=5)))


ggplot(data=melted_compl[!((melted_compl$breed=="HI"&melted_compl$MAF=="LO")|(melted_compl$breed=="LO"&melted_compl$MAF=="HI"))&melted_compl$variable=="Corr",],aes(x=Scen,y=value,fill=variable,color=MAF))+geom_boxplot()+theme_bw()+
  xlab("Szenario")+ylab("Imputation Accuracy")+ggtitle("Corr;breed spec")+scale_fill_manual(values=c("yellow","green"))+
  stat_summary(fun.y=mean, colour="black", geom="text", show.legend = FALSE, 
               aes( label=round(..y.., digits=5)))



maf_ge<-list()
for(i in 1)
{
  maf_ge_n<-read.table(paste(ags[i],"MAF_correlations.txt",sep=""),sep=":",skip=1,nrows=13) 
  maf_ge[[i]]<-read.table(paste(ags[i],"MAF_correlations.txt",sep=""),skip=15,nrows=13,as.is=TRUE)
  maf_ge[[i]]$Scen<-tail(unlist(str_split(ags[i],"/")),n=1)  
  maf_ge[[i]]$MAF<-"GE"
  maf_ge[[i]]$NSNP<-maf_ge_n$V2
  maf_ge[[i]]$class<-c(0,0.025,0.05,0.075,0.1,0.15,0.2,0.25,0.3,0.35,0.4,0.45,0.5)
}
maffile<-do.call(rbind,maf_ge)

maf_hi<-list()
mi<-1
for(i in 2)
{
  if(file.exists(paste(ags[i],"MAF_correlations.txt",sep=""))){
  maf_ge_n<-read.table(paste(ags[i],"MAF_correlations.txt",sep=""),sep=":",skip=1,nrows=13) 
  maf_hi[[mi]]<-read.table(paste(ags[i],"MAF_correlations.txt",sep=""),skip=15,nrows=13,as.is=TRUE)
  maf_hi[[mi]]$Scen<-tail(unlist(str_split(ags[i],"/")),n=1)  
  maf_hi[[mi]]$MAF<-"HI"
  maf_hi[[mi]]$NSNP<-maf_ge_n$V2
  maf_hi[[mi]]$class<-c(0,0.025,0.05,0.075,0.1,0.15,0.2,0.25,0.3,0.35,0.4,0.45,0.5)
  mi<-mi+1
  } else{print(paste("No Higher file for scenario",i,"provided",sep=" "))}
}

if(length(maf_hi)!=0){
  mafhi<-do.call(rbind,maf_hi)
  maffile<-rbind(maffile,mafhi)
}

maf_lo<-list()
mi<-1
for(i in 3)
{
  if(file.exists(paste(ags[i],"MAF_correlations.txt",sep=""))){
    maf_ge_n<-read.table(paste(ags[i],"MAF_correlations.txt",sep=""),sep=":",skip=1,nrows=13) 
    maf_lo[[mi]]<-read.table(paste(ags[i],"MAF_correlations.txt",sep=""),skip=15,nrows=13,as.is=TRUE)
    maf_lo[[mi]]$Scen<-tail(unlist(str_split(ags[i],"/")),n=1)  
    maf_lo[[mi]]$MAF<-"LO"
    maf_lo[[mi]]$NSNP<-maf_ge_n$V2
    maf_lo[[mi]]$class<-c(0,0.025,0.05,0.075,0.1,0.15,0.2,0.25,0.3,0.35,0.4,0.45,0.5)
    mi<-mi+1
  } else{print(paste("No Lower file for scenario",i,"provided",sep=" "))}
}

if(length(maf_lo)!=0){
  maflo<-do.call(rbind,maf_lo)
  maffile<-rbind(maffile,maflo)
}

colnames(maffile)[7:9]<-c("Conc","Error","Corr")
maffile$Corr[maffile$Corr==-99]<-NA
maffile$Conc<-maffile$Conc/100
mafmel<-melt(maffile,id.vars=c("class","Scen","MAF"),measure.vars = c("Corr"))

ggplot(data=mafmel,aes(x=class,y=value,color=interaction(MAF,Scen),group=interaction(MAF,Scen)))+
geom_line()+theme_bw()+
xlab("Szenario")+ylab("Imputation Accuracy")+ggtitle("All Scenarios")

ggplot(data=mafmel[mafmel$MAF=="GE",],aes(x=class,y=value,color=interaction(MAF,Scen),group=interaction(MAF,Scen)))+
geom_line()+theme_bw()+
xlab("Szenario")+ylab("Imputation Accuracy")+ggtitle("All Scenarios")




#Plot regional accuracy
  if(file.exists(paste(ags[1],"SNP_correlations.txt",sep=""))){
    snp_ge<-read.table(paste(ags[1],"SNP_correlations.txt",sep=""))
    manhattan(snp_ge,chr="V1",bp="V2",p="V5",logp=FALSE,
              main=paste("SNP accuracy",args[5],args[7],sep=" "),ylab="Imputation error %",
              genomewideline = 200 ,suggestiveline = 200)
    
  } else{print(paste("No General file for scenario",i,"provided",sep=" "))}
dev.off()