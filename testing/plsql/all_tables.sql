
CREATE TABLE bundle_composition
(
	id_composition       NUMBER(9) NOT NULL ,
	id_bundle_theme      NUMBER(9) NOT NULL ,
	id_theme             NUMBER(6) NOT NULL ,
	id_param             NUMBER(9) NULL ,
	is_groups            CHAR(1) NULL ,
	theme_number         NUMBER(2) NULL ,
	count_question       NUMBER(4) NULL ,
	count_success        NUMBER(3) NULL ,
	period_for_testing   NUMBER(5) NULL 
);



CREATE UNIQUE INDEX XPK_bundle_composition ON bundle_composition
(id_composition   ASC);



CREATE TABLE bundle_config
(
	id_param             NUMBER(9) NOT NULL ,
	period_for_testing   NUMBER(5) NULL 
);



CREATE UNIQUE INDEX XPK_configure_testing ON bundle_config
(id_param   ASC);



CREATE TABLE categories
(
	category             NATIONAL CHAR(1) NOT NULL ,
	active               CHAR(1) NULL ,
	descr                NVARCHAR2(256) NULL ,
	descr_kaz            NVARCHAR2(256) NULL 
);



CREATE UNIQUE INDEX XPK_id_category_person ON categories
(category   ASC);



CREATE TABLE category_position
(
	id_category_for_position NUMBER(5) NOT NULL ,
	category             NATIONAL CHAR(1) NOT NULL ,
	id_equal_category    NUMBER(5) NULL ,
	code_category        VARCHAR2(20) NULL ,
	descr                NVARCHAR2(256) NULL ,
	descr_kaz            NVARCHAR2(256) NULL 
);



CREATE UNIQUE INDEX XPK_category_position ON category_position
(id_category_for_position   ASC);



CREATE TABLE degrees
(
	id_degree            NUMBER(2) NOT NULL ,
	name_degree          NVARCHAR2(256) NULL ,
	name_degree_kaz      NVARCHAR2(256) NULL 
);



CREATE UNIQUE INDEX XPK_degree ON degrees
(id_degree   ASC);



CREATE TABLE educations
(
	id_education         NUMBER(2) NOT NULL ,
	education            NVARCHAR2(256) NULL ,
	education_kaz        NVARCHAR2(256) NULL 
);



CREATE UNIQUE INDEX XPK_educations ON educations
(id_education   ASC);



CREATE TABLE emp
(
	id_emp               NUMBER(9) NOT NULL ,
	id_region            NUMBER(3) NULL ,
	id_pc                NUMBER(6) NULL ,
	active               CHAR(1) NULL ,
	language             CHAR(2) NULL ,
	date_op              DATE NULL ,
	username             NVARCHAR2(32) NULL ,
	password             VARCHAR2(64) NULL ,
	attr                 VARCHAR2(20) NULL ,
	name                 NVARCHAR2(64) NULL ,
	lastname             NVARCHAR2(64) NULL ,
	middlename           NVARCHAR2(64) NULL ,
	descr                NVARCHAR2(256) NULL 
);



CREATE UNIQUE INDEX XUK_employees_username ON emp
(username   ASC);



CREATE TABLE equals_category
(
	id_equal_category    NUMBER(5) NOT NULL ,
	active               CHAR(1) NULL ,
	descr                NVARCHAR2(256) NULL ,
	descr_kaz            NVARCHAR2(256) NULL 
);



CREATE UNIQUE INDEX XPK_equals_category ON equals_category
(id_equal_category   ASC);



CREATE TABLE groups_tests
(
	id_group             NUMBER(9) NOT NULL ,
	id_organization      NUMBER(9) NULL ,
	id_kind_testing      NUMBER(5) NULL ,
	id_category_for_position NUMBER(5) NULL ,
	id_bundle_theme      NUMBER(9) NULL ,
	active               CHAR(1) NULL ,
	name_test_group      VARCHAR2(256) NULL 
);



