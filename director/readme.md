# Director data (Equilar)

The original data from Equilar are stored in two tables: `director` and `co_fin`. These data are imported using code in `import_equilar_director.R`.

The code in `create_equilar_proxies.sql` creates the table `director.equilar_proxies`, which maps the data in `director.director` to proxy filings on SEC's EDGAR.

The code in `match_directors.sql` is a crude attempt to match directors across firms. Equilar does not provide a way to match directors across firms. The results of this match are stored in `director.director_matches`.

The table `director.ciks` is created using data from `ciq.wrds_cusip` and `ciq.wrds_cik` using code in `create_ciqs.sql`.