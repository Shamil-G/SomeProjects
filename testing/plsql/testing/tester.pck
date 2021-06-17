create or replace package tester as

  /* TODO enter package declarations (types, exceptions, methods etc) here */
procedure beginTest(iid_registration in number);
procedure endTheme( iid_registration in number,  oname_theme out varchar2 );
procedure setCurrentTheme( iid_registration in number,  iid_theme in number );

procedure login(ilogin varchar2, 
          ipasswd in varchar2, 
          iip_addr in varchar2, 
          oid_registration out number, 
          oname out varchar2,
          olang out varchar2,
          omess out varchar2);

procedure save_answer(
  idirection in varchar2 default 'N',
  iid_registration in number,
  iid_reply in number,
  oend_theme out char,
  onew_name_theme out varchar2);

procedure getQuestion( iid_registration in number,
                 oorder_num out number,
                 oid_reply  out number,
                 oquestion  out varchar2,
                 oremain_time out number,
                 oused_time   out number);

procedure getInfo(iid_registration in number, 
          okind_testing out varchar2, 
          ocategory     out varchar2,
          oposition     out varchar2,
          oname_organization out varchar2,
          oname_subdivision  out varchar2);

end tester;
/
create or replace package body tester as

procedure beginTest(iid_registration in number)
is
v_beg_time timestamp;
begin
  select r.beg_time_testing
  into v_beg_time
  from test_operator.registration r
  where r.id_registration=iid_registration;
  
  if v_beg_time is null 
  then
    update test_operator.registration r
    set r.beg_time_testing=systimestamp,
        r.status='Идёт тестирование'
    where r.id_registration=iid_registration;

    update test_operator.testing t
    set t.beg_time_testing=systimestamp,
        t.status_testing='Идёт тестирование'
    where t.id_registration=iid_registration;
  end if;
  commit;
end beginTest;

function getIdPc(iip_addr in varchar2, iid_region pls_integer) return number
is
v_id_pc secmgr.list_workstation.id_pc%type;
begin
  select id_pc
  into v_id_pc
  from list_workstation lw
  where lw.ip_addr=iip_addr
  and   lw.id_region=iid_region
  and   lw.active='Y'
  and   lw.type_device='C'; -- Computer
  return v_id_pc;
  exception when no_data_found then return 0;
end getIdPc;

function usedSecond(p1 timestamp, p2 timestamp) return pls_integer
is
used_second pls_integer;
begin
  if ( extract( day from p1) != extract( day from p2) )
  then
    return 0;
  end if;
  used_second:= (extract(hour from p2) - extract(hour from p1))*3600 + 
                 (extract( minute from p2) - extract( minute from p1))*60 +
                  extract( second from p2) - extract( second from p1);
  return used_second;
end usedSecond;

procedure setCurrentTheme( iid_registration in number,  iid_theme in number )
is 
v_id_theme pls_integer;
v_status    varchar2(64);
v_beg_time_testing timestamp;
begin
  select r.status, r.beg_time_testing
  into v_status, v_beg_time_testing
  from test_operator.registration r
  where r.id_registration=iid_registration;
  
  if iid_theme is not null
  then
    update test_operator.testing ts
    set ts.id_current_theme=iid_theme
    where  ts.id_registration=iid_registration;
  else 
    update test_operator.testing ts
    set ts.id_current_theme=iid_theme
    where  ts.id_registration=iid_registration;
  end if;
  commit;
end setCurrentTheme;

function getCurrentTheme(iid_registration in number)
 return number
is
v_id_current_theme  pls_integer;
begin
  select t.id_current_theme
  into    v_id_current_theme
  from test_operator.testing t
  where t.id_registration=iid_registration;
  return v_id_current_theme;
end getCurrentTheme;

function getNameTheme(iid_theme in number)
 return varchar2