CREATE UNIQUE INDEX XPK_groups_testing ON groups_tests
(id_group   ASC);



CREATE TABLE grp
(
	id_group             NUMBER(9) NOT NULL ,
	id_type_group        NUMBER(2) NULL ,
	active               CHAR(1) NULL ,
	date_op              DATE NULL ,
	name                 NVARCHAR2(64) NULL ,
	descr                NVARCHAR2(256) NULL 
);



CREATE UNIQUE INDEX XAK_grp_name ON grp
(name   ASC);



CREATE TABLE kind_testing
(
	id_kind_testing      NUMBER(5) NOT NULL ,
	active               CHAR(1) NULL ,
	descr                NVARCHAR2(256) NULL ,
	descr_kaz            NVARCHAR2(256) NULL 
);



CREATE UNIQUE INDEX XPK_kind_testing ON kind_testing
(id_kind_testing   ASC);



CREATE TABLE list_workstation
(
	id_pc                NUMBER(6) NOT NULL ,
	id_region            NUMBER(3) NOT NULL ,
	active               CHAR(1) NULL ,
	num_device           NUMBER(2) NULL ,
	type_device          NATIONAL CHAR(1) NULL ,
	date_op              DATE NULL ,
	ip_addr              VARCHAR2(15) NULL 
);



CREATE UNIQUE INDEX XPK_list_workstation ON list_workstation
(id_pc   ASC);



CREATE UNIQUE INDEX XUK_list_workstation_ip_addr ON list_workstation
(ip_addr   ASC);



CREATE TABLE log_testing
(
	time_event           TIMESTAMP NOT NULL ,
	ip_addr              VARCHAR2(15) NOT NULL ,
	id_region            NUMBER(3) NULL ,
	id_person            NUMBER(15) NULL ,
	name                 NVARCHAR2(64) NULL ,
	descr                NVARCHAR2(256) NULL 
);



CREATE UNIQUE INDEX XPK_log_testing ON log_testing
(time_event   ASC,ip_addr   ASC);



CREATE TABLE members_group_employee
(
	id_group             NUMBER(9) NOT NULL ,
	id_emp               NUMBER(9) NOT NULL 
);



CREATE UNIQUE INDEX XPK_MGO_id_group_id_emp ON members_group_employee
(id_group   ASC,id_emp   ASC);



CREATE TABLE nationals
(
	id_national          NUMBER(6) NOT NULL ,
	order_num            NUMBER(4) NULL ,
	national             NVARCHAR2(256) NULL ,
	national_kaz         NVARCHAR2(256) NULL 
);



CREATE UNIQUE INDEX XPK_nationals ON nationals
(id_national   ASC);



CREATE TABLE org_positions
(
	id_position_org      NUMBER(9) NOT NULL ,
	active               CHAR(1) NULL ,
	id_position          NUMBER(11) NULL ,
	id_organization      NUMBER(9) NOT NULL ,
	id_category_for_position NUMBER(5) NULL 
);



CREATE UNIQUE INDEX XPK_org_positions ON org_positions
(id_position_org   ASC);



CREATE TABLE org_subdivisions
(
	id_subdivision_in_org NUMBER(15) NOT NULL ,
	active               CHAR(1) NULL ,
	id_organization      NUMBER(9) NULL ,
	id_subdivision       NUMBER(9) NULL 
);



CREATE UNIQUE INDEX XPK_org_subdivision ON org_subdivisions
(id_subdivision_in_org   ASC);



CREATE UNIQUE INDEX XUK_org_subdivisions ON org_subdivisions
(id_organization   ASC,id_subdivision   ASC);



CREATE TABLE organizations
(
	id_organization      NUMBER(9) NOT NULL ,
	category             NATIONAL CHAR(1) NULL ,
	active               CHAR(1) NULL ,
	name_organization    NVARCHAR2(256) NULL ,
	name_organization_kaz NVARCHAR2(256) NULL 
);



