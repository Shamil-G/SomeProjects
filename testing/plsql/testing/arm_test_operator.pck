create or replace package arm_test_operator is

  -- Author  : Gusseynov Shamil/Шамиль Гусейнов
  -- Created : 17.01.2012 18:15:12
  -- Purpose :

  -- Public type declarations
   function IsEditablePerson(iid_person number) return char;

  /* TODO enter package declarations (types, exceptions, methods etc) here */
    procedure bundle_composition_new(iid_composition number, iid_theme number, iid_bundle_theme number, iid_param number, itheme_number number, iis_groups char, icount_question number, icount_success number, iperiod_for_testing number);
    procedure bundle_composition_upd(iid_composition number, iid_param number, itheme_number number, iis_groups char, icount_question number, icount_success number, iperiod_for_testing number);
    procedure bundle_composition_del(iid_composition number);

    procedure bundle_config_new(iid_param number,iperiod_for_testing number);
    procedure bundle_config_upd(iid_param number, iperiod_for_testing number);
    procedure bundle_config_del(iid_param number);

    procedure categories_new(icategory char, idescr varchar2, idescr_kaz varchar2);
    procedure categories_upd(icategory char, iactive char, idescr varchar2, idescr_kaz varchar2);
    procedure categories_del(icategory char);

    procedure categories_position_new(iid_category_for_position number, icategory char, iid_equal_category number, icode_category varchar2, idescr varchar2, idescr_kaz varchar2);
    procedure categories_position_upd(iid_category_for_position number, iid_equal_category number, icode_category varchar2, idescr varchar2, idescr_kaz varchar2);
    procedure categories_position_del(iid_category_for_position number);

    procedure control_registration_new( iid_equal_category number, iid_kind_testing number, iinterval_first number, iinterval_second number);
    procedure control_registration_upd( iid_equal_category number, iid_kind_testing number, iinterval_first number, iinterval_second number);
    procedure control_registration_del( iid_equal_category number, iid_kind_testing number);

    procedure degrees_new(iid_degree number, iname_degree varchar2, iname_degree_kaz varchar2);
    procedure degrees_upd(iid_degree number, iname_degree varchar2, iname_degree_kaz varchar2);
    procedure degrees_del(iid_degree number);

    procedure educations_new(iid_education number, ieducation varchar2, ieducation_kaz varchar2);
    procedure educations_upd(iid_education number, ieducation varchar2, ieducation_kaz varchar2);
    procedure educations_del(iid_education number);

    procedure equals_categories_new(iid_equal_category number, idescr varchar2, idescr_kaz varchar2);
    procedure equals_categories_upd(iid_equal_category number, iactive char, idescr varchar2, idescr_kaz varchar2);
    procedure equals_categories_del(iid_equal_category number);

    procedure groups_tests_new( iid_group number, iid_kind_testing number, 
                                iid_category_for_position number, 
                                iid_organization number, 
                                iid_bundle_theme number, 
                                iid_parent_bundle_theme number, 
                                iname_test_group varchar2 );
    procedure groups_tests_upd( iid_group number, 
                                iactive   char,
                                iid_kind_testing number, 
                                iid_category_for_position number, 
                                iid_organization number, 
                                iid_bundle_theme number, 
                                iid_parent_bundle_theme number, 
                                iname_test_group varchar2 );
    procedure groups_tests_del(iid_group number);

    procedure kind_testing_new(iid_kind_testing number, idescr_kaz varchar2, idescr varchar2);
    procedure kind_testing_upd(iid_kind_testing number, iactive char, idescr varchar2, idescr_kaz varchar2);
    procedure kind_testing_del(iid_kind_testing number);

    procedure nationals_new(iid_national number, iorder_num number, inational varchar2, inational_kaz varchar2);
    procedure nationals_upd(iid_national number, iorder_num number, inational varchar2, inational_kaz varchar2);
    procedure nationals_del(iid_national number);


    procedure org_positions_new(iid_position number, iid_organization number, iid_category_for_position number);
    procedure org_positions_upd(iid_position number, iid_organization number, iid_category_for_position number, iactive char);
    procedure org_positions_del(iid_position number, iid_organization number, iid_category_for_position number );

    procedure organizations_new(iid_organization number, icategory char, iname_organization varchar2, iname_organization_kaz varchar2);
    procedure organizations_upd(iid_organization number, iactive char, icategory char, iname_organization varchar2, iname_organization_kaz varchar2);
    procedure organizations_del(iid_organization number);

    procedure persons_new(iid_person number, iid_national number, iiin varchar2, ibirthday date, isex char, iname varchar2, ilastname varchar2, imiddlename varchar2, idoc_num varchar2, iemail varchar2);
    procedure persons_upd(iid_person number, iid_national number, iiin varchar2, ibirthday date, isex char, iname varchar2, ilastname varchar2, imiddlename varchar2, idoc_num varchar2, iemail varchar2);
    procedure persons_del(iid_person number);

    procedure picture_new(iid_question number, ipicture blob, ipicture_kaz blob, idescr varchar2, idescr_kaz varchar2);
    procedure picture_upd(iid_question number, ipicture blob, ipicture_kaz blob, idescr varchar2, idescr_kaz varchar2);
    procedure picture_del(iid_question number);

    procedure positions_new(iid_position number, iname_position varchar2, iname_position_kaz varchar2);
    procedure positions_upd(iid_position number, iactive char, iname_position varchar2, iname_position_kaz varchar2);
    procedure positions_del(iid_position number);

    procedure questions_new(iid_question number, iid_theme number, iquestion varchar2, iquestion_kaz varchar2);
    procedure questions_upd(iid_question number, iid_theme number, iactive char, iquestion varchar2, iquestion_kaz varchar2);
    procedure questions_del(iid_question number);

    procedure replies_new(iid_reply number, iid_question number, iorder_num number, icorrectly char, ireply varchar2, ireply_kaz varchar2);
    procedure replies_upd(iid_reply number, iid_question number, iorder_num number, icorrectly char, iactive char, ireply varchar2, ireply_kaz varchar2 );
    procedure replies_del(iid_reply number);

    procedure subdivisions_new(iid_subdivision number, iid_region number, iid_organization number, iname_subdivision varchar2, iname_subdivision_kaz varchar2);
    procedure subdivisions_upd(iid_subdivision number, iactive char, iid_organization number, iname_subdivision varchar2, iname_subdivision_kaz varchar2);
    procedure subdivisions_del(iid_subdivision number);

    procedure theme_bundle_new(iid_bundle_theme number, iname_theme_bundle varchar2, iname_theme_bundle_kaz varchar2, idescr varchar2);
    procedure theme_bundle_upd(iid_bundle_theme number, iactive char, iname_theme_bundle varchar2, iname_theme_bundle_kaz varchar2, idescr varchar2);
    procedure theme_bundle_del(iid_bundle_theme number);

    procedure themes_new(iid_theme number, idescr varchar2, idescr_kaz varchar2);
    procedure themes_upd(iid_theme number, iactive char, idescr varchar2, idescr_kaz varchar2);
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
 
  procedure bundle_composition_new(iid_composition number, iid_theme number, iid_bundle_theme number, iid_param number, itheme_number number, iis_groups char, icount_question number, icount_success number, iperiod_for_testing number) as
  begin
    /* TODO implementation required */
    insert into bundle_composition(id_composition , id_theme , id_bundle_theme , id_param , theme_number , is_groups , count_question , count_success , period_for_testing)
    values(iid_composition , iid_theme , iid_bundle_theme, iid_param , itheme_number , iis_groups , icount_question , icount_success , iperiod_for_testing);
    commit;
  end bundle_composition_new;

  procedure bundle_composition_upd(iid_composition number, iid_param number, itheme_number number, iis_groups char, icount_question number, icount_success number, iperiod_for_testing number) as
  begin
    /* TODO implementation required */
    update bundle_composition b
    set  b.id_param=iid_param,
         b.theme_number=itheme_number,
         b.is_groups=iis_groups,
         b.count_question=icount_question,
         b.count_success=icount_success,
         b.period_for_testing=iperiod_for_testing
    where b.id_composition=iid_composition;
    commit;
  end bundle_composition_upd;