is
v_name_theme  nvarchar2(256);
begin
  select case when sys_context('sec_ctx','language') in ('kk','kz') 
              then t.descr_kaz
              else t.descr
         end as name_theme
  into    v_name_theme
  from test_operator.themes t
  where t.id_theme=iid_theme;
  
  return v_name_theme;
end getNameTheme;


procedure nextTheme( iid_registration in number,
                     oend_theme out char,
                     onew_name_theme out varchar2
) 
is 
v_id_current_theme  pls_integer;
v_theme_number      pls_integer;
v_id_theme          pls_integer;
v_id_next_theme     pls_integer;
v_is_group          char;
v_is_next_group     char;
begin
  --Get Current theme
--  SECMGR.sec_ctx.log('nextTheme: iid_registration: '||iid_registration);
  v_id_current_theme:=getCurrentTheme(iid_registration);

  select *
  into v_id_theme, v_id_next_theme, v_is_group, v_is_next_group 
  from (
    select  uc.id_theme, 
            lead(id_theme) over (order by theme_number, is_groups) next_id,
            uc.is_groups,
            lead(is_groups) over (order by theme_number, is_groups) next_is_group
    from  test_operator.users_bundle_composition uc
    where uc.id_registration=iid_registration
    and   uc.status_testing!='Завершён'
  )
  where id_theme=v_id_current_theme;


  if v_is_group='N' or v_is_group!=v_is_next_group or v_id_next_theme is null
  then
    oend_theme:='Y';
  else 
    oend_theme:='N';
  end if;

  if v_id_next_theme is not null
  then
    onew_name_theme:=getNameTheme(v_id_next_theme);
    
    update test_operator.testing t
    set   t.id_current_theme=v_id_next_theme
    where t.id_registration=iid_registration;
    commit;
  end if;
  exception when no_data_found then null;
end nextTheme;

procedure prevTheme( iid_registration in number,
                    oend_theme out char,
                    onew_name_theme out varchar2
) 
is 
v_id_current_theme  pls_integer;
v_theme_number      pls_integer;
v_id_theme          pls_integer;
v_id_next_theme     pls_integer;
v_is_group          char;
v_is_next_group     char;
v_end_theme         char;
begin
  v_id_current_theme:=getCurrentTheme(iid_registration);

  select *
  into v_id_theme, v_id_next_theme, v_is_group, v_is_next_group
  from (
    select  uc.id_theme, 
            lag(id_theme) over (order by theme_number, is_groups) next_id,
            uc.is_groups,
            lag(is_groups) over (order by theme_number, is_groups) next_is_group    
    from  test_operator.users_bundle_composition uc
    where uc.id_registration=iid_registration
    and   uc.status_testing!='Завершён'
  )
  where id_theme=v_id_current_theme;

  if v_is_group='N' or v_is_group!=v_is_next_group or v_id_next_theme is null
  then
    oend_theme:='Y';
  else 
    oend_theme:='N';
  end if;

  if v_id_next_theme is not null
  then
    onew_name_theme:=getNameTheme(v_id_next_theme);

    update test_operator.testing t
    set   t.id_current_theme=v_id_next_theme
    where t.id_registration=iid_registration;
    commit;
  end if;
  exception when no_data_found then null;
end prevTheme;

function calculateResultTheme(iid_registration in number, iid_theme in number)
return pls_integer
is
counter    pls_integer;
begin
  select count(r.correctly)
  into counter
  from  secmgr.questions_for_testing qt,
        test_operator.replies r
  where qt.id_registration=iid_registration
  and   qt.id_theme=iid_theme
  and   qt.id_reply=r.id_reply
  and   r.correctly='Y';
  return counter;
end calculateResultTheme;

procedure calculateResult(iid_registration in number)
is
counter    pls_integer;
is_fail    boolean;
begin
  is_fail:=false;
  counter:=0;
