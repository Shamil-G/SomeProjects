create or replace package helper as

  /* TODO enter package declarations (types, exceptions, methods etc) here */
function getNameTheme(iid_theme in number) return nvarchar2;
function getNameTypeRegistration(iid_type_registration in number) return nvarchar2;
function getNameEmp(iid_emp in number) return nvarchar2;

procedure getFIOByIIN(iiin in number, ofio out nvarchar2);

function getFIOByIdReg(iid_registration in number)  return nvarchar2;
function getIdPersonByIdReg(iid_registration in number) return simple_integer;

function getCodeBundle(iid_bundle in number) return nvarchar2;
function getNameBundle(iid_bundle in number) return nvarchar2;

function getNameAssignment(iid_assignment in number) return nvarchar2;
function getNameAssignmentByIdTheme(iid_theme in number) return nvarchar2;

function getNameTask(iid_task in number) return nvarchar2;
function getNameTargetBundle(iid_target_bundle in number) return nvarchar2;

function getPeriodForTesting(iid_registration number, iid_theme number) return simple_integer;

function getNameRegion(iid_region in number) return nvarchar2;
function getNameOrganization(iid_organization in number) return nvarchar2;
function getNamePostPerson(iid_post in number) return nvarchar2;
function getNamePositionPerson(iid_position in number) return nvarchar2;
function getNameClassPosition(iid_class in number) return nvarchar2;
function getIdPc(iip_addr in varchar2) return simple_integer;

function getStringAbsentFIO( iid_organization number,
  idate_beg_testing date,
  idate_end_testing date)
return nvarchar2;

function getCompactFIO(iid_person in number) return nvarchar2;
function getFIO(iid_person in number) return nvarchar2;

function getStringResultTest(iid_registration number) return nvarchar2;
function getStringTheme( iid_bundle  number) return nvarchar2;
function getMinPoint(iid_registration number)  return number;

function getGroupFromCode(iid_assignment in number) return varchar2;
function countSuccessQuestion(iid_registration number) return simple_integer;
function countSuccessQuestion(iid_registration number, iid_rule in number) return simple_integer;
function countSuccessQuestionPTBT(iid_registration number) return simple_integer;
function countSuccessQuestionPTBe(iid_registration number) return simple_integer;
function countSuccessQuestionPTECT(iid_registration number) return simple_integer;
function get_language (iid_reg in number)  return varchar2;
procedure fill_super_report;

end helper;
/

create or replace package body helper as

function getNameTheme(iid_theme in number) return nvarchar2
is
res test_operator.tasks.DESCR%type;
begin
  select case when sys_context('sec_ctx','language') in ('kk','kz')
              then t.descr_kaz
              else t.descr
         end
  into res
  from test_operator.tasks t
  where t.ID_THEME=iid_theme;
  return exclude_sharp(res);
  exception when no_data_found then return '';
end getNameTheme;

function getNameTypeRegistration(iid_type_registration in number) return nvarchar2
is
res test_operator.type_registration.DESCR%type;
begin
  select t.descr
  into res
  from test_operator.type_registration t
  where t.id_type_registration=iid_type_registration;
  exception when no_data_found then return '';
end getNameTypeRegistration;

function getNameEmp(iid_emp in number) return nvarchar2
is
  Result nvarchar2(512);
begin
  select e.lastname||' '||substr(e.name,1,1)||'. '||substr(e.middlename,1,1)||'.'
  into Result
  from secmgr.emp e
  where e.id_emp=iid_emp;

  return Result;
  exception when no_data_found then null;
--  ofio:='Кандидат отсуствует в системе';
end getNameEmp;

procedure getFIOByIIN(iiin in number, ofio out nvarchar2)
is
  Result nvarchar2(512);
begin
  select p.lastname||' '||p.name||' '||p.middlename
  into Result
  from test_operator.persons p
  where p.iin=iiin;

  ofio:=Result;
  exception when no_data_found then
--  ofio:='Кандидат отсуствует в системе';
  ofio:='';
end getFIOByIIN;


function getIdPersonByIdReg(iid_registration in number)
return simple_integer
is
  Result simple_integer:=0;
begin
  select r.id_person
  into Result
  from test_operator.registration r
  where r.id_registration=iid_registration;
  return Result;
end;

function getFIOByIdReg(iid_registration in number)
return nvarchar2
is
  Result nvarchar2(512);
