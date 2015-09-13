CREATE TABLE streetevents_old.invalid_file_names AS

WITH 

new_data AS (
    SELECT file_name, last_update, speaker_name, employer
    FROM streetevents.speaker_data
    WHERE speaker_number=2 AND context='pres'),
    
old_data AS (
    SELECT file_name, last_update, speaker_name, employer
    FROM streetevents_old.speaker_data
    WHERE speaker_number=2 AND context='pres')
    
SELECT file_name
FROM old_data AS a
INNER JOIN new_data AS b
USING (file_name, last_update)
WHERE a.employer != b.employer