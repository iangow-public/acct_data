UPDATE streetevents.calls
    SET file_path=regexp_replace(file_path, '^/Volumes/2TB/data/streetevents_project/', '');

UPDATE streetevents.call_files
    SET file_path=regexp_replace(file_path, '^/Volumes/2TB/data/streetevents_project/', '');