begin
  select getFIO(r.id_person)
  into Result
  from test_operator.registration r
  where r.id_registration=iid_registration;
  return Result;
  exception when no_data_found then return 'Имя c id_reg='||iid_registration||' не найдено в таблице Persons';
end;

function getFIO(iid_person in number)
return nvarchar2 is
  Result nvarchar2(512);
begin
  select p.lastname||' '||p.name||' '||p.middlename
  into Result
  from test_operator.persons p
  where p.id_person=iid_person;

  return(Result);
  exception when no_data_found then
  return to_char(iid_person);
end getFIO;

function getNameOrganization(iid_organization in number) return nvarchar2
is
  Result nvarchar2(128);
begin
 select
    case when sys_context('sec_ctx','language') in ('kk','kz')
        then o.name_organization
        else o.name_organization_kaz
    end
 into Result
 from type_organizations o
 where o.id_group_organization=iid_organization;
 return Result;
  exception when no_data_found then
    return to_char(iid_organization);
end getNameOrganization;

function getNamePostPerson(iid_post in number) return nvarchar2
is
  Result nvarchar2(128);
begin
 select
    case when sys_context('sec_ctx','language') in ('kk','kz')
        then r.type_emp
        else r.type_emp_kaz
    end
 into Result
 from post_person r
 where r.id_post=iid_post;
 return Result;
  exception when no_data_found then
    return to_char(iid_post);
end getNamePostPerson;

function getNamePositionPerson(iid_position in number) return nvarchar2
is
  Result nvarchar2(128);
begin
 select
    case when sys_context('sec_ctx','language') in ('kk','kz')
        then e.type_emp
        else e.type_emp_kaz
    end
 into Result
 from position_person e
 where e.id_position=iid_position;
 return Result;
  exception when no_data_found then
    return to_char(iid_position);
end getNamePositionPerson;

function getNameClassPosition(iid_class in number) return nvarchar2
is
  Result nvarchar2(128);
begin
 select
    case when sys_context('sec_ctx','language') in ('kk','kz')
        then e.short_descr
        else e.short_descr_kaz
    end
 into Result
 from class_position e
 where e.id_class=iid_class;
 return Result;
  exception when no_data_found then
    return to_char(iid_class);
end getNameClassPosition;

function getCompactFIO(iid_person in number)
return nvarchar2 is
  Result nvarchar2(256);
begin
  select p.lastname||' '||substr(p.name,1,1)||'. '||substr(p.middlename,1,1)||'.'
  into Result
  from test_operator.persons p
  where p.id_person=iid_person;

  return(Result);
  exception when no_data_found then
  return to_char(iid_person);
end getCompactFIO;

function getStringResultTest(iid_registration number)
return nvarchar2 is
v_result nvarchar2(2048);
begin
v_result:='';
for CUR in  (
SELECT uc1.id_registration,
       uc1.theme_number,
       t1.count_success score,
       uc1.count_success as need_to_success,
       uc1.count_question all_questions
  FROM
  (SELECT  distinct qt.id_registration, qt.id_theme,
         sum( case when rep.correctly='Y' then 1 else 0 end)
         OVER ( PARTITION BY id_theme ) count_success
  FROM  test_operator.replies rep,
        test_operator.questions_for_testing qt
  where rep.id_reply=qt.id_reply
  and   qt.id_registration=iid_registration
  ) t1,
  test_operator.users_bundle_composition uc1
  where uc1.id_registration=t1.id_registration
  and   uc1.id_registration=iid_registration
  and   uc1.id_theme=t1.id_theme
  ORDER BY uc1.theme_number
)
loop
  v_result:=v_result||cur.score ||';';
end loop;
  return(v_result);
end getStringResultTest;

function getStringAbsentFIO( iid_organization number,
  idate_beg_testing date,
  idate_end_testing date)
return nvarchar2 is
v_result nvarchar2(2000);
begin
v_result:='';
for CUR in  ( SELECT test_operator.helper.getCompactFIO(r.id_person) fio
              FROM test_operator.registration r
              where trunc(r.date_testing,'day')>=idate_beg_testing
              and   trunc(r.date_testing,'day')<=idate_end_testing
--              and r.id_organization=iid_organization
              and   r.status in ('Неявка','Готов')
            )
loop
  v_result:=v_result||cur.fio ||',';
  if length(v_result)>1920
  then
    exit;
  end if;
end loop;
  return(v_result);
end getStringAbsentFIO;

