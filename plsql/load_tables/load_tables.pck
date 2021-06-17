create or replace package load_tables is

  -- Author  : ГУСЕЙНОВ_Ш
  -- Created : 28.08.2019 11:34:24
  -- Purpose : Для загрузки партиционированных таблиц, ранжированных по дате платежа - PAY_DATE
  -- Реализованы две альтернативные стратегии: 
  -- 1. полная перезаливка партиций: make_dl и make_pd
  -- 2. заливка за период две недели от текущей даты: make_dl2 и make_pd2

  procedure make_pmpd; 
  procedure make_pmdl; 
  
  procedure rebuild_indexes (itable_name varchar2);

end load_tables;
/
create or replace package body load_tables is

  reload_from     date;
  v_last_success_date date;
  v_state         pls_integer default 0;
  cnt_rows        pls_integer default 0;
  week_day        pls_integer default 0;
  e_errm          varchar2(1024);
  cmd             varchar2(1024);

  TYPE My_Cursor  IS REF CURSOR;

  procedure log(iobj in varchar, iaction in varchar2, imsg in nvarchar2 := '');
  function prepare_partition(dtab_name varchar2, icolumn_name in varchar2 := 'PAY_DATE') return pls_integer;

  procedure log(iobj in varchar, iaction in varchar2, imsg in nvarchar2)
  is
  PRAGMA AUTONOMOUS_TRANSACTION;
  begin
    insert into log_load_tables values(CURRENT_TIMESTAMP, iobj, iaction, imsg);
    commit;
  end log;

  procedure init_log(itable_name in varchar2)
  is
  begin
    Update load_tables_status t
    Set t.beg_time = sysdate,
        t.runtime = sysdate,
        t.end_time = '',
        t.state = 1,
        t.info = 'Начата обработка'
    Where t.table_name=itable_name;
    Commit;
  end init_log;

  procedure stop_log(itable_name in varchar2)
  is
  begin
    Update load_tables_status t
    Set t.state = 2,
        t.runtime = trunc(sysdate),
        t.last_success_date = sysdate,
        t.end_time = Sysdate,
        info = Null
    Where upper(t.table_name)=upper(itable_name);
    commit;
  end stop_log;

  function set_days_reload(itable_name in varchar2) return pls_integer
  is
  begin
    select state, last_success_date, trunc(lt.last_success_date) - lt.days_rollback + 1
    into v_state, v_last_success_date, reload_from
    from load_tables_status lt where upper(lt.table_name) = upper(itable_name);

    if week_day > 5 then
       reload_from:=reload_from-7;
    end if;
    return v_state;    
  end;
  
  procedure rebuild_indexes (itable_name varchar2)
  is
  cmd varchar2(1024);
  begin
    dbms_application_info.set_module('LOAD_TABLES','build index for '||itable_name);
    log(itable_name, 'Начинаем перестройку индексов для '||itable_name);

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

      log(current_index.index_name, 'Перестраиваем индекс',current_index.build_command);
      EXECUTE immediate current_index.build_command;
    END LOOP;

    for cur in (select index_name,partition_name,status
                from user_ind_partitions ip
                where ip.status='UNUSABLE'
                and   index_name in (select index_name from all_indexes where table_name = itable_name)
                order by index_name )
    loop
      log(cur.index_name, 'REBUILD PARTITION INDEX',cur.partition_name);
      cmd:= 'ALTER INDEX '||cur.index_name||' REBUILD PARTITION '||cur.partition_name||' ONLINE';
      execute immediate cmd;
    end loop;

    log(itable_name,'Перестройка индексов для '||itable_name||' завершена');
  end rebuild_indexes;

  --Загрузка Virtual_Doc_List
  procedure reload_vdl(iv_table in varchar2)
  is
  v_cnt pls_integer default 0;
  type vdl_t is record(
      pay_date_gfss date,
      part_id     VARCHAR2(8),
      mhmh_id_in  NUMBER(11),
      pmdl_n_in   NUMBER(5),
      mhmh_id_out NUMBER(11),
      pmdl_n_out  NUMBER(11)
  );
  TYPE vdl_table IS TABLE OF vdl_t index by pls_integer;
  list_t_vdl vdl_table;
  l_index pls_integer default 0;
  all_vdl My_Cursor;
  begin
/*
    cmd:='select vd.* '||
         'from virtual_doc_list@crtr  vd '||
         'where dl.pay_date>='''||to_char(ilowest_value,'dd.mm.yyyy')||'''';
--*/
--/*
    cmd:='select pd.pay_date, vd.* '||
         'from virtual_doc_list@crtr  vd, pmpd_pay_doc_s@crtr pd '||
         'where vd.mhmh_id_out = pd.mhmh_id '||
         'and   pd.pay_date>=''01.01.2011'' ';
--         'and   pd.pay_date>='''||to_char(reload_from,'dd.mm.yyyy')||'''';
--*/

    log(iv_table,'Открываем курсор для '||iv_table, cmd);
    open all_vdl for cmd;
    log(iv_table,'Начинаем загружать данные');
    cnt_rows:=0;
    v_cnt:=1;


    loop
      begin
        fetch all_vdl bulk collect into list_t_vdl limit 16000;
        -- Загружаем Virtual_Doc_List
        forall l_index in list_t_vdl.first .. list_t_vdl.last
            insert
