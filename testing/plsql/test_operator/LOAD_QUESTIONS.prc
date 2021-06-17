create or replace procedure LOAD_QUESTIONS(table_name in varchar2, lang in varchar) AS
v_id_theme    pls_integer;
v_id_version  pls_integer;
v_order_quest pls_integer;
v_id_question_for_answer  pls_integer;
v_id_reply  pls_integer;
v_order_answer pls_integer;
BEGIN
  if lang not in ('kz', 'ru')
  then
    raise_application_error(-20000,'Указан неверный язык: '||lang||chr(10)||chr(7)||'должен быть указан "kz" или "ru"');
  end if;
  begin
    select id_theme, id_version
    into v_id_theme, v_id_version
    from test_operator.themes tm where tm.descr=table_name;
  exception when no_data_found then raise_application_error(-20000,'Тема не найдена');
  end;

  delete from REPLIES r where r.ID_QUESTION in
    ( select id_question from questions q where q.id_theme = v_id_theme and q.language=lang );
  delete from questions q where q.id_theme = v_id_theme and q.language=lang;
  --Load Questions
  for cur in (select * from shamil.ld_questions p where p.id_question is not null )
  LOOP
    v_order_quest:=test_operator.seq_id_question_rus.nextval;
    insert into test_operator.questions (id_question, id_theme, id_version, LANGUAGE, active, order_num_question, question)
    values(v_order_quest, v_id_theme, v_id_version, lang, 'Y', cur.id_question, cur.text);
  end loop;
  commit;
  --Load answers
  for cur in (select * from shamil.ld_questions p where p.id_question is null)
  LOOP
      v_id_reply:=test_operator.seq_id_reply_rus.nextval;
      begin
        select id_question
        into   v_id_question_for_answer
        from test_operator.questions q
        where q.order_num_question=cur.id_answer
        and   q.ID_THEME=v_id_theme
        and   q.language=lang;
        exception when no_data_found then raise_application_error(-20000, 'В `test_operator.questions` для '||chr(10)||
                  'id_theme='||v_id_theme||
                  --', id_question='||cur.id_answer||
                  ' не найден id_question='||cur.id_answer);
      end;

      begin
        select max(order_num_answer) into v_order_answer
        from test_operator.replies r where r.id_question=v_id_question_for_answer;
        exception when no_data_found then v_order_answer:=0;
      end;
      v_order_answer:=v_order_answer+1;
      insert into test_operator.replies r (id_reply, id_question, active, correctly, order_num_answer, reply)
      values (v_id_reply, v_id_question_for_answer, 'Y', case when cur.correctly is null then 'N' else 'Y' end, v_order_answer, cur.text);
  end loop;
  commit;
END LOAD_QUESTIONS;
/