function getStringTheme( iid_bundle  number)
return nvarchar2 is
v_result nvarchar2(2048);
begin
v_result:='';
for CUR in
  ( SELECT  case when sys_context('sec_ctx','language') in ('kk','kz')
              then tm.descr_kaz
              else tm.descr
            end  as descr
    FROM  test_operator.bundle gt,
          test_operator.bundle_tasks bt,
          test_operator.tasks tm
    where bt.id_bundle=iid_bundle
    order by bt.theme_number
)
loop
--  v_result:=v_result||cur.theme_number||' '||cur.score ||'/'||cur.need_to_success||';';
  v_result:=v_result||cur.descr ||';';
--  dbms_output.put_line(v_result);
end loop;
--  dbms_output.put_line(v_result);
  return(v_result);
end getStringTheme;


function getCodeBundle(iid_bundle in number) return nvarchar2
is
res nvarchar2(256);
begin
res:='';
select  case when sys_context('sec_ctx','language') in ('kk','kz')
          then o.short_descr||', '||r.short_descr||', '||e.short_descr||', '||c.short_descr
          else o.short_descr||', '||r.short_descr||', '||e.short_descr||', '||c.short_descr
        end
into res
from TEST_OPERATOR.assignment a,
     TEST_OPERATOR.type_organizations o,
     TEST_OPERATOR.post_person r,
     TEST_OPERATOR.position_person e,
     TEST_OPERATOR.M_ASSIGNMENT_BUNDLE m,
     TEST_OPERATOR.class_position c
where m.id_bundle=iid_bundle
and   m.id_assignment=a.id_assignment
and   a.id_group_organization=o.id_group_organization
and   a.id_post=r.id_post
and   a.id_position=e.id_position
and   a.id_class=c.id_class;

return res;
exception when no_data_found then return 'нет данных';
end getCodeBundle;

function getNameAssignment(iid_assignment in number) return nvarchar2
is
res nvarchar2(256);
begin
res:='';
select  case when sys_context('sec_ctx','language') in ('kk','kz')
          then o.name_organization_kaz||', '||r.type_emp_kaz||', '||e.type_emp_kaz||', '||c.short_descr_kaz
          else o.short_descr||', '||r.short_descr||', '||e.short_descr||', '||c.short_descr
        end
--o.short_descr||', '||r.short_descr||', '||e.short_descr||', '||c.short_descr
--select e.short_descr
into res
from TEST_OPERATOR.assignment a,
     TEST_OPERATOR.type_organizations o,
     TEST_OPERATOR.post_person r,
     TEST_OPERATOR.position_person e,
     TEST_OPERATOR.class_position c
where a.id_assignment=iid_assignment
and   a.id_group_organization=o.id_group_organization(+)
and   a.id_post=r.id_post(+)
and   a.id_position=e.id_position(+)
and   a.id_class=c.id_class(+);

return res;
exception when no_data_found then return '';
end getNameAssignment;

function getNameAssignmentByIdTheme(iid_theme in number) return nvarchar2
is
res nvarchar2(256);
begin
res:='';
select  case when sys_context('sec_ctx','language') in ('kk','kz')
          then o.name_organization_kaz||', '||r.type_emp_kaz||', '||e.type_emp_kaz||', '||c.short_descr_kaz
          else o.short_descr||', '||r.short_descr||', '||e.short_descr||', '||c.short_descr
        end
--o.short_descr||', '||r.short_descr||', '||e.short_descr||', '||c.short_descr
--select e.short_descr
into res
from TEST_OPERATOR.tasks t,
     TEST_OPERATOR.assignment a,
     TEST_OPERATOR.type_organizations o,
     TEST_OPERATOR.post_person r,
     TEST_OPERATOR.position_person e,
     TEST_OPERATOR.class_position c
where t.id_theme=iid_theme
and   a.id_assignment=t.id_assignment
and   a.id_group_organization=o.id_group_organization(+)
and   a.id_post=r.id_post(+)
and   a.id_position=e.id_position(+)
and   a.id_class=c.id_class(+);

return res;
exception when no_data_found then return '';
end getNameAssignmentByIdTheme;


function getNameTask(iid_task in number) return nvarchar2
is
res nvarchar2(256);
begin
res:='';
select r.short_descr
into res
from TEST_OPERATOR.tasks r
where r.id_theme=iid_task;

return res;
exception when no_data_found then return '';
end getNameTask;