--            into virtual_doc_list(
            into virtual_doc_list(
--                        pay_date_gfss,
                        part_id,
                        mhmh_id_in,
                        pmdl_n_in,
                        mhmh_id_out,
                        pmdl_n_out
                        )
            values(
--                    list_t_vdl(l_index).pay_date_gfss,
                    list_t_vdl(l_index).part_id,
                    list_t_vdl(l_index).mhmh_id_in,
                    list_t_vdl(l_index).pmdl_n_in,
                    list_t_vdl(l_index).mhmh_id_out,
                    list_t_vdl(l_index).pmdl_n_out
                   );
        cnt_rows:=cnt_rows+list_t_vdl.count;
        exit when all_vdl%NOTFOUND;
        if v_cnt > 20 then
          v_cnt:=0;
          commit;
        end if;
        v_cnt:=v_cnt+1;
      end;
    end loop;

    commit;
    close all_vdl;
    list_t_vdl.delete;

    log(iv_table, '---> Данные загружены', cnt_rows||' - записей' );
  end reload_vdl;

  procedure reload_pmdl(iv_table in varchar2)
  is
--/*
  type pmdl2_t is record(
       pay_date  pmpd_pay_doc.pay_date%type,
       part_id   pmdl_doc_list.part_id%type,
       mhmh_id   pmdl_doc_list.mhmh_id%type,
       pmdl_n    pmdl_doc_list.pmdl_n%type,
       num       pmdl_doc_list.num%type,
       pay_sum   pmdl_doc_list.pay_sum%type,
       opv       pmdl_doc_list.opv%type,
       sic       pmdl_doc_list.sic%type,
       fm        pmdl_doc_list.fm%type,
       fm2       pmdl_doc_list.fm2%type,
       nm        pmdl_doc_list.nm%type,
       nm2       pmdl_doc_list.nm2%type,
       ft        pmdl_doc_list.ft%type,
       ft2       pmdl_doc_list.ft2%type,
       dt        pmdl_doc_list.dt%type,
       la        pmdl_doc_list.la%type,
       rnn       pmdl_doc_list.rnn%type,
       sicid     pmdl_doc_list.sicid%type,
       rfem_id   pmdl_doc_list.rfem_id%type,
       npf_id    pmdl_doc_list.npf_id%type,
       oldsicid  pmdl_doc_list.oldsicid%type,
       sicnull   pmdl_doc_list.sicnull%type,
       period    pmdl_doc_list.period%type
  );
--*/
  TYPE pmdl2_table IS TABLE OF pmdl2_t index by pls_integer;
  list_t_pmdl pmdl2_table;
  l_index pls_integer default 0;
  all_pmdl My_Cursor;

/*
  CURSOR all_pmdl IS select pd.pay_date, dl.*
                  from loader.pmdl_doc_list  dl, loader.pmpd_pay_doc pd
                  where dl.mhmh_id=pd.mhmh_id
                  and   pd.pay_date>=ilowest_value
                  and not exists(
                      select *
                      from pmdl_doc_list dl2
                      where dl2.pay_date = pd.pay_date
                      and   dl2.mhmh_id = pd.mhmh_id
                  );
*/
  begin
    dbms_application_info.set_module('LOAD_TABLES','load '||iv_table);
    
    -- В выходные дни делаем "глубокую" заливку данных с оскоком на 14 дней назад
/*    
    if week_day > 5 then
        cmd:='select dl.* '||
             'from pmdl_doc_list@crtr dl '||
             'where dl.pay_date>='''||to_char(reload_from-7,'dd.mm.yyyy')||''' '||
             'and not exists( '||
                              'select * '||
                              'from pmdl_doc_list dl2 '||
                              'where dl2.pay_date = pd.pay_date '||
                              'and   dl2.mhmh_id = pd.mhmh_id )';
    else
        -- В рабочие дни делаем "неглубокую" заливку данных
        cmd:='select dl.* '||
             'from pmdl_doc_list@crtr  dl '||
             'where dl.pay_date>='''||to_char(reload_from,'dd.mm.yyyy')||'''';
    end if;
*/
    -- В рабочие дни делаем "неглубокую" заливку данных
    cmd:='select /*+parallel(2)*/ pd.pay_date, dl.* '||
         'from loader.pmdl_doc_list dl, loader.pmpd_pay_doc pd '||
         'where pd.mhmh_id=dl.mhmh_id '||
         'and pd.pay_date>='''||to_char(reload_from,'dd.mm.yyyy')||''' ';
         
    
    log(iv_table,'Открываем курсор для '||iv_table, cmd);
    open all_pmdl for cmd;
    log(iv_table,'Начинаем загружать данные');
    cnt_rows:=0;

    loop
      begin
        fetch all_pmdl bulk collect into list_t_pmdl limit 16000;
        -- Загружаем PMDL_DOC_LIST
--/*
        forall l_index in list_t_pmdl.first .. list_t_pmdl.last
            insert
            into pmdl_doc_list(
                        pay_date, part_id, mhmh_id, pmdl_n,
                        num, pay_sum, opv, sic,
                        fm, fm2, nm, nm2,
                        ft, ft2, dt, la,
                        rnn, sicid, rfem_id, npf_id,
                        oldsicid, sicnull, period)
            values( list_t_pmdl(l_index).pay_date, list_t_pmdl(l_index).part_id,
                    list_t_pmdl(l_index).mhmh_id, list_t_pmdl(l_index).pmdl_n,
                    list_t_pmdl(l_index).num, list_t_pmdl(l_index).pay_sum, list_t_pmdl(l_index).opv, list_t_pmdl(l_index).sic,
                    list_t_pmdl(l_index).fm, list_t_pmdl(l_index).fm2, list_t_pmdl(l_index).nm, list_t_pmdl(l_index).nm2,
                    list_t_pmdl(l_index).ft, list_t_pmdl(l_index).ft2, list_t_pmdl(l_index).dt, list_t_pmdl(l_index).la,
                    list_t_pmdl(l_index).rnn, list_t_pmdl(l_index).sicid, list_t_pmdl(l_index).rfem_id, list_t_pmdl(l_index).npf_id,
                    list_t_pmdl(l_index).oldsicid, list_t_pmdl(l_index).sicnull, list_t_pmdl(l_index).period);
--*/
        -- Загружаем PMDL_DOC_LIST_S
        forall l_index in list_t_pmdl.first .. list_t_pmdl.last
            insert /*+APPEND*/
            into pmdl_doc_list_s(
                        pay_date, part_id, mhmh_id, pmdl_n,
                        pay_sum, rnn, sicid, rfem_id, period)
            values( list_t_pmdl(l_index).pay_date,
                    list_t_pmdl(l_index).part_id,
                    list_t_pmdl(l_index).mhmh_id,
                    list_t_pmdl(l_index).pmdl_n,
                    list_t_pmdl(l_index).pay_sum,
                    list_t_pmdl(l_index).rnn,
                    list_t_pmdl(l_index).sicid,
                    list_t_pmdl(l_index).rfem_id,
                    list_t_pmdl(l_index).period
                  );
        cnt_rows:=cnt_rows+list_t_pmdl.count;
        exit when all_pmdl%NOTFOUND;
      end;
    end loop;

    commit;
    close all_pmdl;
    list_t_pmdl.delete;

    log(iv_table, '---> Данные загружены', cnt_rows||' - записей' );
  end reload_pmdl;

  procedure reload_pmpd(iv_table in varchar2)
  is
  v_cnt pls_integer default 0;
  type pmpd2_t is record(
      part_id            pmpd_pay_doc.part_id%type,
      mhmh_id            pmpd_pay_doc.mhmh_id%type,
      refer              pmpd_pay_doc.refer%type,
      pay_date           pmpd_pay_doc.pay_date%type,
      rfcc_code_currency pmpd_pay_doc.rfcc_code_currency%type,
      pay_sum            pmpd_pay_doc.pay_sum%type,
      acc_d_c            pmpd_pay_doc.acc_d_c%type,
      p_account          pmpd_pay_doc.p_account%type,
      p_name             pmpd_pay_doc.p_name%type,
      p_rnn              pmpd_pay_doc.p_rnn%type,
      p_chief            pmpd_pay_doc.p_chief%type,
      p_mainbk           pmpd_pay_doc.p_mainbk%type,
      p_irs              pmpd_pay_doc.p_irs%type,
      rfse_code_p        pmpd_pay_doc.rfse_code_p%type,
      rfbk_mfo_pbank     pmpd_pay_doc.rfbk_mfo_pbank%type,
      rfbk_mfo_pcbank    pmpd_pay_doc.rfbk_mfo_pcbank%type,
      pcbank_acc         pmpd_pay_doc.pcbank_acc%type,
      rfbk_mfo_rcbank    pmpd_pay_doc.rfbk_mfo_rcbank%type,
      rcbank_acc         pmpd_pay_doc.rcbank_acc%type,
      rfbk_mfo_mbank     pmpd_pay_doc.rfbk_mfo_mbank%type,
      rfbk_mfo_rbank     pmpd_pay_doc.rfbk_mfo_rbank%type,
      r_account          pmpd_pay_doc.r_account%type,
      r_name             pmpd_pay_doc.r_name%type,
      r_rnn              pmpd_pay_doc.r_rnn%type,
      r_irs              pmpd_pay_doc.r_irs%type,
      rfse_code_r        pmpd_pay_doc.rfse_code_r%type,
      doc_nmb            pmpd_pay_doc.doc_nmb%type,
      doc_date           pmpd_pay_doc.doc_date%type,
      rfsd_code_send     pmpd_pay_doc.rfsd_code_send%type,
      doc_vo             pmpd_pay_doc.doc_vo%type,
      cipher_id_knp      pmpd_pay_doc.cipher_id_knp%type,
      rfbc_code_profit   pmpd_pay_doc.rfbc_code_profit%type,
      doc_pso            pmpd_pay_doc.doc_pso%type,
      doc_prioritet      pmpd_pay_doc.doc_prioritet%type,
      doc_sim            pmpd_pay_doc.doc_sim%type,
      doc_assign         pmpd_pay_doc.doc_assign%type,
      doc_note           pmpd_pay_doc.doc_note%type,
      doc_err            pmpd_pay_doc.doc_err%type,
      date_execute       pmpd_pay_doc.date_execute%type,
      rfem_id            pmpd_pay_doc.rfem_id%type,
      mhmh_id_list       pmpd_pay_doc.mhmh_id_list%type,
      period             pmpd_pay_doc.period%type,
      parent_group_id    pmpd_pay_doc.parent_group_id%type,
      MSMT_CODE           mhmh_msg_head.msmt_code%type,
      TMST_ID             mhmh_msg_head.tmst_id%type
  );
  TYPE pmpd2_table IS TABLE OF pmpd2_t index by pls_integer;
  list_t_pmpd pmpd2_table;
  l_index pls_integer default 0;
  all_pmpd My_Cursor;
  BEGIN
    dbms_application_info.set_module('LOAD_TABLES','load '||iv_table);
    
/*
    if week_day > 5 then
        cmd:='select pd.*, mh.msmt_code, mh.tmst_id
              from pmpd_pay_doc@crtr pd, mhmh_msg_head@crtr mh
              where pd.pay_date >= '''||to_char(reload_from-7,'dd.mm.yyyy')||'''
              AND pd.mhmh_id=mh.mhmh_id
              and not exists (
                  select *
                  from pmpd_pay_doc pd2
                  Where pd2.pay_date = pd.pay_date
                  and   pd2.mhmh_id = pd.mhmh_id
              )';
    else
        cmd:='select pd.*, mh.msmt_code, mh.tmst_id
              from pmpd_pay_doc@crtr pd, mhmh_msg_head@crtr mh
              where pd.pay_date>='''||reload_from||'''
              AND pd.mhmh_id=mh.mhmh_id';
    end if;
    cmd:='select pd.*
          from pmpd_pay_doc@crtr pd
          where pd.pay_date >= '''||reload_from||'''';
*/

    cmd:='select pd.*, mh.msmt_code, mh.tmst_id '||
        'from loader.pmpd_pay_doc pd, loader.mhmh_msg_head mh '||
        'where pd.mhmh_id=mh.mhmh_id '||
        'and pd.pay_date>='''||to_char(reload_from,'dd.mm.yyyy')||''' ';

    cnt_rows:=0;
    log(iv_table,'Открываем курсор для '||iv_table, cmd);
    open all_pmpd for cmd;
    log(iv_table,'Начинаем загружать данные');
    loop
      begin
        fetch all_pmpd bulk collect into list_t_pmpd limit 16000;
--/*
        forall l_index in list_t_pmpd.first .. list_t_pmpd.last
            insert /*+APPEND*/
--/*
            into pmpd_pay_doc(
                   part_id, mhmh_id, refer, pay_date,
                   rfcc_code_currency, pay_sum, acc_d_c, p_account,
                   p_name, p_rnn, p_chief, p_mainbk,
                   p_irs, rfse_code_p, rfbk_mfo_pbank, rfbk_mfo_pcbank,
                   pcbank_acc, rfbk_mfo_rcbank, rcbank_acc, rfbk_mfo_mbank,
                   rfbk_mfo_rbank, r_account, r_name, r_rnn,
                   r_irs, rfse_code_r, doc_nmb, doc_date,
                   rfsd_code_send, doc_vo, cipher_id_knp, rfbc_code_profit,
                   doc_pso, doc_prioritet, doc_sim, doc_assign,
                   doc_note, doc_err, date_execute, rfem_id,
                   mhmh_id_list, period, parent_group_id,
                   MSMT_CODE, TMST_ID
                   )
            values(
                   list_t_pmpd(l_index).part_id,    list_t_pmpd(l_index).mhmh_id,
                   list_t_pmpd(l_index).refer,      list_t_pmpd(l_index).pay_date,
                   list_t_pmpd(l_index).rfcc_code_currency,
                   list_t_pmpd(l_index).pay_sum,
                   list_t_pmpd(l_index).acc_d_c,    list_t_pmpd(l_index).p_account,
                   list_t_pmpd(l_index).p_name,     list_t_pmpd(l_index).p_rnn,
                   list_t_pmpd(l_index).p_chief,    list_t_pmpd(l_index).p_mainbk,
                   list_t_pmpd(l_index).p_irs,      list_t_pmpd(l_index).rfse_code_p,
                   list_t_pmpd(l_index).rfbk_mfo_pbank, list_t_pmpd(l_index).rfbk_mfo_pcbank,
                   list_t_pmpd(l_index).pcbank_acc, list_t_pmpd(l_index).rfbk_mfo_rcbank,
                   list_t_pmpd(l_index).rcbank_acc, list_t_pmpd(l_index).rfbk_mfo_mbank,
                   list_t_pmpd(l_index).rfbk_mfo_rbank, list_t_pmpd(l_index).r_account,
                   list_t_pmpd(l_index).r_name,     list_t_pmpd(l_index).r_rnn,
                   list_t_pmpd(l_index).r_irs,      list_t_pmpd(l_index).rfse_code_r,
                   list_t_pmpd(l_index).doc_nmb,    list_t_pmpd(l_index).doc_date,
                   list_t_pmpd(l_index).rfsd_code_send, list_t_pmpd(l_index).doc_vo,
                   list_t_pmpd(l_index).cipher_id_knp, list_t_pmpd(l_index).rfbc_code_profit,
                   list_t_pmpd(l_index).doc_pso,       list_t_pmpd(l_index).doc_prioritet,
                   list_t_pmpd(l_index).doc_sim,       list_t_pmpd(l_index).doc_assign,
                   list_t_pmpd(l_index).doc_note,      list_t_pmpd(l_index).doc_err,
                   list_t_pmpd(l_index).date_execute,  list_t_pmpd(l_index).rfem_id,
                   list_t_pmpd(l_index).mhmh_id_list,
                   list_t_pmpd(l_index).period,
                   list_t_pmpd(l_index).parent_group_id,
                   list_t_pmpd(l_index).MSMT_CODE,     list_t_pmpd(l_index).TMST_ID
                   );
--*/
        forall l_index in list_t_pmpd.first .. list_t_pmpd.last
            insert /*+APPEND*/
            into pmpd_pay_doc_S(
                   part_id, mhmh_id, pay_date,
                   pay_sum, p_rnn, r_rnn,
                   Cipher_Id_Knp,
                   period,
                   MSMT_CODE, TMST_ID
                   )
            values(
                   list_t_pmpd(l_index).part_id,
                   list_t_pmpd(l_index).mhmh_id,
                   list_t_pmpd(l_index).pay_date,
                   list_t_pmpd(l_index).pay_sum,
                   list_t_pmpd(l_index).p_rnn,
                   list_t_pmpd(l_index).r_rnn,
                   list_t_pmpd(l_index).cipher_id_knp,
                   list_t_pmpd(l_index).period,
                   list_t_pmpd(l_index).MSMT_CODE,
                   list_t_pmpd(l_index).TMST_ID
                   );
        cnt_rows:=cnt_rows+list_t_pmpd.count;
        exit when all_pmpd%NOTFOUND;
        v_cnt:=v_cnt+1;
        if v_cnt > 20 then
          v_cnt:=0;
          commit;
        end if;
      end;
    end loop;

    commit;
    close all_pmpd;
    list_t_pmpd.delete;

    log(iv_table, '---> Данные загружены', cnt_rows||' - записей' );
  end reload_pmpd;

  procedure reload_pnap(iv_table in varchar2)
  is
  v_cnt pls_integer default 0;
  type pnap_t is record(
      part_id   VARCHAR2(8),
      actp_id   NUMBER(11),
      act_month DATE,
      pncd_id   NUMBER(11),
      rfbn_id   CHAR(4),
      emp_id    NUMBER(11),
      riac_id   NUMBER(3),
      source_id NUMBER(11),
      act_date  DATE,
      notes     NVARCHAR2(500),
      in_date   DATE,
      ip_pc     VARCHAR2(32)
  );
  TYPE pnap_table IS TABLE OF pnap_t index by pls_integer;
  list_t_pnap pnap_table;
  l_index pls_integer default 0;

  /* Full Load
  CURSOR all_pnap IS
          select *
          from   pnap_act_prt pn
          ;
  --*/
  --/* Usually regim
  CURSOR all_pnap IS
          select *
          from   loader.pnap_act_prt pn
          where   pn.act_month>=reload_from;
--*/          
/*
  CURSOR all_pnap IS
          select *

          from   pnap_act_prt@crtr pn
          where   pn.act_month>=reload_from;
  --*/
  begin
    log(iv_table,'Начинаем загружать данные');
    commit;

    open all_pnap;
    loop
      begin
        fetch all_pnap bulk collect into list_t_pnap limit 8192;
        -- Загружаем PNAP_ACT_PRT
        forall l_index in list_t_pnap.first .. list_t_pnap.last
            insert /*+APPEND*/
            into pnap_act_prt(
                  part_id, actp_id, act_month,
                  pncd_id, rfbn_id, emp_id,
                  riac_id, source_id, act_date,
                  notes, in_date, ip_pc
                  )
            values( list_t_pnap(l_index).part_id,
                    list_t_pnap(l_index).actp_id,
                    list_t_pnap(l_index).act_month,
                    list_t_pnap(l_index).pncd_id,
                    list_t_pnap(l_index).rfbn_id,
                    list_t_pnap(l_index).emp_id,
                    list_t_pnap(l_index).riac_id,
                    list_t_pnap(l_index).source_id,
                    list_t_pnap(l_index).act_date,
                    list_t_pnap(l_index).notes,
                    list_t_pnap(l_index).in_date,
                    list_t_pnap(l_index).ip_pc
                    );
        exit when all_pnap%NOTFOUND;
        v_cnt:=v_cnt+1;
        if v_cnt > 20 then
          v_cnt:=0;
          commit;
        end if;
      end;
    end loop;
    close all_pnap;
    commit;
    list_t_pnap.delete;
    log(iv_table, 'Загрузка данных завершена');
    commit;
  end reload_pnap;

  -- Атавизм, осталось для примера, работает медленней чем с коллекцией
  -- Коллекция позволяет вставлять данные сразу в несколько таблиц
  procedure reload_pmpd2(iv_table in varchar2, ilowest_value in date)
  is
  cmd varchar2(512);
  begin
    log(iv_table,'Начинаем загружать данные в '||iv_table);
/*
    cmd:='INSERT
          INTO PMPD_PAY_DOC
          SELECT PD.*, MH.MSMT_CODE, MH.TMST_ID
          FROM   LOADER.PMPD_PAY_DOC PD, LOADER.MHMH_MSG_HEAD MH
          WHERE  PD.MHMH_ID=MH.MHMH_ID
          AND    PD.PAY_DATE >= '|| ilowest_value;
--*/
    cmd:='INSERT /*append*/
          INTO PMPD_PAY_DOC
          SELECT PD.*
          from pmpd_pay_doc@crtr pd
          where pd.pay_date >='||( ilowest_value - 7 )||'
          and not exists (
            select *
            from pmpd_pay_doc pd2
            Where  pd2.pay_date = pd.pay_date
          )';

    execute immediate cmd;
    commit;
    log(iv_table, 'Загрузка данных завершена');
  end reload_pmpd2;

  function trunc_partition(dtab_name varchar2, must_date out date)
    return pls_integer
  is
  begin
    -- Отключим глоабльные индексы
    for global_index in (select index_name
          from all_indexes
          where table_name = dtab_name
--          and partitioned='NO'
          and table_owner='SSWH'
        )
    loop
      log(dtab_name, global_index.index_name, 'Отключение глобального индекса');
      execute immediate 'alter index '||global_index.index_name||' unusable';
    end loop;

    -- Обрежем партиции
    FOR part IN ( SELECT  table_name, partition_name, high_value,
                  partition_position
        FROM user_tab_partitions t
        WHERE TABLE_NAME = upper(dtab_name)
        order by partition_position desc
    )
    LOOP
      if  to_date( substr(part.high_value,11,10), 'yyyy-mm-dd' ) > trunc(reload_from,'YEAR')
      then
        must_date:=to_date( substr(part.high_value,11,10), 'yyyy-mm-dd' );
        -- Отключаем партиционированный индекс, возвращается SQLCODE
        -- Быстрей Truncate работает ?
        execute immediate 'alter table '||part.table_name||' modify partition '||part.partition_name||' unusable local indexes';
        -- Чистим партиции
        log( part.table_name, 'TRUNCATE PARTITION', part.partition_name);
        execute immediate 'ALTER TABLE '||part.table_name||' TRUNCATE PARTITION '||part.partition_name||'';
        -- После Truncate Index становится "USABLE" - фича или баг?
        -- Повторно отключаем партиционированный индекс, возвращается SQLCODE
        execute immediate 'alter table '||part.table_name||' modify partition '||part.partition_name||' unusable local indexes';
        if SQLCODE>0 then
            -- Ошибка, без отключенных индексов лучше таблицы не загружать
            return 0;
        end if;
        log( part.table_name, 'SET UNUSABLE PARTITION',part.partition_name);
      else
        must_date:=to_date( substr(part.high_value,11,10), 'yyyy-mm-dd' );
        exit;
      end if;
    END LOOP;
    log ( dtab_name, 'TRUNCATE PARTITION', 'Будут загружаться строки с "PAY_DATE" >= '||to_char(must_date,'dd.mm.yyyy HH24:MI:SS'));
    return 1;
  end trunc_partition;

  procedure delete_rows(dtab_name varchar2, icolumn_name in varchar2, idate in date)
    is
  begin
    log ( dtab_name, 'Удаляем записи',' условие: '||upper(icolumn_name)||'" >= '||to_char(idate,'dd.mm.yyyy HH24:MI:SS'));
    cmd:='delete from '||dtab_name||' dt where dt.'||upper(icolumn_name)||' >= '''||to_date(idate,'dd.mm.yyyy')||'''';
    execute immediate cmd;
    log ( dtab_name, '---> Записи удалены',sql%rowcount||' - записей');
  end;

  function prepare_partition(dtab_name varchar2, icolumn_name in varchar2)
    return pls_integer
  is
  begin
    log ( dtab_name, 'Подготовка Партиций');
    -- Отключим глоабльные индексы
    for global_index in (select index_name
          from all_indexes
          where table_name = dtab_name
          and partitioned='NO'
          and table_owner='SSWH'
        )
    loop
      log(dtab_name, 'Отключаем глобальный индекс', global_index.index_name );
      execute immediate 'alter index '||global_index.index_name||' unusable';
    end loop;

    -- Отключим индексы партиций
    FOR part IN ( SELECT  table_name, partition_name, high_value,
                  partition_position
        FROM user_tab_partitions t
        WHERE TABLE_NAME = upper(dtab_name)
        order by partition_position desc
    )
    LOOP
      if  to_date( substr(part.high_value,11,10), 'yyyy-mm-dd' ) > trunc(reload_from,'YEAR')
      then
        -- Отключаем партиционированный индекс, возвращается SQLCODE
        -- Быстрей Truncate работает ?
        log( part.table_name, 'Отключаем партицию',part.partition_name);
        execute immediate 'alter table '||part.table_name||' modify partition '||part.partition_name||' unusable local indexes';
        if SQLCODE>0 then
            -- Ошибка, без отключенных индексов лучше таблицы не загружать
            log ( dtab_name, 'Ошибка отключения партиций '||sqlcode);
            return 0;
        end if;
      else
        exit;
      end if;
    END LOOP;
    log ( dtab_name, 'Подготовка партиций завершена');

    log ( dtab_name, 'Далее будут загружаться строки ', 'условие загрузки: '||upper(icolumn_name)||'" >= '||to_char(reload_from,'dd.mm.yyyy HH24:MI:SS'));
    return 1;
  end prepare_partition;

  procedure make_pnap(iv_table1 in varchar2)
  is
    must_date date;
  begin
    --v_count_day:=365;
    log(iv_table1,'Подготовка загрузки');
    -- Выбираем нужную партицию, отключаем индексы
    if trunc_partition(iv_table1, must_date)=0
    then
      return;
    end if;
    reload_from:=must_date;
    -- Загружаем сразу 2 таблицы
    reload_pnap(iv_table1);
    -- Перестраиваем индексы
    rebuild_indexes(iv_table1);
    log(iv_table1, '=====>  Заливка таблицы завершена', 'Загружено записей: '||cnt_rows);   
    -- Загрузка PMPD_PAY_DOC
  end make_pnap;

  procedure make_pnap2(iv_table1 in varchar2)
  is
  begin
    log(iv_table1,'Подготовка загрузки');
    -- Выбираем нужную партицию, отключаем индексы и зачищаем партиции
    if prepare_partition(iv_table1, 'act_month')=0
    then
      return;
    end if;
    -- Загружаем сразу 2 таблицы
    reload_pnap(iv_table1);
    -- Перестраиваем индексы
    rebuild_indexes(iv_table1);
    log(iv_table1, '=====>  Заливка таблицы завершена', 'Загружено записей: '||cnt_rows);   
    -- Загрузка PNAP_ACT_PRT
  end make_pnap2;

  procedure make_dl(iv_table1 in varchar2, iv_table2 in varchar2)
  is
    must_date date;
  begin
    -- Загрузка PMDL_DOC_LIST
    log(iv_table1,'+++ Будут загружаться таблицы '||upper(iv_table1)||' и '||upper(iv_table2)||' по разделам');
    if trunc_partition(iv_table1, must_date)=0
    or trunc_partition(iv_table2, must_date)=0
    then
      return;
    end if;
    reload_from:=must_date;
    -- Загружаем сразу 2 таблицы
    reload_pmdl(iv_table1);
    rebuild_indexes(iv_table1);
    log(iv_table1, '=====>  Заливка таблицы завершена', 'Загружено записей: '||cnt_rows);   
    
    rebuild_indexes(iv_table2);
    log(iv_table2, '=====>  Заливка таблицы завершена', 'Загружено записей: '||cnt_rows);       
    -- Загрузка PMPD_PAY_DOC
  end make_dl;

  -- Загружать будем сразу 2 таблицы,
  -- однако индексы перестраивать будем отдельно по каждой таблице
  -- Загрузка PMPD_PAY_DOC2 и PMPD_PAY_DOC2_S
  procedure make_pd(iv_table1 in varchar2, iv_table2 in varchar2)
  is
    must_date date;
  begin
    log(iv_table1,'+++ Будут загружаться таблицы '||upper(iv_table1)||' и '||upper(iv_table2)||' по разделам');
    -- Выбираем нужную партицию, отключаем индексы и зачищаем партиции
    if trunc_partition(iv_table1, must_date)=0
    or trunc_partition(iv_table2, must_date)=0
    then
      return;
    end if;
    reload_from:=must_date;
    -- Загружаем сразу 2 таблицы
    reload_pmpd(iv_table1);
    -- Перестраиваем индексы
    rebuild_indexes(iv_table1);
    log(iv_table1, '=====>  Заливка таблицы завершена', 'Загружено записей: '||cnt_rows);   
    rebuild_indexes(iv_table2);
    log(iv_table2, '=====>  Заливка таблицы завершена', 'Загружено записей: '||cnt_rows);   
    -- Загрузка PMPD_PAY_DOC
  end make_pd;

  procedure make_pd2(iv_table1 in varchar2, iv_table2 in varchar2)
  is
  begin
    log(iv_table1,'+++ Будут загружаться таблицы '||upper(iv_table1)||' и '||upper(iv_table2)||' по диапазону дат');
    -- Выбираем нужную партицию, отключаем индексы и зачищаем партиции
--    /*
    dbms_application_info.set_module('Загрузка таблиц '||iv_table1, 'delete rows from '||reload_from);

    if week_day < 8 then
--    if week_day < 6 then
      if prepare_partition(iv_table1, 'PAY_DATE')=0
      or prepare_partition(iv_table2, 'PAY_DATE')=0
      then
        return;
      end if;
      delete_rows(iv_table1, 'PAY_DATE', reload_from);
      delete_rows(iv_table2, 'PAY_DATE', reload_from);
    end if;
--    */
    -- Загружаем сразу 2 таблицы
    dbms_application_info.set_module('Загрузка таблиц '||iv_table1, 'load rows from '||reload_from);
    reload_pmpd(iv_table1);
    
    -- Перестраиваем индексы
    dbms_application_info.set_module('Загрузка таблиц '||iv_table1, 'rebuild indexes');
    rebuild_indexes(iv_table1);
    log(iv_table1, '=====>  Заливка таблицы завершена', 'Загружено записей: '||cnt_rows);
    
    rebuild_indexes(iv_table2);
    log(iv_table2, '=====>  Заливка таблицы завершена', 'Загружено записей: '||cnt_rows);
    -- Загрузка PMPD_PAY_DOC
  end make_pd2;

  procedure make_dl2(iv_table1 in varchar2, iv_table2 in varchar2)
  is
  begin
    log(iv_table1,'+++ Будут загружаться таблицы '||upper(iv_table1)||' и '||upper(iv_table2)||' по диапазону дат');
    dbms_application_info.set_module('Загрузка таблиц '||iv_table1, 'delete rows from '||reload_from);
    
    if week_day < 8 then
--    if week_day < 6 then
    -- Выбираем нужную партицию, отключаем индексы и удаляем записи за "v_count_day" последних дней
        if prepare_partition(iv_table1, 'PAY_DATE')=0
        or prepare_partition(iv_table2, 'PAY_DATE')=0
        then
          return;
        end if;
        delete_rows(iv_table1, 'PAY_DATE', reload_from);
        delete_rows(iv_table2, 'PAY_DATE', reload_from);
    end if;
    -- Загружаем сразу 2 таблицы
    dbms_application_info.set_module('Загрузка таблиц '||iv_table1, 'load rows from '||reload_from);
    reload_pmdl(iv_table1);

    -- Перестраиваем индексы
    dbms_application_info.set_module('Загрузка таблиц '||iv_table1, 'rebuild indexes');
    rebuild_indexes(iv_table1);
    log(iv_table1, '=====>  Заливка таблицы завершена', 'Загружено записей: '||cnt_rows);   
    
    rebuild_indexes(iv_table2);
    log(iv_table2, '=====>  Заливка таблицы завершена', 'Загружено записей: '||cnt_rows);   
    -- Загрузка PMPD_PAY_DOC
  end make_dl2;

  procedure make_vdl(iv_table1 in varchar2)
  is
  begin
    log(iv_table1,'+++ Будет загружаться таблица '||upper(iv_table1)||' по диапазону дат');
--    delete_rows(iv_table1, 'PAY_DATE_GFSS', reload_from);

    reload_vdl(iv_table1);
    -- Перестраиваем индексы
    rebuild_indexes(iv_table1);
    log(iv_table1,'+++ Таблица '||upper(iv_table1)||' загружена', 'Загружено записей: '||cnt_rows);
    -- Загрузка PMPD_PAY_DOC
  end make_vdl;

  -- Только для секционированных по рангу таблиц
  -- Ранг - это столбец с полем Дата
  procedure make_pmdl
  is
  v_table varchar2(64);
  begin
    week_day:=to_char(sysdate,'D');
    execute immediate 'alter session set skip_unusable_indexes = true';

    v_table := 'PMDL_DOC_LIST';
    if set_days_reload(v_table)=1 then
        log( v_table, 'Загрузка данных уже выполняется ...');
    else
        if trunc(v_last_success_date) = trunc(sysdate) 
        then
            log( v_table, 'Загрузка данных уже выполнена');
        else
            -- 1. Загружается за период 
            init_log(v_table);    
            make_dl2(v_table, 'PMDL_DOC_LIST_S');
            stop_log(v_table);
            -- 2. Альтернатива - загружается вся партиция
            -- make_dl(v_table, 'PMDL_DOC_LIST2_S');
        end if;
    end if;

    --v_table := 'PNAP_ACT_PRT2';
    --make_pnap2(v_table);
    exception when others then
      begin
          Rollback;
          e_errm:=sqlerrm;
          log( v_table, '! Ошибка', e_errm);
          Update load_tables_status t Set t.end_time = Sysdate, t.state=100, info = e_errm
          Where t.table_name = v_table;
          Commit;
      end;
  end make_pmdl;

  -- Только для секционированных по рангу таблиц
  -- Ранг - это столбец с полем Дата
  procedure make_pmpd
  is
  v_table varchar2(64);
  begin
    week_day:=to_char(sysdate,'D');
    execute immediate 'alter session set skip_unusable_indexes = true';

    v_table := 'PMPD_PAY_DOC';
    if set_days_reload(v_table)=1 then
        log( v_table, 'Загрузка данных уже выполняется ...');
    else
        if trunc(v_last_success_date) = trunc(sysdate)
        then
            log( v_table, 'Загрузка данных уже выполнена');
        else
            -- 1. Загружается за период 
            init_log(v_table);    
            make_pd2(v_table, 'PMPD_PAY_DOC_S');
            stop_log(v_table);
            -- 2. Альтернатива - Загружается вся партиция
            -- make_pd(v_table, 'PMPD_PAY_DOC2_S');
        end if;
    end if;
    --v_table := 'PNAP_ACT_PRT2';
    --make_pnap2(v_table);
    exception when others then
      begin
          Rollback;
          e_errm:=sqlerrm;
          log( v_table, '! Ошибка', e_errm);
          Update load_tables_status t Set t.end_time = Sysdate, t.state=100, info = e_errm
          Where t.table_name = v_table;
          Commit;
      end;
  end make_pmpd;

begin
  execute immediate 'alter session set sort_area_size=50000000';
  execute immediate 'alter session set sort_area_retained_size=50000000';
end load_tables;
/