--  SECMGR.sec_ctx.log('calculateResult: id_registration: '||iid_registration);
  for cur in (  select uc.id_theme, uc.count_success 
                from  test_operator.users_bundle_composition uc
                where uc.id_registration=iid_registration
             )
  loop
      counter:=calculateResultTheme(iid_registration, cur.id_theme);
      if counter<cur.count_success
      then
        is_fail:=true;
      end if;
      update test_operator.users_bundle_composition uc
      set    uc.scores=counter
      where   uc.id_registration=iid_registration
      and     uc.id_theme=cur.id_theme;
  end loop;
  if is_fail=true
  then
    update test_operator.registration r
    set     r.status='Не пройден'
    where   r.id_registration=iid_registration;
  else
    update test_operator.registration r
    set     r.status='Пройден'
    where   r.id_registration=iid_registration;
  end if;
  commit;  
end calculateResult;

procedure endTheme( iid_registration in number,  oname_theme out varchar2 )
is 
v_is_group char;
v_id_theme pls_integer;
v_id_next_theme pls_integer;
counter         pls_integer;
begin
  v_id_theme:=getCurrentTheme(iid_registration);
--SECMGR.sec_ctx.log('endTheme: v_id_theme: '||v_id_theme);
  select uc.is_groups
  into   v_is_group
  from    test_operator.users_bundle_composition uc
  where   uc.id_registration=iid_registration
  and     uc.id_theme=v_id_theme;

  if v_is_group='N' then
    update test_operator.users_bundle_composition uc
    set    uc.status_testing='Завершён'
    where   uc.id_registration=iid_registration
    and     uc.id_theme=v_id_theme;
  else 
    update test_operator.users_bundle_composition uc
    set    uc.status_testing='Завершён'
    where   uc.id_registration=iid_registration
    and     v_is_group='Y';
  end if;
  commit;
  SECMGR.sec_ctx.log('endTheme: status changed for v_id_theme: '||v_id_theme);
  begin
    select t.next_id
    into v_id_next_theme
    from (
      select uc.id_theme as next_id
      from  test_operator.users_bundle_composition uc
      where uc.id_registration=iid_registration
      and   uc.status_testing!='Завершён'
      order by uc.theme_number
    ) t
    where rownum=1;
    exception when no_data_found then 
      begin
        SECMGR.sec_ctx.log('endTheme: no_theme after: '||v_id_next_theme);
        oname_theme:='';
        update test_operator.registration r
        set r.end_time_testing=systimestamp
        where r.id_registration=iid_registration;

        update test_operator.testing t
        set   t.status_testing='Тестирование завершено'
        where t.id_registration=iid_registration;

        calculateResult(iid_registration);
        return; 
      end;
  end;
  SECMGR.sec_ctx.log('endTheme: select next theme: '||v_id_next_theme);
  select 
       case when sys_context('sec_ctx','language') in ('kk','kz') 
            then tm.descr_kaz
            else tm.descr
       end as name_theme
  into  oname_theme
  from  test_operator.themes tm
  where tm.id_theme=v_id_next_theme;
--  SECMGR.sec_ctx.log('endTheme: select next name theme');
  update test_operator.testing t
  set t.id_current_theme=v_id_next_theme
  where t.id_registration=iid_registration;
--  SECMGR.sec_ctx.log('endTheme: update testing');
  commit;
end endTheme;

function nextQuestion (
  iid_registration in number,
  iid_theme     in number,
  iorder_num    in number,
  itime_remain  in pls_integer,
  onew_name_theme out varchar2
) return char
is
v_all_question pls_integer;
v_end_theme char;
v_is_group  char;
begin
    v_end_theme:='N';
    select  bc.count_question, bc.is_groups
    into    v_all_question, v_is_group
    from test_operator.users_bundle_composition bc
    where bc.id_registration=iid_registration
    and   bc.id_theme=iid_theme;

