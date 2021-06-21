LOAD DATA
INFILE 'infile/svod.CSV'
BADFILE 'logs/shablon.bad'
TRUNCATE INTO TABLE svod_16
--INSERT
FIELDS TERMINATED BY ';'
TRAILING NULLCOLS
( id, priz, cat1 char(100), cat2 char(100), cat3 char(100), answer_ru char(2048), answer_kz char(2048))


