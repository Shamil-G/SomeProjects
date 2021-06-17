create or replace package refund_031knp is

  -- Author  : БЕГАДИЛОВ_М
  -- Created : 03.06.2021 9:14:06
  -- Purpose : Невошедшие возвраты излишне перечисленных СО
  
 procedure add_sior(
    isior_id  in number,
    iid_user  in number,
    idoc_ret  in number,  
    idate_ret in varchar2,
    isum_ret   in number,
    idate_ret_gk in varchar2,
    isum_ret_gk   in number,
    idoc_num_df in nvarchar2,
    idoc_date_df  in varchar2,
    ireason_return in nvarchar2
    ); 
/* 
 procedure update_df
    (   v_doc_ret in number,  
        v_date_ret in date,
        v_doc_num_df in nvarchar2,
        v_doc_date_df  in date,
        v_reason_return in nvarchar2,
        v_sior_id  in number );
*/        
 procedure hist_delete(iid_hist in number, iid_user in number);

end refund_031knp;
/
create or replace package body refund_031knp is
--/*

 procedure log(imess in varchar2)
 is
    PRAGMA AUTONOMOUS_TRANSACTION;
 begin
   insert into log(date_op, msg) values(SYSTIMESTAMP, imess);
   commit;
 end;
 
  procedure add_sior
    (
    isior_id  in number,
    iid_user  in number,
    idoc_ret  in number,  
    idate_ret in varchar2,
    isum_ret   in number,
    idate_ret_gk in varchar2,
    isum_ret_gk   in number,
    idoc_num_df in nvarchar2,
    idoc_date_df  in varchar2,
    ireason_return in nvarchar2
    )
  is
    v_gfss_in_nom  NVARCHAR2(30);
    v_doc_date DATE;
    v_period VARCHAR2(6);
    v_sum_gfss NUMBER(11,2);
    v_p_bin NCHAR(14);
    v_p_name NVARCHAR2(300);
    v_sicid NUMBER(11);
    v_iin CHAR(12);
    v_fio hist_ret_SO_031KNP.Fio%type;
  begin 
   log('Начало. Для isior_id: '||isior_id||' начали SELECT');

    select   j.gfss_in_nom,
             to_char(gfss_in_date,'dd.mm.yyyy') doc_date,
             dl.period,
             dl.sum_gfss,
             r.p_bin,
             r.p_name,
             p.sicid,
             dl.iin         
    into v_gfss_in_nom,v_doc_date,v_period,v_sum_gfss,v_p_bin,v_p_name,v_sicid,v_iin
    from test_gfss_pay_doc@crtr pd  ,test_gfss_order_ret_list@crtr dl, test_sior_order_ret@crtr r, gfss_journal@crtr j, test_mhmh_gfss_gcvp@crtr mh, person@crtr p   
    where dl.mhmh_id(+) = pd.mhmh_id
    and r.sior_id=dl.sior_id
    and j.id = pd.id_journ
    and pd.mhmh_id = mh.mhmh_id
    and mh.sior_id=r.sior_id
    and p.rn=dl.iin
    and dl.sior_id=isior_id;

    select p.lastname||' '||substr(p.firstname,1,1)||'.'||substr(p.middlename,1,1)||'.' 
    into v_fio 
    from person@crtr p 
    where p.sicid=v_sicid;
    
    log('Начинаем INSERT. Для isior_id: '||isior_id||', найдено v_gfss_in_nom: '||v_gfss_in_nom||', v_period: '||v_period||
          ', v_sum_gfss: '||v_sum_gfss||', isum_ret: '||isum_ret||', idoc_date_df: '||idoc_date_df||', idate_ret: '||idate_ret);
    
   insert into HIST_RET_SO_031KNP
           (id_hist,ID_USER, DATE_OP, sior_id, deleted, 
            gfss_in_nom, doc_date, period, sum_gfss, 
            p_bin, p_name, sicid, iin, fio, 
            doc_ret, date_ret, sum_ret, date_ret_gk, sum_ret_gk, 
            doc_num_df, doc_date_df, reason_return )
   values  (seq_hist_ret.nextval, to_number(iid_user), CURRENT_TIMESTAMP, to_number(isior_id), 'N', 
           v_gfss_in_nom, v_doc_date, v_period, v_sum_gfss, 
           v_p_bin, v_p_name, v_sicid, v_iin, v_fio,
           idoc_ret, to_date(idate_ret,'yyyy-mm-dd'), isum_ret, to_date(idate_ret_gk,'yyyy-mm-dd'), isum_ret_gk, 
           idoc_num_df , to_date(idoc_date_df,'yyyy-mm-dd'), ireason_return);
/*           
   insert into HIST_RET_SO_031KNP
           (id_hist,ID_USER, DATE_OP, sior_id, deleted, gfss_in_nom, doc_date, period, 
            sum_gfss, p_bin, p_name, sicid, iin, doc_ret, sum_ret, date_ret, doc_num_df , 
            doc_date_df, reason_return )
   values  (seq_hist_ret.nextval, to_number(iid_user), CURRENT_TIMESTAMP, to_number(isior_id), 'N', v_gfss_in_nom, v_doc_date, 
           v_period, v_sum_gfss, v_p_bin, v_p_name, v_sicid, 
           v_iin, isum_ret, idoc_ret, to_date(idate_ret,'yyyy-mm-dd') , idoc_num_df , to_date(idoc_date_df,'yyyy-mm-dd'), ireason_return);
*/           
   commit;
   exception when others then
     log('Exception isior_id: '||isior_id||', iid_user: '||iid_user||', idoc_ret: '||idoc_ret||
            ', idate_ret: '||idate_ret||', isum_ret: '||isum_ret||', idoc_num_df: '||idoc_num_df||
            ', idoc_date_df:'||idoc_date_df||', ireason_return: '||ireason_return ||', sqlerror: '||sqlerrm);
 end add_sior;

  function is_admin(iid_user in number) return pls_integer
  is
    v_ret pls_integer default 0;
  begin
    select 1
    into v_ret
    from roles r, users_roles ur, users u
    where u.id_user=iid_user
    and u.id_user=ur.id_user
    and ur.id_role=r.id_role 
    and r.name='Admin';
    return v_ret;
    exception when no_data_found then return 0;
  end;
 
  procedure hist_delete(iid_hist in number, iid_user in number) 
  is
--    v_status char(1);
  begin
    if is_admin(iid_user)=1 then
       update HIST_RET_SO_031KNP t
       set t.deleted= case when t.deleted = 'N' then 'Y' else 'N' end  
       where t.id_hist= iid_hist;
    else
       update HIST_RET_SO_031KNP t
       set t.deleted='Y'
       where t.id_hist= iid_hist;
    end if;
     commit;
  end hist_delete;

  begin
      execute immediate 'alter session set NLS_DATE_FORMAT = "dd.mm.yyyy"';
    
end refund_031knp;
/