--    SECMGR.sec_ctx.log('nextQuestion: v_all_question: '||v_all_question||', order_num: '||iorder_num||', itime_remain: '||itime_remain);
    
    if( v_all_question>iorder_num and itime_remain>0 )
    then
      update test_operator.users_bundle_composition u
      set u.order_num=iorder_num+1
      where u.id_registration=iid_registration
      and u.id_theme=iid_theme;
    else 
      if v_is_group!='Y' or itime_remain=0 then
        v_end_theme:='Y';
      else
        nextTheme(iid_registration,v_end_theme,onew_name_theme);
      end if;
    end if;
--    SECMGR.sec_ctx.log('nextQuestion: v_end_theme: '||v_end_theme);
    return v_end_theme;
end nextQuestion;

function prevQuestion (  
  iid_registration in number,
  iid_theme       in number,
  iorder_num      in number,
  itime_remain    in pls_integer,
  onew_name_theme out varchar2
) return char
is
v_end_theme char;
v_is_group  char;
begin
    v_end_theme:='N'; -- Тему менять не надо
    if iorder_num>1 and itime_remain>0 then
      update test_operator.users_bundle_composition u
      set u.order_num=iorder_num-1
      where u.id_registration=iid_registration
      and u.id_theme=iid_theme;
    else
      if v_is_group!='Y' or itime_remain=0 then
        v_end_theme:='Y';
      else
        prevTheme(iid_registration,v_end_theme,onew_name_theme);
      end if;
    end if;
    return v_end_theme;
end prevQuestion;

-- refactored
procedure recalcUsedTime( 
   iid_registration   IN number,
   v_id_current_theme IN OUT pls_integer,
   v_order_num        IN OUT pls_integer,
   otime_remain       OUT pls_integer
) as
v_is_group    char;
v_used_second pls_integer;
v_used_time   pls_integer;
v_used        pls_integer;
v_id_param    pls_integer;
v_current_time_stamp  timestamp;
v_last_time_access    timestamp;
v_period_for_testing  pls_integer;
begin
  select t.last_time_access, t.id_current_theme
  into v_last_time_access, v_id_current_theme
  from test_operator.testing t
  where t.id_registration = iid_registration
  and rownum=1;
-- Сколько уже использовано времени на вопросы, кроме последнего
  select ub.order_num, ub.is_groups,
         case when ub.is_groups='Y' 
              then ( select bc.used_time
                     from   test_operator.users_bundle_config bc 
                     where bc.id_registration=ub.id_registration
                     and   bc.id_param=ub.id_param )
              else ub.used_time 
         end as used_time, 
         case when ub.is_groups='Y' 
              then ( select bc.period_for_testing
                     from   test_operator.users_bundle_config bc 
                     where bc.id_registration=ub.id_registration
                     and   bc.id_param=ub.id_param )
              else ub.period_for_testing 
         end as period_for_testing, 
         id_param
  into v_order_num, v_is_group, v_used_time, v_period_for_testing, v_id_param
  from TEST_OPERATOR.users_bundle_composition ub
  where ub.id_registration = iid_registration
  and   ub.id_theme=v_id_current_theme;
-- Сколько использовано времени на последний вопрос
  select systimestamp into v_current_time_stamp from dual;
  v_used_second:= usedSecond(v_last_time_access, v_current_time_stamp);
  v_used:=v_used_second+v_used_time;
  if v_used>v_period_for_testing or v_used<0
  then
    v_used:=v_period_for_testing;
  end if;
-- Обновим использованное время
  if v_is_group='N' 
  then
    update TEST_OPERATOR.users_bundle_composition ub
    set ub.used_time=v_used
    where ub.id_registration=iid_registration
    and   ub.id_theme=v_id_current_theme;
  else
    update test_operator.users_bundle_config bc 
    set   bc.used_time=v_used
    where bc.id_registration=iid_registration
    and   bc.id_param=v_id_param;
  end if;
  otime_remain:=v_period_for_testing-v_used;
end;

procedure save_answer
(
  idirection in varchar2 default 'N',
  iid_registration in number,
  iid_reply in number,
  oend_theme out char,
  onew_name_theme out varchar2)
