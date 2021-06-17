create or replace package registr is

procedure generate_questions(iid_registration number, iid_theme number, icount_questions number);

 -- Public type declarations
function r_new(
  iid_registration in number,
  iid_person in number,
  iid_kind_testing in number,
  icategory in char,
  iid_category_for_position in number,
  iid_organization in number,
  iid_subdivision in number,
  iid_position in number,
  iid_education in number,
  iid_degree in number,
  igov_record_service in number,
  iexperience_in_special in number,
  ilanguage in char,
  idate_testing in date,
  iend_day_testing in date,
  ikey_access in varchar2) return nvarchar2;

procedure r_upd(iid_registration in number,
  iid_education in number,
  iid_degree in number,
  igov_record_service in number,
  iexperience_in_special in number,
  ilanguage in char,
  idate_testing in date,
  iend_day_testing in date,
  ikey_access in varchar2);

function checkUserForTesting(iid_person in number,
         iid_category_for_position in number,
         iid_kind_testing in number,
         idate_testing in date)
         return nvarchar2;
procedure r_del(iid_registration in number);
procedure r_lock(iid_registration in number);
procedure r_unlocks(iid_registration in varchar2);
procedure r_unlock(iid_registration in number);

end registr;
/
create or replace package body registr is

function user_name(iid_person in number) return varchar2
is
str nvarchar2(196);
begin
    str:='';
    if iid_person is not null
    then
       select p.lastname ||' '|| p.name
       into str
       from persons p
       where p.id_person=iid_person;
    end if;
return str;
end user_name;

function kind_testing_name(iid_kind_testing in number) return varchar2
is
str nvarchar2(128);
begin
    str:='';
    if iid_kind_testing is not null
    then
       select k.descr
       into str
       from kind_testing k
       where k.id_kind_testing=iid_kind_testing;
    end if;
return str;
end kind_testing_name;

function getIdBundleTheme( iid_organization in number, 
                           iid_kind_testing in number, 
                           iid_category_for_position in number) 
return number
is
v_id_bundle_theme Number;
begin
  begin
  select gp.id_bundle_theme
  into v_id_bundle_theme
  from groups_tests gp
  where gp.id_organization=iid_organization
  and gp.id_kind_testing=iid_kind_testing
  and gp.id_category_for_position=iid_category_for_position;

  exception when no_data_found then 
    begin
          secmgr.sec_ctx.log('-+- not found groups_tests for v_id_organization: '||iid_organization||
      ', iid_kind_testing: '||iid_kind_testing||
      ', v_id_category_for_position'||iid_category_for_position);
      raise_application_error(-20000,'-+- Не найдена группа тестов для  v_id_organization: '||iid_organization||
      ', iid_kind_testing: '||iid_kind_testing||
      ', v_id_category_for_position'||iid_category_for_position);
    end;

  end;
return v_id_bundle_theme;
end getIdBundleTheme;

-- генерация вопросов
procedure generate_questions(iid_registration number, iid_theme number, icount_questions number)
is
id_num            pls_integer;
random_size       pls_integer;
target_size       pls_integer;
random_number     pls_integer;
order_number      pls_integer;

type id_question_table is table of questions.id_question%type index by pls_integer;
input_array id_question_table;
--str varchar2(1024);
begin
  
  select q.id_question
  bulk collect into input_array
  from questions q
  where q.id_theme=iid_theme
  and   q.active='Y';

  random_size:=input_array.count;

  target_size := icount_questions;
  if target_size>input_array.count
  then
     target_size:=input_array.count;
  end if;
  
  order_number:=0;
--  secmgr.sec_ctx.log('-+- init -+-'||', target_size: '||target_size);
  while order_number<target_size
  loop
    select dbms_random.value(1,random_size) into random_number from dual;
--    secmgr.sec_ctx.log('target_size:'||target_size);
--    secmgr.sec_ctx.log('random_number: '||random_number);
    if input_array.exists(random_number) 
    then
       id_num:=input_array(random_number);
       input_array.delete(random_number);
 
--       str:=str||id_num||' ';
       order_number:=order_number+1;
       insert into secmgr.questions_for_testing( id_registration, id_theme, order_num,
                        id_question, id_reply, time_reply)
       values(iid_registration, iid_theme, order_number, id_num, null, null);
    end if;
  end loop;
--  secmgr.sec_ctx.log(str);
--  secmgr.sec_ctx.log('-+- finish -+-');
end generate_questions;

-- проверка допустимости регистрации
function checkUserForTesting(iid_person in number, 
         iid_category_for_position in number, 
         iid_kind_testing in number,
         idate_testing in date) 
