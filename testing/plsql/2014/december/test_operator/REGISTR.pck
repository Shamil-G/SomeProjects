create or replace package registr is

procedure generate_questions(iid_registration number, iid_theme number, icount_questions number);

 -- Public type declarations
function r_new(
  iid_registration in number,
  iid_person in number,
  iid_assignment in number,
  iid_bundle in number,
  iid_type_registration in number,
  idate_testing in date,
  iend_day_testing in date
  ) return nvarchar2;

procedure r_upd(iid_registration in number,
  iid_assignment in number,
  iid_bundle in number,
  iid_type_registration in number,
  idate_testing in date,
  iend_day_testing in date
);

function checkUserForTesting(iid_person in number, iid_bundle in number, iid_type_registration in number, idate_testing in date)
return nvarchar2;

procedure r_del_oper(iid_registration in number);
procedure r_del(iid_registration in number);
procedure r_lock(iid_registration in number);
procedure r_unlocks(iid_registration in varchar2);
procedure r_unlock(iid_registration in number);

procedure change_lock_status(iid_registration in number);
procedure lock_to_absent(iid_registration in number);
procedure check_default;
procedure remove_registration(iid_registration in number);

end registr;
/

create or replace package body registr is

function user_name(iid_person in number) return varchar2
is
str nvarchar2(196);
begin
    str:='';
    if iid_person is not null
    then
       select p.lastname ||' '|| p.name
       into str
       from persons p
       where p.id_person=iid_person;
    end if;
return str;
end user_name;

function getVersionQuestions(iid_theme in number, ilang in nvarchar2)
return simple_integer
is
v_version_number simple_integer:=0;
begin
  select version_number
  into v_version_number
  from version_questions vq
  where vq.id_theme=iid_theme
  and   vq.language=ilang
  and   vq.selected='Y';

  return v_version_number;
  exception when no_data_found then return 0;
end;
procedure generate_questions(iid_registration in number, iid_theme in number,
                     icount_questions in number, ilang in nvarchar2)
is
v_version_quest   simple_integer:=0;
id_num            pls_integer;
random_size       pls_integer;
target_size       pls_integer;
random_number     pls_integer;
order_number      pls_integer;
l_seed            VARCHAR2(100);

type id_question_table is table of questions.id_question%type index by pls_integer;
input_array id_question_table;
--str varchar2(1024);
begin
  v_version_quest:=getVersionQuestions(iid_theme, ilang);

  select q.id_question
  bulk collect into input_array
  from questions q
  where q.id_theme=iid_theme
  and   q.language=ilang
  and   q.version_number=v_version_quest
  and   q.active='Y';

  random_size:=input_array.count;
  if random_size=0 THEN return; end if;

  target_size := icount_questions;
  if target_size>input_array.count
  then
     target_size:=input_array.count;
  end if;

  order_number:=0;
  l_seed := TO_CHAR(SYSTIMESTAMP,'FFFF');
  DBMS_RANDOM.seed (val => l_seed);
--  secmgr.sec_ctx.log('-+- init -+-'||', target_size: '||target_size);
  while order_number<target_size
  loop
    select dbms_random.value(1,random_size) into random_number from dual;
--    secmgr.sec_ctx.log('target_size:'||target_size);
--    secmgr.sec_ctx.log('random_number: '||random_number);
    if input_array.exists(random_number)
    then
       id_num:=input_array(random_number);
       input_array.delete(random_number);
--       str:=str||id_num||' ';
       order_number:=order_number+1;

       insert into test_operator.questions_for_testing( id_registration, id_theme, order_num_question,
                        id_question, language, id_reply, time_reply)
       values(iid_registration, iid_theme, order_number, id_num, ilang, null, null);
    end if;
  end loop;
--  secmgr.sec_ctx.log(str);
--  secmgr.sec_ctx.log('-+- finish -+-');
end generate_questions;

