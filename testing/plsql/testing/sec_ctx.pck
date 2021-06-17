CREATE OR REPLACE PACKAGE sec_ctx AS
PROCEDURE set_userinfo (app_user VARCHAR2, iip_addr varchar2);
PROCEDURE clear_userinfo;
END;
/
CREATE OR REPLACE PACKAGE BODY sec_ctx AS
PROCEDURE set_userinfo(app_user VARCHAR2, iip_addr varchar2)
AS
-- the employee id and the job role is what the VPD policy in
-- the example is based on
p_deptno NUMBER;
p_employeeno NUMBER;
p_jobrole  VARCHAR2(100);
p_username VARCHAR2(128);
BEGIN
  -- get the user id
  BEGIN
    SELECT e.id_emp
    INTO p_employeeno
    FROM secmgr.emp e
    WHERE lower(e.username) = lower(app_user);
  EXCEPTION WHEN no_data_found THEN
  -- Setting employee number to 0, which means we lock the access
  p_employeeno := 0;
  END;
  BEGIN
    SELECT g.name
    INTO p_jobrole
    FROM secmgr.emp e, secmgr.grp g, secmgr.members_group_employee m
    WHERE lower(e.username) = lower(app_user)
    and   g.id_group = m.id_group
    and   m.id_emp = e.id_emp;
    --and   lower(g.g_type)='job_person';
  EXCEPTION WHEN no_data_found THEN
  -- Setting jobrole number to 0
  p_jobrole :='guest';
  END;
  BEGIN
    SELECT g.name
    INTO p_deptno
    FROM secmgr.emp e, secmgr.grp g, secmgr.members_group_employee m
    WHERE lower(e.username) = lower(app_user)
    and   g.id_group = m.id_group
    and   m.id_emp = e.id_emp;
--    and   lower(g.g_type)='org_unit';
  EXCEPTION WHEN no_data_found THEN
  -- Setting deptno number to 0
  p_deptno :=0;
  END;

  -- write the user detail information into the database session
  -- in a named context, which is accessed by the VPD policy function
  DBMS_SESSION.set_context(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'id_person',VALUE => p_employeeno);
  DBMS_SESSION.set_context(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'name',VALUE => app_user);
  DBMS_SESSION.set_context(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'ip_addr',VALUE => iip_addr);
  DBMS_SESSION.set_context(NAMESPACE => 'SEC_CTX', ATTRIBUTE => 'job', VALUE => p_jobrole);
  DBMS_SESSION.set_context(NAMESPACE => 'SEC_CTX', ATTRIBUTE => 'org_unit', VALUE => p_deptno);

  insert into log_testing( time_event, id_region, id_person, ip_addr, name, descr)
  values(sysdate, null, p_employeeno, iip_addr, app_user, 'logging');
  commit;
END set_userinfo;
-- do some housekeeping
PROCEDURE clear_userinfo AS
BEGIN
  DBMS_SESSION.CLEAR_CONTEXT(NAMESPACE => 'SEC_CTX', ATTRIBUTE =>'id_person');
  DBMS_SESSION.CLEAR_CONTEXT(namespace => 'SEC_CTX', ATTRIBUTE => 'name');
  DBMS_SESSION.CLEAR_CONTEXT(namespace => 'SEC_CTX', ATTRIBUTE => 'ip_addr');
  DBMS_SESSION.CLEAR_CONTEXT(namespace => 'SEC_CTX', ATTRIBUTE => 'job');
  DBMS_SESSION.CLEAR_CONTEXT(namespace => 'SEC_CTX', ATTRIBUTE => 'org_unit');
END;
END;
/
