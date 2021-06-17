create or replace package sec_ctx AS

function getHashResult(iid_registration in simple_integer) return varchar2;

PROCEDURE set_userinfo( username VARCHAR2, id_person number, iip_addr varchar2, id_region number );
PROCEDURE set_userinfo(app_user VARCHAR2, appl_name varchar2, iip_addr varchar2);

PROCEDURE set_language (ilang in VARCHAR2);
PROCEDURE set_language (iid_reg in number, ilang in VARCHAR2);

PROCEDURE clear_userinfo;

function WhereUserIs return nvarchar2;
function IsUserInRoleSecmgr return number;
function IsUserInRoleThemeAdmin  return number;
function IsUserInRoleOperator return number;
function IsUserInRoleAssignAdmin  return number;
function IsUserInRoleAdmin  return number;

procedure log(iDebug in simple_integer, iappname in varchar2, ioperation in varchar2,
                imodule in nvarchar2, imessage in nvarchar2);
procedure log(iDebug in simple_integer, iappname in varchar2, ioperation in varchar2,
                imodule in nvarchar2, iid_registration in number,imessage in nvarchar2);
procedure log(iappname in varchar2, ioperation in varchar2,
                imodule in nvarchar2, imessage in nvarchar2);
procedure log(imessage in varchar2);
END;
/

create or replace package body sec_ctx AS

v_id_region number;
v_region_name  nvarchar2(128);
v_region_name_kaz  nvarchar2(128);

v_lang_territory nvarchar2(2);
v_language  varchar2(16);
v_name      nvarchar2(32);
v_lastname  nvarchar2(32);
v_id_pc     NUMBER;

p_deptno    NUMBER;
v_id_emp    number;
v_username  varchar(128);
v_job       varchar(64);
v_org_unit   varchar(64);
v_ip_addr   varchar2(15);
v_jobrole  VARCHAR2(100);

PROCEDURE set_userinfo(app_user VARCHAR2, appl_name varchar2, iip_addr varchar2)
AS
-- the employee id and the job role is what the VPD policy in
-- the example is based on

BEGIN
  v_username:=app_user;
  v_ip_addr:=iip_addr;
  -- get the user id
  BEGIN
  log('Start logging. Username='||app_user||', ip_addr='||iip_addr);

    SELECT e.id_region, e.id_emp, e.language, e.name, e.lastname, e.id_pc
    INTO v_id_region, v_id_emp, v_language, v_name, v_lastname, v_id_pc
    FROM secmgr.emp e
    WHERE lower(e.username) = lower(app_user);
  EXCEPTION WHEN no_data_found THEN
    begin
  -- Setting employee number to 0, which means we lock the access
        v_id_region := 1;
    end;
  END;

  if(v_id_region>=0)
  then
    begin
        select r.region_name, r.region_name_kaz, r.lang_territory
        into v_region_name, v_region_name_kaz, v_lang_territory
        from region r
        where r.id_region=v_id_region
        and r.active='Y';
        EXCEPTION WHEN no_data_found THEN
            begin
                v_region_name:='';
                v_region_name_kaz:='';
                v_lang_territory:='';
            end;
    end;
  end if;

  BEGIN
    v_jobrole:='';
    for Cur in (
    SELECT g.name, g.id_group
    INTO v_jobrole, p_deptno
    FROM secmgr.grp g, secmgr.members_group_employee m
    WHERE g.id_group = m.id_group
    and   m.id_emp = v_id_emp
    and   g.id_type_group=1 -- —отрудники
    )
    loop
        v_jobrole:=v_jobrole||Cur.name||';';
        p_deptno:=Cur.id_group;
    end loop;
    --and   lower(g.g_type)='job_person';
    if v_jobrole='' then
  -- Setting jobrole number to 0
        v_jobrole :='guest';
        p_deptno :=0;
    end if;
  END;
  log('Username='||app_user||', roles='||v_jobrole);

  -- write the user detail information into the database session
  -- in a named context, which is accessed by the VPD policy function
  DBMS_SESSION.set_context(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'application_name',VALUE => appl_name);
  DBMS_SESSION.set_context(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'id_region',VALUE => v_id_region);
  DBMS_SESSION.set_context(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'id_emp',VALUE => v_id_emp);
  DBMS_SESSION.set_context(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'language',VALUE => v_language);
  DBMS_SESSION.set_context(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'name',VALUE => v_name);
  DBMS_SESSION.set_context(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'lastname',VALUE => v_lastname);
  DBMS_SESSION.set_context(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'id_pc',VALUE => v_id_pc);

  DBMS_SESSION.set_context(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'region_name',VALUE => v_region_name);
  DBMS_SESSION.set_context(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'region_name_kaz',VALUE => v_region_name_kaz);
  DBMS_SESSION.set_context(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'lang_territory',VALUE => v_lang_territory);

  DBMS_SESSION.set_context(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'username',VALUE => app_user);
  DBMS_SESSION.set_context(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'ip_addr',VALUE => iip_addr);
  DBMS_SESSION.set_context(NAMESPACE => 'SEC_CTX', ATTRIBUTE => 'job', VALUE => v_jobrole);
  DBMS_SESSION.set_context(NAMESPACE => 'SEC_CTX', ATTRIBUTE => 'org_unit', VALUE => p_deptno);

  log('success logging');
  commit;
