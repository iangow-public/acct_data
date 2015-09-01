SET work_mem='10GB';

DROP VIEW streetevents.qa_pairs;


CREATE MATERIALIZED VIEW streetevents.qa_pairs AS
WITH 

answers AS (
    SELECT a.file_name, 
        array_agg(speaker_name ORDER BY speaker_number::integer) AS answerers,
        array_agg(speaker_number ORDER BY speaker_number::integer) AS answer_nums,
        array_agg(speaker_text ORDER BY speaker_number::integer) AS answers,
        array_agg(role ORDER BY speaker_number::integer) AS answerer_roles
    FROM streetevents.speaker_data AS a
    INNER JOIN streetevents.qa_pair_data AS b
    USING (file_name) 
    WHERE context='qa' AND a.speaker_number=any(b.answer_nums)
    GROUP BY a.file_name),

questions AS (
    SELECT a.file_name, 
        speaker_name AS questioner,
        array_agg(speaker_number ORDER BY speaker_number::integer) AS question_nums,
        array_agg(speaker_text ORDER BY speaker_number::integer) AS questions
    FROM streetevents.speaker_data AS a
    INNER JOIN streetevents.qa_pair_data  AS b
    USING (file_name) 
    WHERE context='qa' AND a.speaker_number=any(b.question_nums)
    GROUP BY a.file_name, a.speaker_name)

SELECT file_name,  questioner,
    questions, question_nums,
    answerers, answer_nums, answers, answerer_roles
FROM streetevents.qa_pair_data 
INNER JOIN answers
USING (file_name, answer_nums)
INNER JOIN questions
USING (file_name, question_nums)