as
v_count_question number(16);
v_count_real_question pls_integer;
v_id_current_theme    pls_integer;
v_order_num           pls_integer;
v_id_param            pls_integer;
v_time_remain         pls_integer;
begin
  if iid_reply is null and idirection is null
  then
    return;
  end if;
  sec_ctx.log('save answer start. idirection: '||idirection||', iid_registration: '||iid_registration);
  recalcUsedTime( iid_registration, v_id_current_theme, v_order_num, v_time_remain );
--  sec_ctx.log('recalcUsedTime executed: '||v_id_current_theme||', v_order_num: '||v_order_num);
-- Сохраняем ответ
  if iid_reply is not null
  then
    update questions_for_testing q
    set q.id_reply=iid_reply
    where q.id_registration=iid_registration
    and q.id_theme=v_id_current_theme
    and q.order_num=v_order_num;
  end if;
  
  if(idirection='N')
  then
    oend_theme:=nextQuestion( iid_registration,  v_id_current_theme, v_order_num, v_time_remain, onew_name_theme );
  end if;

  if(idirection='P')
  then
    oend_theme:=prevQuestion( iid_registration,  v_id_current_theme, v_order_num, v_time_remain, onew_name_theme );
  end if;
  
  update test_operator.testing t
  set t.last_time_access=systimestamp
  where t.id_registration = iid_registration;
  commit;
  sec_ctx.log('save answer end. idirection: '||idirection||', iid_registration: '||iid_registration);
end save_answer;

procedure getQuestion( iid_registration in number,
                 oorder_num out number,
                 oid_reply  out number,
                 oquestion  out varchar2,
                 oremain_time out number,
                 oused_time   out number) 
is
v_period_for_testing number;
v_id_current_theme   number;
v_used_time          number;
v_id_param           number;
v_is_group           char;
begin
select ts.id_current_theme,
       qt.order_num,
       qt.id_reply,
       case when sys_context('sec_ctx','language') in ('kk','kz') 
            then q.question_kaz
            else q.question
       end as question, 
       uc.id_param,
       uc.is_groups, 
       uc.period_for_testing, 
       case when uc.is_groups='Y' 
            then ( select bc.used_time
                   from   test_operator.users_bundle_config bc 
                   where bc.id_registration=uc.id_registration
                   and   bc.id_param=uc.id_param )
            else uc.used_time 
       end as used_time
into  v_id_current_theme, 
      oorder_num, 
      oid_reply, oquestion, 
      v_id_param,
      v_is_group, 
      v_period_for_testing, 
      v_used_time
from test_operator.testing ts,
secmgr.questions_for_testing qt,
test_operator.questions q,
test_operator.users_bundle_composition uc
where uc.id_registration=ts.id_registration
and   uc.id_theme=ts.id_current_theme
and   uc.order_num=qt.order_num
and   uc.id_registration=qt.id_registration
and   qt.id_theme=ts.id_current_theme
and   qt.id_question=q.id_question
and   ts.id_registration=iid_registration;

if v_is_group='N'
then oremain_time:=v_period_for_testing - coalesce(v_used_time,0);
else
  select bc.period_for_testing, bc.used_time
  into v_period_for_testing, 
       v_used_time
  from test_operator.users_bundle_config bc
  where bc.id_registration=iid_registration
  and   bc.id_param=v_id_param;
  
  oremain_time:=v_period_for_testing - coalesce(v_used_time,0);
end if;  

if v_period_for_testing <= coalesce(v_used_time,0)
then 
  oremain_time:=0;
  update test_operator.users_bundle_composition uc
  set    uc.status_testing='Завершён'
  where  uc.id_registration=iid_registration
  and    uc.id_theme=v_id_current_theme;
end if;

update TEST_OPERATOR.testing t
set   t.last_time_access=systimestamp
where t.id_registration=iid_registration;

oused_time:=v_used_time;
exception when no_data_found then null;
end getQuestion;


