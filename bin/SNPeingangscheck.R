getwd()
args <- commandArgs(TRUE)
if(length(args) != 5) stop("didn't recieve 5 arguments")

PARFILE        <- args[1]

#Variablen aus dem grossen Parameterfile
variable <- read.table(file=PARFILE, sep="=", fill=TRUE)
k <- nrow(variable)
for (i in 1:k) {
  if (variable[i,1] == "WRKF_DIR") { WRKF_DIR <- as.character(variable[[i,2]])}
}

INFILE1=args[2]
INFILE2=args[3]
OUTFILE1=args[4]
nsnps=as.numeric(args[5])

print(nsnps)

data     <-matrix(scan(INFILE1,quiet=TRUE,what=character(),sep=" ",n=nsnps*1),nsnps,1,byrow=T)
#Callrate
cr       <-as.data.frame(xtabs(~data[,1],data))
names(cr)<-c("v1")
crr      <-subset(cr,v1=="--")
crrr     <-crr[,2]
Callrate <-round(1-(crrr/nsnps),digits=3)
#print(Callrate)

#Heterozygotie
ht      <-subset(cr,v1=="AB")
htt     <-ht[,2]
Heterozygotie <-round(htt/nsnps,digits=3)
#print(Heterozygotie)

#print(c("GC"))
#GCscore
data     <-matrix(scan(INFILE2,quiet=TRUE,what=numeric(),sep=" ",n=nsnps*1),nsnps,1,byrow=T)
#Callrate
gcs      <-dim(subset(data,data[,1]<0.4))[1]
GCSscore <-round(gcs/nsnps,digits=3)
#print(GCSscore)
nsnps    <-dim(data)[1]

dataout<-rbind(Callrate,Heterozygotie,GCSscore,nsnps)
write.table(dataout,file=OUTFILE1,quote=FALSE,sep=" ",row.names=FALSE,col.names=FALSE)

quit()
