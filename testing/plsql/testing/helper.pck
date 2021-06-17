create or replace package helper as

  /* TODO enter package declarations (types, exceptions, methods etc) here */ 
function getNameOrganization(iid_organization in number) return nvarchar2;
function getCodeCategory(iid_category_for_position in number) return nvarchar2;
function getNameDegree(iid_degree in number) return nvarchar2;
function getNational(iid_national in number) return nvarchar2;
function getNameRegion(iid_region in number) return nvarchar2;
function getNameEducation(iid_education in number) return nvarchar2;
function getKindTesting(iid_kind_testing in number) return nvarchar2;
function getNamePosition(iid_position in number) return nvarchar2;

function getStringAbsentFIO( iid_organization number, 
  idate_beg_testing date,
  idate_end_testing date) 
return nvarchar2;

function getCompactFIO(iid_person in number) return nvarchar2;
function getFIO(iid_person in number) return nvarchar2;

function getStringResultTest(iid_registration number) return nvarchar2;
function getStringTheme( iid_organization number, 
         iid_kind_testing number, 
         iid_category_for_position  number) return nvarchar2;


end helper;
/
create or replace package body helper as

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
        secmgr.questions_for_testing qt 
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
              where r.id_organization=iid_organization
              and   trunc(r.date_testing,'day')>=idate_beg_testing
              and   trunc(r.date_testing,'day')<=idate_end_testing
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

function getStringTheme( iid_organization number, 
         iid_kind_testing number, 
         iid_category_for_position  number) 
return nvarchar2 is
v_result nvarchar2(2048);
begin
v_result:='';
for CUR in  
  ( SELECT  tm.descr
    FROM  test_operator.groups_tests gt,
          test_operator.bundle_composition bc,
          test_operator.themes tm
    where gt.active='Y'
    and   bc.id_bundle_theme=gt.id_bundle_theme
    and   bc.id_theme=tm.id_theme
    and   gt.id_organization=iid_organization
    and   gt.id_kind_testing=iid_kind_testing
    and   gt.id_category_for_position=iid_category_for_position
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

function getNameOrganization(iid_organization in number) return nvarchar2
is
res TEST_OPERATOR.organizations.name_organization%type;
begin
res:='';
select 
       case when sys_context('sec_ctx','language') in ('kk','kz') 
            then o.name_organization_kaz
            else o.name_organization
       end 
into res       
from TEST_OPERATOR.organizations o
where o.id_organization=iid_organization;
return res;
exception when no_data_found then null;
end getNameOrganization;

function getCodeCategory(iid_category_for_position in number) return nvarchar2
is
res TEST_OPERATOR.category_position.code_category%type;
begin
res:='';
select code_category
into res       
from TEST_OPERATOR.category_position kp
where kp.id_category_for_position=iid_category_for_position;
return res;
exception when no_data_found then null;
end getCodeCategory;

function getNameDegree(iid_degree in number) return nvarchar2
is
res test_operator.degrees.name_degree%type;
begin
res:='';
select 
       case when sys_context('sec_ctx','language') in ('kk','kz') 
            then d.name_degree_kaz
            else d.name_degree
       end 
into res       
from TEST_OPERATOR.degrees d
where d.id_degree=iid_degree;
return res;
exception when no_data_found then null;
return res;
end getNameDegree;

function getNational(iid_national in number) return nvarchar2
is
res test_operator.nationals.national%type;
begin
res:='';
select 
       case when sys_context('sec_ctx','language') in ('kk','kz') 
            then n.national_kaz
            else n.national
       end 
into res       
from TEST_OPERATOR.nationals n
where n.id_national=iid_national;
return res;
exception when no_data_found then null;
return res;
end getNational;

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

function getNameEducation(iid_education in number) return nvarchar2
is
res test_operator.educations.education%type;
begin
res:='';
select 
       case when sys_context('sec_ctx','language') in ('kk','kz') 
            then e.education_kaz
            else e.education
       end 
into res       
from test_operator.educations e
where e.id_education=iid_education;
return res;
exception when no_data_found then null;
return res;
end getNameEducation;

function getKindTesting(iid_kind_testing in number) return nvarchar2
is
res test_operator.kind_testing.descr%type;
begin
res:='';
select 
       case when sys_context('sec_ctx','language') in ('kk','kz') 
            then kt.descr_kaz
            else kt.descr
       end 
into res       
from test_operator.kind_testing kt
where kt.id_kind_testing=iid_kind_testing;
return res;
exception when no_data_found then null;
return res;
end getKindTesting;

function getNamePosition(iid_position in number) return nvarchar2
is
res test_operator.positions.name_position%type;
begin
res:='';
select 
       case when sys_context('sec_ctx','language') in ('kk','kz') 
            then ps.name_position_kaz
            else ps.name_position
       end 
into res       
from test_operator.positions ps
where ps.id_position=iid_position;
return res;
exception when no_data_found then null;
return res;
end getNamePosition;

end helper;
/
