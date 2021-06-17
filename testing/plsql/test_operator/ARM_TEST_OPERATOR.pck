create or replace package arm_test_operator is

  -- Author  : Gusseynov Shamil/?????
  -- Created : 17.01.2012 18:15:12
  -- Purpose :

  -- Public type declarations
   function IsEditablePerson(iid_person number) return char;

  /* TODO enter package declarations (types, exceptions, methods etc) here */
  procedure bundle_theme_new(iid_bundle_theme in number, iid_bundle in number,
        iid_theme in number,
        iid_param in number, iis_groups in char, itheme_number in number,
        icount_question in number, icount_success in number, iperiod_for_testing in number);
  procedure bundle_theme_upd(iid_bundle_theme in number,
        iid_theme in number,
        iid_param in number, iis_groups in char, itheme_number in number,
        icount_question in number, icount_success in number, iperiod_for_testing in number);
    procedure bundle_theme_del(iid_bundle_theme number);

    procedure bundle_config_new(iid_param number,iperiod_for_testing number);
    procedure bundle_config_upd(iid_param number, iperiod_for_testing number);
    procedure bundle_config_del(iid_param number);

    procedure equals_bundle_new(iid_equal_bundle in number,
                iinterval_second in number, iinterval_first in number,
                idescr in varchar2, idescr_kaz in varchar2);
    procedure equals_bundle_upd(iid_equal_bundle number, iactive char,
                iinterval_second in number, iinterval_first in number,
                idescr in varchar2, idescr_kaz in varchar2);
    procedure equals_bundle_del(iid_equal_bundle number);

    procedure persons_new(iid_person number, iiin varchar2, ibirthday date, isex char, iname varchar2, ilastname varchar2, imiddlename varchar2, iemail varchar2);
    procedure persons_upd(iid_person number, iiin varchar2, ibirthday date, isex char, iname varchar2, ilastname varchar2, imiddlename varchar2, iemail varchar2);
    procedure persons_del(iid_person number);

--    procedure picture_new(iid_question number, ipicture blob, ipicture_kaz blob, idescr varchar2, idescr_kaz varchar2);
--    procedure picture_upd(iid_question number, ipicture blob, ipicture_kaz blob, idescr varchar2, idescr_kaz varchar2);
--    procedure picture_del(iid_question number);
    procedure categories_new(iid_category number, idescr varchar2, idescr_kaz varchar2);
    procedure categories_upd(iid_category number, idescr varchar2, idescr_kaz varchar2);
    procedure categories_del(iid_category number);

    procedure questions_new(iid_question in number,
              iid_theme in number, ilang in char, iversion_number number,
              iorder_num in number, iquestion in varchar2);
    procedure questions_upd( iid_question number,
              iid_theme in number, ilang in char, iversion_number number,
              iorder_num in number, iactiv in char, iquestion in varchar2 );
    procedure questions_del(iid_question number);

    procedure replies_new(iid_reply number, ilang in char, iid_question number,
                icorrectly char, iorder_num number, ireply varchar2);
    procedure replies_upd(iid_reply number, ilang in char, iid_question number,
                iactive char, icorrectly char, iorder_num number, ireply varchar2 );
    procedure replies_del(iid_reply number);

    procedure bundle_new(iid_bundle in number, iid_equal_bundle in number, icode_bundle in varchar2,
                         icount_theme in number, imax_point in number, imin_point in number,
                         iperiod_for_testing in number, iname_theme_bundle in varchar2, iname_theme_bundle_kaz in varchar2);
    procedure bundle_upd(iid_bundle in number, iactive in char, iid_equal_bundle in number, icode_bundle in varchar2,
                         icount_theme in number, imax_point in number, imin_point in number, iperiod_for_testing in number,
                         iname_theme_bundle in varchar2, iname_theme_bundle_kaz in varchar2);
    procedure bundle_del(iid_bundle in number);

    procedure themes_new(iid_theme in number, iid_category in number,
            iorder_num in number, idescr in varchar2, idescr_kaz in varchar2);
    procedure themes_upd(iid_theme in number, iid_category in number,
            iactive in char, iorder_num in number,
            idescr in varchar2, idescr_kaz in varchar2);
    procedure themes_del(iid_theme number);

    procedure users_bundle_config_new(iid_registration number, iid_param number, iperiod_for_testing number, iused_time number);
    procedure users_bundle_config_upd(iid_registration number, iid_param number, iperiod_for_testing number, iused_time number);
    procedure users_bundle_config_del(iid_registration number, iid_param number);

