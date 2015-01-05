se.dir <- "/Volumes/2TB/data/streetevents2013"
orig.dirs <- grep("StreetEvents", dir(se.dir, full.names = TRUE), value=TRUE)

for (d in orig.dirs) {
    files <- list.files(d, pattern="*.xml", full.names=TRUE)

    for (i in files) {
      
      # Find last digit before underscore
      m <- regexpr("[0-9](?=_T)", i, perl=TRUE)
      last_digit <- regmatches(i, m)
      new_path <- file.path(se.dir, paste("dir", last_digit, sep="_"), basename(i))
      # print(paste(new_path))
      file.rename(from=i, to=new_path)
    }
}
