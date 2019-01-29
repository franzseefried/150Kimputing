###
###
###   Purpose:   Select SNPs from Fimpute Ergebnis
###   Inputfile wird zeilenweise gelesen
###   started:   2017/05/26 (fsf)
###
### ############################################# ###


args <- commandArgs(TRUE)
if(length(args) != 2) stop("didn't recieve 2 arguments")


INFILE1<-args[1]
INFILE2<-args[2]



### # selection done with a function
readGTs <- function(psInputFn, pbHasHeader = FALSE) {
  ###
  ###   recodeSnpInfo(psInputFn): recoding of SNP Info in psInputFn
  ###     results will be written to an output file which has the 
  ###     same name as the input file with ".out" pasted to it. 
  ###     If old output files with the same name exist, new output
  ###     will be appended, hence delete any old output first
  ### ############################################################# ###
  ### # check whether input file exists
  stopifnot(file.exists(psInputFn))
  ### # define output filename based on psInputFn
  sOutputFn <- paste(psInputFn, ".out", sep = "")
  ### # open a connection to input file
  conSnpInfo  <- file(psInputFn, "r")
  ### # read header, if we have one
  if (pbHasHeader) {
    sCurSnpLine  <- readLines(conSnpInfo, n = 1)
    cat("Header: ", sCurSnpLine, "\n")
  }
  
  #einlesen des files mit den columns die selektiert werden sollen
  selection <- scan(file=INFILE1)
  ###print(selection[1:20])
  ### # loop ueber input lines
  while (length(sCurSnpLine  <- readLines(conSnpInfo, n = 1) ) > 0) {
    # covert Inputlines to vector
    vecCurSnp <- unlist(sCurSnpLine)
    datain  <- unlist(strsplit(vecCurSnp, ""))
    #selection done here
    datasel <- datain[selection]
    #ausschreiben via anhaengen
	cat( datasel, "\n", file = sOutputFn, append = TRUE)
  }
  
  close(conSnpInfo)
}

snpInput.fn <- INFILE2
readGTs(snpInput.fn, FALSE)
#unix.time(recodeSnpInfo(snpInput.fn, FALSE))


