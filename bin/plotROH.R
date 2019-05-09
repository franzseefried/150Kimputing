freq_plot<-function (x, chr = "CHR", bp = "BP", p = "P",p2="P2", snp = "SNP", col = c("gray10",
                                                                                      "gray60"),col2=c("darkolivegreen3","green4"), chrlabs = NULL, suggestiveline = -log10(1e-05),
                     genomewideline = -log10(5e-08), highlight = NULL, logp = TRUE, 
                     annotatePval = NULL, annotateTop = TRUE, ...) 
{
  CHR = BP = P = P2 = index = NULL
  if (!(chr %in% names(x))) 
    stop(paste("Column", chr, "not found!"))
  if (!(bp %in% names(x))) 
    stop(paste("Column", bp, "not found!"))
  if (!(p %in% names(x))) 
    stop(paste("Column", p, "not found!"))
  if (!(p2 %in% names(x))) 
    stop(paste("Column", p2, "not found!"))
  if (!(snp %in% names(x))) 
    warning(paste("No SNP column found. OK unless you're trying to highlight."))
  if (!is.numeric(x[[chr]])) 
    stop(paste(chr, "column should be numeric. Do you have 'X', 'Y', 'MT', etc? If so change to numbers and try again."))
  if (!is.numeric(x[[bp]])) 
    stop(paste(bp, "column should be numeric."))
  if (!is.numeric(x[[p]])) 
    stop(paste(p, "column should be numeric."))
  d = data.frame(CHR = x[[chr]], BP = x[[bp]], P = x[[p]])
  d2 = data.frame(CHR = x[[chr]], BP = x[[bp]], P2 = x[[p2]])
  if (!is.null(x[[snp]])) 
    d = transform(d, SNP = x[[snp]])
  d <- subset(d, (is.numeric(CHR) & is.numeric(BP) & is.numeric(P)))
  d <- d[order(d$CHR, d$BP), ]
  d2 = transform(d2, SNP = x[[snp]])
  d2 <- subset(d2, (is.numeric(CHR) & is.numeric(BP) & is.numeric(P2)))
  d2 <- d2[order(d2$CHR, d2$BP), ]
  if (logp) {
    d$logp <- -log10(d$P)
    d2$logp <- -log10(d2$P2)
  }
  else {
    d$logp <- d$P
    d2$logp <- d2$P2
  }
  d$pos = NA
  d$index = NA
  d2$pos = NA
  d2$index = NA
  
  ind = 0
  for (i in unique(d$CHR)) {
    ind = ind + 1
    d[d$CHR == i, ]$index = ind
    d2[d2$CHR == i, ]$index = ind
  }
  
  nchr = length(unique(d$CHR))
  if (nchr == 1) {
    d$pos = d$BP
    d2$pos = d2$BP
    ticks = floor(length(d$pos))/2 + 1
    xlabel = paste("Chromosome", unique(d$CHR), "position")
    labs = ticks
  }
  else {
    lastbase = 0
    ticks = NULL
    for (i in unique(d$index)) {
      if (i == 1) {
        d[d$index == i, ]$pos = d[d$index == i, ]$BP
        d2[d2$index == i, ]$pos = d2[d2$index == i, ]$BP
      }
      else {
        lastbase = lastbase + tail(subset(d, index == 
                                            i - 1)$BP, 1)
        d[d$index == i, ]$pos = d[d$index == i, ]$BP + 
          lastbase
        d2[d2$index == i, ]$pos = d[d$index == i, ]$BP + 
          lastbase
        
      }
      ticks = c(ticks, (min(d[d$index == i, ]$pos) + max(d[d$index == 
                                                             i, ]$pos))/2 + 1)
    }
    xlabel = "Chromosome"
    labs <- unique(d$CHR)
  }
  xmax = ceiling(max(d$pos) * 1.03)
  xmin = floor(max(d$pos) * -0.03)
  def_args <- list(xaxt = "n", bty = "n", xaxs = "i", yaxs = "i", 
                   las = 1, pch = 20, xlim = c(xmin, xmax), ylim = c(0, 
                                                                     ceiling(max(d$logp))), xlab = xlabel, ylab = "% in ROH")
  dotargs <- list(...)
  do.call("plot", c(NA, dotargs, def_args[!names(def_args) %in% 
                                            names(dotargs)]))
  if (!is.null(chrlabs)) {
    if (is.character(chrlabs)) {
      if (length(chrlabs) == length(labs)) {
        labs <- chrlabs
      }
      else {
        warning("You're trying to specify chromosome labels but the number of labels != number of chromosomes.")
      }
    }
    else {
      warning("If you're trying to specify chromosome labels, chrlabs must be a character vector")
    }
  }
  if (nchr == 1) {
    axis(1, ...)
  }
  else {
    axis(1, at = ticks, labels = labs, ...)
  }
  col = rep(col, max(d$CHR))
  col2 = rep(col2, max(d2$CHR))
  if (nchr == 1) {
    with(d, points(pos, logp, pch = 20, col = col[1], ...))
    with(d2, points(pos, logp, pch = 20, col2 = col[1], ...))
  }
  else {
    icol = 1
    for (i in unique(d$index)) {
      with(d[d$index == unique(d$index)[i], ], points(pos, 
                                                      logp, col = col[icol], pch = 20, ...))
      icol = icol + 1
    }
    icol = 1
    for (i in unique(d2$index)) {
      with(d2[d2$index == unique(d2$index)[i], ], points(pos, 
                                                         logp, col = col2[icol], pch = 20, ...))
      icol = icol + 1
    }
    
  }
  if (suggestiveline) 
    abline(h = suggestiveline, col = "blue")
  if (genomewideline) 
    abline(h = genomewideline, col = "red")
  if (!is.null(highlight)) {
    if (any(!(highlight %in% d$SNP))) 
      warning("You're trying to highlight SNPs that don't exist in your results.")
    d.highlight = d[which(d$SNP %in% highlight), ]
    with(d.highlight, points(pos, logp, col = "green3", pch = 20, 
                             ...))
  }
  if (!is.null(annotatePval)) {
    topHits = subset(d, P <= annotatePval)
    par(xpd = TRUE)
    if (annotateTop == FALSE) {
      with(subset(d, P <= annotatePval), textxy(pos, -log10(P), 
                                                offset = 0.625, labs = topHits$SNP, cex = 0.45), 
           ...)
    }
    else {
      topHits <- topHits[order(topHits$P), ]
      topSNPs <- NULL
      for (i in unique(topHits$CHR)) {
        chrSNPs <- topHits[topHits$CHR == i, ]
        topSNPs <- rbind(topSNPs, chrSNPs[1, ])
      }
      textxy(topSNPs$pos, -log10(topSNPs$P), offset = 0.625, 
             labs = topSNPs$SNP, cex = 0.5, ...)
    }
  }
  par(xpd = FALSE)
}