return nvarchar2
is
v_id_equal_category category_position.id_equal_category%type;
v_interval_first    control_registration.interval_first%type;
v_first             registration.beg_time_testing%type;
v_interval_second   control_registration.interval_second%type;
str nvarchar2(256) default '';
begin
  begin
    select cp.id_equal_category 
    into v_id_equal_category
    from category_position cp
    where cp.id_category_for_position=iid_category_for_position;
  exception when no_data_found then return '';
  end;


  if v_id_equal_category is null
  then
    return '';
  end if;

--  secmgr.sec_ctx.log('-+- v_id_equal_category: '||v_id_equal_category||', iid_kind_testing: '||iid_kind_testing);
 
  begin
    select cr.interval_first, cr.interval_second
    into    v_interval_first, v_interval_second 
    from control_registration cr
    where cr.id_equal_category=v_id_equal_category
    and   cr.id_kind_testing=iid_kind_testing;
  exception when no_data_found then return '';
  end;

--  secmgr.sec_ctx.log('-+- v_id_equal_category: '||v_id_equal_category||', iid_kind_testing: '||iid_kind_testing);
 
  for Cur in ( select t.*, rownum from 
                      ( select r.date_testing, 
                               r.beg_time_testing,
                               r.end_day_testing
                        from registration r
                        where r.id_person=iid_person
                        and   r.status!='Неявка'
                        --and   (sysdate-r.date_registration)<360
                        and   r.id_category_for_position 
                              in (  select c.id_category_for_position 
                                    from category_position c
                                    where c.id_equal_category=v_id_equal_category) 
                        order by 1 desc ) t
                where rownum<3)
  loop
--    secmgr.sec_ctx.log('-+- Cur.Date_Testing: '||Cur.Date_Testing);
--    secmgr.sec_ctx.log('-+- v_interval_first: '||v_interval_first);

    if Cur.Rownum=1 
    then 
        if Cur.Beg_Time_Testing is not null
        then
          v_first:=Cur.Beg_Time_Testing;
          if (idate_testing-v_first)<v_interval_first
          then
              str:= 'К тесту не допущен: '||
                    user_name(iid_person)||
                    ', после последнего тестирования прошло всего '||
                    (idate_testing - v_first)||' дней, должно быть: '||
                    v_interval_first;
          end if;
        else
          v_first:=Cur.Date_Testing;
          if  (idate_testing - v_first)<v_interval_first
          then
              str:= 'К тесту не допущен: '||
                    user_name(iid_person)||
                    ', после последнего тестирования прошло всего '||
                    (idate_testing - v_first)||' дней, должно быть: '||
                    v_interval_first;
          end if;
        end if;    
    end if; 
    if Cur.Rownum=2 
    then 
          if (idate_testing-v_first)<v_interval_second
          then
              str:= 'К тесту не допущен: '||
                    user_name(iid_person)||
                    ', после последнего тестирования прошло всего '||
                    (idate_testing - v_first)||' дней, должно быть: '||
                    v_interval_second;
          end if;
    end if; 
  end loop;
  if str is not null
  then
    secmgr.sec_ctx.log(str);
  end if;
  return str;
end checkUserForTesting;

function r_new(
  iid_registration in number,
  iid_person in number,
  iid_kind_testing in number,
  icategory in char,
  iid_category_for_position in number,
  iid_organization in number,
  iid_subdivision in number,
  iid_position in number,
  iid_education in number,
  iid_degree in number,
  igov_record_service in number,
  iexperience_in_special in number,
  ilanguage in char,
  idate_testing in date,
  iend_day_testing in date,
  ikey_access in varchar2)
  return nvarchar2
  is
  v_id_bundle_theme pls_integer;
  v_id_param        pls_integer;
  v_period_testing  pls_integer;
  str               nvarchar2(256);
  v_first_theme     boolean;
