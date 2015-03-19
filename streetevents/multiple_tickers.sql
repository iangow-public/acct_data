SELECT file_name, array_agg(DISTINCT ticker) AS tickers
FROM streetevents.calls_test
GROUP BY file_name
HAVING COUNT(DISTINCT ticker)>1;