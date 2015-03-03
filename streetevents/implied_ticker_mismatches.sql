SELECT DISTINCT a.file_name, a.permno, c.co_name,
    b.ticker AS crsp_ticker, b.comnam, 
     streetevents.clean_tickers(c.ticker) AS ticker
FROM streetevents.manual_permno_matches AS a
INNER JOIN streetevents.calls AS c
USING (file_name)
INNER JOIN crsp.stocknames AS b
USING (permno)
WHERE b.ticker != streetevents.clean_tickers(c.ticker)
ORDER BY ticker, comnam;