begin
  str:=checkUserForTesting(iid_person, iid_category_for_position, iid_kind_testing, idate_testing );
  if (str is not null)
  then
     secmgr.sec_ctx.log( str );
     return str;
  end if;

  insert into registration(id_registration, 
              id_person, 
              category, 
              id_category_for_position,
              id_organization,
              date_registration,
              id_education, id_degree, id_kind_testing,
              gov_record_service, experience_in_special,
              id_emp, 
              id_region,
              date_testing, id_subdivision,
              id_position, status, key_access,
              beg_time_testing, end_time_testing,
              end_day_testing, language)
  values( iid_registration, iid_person, icategory,
          iid_category_for_position,
          iid_organization,
          sysdate,
          iid_education, iid_degree, iid_kind_testing,
          igov_record_service, iexperience_in_special,
          sys_context('SEC_CTX','id_person'),
          sys_context('SEC_CTX','id_region'),
          idate_testing, iid_subdivision,
          iid_position, 'Готов', ikey_access,
          null, null,
          iend_day_testing, 
          case  when ilanguage is null then sys_context('SEC_CTX','language') else ilanguage end  );

      v_id_bundle_theme:=getIdBundleTheme(iid_organization, iid_kind_testing, iid_category_for_position);
      
      insert into testing( id_registration, id_bundle_theme,
                          id_current_theme, beg_time_testing, last_time_access,
                          status_testing)
      values ( iid_registration, 
             v_id_bundle_theme, null, null, null, 'Готов');

      v_id_param:=-1;
      v_first_theme:=true;

      for Cur in ( select * from bundle_composition b
                 where b.id_bundle_theme=v_id_bundle_theme
                 order by b.theme_number)
        loop
           if v_first_theme=true
           then
              update test_operator.testing t
              set    t.id_current_theme=cur.id_theme
              where  t.id_registration=iid_registration;
              v_first_theme:=false;
           end if;
--           secmgr.sec_ctx.log('Cur.id_param: '||Cur.id_param);
           if(Cur.Is_Groups='Y' and Cur.id_param is not null and
              v_id_param!=Cur.id_param)
           then
             v_id_param:=Cur.id_param;
             select period_for_testing
             into v_period_testing
             from bundle_config uc
             where uc.id_param=v_id_param;

--             secmgr.sec_ctx.log('iid_registration: '||iid_registration||', 1 Cur.id_param: '||Cur.id_param||', v_period_testing: '||v_period_testing);
             arm_test_operator.users_bundle_config_new(iid_registration, v_id_param, v_period_testing,0);
           end if;

--           secmgr.sec_ctx.log('iid_registration: '||iid_registration||', 2 Cur.id_param: '||Cur.id_param||', v_period_testing: '||v_period_testing);
          insert into 
          users_bundle_composition( id_registration,
                                    id_theme, 
                                    id_param,
                                    is_groups, order_num, theme_number,
                                    count_question, count_success,
                                    period_for_testing,
                                    used_time, 
                                    status_testing)
           values( iid_registration,
                   Cur.id_theme, 
                   Cur.id_param,
                   Cur.is_groups, 
                   1, 
                   Cur.theme_number,
                   Cur.count_question, 
                   Cur.count_success,
                   case when Cur.Is_Groups='Y' then 0 else Cur.period_for_testing end, 
                   0, 
                   'Готов' );

             generate_questions(iid_registration, Cur.id_theme, Cur.count_question);
          end loop;
        commit;

        return '';
    end r_new;

procedure r_upd(iid_registration in number,
  iid_education in number,
  iid_degree in number,
  igov_record_service in number,
  iexperience_in_special in number,
  ilanguage in char,
  idate_testing in date,
  iend_day_testing in date,
  ikey_access in varchar2)
as
v_status registration.status%type;
begin

  select status into v_status 
  from registration r
  where r.id_registration=iid_registration;

  if v_status in ('Готов')
  then
    update test_operator.registration r
    set  r.id_education=iid_education,
         r.id_degree=iid_degree,
         r.gov_record_service=igov_record_service,
         r.experience_in_special=iexperience_in_special,
         r.id_emp=sys_context('SEC_CTX','id_person'),
         r.date_testing=idate_testing,
         r.key_access=ikey_access,
         r.end_day_testing=iend_day_testing,
         r.language=ilanguage
    where r.id_registration=iid_registration;
  commit;
  end if;
end r_upd;

procedure r_lock(iid_registration in number)
as
str       nvarchar2(128);
begin

  str:='Блокировал '||user_name(sys_context('SEC_CTX','id_person'));
  update registration r
  set r.status=str
  where r.id_registration=iid_registration;
  commit;
end r_lock;

procedure r_unlock(iid_registration in number)
as
begin
  secmgr.sec_ctx.log('-+- 2 iid_registration: '||iid_registration);
  update registration r
  set r.status='Разблокирован Администратором',
      r.id_pc=null
  where r.id_registration=iid_registration;
commit;
end r_unlock;

procedure r_unlocks(iid_registration in varchar2)
as
begin
--  secmgr.sec_ctx.log('-+- 1 iid_registration: '||iid_registration);
  r_unlock(to_number(iid_registration));
end r_unlocks;

procedure r_del(iid_registration in number) as
  begin
    r_lock(iid_registration);
end r_del;
    
end registr;
/
