create or replace package test_operator.tester as

  /* TODO enter package declarations (types, exceptions, methods etc) here */
procedure beginTest(iid_registration in number, iiip_addr in varchar2, omess out nvarchar2);
procedure check_Session(iid_registration in number, iiip_addr in varchar2, omess out nvarchar2);
procedure checkEndTheme(iid_registration in number, status out char, omess out nvarchar2);
procedure endTheme( iid_registration in number,  oname_theme out varchar2 );
procedure setCurrentTheme( iid_registration in number,  iid_theme in number );

procedure login(ilogin varchar2,
          ipasswd in varchar2,
          iip_addr in varchar2,
          oid_registration out number,
          oname out varchar2,
          olang out varchar2,
          omess out varchar2);

procedure save_answer(
  idirection in varchar2 default 'N',
  iid_registration in number,
  iid_reply in number,
  oend_theme out char,
  onew_name_theme out varchar2);

procedure getQuestion( iid_registration in number,
                 oorder_num out number,
                 ocount_question out number,
                 oid_reply  out number,
                 oquestion  out varchar2,
                 oremain_time out number,
                 oused_time   out number);

procedure getInfo(iid_registration in number,
          ocategory     out varchar2);

procedure calculateResult(iid_registration in number);
function gotoThemeByNumber(iid_registration in number, inumber_theme in number, inumber_question in number) return simple_integer;
procedure gotoFirstQuestion(iid_registration in number, onew_name_theme out nvarchar2);
procedure gotoLastQuestion(iid_registration in number, onew_name_theme out nvarchar2);
procedure setTypeDirection(iid_registration in number, itype_dir in char);
procedure getTypeDirection(iid_registration in number, itype_dir out char);

end tester;
/

create or replace package body test_operator.tester as

procedure beginTest(iid_registration in number, iiip_addr in varchar2, omess out nvarchar2)
is
v_beg_time timestamp;
v_id_pc         simple_integer:=0;
v_id_region     simple_integer:=0;
begin
  begin
    select lw.id_pc, lw.id_region
    into v_id_pc, v_id_region
    from SECMGR.list_workstation lw
    where lw.ip_addr=iiip_addr;
  exception when no_data_found then
    begin
        omess:='���������, � ��� �������� � ���� ...';
        secmgr.sec_ctx.set_userinfo(
                username=>helper.getfiobyidreg(iid_registration),
                id_person=>helper.getidpersonbyidreg(iid_registration),
                iip_addr=>iiip_addr,
                id_region=>v_id_region );
        secmgr.sec_ctx.log(5, iappname=>'Tester',
            ioperation=>'������ ������������',
            imodule=>'beginTest',
            imessage=> '������� ����� � ��������������������� ������, �� �������.: '||iid_registration );
        return;
    end;
  end;

  select r.beg_time_testing
  into v_beg_time
  from test_operator.registration r
  where r.id_registration=iid_registration;

  secmgr.sec_ctx.set_userinfo(
            username=>helper.getfiobyidreg(iid_registration),
            id_person=>helper.getidpersonbyidreg(iid_registration),
            iip_addr=>iiip_addr,
            id_region=>v_id_region );

  if v_beg_time is null
  then
    update test_operator.registration r
    set r.beg_time_testing=systimestamp,
        r.id_pc=v_id_pc,
        r.status='��� ������������'
    where r.id_registration=iid_registration;

    update test_operator.testing t
    set t.last_time_access=systimestamp,
        t.type_direction=0,
        t.used_time=0,
        t.status='��� ������������'
    where t.id_registration=iid_registration;
    secmgr.sec_ctx.log( iDebug=>4,
        iappname=>'Tester',
        ioperation=>'������ ������������',
        imodule=>'beginTest',
        imessage=> 'id_regisration: '||iid_registration );
  end if;
  commit;
end beginTest;

procedure check_Session(iid_registration in number, iiip_addr in varchar2, omess out nvarchar2)
is
v_beg_time timestamp;
v_id_region simple_integer:=0;
v_id_pc     simple_integer:=0;
v2_id_pc    simple_integer:=0;
begin
    begin
        select lw.id_pc, lw.id_region
        into v_id_pc, v_id_region
        from SECMGR.list_workstation lw
        where lw.ip_addr=iiip_addr;
    exception when no_data_found then
        begin
            omess:='���������, ������� � ��� �������� � ���� ...';
            secmgr.sec_ctx.set_userinfo(
                username=>helper.getfiobyidreg(iid_registration),
                id_person=>helper.getidpersonbyidreg(iid_registration),
                iip_addr=>iiip_addr,
                id_region=>v_id_region );
            secmgr.sec_ctx.log(iDebug=>5,
                iappname=>'Tester',
                ioperation=>'�������� IP ������',
                imodule=>'check_Session',
                imessage=> '������� �������������������� ������� � ��������������������� ������: '||
                iiip_addr||', id_registration: '||iid_registration );
            return;
        end;
    end;
    secmgr.sec_ctx.set_userinfo(
        username=>helper.getfiobyidreg(iid_registration),
        id_person=>helper.getidpersonbyidreg(iid_registration),
        iip_addr=>iiip_addr,
        id_region=>v_id_region );
    begin
        select id_pc into v2_id_pc
        from test_operator.registration r
        where r.id_registration=iid_registration;
    exception when no_data_found then
        begin
            omess:='���������, ������� � ��� �������� � ���� ...';
            secmgr.sec_ctx.log(5, iappname=>'Tester',
                ioperation=>'�������� IP ������',
                imodule=>'check_Session',
                imessage=> '������� �������������������� ������� ��� ����������� � ������: '||
                iiip_addr||', id_registration: '||iid_registration );
        end;
    end;

  if v2_id_pc!=v_id_pc then
        omess:='���������, ������� � ��� �������� � ���� ...';
        secmgr.sec_ctx.log('Tester','�������� IP ������','check_Session',
            '������� �������������������� ������� � ������: '||
            iiip_addr||', id_registration: '||iid_registration ||
            helper.getfiobyidreg(iid_registration) );

            secmgr.sec_ctx.log(5, iappname=>'Tester',
                ioperation=>'�������� IP ������',
                imodule=>'check_Session',
                imessage=> '������� �������������������� ������� � ������: '||
                iiip_addr||', id_registration: '||iid_registration );
        return;
  end if;
  omess:='';
