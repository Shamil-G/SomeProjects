CREATE OR REPLACE PACKAGE LOADER AS

  /* TODO enter package declarations (types, exceptions, methods etc) here */

  procedure REPLACE_QUESTIONS(table_name in varchar2, lang in varchar);
  procedure  APPEND_QUESTIONS(table_name in varchar2, lang in varchar);
  procedure  ADD_QUESTIONS(table_name in varchar2, lang in varchar);
  procedure  ADD_ASSIGNMENT(table_name in varchar2, lang in varchar);


END LOADER;
/

CREATE OR REPLACE PACKAGE BODY LOADER AS

/*
procedure migrate_registration is
begin
  for cur  in  ( select * from reg_2013 r order by r.date_registration)
  loop
    insert into registration (id_registration, id_person, date_registration, id_assignment, id_bundle,
          id_type_registration, id_emp, id_region,
          id_pc, date_testing, beg_time_testing, end_time_testing,
          end_day_testing, language, signature, status
          )
    values(cur.id_registration, cur.id_person,
           cur.date_registration, cur.id_assignment, cur.id_bundle,
           cur.id_type_registration, cur.id_emp, cur.id_region,
           cur.id_pc, cur.date_testing, cur.beg_time_testing, cur.end_time_testing,
           cur.end_day_testing, cur.language, cur.signature, cur.status
           );
  end loop;
  commit;
end migrate_registration;
*/

function incrementVersionQuestions(iid_theme in number, ilang in varchar)
return simple_integer
is
v_version_number simple_integer:=0;
begin
  begin
    select version_number
    into v_version_number
    from test_operator.version_questions vt
    where vt.id_theme=iid_theme
    and   vt.language=ilang
    and   vt.selected='Y';

    update test_operator.version_questions vt
    set vt.selected='N'
    where vt.id_theme=iid_theme
    and   vt.language=ilang
    and   vt.version_number=v_version_number
    and   vt.selected='Y';
    exception when no_data_found then v_version_number:=0;
  end;
    v_version_number:=v_version_number+1;
    insert into test_operator.version_questions (id_theme, language,
           version_number, selected, date_registration, ip_addr, name)
    values (iid_theme, ilang, v_version_number, 'Y', sysdate,
           SYS_CONTEXT ('USERENV', 'IP_ADDRESS'),
           SYS_CONTEXT ('USERENV', 'SESSION_USER') );

    return v_version_number;
end;

procedure REPLACE_QUESTIONS(table_name in varchar2, lang in varchar) AS
 v_id_theme    pls_integer;
 v_order_quest pls_integer;
 v_id_question_for_answer  pls_integer;
 v_id_reply  pls_integer;
 v_last_id_quest pls_integer;
 v_last_id_reply simple_integer:=0;
 v_order_answer simple_integer:=0;
 v_version_number  simple_integer:=0;
 v_last_order_num_quest simple_integer:=0;
 BEGIN
  if lang not in ('kz', 'ru')
  then
    raise_application_error(-20000,'Указан неверный язык: '||lang||chr(10)||chr(7)||'должен быть указан "kz" или "ru"');
  end if;
  begin
    select id_theme
    into v_id_theme
    from test_operator.tasks tm where tm.descr=table_name;
  exception when no_data_found then raise_application_error(-20000,'Тема не найдена');
  end;

  v_version_number:=incrementVersionQuestions(v_id_theme, lang);

  for cur in (select * from adil.ld_questions p where p.id_question is not null order by 1 )
  LOOP
    v_last_order_num_quest:=v_last_order_num_quest+1;
    v_last_id_quest := test_operator.seq_id_question_rus.nextval;

    insert into test_operator.questions (id_question, id_theme, version_number, LANGUAGE, active, order_num_question, question)
    values(v_last_id_quest, v_id_theme, v_version_number, lang, 'Y', v_last_order_num_quest, cur.text);

    v_order_answer:=1;

    for cur2 in (select * from adil.ld_questions p where p.id_answer=cur.id_question order by 1)
    LOOP
        v_last_id_reply := test_operator.seq_id_reply_rus.nextval;

        insert into test_operator.replies r (id_reply, id_question, active, correctly, order_num_answer, reply)
        values (v_last_id_reply, v_last_id_quest, 'Y', case when cur2.correctly is null then 'N' else 'Y' end, v_order_answer, cur2.text);

        v_order_answer:=v_order_answer+1;
    end loop;

  end loop;

  commit;
  END REPLACE_QUESTIONS;


