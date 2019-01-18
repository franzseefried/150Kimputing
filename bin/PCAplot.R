getwd()
args <- commandArgs(TRUE)
if(length(args) != 4) stop("didn't recieve 4 arguments")

INFILE1=args[1]
INFILE2=args[2]
OUTFILE1=args[3]
OUTFILE2=args[4]


#PCA-Plot

#eigenvalues:
pcas<-read.table(INFILE1,header=F,sep=" ")
names(pcas)<-c("famid","id","EV1","EV2","EV3","EV4","EV5","EV6","EV7","EV8","EV9","EV10")
#blutanteile
blut<-read.table(INFILE2,header=T)

#mergen
tabBlut<-merge(pcas,blut,by.x="id",by.y="sample.id")
head(tabBlut)
dim(tabBlut)
tabBlut$blutFa<-as.factor(1)
tabBlut$blutFa<-ifelse(tabBlut$blut>=0 &tabBlut$blut<0.1,1,tabBlut$blutFa )
tabBlut$blutFa<-ifelse(tabBlut$blut>=0.1 &tabBlut$blut<0.2,2,tabBlut$blutFa )
tabBlut$blutFa<-ifelse(tabBlut$blut>=0.2 &tabBlut$blut<0.3,3,tabBlut$blutFa )
tabBlut$blutFa<-ifelse(tabBlut$blut>=0.3 &tabBlut$blut<0.4,4,tabBlut$blutFa )
tabBlut$blutFa<-ifelse(tabBlut$blut>=0.4 &tabBlut$blut<0.5,5,tabBlut$blutFa )
tabBlut$blutFa<-ifelse(tabBlut$blut>=0.5 &tabBlut$blut<0.6,6,tabBlut$blutFa )
tabBlut$blutFa<-ifelse(tabBlut$blut>=0.6 &tabBlut$blut<0.7,7,tabBlut$blutFa )
tabBlut$blutFa<-ifelse(tabBlut$blut>=0.7 &tabBlut$blut<0.8,8,tabBlut$blutFa )
tabBlut$blutFa<-ifelse(tabBlut$blut>=0.8 &tabBlut$blut<0.9,9,tabBlut$blutFa )
tabBlut$blutFa<-ifelse(tabBlut$blut>=0.9 &tabBlut$blut<=1,10,tabBlut$blutFa )
head(tabBlut,n=30)

#col.terrain <- terrain.colors(10)
#palette(col.terrain)
#col.rainbow <- rainbow(10)
#palette(col.rainbow)
col.topo <- topo.colors(10)
palette(col.topo)


#ausschreiben eigenvalues mit TVD
write.table(tabBlut,file=OUTFILE1,quote=F,sep=";",col.names=T,row.names=F)

# Plot
pdf(OUTFILE2, paper = "a4r", width=20/2.54, height=20/2.54) # pdf, A4 landscape
plot(tabBlut$EV1,tabBlut$EV2, col=tabBlut$blutFa, pch=1,xlab="PC_1 ", ylab="PC_2", cex=0.7)
dev.off()


closeAllConnections()