CREATE UNIQUE INDEX XPK_organizations ON organizations
(id_organization   ASC);



CREATE TABLE persons
(
	id_person            NUMBER(15) NOT NULL ,
	id_national          NUMBER(6) NULL ,
	iin                  VARCHAR2(12) NULL ,
	birthday             DATE NULL ,
	sex                  NATIONAL CHAR(1) NULL ,
	name                 NVARCHAR2(64) NULL ,
	lastname             NVARCHAR2(64) NULL ,
	middlename           NVARCHAR2(64) NULL ,
	doc_num              VARCHAR2(20) NULL ,
	email                VARCHAR2(128) NULL 
);



CREATE UNIQUE INDEX XPK_persons ON persons
(id_person   ASC);



CREATE UNIQUE INDEX XUK_persons_iin ON persons
(iin   ASC);



CREATE TABLE picture
(
	id_question          NUMBER(16) NOT NULL ,
	descr_kaz            NVARCHAR2(256) NULL ,
	descr                NVARCHAR2(256) NULL ,
	picture              BLOB NULL ,
	picture_kaz          BLOB NULL 
);



CREATE UNIQUE INDEX XPK_pictures ON picture
(id_question   ASC);



CREATE TABLE positions
(
	id_position          NUMBER(11) NOT NULL ,
	active               CHAR(1) NULL ,
	name_position        NVARCHAR2(128) NULL ,
	name_position_kaz    NVARCHAR2(128) NULL 
);



CREATE UNIQUE INDEX XPK_positions ON positions
(id_position   ASC);



CREATE TABLE questions
(
	id_question          NUMBER(16) NOT NULL ,
	id_theme             NUMBER(6) NULL ,
	active               CHAR(1) NULL ,
	question             NVARCHAR2(2048) NULL ,
	question_kaz         NVARCHAR2(2048) NULL 
);



CREATE UNIQUE INDEX XPK_list_questions ON questions
(id_question   ASC);



CREATE TABLE questions_for_testing
(
	id_registration      NUMBER(16) NOT NULL ,
	id_theme             NUMBER(6) NOT NULL ,
	order_num            NUMBER(4) NOT NULL ,
	id_question          NUMBER(16) NOT NULL ,
	id_reply             NUMBER(16) NULL ,
	time_reply           TIMESTAMP NULL 
);



CREATE UNIQUE INDEX XPK_question4testing ON questions_for_testing
(id_theme   ASC,order_num   ASC,id_registration   ASC);



CREATE TABLE region
(
	id_region            NUMBER(3) NOT NULL ,
	active               CHAR(1) NULL ,
	date_op              DATE NULL ,
	lang_territory       CHAR(2) NULL ,
	region_name          VARCHAR2(128) NULL ,
	region_name_kaz      VARCHAR2(128) NULL 
);



CREATE TABLE registration
(
	id_registration      NUMBER(16) NOT NULL ,
	id_person            NUMBER(15) NOT NULL ,
	category             NATIONAL CHAR(1) NULL ,
	id_organization      NUMBER(9) NOT NULL ,
	id_category_for_position NUMBER(5) NULL ,
	date_registration    TIMESTAMP NULL ,
	id_education         NUMBER(2) NULL ,
	id_degree            NUMBER(2) NULL ,
	id_kind_testing      NUMBER(5) NULL ,
	id_emp               NUMBER(9) NULL ,
	id_admin             NUMBER(9) NULL ,
	id_region            NUMBER(3) NULL ,
	id_subdivision_in_org NUMBER(15) NULL ,
	id_position_org      NUMBER(9) NULL ,
	id_pc                NUMBER(6) NULL ,
	gov_record_service   NUMBER(2) NULL ,
	experience_in_special NUMBER(2) NULL ,
	language             CHAR(2) NULL ,
	date_testing         DATE NULL ,
	beg_time_testing     TIMESTAMP NULL ,
	end_time_testing     TIMESTAMP NULL ,
	end_day_testing      DATE NULL ,
	key_access           VARCHAR2(32) NULL ,
	status               NVARCHAR2(32) NULL 
);