procedure login( ilogin varchar2, 
                 ipasswd in varchar2, 
                 iip_addr in varchar2, 
                 oid_registration out number, 
                 oname out varchar2,
                 olang out varchar2,
                 omess out varchar2) 
is
v_id_registration TEST_OPERATOR.registration.id_registration%type;
v_passwd          TEST_OPERATOR.registration.KEY_ACCESS%type;
v_id_pc           pls_integer;
v_id_region       pls_integer;
begin
  oid_registration:=0;
  omess:='';
--  select * from test_operator.registration r;
  begin
    select id_registration,  fio, KEY_ACCESS, id_region, lang
    into  v_id_registration, oname, v_passwd, v_id_region, olang
    from (
      select r.id_registration, 
             p.lastname||' '||p.name||' '||p.middlename as fio,
             r.key_access, 
             r.id_region,
             r.language as lang
      from  TEST_OPERATOR.persons p, 
            TEST_OPERATOR.registration r
      where p.id_person=r.id_person
      and   p.iin=ilogin
      and (
        trunc(sysdate) >= trunc(r.date_testing)
        and
        trunc(sysdate) <= trunc(r.end_day_testing)
      )
--      and r.status in ('Готов','Идёт тестирование')
      order by r.date_testing desc
    ) where rownum=1;
  exception when no_data_found then
    omess:='Для '||ilogin||' тестирование не назначено';
    secmgr.sec_ctx.log(omess);
    return;
  end;
  
  sec_ctx.set_language(olang);
  
  if ipasswd!=v_passwd then
    omess:='Для '||ilogin||' введён неверный пароль';
    secmgr.sec_ctx.log(omess);
    return;
  end if;
/*  
  v_id_pc:=getIdPc(iip_addr, v_id_region);
  if v_id_pc>0
  then
    update test_operator.registration r
    set r.status='Тестирование начато',
        r.id_pc=v_id_pc
    where r.id_registration=v_id_registration;
  else
    omess:='Попытка начать тестировния с неразрешённого адреса '||iip_addr;
    secmgr.sec_ctx.log(omess);
    return;
  end if;  
*/  
  commit;

  oid_registration:=v_id_registration;
  exception when no_data_found then return;
end login;

procedure getInfo(iid_registration in number, 
          okind_testing out varchar2, 
          ocategory     out varchar2,
          oposition     out varchar2,
          oname_organization out varchar2,
          oname_subdivision  out varchar2)
is
begin
 select 
       case when sys_context('sec_ctx','language') in ('kk','kz') 
            then ts.descr_kaz
            else ts.descr
       end 
  into okind_testing
 from test_operator.registration r,
      TEST_OPERATOR.kind_testing ts
 where r.id_kind_testing=ts.id_kind_testing
 and   r.id_registration=iid_registration;

 select cp.code_category
 into ocategory
 from test_operator.registration r,
      TEST_OPERATOR.category_position cp
 where r.id_category_for_position=cp.id_category_for_position
 and   r.id_registration=iid_registration;
 
 select 
       case when sys_context('sec_ctx','language') in ('kk','kz') 
            then ps.name_position_kaz
            else ps.name_position
       end 
 into oposition
 from test_operator.registration r,
      TEST_OPERATOR.positions ps
 where r.id_position=ps.id_position
 and   r.id_registration=iid_registration;
 
 select 
       case when sys_context('sec_ctx','language') in ('kk','kz') 
            then o.name_organization_kaz
            else o.name_organization
       end 
 into oname_organization
 from test_operator.registration r,
      TEST_OPERATOR.organizations o
 where r.id_organization=o.id_organization
 and   r.id_registration=iid_registration;
 
 select 
       case when sys_context('sec_ctx','language') in ('kk','kz') 
            then s.name_subdivision_kaz
            else s.name_subdivision
       end 
 into oname_subdivision
 from test_operator.registration r,
      TEST_OPERATOR.subdivisions s
 where r.id_subdivision=s.id_subdivision
 and   r.id_registration=iid_registration;

end getInfo;

end tester;
/
