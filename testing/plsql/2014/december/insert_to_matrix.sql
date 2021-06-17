
ALTER TABLE test_operator.registration
DROP CONSTRAINT YR_bundle_registration;



ALTER TABLE test_operator.registration
DROP CONSTRAINT YR_emp_Registration_id_emp;



ALTER TABLE test_operator.registration
DROP CONSTRAINT YR_persons_Registration;



ALTER TABLE test_operator.registration
DROP CONSTRAINT YR_region_Registration;



ALTER TABLE test_operator.registration
DROP CONSTRAINT Yr_type_reg_registration;



ALTER TABLE test_operator.registration
DROP CONSTRAINT YR_list_workstation_registr;



ALTER TABLE test_operator.registration
DROP PRIMARY KEY CASCADE  DROP INDEX;



ALTER TABLE type_registration
DROP PRIMARY KEY CASCADE  DROP INDEX;



DROP INDEX test_operator.XK_registration_status;



DROP INDEX test_operator.XFK_registration_id_bundle;



DROP INDEX test_operator.XFK_registration_id_emp;



DROP INDEX test_operator.XFK_registration_id_person;



DROP INDEX test_operator.XFK_registration_id_region;



DROP INDEX test_operator.XFK_registration_id_type_reg;



DROP INDEX test_operator.XFK_registration_ip_addr;



DROP INDEX test_operator.XPK_registration;



DROP TABLE test_operator.registration CASCADE CONSTRAINTS PURGE;



DROP INDEX XPK_type_registration;



DROP TABLE type_registration CASCADE CONSTRAINTS PURGE;



CREATE TABLE test_operator.registration
(
	id_registration      NUMBER(16) NOT NULL ,
	id_person            NUMBER(15) NOT NULL ,
	date_registration    TIMESTAMP NULL ,
	id_bundle            NUMBER(9) NULL ,
	id_type_registration NUMBER(2) NULL ,
	id_emp               NUMBER(9) NULL ,
	id_region            NUMBER(3) NULL ,
	id_pc                NUMBER(6) NULL ,
	date_testing         DATE NULL ,
	beg_time_testing     TIMESTAMP NULL ,
	end_time_testing     TIMESTAMP NULL ,
	end_day_testing      DATE NULL ,
	language             NVARCHAR2(2) NULL ,
	signature            NVARCHAR2(64) NULL ,
	status               NVARCHAR2(128) NULL 
);



COMMENT ON TABLE test_operator.registration IS 'Регистрация тестируемых';



CREATE UNIQUE INDEX test_operator.XPK_registration ON test_operator.registration
(id_registration   ASC);



ALTER TABLE test_operator.registration
	ADD CONSTRAINT  XPK_registration PRIMARY KEY (id_registration);



CREATE  INDEX test_operator.XK_registration_status ON test_operator.registration
(status   ASC);



CREATE TABLE type_registration
(
	id_type_registration NUMBER(2) NOT NULL ,
	active               CHAR(1) NULL ,
	descr                NVARCHAR2(32) NULL 
);



CREATE UNIQUE INDEX XPK_type_registration ON type_registration
(id_type_registration   ASC);



ALTER TABLE type_registration
	ADD CONSTRAINT  XPK_type_registration PRIMARY KEY (id_type_registration);



ALTER TABLE test_operator.registration
	ADD (CONSTRAINT YR_bundle_registration FOREIGN KEY (id_bundle) REFERENCES test_operator.bundle (id_bundle) ON DELETE SET NULL);



ALTER TABLE test_operator.registration
	ADD (CONSTRAINT YR_emp_Registration_id_emp FOREIGN KEY (id_emp) REFERENCES secmgr.emp (id_emp) ON DELETE SET NULL);



ALTER TABLE test_operator.registration
	ADD (CONSTRAINT YR_persons_Registration FOREIGN KEY (id_person) REFERENCES test_operator.persons (id_person));



ALTER TABLE test_operator.registration
	ADD (CONSTRAINT YR_region_Registration FOREIGN KEY (id_region) REFERENCES secmgr.region (id_region) ON DELETE SET NULL);



ALTER TABLE test_operator.registration
	ADD (CONSTRAINT Yr_type_reg_registration FOREIGN KEY (id_type_registration) REFERENCES type_registration (id_type_registration) ON DELETE SET NULL);



ALTER TABLE test_operator.registration
	ADD (CONSTRAINT YR_list_workstation_registr FOREIGN KEY (id_pc) REFERENCES secmgr.list_workstation (id_pc) ON DELETE SET NULL);