procedure bundle_composition_del(iid_composition number)
  as
  v_exists char(1);
  begin
    select '1'
    into  v_exists
    from  testing t, bundle_composition bc
    where t.id_bundle_theme=bc .id_bundle_theme
    and   bc.id_composition=iid_composition;
    /* TODO implementation required */
    return;
    exception when no_data_found then
        begin
            delete from bundle_composition bc 
                where bc.id_composition=iid_composition;
            commit;
        end;
end bundle_composition_del;

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

    procedure categories_new(icategory char, idescr varchar2, idescr_kaz varchar2)
    as
    begin
    insert into categories(category, active, descr, descr_kaz)
    values(icategory, 'Y', idescr, idescr_kaz);
    commit;
    end categories_new;

    procedure categories_upd(icategory char, iactive char, idescr varchar2, idescr_kaz varchar2)
    as
    begin
    update categories c
    set c.active=iactive,
        c.descr=idescr,
        c.descr_kaz=idescr_kaz
    where c.category=icategory;
    commit;
    end categories_upd;

    procedure categories_del(icategory char)
    as
    begin
    update TEST_OPERATOR.categories c
    set c.active='N'
    where c.category=icategory;
    commit;
    end categories_del;

    procedure categories_position_new(iid_category_for_position number, icategory char, iid_equal_category number, icode_category varchar2, idescr varchar2, idescr_kaz varchar2)
    as
    begin
    insert into category_position (id_category_for_position, category, id_equal_category, code_category, descr, descr_kaz)
                            values(iid_category_for_position, icategory, iid_equal_category, icode_category, idescr, idescr_kaz);
    commit;
    end categories_position_new;

    procedure categories_position_upd(iid_category_for_position number, iid_equal_category number, icode_category varchar2, idescr varchar2, idescr_kaz varchar2)
    as
    begin
    update category_position cp
    set cp.code_category=icode_category,
        cp.id_equal_category=iid_equal_category,
        cp.descr=idescr,
        cp.descr_kaz=idescr_kaz
    where cp.id_category_for_position=iid_category_for_position;
    commit;
    end categories_position_upd;

    procedure categories_position_del(iid_category_for_position number)
    as
    begin

    null;
    commit;
    end categories_position_del;

    procedure control_registration_new( iid_equal_category number, iid_kind_testing number, iinterval_first number, iinterval_second number)
    is
    begin
        insert into control_registration (id_equal_category, id_kind_testing, interval_first, interval_second)
        values (iid_equal_category, iid_kind_testing, iinterval_first, iinterval_second);
        exception when dup_val_on_index then null;
        commit;
    end control_registration_new;

    procedure control_registration_upd( iid_equal_category number, iid_kind_testing number, iinterval_first number, iinterval_second number)
    is
    begin
        update control_registration c
        set c.interval_first=iinterval_first,
            c.interval_second=iinterval_second
        where c.id_equal_category=iid_equal_category
        and c.id_kind_testing=iid_kind_testing;
        commit;
    end control_registration_upd;

    procedure control_registration_del( iid_equal_category number, iid_kind_testing number)
    is
    begin
        update control_registration c
        set c.interval_first=0,
            c.interval_second=0
        where c.id_equal_category=iid_equal_category
        and c.id_kind_testing=iid_kind_testing;
        commit;
    end control_registration_del;

    procedure degrees_new(iid_degree number, iname_degree varchar2, iname_degree_kaz varchar2)
    as
    begin
    insert into degrees (id_degree, name_degree, name_degree_kaz)
    values(iid_degree, iname_degree, iname_degree_kaz);
    commit;
    end degrees_new;

    procedure degrees_upd(iid_degree number, iname_degree varchar2, iname_degree_kaz varchar2)
    as
    begin
    update degrees d
    set d.name_degree=iname_degree,
        d.name_degree_kaz=iname_degree_kaz
    where d.id_degree=iid_degree;
    commit;
    end degrees_upd;

    procedure degrees_del(iid_degree number)
    as
    begin
    null;
    commit;
    end degrees_del;

    procedure educations_new(iid_education number, ieducation varchar2, ieducation_kaz varchar2)
    as
    begin
    insert into educations (id_education, education, education_kaz)
    values(iid_education, ieducation, ieducation_kaz);
    commit;
    end educations_new;

    procedure educations_upd(iid_education number, ieducation varchar2, ieducation_kaz varchar2)
    as
    begin
    update educations e
    set e.education=ieducation,
        e.education_kaz=ieducation_kaz
    where e.id_education=iid_education;
    commit;
    end educations_upd;

    procedure educations_del(iid_education number)
    as
    begin
    null;
    commit;
    end educations_del;

    procedure equals_categories_new(iid_equal_category number, idescr varchar2, idescr_kaz varchar2)
    as
    begin
    insert into equals_category (id_equal_category , active, descr, descr_kaz)
    values(iid_equal_category, 'Y', idescr, idescr_kaz);
    commit;
    end equals_categories_new;

    procedure equals_categories_upd(iid_equal_category number, iactive char, idescr varchar2, idescr_kaz varchar2)
    as
    begin
    update equals_category eq
    set eq.active=iactive,
        eq.descr=idescr,
        eq.descr_kaz=idescr_kaz
    where eq.id_equal_category=iid_equal_category;
    commit;
    end equals_categories_upd;

    procedure equals_categories_del(iid_equal_category number)
    as
    begin
    update equals_category eq
    set eq.active='N'
    where eq.id_equal_category=iid_equal_category;
    commit;
    end equals_categories_del;

    procedure groups_tests_new( iid_group number, iid_kind_testing number, 
                                iid_category_for_position number, 
                                iid_organization number, 
                                iid_bundle_theme number, 
                                iid_parent_bundle_theme number, 
                                iname_test_group varchar2 )
    as
    begin
    insert into groups_tests (id_group, active, id_kind_testing, 
                              id_category_for_position, id_organization, 
                              id_bundle_theme, id_parent_bundle_theme, name_test_group )
    values( iid_group, 'Y', iid_kind_testing, 
            iid_category_for_position, iid_organization, 
            iid_bundle_theme, 
            iid_parent_bundle_theme, 
            iname_test_group);
    commit;
    end groups_tests_new;

    procedure groups_tests_upd( iid_group number, 
                                iactive   char,
                                iid_kind_testing number, 
                                iid_category_for_position number, 
                                iid_organization number, 
                                iid_bundle_theme number, 
                                iid_parent_bundle_theme number, 
                                iname_test_group varchar2 )
    as
    begin
    update groups_tests g
    set g.active=iactive,
        g.id_kind_testing=iid_kind_testing,
        g.id_category_for_position=iid_category_for_position,
        g.id_organization=iid_organization,
        g.id_bundle_theme=iid_bundle_theme,
        g.id_parent_bundle_theme=iid_parent_bundle_theme,
        g.name_test_group=iname_test_group
    where g.id_group=iid_group;
    commit;
    end groups_tests_upd;

    procedure groups_tests_del(iid_group number)
    as
    begin
    update groups_tests g
    set g.active='N'
    where g.id_group=iid_group;
    commit;
    end groups_tests_del;

    procedure kind_testing_new(iid_kind_testing number, idescr_kaz varchar2, idescr varchar2)
    as
    begin
    insert into kind_testing (id_kind_testing, descr_kaz, descr, active)
    values(iid_kind_testing, idescr_kaz, idescr, 'Y');
    commit;
    end kind_testing_new;

    procedure kind_testing_upd(iid_kind_testing number, iactive char, idescr varchar2, idescr_kaz varchar2 )
    as
    begin
    update kind_testing k
    set k.active=iactive,
        k.descr_kaz=idescr_kaz,
        k.descr=idescr
    where k.id_kind_testing=iid_kind_testing;
    commit;
    end kind_testing_upd;

    procedure kind_testing_del(iid_kind_testing number)
    as
    begin
    update kind_testing k
    set k.active='N'
    where k.id_kind_testing=iid_kind_testing;
    commit;
    end kind_testing_del;

    procedure nationals_new(iid_national number, iorder_num number, inational varchar2, inational_kaz varchar2)
    as
    begin
    insert into nationals (id_national, national, national_kaz, order_num)
    values(iid_national, inational, inational_kaz, iorder_num);
    commit;
    end nationals_new;

    procedure nationals_upd(iid_national number, iorder_num number, inational varchar2, inational_kaz varchar2)
    as
    begin
    update nationals n
    set n.national=inational,
        n.national_kaz=inational_kaz,
        n.order_num=iorder_num
    where n.id_national=iid_national;
    commit;
    end nationals_upd;

    procedure nationals_del(iid_national number)
    as
    begin
    null;
    commit;
    end nationals_del;

    procedure org_positions_new(iid_position number, iid_organization number, iid_category_for_position number )
    as
    begin
    insert into org_positions (id_position, id_organization, id_category_for_position, active)
    values(iid_position, iid_organization, iid_category_for_position, 'Y' );
    commit;
    exception when dup_val_on_index then null;
    end org_positions_new;

    procedure org_positions_upd(iid_position number, iid_organization number, iid_category_for_position number, iactive char)
    as
    begin
    if iid_position is null
    then
        raise_application_error(-20001,'Error: id position is null');
    end if;
    if iid_organization is null
    then
        raise_application_error(-20001,'Error: id organization is null');
    end if;
    if iid_category_for_position is null
    then
        raise_application_error(-20001,'Error: id category for position is null');
    end if;

    update org_positions o
    set    o.active=iactive
    where o.id_position=iid_position
    and   o.id_organization=iid_organization
    and   o.id_category_for_position=iid_category_for_position;
    commit;
    end org_positions_upd;

    procedure org_positions_del(iid_position number, iid_organization number, iid_category_for_position number )
    as
    v_count_used pls_integer;
    begin
    select count(r.id_registration)
    into v_count_used
    from test_operator.registration r
    where r.id_category_for_position=iid_category_for_position
    and   r.id_position=iid_position
    and   r.id_organization=iid_organization;
    if v_count_used>0 then
       update org_positions o
       set o.active='N'
       where o.id_position=iid_position
       and   o.id_organization=iid_organization
       and   o.id_category_for_position=iid_category_for_position;
    else
       delete from org_positions o
       where o.id_position=iid_position
       and   o.id_organization=iid_organization
       and   o.id_category_for_position=iid_category_for_position;
    end if;
    commit;
    end org_positions_del;


    procedure organizations_new(iid_organization number, icategory char, iname_organization varchar2, iname_organization_kaz varchar2)
    as
    begin
    insert into organizations (id_organization, active, category, name_organization, name_organization_kaz )
    values(iid_organization, 'Y', icategory, iname_organization, iname_organization_kaz );
    commit;
    end organizations_new;

    procedure organizations_upd(iid_organization number, iactive char, icategory char, iname_organization varchar2, iname_organization_kaz varchar2)
    as
    begin
    update organizations org
    set org.active=iactive,
        org.category=icategory,
        org.name_organization=iname_organization,
        org.name_organization_kaz=iname_organization_kaz
    where org.id_organization=iid_organization;
    commit;
    end organizations_upd;

    procedure organizations_del(iid_organization number)
    as
    begin
    update organizations org
    set org.active='N'
    where org.id_organization=iid_organization;
    commit;
    end organizations_del;

    procedure persons_new(iid_person number, iid_national number, iiin varchar2, ibirthday date, isex char, iname varchar2, ilastname varchar2, imiddlename varchar2, idoc_num varchar2, iemail varchar2)
    as
    begin
    insert into persons (id_person, doc_num, birthday, lastname, name, middlename, email, sex, id_national, iin)
    values(iid_person, idoc_num, ibirthday, ilastname, iname, imiddlename, iemail, isex, iid_national, iiin);
    commit;
    end persons_new;

    procedure persons_upd(iid_person number, iid_national number, iiin varchar2, ibirthday date, isex char, iname varchar2, ilastname varchar2, imiddlename varchar2, idoc_num varchar2, iemail varchar2)
    as
    begin
    update persons p
    set p.doc_num=idoc_num,
        p.birthday=ibirthday,
        p.lastname=ilastname,
        p.name=iname,
        p.middlename=imiddlename,
        p.email=iemail,
        p.sex=isex,
        p.id_national=iid_national,
        p.iin=iiin
    where p.id_person=iid_person;
    commit;
    end persons_upd;

    procedure persons_del(iid_person number)
    as
    begin
    null;
    commit;
    end persons_del;

    procedure picture_new(iid_question number, ipicture blob, ipicture_kaz blob, idescr varchar2, idescr_kaz varchar2)
    as
    begin
    insert into picture (id_question, picture, picture_kaz, descr, descr_kaz)
    values(iid_question, ipicture, ipicture_kaz, idescr, idescr_kaz);
    commit;
    end picture_new;

    procedure picture_upd(iid_question number, ipicture blob, ipicture_kaz blob, idescr varchar2, idescr_kaz varchar2)
    as
    begin
    update picture pic
    set pic.picture=ipicture,
        pic.picture_kaz=ipicture_kaz,
        pic.descr=idescr,
        pic.descr_kaz=idescr_kaz
    where pic.id_question=iid_question;
    commit;
    end picture_upd;

    procedure picture_del(iid_question number)
    as
    begin
    null;
    commit;
    end picture_del;

    procedure positions_new(iid_position number, iname_position varchar2, iname_position_kaz varchar2)
    as
    begin
    insert into positions (id_position, active, name_position, name_position_kaz)
    values(iid_position, 'Y', iname_position, iname_position_kaz);
    commit;
    end positions_new;

    procedure positions_upd(iid_position number, iactive char, iname_position varchar2, iname_position_kaz varchar2)
    as
    begin
    update positions po
    set po.active=iactive,
        po.name_position=iname_position,
        po.name_position_kaz=iname_position_kaz
    where po.id_position=iid_position;
    commit;
    end positions_upd;

    procedure positions_del(iid_position number)
    as
    begin
    update positions po
    set po.active='N'
    where po.id_position=iid_position;
    commit;
    end positions_del;

    procedure questions_new(iid_question number, iid_theme number, iquestion varchar2, iquestion_kaz varchar2)
    as
    begin
    insert into questions (id_question, id_theme, active, question, question_kaz)
    values(iid_question, iid_theme, 'Y', iquestion, iquestion_kaz);
    commit;
    end questions_new;

    procedure questions_upd(iid_question number, iid_theme number, iactive char, iquestion varchar2, iquestion_kaz varchar2)
    as
    begin
    update questions qu
    set qu.id_theme=iid_theme,
        qu.active=iactive,
        qu.question=iquestion,
        qu.question_kaz=iquestion_kaz
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

    procedure replies_new(iid_reply number, iid_question number, iorder_num number, icorrectly char, ireply varchar2, ireply_kaz varchar2)
    as
    begin
    insert into replies (id_reply, id_question, order_num, correctly, active, reply, reply_kaz)
    values(iid_reply, iid_question, iorder_num, icorrectly, 'Y', ireply, ireply_kaz);
    commit;
    end replies_new;

    procedure replies_upd(iid_reply number, iid_question number,  iorder_num number, icorrectly char, iactive char, ireply varchar2, ireply_kaz varchar2 )
    as
    begin
    update replies r
    set r.id_question=iid_question,
        r.order_num=iorder_num,
        r.active=iactive,
        r.correctly=icorrectly,
        r.reply=ireply,
        r.reply_kaz=ireply_kaz
    where r.id_reply=iid_reply;
    commit;
    end replies_upd;

    procedure replies_del(iid_reply number)
    as
    begin
    update replies r
    set r.active=case when r.active='N' then 'Y' else 'N' end
    where r.id_reply=iid_reply;
    commit;
    end replies_del;

    procedure subdivisions_new(iid_subdivision number, iid_region number, iid_organization number, iname_subdivision varchar2, iname_subdivision_kaz varchar2)
    as
    begin
    insert into subdivisions (id_subdivision, active, id_region, id_organization, name_subdivision, name_subdivision_kaz)
    values(iid_subdivision, 'Y', iid_region, iid_organization, iname_subdivision, iname_subdivision_kaz);
    commit;
    end subdivisions_new;

    procedure subdivisions_upd(iid_subdivision number, iactive char, iid_organization number, iname_subdivision varchar2, iname_subdivision_kaz varchar2)
    as
    begin
    update subdivisions sub
    set sub.active=iactive,
        sub.id_organization=iid_organization,
        sub.name_subdivision=iname_subdivision,
        sub.name_subdivision_kaz=iname_subdivision_kaz
    where sub.id_subdivision=iid_subdivision;
    commit;
    end subdivisions_upd;

    procedure subdivisions_del(iid_subdivision number)
    as
    begin
    update subdivisions sub
    set sub.active='N'
    where sub.id_subdivision=iid_subdivision;
    commit;
    end subdivisions_del;

    procedure theme_bundle_new(iid_bundle_theme number, iname_theme_bundle varchar2, iname_theme_bundle_kaz varchar2, idescr varchar2)
    as
    begin
    insert into theme_bundle (id_bundle_theme, active, name_theme_bundle, name_theme_bundle_kaz, descr)
    values(iid_bundle_theme, 'Y', iname_theme_bundle, iname_theme_bundle_kaz, idescr);
    commit;
    end theme_bundle_new;

    procedure theme_bundle_upd(iid_bundle_theme number, iactive char, iname_theme_bundle varchar2, iname_theme_bundle_kaz varchar2, idescr varchar2)
    as
    begin
    update theme_bundle tb
    set tb.active=iactive,
        tb.name_theme_bundle=iname_theme_bundle,
        tb.name_theme_bundle_kaz=iname_theme_bundle_kaz,
        tb.descr=idescr
    where tb.id_bundle_theme=iid_bundle_theme;
    commit;
    end theme_bundle_upd;

    procedure theme_bundle_del(iid_bundle_theme number)
    as
    begin
    update theme_bundle tb
    set tb.active='N'
    where tb.id_bundle_theme=iid_bundle_theme;
    commit;
    end theme_bundle_del;

    procedure themes_new(iid_theme number, idescr varchar2, idescr_kaz varchar2)
    as
    begin
    insert into themes (id_theme, active, descr, descr_kaz)
    values(iid_theme, 'Y', idescr, idescr_kaz);
    commit;
    end themes_new;

    procedure themes_upd(iid_theme number, iactive char, idescr varchar2, idescr_kaz varchar2)
    as
    begin
    update themes th
    set th.active=iactive,
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
