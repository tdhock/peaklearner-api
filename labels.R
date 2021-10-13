hub <- "Public/H3K4me3_TDH_ENCODE"

hub <- "tristanmillerschool@gmail.com/H3K36me3_TDH_other"
todays.date <- paste(Sys.time())
hub.dir <- gsub("[ :]", "_", file.path("labels", hub, todays.date))
u <- sprintf(
  "https://peaklearner.rc.nau.edu/%s/labels",
  hub)
dir.create(hub.dir, showWarnings = FALSE, recursive = TRUE)
labels.csv <- file.path(hub.dir, "labels.csv")
download.file(u, labels.csv, headers=c("accept"="text/csv"))

labels.dt <- data.table::fread(labels.csv)
labels.dt[, .(
  labels=.N
), by=.(chrom, lastModifiedBy)]
system("git add labels/*/*/labels.csv")

## my labeling speed is about 100 labels per minute on this hub. 15
## tracks labeled during that session, so that is 6.67 regions per
## minute.