END set_userinfo;
-- do some housekeeping
PROCEDURE clear_userinfo AS
BEGIN
  DBMS_SESSION.CLEAR_CONTEXT(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'application_name');
  DBMS_SESSION.CLEAR_CONTEXT(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'id_region');
  DBMS_SESSION.CLEAR_CONTEXT(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'id_emp');
  DBMS_SESSION.CLEAR_CONTEXT(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'language');
  DBMS_SESSION.CLEAR_CONTEXT(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'name');
  DBMS_SESSION.CLEAR_CONTEXT(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'lastname');
  DBMS_SESSION.CLEAR_CONTEXT(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'id_pc');
  DBMS_SESSION.CLEAR_CONTEXT(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'region_name');
  DBMS_SESSION.CLEAR_CONTEXT(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'region_name_kaz');
  DBMS_SESSION.CLEAR_CONTEXT(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'lang_territory');


  DBMS_SESSION.CLEAR_CONTEXT(namespace => 'SEC_CTX', ATTRIBUTE => 'username');
  DBMS_SESSION.CLEAR_CONTEXT(namespace => 'SEC_CTX', ATTRIBUTE => 'ip_addr');
  DBMS_SESSION.CLEAR_CONTEXT(namespace => 'SEC_CTX', ATTRIBUTE => 'job');
  DBMS_SESSION.CLEAR_CONTEXT(namespace => 'SEC_CTX', ATTRIBUTE => 'org_unit');
END;

PROCEDURE set_userinfo(username VARCHAR2, id_person number, iip_addr varchar2, id_region number)
is
begin
  DBMS_SESSION.CLEAR_CONTEXT(namespace => 'SEC_CTX', ATTRIBUTE => 'username');
  DBMS_SESSION.CLEAR_CONTEXT(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'id_emp');
  DBMS_SESSION.CLEAR_CONTEXT(namespace => 'SEC_CTX', ATTRIBUTE => 'ip_addr');
  DBMS_SESSION.CLEAR_CONTEXT(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'id_region');

  DBMS_SESSION.set_context(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'username',VALUE => username);
  DBMS_SESSION.set_context(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'id_emp',VALUE => id_person);
  DBMS_SESSION.set_context(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'ip_addr',VALUE => iip_addr);
  DBMS_SESSION.set_context(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'id_region',VALUE => id_region);
/*
  raise_application_error(-20001,
        ', v_ip_addr: '||iip_addr||
        ', v_username: '||username||
        ', iid_pc: '||iid_pc||
        ', v_region_name: '||region_name );
*/
end;


function WhereUserIs return nvarchar2
is
begin
 return sys_context('sec_ctx', 'region_name');
end WhereUserIs;

function IsUserInRoleSecmgr
return number
is
begin
    if instr(lower(sys_context('sec_ctx', 'job')),'secmgr',1)>0
    then
    return 1;
    end if;
    return 0;
end;

function IsUserInRoleAdmin
return number
is
begin
    secmgr.sec_ctx.log('Admin role='||sys_context('sec_ctx', 'job'));
    if instr(lower(sys_context('sec_ctx', 'job')),'admin',1)>0
    then
    return 1;
    end if;
    return 0;
end;

function IsUserInRoleAssignAdmin
return number
is
begin
    secmgr.sec_ctx.log('Admin role='||sys_context('sec_ctx', 'job'));
    if instr(lower(sys_context('sec_ctx', 'job')),'assignadmin',1)>0
    then
    return 1;
    end if;
    return 0;
end;

function IsUserInRoleThemeAdmin
return number
is
begin
    if instr(lower(sys_context('sec_ctx', 'job')),'themeadmin',1)>0
    then
    return 1;
    end if;
    return 0;
end;

function IsUserInRoleOperator
return number
is
begin
--    secmgr.sec_ctx.log('role='||sys_context('sec_ctx', 'job'));
    if instr(lower(sys_context('sec_ctx', 'job')),'operator',1)>0
    then
    return 1;
    end if;
    return 0;