end check_Session;

function getIdPc(iip_addr in varchar2, iid_region pls_integer) return number
is
v_id_pc secmgr.list_workstation.id_pc%type;
begin
    select id_pc
    into v_id_pc
    from  secmgr.list_workstation lw
    where lw.ip_addr=iip_addr
    and   lw.id_region=iid_region
    and   lw.active='Y'
    and   lw.type_device='C'; -- Computer
    secmgr.sec_ctx.log(0, iappname=>'Tester',
        ioperation=>'��������� �� ������� �������',
        imodule=>'getIdPc',
        imessage=> '' );
    return v_id_pc;
    exception when no_data_found then return 0;
end getIdPc;

function usedSecond(p1 timestamp, p2 timestamp) return pls_integer
is
used_second pls_integer;
begin
  if ( extract( day from p1) != extract( day from p2) )
  then
    return 0;
  end if;
  used_second:= (extract(hour from p2) - extract(hour from p1))*3600 +
                 (extract( minute from p2) - extract( minute from p1))*60 +
                  extract( second from p2) - extract( second from p1);
    secmgr.sec_ctx.log(0, iappname=>'Tester',
        ioperation=>'������ ����������� �������',
        imodule=>'usedSecond',
        imessage=> '������������ ���.: '||used_second );
  return used_second;
end usedSecond;

function isBundleGroup(iid_registration  in number ) return char
is
v_is_groups char(1);
begin
  select b.is_groups
  into v_is_groups
  from test_operator.registration r, test_operator.bundle b
  where r.id_bundle=b.id_bundle
  and   r.id_registration=iid_registration;

  return v_is_groups;
  exception when no_data_found then return 'U';
end isBundleGroup;

procedure getBundlePeriod(iid_registration  in number,
  operiod_for_testing out number,
  oused_time out number,
  ois_groups out char
  )
is
v_is_groups char(1);
v_period simple_integer:=0;
begin
  ois_groups:=isBundleGroup(iid_registration);

  if ois_groups='Y' then
     select period_for_testing, used_time
     into operiod_for_testing, oused_time
     from test_operator.testing t
     where t.id_registration=iid_registration;
  end if;
end getBundlePeriod;

procedure getBundleCompositionPeriod(iid_registration  in number,
  operiod_for_testing out number,
  oused_time out simple_integer,
  ogroup  out char
  )
is
v_is_groups char(1);
v_period simple_integer:=0;
begin
    select uc.is_groups,
          case when uc.is_groups='Y'
                then ( select bc.used_time
                       from   test_operator.users_bundle_config bc
                       where bc.id_registration=ts.id_registration
                       and   bc.id_param=uc.id_param )
                else uc.used_time
           end as used_time,
          case when uc.is_groups='Y'
                then ( select bc.period_for_testing
                       from   test_operator.users_bundle_config bc
                       where bc.id_registration=ts.id_registration
                       and   bc.id_param=uc.id_param )
                else uc.period_for_testing
           end as period_for_testing
    into  ogroup, oused_time, operiod_for_testing
    from  test_operator.testing ts,
          test_operator.users_bundle_composition uc
    where uc.id_registration=ts.id_registration
    and   uc.id_theme=ts.id_current_theme
    and   ts.id_registration=iid_registration;

end getBundleCompositionPeriod;

procedure getRemainTime(iid_registration  in number,
      operiod_for_testing out number,
      oused_time out number,
      oremain_time out number,
      ogroup out char)
is
v_is_groups char(1);
v_period_for_testing    number;
v_used_time             number;
v_remain_time           simple_integer:=0;
begin
  getBundlePeriod(iid_registration, v_period_for_testing, v_used_time, v_is_groups);
  if v_is_groups='Y' then
     ogroup:='B';
  else
    getBundleCompositionPeriod(iid_registration,  v_period_for_testing, v_used_time, ogroup );
  end if;

  operiod_for_testing:=coalesce(v_period_for_testing,0);
  oused_time:=coalesce(v_used_time,0);
  oremain_time:=v_period_for_testing-oused_time;
end getRemainTime;

procedure setCurrentTheme( iid_registration in number,  iid_theme in number )
is
v_id_theme pls_integer;
v_status    varchar2(64);
v_beg_time_testing timestamp;
begin
/* 22.08.2013
    select r.status, r.beg_time_testing
    into v_status, v_beg_time_testing
    from test_operator.registration r
    where r.id_registration=iid_registration;
*/
    secmgr.sec_ctx.log(0, iappname=>'Tester',
        ioperation=>'��������� ������� ����',
        imodule=>'setCurrentTheme',
        imessage=> '�� �������.: '|| iid_registration ||', �� ����: '|| iid_theme);

    update test_operator.testing ts
    set ts.id_current_theme=iid_theme
    where  ts.id_registration=iid_registration;

    commit;
end setCurrentTheme;

function getCurrentTheme(iid_registration in number)
 return simple_integer
is
v_id_current_theme  simple_integer:=0;
begin
    select t.id_current_theme
    into    v_id_current_theme
    from test_operator.testing t
    where t.id_registration=iid_registration;
    secmgr.sec_ctx.log(2, iappname=>'Tester',
        ioperation=>'��������� �� ����',
        imodule=>'getCurrentTheme',
        imessage=> '�� �������.: '|| iid_registration ||', �� ����: '|| v_id_current_theme);
  return v_id_current_theme;
end getCurrentTheme;

function getNameTheme(iid_theme in number)
 return varchar2
is
v_name_theme  nvarchar2(256);
begin
    select case when sys_context('sec_ctx','language') in ('kk','kz')
              then t.descr_kaz
              else t.descr
         end as name_theme
    into    v_name_theme
    from test_operator.tasks t
    where t.id_theme=iid_theme;
    secmgr.sec_ctx.log(2, iappname=>'Tester',
        ioperation=>'��������� �������� ����',
        imodule=>'getNameTheme',
        imessage=> '�� ����: '|| iid_theme);
    return v_name_theme;
end getNameTheme;

--����������� ��� ��������� �������
procedure nextTheme( iid_registration in number,
                     oend_theme out char,
                     onew_name_theme out varchar2
)
is
v_id_current_theme  simple_integer:=0;
v_theme_number      pls_integer;
v_id_theme          pls_integer;
v_id_next_theme     pls_integer;
v_count_question    simple_integer:=0;
v_is_group          char;
v_is_next_group     char;
begin
  --Get Current theme
