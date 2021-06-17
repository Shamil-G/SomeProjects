create or replace package models is

  -- Author  : ГУСЕЙНОВ_Ш
  -- Created : 20.10.2020 16:44:06
  -- Purpose : test python

  -- Public type declarations
  procedure model_new(ititle in char, iintro in varchar2, itext in varchar2);
  procedure model_del(iid in number);
  procedure model_upd(iid in number, ititle in char, iintro in varchar2, itext in varchar2);

  procedure model_calc_new(iid_model in number, idate_calc varchar2);
  procedure model_calc_del(iid_calc number);
  
  procedure run_calculate(iid_calc number);


  procedure run_0701;
  procedure run_0702;
  procedure run_0703;
  procedure run_0705;
  
end models;
/
create or replace package body models is

 procedure log(imess in varchar2)
 is
    PRAGMA AUTONOMOUS_TRANSACTION;
 begin
   insert into log(date_op, msg) values(SYSTIMESTAMP, imess);
   commit;
 end;
 
  procedure model_new(ititle in char, iintro in varchar2, itext in varchar2)
  is
  msg varchar2(1000);
  begin
    msg:='INS Получено: '||ititle || ' : ' || iintro || ' : '||itext;
    insert into protocol values(sysdate, msg);
    commit;
    insert into aktuar_models(id_model, title, intro, text, dat) values(seq_model.nextval, ititle, iintro, itext, sysdate);
    commit;
  end model_new;

  procedure model_del(iid in number)
  is
  msg varchar2(64);
  begin
    msg:='DEL Удалена статья : '||iid;
    insert into protocol values(sysdate, msg);
    commit;
