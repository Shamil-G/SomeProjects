create or replace package AuthProvider is
  -- Author  : SHAMIL
  -- Created : 08.04.2011 17:02:12
  -- Purpose : Поддержка авторизации на стороне сервера приложений

  procedure user_new(uname in varchar2, passwd in varchar2, idescr in varchar2);
  procedure user_passwd(passwd in varchar2, uname in varchar2);
  procedure user_del(uname in varchar2);

  procedure group_new(uname in varchar2, idescr in varchar2);
  procedure group_del(uname in varchar2);

  procedure member_remove(ugroup in varchar2, uname in varchar2);
  procedure member_add(ugroup in varchar2, uname in varchar2);
  procedure remove_member_from_group(ugroup in varchar2, uname in varchar2);

end AuthProvider;
/

create or replace package body AuthProvider is

  procedure user_new(uname in varchar2, passwd in varchar2, idescr in varchar2) is
  begin
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
    delete from secmgr.emp u where u.username = uname;
  commit;
  end user_del;

  procedure group_new(uname in varchar2, idescr in varchar2) is
  begin
  insert into secmgr.grp(id_group, name, descr)
  values( seq_id_group.nextval, uname, idescr);
  commit;
  end group_new;

  procedure group_del(uname in varchar2) is
  begin
  delete from secmgr.grp u where u.name = uname;
  commit;
  end group_del;


  procedure member_add(ugroup in varchar2, uname in varchar2) is
  v_id_group pls_integer;
  v_id_emp   pls_integer;
  begin
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
    select g.id_group into v_id_group from secmgr.grp g where g.name=ugroup;
    select e.id_emp into v_id_emp from secmgr.emp e where e.username=uname;
    delete from secmgr.members_group_employee u
    where u.id_group = v_id_group
    or    u.id_emp = v_id_emp;
  commit;
  exception when no_data_found then secmgr.sec_ctx.log('Не найдена группа или сотрудник');
  end member_remove;

  procedure member_group_remove(ugroup in varchar2) is
  v_id_group pls_integer;
  begin
    select g.id_group into v_id_group from secmgr.grp g where g.name=ugroup;
    DELETE FROM secmgr.members_group_employee u
    WHERE u.id_group = v_id_group;
  commit;
  exception when no_data_found then secmgr.sec_ctx.log('Не найдена группа');
  end member_group_remove;

  procedure remove_member_from_group(ugroup in varchar2, uname in varchar2) is
  v_id_group pls_integer;
  v_id_emp   pls_integer;
  begin
    select g.id_group into v_id_group from secmgr.grp g where g.name=ugroup;
    select e.id_emp into v_id_emp from secmgr.emp e where e.username=uname;
    delete from secmgr.members_group_employee u
    where u.id_group = v_id_group
    and    u.id_emp = v_id_emp;
  commit;
  exception when no_data_found then secmgr.sec_ctx.log('Не найдена группа или сотрудник');
  end remove_member_from_group;

--begin
  -- Initialization
--  <Statement>;
end AuthProvider;
/