-- генерация вопросов
procedure generate_questions(iid_registration number, iid_theme number, icount_questions number)
is begin
  for cur in (select code from supp_lang)
  loop
    generate_questions(iid_registration, iid_theme, icount_questions, cur.code);
  end loop;
end;

-- проверка допустимости регистрации
function checkUserForTesting(iid_person in number,
        iid_bundle in number,
        iid_type_registration in number,
        idate_testing in date)
return nvarchar2
is
v_interval_first    equals_bundle.interval_first%type;
v_first             registration.beg_time_testing%type;
v_interval_second   equals_bundle.interval_second%type;
v_id_equal_bundle   equals_bundle.id_equal_bundle%type;
str nvarchar2(256) default '';
begin

  if iid_bundle is null
  then
    secmgr.sec_ctx.log(iDebug=>5, iappname=>'Registr',
            ioperation=>'Проверка кандидата на допуск к тестированию',
            imodule=>'checkUserForTesting',
            imessage=> 'Не допущен кандидат '||
             user_name(iid_person)||chr(10)||
             ': задания для тестирования не выбраны' );
    return 'Задания для тестирования не выбраны';
  end if;

  if sys_context('gsec_ctx','Production')='N'
  then
    return '';
  end if;
--  secmgr.sec_ctx.log('-+- v_id_equal_category: '||v_id_equal_category||', iid_kind_testing: '||iid_kind_testing);
/*
-- Закомментировано Гусейновым 15.08.2014
-- Проверка сроков на допустимость повторного тестирования
  begin
    select b.id_equal_bundle, e.interval_first, e.interval_second
    into   v_id_equal_bundle, v_interval_first, v_interval_second
    from test_operator.equals_bundle e, test_operator.bundle b
    where b.id_bundle=iid_bundle
    and   b.id_equal_bundle=e.id_equal_bundle;
  exception when no_data_found then return '';
  end;
--*/
--  secmgr.sec_ctx.log('-+- v_id_equal_category: '||v_id_equal_category||', iid_kind_testing: '||iid_kind_testing);

  for Cur in ( select t.*, rownum from
                      ( select r.date_testing,
                               r.beg_time_testing,
                               r.end_day_testing
                        from test_operator.registration r
                        where r.id_person=iid_person
-- Закомментировано Гусейновым 15.08.2014
--                        and   r.id_bundle in ( select id_bundle
--                                                from TEST_OPERATOR.bundle b
--                                                where b.id_equal_bundle=v_id_equal_bundle )
                        and   r.status!='Неявка'
                        --and   (sysdate-r.date_registration)<360
                        order by 1 desc ) t
                where rownum<3)
  loop
--    secmgr.sec_ctx.log('-+- Cur.Date_Testing: '||Cur.Date_Testing);
--    secmgr.sec_ctx.log('-+- v_interval_first: '||v_interval_first);

    if Cur.Rownum=1
    then
        if Cur.Beg_Time_Testing is not null
        then
          v_first:=Cur.Beg_Time_Testing;
          if (idate_testing-v_first)<v_interval_first
          then
              str:= 'После последнего тестирования прошло всего '||
                    trunc((idate_testing -
                    to_date(to_char(v_first,'dd.mm.yyyy'),'dd.mm.yyyy')))||
                    ' дней, должно быть: '||
                    v_interval_first;
          end if;
        else
          v_first:=Cur.Date_Testing;
          if  (idate_testing - v_first)<v_interval_first
          then
              str:= 'После последнего тестирования прошло всего '||
                    trunc((idate_testing -
                    to_date(to_char(v_first,'dd.mm.yyyy'),'dd.mm.yyyy')))||
                    ' дней, должно быть: '||
                    v_interval_first;
          end if;
        end if;
    end if;
    if Cur.Rownum=2
    then
          if (idate_testing-v_first)<v_interval_second
          then
              str:= 'После последнего тестирования прошло всего '||
                    trunc((idate_testing -
                    to_date(to_char(v_first,'dd.mm.yyyy'),'dd.mm.yyyy')))||
                    ' дней, должно быть: '||
                    v_interval_second;

          end if;
    end if;
  end loop;
  return str;
