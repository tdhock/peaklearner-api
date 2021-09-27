library(data.table)
keep.cols <- c(
  "annotation",
  "chrom",
  "chromEnd",
  "chromStart",
  "createdBy",
  "lastModifiedBy",
  "lastModified",
  "track")
labels.dt <- data.table(labels.csv=Sys.glob(
  "labels/H3K4me3_TDH_ENCODE/2021-09-21*/labels.csv"
))[, fread(labels.csv, select=keep.cols), by=labels.csv]
labels.dt[lastModifiedBy=="th798@nau.edu"]

last.dt <- fread("labels/H3K4me3_TDH_ENCODE/2021-09-21_14_55_10/labels.csv")
today.dt <- last.dt[lastModifiedBy=="th798@nau.edu" & chrom=="chr10"]
today.dt[, time := as.POSIXct(lastModified, origin="1970-01-01")]
track.dt <- today.dt[, .(
  labels=.N,
  bases=max(chromEnd)-min(chromStart),
  seconds=max(lastModified)-min(lastModified)
), by=track]
track.dt[, minutes := seconds / 60]
track.dt[, hours := minutes / 60]
track.dt[, bases.per.hour := bases/hours ]
track.dt[, labels.per.hour := labels/hours ]
not.input <- track.dt[minutes>1]
not.input[which.max(labels.per.hour), .(track, minutes, labels, labels.per.hour, bases, bases.per.hour)]
