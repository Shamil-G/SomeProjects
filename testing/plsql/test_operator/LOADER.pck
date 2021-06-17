CREATE OR REPLACE PACKAGE LOADER AS

  /* TODO enter package declarations (types, exceptions, methods etc) here */
  procedure renumberVersion;

  procedure REPLACE_QUESTIONS(table_name in varchar2, lang in varchar);
  procedure  APPEND_QUESTIONS(table_name in varchar2, lang in varchar);

END LOADER;
/

CREATE OR REPLACE PACKAGE BODY LOADER AS

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
procedure renumberVersion
is
begin
  for cur in (select * from TEST_OPERATOR.VERSION_QUESTIONS_OF_THEME)
  loop
--    update TEST_OPERATOR.VERSION_QUESTIONS_OF_THEME qt
--    set qt.language='ru'
--    where qt.id_version=cur.id_version;

    cur.id_version:=seq_id_version.nextval;
    cur.language:='kz';
    insert into TEST_OPERATOR.VERSION_QUESTIONS_OF_THEME values cur;
  end loop;
  --commit;
end renumberVersion;


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
    from test_operator.themes tm where tm.descr=table_name;
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
    from test_operator.themes tm where tm.descr=table_name;
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

END LOADER;
/