end checkUserForTesting;

function r_new(
  iid_registration in number,
  iid_person in number,
  iid_assignment in number,
  iid_bundle in number,
  iid_type_registration in number,
  idate_testing in date,
  iend_day_testing in date
  )
  return nvarchar2
  is
  v_id_bundle_theme pls_integer;
--  v_id_bundle       pls_integer;
  v_id_param        pls_integer;
  v_period_testing  pls_integer;
  v_is_groups       char(1);
  str               nvarchar2(256);
  v_first_theme     boolean;
  v_count_theme     simple_integer:=0;
  v_first_id_question simple_integer:=0;
begin
  select b.period_for_testing, b.is_groups
  into v_period_testing, v_is_groups
  from bundle b
  where b.id_bundle=iid_bundle;
--  raise_application_error(-20000,'iid_bundle='||iid_bundle||', period_for_testing='||v_period_testing||', is_groups='||v_is_groups);

  str:=checkUserForTesting(iid_person, iid_bundle, iid_type_registration, idate_testing );
  if (str is not null)
  then
      secmgr.sec_ctx.log(iDebug=>5,iappname=>'Registr',
            ioperation=>'Проверка кандидата на допуск к тестированию',
            imodule=>'checkUserForTesting',
            imessage=> 'Не допущен кандидат '||
             helper.getfio(iid_person)||chr(10)||
             ', Ид регистр.: '||iid_registration ||
             ', Программа: '||iid_assignment||': '||helper.getNameBundle(iid_assignment) ||
             ', ошибка: '||str );
     return str;
  end if;

  insert into test_operator.registration(id_registration,
              id_person,
              id_assignment,
              id_bundle,
              ID_TYPE_REGISTRATION,
              date_registration,
              id_emp,
              id_region,
              date_testing,
              status,
              beg_time_testing, end_time_testing,
              end_day_testing, language)
  values( iid_registration, iid_person, iid_assignment, iid_bundle,
          IID_TYPE_REGISTRATION,
          sysdate,
          sys_context('SEC_CTX','id_emp'),
          sys_context('SEC_CTX','id_region'),
          idate_testing,
          'Готов',
          null, null,
          iend_day_testing, 'ru');

      insert into test_operator.testing( id_registration, id_bundle,
                          id_current_theme,  last_time_access,
                          status)
      values ( iid_registration, iid_bundle,
                null, null, 'Готов');

      v_id_param:=-1;
      v_first_theme:=true;

      for Cur in ( select *
                    from bundle_tasks b
                 where b.id_bundle=iid_bundle
                 order by b.theme_number)
        loop
           if v_first_theme=true
           then
              update test_operator.testing t
              set    t.id_current_theme=cur.id_theme,
                    t.count_question=cur.count_question,
                    t.current_theme_number=1,
                    t.count_theme = ( select count(tb.id_bundle) from
                                        test_operator.bundle_tasks tb
                                      where tb.id_bundle=iid_bundle
                                    ),
                    t.current_question_num = 1
              where  t.id_registration=iid_registration;
           end if;
--           secmgr.sec_ctx.log('Cur.id_param: '||Cur.id_param);
           if(v_is_groups!='Y' and --т.е. в Bundle не указывается общее время 17.11.2014
              Cur.Is_Groups='Y' and Cur.id_param is not null and
              v_id_param!=Cur.id_param)
           then
             v_id_param:=Cur.id_param;
             select period_for_testing
             into v_period_testing
             from bundle_config uc
             where uc.id_param=v_id_param;
--          secmgr.sec_ctx.log('set id_param iid_registration: '||iid_registration||', 2 Cur.id_param: '||Cur.id_param||', v_id_param: '||v_id_param);
             arm_test_operator.users_bundle_config_new(iid_registration, v_id_param, v_period_testing*60,0);
           end if;