--  SECMGR.sec_ctx.log('nextTheme: iid_registration: '||iid_registration);
  v_id_current_theme:=getCurrentTheme(iid_registration);

  select *
  into v_id_theme, v_id_next_theme, v_is_group, v_is_next_group
  from (
    select  uc.id_theme,
            lead(id_theme) over (order by theme_number, is_groups) next_id,
            uc.is_groups,
            lead(is_groups) over (order by theme_number, is_groups) next_is_group
    from  test_operator.users_bundle_composition uc
    where uc.id_registration=iid_registration
    and   uc.status_testing!='��������'
  )
  where id_theme=v_id_current_theme;


  if v_is_group='N' or v_is_group!=v_is_next_group or v_id_next_theme is null
  then
    oend_theme:='Y';
  else
    oend_theme:='N';
  end if;

  if v_id_next_theme is not null
  then
    onew_name_theme:=exclude_sharp(getNameTheme(v_id_next_theme));

    select uc.count_question
    into v_count_question
    from  test_operator.users_bundle_composition uc
    where uc.id_registration=iid_registration
    and   uc.id_theme=v_id_next_theme;

    update test_operator.testing t
    set   t.id_current_theme=v_id_next_theme,
          t.current_question_num=1,
          t.count_question=v_count_question
    where t.id_registration=iid_registration;
    commit;
    secmgr.sec_ctx.log(2, iappname=>'Tester',
        ioperation=>'������� �� ����� ����',
        imodule=>'nextTheme',
        imessage=> '�� ����� ����: '||v_id_next_theme||
        ', �������� � ����: '||v_count_question );
  end if;
  exception when no_data_found then null;
end nextTheme;

--����������� ��� ��������� �������
procedure prevTheme( iid_registration in number,
                    oend_theme out char,
                    onew_name_theme out varchar2
)
is
v_id_current_theme  simple_integer:=0;
v_theme_number      pls_integer;
v_id_theme          pls_integer;
v_id_next_theme     pls_integer;
v_count_question    simple_integer:=0;

v_is_group          char;
v_is_next_group     char;
v_end_theme         char;
begin
  v_id_current_theme:=getCurrentTheme(iid_registration);

  select *
  into v_id_theme, v_id_next_theme, v_is_group, v_is_next_group
  from (
    select  uc.id_theme,
            lag(id_theme) over (order by theme_number, is_groups) next_id,
            uc.is_groups,
            lag(is_groups) over (order by theme_number, is_groups) next_is_group
    from  test_operator.users_bundle_composition uc
    where uc.id_registration=iid_registration
    and   uc.status_testing!='��������'
  )
  where id_theme=v_id_current_theme;

  if v_is_group='N' or v_is_group!=v_is_next_group or v_id_next_theme is null
  then
    oend_theme:='Y';
  else
    oend_theme:='N';
  end if;

  if v_id_next_theme is not null
  then
    onew_name_theme:=exclude_sharp(getNameTheme(v_id_next_theme));

    select uc.count_question
    into v_count_question
    from  test_operator.users_bundle_composition uc
    where uc.id_registration=iid_registration
    and   uc.id_theme=v_id_next_theme;

    update test_operator.testing t
    set   t.id_current_theme=v_id_next_theme,
            t.count_question=v_count_question,
            t.current_question_num=v_count_question
    where t.id_registration=iid_registration;
    commit;
    secmgr.sec_ctx.log(2, iappname=>'Tester',
        ioperation=>'������� �� ���������� ����',
        imodule=>'prevTheme',
        imessage=> '�� ����: '||v_id_next_theme||
        ', �������� � ����: '||v_count_question );
  end if;
  exception when no_data_found then null;
end prevTheme;

function calculateResultTheme(iid_registration in number, iid_theme in number)
return pls_integer
is
counter    pls_integer;
begin
  select count(r.correctly)
  into counter
  from  test_operator.questions_for_testing qt,
        test_operator.replies r
  where qt.id_registration=iid_registration
  and   qt.id_theme=iid_theme
  and   qt.id_reply=r.id_reply
  and   r.correctly='Y';
    secmgr.sec_ctx.log(1, iappname=>'Tester',
        ioperation=>'������ ���������� �� ����',
        imodule=>'calculateResultTheme',
        imessage=> '�� �������.: '||iid_registration ||
                    ', �� ����: '||iid_theme ||
                    ', ���������: '||counter);
  return counter;
end calculateResultTheme;

procedure calculateResult(iid_registration in number)
is
counter    simple_integer:=0;
all_counter    simple_integer:=0;
is_fail    boolean;
hash_result nvarchar2(128);
v_min_point     simple_integer:=0;
begin
  is_fail:=false;
  counter:=0;
--  SECMGR.sec_ctx.log('calculateResult: id_registration: '||iid_registration);
    secmgr.sec_ctx.log(3, iappname=>'Tester',
        ioperation=>'������ ���������� �� ����',
        imodule=>'calculateResult',
        iid_registration=>iid_registration,
        imessage=> '������ �������');
        secmgr.ctl.second_check(iid_registration);


  for cur in (  select uc.id_theme, uc.count_success
                from  test_operator.users_bundle_composition uc
                where uc.id_registration=iid_registration
             )
  loop
      counter:=calculateResultTheme(iid_registration, cur.id_theme);
      all_counter:=all_counter+counter;
      -- ��� ����������� ������ ������ �� ���� �����
--      if counter<cur.count_success
--      then
--        is_fail:=true;
--      end if;
      update test_operator.users_bundle_composition uc
      set    uc.scores=counter
      where   uc.id_registration=iid_registration
      and     uc.id_theme=cur.id_theme;
  end loop;

    if is_fail=true
    then
        secmgr.sec_ctx.log(5, iappname=>'Tester',
            ioperation=>'���� �� �������',
            imodule=>'calculateResult',
            imessage=> 'is_Fail=true, id_registration: '||iid_registration);
        update test_operator.registration r
        set     r.status='�� �������'
        where   r.id_registration=iid_registration;
    else
        select b.min_point
        into v_min_point
        from test_operator.bundle b,
             test_operator.registration r,
             m_assignment_bundle m
        where r.id_registration=iid_registration
        and   m.id_bundle=b.id_bundle
        and   r.id_assignment=m.id_assignment;
        if v_min_point=0 or (v_min_point>0 and all_counter>=v_min_point)
        then
            secmgr.sec_ctx.log(5, iappname=>'Tester',
                ioperation=>'���� �������',
                imodule=>'calculateResult',
                imessage=> '�� �������.: '||iid_registration||
                        ', ��������� ����: '||v_min_point||', �������: '||all_counter);
            update test_operator.registration r
            set     r.status='�������'
            where   r.id_registration=iid_registration;
        else
            secmgr.sec_ctx.log(5, iappname=>'Tester',
                ioperation=>'���� �� �������',
                imodule=>'calculateResult',
                imessage=> 'is_Fail=false. �� �������.: '||iid_registration||
                        ', ��������� ����: '||v_min_point||', �������: '||all_counter);
            update test_operator.registration r
            set     r.status='�� �������'
            where   r.id_registration=iid_registration;
        end if;
    end if;
    hash_result:=secmgr.sec_ctx.getHashResult(iid_registration);
    update test_operator.registration r
    set     r.signature=hash_result
    where   r.id_registration=iid_registration;
  commit;
end calculateResult;

procedure checkEndTheme(iid_registration in number, status out char, omess out nvarchar2)
is
v_question_count simple_integer:=0;
v_current_question_num simple_integer:=0;
v_first_num simple_integer:=0;
v_theme_number  simple_integer:=0;
v_id_theme  simple_integer:=0;
v_is_groups char(1);
v_id_param  pls_integer;
v_name_theme    nvarchar2(512);
v_lang          test_operator.registration.language%type;
len_omess       simple_integer:=1024;
begin
    status:='N';
    v_lang:=helper.get_language(iid_registration);
    omess:='';
    select  t.count_question, t.current_question_num, uc.is_groups, uc.id_param
    into    v_question_count, v_current_question_num, v_is_groups, v_id_param
    from test_operator.testing t, test_operator.users_bundle_composition uc
    where t.id_registration=iid_registration
    and     t.id_registration=uc.id_registration
--    and     t.current_theme_number=uc.theme_number
    and     t.id_current_theme=uc.id_theme;
-- �� ��������� �������� �������
    if v_question_count=v_current_question_num and v_id_param is null
       and isBundleGroup(iid_registration)!='Y'
    then
        status:='Y';
        for cur in ( select qt.order_num_question
                     from test_operator.questions_for_testing qt,
                            test_operator.testing t
                     where t.id_registration=iid_registration
                     and   t.id_registration= qt.id_registration
                     and   t.id_current_theme=qt.id_theme
                     and   qt.id_reply is null )
        loop
            if v_first_num=0 then
                v_first_num:=cur.order_num_question;
                omess:='�� �������� �������: �'||cur.order_num_question;
                update test_operator.testing t
                set     t.current_question_num=cur.order_num_question
                where t.id_registration=iid_registration;
                commit;
            else
                if length(omess)<len_omess
                then
                   omess:=omess||', �'||cur.order_num_question;
                end if;
            end if;
        end loop;
    end if;
-- ��������� �������� �������
    v_name_theme:='';
    if v_question_count=v_current_question_num
    and ( v_id_param is not null or isBundleGroup(iid_registration)='Y')
    then
        status:='Y';
        for cur in ( select qt.order_num_question,
                        uc.theme_number, uc.count_question, qt.id_theme,
                        case when v_lang in ('kk','kz')
                                  then th.descr_kaz
                             else th.descr end descr
                     from test_operator.questions_for_testing qt,
                            test_operator.users_bundle_composition uc,
                            TEST_OPERATOR.tasks th
                     where uc.id_registration=iid_registration
                     and   uc.id_registration= qt.id_registration
                     and   uc.id_theme=qt.id_theme
                     and   uc.id_theme=th.id_theme
                     and   qt.id_reply is null
                     order by uc.theme_number, qt.order_num_question)
        loop
            if v_name_theme is null or v_name_theme!=exclude_sharp(cur.descr) then
                if v_name_theme is null then
                    omess:='������� ������������ ������� �� �����: <br><b>'||exclude_sharp(cur.descr)||'</b>:';
                else
                    if length(omess)<len_omess
                    then
                       omess:=omess||'<br><b>'||exclude_sharp(cur.descr)||'</b>:';
                    end if;
                end if;
                v_name_theme:=exclude_sharp(cur.descr);
            end if;
            if v_first_num=0 then
                v_first_num:=cur.order_num_question;
                update test_operator.testing t
                set     t.current_question_num=cur.order_num_question,
                        t.current_theme_number=cur.theme_number,
                        t.count_question=cur.count_question,
                        t.id_current_theme=cur.id_theme
                where t.id_registration=iid_registration;
                commit;
            end if;
            omess:=omess||'  �'||cur.order_num_question;
        end loop;
    end if;
    secmgr.sec_ctx.log(3, iappname=>'Tester',
        ioperation=>'�������� ����������� �������',
        imodule=>'checkEndTheme',
        imessage=> rtrim(substr(omess,1,256) ));
end checkEndTheme;

procedure endTheme( iid_registration in number,  oname_theme out varchar2 )
is
v_is_group char;
v_id_theme          pls_integer;
v_id_next_theme     pls_integer;
v_count_question       simple_integer:=0;
begin
  select b.is_groups
  into v_is_group
  from test_operator.registration r, test_operator.bundle b
  where r.id_bundle=b.id_bundle
  and   r.id_registration=iid_registration;

  if v_is_group='Y' then
    update test_operator.users_bundle_composition uc
    set    uc.status_testing='��������'
    where   uc.id_registration=iid_registration;
  else
    v_id_theme:=getCurrentTheme(iid_registration);
