DROP VIEW activist_director.permnos;

ALTER TABLE crsp.ccmxpf_linktable ALTER lpermno TYPE bigint;
ALTER TABLE crsp.ccmxpf_linktable ALTER lpermco TYPE bigint;
ALTER TABLE crsp.stocknames ALTER permno TYPE bigint;
ALTER TABLE crsp.stocknames ALTER permco TYPE bigint;

CREATE OR REPLACE VIEW activist_director.permnos AS 
 SELECT DISTINCT stocknames.permno,
    stocknames.ncusip
   FROM crsp.stocknames
  WHERE stocknames.ncusip IS NOT NULL
UNION
 SELECT DISTINCT missing_permnos.permno,
    missing_permnos.cusip AS ncusip
   FROM activism.missing_permnos
  WHERE missing_permnos.permno IS NOT NULL;

ALTER VIEW activist_director.permnos OWNER TO activism;
