args <- commandArgs(TRUE)


inst_pack <- installed.packages()
pkgs <- c("MASS","stats","grDevices","e1071")
for (p in pkgs){
  if(!p %in% inst_pack)
    install.packages(p, repos = "https://cran.rstudio.com")
}
library(MASS)
library(stats)
library(grDevices)
library(e1071)
set.seed(2000)


#Variablen aus der Komandozeile
breed        <- args[1]
haplotyp     <- args[2]
lkernel      <- args[3]
INFILE       <- args[4]
OUTFILE      <- args[5]




#Einlesen des LogRRFiles
data         <- read.table(file= INFILE, sep=" ",header=T,na.strings="-")
#summary(data)
print("Dimension of inputdata")
dim(data)
print(" ")

#aufteilen in referenz & training
trainset     <- subset(data,TrainValidStatus=="T")
print("Dimension of Referenceanimals")
dim(trainset)
print(" ")


print("#SVM Model leave one out cross validation, n times number of reference animals")

t<-trainset
nt<-dim(trainset)[1]
for (i in seq(1,nt)){
   #x <- floor(runif(1,1,nt))
   tr_small<-trainset[-c(i),]
   vl_set<-trainset[i,]
   for (k_type in c("radial","linear","polynomial","sigmoid")){
       svm.model <- svm(as.factor(tr_small$RYFcode)~., data = tr_small[,c(4:dim(tr_small)[2])],kernel=k_type)
       svm.pred  <- predict(svm.model, vl_set[,c(4:dim(vl_set)[2])],decision.values=TRUE)
       tbl<-as.data.frame(table(svm.pred,vl_set$RYFcode))
       write.table(tbl,file=paste(OUTFILE,"/","LeaveOneOut_",breed,haplotyp,k_type,".txt",sep=""),append=T,col.names=T,row.names=F,quote=F)
   }
}




