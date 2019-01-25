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
print(names(data))
#summary(data)
print("Dimension of inputdata")
dim(data)
print(" ")

#aufteilen in referenz & training
trainset     <- subset(data,TrainValidStatus=="T")
print("Dimension of Referenceanimals")
dim(trainset)
print(" ")
predictionset<- subset(data,TrainValidStatus=="V")
print("Dimension of Predictionanimals")
dim(predictionset)
print(" ")


#SVM Model
svm.model    <- svm(as.factor(trainset$RYFcode)~., data = trainset[,c(4:dim(trainset)[2])],kernel=lkernel)
#SVM Prediction
svm.pred     <- predict(svm.model, predictionset[,c(4:dim(predictionset)[2])],decision.values=TRUE)
#tbl         <-as.data.frame(table(predictionset$RYFcode,svm.pred))
tbl          <-as.data.frame(table(predictionset$animal,svm.pred))
#selektion des Predictionergebnisses aus der Tabelle
tbm          <-subset(tbl,Freq==1)
names(tbm)   <-c("animal","Genotypeprediction","Frq")

#print output
write.table(tbm,file=OUTFILE,append=F,col.names=T,row.names=F,quote=F)


closeAllConnections()

