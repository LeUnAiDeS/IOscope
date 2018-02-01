#This script is written to rapidly draw any file  produced produced by IOscop 
# as a couple of Offsets and the either sequence of I/O requests or sequences of memory faults.
#
#
# Copyright 2018 Qwant Entreprise, Inc. 
# Author: Abdulqawi SAIF


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
plot(dataFrame$i, dataFrame$offset, xlab="Sequences of I/O requests",ylab="File offsets",  pch = 20, col = ifelse(dataFrame$type==0,'red','blue'), cex.lab=1.8, cex.axis=1.8)
legend('topleft', legend= c("Read IO req.", "Write IO req."), col=c("red", "blue"),pch = c(19,19), cex=1.8)
} else {
plot(dataFrame$i, dataFrame$offset, xlab="Sequences of memory faults",ylab="File offsets",  pch = 20, col ="black", cex.lab=1.8, cex.axis=1.8)
legend('topleft', legend= c("mmap mem. faults"), col=c("black"),pch =19, cex=1.8)
}
invisible(dev.off())

