WITH unique_old AS (
  SELECT announce_date, cusip_9_digit
  FROM factset.sharkwatch_old
  GROUP BY announce_date, cusip_9_digit
  HAVING COUNT(DISTINCT dissident_group)=1),
old_events AS (
  SELECT announce_date, cusip_9_digit,
      regexp_split_to_array(regexp_replace(dissident_group_with_sharkwatch50,
      '\s+SharkWatch50\?:\s+(Yes|No)', '', 'g'), E'Dissident Group: ') AS dissidents_old
  FROM factset.sharkwatch_old
  INNER JOIN unique_old
  USING (announce_date, cusip_9_digit)),
unique_new AS (
  SELECT announce_date, cusip_9_digit
  FROM factset.sharkwatch_new
  GROUP BY announce_date, cusip_9_digit
  HAVING COUNT(DISTINCT dissident_group)=1),
new_events AS (
  SELECT announce_date, cusip_9_digit,
    regexp_split_to_array(regexp_replace(dissident_group_with_sharkwatch50,
      '\s+SharkWatch50\?:\s+(Yes|No)', '', 'g'), E'Dissident Group: ') AS dissidents_new
  FROM factset.sharkwatch_new
  INNER JOIN unique_new
  USING (announce_date, cusip_9_digit)),
dissident_name_changes AS (
    SELECT DISTINCT
      unnest(dissidents_old) AS dissident_old,
      unnest(dissidents_new) AS dissident_new
    FROM old_events
    INNER JOIN new_events
    USING (announce_date, cusip_9_digit)
    WHERE NOT (dissidents_new @> dissidents_old)
      AND array_length(dissidents_old, 1)=2
      AND array_length(dissidents_new, 1)=2),
sharkwatch_old AS (
    SELECT cusip_9_digit, COALESCE(dissident_new, dissident_group) AS dissident_group,
        announce_date, company_name
    FROM factset.sharkwatch_old AS a
    INNER JOIN dissident_name_changes AS b
    ON a.dissident_group=b.dissident_old)

SELECT cusip_9_digit, dissident_group, announce_date,
    a.company_name AS company_name_new,
    b.company_name AS company_name_old, campaign_id
FROM factset.sharkwatch_new AS a
FULL OUTER JOIN sharkwatch_old AS b
USING (cusip_9_digit, dissident_group, announce_date)
-- WHERE cusip_9_digit IS NOT NULL AND campaign_id IS NULL
ORDER BY cusip_9_digit, dissident_group, announce_date