--SECMGR.sec_ctx.log('endTheme: v_id_theme: '||v_id_theme);
    select uc.is_groups
    into   v_is_group
    from    test_operator.users_bundle_composition uc
    where   uc.id_registration=iid_registration
    and     uc.id_theme=v_id_theme;

    if v_is_group='N' then
      update test_operator.users_bundle_composition uc
      set    uc.status_testing='��������'
      where   uc.id_registration=iid_registration
      and     uc.id_theme=v_id_theme;
    else
      update test_operator.users_bundle_composition uc
      set    uc.status_testing='��������'
      where   uc.id_registration=iid_registration
      and     v_is_group='Y';
    end if;
  end if;

  commit;

  secmgr.sec_ctx.log(iDebug=>3,
            iappname=>'Tester',
            ioperation=>'������� �� ����� ����',
            imodule=>'endTheme',
            imessage=> '��������� ����. �� �������.: '||iid_registration||
                    ', �� ����: '||v_id_theme
             );
  begin
    select t.next_id, t.count_question
    into v_id_next_theme, v_count_question
    from (
      select uc.id_theme as next_id, uc.count_question
      from  test_operator.users_bundle_composition uc
      where uc.id_registration=iid_registration
      and   uc.status_testing!='��������'
      order by uc.theme_number
    ) t
    where rownum=1;
    exception when no_data_found then
      begin
        secmgr.sec_ctx.log(iDebug=>3,
            iappname=>'Tester',
            ioperation=>'������� �� ����� ����',
            imodule=>'endTheme',
            imessage=> '������������ ���������.'||
            ', �� �������.: '||iid_registration ||
            ', �� ����: '||v_id_theme
            );

        oname_theme:='';
        update test_operator.registration r
        set r.end_time_testing=systimestamp
        where r.id_registration=iid_registration;

        update test_operator.testing t
        set   t.status='������������ ���������'
        where t.id_registration=iid_registration;

        calculateResult(iid_registration);
        return;
      end;
  end;
  secmgr.sec_ctx.log(iDebug=>1,
        iappname=>'Tester',
         ioperation=>'������� �� ����� ����',
         imodule=>'endTheme',
         imessage=> '����� ����. '||
         '�� �������.: '||iid_registration ||
         ', �� ����: '||v_id_next_theme||
         ', ����� ��������: '||v_count_question );
  select
       case when sys_context('sec_ctx','language') in ('kk','kz')
            then tm.descr_kaz
            else tm.descr
       end as name_theme
  into  oname_theme
  from  test_operator.tasks tm
  where tm.id_theme=v_id_next_theme;
--  SECMGR.sec_ctx.log('endTheme: select next name theme');
  update test_operator.testing t
  set t.id_current_theme=v_id_next_theme,
        t.current_question_num=1,
        t.current_theme_number=t.current_theme_number+1,
        t.count_question=v_count_question
  where t.id_registration=iid_registration;
  commit;
end endTheme;

function nextQuestion (
  iid_registration in number,
  iid_theme     in number,
  iorder_num    in number,
  itime_remain  in pls_integer,
  onew_name_theme out varchar2
) return char
is
v_all_question pls_integer;
v_end_theme char;
v_is_group  char;
begin
    v_end_theme:='N';
    select  bc.count_question, bc.is_groups
    into    v_all_question, v_is_group
    from test_operator.users_bundle_composition bc
    where bc.id_registration=iid_registration
    and   bc.id_theme=iid_theme;

    secmgr.sec_ctx.log(iDebug=>1,
            iappname=>'Tester',
            ioperation=>'������� �� ����� ������',
            imodule=>'nextQuestion',
            imessage=> '�� �������.: '||iid_registration ||', '||
            '�� ����: '||Iid_theme||
             ', ����� ��������: '||v_all_question||', ����� �������: '||iorder_num||
             ', ������� �������: '||itime_remain );

    if( v_all_question>iorder_num and itime_remain>0 )
    then
/* 22.08.2013 ��������
      update test_operator.users_bundle_composition u
      set u.order_num=iorder_num+1
      where u.id_registration=iid_registration
      and u.id_theme=iid_theme;
--*/
      update test_operator.testing t
      set t.current_question_num=iorder_num+1
      where t.id_registration=iid_registration;
    else
      if v_is_group!='Y' or itime_remain=0 then
        v_end_theme:='Y';
      else
        nextTheme(iid_registration,v_end_theme,onew_name_theme);
      end if;
    end if;
--    SECMGR.sec_ctx.log('nextQuestion: v_end_theme: '||v_end_theme);
    return v_end_theme;
end nextQuestion;

function nextQuestionNoAnswer (
  iid_registration in number,
  iid_theme     in number,
  iorder_num    in number,
  itime_remain  in pls_integer,
  onew_name_theme out varchar2
) return char
is
v_all_question simple_integer:=0;
v_order_num_question simple_integer:=0;
v_end_theme char;
v_is_group  char;
begin
    v_end_theme:='N';
    select  bc.count_question, bc.is_groups
    into    v_all_question, v_is_group
    from test_operator.users_bundle_composition bc
    where bc.id_registration=iid_registration
    and   bc.id_theme=iid_theme;

    secmgr.sec_ctx.log(iDebug=>5,
            iappname=>'Tester',
            ioperation=>'������� �� ����� ������',
            imodule=>'nextQuestionNoAnswer',
            imessage=> '�� �������.: '||iid_registration ||', '||
            '�� ����: '||Iid_theme||
             ', ����� ��������: '||v_all_question||', ����� �������: '||iorder_num||
             ', ������� �������: '||itime_remain );

    begin
      select order_num_question
      into v_order_num_question
      from (
        select qt.order_num_question
        from test_operator.questions_for_testing qt
            ,test_operator.testing t
        where qt.id_registration=iid_registration
        and   t.id_registration=qt.id_registration
        and   t.ID_CURRENT_THEME=qt.id_theme
        and   qt.id_reply is null
        and   qt.order_num_question>iorder_num
        order by qt.order_num_question
      ) a
      where rownum=1;
    exception when no_data_found then v_order_num_question:=v_all_question;
    end;

    if( v_all_question>v_order_num_question and itime_remain>0 )
    then
/* 22.08.2013 ��������
      update test_operator.users_bundle_composition u
      set u.order_num=iorder_num+1
      where u.id_registration=iid_registration
      and u.id_theme=iid_theme;
--*/
      update test_operator.testing t
      set t.current_question_num=v_order_num_question
      where t.id_registration=iid_registration;
    else
      if v_is_group!='Y' or itime_remain=0 then
        v_end_theme:='Y';
      else
        nextTheme(iid_registration,v_end_theme,onew_name_theme);
      end if;
    end if;
--    SECMGR.sec_ctx.log('nextQuestion: v_end_theme: '||v_end_theme);
    return v_end_theme;
end nextQuestionNoAnswer;