options(echo=TRUE) # if you want see commands in output file
args <- commandArgs(trailingOnly = TRUE)
#args: 1: Phenotypes
# WORK_Dir

setwd(args[2])



homozyg<-read.table(paste(args[2],"/",args[3],".Homozyg_",args[1],".hom",sep=""),header=TRUE)
map<-read.table(paste(args[2],"/",args[3],".",args[1],".map",sep=""))

colnames(map)<-c("CHR","SNP","gPOS","BP")
ind<-unique(homozyg[,2])

case<-read.table(paste(args[2],"/",args[3],".cases_",args[1],".phen",sep=""))
cont<-read.table(paste(args[2],"/",args[3],".controls_",args[1],".phen",sep=""))
print("Note you are using all controls, if you want to use samples controls, adapt code")
#samp1<-sample(cont[,2],length(case[,2]))
#samp2<-sample(cont[,2],length(case[,2]))
#samp3<-sample(cont[,2],length(case[,2]))
map_h<- cbind(map,matrix(0,as.numeric(args[4]),2))
colnames(map_h)<-c(colnames(map),"Freq_Case","Freq_Cont")
system.time(
  for( i in 1:nrow(map_h))
  {
    h<-map_h$BP[[i]]
    ch<-map_h$CHR[[i]]
    ct<-homozyg[homozyg$CHR==ch&homozyg$POS1<=h&homozyg$POS2>=h,2]
    map_h$Freq_Case[[i]]<-length(which(ct%in%case[,2]))/length(case[,2])
    map_h$Freq_Cont[[i]]<-length(which(ct%in%cont[,2]))/length(cont[,2])
  }
)
write.table(map_h,paste(args[2],"/ROHfreq_",args[1],".txt",sep=""),row.names=FALSE,col.names=TRUE,quote=FALSE)

out <- paste(args[2],"/ROHplot_",args[1],".pdf",sep="")
pdf(file=out,paper = "a4r", width=20/2.54, height=20/2.54)
freq_plot(map_h,p="Freq_Case",p2="Freq_Cont",logp=FALSE,ylim=c(0,1.1),cex=0.5)
pos<-legend("topright",c("Controls","Cases"),bty="o") #,fill=c("dodgerblue","gray60")
# Plot symbols in two columns, shifted to the left by 3 and 1 respectively
points(x=c(rep(pos$text$x, times=2) - c(1e+08,0.5e+08)), 
       y=c(pos$text$y,pos$text$y[2],pos$text$y[1]), 
       col=c("darkolivegreen3","gray60","gray10","green4"),
       pch=16,
       cex=0.5)
       
dev.off()

#Um ROHs in einzelnen Tieren anzuschauen
#map_h<- cbind(map,matrix(0,40636,925))
#colnames(map_h)<-c(colnames(map),ind,"Freq_Case","Freq_Cont")
#system.time(
#  for( i in 1:nrow(map_h))
#  {
#    h<-map_h$BP[[i]]
#    ch<-map_h$CHR[[i]]
#    ct<-homozyg[homozyg$CHR==ch&homozyg$POS1<=h&homozyg$POS2>=h,2]
#    map_h[i,which(colnames(map_h)%in%ct)]<-1
#    map_h$Freq_Case[[i]]<-length(which(ct%in%case[,2]))/83
#    map_h$Freq_Cont[[i]]<-length(which(ct%in%cont[,2]))/844
#  }
#)

