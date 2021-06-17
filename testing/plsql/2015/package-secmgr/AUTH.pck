create or replace package auth is
  -- Author  : SHAMIL
  -- Created : 08.04.2011 17:02:12
  -- Purpose : Поддержка авторизации на стороне сервера приложений
  function getUserPassword(iusername in varchar2) return varchar2;
  function userExists(iusername in varchar2) return varchar2;
  function groupExists(igroup in varchar2) return varchar2;


  procedure user_new(uname in varchar2, passwd in varchar2, idescr in varchar2);
  procedure user_passwd(passwd in varchar2, uname in varchar2);
  procedure user_del(uname in varchar2);

  procedure group_new(uname in varchar2, idescr in varchar2);
  procedure group_del(uname in varchar2);

  procedure member_remove(ugroup in varchar2, uname in varchar2);
  procedure member_add(ugroup in varchar2, uname in varchar2);
  procedure remove_member_from_group(ugroup in varchar2, uname in varchar2);

end auth;
/

create or replace package body auth is

  function getUserPassword(iusername in varchar2) return varchar2
  is
  passwd secmgr.emp.password%type:='';
  begin
-- По умолчанию SqlProvider: SELECT U_PASSWORD FROM USERS WHERE U_NAME = ?
-- Сейчас: SELECT auth.getUserPassword(:U_NAME) FROM dual
  SELECT e.password into passwd	FROM secmgr.emp e where e.username=iusername;
  sec_ctx.log('getUserPassowrd, username='||iusername);
  return passwd;
  exception when no_data_found then
    begin
--      select lastname into passwd
--      from test_operator.persons p
--      where p.name=iusername
--      and rownum=1;
      sec_ctx.log('Регистрация в системе, неверно введено имя пользователя='||iusername);
      return passwd;
    end;
  end getUserPassword;

  function userExists(iusername in varchar2) return varchar2
  is
  uname secmgr.emp.username%type;
  begin
-- По умолчанию SqlProvider: SELECT U_NAME FROM USERS WHERE U_NAME = ?
-- Сейчас: SELECT auth.userExists(:U_NAME) FROM dual
    SELECT e.username into uname FROM secmgr.emp e where e.username=iusername;
  return uname;
  exception when no_data_found then
    sec_ctx.log('Регистрация в системе, пользователь '||iusername||' не существует');
    return '';
  end userExists;

  procedure user_new(uname in varchar2, passwd in varchar2, idescr in varchar2) is
  begin
-- По умолчанию SqlProvider: INSERT INTO USERS VALUES ( ? , ? , ? )
-- Сейчас: begin auth.user_new(:U_NAME, :U_PASSWD, :U_DESCR); end;
  insert into secmgr.emp( id_emp, username, password, descr)
         values( seq_id_emp.nextval, uname, passwd,  idescr);
  commit;
  end user_new;

  procedure user_passwd(passwd in varchar2, uname in varchar2)
  is
  begin
    update secmgr.emp u
    set u.password=passwd
    where u.username=uname;
  commit;
  end user_passwd;

  procedure user_del(uname in varchar2) is
  begin
-- По умолчанию SqlProvider: DELETE FROM USERS WHERE U_NAME = ?
-- Сейчас: begin auth.user_del(:U_NAME); end;
    delete from secmgr.emp u where u.username = uname;
  commit;
  end user_del;

  function groupExists(igroup in varchar2) return varchar2
  is
  ugroup secmgr.emp.username%type;
  begin
-- По умолчанию SqlProvider: SELECT G_NAME FROM GROUPS WHERE G_NAME = ?
-- Сейчас: SELECT auth.groupExists(:U_GROUP) FROM dual
    SELECT e.name into ugroup FROM secmgr.grp e where e.name=igroup;
  return ugroup;
  exception when no_data_found then
    sec_ctx.log('Регистрация в системе, группа '||igroup||' не существует');
  end groupExists;

  procedure group_new(uname in varchar2, idescr in varchar2) is
  begin
-- По умолчанию SqlProvider: INSERT INTO GROUPS VALUES ( ? , ? )
-- Сейчас: begin auth.group_new(:U_GROUP, :U_DESCR); end;
  insert into secmgr.grp(id_group, name, descr)
  values( seq_id_group.nextval, uname, idescr);
  commit;
  end group_new;

  procedure group_del(uname in varchar2) is
  begin
-- По умолчанию SqlProvider: DELETE FROM GROUPS WHERE G_NAME = ?
-- Сейчас: begin auth.group_del(:U_GROUP); end;
  delete from secmgr.grp u where u.name = uname;
  commit;
  end group_del;

  procedure member_add(ugroup in varchar2, uname in varchar2) is
  v_id_group pls_integer;
  v_id_emp   pls_integer;
  begin
-- По умолчанию SqlProvider: INSERT INTO GROUPMEMBERS VALUES( ?, ?)
-- Сейчас: begin auth.member_remove(:G_GROUP, :G_NAME); end;
    select g.id_group into v_id_group from secmgr.grp g where g.name=ugroup;
    select e.id_emp into v_id_emp from secmgr.emp e where e.username=uname;
    INSERT INTO SECMGR.members_group_employee VALUES( v_id_group, v_id_emp);
  commit;
  exception when no_data_found then secmgr.sec_ctx.log('Не найдена группа или сотрудник');
  end member_add;

  procedure member_remove(ugroup in varchar2, uname in varchar2) is
  v_id_group pls_integer;
  v_id_emp   pls_integer;
  begin
-- По умолчанию SqlProvider: DELETE FROM GROUPMEMBERS WHERE G_MEMBER = ? OR G_NAME = ?
-- Сейчас: begin auth.member_remove(:G_MEMBER, :G_NAME); end;
    select g.id_group into v_id_group from secmgr.grp g where g.name=ugroup;
    select e.id_emp into v_id_emp from secmgr.emp e where e.username=uname;
    delete from secmgr.members_group_employee u
    where u.id_group = v_id_group
    or    u.id_emp = v_id_emp;
  commit;
  exception when no_data_found then secmgr.sec_ctx.log('Не найдена группа или сотрудник');
  end member_remove;

  procedure remove_member_from_group(ugroup in varchar2, uname in varchar2) is
  v_id_group pls_integer;
  v_id_emp   pls_integer;
  begin
-- По умолчанию SqlProvider: DELETE FROM GROUPMEMBERS WHERE G_NAME = ? AND G_MEMBER = ?
-- Сейчас: begin auth.remove_member_from_group(:G_NAME, :G_MEMBER); end;
    select g.id_group into v_id_group from secmgr.grp g where g.name=ugroup;
    select e.id_emp into v_id_emp from secmgr.emp e where e.username=uname;
    delete from secmgr.members_group_employee u
    where u.id_group = v_id_group
    and    u.id_emp = v_id_emp;
  commit;
  exception when no_data_found then secmgr.sec_ctx.log('Не найдена группа или сотрудник');
  end remove_member_from_group;

  procedure member_group_remove(ugroup in varchar2) is
  v_id_group pls_integer;
  begin
-- По умолчанию SqlProvider: DELETE FROM GROUPMEMBERS WHERE G_NAME = ?
-- Сейчас: begin auth.member_group_remove(:G_NAME); end;
    select g.id_group into v_id_group from secmgr.grp g where g.name=ugroup;
    DELETE FROM secmgr.members_group_employee u
    WHERE u.id_group = v_id_group;
  commit;
  exception when no_data_found then secmgr.sec_ctx.log('Не найдена группа');
  end member_group_remove;


--begin
  -- Initialization
--  <Statement>;
end auth;
/
