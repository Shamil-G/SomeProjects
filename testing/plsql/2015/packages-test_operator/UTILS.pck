CREATE OR REPLACE PACKAGE UTILS is
  /* TODO enter package declarations (types, exceptions, methods etc) here */
  PROCEDURE deduplicate_questions;
  PROCEDURE LOAD_TASKS_FROM_THEME;
  PROCEDURE load_assignment;
  procedure load_referencies;
  procedure migrate_bundle;
  procedure migrate_registration;
  PROCEDURE analyze_tasks;
  PROCEDURE analyze_bundle;


END UTILS;
/

CREATE OR REPLACE PACKAGE BODY UTILS AS

PROCEDURE deduplicate_questions AS
quest questions.question%type;
BEGIN
  quest:=' ';
  for cur in ( select * from questions q2 order by q2.question )
  loop
      if quest!=cur.question then
         quest:=cur.question;
      else
         delete from questions q3 where q3.id_question=cur.id_question;
      end if;
  end loop;
  <<end_loop>>
  null;
  commit;

END deduplicate_questions;

  procedure migrate_registration AS
  BEGIN
  for cur in ( select * from REGISTRATION)
  loop
    insert into
    test_operator.REGISTRATION (
      ID_REGISTRATION, ID_PERSON, DATE_REGISTRATION, ID_assignment,
      ID_TYPE_REGISTRATION,
      ID_EMP, ID_REGION, ID_PC,
      DATE_TESTING, BEG_TIME_TESTING, END_TIME_TESTING, END_DAY_TESTING,
      LANGUAGE, SIGNATURE, STATUS )
    values(
      cur.ID_REGISTRATION, cur.ID_PERSON, cur.DATE_REGISTRATION, cur.ID_assignment,
      1,
      cur.ID_EMP, cur.ID_REGION, cur.ID_PC,
      cur.DATE_TESTING, cur.BEG_TIME_TESTING, cur.END_TIME_TESTING, cur.END_DAY_TESTING,
      CUR.LANGUAGE, CUR.SIGNATURE, CUR.STATUS );
  end loop;
  commit;
  END migrate_registration;

  procedure migrate_bundle AS
  BEGIN
  for cur in ( select * from bundle)
  loop
    insert into
    test_operator.bundle ( ID_BUNDLE, ID_TARGET_BUNDLE,
                            ACTIVE, COUNT_THEME,
                            MAX_POINT, MIN_POINT, PERIOD_FOR_TESTING )
      values( cur.ID_BUNDLE, 1,
              cur.ACTIVE, cur.COUNT_THEME,
              cur.MAX_POINT, cur.MIN_POINT, cur.PERIOD_FOR_TESTING );
  end loop;
  commit;
  END migrate_bundle;


procedure load_referencies as
begin
--load boss group person
insert into position_person ( id_position, active, short_descr, TYPE_EMP, type_emp_kaz )
values (1, 'Y', 'Руководство', 'Лица, относящиеся к первым руководителям, ответственным за энергохозяйство и безопасность', 'Лица, относящиеся к первым руководителям, ответственным за энергохозяйство и безопасность');

insert into post_person ( id_position, active, short_descr, TYPE_EMP, type_emp_kaz )
values (2, 'Y', 'Специалисты', 'Специалисты', 'Специалисты');

--load electro group person
insert into post_person ( id_post, active, short_descr, TYPE_EMP, type_emp_kaz )
values (1, 'Y', 'Электрики', 'Специалисты', 'Специалисты');

insert into post_person ( id_post, active, short_descr, TYPE_EMP, type_emp_kaz )
values (2, 'Y', 'Электрики', 'Электрики', 'Электрики');

insert into post_person ( id_post, active, short_descr, TYPE_EMP, type_emp_kaz )
values (3, 'Y', 'Электрики', 'Электрики', 'Электрики');

--load rules
insert into tasks ( id_theme, date_creation, active, order_num, short_descr, descr, descr_kaz )
values (1, sysdate, 'Y', 1, 'ПТЭ', 'Правила технической эксплуатации электрических станций и сетей', 'Правила технической эксплуатации электрических станций и сетей');

insert into tasks ( id_theme, date_creation, active, order_num, short_descr, descr, descr_kaz )
values (2, sysdate,'Y', 2, 'ПТБ', 'Правила техники безопасности при эксплуатации электроустановок', 'Правила техники безопасности при эксплуатации электроустановок');

