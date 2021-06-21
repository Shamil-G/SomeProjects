LOAD DATA
INFILE 'infile/svod.csv'
BADFILE 'logs/bad_load_file.log'
INTO TABLE svod_smi_16
APPEND
FIELDS TERMINATED BY ';'
TRAILING NULLCOLS
(id, bin, fio char(512), lang char(32), type )  
 
