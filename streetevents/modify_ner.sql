CREATE TABLE streetevents.ner_4class_questions AS 
SELECT 
  file_name,
  q_num AS question_num,
  ner_location,
  ner_time,
  ner_person,
  ner_organization,
  ner_money,
  ner_percent,
  ner_date,
  ner_number,
  ner_duration,
  ner_ordinal,
  ner_misc
FROM streetevents.ner_4class_questions;

ALTER TABLE  streetevents.ner_4class_questions ADD PRIMARY KEY (file_name, question_num);

DROP TABLE streetevents.ner_4class_q;

CREATE TABLE streetevents.ner_7class_questions AS 
SELECT 
  file_name text,
  q_num integer,
  ner_location,
  ner_time,
  ner_person,
  ner_organization,
  ner_money,
  ner_percent,
  ner_date,
  ner_number,
  ner_duration,
  ner_ordinal,
  ner_misc
FROM streetevents.ner_7class_q;


ALTER TABLE  streetevents.ner_7class_questions ADD PRIMARY KEY (file_name, question_num);

DROP TABLE streetevents.ner_7class_q;
