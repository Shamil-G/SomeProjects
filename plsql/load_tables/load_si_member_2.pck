create or replace package load_si_member_2 is

  -- Author  : ��������_�
  -- Created : 26.11.2019 10:43:24
  
  -- Purpose : ��� �������� ������������������ ������, ������������� �� ���� ������� - PAY_DATE
  -- ����������� ��� �������������� ���������: 
  -- 1. ������ ����������� ��������: make_member
  -- 2. ������� �� ������ ��� ������ �� ������� ����: make_member2 

  procedure make; 

end load_si_member_2;
/
create or replace package body load_si_member_2 is

  reload_from     date;
  reload_before   date;
  v_state         pls_integer default 0;
  v_last_success_date date;
  cmd             varchar2(1024); 
  cnt_rows        pls_integer default 0;
  week_day        pls_integer default 0;
  e_errm  varchar2(1024);
  v_action        varchar2(32);

  TYPE My_Cursor  IS REF CURSOR;  

  procedure log(iaction in varchar2, imsg in nvarchar2 := '');

  procedure log(iaction in varchar2, imsg in nvarchar2)
  is
  PRAGMA AUTONOMOUS_TRANSACTION;
  begin
    insert into log_load_tables values(CURRENT_TIMESTAMP, 'LOAD_SI_MEMBER_2', iaction, imsg);
    commit;
  end log;

  function set_days_reload(module_name in varchar2) return pls_integer
  is
  begin
    v_action:='SET_DAYS_RELOAD';
    dbms_application_info.set_module('LOAD_SI_MEMBER_2',v_action);
    
    select state, last_success_date, add_months(trunc(runtime,'MM'),-1)
    into v_state, v_last_success_date, reload_from
    from load_tables_status lt where upper(lt.table_name) = upper(module_name);
    return v_state;
  end;

  procedure init_log(itable_name in varchar2)
  is
  begin
    v_action:='INIT';
    dbms_application_info.set_module('LOAD_SI_MEMBER_2',v_action);

    Update load_tables_status t
    Set t.state = 1,
        t.beg_time = sysdate,        
        t.end_time = '',
        t.info='�������� ��������'
    Where t.table_name=itable_name;
    Commit;
    dbms_application_info.set_action('�������� ������� '||itable_name);
  end init_log;
  
  procedure stop_log(itable_name in varchar2)
  is
  begin
    v_action:='REBUILD INDEXE';
    dbms_application_info.set_module('LOAD_SI_MEMBER_2',v_action);

    update load_tables_status lt 
    set lt.state=0,
        lt.runtime=add_months(lt.runtime,1),
        lt.last_success_date=trunc(sysdate),
        lt.end_time=sysdate,
        lt.info=''
    where upper(lt.table_name) = upper(itable_name);
    commit;
  end;

  procedure rebuild_indexes (itable_name varchar2)
  is
  cmd varchar2(1024);
  begin
    v_action:='REBUILD INDEXE';
    dbms_application_info.set_module('LOAD_SI_MEMBER_2',v_action);
    
    log(itable_name, '�������� ����������� �������� ��� '||itable_name);

    FOR current_index IN
    (
        select * from 
        (
          SELECT 'ALTER INDEX '||INDEX_NAME||' REBUILD ONLINE PARALLEL' build_command, ui.index_name index_name
            FROM    user_indexes ui
            WHERE   status = 'UNUSABLE'
            and table_owner='SSWH'
            and table_name = itable_name
            and partitioned='NO' 
          UNION ALL
          SELECT 'ALTER INDEX '||index_name||' REBUILD PARTITION '||partition_name||' ONLINE PARALLEL', uip.index_name
            FROM    user_ind_PARTITIONS uip
            WHERE   status = 'UNUSABLE'
            and   index_name in (select index_name from all_indexes where table_name = itable_name)       
          UNION ALL
          SELECT 'ALTER INDEX '||index_name||' REBUILD SUBPARTITION '||subpartition_name||' ONLINE PARALLEL', uis.index_name
            FROM    user_ind_SUBPARTITIONS uis
            WHERE   status = 'UNUSABLE'
            and   index_name in (select index_name from all_indexes where table_name = itable_name)
        ) order by build_command
    )
    LOOP
      log('������������� ������: '||current_index.index_name,current_index.build_command);
      EXECUTE immediate current_index.build_command;
    END LOOP;    
    
    for cur in (select index_name,partition_name,status
                from user_ind_partitions ip
                where ip.status='UNUSABLE'
                and   index_name in (select index_name from all_indexes where table_name = itable_name)
                order by index_name )
    loop
      log('REBUILD PARTITION INDEX'||cur.index_name,cur.partition_name);
      cmd:= 'ALTER INDEX '||cur.index_name||' REBUILD PARTITION '||cur.partition_name||' ONLINE';
      execute immediate cmd;
    end loop;
    
    log(itable_name,'����������� �������� ��� '||itable_name||' ���������');
  end rebuild_indexes;

  function prepare_partition(dtab_name varchar2, icolumn_name in varchar2) 
    return pls_integer
  is
  begin
    v_action:='PREPARE_PARTITION';
    dbms_application_info.set_module('LOAD_SI_MEMBER_2',v_action);
    
    log ( dtab_name, '���������� ��������');
    -- �������� ���������� �������
    for global_index in (select index_name
          from all_indexes 
          where table_name = dtab_name
          and partitioned='NO' 
          and table_owner='SSWH'
        )
    loop
      log('��������� ���������� ������:'|| global_index.index_name );
      execute immediate 'alter index '||global_index.index_name||' unusable';
    end loop;
       
    -- �������� ������� ��������
    FOR part IN ( SELECT  table_name, partition_name, high_value,
                  partition_position
        FROM user_tab_partitions t
        WHERE TABLE_NAME = upper(dtab_name)
        order by partition_position desc
    )
    LOOP
      if  to_date( substr(part.high_value,11,10), 'yyyy-mm-dd' ) > trunc(reload_from,'YEAR')
      then
        -- ��������� ������������������ ������, ������������ SQLCODE
        -- ������� Truncate �������� ?
        log( '��������� ��������: ' ||part.partition_name);
        execute immediate 'alter table '||part.table_name||' modify partition '||part.partition_name||' unusable local indexes';
        if SQLCODE>0 then
            -- ������, ��� ����������� �������� ����� ������� �� ���������
            return 0;
        end if;
      else
        exit;
      end if;
    END LOOP;
    log ( dtab_name, '���������� �������� ���������');

    log ( '����� ����� ����������� ������ ', '������� ��������: '||upper(icolumn_name)||'" >= '||to_char(reload_from,'dd.mm.yyyy HH24:MI:SS'));
    return 1;
  end prepare_partition;


  --�������� Virtual_Doc_List
  procedure reload_member(iv_table in varchar2)
  is
  v_cnt pls_integer default 0;
  type si_member_t is record(
      sicid         NUMBER(11),
      pay_date      DATE,
      pay_date_gfss DATE,
      pay_month     DATE,
      p_rnn         CHAR(12),
      knp           CHAR(3),
      mhmh_id       NUMBER(11),
      pmdl_n        NUMBER(5),
      sum_pay       NUMBER,
      period        VARCHAR2(6),
      mzp           NUMBER(19,2),
      cnt_mzp       NUMBER,
      type_payer    NCHAR(1)
  );
  TYPE member_table IS TABLE OF si_member_t index by pls_integer;
  list_t_member member_table;
  l_index pls_integer default 0;
  all_member My_Cursor;
  begin
    v_action:='RELOAD_MEMBER';
    dbms_application_info.set_module('LOAD_SI_MEMBER_2',v_action);

