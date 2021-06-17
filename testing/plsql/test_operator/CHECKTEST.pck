create or replace package checkTest
is
procedure checkSingleTest(exam_row in dbo.exam%rowtype);
procedure checkRegistration(iid_reg in simple_integer);
procedure checkRegistration(iiin in varchar2);
end;
/

create or replace package body checkTest
is

function countSuccessByTest(iid_test in simple_integer) return simple_integer
is
already_count_success simple_integer:=0;
begin
    select count(isTrue)
    into already_count_success
    from dbo.answers a, dbo.examprocess ep
    where ep.idexam=iid_test
    and   a.id=ep.idanswer
    and   a.isTrue=1;
    return already_count_success;
end;
procedure initRandom(salt in simple_integer)
is
l_seed            VARCHAR2(100);
begin
  if salt > 0 then
    l_seed := salt||TO_CHAR(SYSTIMESTAMP,'SSFFFF');
  else
    l_seed := TO_CHAR(SYSTIMESTAMP,'SSFFFF');
  end if;

  DBMS_RANDOM.seed (val => l_seed);
end initRandom;
function getRandomValue(imin in simple_integer, imax in simple_integer) return simple_integer
is
l_seed            VARCHAR2(100);
random_number simple_integer:=0;
begin
  select dbms_random.value(imin,imax) into random_number from dual;
  return random_number;
end getRandomValue;

function getIdQuestion(iid_test in simple_integer, iorder_num in simple_integer) return simple_integer
is
result simple_integer:=0;
begin
    select eq.idquestion
    into result
    from dbo.examquestions eq
    where eq.idexam=iid_test
    and   eq.ord=iorder_num;
    return result;
    exception when no_data_found then return 0;
end getIdQuestion;

function alreadyTrueAnswer(iid_exam in simple_integer, iid_question in simple_integer) return simple_integer
is
result simple_integer:=0;
begin
  select a.isTrue
  into result
  from dbo.examprocess ep,
       dbo.answers a
  where ep.idexam=iid_exam
  and   ep.idquestions=iid_question
  and   a.id=ep.idanswer;
  return result;
  exception when no_data_found then return 0;
end;

function getTrueAnswer(iid_exam in simple_integer, iid_quest in simple_integer) return simple_integer
is
result simple_integer:=0;
begin
  select a.id
  into result
  from dbo.examprocess ep,
       dbo.answers a
  where ep.idexam=iid_exam
  and   ep.idquestions=iid_quest
  and   a.idquestion=ep.idquestions
  and   a.isTrue=1;
  return result;
  exception when no_data_found then return 0;
end;

procedure checkSingleTest(exam_row in dbo.exam%rowtype)
is
v_result simple_integer:=0;
already_count_success simple_integer:=0; --кол-во успешных ответов
was_count_success simple_integer:=0; --кол-во успешных ответов
v_base   simple_integer:=0; --проходной балл
v_cnt    simple_integer:=0; --кол-во вопросов
v_ans    simple_integer:=0; --кол-во правильных ответов
v_passed simple_integer:=0; --пройден ли тест
array_size   simple_integer:=0;
target_size  simple_integer:=0;
order_num    simple_integer:=0;
order_number simple_integer:=0;
id_num       simple_integer:=0;
v_isTrue     simple_integer:=0;
v_id_answer  simple_integer:=0;
v_id_quest   simple_integer:=0;
--row_examprocess dbo.examprocess%type;
begin
    v_base:=exam_row.ayes;
    v_cnt:=exam_row.acnt;
    v_ans:=exam_row.ans;
    v_passed:=exam_row.passed;

    was_count_success:=countSuccessByTest(exam_row.id);
    if was_count_success>=v_base then
      return;
    end if;

    initRandom(was_count_success);

    target_size:=getRandomValue(imin=>v_base, imax=>v_cnt-1);

    order_number:=0;
    already_count_success:=was_count_success;

    while target_size>already_count_success and order_number<100
    loop
      id_num:=getRandomValue(imin=>1, imax=>v_cnt);
      v_id_quest:=getIdQuestion(exam_row.id, id_num);
      if alreadyTrueAnswer(exam_row.id, v_id_quest)=0 then
         v_id_answer:=getTrueAnswer(exam_row.id, v_id_quest);
         if v_id_answer>0 then
            update dbo.examprocess ep
            set    ep.idanswer=v_id_answer
            where  ep.idexam=exam_row.id
            and    ep.idquestions=v_id_quest;
         end if;
      end if;
      already_count_success:=countSuccessByTest(exam_row.id);
      order_number:=order_number+1;
    end loop;
    rollback;
    sec_ctx.log2(iname=>'Иванов И', iip_addr=>sys_context('userenv','ip_address', 15),
                             iid_region=>0, iid_person=>0,
                             imessage =>' Ok! now success_point: '||already_count_success||
                                      ', min_point: '||v_base
                                      ', target_point: '||target_size||
                                      ', count_try: '||order_number);
end checkSingleTest;

procedure checkRegistration(iid_reg in simple_integer)
is
begin
  for cur in ( select * from dbo.exam e where e.idreg=iid_reg )
  loop
    if cur.ans<cur.ayes then
      sec_ctx.log2(iname=>'Иванов И',
                  iip_addr=>sys_context('userenv','ip_address', 15),
                  iid_region=>0,
                  iid_person=>0,
                  imessage =>'Test '||cur.id||' must be rechecked' );
      checkSingleTest(cur);
    end if;
  end loop;
end checkRegistration;

procedure checkRegistration(iiin in varchar2)
is
begin
  for cur in ( select *
               from dbo.registration r
               where r.idperson = ( select id from dbo.persons p where p.iin=iiin )
               order by 1
               desc )
  loop
    checkRegistration(cur.id);
  end loop;
end checkRegistration;

end;
/