--          secmgr.sec_ctx.log('iid_registration: '||iid_registration||', 2 Cur.id_param: '||Cur.id_param||', v_period_testing: '||v_period_testing);
          insert into
          users_bundle_composition( id_registration,
                                    id_theme,
                                    id_param,
                                    is_groups, order_num, theme_number,
                                    count_question, count_success,
                                    period_for_testing,
                                    used_time,
                                    status_testing)
           values( iid_registration,
                   Cur.id_theme,
                   Cur.id_param,
                   Cur.is_groups,
                   1,
                   Cur.theme_number,
                   Cur.count_question,
                   Cur.count_success,
                   case when Cur.Is_Groups='Y' then 0 else Cur.period_for_testing*60 end,
                   0,
                   'Готов' );

             generate_questions(iid_registration, Cur.id_theme, Cur.count_question);
             if v_first_theme=true then
                v_period_testing:=case when Cur.Is_Groups='Y' or v_is_groups='Y'
                                                    then v_period_testing*60
                                                    else Cur.period_for_testing*60
                                                    end;
                update test_operator.testing t1
                set    t1.period_for_testing=v_period_testing
                where t1.id_registration=iid_registration;
--                secmgr.sec_ctx.log('Registr','Update Testing','r_new',
--                        'Пользователь '||
--                        helper.getfiobyidreg(iid_registration)||chr(10)||
--                        ', id_registration: '||iid_registration ||
--                        ', first_id_question: '||v_first_id_question||
--                        ', v_period_testing: '||v_period_testing);
                v_first_theme:=false;
             end if;
          end loop;
        commit;
        secmgr.sec_ctx.log(iDebug=>5, iappname=>'Registr',
            ioperation=>'Регистрация',
            imodule=>'r_new',
            imessage=> 'Успешно зарегистрирован пользователь '||
                        helper.getfiobyidreg(iid_registration)||chr(10)||
                        ', id_registration: '||iid_registration);
        return '';
end r_new;

procedure r_upd(iid_registration in number,
  iid_assignment in number,
  iid_bundle in number,
  iid_type_registration in number,
  idate_testing in date,
  iend_day_testing in date
  )
as
v_status registration.status%type;
begin

  select status into v_status
  from registration r
  where r.id_registration=iid_registration;

  if v_status in ('Готов')
  then
    update test_operator.registration r
    set  r.id_emp=sys_context('SEC_CTX','id_person'),
         r.date_testing=idate_testing,
         r.end_day_testing=iend_day_testing
    where r.id_registration=iid_registration;
  commit;
  end if;
end r_upd;

procedure r_lock(iid_registration in number)
as
str       nvarchar2(128);
begin
  update registration r
  set r.status=str
  where r.id_registration=iid_registration
  and   r.status not in ('Неявка');
    secmgr.sec_ctx.log(iDebug=>5, iappname=>'Registr',
        ioperation=>'Блокировка теста',
        imodule=>'r_lock',
        imessage=> 'Ид регистр.: '||iid_registration||
                    ', Блокирован пользователь: '||
                    helper.getfiobyidreg(iid_registration) );
  commit;
end r_lock;

procedure r_unlock(iid_registration in number)
as
begin
  update registration r
  set r.status='Разблокирован Администратором',
      r.id_pc=null
  where r.id_registration=iid_registration
  and   r.status not in ('Неявка');
    secmgr.sec_ctx.log(iDebug=>5, iappname=>'Registr',
        ioperation=>'Разблокировка теста',
        imodule=>'r_unlock',
        imessage=> 'Ид регистр.: '||iid_registration||
                    ', Блокирован пользователь: '||
                    helper.getfiobyidreg(iid_registration) );
commit;
end r_unlock;

procedure r_unlocks(iid_registration in varchar2)
as
begin
--  secmgr.sec_ctx.log('-+- 1 iid_registration: '||iid_registration);
  r_unlock(to_number(iid_registration));
end r_unlocks;

procedure r_del(iid_registration in number) as
  begin
    r_lock(iid_registration);
end r_del;

