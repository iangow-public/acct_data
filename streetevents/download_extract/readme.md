### StreetEvents data

- The file `import_call_meta_data.R` calls `parse_xml_files.pl` to extract call-level data (e.g., ticker, call time, call type) and puts it in `streetevents.calls_test`.
- The file `create_calls_files.R` extracts details about the files associated with each call (e.g., `mtime`) and puts it in `streetevents.call_files`.
- The file `import_speaker_data.R` runs `import_speaker_data.pl` to parse the speaker data from the XML call files.
