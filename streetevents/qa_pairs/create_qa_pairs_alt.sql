CREATE TABLE streetevents.qa_pairs AS 
 WITH answers AS (
         SELECT a.file_name,
            array_agg(a.speaker_name ORDER BY a.speaker_number) AS answerers,
            array_agg(a.speaker_number ORDER BY a.speaker_number) AS answer_nums,
            array_agg(a.speaker_text ORDER BY a.speaker_number) AS answers,
            array_agg(a.role ORDER BY a.speaker_number) AS answerer_roles
           FROM streetevents.speaker_data a
             JOIN streetevents.qa_pair_data b USING (file_name)
          WHERE a.context = 'qa'::text AND (a.speaker_number = ANY (b.answer_nums))
          GROUP BY a.file_name
        ), questions AS (
         SELECT a.file_name,
            a.speaker_name AS questioner,
            array_agg(a.speaker_number ORDER BY a.speaker_number) AS question_nums,
            array_agg(a.speaker_text ORDER BY a.speaker_number) AS questions
           FROM streetevents.speaker_data a
             JOIN streetevents.qa_pair_data b USING (file_name)
          WHERE a.context = 'qa'::text AND (a.speaker_number = ANY (b.question_nums))
          GROUP BY a.file_name, a.speaker_name
        )
 SELECT qa_pair_data.file_name,
    questions.questioner,
    questions.questions,
    qa_pair_data.question_nums,
    answers.answerers,
    qa_pair_data.answer_nums,
    answers.answers,
    answers.answerer_roles
   FROM streetevents.qa_pair_data
     JOIN answers USING (file_name, answer_nums)
     JOIN questions USING (file_name, question_nums);

ALTER TABLE streetevents.qa_pairs
  OWNER TO igow;