/*    
    cmd:='SELECT * FROM si_member_2@crtr s '||
         'WHERE s.pay_date_gfss between '''||to_char(reload_from,'dd.mm.yyyy')||''' and  '''||last_day(reload_from)|| ''' '||
         'and s.pay_date between '''||to_char(add_months(reload_from,-1),'dd.mm.yyyy')||''' and  '''||last_day(reload_from)|| ''' ';
/*        
         
    cmd:='SELECT * FROM v_gfss_incoming_pay_s s '||
         'WHERE s.pay_date_gfss between '''||to_char(reload_from,'dd.mm.yyyy')||''' and  '''||last_day(reload_from)|| ''' '||
         'and s.pay_date between '''||to_char(add_months(reload_from,-1),'dd.mm.yyyy')||''' and  '''||last_day(reload_from)|| ''' ';

--    raise_application_error(-20000, ' reload_from:'||reload_from|| ' cmd: '|| cmd);
--*/
    cmd:='SELECT sicid, pay_date,pay_date_gfss, pay_month, '||
                'p_rnn, knp, mhmh_id, pmdl_n, sum_pay, period, '||
                'mzp, cnt_mzp, type_payer ' ||   
         'FROM v_load_si_member s '||
         'WHERE s.pay_date_gfss between '''||to_char(reload_from,'dd.mm.yyyy')||''' and  '''||last_day(reload_from)|| ''' '||
         'and s.pay_date between '''||to_char(add_months(reload_from,-1),'dd.mm.yyyy')||''' and  '''||last_day(reload_from)|| ''' ';

/*
    cmd:='SELECT sicid, pay_date,pay_date_gfss, pay_month, '||
                'p_rnn, knp, mhmh_id, pmdl_n, sum_pay, period, '||
                'mzp, cnt_mzp, type_payer ' ||    
         'FROM v_load_si_member s '||
         'WHERE s.pay_date_gfss >= '''||to_char(reload_from,'dd.mm.yyyy')||''' '||
         'and s.pay_date > '''||to_char(add_months(reload_from,-1),'dd.mm.yyyy')||''' ';
//*/
/*
    cmd:='SELECT sicid, pay_date,pay_date_gfss, pay_month, '||
                'p_rnn, knp, mhmh_id, pmdl_n, sum_pay, period, '||
                'mzp, cnt_mzp, type_payer ' ||  
         'FROM v_load_si_member s '||
         'WHERE s.pay_date_gfss = ''10.01.2020'' '||
         'and s.pay_date = ''09.01.2020'' ';
*/
    log('��������� ������ ���: '||iv_table, cmd);
    open all_member for cmd;
    log(iv_table,'�������� ��������� ������');
    cnt_rows:=0;
    v_cnt:=1;        
    
    dbms_application_info.set_module('LOAD_SI_MEMBER_2',v_action);
    
    loop
      begin
        fetch all_member bulk collect into list_t_member limit 16000;
        forall l_index in list_t_member.first .. list_t_member.last
            insert
            into si_member_2(
                  sicid,
                  pay_date,
                  pay_date_gfss,
                  pay_month,
                  p_rnn,
                  knp,
                  mhmh_id,
                  pmdl_n,
                  sum_pay,
                  period,
                  mzp,
                  cnt_mzp,
                  type_payer
                  )
            values( 
--                    list_t_vdl(l_index).pay_date_gfss, 
                    list_t_member(l_index).sicid,
                    list_t_member(l_index).pay_date, 
                    list_t_member(l_index).pay_date_gfss,
                    list_t_member(l_index).pay_month, 
                    list_t_member(l_index).p_rnn, 
                    list_t_member(l_index).knp, 
                    list_t_member(l_index).mhmh_id, 
                    list_t_member(l_index).pmdl_n, 
                    list_t_member(l_index).sum_pay, 
                    list_t_member(l_index).period, 
                    list_t_member(l_index).mzp, 
                    list_t_member(l_index).cnt_mzp,
                    list_t_member(l_index).type_payer
                   );
        cnt_rows:=cnt_rows+list_t_member.count;
        exit when all_member%NOTFOUND;
        if v_cnt > 20 then
          v_cnt:=0;
          commit;
        end if;
        v_cnt:=v_cnt+1;        
      end;
    end loop;

    commit;
    close all_member;
    list_t_member.delete;

    log('---> ������ ���������', cnt_rows||' - �������' );    
  end reload_member;  
  
  function trunc_partition(dtab_name varchar2, must_date out date) 
    return pls_integer
  is
  begin
    v_action:='TRUNC_PARTITION';
    dbms_application_info.set_module('LOAD_SI_MEMBER_2',v_action);
    -- �������� ���������� �������
    for global_index in (select index_name
          from all_indexes 
          where table_name = dtab_name
--          and partitioned='NO' 
          and table_owner='SSWH'
        )
    loop
      log('���������� ����������� �������: '||global_index.index_name);
      execute immediate 'alter index '||global_index.index_name||' unusable';
    end loop;
      
    -- ������� ��������
    FOR part IN ( SELECT  table_name, partition_name, high_value,
                  partition_position
        FROM user_tab_partitions t
        WHERE TABLE_NAME = upper(dtab_name)
        order by partition_position desc
    )
    LOOP
      if  to_date( substr(part.high_value,11,10), 'yyyy-mm-dd' ) > trunc(reload_before,'YEAR')
      then
        must_date:=to_date( substr(part.high_value,11,10), 'yyyy-mm-dd' );
        -- ��������� ������������������ ������, ������������ SQLCODE
        -- ������� Truncate �������� ?
        execute immediate 'alter table '||part.table_name||' modify partition '||part.partition_name||' unusable local indexes';
        -- ������ ��������
        log( 'TRUNCATE PARTITION: ' || part.partition_name);
        execute immediate 'ALTER TABLE '||part.table_name||' TRUNCATE PARTITION '||part.partition_name||'';
        -- ����� Truncate Index ���������� "USABLE" - ���� ��� ���?
        -- �������� ��������� ������������������ ������, ������������ SQLCODE
        execute immediate 'alter table '||part.table_name||' modify partition '||part.partition_name||' unusable local indexes';
        if SQLCODE>0 then
            -- ������, ��� ����������� �������� ����� ������� �� ���������
            return 0;
        end if;
        log( 'SET UNUSABLE PARTITION: '||part.partition_name);
      else
        must_date:=to_date( substr(part.high_value,11,10), 'yyyy-mm-dd' );
        exit;
      end if;
    END LOOP;
    log ( 'TRUNCATE PARTITION', '����� ����������� ������ � "PAY_DATE" >= '||to_char(must_date,'dd.mm.yyyy'));
    return 1;
  end trunc_partition;

  procedure delete_rows(dtab_name varchar2, idate in date)
    is
  begin
    v_action:='DELETE_ROWS';
    dbms_application_info.set_module('LOAD_SI_MEMBER_2',v_action);
    
    cmd:='delete /*+parallel(4)*/ from '||dtab_name||' dt where dt.pay_date_gfss >= '''||to_date(idate,'dd.mm.yyyy')||
                      ''' and dt.pay_date > '''||to_date(add_months(idate,-1),'dd.mm.yyyy')||''''; 
    log ( '������� ������',cmd);
    execute immediate cmd;
    commit;
    log (  '---> ������ �������',sql%rowcount||' - �������');
  end;

  procedure make_member(iv_table in varchar2) 
  is
    must_date date;
  begin
    v_action:='MAKE_MEMBER';
    dbms_application_info.set_module('LOAD_SI_MEMBER_2','MAKE_MEMBER');
    
    -- �������� SI_MEMBER
    reload_before:=to_date('01.01.2010','dd.mm.yyyy');
    if trunc_partition(iv_table, must_date)=0 
    then
      return;
    end if;
    reload_from:=must_date;
    reload_member(iv_table);
    rebuild_indexes(iv_table);
    log('+++ ������� '||upper(iv_table)||' ��������� �� ��������', '��������� �������: '||cnt_rows);

  end make_member;

  
  procedure make_member2(iv_table in varchar2)
  is
  begin
    v_action:='MAKE_MEMBER2';
    dbms_application_info.set_module('LOAD_SI_MEMBER_2',v_action);
    
    log(iv_table,'+++ ������ �������� '||upper(iv_table)||' �� ��������� ���');

    update load_tables_status lt
    set   lt.state=1,
          lt.beg_time=sysdate,
          lt.end_time=null,
          lt.info='�������� ��������'
    where  upper(lt.table_name) = upper(iv_table);
    commit;
    
    -- �������� ������ ��������, ��������� ������� � ������� ������ �� "v_count_day" ��������� ����
    if prepare_partition(iv_table, 'PAY_DATE')=0
    then
      return;
    end if;
    execute immediate 'ALTER SESSION ENABLE PARALLEL DML';
    delete_rows(iv_table, reload_from);
    -- ��������� ������
    execute immediate 'ALTER SESSION DISABLE PARALLEL DML';
    log(iv_table,'--> �������� ������� ');
    reload_member(iv_table);
    -- ������������� �������
    execute immediate 'ALTER SESSION ENABLE PARALLEL DML';
    
    -- ��������������� 3.11.2020 ����� ���������� ������������
    rebuild_indexes(iv_table);
    
    
    log('+++ ������� '||' ��������� �� ��������� ���', '��������� �������: '||cnt_rows);
    exception when others then
        begin
              e_errm:=sqlerrm;
              insert into log_load_tables values(CURRENT_TIMESTAMP, 'SI_MEMBER_2', 'MAKE_MEMBER2->������: ', e_errm);
              commit;
              return;
        end;
      
  end make_member2;
  
  procedure make  
  is
    v_table varchar2(64);
  begin
    v_action:='MAKE';
    dbms_application_info.set_module('LOAD_SI_MEMBER_2',v_action);

    week_day:=to_char(sysdate,'D');
    execute immediate 'alter session set skip_unusable_indexes = true';

    v_table := 'SI_MEMBER_2';
    if set_days_reload(v_table)=1 then
        log( v_table, '�������� ������ ��� ����������� ...');
        return;
    end if;

    if trunc(v_last_success_date,'MONTH') >= trunc(sysdate,'MONTH')
    then
        log( v_table, '�������� ������ ��� ���������');
    else
        init_log(v_table);    
        make_member2(v_table);
        stop_log(v_table);
    end if;
    exception when others then
        begin
              log(v_action, sqlerrm);
              return;
        end;
  end make;  
    
begin
  execute immediate 'alter session set sort_area_size=50000000';  
  execute immediate 'alter session set sort_area_retained_size=50000000';
end load_si_member_2;
/