procedure APPEND_QUESTIONS(table_name in varchar2, lang in varchar) AS
    v_id_theme    pls_integer;
    v_version_number  simple_integer:=0;
    v_order_quest pls_integer;
    v_last_id_quest pls_integer;
    v_last_order_num_quest pls_integer;
    v_last_id_reply pls_integer;
    v_id_question_for_answer  pls_integer;
    v_id_reply  pls_integer;
    v_order_answer pls_integer;
    v_cur_id_quest pls_integer;
  BEGIN
  if lang not in ('kz', 'ru')
  then
    raise_application_error(-20000,'Указан неверный язык: '||lang||chr(10)||chr(7)||'должен быть указан "kz" или "ru"');
  end if;

  begin
    select id_theme
    into v_id_theme
    from test_operator.tasks tm where tm.descr=table_name;
  exception when no_data_found then raise_application_error(-20000,'Тема не найдена');
  end;

  begin
    select version_number
    into v_version_number
    from test_operator.version_questions vt
    where vt.id_theme=v_id_theme
    and   vt.language=lang
    and   vt.selected='Y';
  exception when no_data_found then raise_application_error(-20000,'Версия не найдена');
  end;

  --delete from REPLIES r where r.ID_QUESTION in
  --  ( select id_question from questions q where q.id_theme = v_id_theme and q.language=lang and q.id_version=v_id_version);
  --delete from questions q where q.id_theme = v_id_theme and q.language=lang and q.id_version=v_id_version;

  select nvl(max(order_num_question),0)+1 into v_last_order_num_quest
  from test_operator.questions q
  where q.id_theme=v_id_theme
  and   q.language=lang;

  for cur in (select * from adil.ld_questions p where p.id_question is not null order by 1 )
  LOOP
    v_last_id_quest := test_operator.seq_id_question_rus.nextval;

    insert into test_operator.questions (id_question, id_theme, version_number, LANGUAGE, active, order_num_question, question)
    values(v_last_id_quest, v_id_theme, v_version_number, lang, 'Y', v_last_order_num_quest, cur.text);

    v_order_answer:=1;

    for cur2 in (select * from adil.ld_questions p where p.id_answer=cur.id_question order by 1)
    LOOP
        v_last_id_reply := test_operator.seq_id_reply_rus.nextval;

        insert into test_operator.replies r (id_reply, id_question, active, correctly, order_num_answer, reply)
        values (v_last_id_reply, v_last_id_quest, 'Y', case when cur2.correctly is null then 'N' else 'Y' end, v_order_answer, cur2.text);

        v_order_answer:=v_order_answer+1;
    end loop;

    v_last_order_num_quest:=v_last_order_num_quest+1;
  end loop;

  commit;
  END APPEND_QUESTIONS;








procedure ADD_QUESTIONS(table_name in varchar2, lang in varchar) AS
    v_id_theme    pls_integer;
    v_version_number  simple_integer:=0;
    v_order_quest pls_integer;
    v_last_id_quest pls_integer;
    v_last_order_num_quest pls_integer;
    v_last_id_reply pls_integer;
    v_id_question_for_answer  pls_integer;
    v_id_reply  pls_integer;
    v_order_answer pls_integer;
    v_cur_id_quest pls_integer;
  BEGIN

  v_last_order_num_quest:=1;
  for cur in (select * from test_operator.questions p where p.id_theme=112 and language='ru' )
  LOOP
    v_last_id_quest := test_operator.seq_id_question_rus.nextval;

    insert into test_operator.questions (id_question, id_theme, version_number, LANGUAGE, active, order_num_question, question)
    values(v_last_id_quest, '157', 1, 'ru', 'Y', v_last_order_num_quest, cur.question);

    v_order_answer:=1;

    for cur2 in (select * from test_operator.replies r where r.id_question=cur.id_question order by 1)
    LOOP
        v_last_id_reply := test_operator.seq_id_reply_rus.nextval;

        insert into test_operator.replies r (id_reply, id_question, active, correctly, order_num_answer, reply)
        values (v_last_id_reply, v_last_id_quest, 'Y', cur2.correctly, v_order_answer, cur2.reply);

        v_order_answer:=v_order_answer+1;
    end loop;

    v_last_order_num_quest:=v_last_order_num_quest+1;
  end loop;

  --commit;
  END ADD_QUESTIONS;




procedure ADD_ASSIGNMENT(table_name in varchar2, lang in varchar) AS
    v_id_theme    pls_integer;
    v_version_number  simple_integer:=0;
    v_order_quest pls_integer;
    v_last_id_quest pls_integer;
    v_last_order_num_quest pls_integer;
    v_last_id_reply pls_integer;
    v_id_question_for_answer  pls_integer;
    v_id_reply  pls_integer;
    v_order_answer pls_integer;
    v_cur_id_quest pls_integer;
  BEGIN

  for cur in (select * from test_operator.questions p where p.id_theme=157 and language='ru' )
  LOOP

    insert into test_operator.m_assignment_questions (id_question, id_assignment)
    values(cur.id_question, 2);

  end loop;

  --commit;
  END ADD_ASSIGNMENT;



END LOADER;
/
