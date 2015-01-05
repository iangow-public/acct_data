INSERT INTO streetevents.qa_pairs 

WITH sample_transcripts AS (
    SELECT a.file_name, a.speaker_name, a.speaker_number,
      trim(a.speaker_text) AS speaker_text, a.role,
      role != 'Analyst' AS is_answer,
      role = 'Analyst' AND speaker_text ~ '\?' AS is_question
    FROM streetevents.speaker_data AS a
    INNER JOIN streetevents.calls
    USING (file_name)
    WHERE  call_type=1 AND context='qa' AND speaker_name != 'Operator'
        AND file_name='%s'
    ORDER BY file_name, speaker_number),

grouped AS (
   SELECT *, 
      sum(is_question::integer) OVER all_obs AS question_group
      FROM sample_transcripts
      WINDOW all_obs AS (PARTITION BY file_name ORDER BY speaker_number)),

questions_raw AS (
    SELECT file_name, question_group,
      speaker_name,
      array_agg(speaker_number ORDER BY speaker_number) AS speaker_numbers,
      array_agg(speaker_text ORDER BY speaker_number) AS speaker_texts,
      bool_or(is_question) AS is_question
    FROM grouped
    WHERE role='Analyst'
    GROUP BY file_name, question_group, speaker_name),

questions_inter AS (
    SELECT *, lead(speaker_numbers) OVER w AS lead_speaker_numbers
    FROM questions_raw 
    WINDOW w AS (PARTITION BY file_name ORDER BY speaker_numbers)),

questions AS (
    SELECT file_name, speaker_name AS questioner, speaker_texts AS questions, 
        speaker_numbers AS question_nums,
        array_min(speaker_numbers) AS first_speaker_num, 
        array_min(lead_speaker_numbers) - 1 AS last_speaker_num 
    FROM questions_inter),

answers AS (
    SELECT a.file_name, b.first_speaker_num,
        array_agg(speaker_name ORDER BY speaker_number) AS answerers,
        array_agg(speaker_number ORDER BY speaker_number) AS answer_nums,
        array_agg(speaker_text ORDER BY speaker_number) AS answers,
        array_agg(role ORDER BY speaker_number) AS answerer_roles
    FROM sample_transcripts AS a
    INNER JOIN questions AS b
    ON a.file_name=b.file_name AND a.speaker_number>=b.first_speaker_num AND 
        (a.speaker_number <= b.last_speaker_num OR b.last_speaker_num IS NULL)
    WHERE is_answer
    GROUP BY a.file_name, b.first_speaker_num)

SELECT file_name, questioner, questions, question_nums,
  answerers, answer_nums, answers, answerer_roles
FROM questions 
INNER JOIN answers
USING (file_name, first_speaker_num) ;