function prevQuestionNoAnswer (
  iid_registration in number,
  iid_theme       in number,
  iorder_num      in number,
  itime_remain    in pls_integer,
  onew_name_theme out varchar2
) return char
is
v_order_num_question simple_integer:=0;
v_end_theme char;
v_is_group  char;
begin
    v_end_theme:='N'; -- ���� ������ �� ����
    secmgr.sec_ctx.log( iDebug=>1,
            iappname=>'Tester',
            ioperation=>'������� �� ���������� ������',
            imodule=>'prevQuestionNoAnswer',
            imessage=> '�� �������.: '||iid_registration ||', '||
            '�� ����: '||Iid_theme||
            ', ����� �������: '||iorder_num||
            ', ������� �������: '||itime_remain );

    begin
      select order_num_question
      into v_order_num_question
      from (
        select qt.order_num_question
        from test_operator.questions_for_testing qt
            ,test_operator.testing t
        where qt.id_registration=iid_registration
        and   t.id_registration=qt.id_registration
        and   t.ID_CURRENT_THEME=qt.id_theme
        and   qt.id_reply is null
        and   qt.order_num_question<iorder_num
        order by qt.order_num_question desc
      ) a
      where rownum=1;
    exception when no_data_found then
            begin
            v_order_num_question:=0;
            secmgr.sec_ctx.log( iDebug=>1,
              iappname=>'Tester',
              ioperation=>'������� �� ���������� ������',
              imodule=>'prevQuestionNoAnswer',
              imessage=> '�� �������.: '||iid_registration ||', '||
              '�� ����: '||Iid_theme||
              ', ����� �������: '||iorder_num||
              ', v_order_num_question: '||v_order_num_question );
            end;
    end;

    if iorder_num>1 and v_order_num_question>0 and itime_remain>0 then
      update test_operator.users_bundle_composition u
      set u.order_num=v_order_num_question
      where u.id_registration=iid_registration
      and u.id_theme=iid_theme;

      update test_operator.testing t
      set t.current_question_num=v_order_num_question
      where t.id_registration=iid_registration;
    else
      if v_is_group!='Y' or itime_remain=0 then
        v_end_theme:='Y';
      else
        prevTheme(iid_registration,v_end_theme,onew_name_theme);
      end if;
    end if;
    return v_end_theme;
end prevQuestionNoAnswer;

function prevQuestion (
  iid_registration in number,
  iid_theme       in number,
  iorder_num      in number,
  itime_remain    in pls_integer,
  onew_name_theme out varchar2
) return char
is
v_end_theme char;
v_is_group  char;
begin
    v_end_theme:='N'; -- ���� ������ �� ����
    secmgr.sec_ctx.log( iDebug=>1,
            iappname=>'Tester',
            ioperation=>'������� �� ���������� ������',
            imodule=>'prevQuestion',
            imessage=> '�� �������.: '||iid_registration ||', '||
            '�� ����: '||Iid_theme||
            ', ����� �������: '||iorder_num||
            ', ������� �������: '||itime_remain );

    if iorder_num>1 and itime_remain>0 then
      update test_operator.users_bundle_composition u
      set u.order_num=iorder_num-1
      where u.id_registration=iid_registration
      and u.id_theme=iid_theme;

      update test_operator.testing t
      set t.current_question_num=iorder_num-1
      where t.id_registration=iid_registration;
    else
      if v_is_group!='Y' or itime_remain=0 then
        v_end_theme:='Y';
      else
        prevTheme(iid_registration,v_end_theme,onew_name_theme);
      end if;
    end if;
    return v_end_theme;
end prevQuestion;

-- refactored
procedure recalcUsedTime(
   iid_registration   IN number,
   v_id_current_theme IN OUT pls_integer,
   v_order_num        IN OUT pls_integer,
   otime_remain       OUT pls_integer
) as
v_is_group    char;
v_used_second pls_integer;
v_used_time   pls_integer;
v_used        pls_integer;
v_id_param    pls_integer;
v_current_time_stamp  timestamp;
v_last_time_access    timestamp;
v_period_for_testing  pls_integer;
begin
  select t.last_time_access, t.id_current_theme,
            t.current_question_num
  into v_last_time_access, v_id_current_theme, v_order_num
  from test_operator.testing t
  where t.id_registration = iid_registration
  and rownum=1;

-- ������� ��� ������������ ������� �� �������, ����� ����������
  getRemainTime(iid_registration, v_period_for_testing, v_used_time, otime_remain, v_is_group);
--
  select systimestamp into v_current_time_stamp from dual;
  v_used_second:= usedSecond(v_last_time_access, v_current_time_stamp);
  v_used:=v_used_second+v_used_time;
  if v_used>v_period_for_testing or v_used<0
  then
    v_used:=v_period_for_testing;
  end if;
--
  if v_is_group='N' or v_is_group='B'
  then
    update TEST_OPERATOR.testing t
    set t.used_time=v_used
    where t.id_registration=iid_registration;

    update TEST_OPERATOR.users_bundle_composition ub
    set ub.used_time=v_used
    where ub.id_registration=iid_registration
    and   ub.id_theme=v_id_current_theme;
  else
    update test_operator.users_bundle_config bc
    set   bc.used_time=v_used
    where bc.id_registration=iid_registration
    and   bc.id_param=v_id_param;
  end if;
  otime_remain:=v_period_for_testing-v_used;
    secmgr.sec_ctx.log( iDebug=>1,
            iappname=>'Tester',
            ioperation=>'������ ��������������� �������',
            imodule=>'recalcUsedTime',
            imessage=> '�� �������.: '||iid_registration ||
            ', �� ����: '||v_id_current_theme ||
            ', ������������: '||v_used ||
            ', ��������: '||otime_remain );
end;

procedure save_answer
(
  idirection in varchar2 default 'N',
  iid_registration in number,
  iid_reply in number,
  oend_theme out char,
  onew_name_theme out varchar2)
