create or replace package helper as

  /* TODO enter package declarations (types, exceptions, methods etc) here */
function getNameTheme(iid_theme in number) return nvarchar2;
function getNameEmp(iid_emp in number) return nvarchar2;

procedure getFIOByIIN(iiin in number, ofio out nvarchar2);

function getFIOByIdReg(iid_registration in number)  return nvarchar2;
function getIdPersonByIdReg(iid_registration in number) return simple_integer;

function getCodeBundle(iid_bundle in number) return nvarchar2;
function getNameBundle(iid_bundle in number) return nvarchar2;
function getPeriodForTesting(iid_registration number, iid_theme number) return simple_integer;

function getNameRegion(iid_region in number) return nvarchar2;
function getNameOrganization(iid_organazation in number) return nvarchar2;
function getIdPc(iip_addr in varchar2) return simple_integer;

function getStringAbsentFIO( iid_organization number,
  idate_beg_testing date,
  idate_end_testing date)
return nvarchar2;

function getCompactFIO(iid_person in number) return nvarchar2;
function getFIO(iid_person in number) return nvarchar2;

function getStringResultTest(iid_registration number) return nvarchar2;
function getStringTheme( iid_category  number) return nvarchar2;
function getMinPoint(iid_registration number)  return number;

function getGroupFromCode(iid_bundle number) return varchar2;
function countSuccessQuestion(iid_registration number) return simple_integer;
function countSuccessQuestionPTBT(iid_registration number) return simple_integer;
function countSuccessQuestionPTBe(iid_registration number) return simple_integer;
function countSuccessQuestionPTECT(iid_registration number) return simple_integer;
function get_language (iid_reg in number)  return varchar2;


end helper;
/

create or replace package body helper as

function getNameTheme(iid_theme in number) return nvarchar2
is
res test_operator.THEMES.DESCR%type;
begin
  select case when sys_context('sec_ctx','language') in ('kk','kz')
              then t.descr_kaz
              else t.descr
         end
  into res
  from test_operator.themes t
  where t.ID_THEME=iid_theme;
  return exclude_sharp(res);
  exception when no_data_found then return '';
  commit;
end getNameTheme;

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

function getNameOrganization(iid_organazation in number) return nvarchar2
is
begin
 return '';
end;

function getCompactFIO(iid_person in number)
return nvarchar2 is
  Result nvarchar2(512);
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

function getStringTheme( iid_category  number)
return nvarchar2 is
v_result nvarchar2(2048);
begin
v_result:='';
for CUR in
  ( SELECT  tm.descr
    FROM  test_operator.bundle gt,
          test_operator.bundle_theme bc,
          test_operator.themes tm
    where gt.active='Y'
    and   gt.id_bundle=bc.id_bundle
    and   bc.id_theme=tm.id_theme
    order by bc.theme_number
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
res test_operator.bundle.code_bundle%type;
begin
res:='';
select kp.code_bundle
into res
from TEST_OPERATOR.bundle kp
where kp.id_bundle=iid_bundle;
return res;
exception when no_data_found then null;
end getCodeBundle;

function getNameBundle(iid_bundle in number) return nvarchar2
is
res test_operator.bundle.name_theme_bundle%type;
begin
res:='';
select kp.name_theme_bundle
into res
from TEST_OPERATOR.bundle kp
where kp.id_bundle=iid_bundle;
return res;
exception when no_data_found then null;
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
    from test_operator.bundle b, registration r
    where b.id_bundle=r.id_bundle
    and     r.id_registration=iid_registration;
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

function getGroupFromCode(iid_bundle number) return varchar2
is
pos simple_integer:=0;
v_code test_operator.bundle.code_bundle%type;
begin
 v_code:=substr(helper.getCodeBundle(iid_bundle), instr(helper.getCodeBundle(iid_bundle),'.',1,3)+1);
 pos:=instr(v_code,'.',1,1);
 while(pos>0)
 loop
    v_code:=substr(v_code,pos+1);
    pos:=instr(v_code,'.',1,1);
 end loop;
 return v_code;
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
function countSuccessQuestionPTBT(iid_registration number) return simple_integer
is
v_count simple_integer:=0;
begin
  select coalesce(bc.scores,0)
  into   v_count
  from test_operator.users_bundle_composition bc, test_operator.themes t
  where bc.id_theme=t.id_theme
  and   bc.id_registration=iid_registration
  and   instr( nvl(t.descr,'1'),'тепломехан',1,1)>0;
  return v_count;
  exception when no_data_found then return 0;
end countSuccessQuestionPTBT;
function countSuccessQuestionPTBe(iid_registration number) return simple_integer
is
v_count simple_integer:=0;
begin
  select coalesce(bc.scores,0)
  into   v_count
  from test_operator.users_bundle_composition bc, test_operator.themes t
  where bc.id_theme=t.id_theme
  and   bc.id_registration=iid_registration
  and   instr( nvl(t.descr,'1'),'электроустановок',1,1)>0;
  return v_count;
  exception when no_data_found then return 0;
end countSuccessQuestionPTBe;
function countSuccessQuestionPTECT(iid_registration number) return simple_integer
is
v_count simple_integer:=0;
begin
  select coalesce(bc.scores,0)
  into   v_count
  from test_operator.users_bundle_composition bc, test_operator.themes t
  where bc.id_theme=t.id_theme
  and   bc.id_registration=iid_registration
  and   instr( nvl(t.descr,'1'),'электрических станций',1,1)>0;
  return v_count;
  exception when no_data_found then return 0;
end countSuccessQuestionPTECT;

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

end helper;
/
