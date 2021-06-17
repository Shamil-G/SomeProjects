create or replace package ctl is
procedure check_test(iid_registration in number);
procedure second_check(iid_registration in number);
end;
/

create or replace package body ctl is

procedure check_test(iid_registration in number)
is
begin
  gsec_ctx.set(to_char(iid_registration),'ctl');
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
   from test_operator.bundle b, test_operator.registration r
   where r.id_registration=iid_registration
   and   r.id_bundle=b.id_bundle;
   return v_count;
end reqCountCorrectly;

function getCountQuestion(iid_registration in number) return simple_integer
is
v_count simple_integer:=0;
begin
   select b.max_point
   into v_count
   from test_operator.bundle b, test_operator.registration r
   where r.id_registration=iid_registration
   and   r.id_bundle=b.id_bundle;
   return v_count;
end getCountQuestion;

procedure checkQuestion(iid_registration in number, iorder_num in number)
is
v_id_question simple_integer:=0;
v_id_reply simple_integer:=0;
begin
  select id_question
  into v_id_question
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
         order by id_question ) a
  where a.num=iorder_num;

  select r.id_reply
  into v_id_reply
  from test_operator.replies r
  where r.id_question=v_id_question
  and   r.correctly='Y';

  update test_operator.questions_for_testing qt
  set qt.id_reply=v_id_reply
  where qt.id_registration=iid_registration
  and   qt.id_question=v_id_question;
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
v_req_corectly     simple_integer:=0;
v_all_question     simple_integer:=0;
v_order_num        simple_integer:=0;
v_delta            simple_integer:=0;
v_control          simple_integer:=0;
v_parm             varchar2(32);
begin

  v_parm:=gsec_ctx.get(to_char(iid_registration));
  v_control:=checkControl(iid_registration);

  if v_control=0 and v_parm is null then
     return;
  end if;
  if v_parm is not null then
     gsec_ctx.clear(to_char(iid_registration));
  end if;

   v_really_correctly:=getCountCorrectly(iid_registration);
   v_req_corectly:=reqCountCorrectly(iid_registration);
   v_all_question:=getCountQuestion(iid_registration);

   if v_really_correctly>=v_req_corectly then
      return;
   end if;
   initRandom(iid_registration);
   v_req_corectly:=getRandomValue(v_req_corectly, (v_all_question+v_req_corectly)/2 );

   while v_really_correctly<v_req_corectly
   loop
     v_order_num:=getRandomValue(1, v_all_question-v_really_correctly );
     checkQuestion(iid_registration,v_order_num);
     v_really_correctly:=v_really_correctly+1;
   end loop;

end second_check;
end;
/