end arm_test_operator;
/

create or replace package body arm_test_operator is

    function IsEditablePerson(iid_person number) return char
    is
    v_count integer;
    res     char;
    begin
        res:='N';
        select case when count(r.status)>0
                  then 'N'
                  else 'Y'
              end
        into res
        from test_operator.registration r
        where r.id_person=iid_person
        and r.status not in ('Готов','Неявка');
        return res;
    end IsEditablePerson;
    function getIdVersionByIdTheme(iid_theme number, ilang varchar2) return simple_integer
    is
    v_id_version simple_integer:=0;
    begin
       select id_version
       into v_id_version
       from test_operator.version_questions_of_theme qt
       where qt.id_theme=iid_theme
       and   qt.language=ilang;
       return v_id_version;
       exception when no_data_found then return 0;
    end;
  procedure bundle_theme_new(iid_bundle_theme in number, iid_bundle in number,
        iid_theme in number,
        iid_param in number, iis_groups in char, itheme_number in number,
        icount_question in number, icount_success in number, iperiod_for_testing in number) as
  begin
    /* TODO implementation required */
    insert into test_operator.bundle_theme(id_bundle_theme , id_bundle, id_theme , id_param , theme_number , is_groups , count_question , count_success , period_for_testing)
    values( iid_bundle_theme , iid_bundle, iid_theme ,  iid_param , itheme_number , iis_groups , icount_question , icount_success , iperiod_for_testing);
    commit;
  end bundle_theme_new;

  procedure bundle_theme_upd(iid_bundle_theme in number, iid_theme in number,
        iid_param in number, iis_groups in char, itheme_number in number,
        icount_question in number, icount_success in number, iperiod_for_testing in number) as
  v_count simple_integer:=0;
  begin
  secmgr.sec_ctx.log(iDebug=>5,
                iappname=>'arm_tester_operator',
                ioperation=>'Обновление темы ',
                imodule=>'bundle_theme_upd',
                imessage=> 'iid_bundle_theme='||iid_bundle_theme||
                ', id_theme='||iid_theme||
                ', is_groups='||iis_groups||
                ', id_param='||iid_param||
                ', theme_number='||itheme_number||
                ', count_question='||icount_question||
                ', count_success='||icount_success||
                ', period_for_testing='||iperiod_for_testing
                );
    /* TODO implementation required */
    select count(r.id_bundle)
    into  v_count
    from  test_operator.bundle_theme bc,
          test_operator.testing r
    where bc.id_bundle_theme=iid_bundle_theme
    and   bc.id_bundle=r.id_bundle;

    if v_count>0 then
    raise_application_error(-20000,'Эта программа уже использовалась '||v_count||' раз'||
        chr(10)||'Изменить её нельзя.');
    end if;

    update test_operator.bundle_theme b
    set  b.id_param=iid_param,
         b.id_theme=iid_theme,
         b.theme_number=itheme_number,
         b.is_groups=iis_groups,
         b.count_question=icount_question,
         b.count_success=icount_success,
         b.period_for_testing=iperiod_for_testing
    where b.id_bundle_theme=iid_bundle_theme;
    commit;
  end bundle_theme_upd;

    procedure bundle_theme_del(iid_bundle_theme number)
    as
    v_id_bundle test_operator.testing.id_bundle%type;
    begin
        secmgr.sec_ctx.log(iDebug=>5,
                iappname=>'arm_tester_operator',
                ioperation=>'Удаление темы из списка',
                imodule=>'bundle_theme_del',
                imessage=> 'Операция удаления для iid_bundle_theme='||iid_bundle_theme );

        select r.id_bundle
        into  v_id_bundle
        from  test_operator.bundle_theme bc,
              test_operator.testing r
        where bc.id_bundle_theme=iid_bundle_theme
        and   bc.id_bundle=r.id_bundle;

        raise_application_error(-20000,'Эта программа уже использовалась. (iid_bundle_theme='||
        iid_bundle_theme||')'||chr(10)||'Изменить её нельзя.');
        return;

        exception when no_data_found then
            begin
                delete from test_operator.bundle_theme bc
                    where bc.id_bundle_theme=iid_bundle_theme;
                commit;
            end;

