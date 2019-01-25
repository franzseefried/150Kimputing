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


args <- commandArgs(TRUE)
#Variablen aus der Komandozeile
breed        <- args[1]
haplotyp     <- args[2]
INFILE      <- args[3]
OUTFILE     <-args[4]

data<-read.table(file=INFILE,header=F,sep=" ")
names(data)<-c("cow","MGS","Year","sire")


print("Dimension of inputdata")
dim(data)
print(" ")

#make summarytable
summrytable<-as.data.frame(xtabs(~Year,data))

header<-paste(haplotyp," No. of Riskmatings by Year")


pdf(OUTFILE, paper = "a4r", width=20/2.54, height=20/2.54)
ggplot(summrytable,aes(x=Year,y=Freq,group = 1)) + geom_line() + geom_point(size=2.5,shape=21,fill="white") + ylab("Number of\nRiskmatings") + theme(axis.text.x = element_text(angle=90)) + labs(title=header)
dev.off()