end;

PROCEDURE set_language (ilang in VARCHAR2)
is
begin
  DBMS_SESSION.CLEAR_CONTEXT(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'language');
  DBMS_SESSION.set_context(NAMESPACE =>'SEC_CTX', ATTRIBUTE => 'language',VALUE => ilang);
end;

PROCEDURE set_language (iid_reg in number, ilang in VARCHAR2)
is
v_code nvarchar2(8);
PRAGMA AUTONOMOUS_TRANSACTION;
begin
  if iid_reg is null or ilang is null then
    return;
  end if;
  begin
    select code into v_code from test_operator.supp_lang l where l.code=ilang;
  exception when no_data_found then
    begin
        log('языкова€ поддержка дл€ "ilang" отсутствует');
        return;
    end;
  end;
  -- ”далим вопорсы на других €зыках
  delete from TEST_OPERATOR.questions_for_testing qt
  where qt.id_registration=iid_reg and qt.language!=ilang;
  update TEST_OPERATOR.registration r
  set r.language=ilang
  where r.id_registration=iid_reg;
  commit;
  set_language(ilang);
end;

procedure log(idebug simple_integer, iappname in varchar2, ioperation in varchar2,
                imodule in nvarchar2, imessage in nvarchar2)
is
PRAGMA AUTONOMOUS_TRANSACTION;
v_id_emp simple_integer:=0;
begin
--  raise_application_error(-20001, 'idebug: '||idebug||', getDebug: '||getDebug);
  if idebug>=GSEC_CTX.getDebug then
      v_ip_addr:=nvl(sys_context('sec_ctx', 'ip_addr'),'unknown');
      v_username:=nvl(sys_context('sec_ctx', 'username'),'unknown');
      v_id_region:=nvl(sys_context('sec_ctx', 'id_region'), 0);
      v_id_emp:=nvl(sys_context('sec_ctx', 'id_emp'), 0);
      insert into log_testing( time_event, ip_addr, id_region,
                id_person, name,
                application, operation, module, descr)
      values( systimestamp, v_ip_addr, v_id_region,
                v_id_emp, v_username,
                iappname, ioperation, imodule, imessage);

      commit;
  end if;
end log;

procedure log(idebug simple_integer, iappname in varchar2, ioperation in varchar2,
                imodule in nvarchar2,
                iid_registration in number,
                imessage in nvarchar2)
is
PRAGMA AUTONOMOUS_TRANSACTION;
v_id_emp simple_integer:=0;
begin
  secmgr.sec_ctx.log(iDebug=>idebug,
            iappname=>iappname,
            ioperation=>ioperation,
            imodule=>imodule,
            imessage=> imessage||
            ', »д регистр.: '||iid_registration );
--            secmgr.ctl.second_check(iid_registration);
end log;

procedure log(iappname in varchar2, ioperation in varchar2,
                imodule in nvarchar2, imessage in nvarchar2)
is
PRAGMA AUTONOMOUS_TRANSACTION;
begin
    log(3, iappname, ioperation, imodule, imessage);
end log;

procedure log(imessage in varchar2)
is
PRAGMA AUTONOMOUS_TRANSACTION;
begin
  v_ip_addr:=nvl(v_ip_addr,'unknown');
  insert into log_testing( time_event, id_region, ip_addr, name, descr)
  values(systimestamp, v_id_region, v_ip_addr, v_username, imessage);
  commit;
end log;

function getHashResult(iid_registration in simple_integer) return varchar2
is
ResI varchar2(2000);
ResII varchar2(2000);
Res varchar2(32);
begin
  select (
        p.lastname||
        p.name||p.middlename||p.iin||
        r.id_registration||
        r.beg_time_testing||
        r.status ||
        b.code_bundle||
        b.min_point)
  into ResI
  from test_operator.registration r, TEST_OPERATOR.persons p, test_operator.bundle b
  where r.id_registration=iid_registration
  and   r.id_bundle=b.id_bundle
  and   r.id_person=p.id_person;

  for cur in ( select * from test_operator.users_bundle_composition bc
               where bc.id_registration=iid_registration)
  loop
    ResII:=ResII||cur.id_theme||cur.count_question||cur.scores;
  end loop;
  ResI:=ResI||ResII;
  Res:=utl_raw.cast_to_varchar2(utl_encode.base64_encode(dbms_crypto.hash (src=>utl_i18n.string_to_raw(ResI,'AL32UTF8'),typ=>dbms_crypto.hash_sh1)));
  return Res;
end getHashResult;

END;
/