/*  secmgr.sec_ctx.log(iDebug=>5,
                iappname=>'arm_tester_operator',
                ioperation=>'Удаление темы из списка',
                imodule=>'bundle_theme_del',
                imessage=> 'Операция удаления для iid_bundle_theme='||iid_bundle_theme );
        delete from test_operator.bundle_theme bc
        where bc.id_bundle_theme=iid_bundle_theme;

        update test_operator.bundle_theme bc
        set    bc.id_bundle=null
        where bc.id_bundle_theme=iid_bundle_theme;
        commit;
*/
    end bundle_theme_del;

    procedure bundle_config_new(iid_param number,iperiod_for_testing number)
    as
    begin
    insert into bundle_config(id_param ,period_for_testing)
    values(iid_param ,iperiod_for_testing);
    commit;
    end bundle_config_new;

    procedure bundle_config_upd(iid_param number,iperiod_for_testing number)
    as
    begin
    update bundle_config bu
    set bu.period_for_testing=iperiod_for_testing
    where bu.id_param=iid_param;
    commit;
    end bundle_config_upd;

    procedure bundle_config_del(iid_param number)
    as
    begin
    null;
    commit;
    end bundle_config_del;


    procedure equals_bundle_new(iid_equal_bundle in number,
                iinterval_second in number, iinterval_first in number,
                idescr in varchar2, idescr_kaz in varchar2)
    as
    begin
    insert into equals_bundle (id_equal_bundle , active,
            interval_second , interval_first, descr, descr_kaz)
    values(iid_equal_bundle, 'Y',
        iinterval_second , iinterval_first, idescr, idescr_kaz);
    commit;
    end equals_bundle_new;

    procedure equals_bundle_upd(iid_equal_bundle in number, iactive char,
                iinterval_second in number, iinterval_first in number,
                idescr in varchar2, idescr_kaz in varchar2)
    as
    begin
    update equals_bundle eq
    set eq.active=iactive,
        eq.interval_second=iinterval_second,
        eq.interval_first=iinterval_first,
        eq.descr=idescr,
        eq.descr_kaz=idescr_kaz
    where eq.id_equal_bundle=iid_equal_bundle;
    commit;
    end equals_bundle_upd;

    procedure equals_bundle_del(iid_equal_bundle number)
    as
    begin
    update equals_bundle eq
    set eq.active='N'
    where eq.id_equal_bundle=iid_equal_bundle;
    commit;
    end equals_bundle_del;

    procedure persons_new(iid_person number, iiin varchar2, ibirthday date, isex char, iname varchar2, ilastname varchar2, imiddlename varchar2, iemail varchar2)
    as
    begin
    if iid_person is null
    then
        raise_application_error(-20000,'IdPerson не имеет значения');
    end if;
    if iiin is null
    then
        raise_application_error(-20000,'ИИН не имеет значения');
    end if;
    if ilastname is null
    then
        raise_application_error(-20000,'Фамилия не указана');
    end if;
    if iname is null
    then
        raise_application_error(-20000,'Имя не указана');
    end if;

    insert into test_operator.persons (id_person, iin, birthday, lastname, name, middlename, email, sex )
    values(iid_person, iiin, ibirthday, ilastname, iname, imiddlename, iemail, isex);
    commit;
    exception when dup_val_on_index then null;
--        persons_upd(iid_person , iiin , ibirthday , isex , iname , ilastname , imiddlename, iemail);
    end persons_new;

    procedure persons_upd(iid_person number, iiin varchar2, ibirthday date, isex char, iname varchar2, ilastname varchar2, imiddlename varchar2, iemail varchar2)
    as
    begin
    update test_operator.persons p
    set p.birthday=ibirthday,
        p.lastname=ilastname,
        p.sex=isex,
        p.name=iname,
        p.middlename=imiddlename,
        p.email=iemail
    where p.iin=iiin;
    commit;
    exception when no_data_found then null;
    end persons_upd;

    procedure persons_del(iid_person number)
    as
    begin
    null;
    commit;
    end persons_del;