insert into tasks ( id_theme, date_creation, active, order_num, short_descr, descr, descr_kaz )
values (3, sysdate,'Y', 3, 'ПТБт', 'Правила техники безопасности при эксплуатации тепломеханического оборудования электростанций и тепловых сетей', 'Правила техники безопасности при эксплуатации тепломеханического оборудования электростанций и тепловых сетей');


--load type_organization
insert into type_ORGANIZATIONS(id_group_organization, active, short_descr,  name_organization, name_organization_kaz)
values(1, 'Y', 'ТЭЦ', 'Тепловая электростанция', 'Тепловая электростанция');

insert into type_organizations(id_group_organization, active, short_descr,  name_organization, name_organization_kaz)
values(2, 'Y', 'ГРЭС', 'Гидроэлектростанция', 'Гидроэлектростанция');

insert into type_organizations(id_group_organization, active,  short_descr,  name_organization, name_organization_kaz)
values(3, 'Y', 'ГТЭС', 'Газотурбинная электростанция', 'Газотурбинная электростанция');

insert into type_organizations(id_group_organization, active, short_descr,  name_organization, name_organization_kaz)
values(4, 'Y', 'ЭС', 'Электрические сети', 'Электрические сети');

insert into type_organizations(id_group_organization, active, short_descr,  name_organization, name_organization_kaz)
values(5, 'Y', 'ТС', 'Тепловые сети', 'Тепловые сети');

insert into type_organizations(id_group_organization, active, short_descr,  name_organization, name_organization_kaz)
values(6, 'Y', 'ЭСО', 'Энергоснабжающая организация', 'Энергоснабжающая организация');

insert into target_bundle(id_target_bundle, active, descr) values(1, 'Y', 'Для сертификации');
insert into target_bundle(id_target_bundle, active, descr) values(2, 'Y', 'Учебное');

insert into type_registration( id_type_registration, active, interval_success, interval_fail, descr ) values (1, 'Y', 0, 30, 'Первичное тестирование');
insert into type_registration( id_type_registration, active, interval_success, interval_fail, descr ) values (2, 'Y', 365, 30, 'Периодическое тестирование');
insert into type_registration( id_type_registration, active, interval_success, interval_fail, descr ) values (3, 'Y', 0, 30, 'Внеочередное тестирование');

end;

PROCEDURE load_assignment AS
num simple_integer:=1;
begin
  update test_operator.tasks
  set id_assignment='';
  delete from test_operator.assignment;
  commit;

  --execute immediate 'truncate table test_operator.assignment';
  for cOrg in ( select * from type_ORGANIZATIONS )
  loop
      for cRuk in ( select * from post_person )
      loop
          for cEl in ( select * from position_person )
          loop
              for cGRTB in ( select * from class_position )
              loop
		          insert into assignment (id_assignment, id_group_organization, id_class, id_position)
			      values(num, cOrg.id_group_organization, cGRTB.id_class, cEl.id_position);
                  num:=num+1;
              end loop;
          end loop;
      end loop;
  end loop;
  commit;

end load_assignment;

PROCEDURE LOAD_TASKS_FROM_THEME AS
all_content varchar2(32);
simple_content varchar2(32);
pos simple_integer:=0;
BEGIN
  for cur in ( select * from TASKS )
  LOOP
  insert into TASKS( ID_THEME, date_creation, id_assignment, active, order_num, short_descr, descr, descr_kaz)
            values( cur.id_theme, cur.date_creation, cur.id_assignment, 'Y', cur.short_descr, cur.order_num, cur.descr, cur.descr_kaz);
  end loop;
  commit;

END LOAD_TASKS_FROM_THEME;


function getNextParameter(str in varchar2) return varchar2
is
pos simple_integer:=0;
begin
  pos := instr( str, '.', 1, 1 );
  if pos=0 then return str; end if;
  return substr( str, pos+1, length(str)-pos);
end getNextParameter;

function getIdRule(str in varchar2) return simple_integer
is
pos simple_integer:=0;
begin
  pos:=instr(str,'технической эксплуатации электрических станций и сетей ',1,1);
  if pos > 0 then
     return 1;
  end if;
  pos:=instr(str,'техники безопасности при эксплуатации электроустановок',1,1);
  if pos > 0 then
     return 2;
  end if;
  pos:=instr(str,'техники безопасности при эксплуатации тепломеханического оборудования электростанций и тепловых сетей',1,1);
  if pos > 0 then
     return 3;
  end if;