as
v_count_question number(16);
v_count_real_question pls_integer;
v_id_current_theme    pls_integer;
v_order_num           pls_integer;
v_id_param            pls_integer;
v_time_remain         pls_integer;
v_type_direction        pls_integer;
counter         simple_integer:=0;
begin
  if iid_reply is null and idirection is null
  then
    return;
  end if;
  recalcUsedTime( iid_registration, v_id_current_theme, v_order_num, v_time_remain );
  secmgr.sec_ctx.log( iDebug=>2,
            iappname=>'Tester',
            ioperation=>'���������� ������',
            imodule=>'save_answer',
            imessage=> '�� �������: '||iid_registration ||
            ', �����������: '||idirection||
            ', �� ������: '||iid_reply||
            ', ����� �������: '||v_order_num );
  if iid_reply is not null
  then
    update test_operator.questions_for_testing q
    set q.id_reply=iid_reply,
        q.time_reply=systimestamp
    where q.id_registration=iid_registration
    and q.id_theme=v_id_current_theme
    and q.order_num_question=v_order_num;
  end if;

--/* ������ ����� ��������� ������� ������
    select count(q.id_reply)
    into counter
    from test_operator.questions_for_testing q
    where q.id_registration=iid_registration
    and     q.id_reply=iid_reply;
    if counter>1 then
      secmgr.sec_ctx.log( iDebug=>5,
                iappname=>'Tester',
                ioperation=>'���������� ������',
                imodule=>'save_answer',
                imessage=> '������������ �������! �� �������. '||iid_registration ||
                ', �� ����: '||v_id_current_theme||
                ', ����� �������: '||v_order_num||
                ', �� ������: '||iid_reply );
        rollback;
        raise_application_error(-2000, '������������ �������!!<BR>���������� �����!');
    end if;
--*/

  /*GetTypeDirection (0 - all questions or 1 - not answered)*/
  select type_direction
  into v_type_direction
  from test_operator.testing t
  where t.id_registration=iid_registration;
  /* ------------------------------------------------------*/

  if(idirection='N')
  then
    if (v_type_direction = 0 or v_type_direction is null) then
        oend_theme:=nextQuestion( iid_registration,  v_id_current_theme, v_order_num, v_time_remain, onew_name_theme );
    else
        oend_theme:=nextQuestionNoAnswer( iid_registration,  v_id_current_theme, v_order_num, v_time_remain, onew_name_theme );
    end if;
  end if;

  if(idirection='P')
  then
    if (v_type_direction = 0 or v_type_direction is null) then
        oend_theme:=prevQuestion( iid_registration,  v_id_current_theme, v_order_num, v_time_remain, onew_name_theme );
    else
        oend_theme:=prevQuestionNoAnswer( iid_registration,  v_id_current_theme, v_order_num, v_time_remain, onew_name_theme );
    end if;
  end if;

  if(idirection='L')
  then
    gotoLastQuestion( iid_registration,  onew_name_theme );
    oend_theme:='N';
  end if;

  if(idirection='F')
  then
    gotoFirstQuestion( iid_registration,  onew_name_theme );
    oend_theme:='N';
  end if;

  update test_operator.testing t
  set t.last_time_access=systimestamp
  where t.id_registration = iid_registration;
  commit;
--/*
  secmgr.sec_ctx.log( iDebug=>2,
            iappname=>'Tester',
            ioperation=>'���������� ������',
            imodule=>'save_answer',
            imessage=> '����� ��������. �� �������: '||iid_registration ||
            ', �� ����: '||v_id_current_theme||
            ', �����������: '||idirection||
            ', �� ������: '||iid_reply||
            ', ����� �������: '||v_order_num||', ���������: '||substr(oend_theme,1,64)
             );
--*/
end save_answer;

procedure getQuestion( iid_registration in number,
                 oorder_num out number,
                 ocount_question out number,
                 oid_reply  out number,
                 oquestion  out varchar2,
                 oremain_time out number,
                 oused_time   out number)
is
v_period_for_testing number;
v_id_current_theme   number;
v_used_time          number;
v_remain_time        number;
v_id_param           number;
v_is_group           char;
begin

    select ts.id_current_theme,
           qt.order_num_question,
           qt.id_reply,
           q.question as question,
           ts.count_question,
           uc.id_param
    into  v_id_current_theme,
          oorder_num,
          oid_reply,
          oquestion,
          ocount_question,
          v_id_param
    from test_operator.testing ts,
    test_operator.questions_for_testing qt,
    test_operator.questions q,
    test_operator.users_bundle_composition uc
    where uc.id_registration=ts.id_registration
    and   uc.id_theme=ts.id_current_theme
    and   ts.current_question_num=qt.order_num_question
    and   ts.id_registration=qt.id_registration
    and   qt.id_theme=ts.id_current_theme
    and   qt.id_question=q.id_question
    and   ts.id_registration=iid_registration;

  getRemainTime(iid_registration, v_period_for_testing, v_used_time, v_remain_time, v_is_group);
  oremain_time:=v_remain_time;
  oused_time:=v_used_time;

  if v_period_for_testing <= v_used_time
  then
    oremain_time:=0;
    update test_operator.users_bundle_composition uc
    set    uc.status_testing='��������'
    where  uc.id_registration=iid_registration
    and    uc.id_theme=v_id_current_theme;
  end if;

  update TEST_OPERATOR.testing t
  set   t.last_time_access=systimestamp
  where t.id_registration=iid_registration;

  secmgr.sec_ctx.log( iDebug=>1,
            iappname=>'Tester',
            ioperation=>'������� �������� �������',
            imodule=>'getQuestion',
            imessage=> '����� �������. �� �������: '||iid_registration ||
            ', ����: '||v_id_current_theme||
            ', ����� �������: '||oorder_num ||
            ', �� ������: '||oid_reply );

exception when no_data_found then null;
end getQuestion;

procedure login( ilogin varchar2,
                 ipasswd in varchar2,
                 iip_addr in varchar2,
                 oid_registration out number,
                 oname out varchar2,
                 olang out varchar2,
                 omess out varchar2)
is
v_id_registration TEST_OPERATOR.registration.id_registration%type;
v_passwd          TEST_OPERATOR.persons.iin%type;
v_id_pc           number;
v_id_region       pls_integer;
v_id_person       pls_integer;
begin
  oid_registration:=0;
  omess:='';