--    delete from aktuar_models a where a.id_model = iid;
    commit;
  end model_del;

  procedure model_upd(iid in number, ititle in char, iintro in varchar2, itext in varchar2)
  is
  msg varchar2(1000);
  begin
    msg:='UPD Получено: '||ititle || ' : ' || iintro || ' : '||itext;
    insert into protocol values(sysdate, msg);
    commit;
    update aktuar_models a
           set a.title=ititle,
               a.intro=iintro,
               a.text=itext,
               a.dat=sysdate
    where a.id_model = iid;
    commit;
  end model_upd;


  procedure model_calc_new(iid_model in number, idate_calc varchar2)
  is
  msg varchar2(1000);
      id_calculate pls_integer;
  begin
    msg:='Model_calc_new. Получен модель: '||iid_model || ', месяц расчета: ' || trunc(to_date(idate_calc,'YYYY-MM-DD'),'MM');
    insert into protocol values(sysdate, msg);
    commit;
    id_calculate:=SEQ_MODEL_CALC.NEXTVAL;
    insert into model_status_calculates(id_calc, date_calc, id_model, st_0701, st_0702, st_0703, st_0705)
           values( id_calculate, trunc(to_date(idate_calc,'YYYY-MM-DD'),'MM'), iid_model, 'Z', 'Z', 'Z', 'Z');
    commit;
    
    run_calculate(id_calculate);
    
    exception when dup_val_on_index then 
      begin
            msg:='Model_calc_new. Дублирование вставки модели: '||iid_model || ', месяц расчета: ' || trunc(to_date(idate_calc,'YYYY-MM-DD'),'MM');
            insert into protocol values(sysdate, msg);
    commit;

      end;
  end model_calc_new;

  procedure model_calc_del(iid_calc number)
  is
  msg varchar2(1000);
  begin
    msg:='Model_calc_del. Удаляем расчеты с id_calc: '||iid_calc;
    insert into protocol values(sysdate, msg);
    commit;
    delete from model_calculates where id_calc=iid_calc;
    delete from model_status_calculates where id_calc=iid_calc;
    commit;
  end model_calc_del;

  --
  procedure run_0705
  is
    v_record     model_status_calculates%rowtype; 
  begin
    dbms_application_info.set_module('Aktuar_Models','Run_0705');    
    select * into v_record
    from model_status_calculates sc 
    where sc.st_0705='E' 
    and   sc.sched_time_0705 is not null
    and   sc.beg_time_0705 is null;

    if v_record.id_calc is null then
      log('0705: Не найдено задание для расчета');
      return;
    end if;
        
    update model_status_calculates sc  
           set sc.st_0705='J',
               sc.beg_time_0705=sysdate
    where sc.id_calc=v_record.id_calc;
    commit;

    aktuar_2020.proc_childcare(v_record.id_calc, v_record.date_calc);
    
    update model_status_calculates sc  
           set sc.st_0705='R',
               sc.end_time_0705=sysdate
    where sc.id_calc=v_record.id_calc;
    commit;
    exception when others then log('0705. Ошибка: '||sqlerrm);
  end;

  procedure run_0703
  is
    v_record     model_status_calculates%rowtype; 
  begin
    dbms_application_info.set_module('Aktuar_Models','Run_0703');    
    select * into v_record
    from model_status_calculates sc 
    where sc.st_0703='E' 
    and   sc.sched_time_0703 is not null
    and   sc.beg_time_0703 is null;

    
    if v_record.id_calc is null then
      log('0703: Не найдено задание для расчета');
      return;
    end if;
        
    update model_status_calculates sc  
           set sc.st_0703='J',
               sc.beg_time_0703=sysdate
    where sc.id_calc=v_record.id_calc;
    commit;

    aktuar_2020.proc_unemployment(v_record.id_calc, v_record.date_calc);
    
    update model_status_calculates sc  
           set sc.st_0703='R',
               sc.end_time_0703=sysdate
    where sc.id_calc=v_record.id_calc;
    commit;
    exception when others then log('0703. Ошибка: '||sqlerrm);
  end;

  procedure run_0702
  is
    v_record     model_status_calculates%rowtype; 
  begin
    dbms_application_info.set_module('Aktuar_Models','Run_0702'); 
    log('0702: Начало работы');   
    select * into v_record
    from model_status_calculates sc 
    where sc.st_0702='E' 
    and   sc.sched_time_0702 is not null
    and   sc.beg_time_0702 is null;
    
    if v_record.id_calc is null then
      log('0702: Не найдено задание для расчета');
      return;
    end if;
    
    update model_status_calculates sc  
           set sc.st_0702='J',
               sc.beg_time_0702=sysdate
    where sc.id_calc=v_record.id_calc;
    commit;
    log('0702: Установили статус работы J');   

    aktuar_2020.proc_disability_with_mortality(v_record.id_calc, v_record.date_calc);
    log('0702: Успешно отработала процедура - proc_disability_with_mortality');   

    aktuar_2020.proc_disability_without_mortality(v_record.id_calc, v_record.date_calc);
    log('0702: Успешно отработала процедура - proc_disability_without_mortality');
    
    update model_status_calculates sc  
           set sc.st_0702='R',
               sc.end_time_0702=sysdate
    where sc.id_calc=v_record.id_calc;
    commit;
    log('0702: Успешно отработал расчет1');

    exception when others then log('0702. Ошибка: '||sqlerrm);
  end;

  procedure run_0701
  is
    v_record     model_status_calculates%rowtype; 
  begin
    log('0701. run_0701 started...');    
    for v_record in ( select * 
                      from model_status_calculates sc 
                      where sc.st_0701 = 'E' 
                      and   sc.sched_time_0701 is not null
                      and   sc.beg_time_0701 is null 
                     )
    loop
        dbms_application_info.set_module('Aktuar_Models','Run_0701');    
        
        update model_status_calculates sc  
               set sc.st_0701='0',
                   sc.beg_time_0701=sysdate
        where sc.id_calc=v_record.id_calc;
        commit;

        aktuar_2020.proc_bw_1(v_record.id_calc, v_record.date_calc);
        update model_status_calculates sc  
               set sc.st_0701='1',
                   sc.beg_time_0701=sysdate
        where sc.id_calc=v_record.id_calc;
        commit;

        aktuar_2020.proc_bw_2(v_record.id_calc, v_record.date_calc);
        update model_status_calculates sc  
               set sc.st_0701='2',
                   sc.beg_time_0701=sysdate
        where sc.id_calc=v_record.id_calc;
        commit;

        aktuar_2020.proc_bw_3(v_record.id_calc, v_record.date_calc);
        update model_status_calculates sc  
               set sc.st_0701='3',
                   sc.beg_time_0701=sysdate
        where sc.id_calc=v_record.id_calc;
        commit;

        aktuar_2020.proc_bw_4(v_record.id_calc, v_record.date_calc);
        
        update model_status_calculates sc  
               set sc.st_0701='R',
                   sc.end_time_0701=sysdate
        where sc.id_calc=v_record.id_calc;
        commit;
    end loop;
    exception when others then log('0701. Ошибка: '||sqlerrm);
  end;

  -- Стандартный блок
  procedure run_calculate(iid_calc number)
  is
    v_record     model_status_calculates%rowtype; 
  begin
    for v_record in ( select * 
                      from model_status_calculates sc 
                      where sc.id_calc=iid_calc )
    loop
        -- Расчет проведен 0705
        if v_record.st_0705='Z' 
        then
            update model_status_calculates sc  
                   set sc.st_0705='E',
                       sc.sched_time_0705=sysdate
            where sc.id_calc=v_record.id_calc;
            commit;
            DBMS_SCHEDULER.CREATE_JOB (
              job_name                 =>  'Aktuar2020_0705_'||extract(year from sysdate)||extract(month from sysdate),
              job_type                 =>  'PLSQL_BLOCK',
              job_action               =>  'BEGIN models.run_0705; END;',
              enabled                  =>  true );
        end if;

        --dbms_lock.sleep(300);

        if v_record.st_0703='Z' 
        then
            update model_status_calculates sc  
                   set sc.st_0703='E',
                       sc.sched_time_0703=sysdate
            where sc.id_calc=v_record.id_calc;
            commit;
            DBMS_SCHEDULER.CREATE_JOB (
              job_name                 =>  'Aktuar2020_0703_'||extract(year from sysdate)||extract(month from sysdate),
              job_type                 =>  'PLSQL_BLOCK',
              job_action               =>  'BEGIN models.run_0703; END;',
              enabled                  =>  true );
        end if;
        
        --dbms_lock.sleep(1800);

        if v_record.st_0702='Z' 
        then
            update model_status_calculates sc  
                   set sc.st_0702='E',
                       sc.sched_time_0702=sysdate
            where sc.id_calc=v_record.id_calc;
            commit;
            DBMS_SCHEDULER.CREATE_JOB (
              job_name                 =>  'Aktuar2020_0702_'||extract(year from sysdate)||extract(month from sysdate),
              job_type                 =>  'PLSQL_BLOCK',
              job_action               =>  'BEGIN models.run_0702; END;',
              enabled                  =>  true );
        end if;

        if v_record.st_0701='Z' 
        then
            update model_status_calculates sc  
                   set sc.st_0701='E',
                       sc.sched_time_0701=sysdate
            where sc.id_calc=v_record.id_calc;
            commit;
            DBMS_SCHEDULER.CREATE_JOB (
              job_name                 =>  'Aktuar2020_0701_'||extract(year from sysdate)||extract(month from sysdate),
              job_type                 =>  'PLSQL_BLOCK',
              job_action               =>  'BEGIN models.run_0701; END;',
              enabled                  =>  true );
        end if;
    end loop;
    exception when others then log('RUN_CALCULATION. Fault: '||sqlerrm);
  end;

begin
    execute immediate 'alter session set NLS_DATE_FORMAT = "dd.mm.yyyy"';
  -- Initialization
/*
grant create job to shamil;
*/  
end models;
/