function getNameTargetBundle(iid_target_bundle in number) return nvarchar2
is
res nvarchar2(256);
begin
res:='';
select tb.descr
into res
from TEST_OPERATOR.target_bundle tb
where tb.id_target_bundle=iid_target_bundle;

return res;
exception when no_data_found then return '';
end getNameTargetBundle;

function getNameBundle(iid_bundle in number) return nvarchar2
is
res nvarchar2(256);
begin
res:='';
select b.descr
into res
from TEST_OPERATOR.bundle b
where b.id_bundle=iid_bundle;

return res;
exception when no_data_found then return 'нет данных';
end getNameBundle;

function getNameRegion(iid_region in number) return nvarchar2
is
res secmgr.region.region_name%type;
begin
res:='';
select
       case when sys_context('sec_ctx','language') in ('kk','kz')
            then r.region_name_kaz
            else r.region_name
       end
into res
from secmgr.region r
where r.id_region=iid_region;
return res;
exception when no_data_found then null;
return res;
end getNameRegion;

function getIdPc(iip_addr in varchar2)
return simple_integer
is
v_id_pc simple_integer:=0;
begin
  select lw.id_pc
  into v_id_pc
  from secmgr.list_workstation lw
  where lw.ip_addr=iip_addr;
  return v_id_pc;
  exception when no_data_found then return 0;
end;

function getMinPoint(iid_registration number)
return number
is
v_min_point number;
begin
    select b.min_point into v_min_point
    from test_operator.bundle b, registration r, M_ASSIGNMENT_BUNDLE m
    where r.id_registration=iid_registration
    and   m.id_assignment=r.id_assignment
    and   m.id_bundle=b.id_bundle;
    return v_min_point;
    exception when no_data_found then return 0;
end;

function getPeriodForTesting(iid_registration number, iid_theme number)
return simple_integer
is
v_period simple_integer:=0;
v_ISGROUP char(1);
v_id_param number;
begin
    select is_groups, period_for_testing
    into v_ISGROUP, v_period
    from test_operator.registration r, bundle b
    where b.id_bundle=r.id_bundle
    and   r.id_registration=iid_registration;

    if v_isgroup='Y' and v_period is not null
      then return v_period*60;
    end if;

    select uc.is_groups, uc.period_for_testing, uc.id_param
    into v_ISGROUP, v_period, v_id_param
    from test_operator.users_bundle_composition uc
    where uc.id_registration=iid_registration
    and     uc.id_theme=iid_theme;

    if v_isgroup='Y' and v_id_param is not null
    then
        select ub.period_for_testing
        into v_period
        from test_operator.users_bundle_config ub
        where ub.id_param=v_id_param
        and   ub.id_registration=iid_registration;
    end if;
    return v_period;
    exception when no_data_found then return 0;
end;

function getGroupFromCode(iid_assignment in number) return varchar2
is
v_code varchar2(32);
begin
select helper.getNameClassPosition(a.id_class)
into v_code
from TEST_OPERATOR.assignment a
where a.id_assignment=iid_assignment;
return v_code;
exception when no_data_found then return '';
end getGroupFromCode;

function countSuccessQuestion(iid_registration number) return simple_integer
is
v_count simple_integer:=0;
begin
  select sum(coalesce(bc.scores,0))
 into v_count
 from test_operator.users_bundle_composition bc
 where bc.id_registration=iid_registration;
 return v_count;
end countSuccessQuestion;

function countSuccessQuestion(iid_registration number, iid_rule in number) return simple_integer
is
v_count simple_integer:=0;
v_like  nvarchar2(8);
begin
--  v_like:='';
  v_like := case  when iid_rule=1 then 'ПТЭ,'
                  when iid_rule=2 then 'ПТБ,'
                  when iid_rule=3 then 'ПТБт,'
            ELSE 'none' end;
  select coalesce(bc.scores,0)
  into   v_count
  from test_operator.users_bundle_composition bc, test_operator.tasks t
  where bc.id_theme=t.id_theme
  and   t.short_descr like v_like||'%'
  and   bc.id_registration=iid_registration;
  return v_count;
  exception when no_data_found then return 0;
end countSuccessQuestion;

function countSuccessQuestionPTECT(iid_registration number) return simple_integer
is
begin
  return countSuccessQuestion(iid_registration, 1);
end countSuccessQuestionPTECT;

function countSuccessQuestionPTBe(iid_registration number) return simple_integer
is
begin
  return countSuccessQuestion(iid_registration, 2);
