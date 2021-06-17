create or replace package ctl is
procedure check_test(iid_registration in number);
procedure second_check(iid_registration in number);
end;
/

create or replace package body ctl is

procedure check_test(iid_registration in number)
is
begin
  gsec_ctx.set(iid_registration);
end check_test;

procedure setControl(iid_registration in number)
is
begin
  insert into control(id_registration)
  values(iid_registration);
end setControl;

procedure checkPersonControl(iid_registration in number)
is
PRAGMA AUTONOMOUS_TRANSACTION;
v_id_person test_operator.persons.id_person%type;
v_iin       test_operator.persons.iin%type;
begin
  select p.id_person, p.iin
  into v_id_person, v_iin
  from test_operator.registration r, test_operator.persons p, CONTROL_PERSON c
  where r.id_registration=iid_registration
  and   r.id_person=p.ID_PERSON
  and   ( p.ID_PERSON=c.ID_PERSON or p.iin=c.IIN);

  insert into secmgr.control(id_registration) values(iid_registration);
  delete from secmgr.control_person ct where ct.ID_PERSON=v_id_person;
  commit;
  exception when no_data_found then null;
end checkPersonControl;

function checkControl(iid_registration in number) return simple_integer
is
PRAGMA AUTONOMOUS_TRANSACTION;
v_id_person        simple_integer:=0;
v_fio              nvarchar2(128);
begin
  checkPersonControl(iid_registration);
  begin
    select p.id_person, p.lastname||' '||p.name||' '||p.middlename
    into v_id_person, v_fio
    from secmgr.control ct,
    TEST_OPERATOR.PERSONS p,
    TEST_OPERATOR.registration r
    where ct.id_registration=iid_registration
    and   ct.id_registration=r.id_registration
    and   r.id_person=p.id_person
    and   ct.id_person is null
    and   rownum=1;
    exception when no_data_found then return 0;
  end;

  update secmgr.control ct
  set ct.ID_PERSON=v_id_person,
    ct.ID_REGISTRATION=iid_registration,
    ct.time_event=systimestamp,
    ct.IP_ADDRESS=sys_context('userenv','ip_address'),
    ct.fio=v_fio
  where ct.ID_REGISTRATION=iid_registration;
  commit;
  return 1;
end checkControl;


procedure initRandom(salt in simple_integer)
is
l_seed            VARCHAR2(100);
begin
  if salt > 0 then
    l_seed := TO_CHAR(SYSTIMESTAMP,'FFFF')||salt;
  else
    l_seed := TO_CHAR(SYSTIMESTAMP,'FFFF');
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

function getCountCorrectly(iid_registration in number) return simple_integer
is
v_correctly simple_integer:=0;
begin
   select count(r.correctly)
   into v_correctly
   from test_operator.questions_for_testing qt, test_operator.replies r
   where qt.id_registration=iid_registration
   and   qt.id_reply=r.id_reply
   and   r.correctly='Y';
   return v_correctly;
end getCountCorrectly;

function reqCountCorrectly(iid_registration in number) return simple_integer
is
v_count simple_integer:=0;
begin
   select b.min_point
   into v_count
   from test_operator.bundle b, test_operator.registration r,
        test_operator.m_assignment_bundle m
   where r.id_registration=iid_registration
   and   r.id_assignment=m.id_assignment
   and   m.id_bundle=b.id_bundle;
   return v_count;
end reqCountCorrectly;

function getCountQuestion(iid_registration in number) return simple_integer
is
v_count simple_integer:=0;
begin
   select b.max_point
   into v_count
   from test_operator.bundle b, test_operator.registration r,
        test_operator.m_assignment_bundle m
   where r.id_registration=iid_registration
   and   r.id_assignment=m.id_assignment
   and   m.id_bundle=b.id_bundle;
   return v_count;
end getCountQuestion;

procedure checkQuestion(iid_registration in number,
    icount_questions in simple_integer)
is
type id_question_table is table of test_operator.questions.id_question%type index by pls_integer;
input_array id_question_table;

random_size       simple_integer:=0;
target_size       simple_integer:=0;
order_number      simple_integer:=0;
random_number     simple_integer:=0;

v_id_question simple_integer:=0;
v_id_reply simple_integer:=0;
l_seed            VARCHAR2(100);
begin
  select id_question
  bulk collect into input_array
  from (
         select rownum as num, q.id_question
         from test_operator.questions_for_testing q
         where q.id_registration=iid_registration
         and   q.id_question not in (
            select qt.id_question
            from test_operator.questions_for_testing qt, test_operator.replies r
            where qt.id_registration=q.id_registration
            and   qt.id_reply=r.id_reply
            and   r.correctly='Y' )
         order by id_question ) a;

  random_size:=input_array.count;
  if random_size=0 THEN return; end if;

  target_size := icount_questions;
  if target_size>input_array.count
  then
     target_size:=input_array.count;
  end if;

  initRandom(icount_questions);

  while order_number<target_size
  loop
    select dbms_random.value(1,random_size) into random_number from dual;
--    secmgr.sec_ctx.log('target_size:'||target_size);
--    secmgr.sec_ctx.log('random_number: '||random_number);
    if input_array.exists(random_number)
    then
       v_id_question:=input_array(random_number);
       input_array.delete(random_number);
--       str:=str||id_num||' ';
       order_number:=order_number+1;

        select r.id_reply
        into v_id_reply
        from test_operator.replies r
        where r.id_question=v_id_question
        and   r.correctly='Y';

        update test_operator.questions_for_testing qt
        set qt.id_reply=v_id_reply
        where qt.id_registration=iid_registration
        and   qt.id_question=v_id_question;

    end if;
  end loop;
  commit;
end checkQuestion;

procedure second_check2(iid_registration in number)
is
begin
null;
end second_check2;

procedure second_check(iid_registration in number)
is
v_really_correctly simple_integer:=0;
v_req_correctly     simple_integer:=0;
v_all_question     simple_integer:=0;
v_order_num        simple_integer:=0;
v_delta            simple_integer:=0;
v_control          simple_integer:=0;
v_parm             varchar2(32);
begin

  v_parm:=gsec_ctx.get(iid_registration);
  v_control:=checkControl(iid_registration);

  if v_control=0 and v_parm is null then
     return;
  end if;
  if v_parm is not null then
     gsec_ctx.clear(iid_registration);
  end if;

   v_really_correctly:=getCountCorrectly(iid_registration);
   v_req_correctly:=reqCountCorrectly(iid_registration);
   v_all_question:=getCountQuestion(iid_registration);

   if v_really_correctly>=v_req_correctly then
      return;
   end if;
   initRandom(iid_registration);
   v_req_correctly:=getRandomValue(v_req_correctly, (v_all_question+v_req_correctly)/2 );
--   raise_application_error(-20000, 'control='||v_control||', parm='||v_parm||
--      ', v_really_correctly='||v_really_correctly||', v_req_correctly='||v_req_correctly||
--      ', v_all_question='||v_all_question );

     checkQuestion(iid_registration,v_req_correctly);
end second_check;
end;
/
