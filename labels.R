hub <- "H3K4me3_TDH_ENCODE"
todays.date <- as.Date(Sys.time())
hub.dir <- file.path("labels", hub, todays.date)
u <- sprintf(
  "https://peaklearner.rc.nau.edu/Public/%s/labels",
  hub)
dir.create(hub.dir, showWarnings = FALSE, recursive = TRUE)
labels.csv <- file.path(hub.dir, "labels.csv")
download.file(u, labels.csv, headers=c("accept"="text/csv"))
labels.dt <- data.table::fread(labels.csv)
labels.dt[, .(
  labels=.N
), by=.(createdBy, lastModifiedBy)]
system("git add labels/*/*/labels.csv")
