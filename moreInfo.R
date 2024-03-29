library(data.table)
## Second method, parse moreInfo web page which has a table for each
## labeled chrom/track.
hub <- "H3K4me3_TDH_ENCODE" #525 labels defined in upload hub files, see https://github.com/tdhock/feature-learning-benchmark#30-jan-2018-data-set-sizes
todays.date <- as.Date(Sys.time())
hub.dir <- file.path("moreInfo", hub, todays.date)
unlink(file.path(hub.dir, "*"))
dir.create(hub.dir, showWarnings = FALSE, recursive = TRUE)
labels.html <- file.path(hub.dir, "labels.html")
if(!file.exists(labels.html)){
  more.info.url <- sprintf(
    "https://peaklearner.rc.nau.edu/Public/%s/info", hub)
  download.file(more.info.url, labels.html, headers=c(Accept="text/html"))
}
labels.csv <- file.path(hub.dir, "labels.csv")
if(file.exists(labels.csv)){
  label.dt <- data.table::fread(labels.csv, na.strings="")
}else{
  todays.rvest <- rvest::read_html(labels.html)
  label.dt.list <- list(fill=TRUE)
  track.list <- rvest::html_elements(
    todays.rvest, xpath="//html/body/div/div/div/h5")
  ## TODO.
  for(table.i in seq_along(track.list)){
    li.element <- li.element.list[[table.i]]
    li.text <- rvest::html_text(li.element)
    li.track <- nc::capture_first_vec(li.text, "'", track="[^']+")
    li.labels <- rvest::html_table(li.element)[,-1]
    label.dt.list[[paste(table.i)]] <- data.table(li.track, li.labels)
  }
  label.dt <- do.call(rbind, label.dt.list)
  data.table::fwrite(label.dt, labels.csv)
}
system(paste0("git add ", hub.dir, "/*"))

historical.labels <- data.table(
  labels.csv=Sys.glob("moreInfo/*/*/labels.csv")
)[, fread(labels.csv), by=labels.csv]
historical.labels[, .(count=.N), by=labels.csv]
# I guess <NA> means labels were in the DB before USER ID storage was
# implemented?