CREATE UNIQUE INDEX XPK_registration ON registration
(id_registration   ASC);



CREATE TABLE replies
(
	id_reply             NUMBER(16) NOT NULL ,
	id_question          NUMBER(16) NULL ,
	order_num            NUMBER(4) NULL ,
	correctly            CHAR(1) NULL ,
	active               CHAR(1) NULL ,
	reply                NVARCHAR2(1024) NULL ,
	reply_kaz            NVARCHAR2(1024) NULL 
);



CREATE UNIQUE INDEX XPK_replies ON replies
(id_reply   ASC);



CREATE TABLE subdivisions
(
	id_subdivision       NUMBER(9) NOT NULL ,
	active               CHAR(1) NULL ,
	id_region            NUMBER(3) NULL ,
	name_subdivision     NVARCHAR2(128) NULL ,
	name_subdivision_kaz NVARCHAR2(128) NULL 
);



CREATE UNIQUE INDEX XPK_subdivisions ON subdivisions
(id_subdivision   ASC);



CREATE TABLE testing
(
	id_registration      NUMBER(16) NOT NULL ,
	id_bundle_theme      NUMBER(9) NULL ,
	id_current_theme     NUMBER(6) NULL ,
	beg_time_testing     TIMESTAMP NULL ,
	last_time_access     TIMESTAMP NULL ,
	status_testing       NVARCHAR2(32) NULL 
);



CREATE UNIQUE INDEX XPK_testing ON testing
(id_registration   ASC);



CREATE TABLE theme_bundle
(
	id_bundle_theme      NUMBER(9) NOT NULL ,
	active               CHAR(1) NULL ,
	name_theme_bundle    NVARCHAR2(128) NULL ,
	name_theme_bundle_kaz NVARCHAR2(128) NULL ,
	descr                NVARCHAR2(256) NULL 
);



CREATE UNIQUE INDEX XPK_theme_bundle ON theme_bundle
(id_bundle_theme   ASC);



CREATE TABLE themes
(
	id_theme             NUMBER(6) NOT NULL ,
	active               CHAR(1) NULL ,
	descr                NVARCHAR2(256) NULL ,
	descr_kaz            NVARCHAR2(256) NULL 
);



CREATE UNIQUE INDEX XPK_themes ON themes
(id_theme   ASC);



CREATE TABLE types_group
(
	id_type_group        NUMBER(2) NOT NULL ,
	group_type           VARCHAR2(32) NULL 
);



CREATE UNIQUE INDEX XPK_types_group ON types_group
(id_type_group   ASC);



CREATE TABLE users_bundle_composition
(
	id_registration      NUMBER(16) NOT NULL ,
	id_theme             NUMBER(6) NOT NULL ,
	id_param             NUMBER(9) NULL ,
	is_groups            CHAR(1) NULL ,
	theme_number         NUMBER(2) NULL ,
	order_num            NUMBER(4) NULL ,
	count_question       NUMBER(4) NULL ,
	count_success        NUMBER(3) NULL ,
	period_for_testing   NUMBER(5) NULL ,
	used_time            NUMBER(5) NULL ,
	status_testing       NVARCHAR2(32) NULL 
);



CREATE UNIQUE INDEX XPK_users_bundle_composition ON users_bundle_composition
(id_theme   ASC,id_registration   ASC);



CREATE TABLE users_bundle_config
(
	id_registration      NUMBER(16) NOT NULL ,
	id_param             NUMBER(9) NOT NULL ,
	period_for_testing   NUMBER(5) NULL ,
	used_time            NUMBER(5) NULL 
);



CREATE UNIQUE INDEX XPK_users_bundle_config ON users_bundle_config
(id_registration   ASC,id_param   ASC);


