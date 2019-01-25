args <- commandArgs(TRUE)
if(length(args) != 5) stop("didn't recieve 5 arguments")

BREED<- args[1]
INFILE1<-args[2]
OUTFILE1<-args[3]
OUTFILE2<-args[4]
defect<-args[5]

inst_pack <- installed.packages()
pkgs <- c("MASS","stats","grDevices","ggplot2")
for (p in pkgs){
  if(!p %in% inst_pack)
    install.packages(p, repos = "https://cran.rstudio.com")
}
library(MASS)
library(stats)
library(grDevices)
library(ggplot2)

###Dateiname, der Datei, die eingelesen wird
#liest Datei mit der Tierinfo und Trägerstatus ein
rawdata <- as.data.frame(scan(file= INFILE1, sep=" ", what=list(TVDID="", Haplotypestatus=0, idimputing=0, ITBNr="", VaterTVD="", RasseTier="", BlutanteilSIOB="", Chipdichte="", Geburtstag=0),quiet = TRUE))
rawdata<-rawdata[complete.cases(rawdata[,9]),]
rawdata$Geburtsjahr<-as.numeric(substr(rawdata$Geburtstag, 1, 4))

if(BREED == "BSW"){
rasseI<-c("OB","BV")
}
if(BREED == "HOL"){
rasseI<-c("HO","SI")
}

for (rasse in rasseI) {
if(rasse == "OB"){
data <- subset(rawdata, rawdata$RasseTier != "BV")
data <- subset(data, data$RasseTier != "BS")
}
if(rasse == "BV"){
data <- subset(rawdata, rawdata$RasseTier != "OB")
}
if(rasse == "SI"){
data <- subset(rawdata, rawdata$RasseTier == "SI")
}
if(rasse == "HO"){
data <- subset(rawdata, rawdata$RasseTier != "SI")
}



#Anzahl Jahrgaenge
nGeb<-length(unique(data$Geburtsjahr))
minGJ<-min(data$Geburtsjahr)
maxGJ<-max(data$Geburtsjahr)
store <- as.data.frame(matrix(nrow=nGeb, ncol =3))
j<-1
for (i in minGJ:maxGJ){
  temp <- subset(data, data$Geburtsjahr == i)
  store[j,1]<-i
  for (s in c("M","F")){
  tempS <- subset(temp, substr(temp$ITBNr,7,7)==s)
  temp1 <- subset(tempS, tempS$Haplotypestatus==1)
  temp2 <- subset(tempS, tempS$Haplotypestatus==2)
  #Allelfrequenz wird berechnet
  frqz<-round((dim(temp1)[1]+(dim(temp2)[1]*2))/(dim(tempS)[1]*2),digits=10)

  if(s=="M"){store[j,2]<-frqz}
  if(s=="F"){store[j,3]<-frqz}
}
j<-j+1
}
store[is.na(store)] <- 0


names(store)<-c("YearOfBirth","AllelfrqMales","AllelfrqFemales")
header<-paste(rasse,defect," Allelfrq. by Year of Birth and Sex")
outEND<-paste(OUTFILE1,".",rasse,".pdf",sep="")
pdf(outEND, paper = "a4r", width=20/2.54, height=20/2.54)
print(ggplot(store,aes(x=YearOfBirth,y=AllelfrqMales,group = 1)) + geom_line(aes(y=AllelfrqMales,col="royalblue")) + geom_line(aes(y=AllelfrqFemales,col="hotpink")) + ylab("Allelefrequency") + theme(axis.text.x = element_text(angle=90)) + labs(title=header) + scale_color_manual(labels = c("Females", "Males"), values = c("hotpink","royalblue")))
dev.off()



#rechne Allelfrequenz in den letzten 4 vollen GebJahren aus
frgj<-subset(data, data$Geburtsjahr > maxGJ-6)
frgj2<-subset(frgj, frgj$Geburtsjahr < maxGJ)
temp1 <- subset(frgj2, frgj2$Haplotypestatus==1)
temp2 <- subset(frgj2, frgj2$Haplotypestatus==2)
#Allelfrequenz wird berechnet
frqz<-round((dim(temp1)[1]+(dim(temp2)[1]*2))/(dim(frgj2)[1]*2),digits=3)
outEND2<-paste(OUTFILE2,".",rasse,".lst",sep="")
write.table(frqz,file=outEND2,quote=F,col.names=F,row.names=F)

}

