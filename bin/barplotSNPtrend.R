getwd()
args <- commandArgs(TRUE)
if(length(args) != 2) stop("didn't recieve 2 arguments")

INFILE1=args[1]
OUTFILE1=args[2]


#Bar-Plot
#######################################################
tbl<-read.table(INFILE1,header=T)
tplot<-tbl[,c(1,2)]
#tplot
z<-dim(tplot)[1]
main<-c(paste(c("SNPtrend XXXXXXXXXX "),c("("),tplot[1,1],c(" - "),tplot[z,1],c(")")),sep="")
pdf(OUTFILE1, paper = "a4r", width=20/2.54, height=20/2.54)
#barplot(t(as.matrix(tbl)), col=rainbow(3),xlab="Individual #", ylab="Ancestry", border=NA)
barplot(c(tplot[,2]),col=rep(c("deeppink2","royalblue2","palevioletred1","skyblue2"),times=length(c(tplot[,2]))),xlab="Run #", ylab="n Samples", border=NA,ylim=c(0,max(c(tplot[,2])*1.2)),main=main)
legend("topleft",legend=c("F_HD","M_HD","F_LD","M_LD"),col=c("deeppink2","royalblue2","palevioletred1","skyblue2"),pch="-")
dev.off()