end getIdRule;

function getGrpTB(str in varchar2) return simple_integer
is
begin
  case when substr(str,1,3)='III' then return 3;
       when substr(str,1,2)='II' then return 2;
       when substr(str,1,2)='IV' then return 4;
       when substr(str,1,1)='V' then return 5;
       else return 0;
  end case;
end getGrpTB;

function getIdGroupOrganization(str in varchar2) return simple_integer
is
begin
  case when substr(str,1,3)='II.' then return 4;
       when substr(str,1,4)='III.' then return 5;
       when substr(str,1,2)='I.' then
            begin
              case when substr(str,5,1)='1' then return 1;
                   when substr(str,5,1)='2' then return 2;
                   when substr(str,5,1)='3' then return 3;
                   else return 0;
              end case;
            end;
       else return 0;
  end case;
  return 0;
end getIdGroupOrganization;

function getIdGroupPersons(str in varchar2) return simple_integer
is
begin
         case when substr(str,1,1)='1' then return 1;
              when substr(str,1,1)='2' then return 2;
              else return 0;
         end case;
end getIdGroupPersons;

PROCEDURE analyze_tasks AS
all_content varchar2(32);
simple_content varchar2(32);
pos simple_integer:=0;
vid_group_organization simple_integer:=0;
vid_post_person      simple_integer:=0;
vid_position_person  simple_integer:=0;
vgrp_tb              simple_integer:=0;
vid_assignment       simple_integer:=0;
BEGIN
  for cur in ( select * from tasks )
  loop
    pos:=instr( cur.descr, '#',1,1);
    if pos=0 then
       goto end_loop2;
    end if;
    all_content:=substr(cur.descr,pos+1, length(cur.descr)-pos);
    vid_group_organization:=getIdGroupOrganization(all_content);
    simple_content:=getNextParameter(all_content);
    vid_post_person:=getIdGroupPersons(simple_content);
    pos:=instr(simple_content, '.', -1, 2);
    simple_content:=substr( simple_content, pos+1 );
    vid_position_person:=getIdGroupPersons(simple_content);
    simple_content:=getNextParameter(simple_content);
    vgrp_tb:=getGrpTB(simple_content);
    --id_rgroup_person:=getRgroupPersons(all_content);
    begin
    select a.id_assignment into vid_assignment
    from assignment a
    where a.id_position=vid_position_person
    and   a.id_post=vid_post_person
    and   a.id_group_organization=vid_group_organization;
    end;

    --insert into log(a,b) values(1, all_content||' : '||simple_content||' : id_rgroup='||vid_rgroup_person||' : id_egroup='||vid_egroup_person||' grp_tb='||vgrp_tb||' --> '||vid_assignment);
  <<end_loop2>>
  null;
  end loop;
  commit;

END analyze_tasks;

PROCEDURE analyze_bundle AS
all_content varchar2(32);
simple_content varchar2(32);
pos simple_integer:=0;
vid_group_organization simple_integer:=0;
vid_post_person      simple_integer:=0;
vid_position_person      simple_integer:=0;
vid_assignment         simple_integer:=0;
vid_rule               simple_integer:=0;
BEGIN
  for cur in ( select * from bundle )
  loop
--    all_content:=cur.code_bundle;
    vid_group_organization:=getIdGroupOrganization(all_content);
    simple_content:=getNextParameter(all_content);
    vid_post_person:=getIdGroupPersons(simple_content);
    pos:=instr(simple_content, '.', -1, 2);
    simple_content:=substr( simple_content, pos+1 );
    vid_position_person:=getIdGroupPersons(simple_content);
    simple_content:=getNextParameter(simple_content);
    --id_rgroup_person:=getRgroupPersons(all_content);
    begin
    select a.id_assignment into vid_assignment
    from assignment a
    where a.id_position=vid_position_person
    and   a.id_post=vid_post_person
    and   a.id_group_organization=vid_group_organization;
    exception when no_data_found then goto end_loop2;
    end;


    --insert into log(a,b) values(1, all_content||' : '||simple_content||' : id_rgroup='||vid_rgroup_person||' : id_egroup='||vid_egroup_person||' grp_tb='||vgrp_tb||' --> '||vid_assignment);
  <<end_loop2>>
  null;
  end loop;
  commit;

END analyze_bundle;



END UTILS;
/