--  olang:='ru';
--  select * from test_operator.registration r;
  helper.getFIOByIIN(ilogin,omess);
  if omess is null then
     omess:='�������� c ��� '||ilogin||' � ������� �����������';
     secmgr.sec_ctx.log(iDebug=>3, iappname=>'Tester',
            ioperation=>'�����������',
            imodule=>'login',
            imessage=> omess );
     return;
  end if;
  omess:='';
  begin
    select id_registration,  id_person, fio, iin, id_region, lang
    into  v_id_registration, v_id_person, oname, v_passwd, v_id_region, olang
    from (
      select r.id_registration, p.id_person,
             p.lastname||' '||p.name||' '||p.middlename as fio,
             p.iin,
             r.id_region,
             r.language as lang
      from  TEST_OPERATOR.persons p,
            TEST_OPERATOR.registration r
      where p.id_person=r.id_person
      and   p.iin=ilogin
      and (
        trunc(sysdate) >= trunc(r.date_testing)
        and
        trunc(sysdate) <= trunc(r.end_day_testing)
      )
      and r.status in ('�����','��� ������������', '������������ ������')
      order by r.date_testing desc
    ) where rownum=1;
  exception when no_data_found then
    olang:= case when olang is null then 'ru' else olang end;
    omess:='��� '||ilogin||' ������������ �� ���������';
    secmgr.sec_ctx.log(iDebug=>4, iappname=>'Tester',
            ioperation=>'�����������',
            imodule=>'login',
            imessage=> omess );
    return;
  end;

  v_id_pc:=helper.getIdPc(iip_addr);
--  raise_application_error(-20001, 'v_id_pc: '||v_id_pc);
  secmgr.sec_ctx.set_userinfo(username=> ilogin,
        id_person=>v_id_person,
        iip_addr=>iip_addr,
        id_region=>v_id_region );

  olang:= case when olang is null then 'ru' else olang end;
  secmgr.sec_ctx.set_language(olang);
--
  if ipasswd!=v_passwd then
    omess:='����� �������� ������';
     secmgr.sec_ctx.log(iDebug=>3, iappname=>'Tester',
            ioperation=>'�����������',
            imodule=>'login',
            imessage=> omess );
    return;
  end if;
--/*
  v_id_pc:=getIdPc(iip_addr, v_id_region);
  if v_id_pc>0
  then
    update test_operator.registration r
    set r.status='������������ ������',
        r.id_pc=v_id_pc
    where r.id_registration=v_id_registration;
  else
    omess:='������� ������ ������������ � �������������� ������ '||iip_addr;
    secmgr.sec_ctx.log(iDebug=>5,
            iappname=>'Tester',
            ioperation=>'�����������',
            imodule=>'login',
            imessage=> omess);
    return;
  end if;
--*/
   secmgr.sec_ctx.log(iDebug=>4,
            iappname=>'Tester',
            ioperation=>'�����������',
            imodule=>'login',
            imessage=> '������������ ������');
  commit;

  oid_registration:=v_id_registration;
  exception when no_data_found then return;
end login;

procedure getInfo(iid_registration in number,
          ocategory     out varchar2
)
is
v_lang registration.language%type;
v_id_assignment registration.id_assignment%type;
v_id_bundle     bundle.id_bundle%type;
v_descr nvarchar2(256);
v_temp  nvarchar2(256);
pos pls_integer;
begin


 select r.language, r.id_assignment, m.id_bundle
 into v_lang, v_id_assignment, v_id_bundle
 from test_operator.registration r, test_operator.M_ASSIGNMENT_BUNDLE m
 where r.id_registration=iid_registration
 and   m.id_assignment=r.id_assignment
 and rownum=1;

 v_descr:=helper.getNameBundle(v_id_assignment);

 --��� ����������� ������� � ������ ���� ���������
  ocategory:=v_descr;
-- ocategory:=helper.exclude_sharp(v_descr);

 secmgr.sec_ctx.log(iDebug=>1,
            iappname=>'Tester',
            ioperation=>'����� ��������� �����',
            imodule=>'getInfo',
            imessage=> '���������: '||ocategory);
end getInfo;

function gotoThemeByNumber(iid_registration in number, inumber_theme in number, inumber_question in number)
return simple_integer
is
v_id_theme simple_integer:=0;
v_order_num simple_integer:=0;
v_count_question simple_integer:=0;
begin
  select bc.id_theme, bc.order_num, bc.count_question
  into   v_id_theme, v_order_num, v_count_question
  from test_operator.users_bundle_composition bc
  where bc.id_registration=iid_registration
  and   bc.theme_number=inumber_theme;

  update test_operator.testing t
  set   t.current_question_num= case when inumber_question=0 then v_order_num else inumber_question end,
        t.count_question=v_count_question,
        t.current_theme_number=inumber_theme,
        t.ID_CURRENT_THEME=v_id_theme
  where t.id_registration=iid_registration;

  commit;
  return v_id_theme;
end gotoThemeByNumber;

procedure gotoFirstQuestion(iid_registration in number, onew_name_theme out nvarchar2)
is
begin
  onew_name_theme:=exclude_sharp(helper.getNameTheme(gotoThemeByNumber(iid_registration,1,1)));
end gotoFirstQuestion;

procedure gotoLastQuestion(iid_registration in number, onew_name_theme out nvarchar2)
is
v_max_number_theme simple_integer:=0;
v_max_number_question simple_integer:=0;
v_id_theme simple_integer:=0;
begin
  select count_question, theme_number, id_theme
  into  v_max_number_question, v_max_number_theme, v_id_theme
  from
  (
    select bc.count_question, bc.theme_number, bc.id_theme
    from  users_bundle_composition bc
    where bc.id_registration=iid_registration
    order by bc.theme_number desc
  )
  where rownum=1;

  update test_operator.testing t
  set   t.current_question_num=v_max_number_question,
        t.count_question=v_max_number_question,
        t.current_theme_number=v_max_number_theme,
        t.ID_CURRENT_THEME=v_id_theme
  where t.id_registration=iid_registration;
  commit;
  onew_name_theme:=exclude_sharp(helper.getNameTheme(v_id_theme));
end gotoLastQuestion;


procedure setTypeDirection( iid_registration in number,  itype_dir in char )
is
v_id_theme pls_integer;
begin

    update test_operator.testing ts
    set ts.type_direction=itype_dir
    where  ts.id_registration=iid_registration;

    commit;
end setTypeDirection;

procedure getTypeDirection( iid_registration in number,  itype_dir out char )
is
v_type_dir pls_integer;
begin

    select type_direction
    into v_type_dir
    from test_operator.testing ts
    where  ts.id_registration=iid_registration;

    if v_type_dir is null then
        v_type_dir:=0;
    end if;

    itype_dir:=v_type_dir;
end getTypeDirection;

end tester;
/