procedure r_del_oper(iid_registration in number) as
  begin
  update registration r
  set r.status='Отмена оператором'
  where r.id_registration=iid_registration
  and   r.status in ('Готов');
    secmgr.sec_ctx.log(iDebug=>5, iappname=>'Registr',
        ioperation=>'Отмена регистрации операторогм',
        imodule=>'r_del_oper',
        imessage=> 'Ид регистр.: '||iid_registration||
                    ', Отмена регистрации для: '||
                    helper.getfiobyidreg(iid_registration) );
  commit;
end r_del_oper;

procedure remove_registration(iid_registration in number) as
  begin
    delete from TEST_OPERATOR.questions_for_testing qt where qt.id_registration=iid_registration;
    delete from TEST_OPERATOR.users_bundle_composition bc where bc.id_registration=iid_registration;
    delete from TEST_OPERATOR.users_bundle_config bc where bc.id_registration=iid_registration;
--  delete from test_operator.print_result_history pr where pr.id_registration=id_reg;
    delete from TEST_OPERATOR.testing t where t.id_registration=iid_registration;
    delete from TEST_OPERATOR.registration r where r.id_registration=iid_registration;
    secmgr.sec_ctx.log(iDebug=>5, iappname=>'Registr',
            ioperation=>'Удаление регистрации',
            imodule=>'remove_registration',
            imessage=> 'Ид регистр.: '||iid_registration||
                        ', пользователь: '||
                        helper.getfiobyidreg(iid_registration) );
end remove_registration;
procedure change_lock_status(iid_registration in number)
is
v_status nvarchar2(128);
begin
    select r.status
    into v_status
    from test_operator.registration r
    where r.id_registration=iid_registration;
    if substr(lower(v_status), 1, 5)='блоки' then
        r_unlock(iid_registration);
        secmgr.sec_ctx.log(iDebug=>5, iappname=>'Registr',
            ioperation=>'Разблокировка теста',
            imodule=>'change_lock_status',
            imessage=> 'Ид регистр.: '||iid_registration||
                        ', Разблокирован пользователь: '||
                        helper.getfiobyidreg(iid_registration) );
    else
    if substr(lower(v_status), 1, 5) in ('разбл', 'готов') then
        r_lock(iid_registration);
        secmgr.sec_ctx.log(iDebug=>5, iappname=>'Registr',
            ioperation=>'Разблокировка теста',
            imodule=>'change_lock_status',
            imessage=> 'Ид регистр.: '||iid_registration||
                        ', Блокирован пользователь: '||
                        helper.getfiobyidreg(iid_registration) );
    end if;
    end if;
    commit;
end change_lock_status;

procedure lock_to_absent(iid_registration in number)
is
begin
    update test_operator.registration r
    set r.status='Неявка'
    where r.id_registration=iid_registration;
    remove_registration(iid_registration);

    secmgr.sec_ctx.log(iDebug=>5, iappname=>'Registr',
            ioperation=>'Неявка',
            imodule=>'lock_to_absent',
            imessage=> 'Ид регистр.: '||iid_registration||
                        ', Блокирован пользователь: '||
                        helper.getfiobyidreg(iid_registration) );
    commit;
    exception when no_data_found then null;
end lock_to_absent;

procedure check_default
is
begin
    For cur in ( select * from test_operator.registration r
                where r.status in ('Готов')
                and trunc(r.date_testing,'dd')<trunc(sysdate,'dd')
                and coalesce(r.end_day_testing,r.date_testing)<trunc(sysdate)
            )
    loop
--        update test_operator.registration r
--        set r.status='Неявка'
--        where r.id_registration=cur.id_registration;
        remove_registration(cur.id_registration);

    secmgr.sec_ctx.log(iDebug=>5, iappname=>'Registr',
        ioperation=>'Контроль Системой "Неявок"',
        imodule=>'checkDefault',
        imessage=> 'Неявка. Ид регистр.: '||cur.id_registration||
            ', Кандидат: '||helper.getfiobyidreg(cur.id_registration) );
    end loop;
--rollback;
commit;
end;


end registr;
/