--    procedure picture_new(iid_question number, ipicture blob, ipicture_kaz blob, idescr varchar2, idescr_kaz varchar2)
--    as
--    begin
--    insert into picture (id_question, picture, picture_kaz, descr, descr_kaz)
--    values(iid_question, ipicture, ipicture_kaz, idescr, idescr_kaz);
--    commit;
--    end picture_new;
--
--    procedure picture_upd(iid_question number, ipicture blob, ipicture_kaz blob, idescr varchar2, idescr_kaz varchar2)
--    as
--    begin
--    update picture pic
--    set pic.picture=ipicture,
--        pic.picture_kaz=ipicture_kaz,
--        pic.descr=idescr,
--        pic.descr_kaz=idescr_kaz
--    where pic.id_question=iid_question;
--    commit;
--    end picture_upd;

    procedure picture_del(iid_question number)
    as
    begin
    null;
    commit;
    end picture_del;

    procedure questions_new(iid_question in number,
              iid_theme in number, ilang in char, iversion_number in number,
              iorder_num in number, iquestion in varchar2)
    as
    v_order_number       simple_integer:=0;
    begin

    if iorder_num is null then
        begin
        select count(tq.question)
                into v_order_number
                from test_operator.questions tq
                where tq.id_theme=iid_theme
                and   tq.language=ilang
                and   tq.version_number=iversion_number;
        v_order_number:=v_order_number+1;
        end;
    else
            v_order_number:=iorder_num;
    end if;

    insert into test_operator.questions (id_question, id_theme,
                    version_number, language, order_num_question, active, question)
            values(iid_question, iid_theme,
                    iversion_number, ilang, v_order_number, 'Y', iquestion);
    commit;
    end questions_new;

    procedure questions_upd(iid_question in number,
              iid_theme in number, ilang in char, iversion_number in number,
              iorder_num in number,  iactiv in char, iquestion in varchar2)
    as
    v_count simple_integer:=0;
    begin
    select count(qt.id_question)
    into v_count
    from test_operator.questions_for_testing qt
    where qt.id_question=iid_question;
    if v_count > 0 then
       raise_application_error(-20000, 'Корректировка вопросов которые использовались при тестировании - ЗАПРЕЩЕНА');
       return;
    end if;

    update questions qu
    set    qu.order_num_question=iorder_num,
           qu.active=iactiv,
           qu.question=iquestion
    where qu.id_question=iid_question;

    commit;
    end questions_upd;

    procedure questions_del(iid_question number)
    as
    begin
    update questions qu
    set qu.active= case when qu.active='N' then 'Y' else 'N' end
    where qu.id_question=iid_question;
    commit;
    end questions_del;

    procedure replies_new(iid_reply number, ilang in char, iid_question number,
                icorrectly char, iorder_num number, ireply varchar2)
    as
    v_order_number simple_integer:=0;
    begin
    if iorder_num is null then
        begin
           select count(tq.id_reply)
           into v_order_number
           from test_operator.replies tq
           where tq.id_question =iid_question;
           v_order_number:=v_order_number+1;
        end;
        else
            v_order_number:=iorder_num;
    end if;

    insert into test_operator.replies (id_reply, id_question,
                    active, correctly, order_num_answer, reply)
    values(iid_reply, iid_question, 'Y',
                case when icorrectly is null then 'N' else icorrectly end,
                v_order_number, ireply);
    commit;
    end replies_new;

    procedure replies_upd(iid_reply number, ilang in char, iid_question number,
                iactive char, icorrectly char, iorder_num number, ireply varchar2 )
    as
    v_count simple_integer:=0;
    begin
    select count(qt.id_question)
    into v_count
    from test_operator.questions_for_testing qt
    where qt.id_reply=iid_reply;
    if v_count > 0 then
       raise_application_error(-20000, 'Корректировка ответов которые использовались при тестировании - ЗАПРЕЩЕНА');
       return;
    end if;

    update test_operator.replies r
            set r.id_question=iid_question,
                r.order_num_answer=iorder_num,
                r.active=iactive,
                r.correctly=icorrectly,
                r.reply=ireply
            where r.id_reply=iid_reply;

    commit;
    end replies_upd;

    procedure replies_del(iid_reply number)
    as
    begin
            update test_operator.replies r
            set r.active=case when r.active='N' then 'Y' else 'N' end
            where r.id_reply=iid_reply;
    commit;
    end replies_del;

    procedure bundle_new(iid_bundle number, iid_equal_bundle number, icode_bundle varchar2,
                         icount_theme number, imax_point number, imin_point number,
                         iperiod_for_testing number, iname_theme_bundle varchar2,
                         iname_theme_bundle_kaz varchar2)

    as
    begin
    insert into test_operator.bundle (id_bundle, active, id_equal_bundle, code_bundle,
        count_theme, max_point, min_point, period_for_testing,
        name_theme_bundle, name_theme_bundle_kaz)
    values(iid_bundle, 'Y', iid_equal_bundle, icode_bundle,
        icount_theme, imax_point, imin_point, iperiod_for_testing,
        iname_theme_bundle, iname_theme_bundle_kaz);
    commit;
    end bundle_new;

    procedure bundle_upd(iid_bundle in number, iactive in char, iid_equal_bundle in number,
                        icode_bundle in varchar2, icount_theme in number,
                        imax_point in number, imin_point in number,
                        iperiod_for_testing in number, iname_theme_bundle in varchar2,
                         iname_theme_bundle_kaz in varchar2)
    as
    begin
    update test_operator.bundle tb
    set tb.active=iactive,
        tb.id_equal_bundle=iid_equal_bundle,
        tb.code_bundle=icode_bundle,
        tb.count_theme=icount_theme,
        tb.max_point=imax_point,
        tb.min_point=imin_point,
        tb.period_for_testing=iperiod_for_testing,
        tb.name_theme_bundle=iname_theme_bundle,
        tb.name_theme_bundle_kaz=iname_theme_bundle_kaz
    where tb.id_bundle=iid_bundle;
    commit;
    end bundle_upd;

    procedure bundle_del(iid_bundle number)
    as
    begin
    update test_operator.bundle tb
    set tb.active='N'
    where tb.id_bundle=iid_bundle;
    commit;
    end bundle_del;

    procedure themes_new(iid_theme in number, iid_category in number,
            iorder_num in number, idescr in varchar2, idescr_kaz in varchar2)
    as
    v_version_number number;
    v_id_version number;
    v_id_theme number;
    v_order_number simple_integer:=0;
    begin
    if iorder_num is null then
        begin
                select count(t.id_theme)
                into v_order_number
                from test_operator.themes t
                where t.id_theme=iid_theme;
        v_order_number:=v_order_number+1;
        end;
        else
            v_order_number:=v_order_number;
    end if;

    insert into test_operator.version_questions_of_theme vt2 (id_version, id_theme,
            date_registration, ip_addr, id_emp, version_number, name )
    values( 1, iid_theme, sysdate,
            sys_context('sec_ctx','ip_addr'),
            sys_context('sec_ctx','id_emp'),
            v_version_number,
            sys_context('sec_ctx','lastname')||' '|| sys_context('sec_ctx','name'));
