for (j in 1L:9L) {
  path <- paste("/Volumes/2TB/data/streetevents2013/dir_", j, sep="")
  files <- list.files(path, full.names=TRUE)
  for (i in files) {
    new_path <- gsub("/dir_\\d", "", i, perl=TRUE)
    file.rename(from=i, to=new_path)
  }
}

path <- "/Volumes/2TB/data/streetevents2013/*.xml"
files <- list.files(path, full.names=TRUE)

dir.create("/Volumes/2TB/data/streetevents2013/dir_0")

for (i in files) {
  # Find last digit before underscore
  m <- regexpr("[0-9](?=_)", i, perl=TRUE)
  last_digit <- regmatches(i, m)
  new_path <- file.path(dirname(i), paste("dir", last_digit, sep="_"), basename(i))
  file.rename(from=i, to=new_path)
}