end countSuccessQuestionPTBe;

function countSuccessQuestionPTBT(iid_registration number) return simple_integer
is
begin
  return countSuccessQuestion(iid_registration, 3);
end countSuccessQuestionPTBT;


function get_language (iid_reg in number)  return varchar2
is
v_lang  test_operator.registration.language%type ;
begin
  if iid_reg is not null then
     begin
        select language into v_lang
        from test_operator.registration r
        where r.id_registration=iid_reg;
        exception when no_data_found then null;
     end;
  end if;
  return coalesce(v_lang,'ru');
end get_language ;

procedure fill_super_report
is
v_id_registration test_operator.registration.id_registration%type;
v_date_testing date;
v_fio nvarchar2(256);
v_region nvarchar2(128);
v_code varchar(20);
v_pte number;
v_ptbe number;
v_ptbt number;
v_score number;
v_min_point number;
v_status nvarchar2(128);
v_language char(2);
v_signature nvarchar2(128);
sql_str_question varchar2(2000);
sql_str_answer varchar2(2000);
order_num      simple_integer:=1;
old_id_registration simple_integer:=0;
begin
  DBMS_OUTPUT.enable;
--/*
  for cur in (select r.id_registration as id_registration,
       r.date_testing as date_testing,
       p.iin,
       helper.getFIO(r.id_person) as fio,
       helper.getNameRegion(r.id_region) as region,
       helper.getCodeBundle(b.id_bundle) as code,
       helper.countSuccessQuestionPTECT(r.id_registration) as pte,
       helper.countSuccessQuestionPTBe(r.id_registration)as ptbe,
       helper.countSuccessQuestionPTBT(r.id_registration) as ptbt,
       helper.countSuccessQuestion(r.id_registration) as score,
       b.min_point as min_point,
       case when substr(r.status,1,10)='Не пройден' then 'Нет'
            when substr(r.status,1,7)='Пройден' then 'Да'
            else '---' end as status,
       r.language as language,
       r.signature as signature
  --into v_id_registration, v_date_testing, v_fio, v_region, v_code, v_pte, v_ptbe, v_ptbt, v_score, v_min_point, v_status, v_language, v_signature
  from  test_operator.registration r, test_operator.bundle b,
        TEST_OPERATOR.persons p, test_operator.m_assignment_bundle m
  where r.id_assignment=m.id_assignment
  and b.id_bundle=m.id_bundle
  and p.id_person=r.id_person
  and r.signature is not null
  and   trunc(r.beg_time_testing,'dd')>=to_date('08.12.2014','dd.mm.yyyy')
  and   trunc(r.end_time_testing,'dd')<=to_date('09.12.2014','dd.mm.yyyy')
  order by r.id_region, r.date_testing, helper.getFIO(r.id_person))
  loop
    insert into test_operator.super_report (id_registration, iin, date_testing, fio, region_name, code, pte_result, ptbe_result,
            ptbt_result, total_score_result, min_point, status, test_language, signature)
    values (cur.id_registration, cur.iin, cur.date_testing, cur.fio, cur.region, cur.code, cur.pte, cur.ptbe, cur.ptbt, cur.score,
            cur.min_point, cur.status, cur.language, cur.signature);
  end loop;
  commit;
--*/
    for cur_question in (select sr.id_registration, qt.order_num_question, q.question, r.reply, r.correctly
            from TEST_OPERATOR.super_report sr,
                 TEST_OPERATOR.questions_for_testing qt,
                 TEST_OPERATOR.questions q,
                 test_operator.replies r
            where sr.id_registration = qt.id_registration
            and   qt.id_question = q.id_question
            and   qt.id_question = r.id_question(+)
            and   qt.id_reply = r.id_reply(+)
            order by sr.id_registration, qt.id_theme, qt.order_num_question)
    loop
      if old_id_registration!=cur_question.id_registration then
         old_id_registration:=cur_question.id_registration;
         order_num:=1;
         commit;
      end if;
      sql_str_question :=  'update test_operator.super_report set '||
                           ' V'||order_num||'='''||cur_question.question||
                           ''', A'||order_num||'='''||cur_question.reply||
                           ''', C'||order_num||'='''|| cur_question.correctly||
                           ''' where id_registration='||cur_question.id_registration;
      execute immediate sql_str_question;
      order_num:=order_num+1;
    end loop;
    commit;

end fill_super_report;

end helper;
/