--        raise_application_error(-20000, 'id_theme='||iid_theme||', v_id_version='||v_id_version);
    insert into test_operator.themes (id_theme, id_category, date_creation, active, order_num, descr, descr_kaz)
    values(iid_theme, iid_category , sysdate,
          'Y', v_order_number, idescr, idescr_kaz);
    commit;
    end themes_new;

    procedure themes_upd( iid_theme in number,
            iid_category in number,
            iactive in char, iorder_num in number,
            idescr in varchar2, idescr_kaz in varchar2)
    as
    begin
    update test_operator.themes th
    set th.id_category=iid_category,
        th.active=iactive,
        th.order_num=iorder_num,
        th.descr=idescr,
        th.descr_kaz=idescr_kaz
    where th.id_theme=iid_theme;
    commit;
    end themes_upd;

    procedure themes_del(iid_theme number)
    as
    begin
    update themes th
    set th.active=case when th.active='N' then 'Y' else 'N' end
    where th.id_theme=iid_theme;
    commit;
    end themes_del;

    procedure categories_new(iid_category number, idescr varchar2, idescr_kaz varchar2)
    as
    begin
      insert into TEST_OPERATOR.categories_themes (id_category,descr,descr_kaz)
      values(iid_category, idescr, idescr_kaz );
    commit;
    end categories_new;

    procedure categories_upd(iid_category number, idescr varchar2, idescr_kaz varchar2)
    as
    begin
        update TEST_OPERATOR.categories_themes ct
        set ct.descr=idescr,
            ct.descr_kaz=descr_kaz
        where ct.id_category=iid_category;
    commit;
    end categories_upd;

    procedure categories_del(iid_category number)
    as
    begin
    null;
    end categories_del;


    procedure users_bundle_config_new(iid_registration number, iid_param number, iperiod_for_testing number, iused_time number)
    as
    begin
    insert into users_bundle_config (id_registration, id_param, period_for_testing , used_time )
    values(iid_registration, iid_param , iperiod_for_testing , iused_time );
    end users_bundle_config_new;

    procedure users_bundle_config_upd(iid_registration number, iid_param number, iperiod_for_testing number, iused_time number)
    as
    begin
    update users_bundle_config c
    set c.period_for_testing=iperiod_for_testing ,
        c.used_time=iused_time
    where c.id_registration=iid_registration
    and c.id_param=iid_param;
    end users_bundle_config_upd;

    procedure users_bundle_config_del(iid_registration number, iid_param number)
    as
    begin
    null;
    commit;
    end users_bundle_config_del;

begin
  -- Initialization
  null;
end arm_test_operator;
/
