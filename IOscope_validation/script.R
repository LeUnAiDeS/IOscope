#This script is written to rapidly draw any file  produced by IOscop 
# as a couple of Offsets against either a sequence of I/O requests or a sequence of memory faults.
#
#
# Copyright 2018 Qwant Entreprise, Inc. 
# Author: Abdulqawi SAIF

add_legend <- function(...) {
  opar <- par(fig=c(0, 1, 0, 1), oma=c(0, 0, 0, 0), 
    mar=c(0, 0, 0, 0), new=TRUE)
  on.exit(par(opar))
  plot(0, 0, type='n', bty='n', xaxt='n', yaxt='n')
  legend(...)
}

args <- commandArgs(trailingOnly = TRUE)

library(tools)  # for the file extensions
pdf(paste("out",file_path_sans_ext(args[1]),".pdf", sept=""), width=6, height=4.5)
par(mai=c(1,1,0.5,.5))
dataTable <- read.table(args[1], header=TRUE)
ifelse("type" %in% colnames(dataTable),
dataFrame <- data.frame(offset=dataTable$offset, latency=dataTable$latency_ms, type=dataTable$type),
dataFrame <- data.frame(offset=dataTable$offset, latency=dataTable$latency_ms))

temp = nrow(dataFrame)
dataFrame$i <- seq(1,as.numeric(temp))
if ("type" %in% colnames(dataFrame))
{
#without color 
#plot(dataFrame$i, dataFrame$offset, xlab="Sequences of I/O requests",ylab="File offsets", pch = ifelse(dataFrame$type==0,3,4), cex.lab=1.8, cex.axis=1.8)
#legend('topleft', legend= c("Read IO req.", "Write IO req."), pch = c(3,4), cex=1.5)
plot(dataFrame$i, dataFrame$offset, xlab="Sequences of I/O requests",ylab="File offsets (byte)",  pch = 20, col = ifelse(dataFrame$type==0,'gray','red'), cex.lab=1.8, cex.axis=1.8)
#legend('topleft', legend= c("Read IO req.", "Write IO req."), col=c("gray", "red"),pch = c(20,20), cex=1.5)
add_legend('top', legend= c("Read IO req.", "Write IO req."), col=c("gray", "red"),pch = c(20,20), cex=1.5, horiz=TRUE, bty='n')
} else {
plot(dataFrame$i, dataFrame$offset, xlab="Sequences of memory faults",ylab="File offsets (byte)",  pch = 20, col ="black", cex.lab=1.8, cex.axis=1.8)
legend('topleft', legend= c("mmap mem. faults"), col=c("black"),pch =19, cex=1.8)
}
invisible(dev.off())

