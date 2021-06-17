create or replace package cop is

  -- Author  : ГУСЕЙНОВ_Ш
  -- Created : 02.11.2020 16:13:15
  -- Purpose : 
  
  -- Public type declarations
  procedure user(uname in nvarchar2, upass out nvarchar2, uactive out nchar);
  procedure new_user(uname in nvarchar2, upass in nvarchar2, imess out nvarchar2);
  procedure new_user2(uname in nvarchar2, upass in nvarchar2, imess out nvarchar2, iid_creator in number);
  procedure login(uname in nvarchar2, upass out nvarchar2, uactive out nchar);
  procedure login(uname in nvarchar2, upass out nvarchar2, iid_user out number);
  
  
  
end cop;
/
create or replace package body cop is

  procedure user(uname in nvarchar2, upass out nvarchar2, uactive out nchar)
  is
  begin
    insert into protocol(event_date, message) values(sysdate, 'get User: '||uname||' : '||upass||' : '||uactive);
    commit;
    select
         u.password, u.active
         into
         upass, uactive
    from users u where u.name=uname;
    exception when no_data_found then upass := '';
  end;

  procedure new_user(uname in nvarchar2, upass in nvarchar2, imess out nvarchar2)
  is
  v_id_user number(9);
  begin
    select max(id_user) into v_id_user from users;
    insert into protocol(event_date, message) values(sysdate, 'New User: '||uname||' : '||upass);
    commit;
    insert into users(id_user, name, password) values(v_id_user+1, uname, upass);
    commit;
    imess:='';
    exception when dup_val_on_index then
      begin
        insert into protocol(event_date, message) values(sysdate, 'New User duplicate user name: '||uname);
        imess:='Такое имя в системе уже существует';
        commit;
      end;
  end;

  function is_admin(iid_user in number) return pls_integer
  as
    v_admin pls_integer default 0;
  begin
    select count(*) into v_admin
    from users u, users_roles ur, roles r
    where u.id_user=iid_user
    and   ur.id_user=iid_user
    and   r.id_role=ur.id_role
    and   r.name='Admin';
    return v_admin;    
  end is_admin;
  
  procedure new_user2(uname in nvarchar2, upass in nvarchar2, imess out nvarchar2, iid_creator in number)
  is
    v_id_user    number(9);
    v_name_creator nvarchar2(64);
  begin
    imess:='';
    select u.name into v_name_creator from users u where u.id_user=iid_creator;
    select max(id_user) into v_id_user from users;
    insert into users(id_user, name, password) values(v_id_user+1, uname, upass);
    insert into protocol(event_date, message) 
           values(sysdate, 'New User: '||uname||', created by: '||v_name_creator);
    commit;
    exception 
      when no_data_found then
        begin
          insert into protocol(event_date, message) values(sysdate, 'Not found iid_creator: '||iid_creator);
          imess:='Mistake '||iid_creator;
          commit;
        end;
      when dup_val_on_index then
      begin
        if is_admin(iid_creator)>0 or 
           v_name_creator=uname
          then
            update users u
            set u.password=upass
            where u.name=uname;
            commit;
            insert into protocol(event_date, message) values(sysdate, 'Update password for user name: '||uname||' by: '||v_name_creator);
            commit;
        else
          insert into protocol(event_date, message) values(sysdate, 'New User duplicate user name: '||uname);
          imess:='Такое имя в системе уже существует';
          commit;
        end if;
      end;
  end;

  procedure login(uname in nvarchar2, upass out nvarchar2, uactive out nchar)
  is
  v_password nvarchar2(512);
  v_active   nchar(1);
  v_id       number(9);
  begin
    insert into protocol(event_date, message) values(CURRENT_TIMESTAMP, 'Login for: '||uname);
    commit;
    select
        u.password, u.active
         into
        v_password, v_active
    from users u where u.name=uname;
    insert into protocol(event_date, message) values(CURRENT_TIMESTAMP, 'Success: '||uname||' : '||v_id ||' : '||v_password||' : '||v_active);
    commit;
    upass:=v_password;
    uactive:=v_active;
    exception when no_data_found then upass := '';
  end;

  procedure login(uname in nvarchar2, upass out nvarchar2, iid_user out number)
  is
  v_password nvarchar2(512);
  v_id       number(9);
  begin
    insert into protocol(event_date, message) values(CURRENT_TIMESTAMP, 'Login for: '||uname);
    commit;
    select
        u.password, u.id_user
         into
        v_password, v_id
    from users u where u.name=uname;
    insert into protocol(event_date, message) values(CURRENT_TIMESTAMP, 'Success: '||uname||' : '||v_id||' : '||v_password);
    commit;
    upass:=v_password;
    iid_user:=v_id;
    exception when no_data_found then upass := '';
  end;

begin
  null;
end cop;
/
