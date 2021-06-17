create or replace package aktuar_2020 is

  -- Author  : ГУСЕЙНОВ_Ш
  -- Created : 11.08.2020 15:00:47
  -- Purpose : Проведение актуарных расчетов
  
  --0705
  procedure proc_childcare(iid_calc pls_integer, idate date);
  --0703
  procedure proc_unemployment(iid_calc pls_integer, idate date);

  --0702  
  procedure proc_disability_with_mortality(iid_calc pls_integer, idate date);
  procedure proc_disability_without_mortality(iid_calc pls_integer, idate date);
  --0701
  procedure proc_BW_1(iid_calc pls_integer, idate date); 
  procedure proc_BW_2(iid_calc pls_integer, idate date);
  procedure proc_BW_3(iid_calc pls_integer, idate date);
  procedure proc_BW_4(iid_calc pls_integer, idate date);

end  aktuar_2020;
/
create or replace package body aktuar_2020 is

  v_pnpt_id pls_integer default 0;
  v_rfpm   varchar2(8);
  is_pnpt  char(1);

  on_print char(1);
  v_date_calculate date;
  cmd varchar2(512);
/*
  type age is record(
       years pls_integer,
       months pls_integer,
       days   pls_integer
  );
*/
  -- Работать будем со списком
  TYPE My_Cursor  IS REF CURSOR;
  type aktuar_dependant_t is record(
       row_number   number,
       pncd_id      sswh.aktuar_dependant.pncd_id%type,
       birthdate    sswh.aktuar_dependant.birthdate%type,
       appointdate  sswh.aktuar_dependant.appointdate%type,
       stopdate     sswh.aktuar_dependant.stopdate%type,
       sum_pay      sswh.aktuar_dependant.sum_pay%type,
       depend_birthdate sswh.aktuar_dependant.depend_birthdate%type
  );
  TYPE aktuar_dependant_table IS TABLE OF aktuar_dependant_t index by pls_integer;
  table_aktuar_dependant aktuar_dependant_table;
  l_index pls_integer default 0;

 procedure log(imess in varchar2)
 is
    PRAGMA AUTONOMOUS_TRANSACTION;
 begin
   insert into log(date_op, msg) values(SYSTIMESTAMP, imess);
   commit;
 end;

  procedure set_print(ion_print in char)
  is
  begin
    on_print:=ion_print;
  end set_print;

  procedure print_line(iid_calc pls_integer, iCalc_type char, iPNPT_ID pls_integer, iIRFPM_ID varchar, iSUMM_ALL NUMBER, idate_stop date)
  is
    PRAGMA AUTONOMOUS_TRANSACTION;
  begin
    if on_print='Y' then
      INSERT INTO model_calculates( id_calc, calc_type, PNPT_ID, RFPM_ID, SUMM_ALL, date_stop) 
             VALUES(iid_calc, iCalc_type, iPNPT_ID, iIRFPM_ID, iSUMM_ALL, idate_stop);
      commit;
    end if;
    exception when dup_val_on_index then 
      begin
      INSERT INTO model_calculates_err( id_calc, calc_type, PNPT_ID, RFPM_ID, SUMM_ALL, date_stop) 
             VALUES(iid_calc, iCalc_type, iPNPT_ID, iIRFPM_ID, iSUMM_ALL, idate_stop);
      commit;
      end;
  end print_line;

  function fprint_line(iid_calc pls_integer, iCalc_type char, iPNPT_ID pls_integer, iIRFPM_ID varchar, iSUMM_ALL NUMBER, idate_stop date)
           return pls_integer
  is
    PRAGMA AUTONOMOUS_TRANSACTION;
  begin
    if on_print='Y' then
      INSERT INTO model_calculates( id_calc, calc_type, PNPT_ID, RFPM_ID, SUMM_ALL, date_stop) 
             VALUES(iid_calc, iCalc_type, iPNPT_ID, iIRFPM_ID, iSUMM_ALL, idate_stop);
      commit;
      return 0;
    end if;
    
    exception when dup_val_on_index then 
      begin
        INSERT INTO model_calculates_err( id_calc, calc_type, PNPT_ID, RFPM_ID, SUMM_ALL, date_stop) 
               VALUES(iid_calc, iCalc_type, iPNPT_ID, iIRFPM_ID, iSUMM_ALL, idate_stop);
      commit;
      return 1;
      end;
  end fprint_line;


  function get_days(idate1 date, idate2 date) return pls_integer
  is
  begin
    return  idate1 - idate2;
  end get_days;

  function get_coeff(imax_rows pls_integer, curr_row pls_integer) return number DETERMINISTIC
  is
  v_coeff number(10,8);
  begin
    select p.value into v_coeff from sswh.aktuar_dependant_parms p where lower(p.name_param)='coeff_depend' and p.code1=to_char(imax_rows) and p.code2=to_char(curr_row);
    return v_coeff;
    exception when others then
       raise_application_error(-20001, 'function get_coeff. imax_rows: '||imax_rows||chr(10)||'curr_row: '||curr_row||chr(10));
  end get_coeff;
--/*
  function correct_pension_date(birthdate in date, ilast_date in date) return date
  is
    res date;
  begin
    res:=trunc(ilast_date,'MM')+extract(day from birthdate)-1;
    return res;
  end correct_pension_date;
--*/
  function get_pension_age (birthdate in date, sex in char) return number
  is
    return_age number(4,2);
  begin
    case when sex='1' then return_age := 63;
          when birthdate<'01.01.1960' then return_age:=58;
          when birthdate<'01.07.1960' then return_age:=58.5;
          when birthdate<'01.01.1961' then return_age:=59;
          when birthdate<'01.07.1961' then return_age:=59.5;
          when birthdate<'01.01.1962' then return_age:=60;
          when birthdate<'01.07.1962' then return_age:=60.5;
          when birthdate<'01.01.1963' then return_age:=61;
          when birthdate<'01.07.1963' then return_age:=61.5;
          when birthdate<'01.01.1964' then return_age:=62;
          when birthdate<'01.07.1964' then return_age:=62.5;
          else return_age:=63;
    end case;

    return return_age;
  end get_pension_age;

  function get_pension_date (birthdate in date, sex in char) return date
  is
    add_yer   pls_integer default 0;
    add_mon   pls_integer default 0;
    v_day     pls_integer default 0;
    return_date date;
  begin
    v_day:=extract( day from birthdate);
    case when sex='1' then add_yer := 63;
        when birthdate<'01.01.1960' then add_yer:=58;
        when birthdate<'01.07.1960' then add_yer:=58; add_mon:=6;
        when birthdate<'01.01.1961' then add_yer:=59;
        when birthdate<'01.07.1961' then add_yer:=59; add_mon:=6;
        when birthdate<'01.01.1962' then add_yer:=60;
        when birthdate<'01.07.1962' then add_yer:=60; add_mon:=6;
        when birthdate<'01.01.1963' then add_yer:=61;
        when birthdate<'01.07.1963' then add_yer:=61; add_mon:=6;
        when birthdate<'01.01.1964' then add_yer:=62;
        when birthdate<'01.07.1964' then add_yer:=62; add_mon:=6;
        else add_yer:=63;
    end case;

    return_date:=trunc(add_months(birthdate, add_yer*12+add_mon),'MM')+v_day-1;
--    return_date:=add_months(birthdate, add_yer*12+6);
    return return_date;
    exception when others then 
        log( '0702: get_pension_date, birthdate: '||birthdate||', return_date: '||return_date||', error: '||sqlerrm);    
  end get_pension_date;

  function get_23_date (birthdate in date, age_23 in number) return date
  is
    v_day     pls_integer default 0;
    return_date date;
  begin
    v_day:=extract( day from birthdate);

    return_date:=trunc(add_months(birthdate, age_23*12),'MM')+v_day-1;
    return return_date;
  end get_23_date;

  function get_max_age return pls_integer DETERMINISTIC
  is
  v_age number;
  begin
    select p.value into v_age from sswh.aktuar_dependant_parms p where lower(p.name_param)='coeff_depend' and p.code1='max_age' and rownum=1;
    return v_age;
  end get_max_age;

  function bread_winner return number
  is
    cnt_bw pls_integer;
    list_dependant My_Cursor;
    v_days    pls_integer default 0;
    v_coeff   number(12,10);
    v_result  number(16,5);
    v_get_23_date date;
    v_max_age number(4,2);
  begin
    cmd:='select row_number() over( partition by ad.pncd_id order by ad.depend_birthdate) row_num, '||
         'ad.pncd_id, ad.birthdate, ad.appointdate, ad.stopdate, ad.sum_pay, ad.depend_birthdate '||
         'from (select unique ad1.*, row_number() over( partition by ad1.depend_sicid order by ad1.depend_birthdate) rnum '||
         'from sswh.aktuar_dependant ad1 '||
         'where ad1.pnpt_id=:D1 '--3089421
         ||'and ad1.mnth=:D2) ad '|| --'01.08.2020'
         'where ad.rnum=1 '||
         'order by ad.depend_birthdate desc';

    v_max_age:=get_max_age;

    open list_dependant for cmd using v_pnpt_id, v_date_calculate;
    fetch list_dependant bulk collect into table_aktuar_dependant;
    cnt_bw:=table_aktuar_dependant.last;
    v_result:=0;

    for l_index in  table_aktuar_dependant.first ..  table_aktuar_dependant.last
    loop
      begin
          v_coeff:=get_coeff(cnt_bw,cnt_bw-l_index+1);

--          if cnt_bw=l_index+1 then --  Предпоследняя запись
--          if cnt_bw!=l_index then --  Предпоследняя запись
          v_get_23_date:=get_23_date(table_aktuar_dependant(l_index).depend_birthdate, v_max_age);
          if cnt_bw=l_index then
              v_days:=get_days(  case
--                                      when table_aktuar_dependant(l_index).depend_birthdate is null
--                                      then table_aktuar_dependant(l_index).stopdate
--/*
                                      when v_get_23_date>table_aktuar_dependant(l_index).stopdate
                                      then v_get_23_date
                                      when v_get_23_date<=table_aktuar_dependant(l_index).stopdate and
                                           v_get_23_date>v_date_calculate
                                      then v_get_23_date
----                                      then table_aktuar_dependant(l_index).stopdate
--*/
                                      else
                                           table_aktuar_dependant(l_index).stopdate
--                                          table_aktuar_dependant(l_index).depend_birthdate+get_max_age*365.25
                                 end,
                                 v_date_calculate);
              v_result:=v_result+v_coeff*v_days;
          else
              v_days:=get_days(v_get_23_date,
                               case when
                                          get_23_date(table_aktuar_dependant(l_index+1).depend_birthdate, v_max_age)<v_date_calculate
--                                        table_aktuar_dependant(l_index+1).depend_birthdate+get_max_age*365.25<v_date_calculate
                                    then table_aktuar_dependant(l_index).stopdate
--                                    then v_date_calculate
                                    else
                                        get_23_date(table_aktuar_dependant(l_index+1).depend_birthdate, v_max_age)
--                                      table_aktuar_dependant(l_index+1).depend_birthdate+get_max_age*365.25
                               end );
              v_result:=v_result+ case when v_days>0
                                     then v_coeff*v_days
                                     else 0 end;
              null;
--              v_days:=get_days(table_aktuar_dependant(l_index).depend_birthdate, table_aktuar_dependant(l_index+1).depend_birthdate);
--              v_result:=coalesce(v_result,0)+v_coeff*v_days;
          end if;

/*
        if l_index=2 then
        raise_application_error(-20002, 'row_number: '||table_aktuar_dependant(l_index).row_number||chr(10)||
                                        'cnt_bw: '||cnt_bw||chr(10)||
                                        'l_index: '||l_index||chr(10)||
                                        'sum_pay: '||table_aktuar_dependant(l_index).sum_pay||chr(10)||
                                        'depend_birthdate: '||table_aktuar_dependant(l_index).depend_birthdate||chr(10)||
                                        'v_get_23_date: '||v_get_23_date||chr(10)||
                                        'v_max_age: '||v_max_age||chr(10)||
--                                        'depend_birthdate_2: '||table_aktuar_dependant(l_index+1).depend_birthdate||chr(10)||
                                        'v_date_calculate: '||v_date_calculate||chr(10)||
                                        'stop_date: '||table_aktuar_dependant(l_index).stopdate||chr(10)||
                                        'v_days: '||v_days||chr(10)||
                                        'max_rows: '||cnt_bw||chr(10)||
                                        'v_coeff: '||v_coeff||chr(10)||
                                        'v_result: '||v_result||chr(10)
                                        );
       end if;
--*/

/*
      exception when others then
        raise_application_error(-20002, 'row_number: '||table_aktuar_dependant(l_index).row_number||chr(10)||
                                        'sum_pay: '||table_aktuar_dependant(l_index).sum_pay||chr(10)||
                                        'depend_birthdate: '||table_aktuar_dependant(l_index).depend_birthdate||chr(10)||
                                        'max_rows: '||cnt_bw||chr(10)||
                                        'v_coeff: '||v_coeff||chr(10)||
                                        'v_days: '||v_days||chr(10)||
                                        'l_index: '||l_index||chr(10)||
                                        'v_addon: '||v_addon||chr(10)||sqlerrm
                                        );
*/
      end;
    end loop;
    v_result:=v_result*table_aktuar_dependant(cnt_bw).sum_pay*12/365.25;
--    print_line(v_pnpt_id, v_rfpm, v_result);
    table_aktuar_dependant.delete;
/*
        raise_application_error(-20002, 'max_rows: '||cnt_bw||chr(10)||
                                        'v_coeff: '||v_coeff||chr(10)||
                                        'v_days: '||v_days||chr(10)||
                                        'l_index: '||l_index||chr(10)||
                                        'v_result: '||v_result||chr(10)||sqlerrm
                                        );

--*/
/*  Формула в Excel для одного иждивенца
    =N8* -- =1 если выплата на одного
    $Y8*12*H8*  -- Y -  проверка по датам, что выплата действительна, H-  назначенная сумма в месяц
    (L8-Summary!$B$30)/365,25 -- кол-во дней от даты расчета до даты закрытия выплаты
*/
/*  Формула в Excel для двух иждивенца
    =P19537* -- =1 если выплата на двоих
    $Y19537*12*$H19537*
    (($L19537-Summary!$B$30)+ -- кол-во дней от даты расчета до даты закрытия выплаты
    (5/6,5)*
    МАКС(($K19538+$B$1*365,25-$L19537);0))/365,25 -- K- дата рождения иждивенца второго иждивенца  В- до скольки лет он может быть иждивецем (23 года)
*/
/*  Формула в Excel на трех иждивенцев
    =Q37766*
    $Y37766*12*$H37766*
    (($L37766-Summary!$B$30)+
    (6,5/8)*
    МАКС(($K37767+$B$1*365,25-$L37766);0)+
    (5/8)*($K37768-$K37767))/365,25
*/
/*  Формула в Excel на четырех иждивенцев
    =R48033*
    $Y48033*12*$H48033*
    (($L48033-Summary!$B$30)+
    (8/10)*
    МАКС(($K48034+$B$1*365,25-$L48033);0)+
    (6,5/10)*($K48035-$K48034)+
    (5/10)*($K48036-$K48035))/365,25
*/
/*  Формула в Excel на пятерых иждивенцев
    =S48037*
    $Y48037*12*$H48037*
    (($L48037-Summary!$B$30)+
    (10/10)*
    МАКС(($K48038+$B$1*365,25-$L48037);0)+
    (8/10)*($K48039-$K48038)+
    (6,5/10)*($K48040-$K48039)+
    (5/10)*($K48041-$K48040))/365,25
*/
/*  Формула в Excel на шестерых иждивенцев
    =T48063*
    $Y48063*12*$H48063*
    (($L48063-Summary!$B$30)+
    (10/10)*МАКС(($K48064+$B$1*365,25-$L48063);0)+
    (10/10)*($K48065-$K48064)+
    (8/10)*($K48066-$K48065)+
    (6,5/10)*($K48067-$K48066)+
    (5/10)*($K48068-$K48067))/365,25
*/
/*  Формула в Excel на семерых иждивенцев
    =U48355*
    $Y48355*12*$H48355*
    (($L48355-Summary!$B$30)+
    (10/10)*МАКС(($K48356+$B$1*365,25-$L48355);0)+
    (10/10)*($K48357-$K48356)+
    (10/10)*($K48358-$K48357)+
    (8/10)*($K48359-$K48358)+
    (6,5/10)*($K48360-$K48359)+
    (5/10)*($K48361-$K48360))/365,25
*/
/*  Формула в Excel на вомьмерых иждивенцев, sicid=3089421
    =V48847*
    $Y48847*12*$H48847*
    (($L48847-Summary!$B$30)+
    (10/10)*МАКС(($K48848+$B$1*365,25-$L48847);0)+
    (10/10)*($K48849-$K48848)+
    (10/10)*($K48850-$K48849)+
    (10/10)*($K48851-$K48850)+
    (8/10)*($K48852-$K48851)+
    (6,5/10)*($K48853-$K48852)+
    (5/10)*($K48854-$K48853))/365,25
*/

     return v_result;
  end;

  function bread_winner(iin varchar2) return number
  is
  begin
    select p.sicid into v_pnpt_id from sswh.person p where p.rn=iin;
    --
    return bread_winner;
  end;

  function bread_winner(ipnpt_id pls_integer) return number
  is
  begin
    v_pnpt_id:=ipnpt_id;
    return bread_winner;
  end;

  procedure get_result_BW_1(iid_calc pls_integer)
  is
    cnt pls_integer default 0;
    cnt_all pls_integer default 0;
    all_summ  number(19,2);
    curr_summ number(19,2);
  begin
    all_summ:=0;
    cnt:=0;
    log('0701: Начало работы: '||v_rfpm);
    dbms_application_info.set_module('aktuar_2020','get_result_BW_1');
    for cur in ( select unique ad.pnpt_id, ad.stopdate date_stop 
                 from sswh.aktuar_dependant ad 
                 where ad.mnth=v_date_calculate 
                 and   ad.rfpm_id=v_rfpm 
               )
    loop
      begin
        cnt:=cnt+1;
        cnt_all:=cnt_all+1;
        if cnt>1023 then
           dbms_application_info.set_module('aktuar_2020','get_result_BW_1: '||cnt_all||' дел');
           cnt:=0;
        end if;
        curr_summ:=coalesce(aktuar_2020.bread_winner(cur.pnpt_id),0);
        all_summ:=all_summ+coalesce(curr_summ,0);

        print_line(iid_calc, '1',cur.pnpt_id, v_rfpm, curr_summ, cur.date_stop);
      exception when others then
          log('Aktuar_2020, get_result_BW_1, Ощибка. pnpt_id: '||cur.pnpt_id);
          raise_application_error(-20000, 'get_result_BW_1, pnpt_id: '||cur.pnpt_id||' : '||sqlerrm);
      end;
    end loop;
    log('0701: Завершен расчет по: '||v_rfpm||', Дел: '||cnt_all||', Сумма: '||all_summ);
  end get_result_BW_1;


  procedure get_result_BW_2(iid_calc pls_integer)
  is
    cnt pls_integer default 0;
    cnt_all pls_integer default 0;
    all_summ  number(19,2);
    curr_summ number(19,2);
  begin
    all_summ:=0;
    cnt:=0;
    log('0701: Начало работы: '||v_rfpm);
    dbms_application_info.set_module('aktuar_2020','get_result_BW_2');
    for cur in ( select unique ad.pnpt_id, max(ad.stopdate) date_stop 
                 from sswh.aktuar_dependant ad 
                 where ad.mnth=v_date_calculate 
                 and ad.rfpm_id='07010102' 
                 group by (ad.pnpt_id)
                )
    loop
      begin
        cnt:=cnt+1;
        cnt_all:=cnt_all+1;
        if cnt>1023 then
           dbms_application_info.set_module('aktuar_2020','get_result_BW_2: '||cnt_all||' дел');
           cnt:=0;
        end if;
        curr_summ:=coalesce(aktuar_2020.bread_winner(cur.pnpt_id),0);
        all_summ:=all_summ+curr_summ;

        print_line(iid_calc, '2', cur.pnpt_id, '07010102', curr_summ, cur.date_stop);
      exception when others then
          log('Aktuar_2020, get_result_BW_2, Ощибка. pnpt_id: '||cur.pnpt_id);
          raise_application_error(-20000, 'get_result_BW_2, pnpt_id: '||cur.pnpt_id||' : '||sqlerrm);
      end;
    end loop;
    log('0701: Завершен расчет по: '||v_rfpm||', Дел: '||cnt_all||', Сумма: '||all_summ);
  end get_result_BW_2;


  procedure get_result_BW_3(iid_calc pls_integer)
  is
    cnt pls_integer default 0;
    cnt_all pls_integer default 0;
    all_summ  number(19,2);
    curr_summ number(19,2);
  begin
    all_summ:=0;
    cnt:=0;
    log('0701: Начало работы: '||v_rfpm);
    dbms_application_info.set_module('aktuar_2020','get_result_BW_3');
    for cur in ( select unique ad.pnpt_id, max(ad.stopdate) date_stop 
                 from sswh.aktuar_dependant ad 
                 where ad.mnth=v_date_calculate 
                 and ad.rfpm_id='07010103' 
                 group by (ad.pnpt_id)
                )
    loop
      begin
        cnt:=cnt+1;
        cnt_all:=cnt_all+1;
        if cnt>1023 then
           dbms_application_info.set_module('aktuar_2020','get_result_BW_3: '||cnt_all||' дел');
           cnt:=0;
        end if;
        curr_summ:=coalesce(aktuar_2020.bread_winner(cur.pnpt_id),0);
        all_summ:=all_summ+curr_summ;

        print_line(iid_calc, '3', cur.pnpt_id, '07010103', curr_summ, cur.date_stop);
      exception when others then
          log('aktuar_2020, get_result_BW_3, Ошибка. pnpt_id: '||cur.pnpt_id);
          raise_application_error(-20000, 'get_result__BW_3, pnpt_id: '||cur.pnpt_id||' : '||sqlerrm);
      end;
    end loop;
    log('0701: Завершен расчет по: '||v_rfpm||', Дел: '||cnt_all||', Сумма: '||all_summ);
  end get_result_BW_3;

  procedure get_result_BW_4(iid_calc pls_integer)
  is
    cnt pls_integer default 0;
    cnt_all pls_integer default 0;
    all_summ  number(19,2);
    curr_summ number(19,2);
  begin
    all_summ:=0;
    cnt:=0;
    log('0701: Начало работы: '||v_rfpm);
    dbms_application_info.set_module('aktuar_2020','get_result_BW_4');
    for cur in ( select unique ad.pnpt_id, max(ad.stopdate) date_stop 
                 from sswh.aktuar_dependant ad 
                 where ad.mnth=v_date_calculate 
                 and ad.rfpm_id='07010104' 
                 group by (ad.pnpt_id)
                )
    loop
      begin
        cnt:=cnt+1;
        cnt_all:=cnt_all+1;
        if cnt>1023 then
           dbms_application_info.set_module('aktuar_2020','get_result_BW_4: '||cnt_all||' дел');
           cnt:=0;
        end if;
        curr_summ:=coalesce(aktuar_2020.bread_winner(cur.pnpt_id),0);
        all_summ:=all_summ+curr_summ;

        print_line(iid_calc, '4', cur.pnpt_id, '07010104', curr_summ, cur.date_stop);
      exception when others then
          log('Aktuar_2020, get_result_BW_4, Ощибка. pnpt_id: '||cur.pnpt_id);
          raise_application_error(-20000, 'get_result_BW_4, pnpt_id: '||cur.pnpt_id||' : '||sqlerrm);
      end;
    end loop;
    log('0701: Завершен расчет по: '||v_rfpm||', Дел: '||cnt_all||', Сумма: '||all_summ);
  end get_result_BW_4;


  function get_expect_duration_live(age_valuation in number, years_before_pension in number, sex in char) return number
  is
     value_age_valuation        number(10,2);
     value_age_valuation_Dx     number(10,2);
     value_age_valuation_Dy     number(10,2);
     value_years_before_pension number(10,2);
     result                     number(10,7);
  begin
    /*
      ЕСЛИ(  C8=1; (
                  ВПР(T8;com;6) - ВПР(T8+V8;com;6) --T8: age_valuation, V8: сколько лет до пенсии с округлением вверх
                  )
                  /
                  ВПР(T8;com;4);
            ЕСЛИ ( C8=0;
                      (
                        ВПР(T8;com;7)-
                        ВПР(T8+V8;com;7)
                      )
                      /
                      ВПР(T8;com;5);"Error"
                )
          )
    */
--    raise_application_error(-20000, 'sex: '||sex||chr(10)||'age_valuation: '||age_valuation||chr(10)||'years_before_pension: '||years_before_pension);
     if sex='1' then
       begin
            select Nx
            into value_age_valuation
            from sswh.aktuar_target_model_disability p
            where p.age=age_valuation
            and   coalesce(m_id,1)=1;

            select Nx
            into   value_years_before_pension
            from   sswh.aktuar_target_model_disability p
            where  p.age=age_valuation+years_before_pension
            and   coalesce(m_id,1)=1;

            select Dx
            into   value_age_valuation_Dx
            from   sswh.aktuar_target_model_disability p
            where  p.age=age_valuation
            and   coalesce(m_id,1)=1;

            result:=(value_age_valuation-value_years_before_pension)/value_age_valuation_Dx;
/*
            raise_application_error(-20000, 'sex: '||sex||chr(10)||
                                            'NX age_valuation: '||age_valuation||chr(10)||
                                            'value_age_valuation: '||value_age_valuation||chr(10)||
                                            'Nx_years_before_pension: '||years_before_pension||chr(10)||
                                            'value_years_before_pension: '||value_years_before_pension||chr(10)||
                                            'Dx_age_valuation: '||age_valuation||chr(10)||
                                            'value_age_valuation_Dx: '||value_age_valuation_Dx||chr(10)||
                                            'result: '||result);
--*/
        exception when no_data_found then
--          raise_application_error(-20100, 'sex: '||sex||chr(10)||'age_valuation: '||age_valuation||chr(10)||'years_before_pension: '||years_before_pension||chr(10)||'result: '||result);
          return 0;
        end;
     elsif sex='0' then
       begin
            select Ny
            into value_age_valuation
            from sswh.aktuar_target_model_disability p
            where p.age=age_valuation
            and   coalesce(m_id,1)=1;

            select Ny
            into   value_years_before_pension
            from   sswh.aktuar_target_model_disability p
            where  p.age=age_valuation+years_before_pension
            and   coalesce(m_id,1)=1;

            select Dy
            into   value_age_valuation_Dy
            from   sswh.aktuar_target_model_disability p
            where  p.age=age_valuation
            and   coalesce(m_id,1)=1;

            result:=(value_age_valuation-value_years_before_pension)/value_age_valuation_Dy;
/*
            raise_application_error(-20000, 'sex: '||sex||chr(10)||
                                            'Ny age_valuation: '||age_valuation||chr(10)||
                                            'value_age_valuation: '||value_age_valuation||chr(10)||
                                            'Ny_years_before_pension: '||years_before_pension||chr(10)||
                                            'value_years_before_pension: '||value_years_before_pension||chr(10)||
                                            'Dy_age_valuation: '||age_valuation||chr(10)||
                                            'value_age_valuation_Dy: '||value_age_valuation_Dy||chr(10)||
                                            'result: '||result);
--*/
        exception when no_data_found then return 0;
        end;
     else
          return 0;
     end if;

    return result;
  end get_expect_duration_live;

  --утрата трудоспособности с таблицей смертности
  function disability_with_mortality_personality(ipnpt_id number) return number
  is
--    stop_age    date;
    stop_date    date;
--    pension_age number(3,1);
    age_valuation number(4,2);
    years_before_pension number(10,8);
    error       pls_integer default 0;
    curr_summ number(19,2);
    expect_duration_live  number(10,7); -- Средняя ожидаемая продолжительность жизни до пенсии
    cur sswh.aktuar_dependant%rowtype;
  begin
    v_date_calculate:='01.08.2020';
    expect_duration_live:=0;

    select * into cur
    from sswh.aktuar_dependant ad
    where ad.mnth=v_date_calculate
    and   ad.pnpt_id=ipnpt_id
    and   substr(ad.rfpm_id,1,4)='0702';

    age_valuation:=round(get_days(v_date_calculate,cur.birthdate)/365.25);
--    pension_age:=get_pension_age(cur.birthdate, cur.sex);
--    stop_age:=get_pension_date(cur.birthdate,cur.birthdate+365.25*pension_age);
    stop_date:=get_pension_date(cur.birthdate,cur.sex);
--    years_before_pension:=get_days(stop_age,v_date_calculate)/365.25;
      years_before_pension:=get_days(stop_date,v_date_calculate)/365.25;

--    error:=case when stop_age<cur.appointdate or stop_age<v_date_calculate
    error:=case when stop_date<cur.appointdate or stop_date<v_date_calculate
                then 1
                else 0
           end;
    if error=0 then
      expect_duration_live:=get_expect_duration_live(age_valuation, ceil(years_before_pension), cur.sex);
      if expect_duration_live=0 then
        curr_summ:=0;
      else
         curr_summ:=12*cur.sum_pay*years_before_pension*expect_duration_live/ceil(years_before_pension);
      end if;
    else
      curr_summ:=0;
    end if;
/*
    log('pnpt_id: '||cur.pnpt_id||chr(10)||
        'sex: '||cur.sex||chr(10)||
        'birthdate: '||cur.birthdate||chr(10)||
        'age_valuation: '||age_valuation||chr(10)||
--                                    'pension_age: '||pension_age||chr(10)||
        'DB stopdate: '||cur.stopdate||chr(10)||
        'stop_date: '||stop_date||chr(10)||
        'v_date_calculate: '||v_date_calculate||chr(10)||
        'years_before_pension: '||years_before_pension||chr(10)||
        'sum_pay: '||cur.sum_pay||chr(10)||
        'expect_duration_live: '||expect_duration_live||chr(10)||
        'years_before_pension: '||years_before_pension||chr(10)||
        'окр_вверх_years_before_pension: '||ceil(years_before_pension)||chr(10)||
        'RESULT: '||curr_summ
                                    );
--*/
    return curr_summ;
  end disability_with_mortality_personality;

  --утрата трудоспособности без таблицы смертности
  procedure disability_without_mortality(iid_calc pls_integer)
  is
    stop_age    date;
--    pension_age number(3,1);
    age_valuation number(4,2);
    years_before_pension number(4,2);
    error       pls_integer default 0;
    curr_summ number(19,2);
    all_summ number(19,2);
  begin
    /*ЕСЛИ(ИЛИ(G8<F8;G8<Summary!$B$30);
              "ERROR";
      12*H8*: sum_pay
      (M8-Summary!$B$30)/365,25)
    */
    all_summ:=0;

    delete from model_calculates mc where mc.id_calc = iid_calc and mc.calc_type = 'W';
    log('0702: Type=W. Для ID_CALC: '||iid_calc||', удалено записей: '||sql%rowcount);
    commit;
    
    for cur in( select *
                from sswh.aktuar_dependant ad
                where ad.mnth=v_date_calculate
                and   substr(ad.rfpm_id,1,4)='0702'
               )
    loop
      begin
        age_valuation:=round(get_days(v_date_calculate,cur.birthdate)/365.25);
  --      pension_age:=get_pension_age(cur.birthdate, cur.sex);
  --      stop_age:=cur.birthdate+365.25*pension_age;
        stop_age:=get_pension_date(cur.birthdate,cur.sex);
        years_before_pension:=get_days(stop_age,v_date_calculate)/365.25;

        error:=case when stop_age<cur.appointdate or stop_age<v_date_calculate
                    then 1
                    else 0
               end;
        if error=0
        then
          curr_summ:=12*cur.sum_pay*years_before_pension;
        else
          curr_summ:=0;
        end if;
        all_summ:=all_summ+curr_summ;
        print_line(iid_calc, 'W', cur.pnpt_id, cur.RFPM_ID, curr_summ, cur.stopdate);
      exception when others then 
        log( '0702: Type=W, Ошибка pnpt_id: '||cur.pnpt_id||', age_valuation: '||age_valuation||
             ', stop_age: '||stop_age||',  years_before_pension:'|| years_before_pension||
             ', error: '||error||', all_sum: '||all_summ||', error: '||sqlerrm);
      end;
    end loop;
--    return all_summ;
  end disability_without_mortality;

  procedure disability_with_mortality(iid_calc pls_integer)
  is
    stop_date    date;
--    pension_age number(3,1);
    age_valuation number(4,2);
    years_before_pension number(10,8);
    error       pls_integer default 0;
    curr_summ number(19,2);
    all_summ number(19,2);
    expect_duration_live  number(10,7); -- Средняя ожидаемая продолжительность жизни до пенсии
  begin
    /*
    ЕСЛИ( ИЛИ(M8<F8;M8<Summary!$B$30);
          "ERROR";
          ЕСЛИ(W8=0;0;12*H8*(U8/V8)*W8)
        )
   Где M8: birthdate+retAge*365,25
   где retAge:=ЕСЛИ(C8=1;63;ЕСЛИ(D8<ДАТА(1960;1;1);58;ЕСЛИ(D8<ДАТА(1960;7;1);58,5;ЕСЛИ(D8<ДАТА(1961;1;1);59;ЕСЛИ(D8<ДАТА(1961;7;1);59,5;ЕСЛИ(D8<ДАТА(1962;1;1);60;ЕСЛИ(D8<ДАТА(1962;7;1);60,5;ЕСЛИ(D8<ДАТА(1963;1;1);61;ЕСЛИ(D8<ДАТА(1963;7;1);61,5;ЕСЛИ(D8<ДАТА(1964;1;1);62;ЕСЛИ(D8<ДАТА(1964;7;1);62,5;63)))))))))))

   F8: AppointDate
   W8: ЕСЛИ(C8=1;(ВПР(T8;com;6)-ВПР(T8+V8;com;6))/ВПР(T8;com;4);ЕСЛИ(C8=0;(ВПР(T8;com;7)-ВПР(T8+V8;com;7))/ВПР(T8;com;5);"Error"))
    */
    all_summ:=0;
    expect_duration_live:=0;
    
    delete from model_calculates mc where mc.id_calc = iid_calc and mc.calc_type = 'M';
    log('0702: Type=M. Для ID_CALC: '||iid_calc||', удалено записей: '||sql%rowcount);
    commit;
    
    for cur in( select *
                from sswh.aktuar_dependant ad
                where ad.mnth=v_date_calculate
                and   substr(ad.rfpm_id,1,4)='0702'
               )
    loop
      begin
        age_valuation:=round(get_days(v_date_calculate,cur.birthdate)/365.25);
  --      pension_age:=get_pension_age(cur.birthdate, cur.sex);
  --      stop_age:=cur.birthdate+365.25*pension_age;
  --      stop_date:=get_pension_date(cur.birthdate,cur.birthdate+365.25*pension_age);
        stop_date:=get_pension_date(cur.birthdate,cur.sex);
        years_before_pension:=get_days(stop_date,v_date_calculate)/365.25;

        error:=case when stop_date<cur.appointdate or stop_date<v_date_calculate
                    then 1
                    else 0
               end;
        if error=0 then
          expect_duration_live:=get_expect_duration_live(age_valuation, ceil(years_before_pension), cur.sex);
          if expect_duration_live=0 then
            curr_summ:=0;
          else
             curr_summ:=12*cur.sum_pay*years_before_pension*expect_duration_live/ceil(years_before_pension);
          end if;
        else
          curr_summ:=0;
        end if;
        all_summ:=all_summ+curr_summ;
  /*
        log('pnpt_id: '||cur.pnpt_id||chr(10)||
            'sex: '||cur.sex||chr(10)||
            'age_valuation: '||age_valuation||chr(10)||
            'birthdate: '||cur.birthdate||chr(10)||
            'stopdate: '||cur.stopdate||chr(10)||
            'stop_date: '||stop_date||chr(10)||
            'years_before_pension: '||years_before_pension||chr(10)||
            'curr_summ: '||curr_summ||chr(10)||
            'sum_pay: '||cur.sum_pay||chr(10)||
            'expect_duration_live: '||expect_duration_live||chr(10)||
            'years_before_pension: '||years_before_pension||chr(10)||
            'years_before_pension: '||ceil(years_before_pension)||chr(10));
  --*/
        print_line(iid_calc, 'M', cur.pnpt_id, cur.RFPM_ID, curr_summ, stop_date);
      exception when others then
        log( '0702: Type=M, Ошибка pnpt_id: '||cur.pnpt_id||', age_valuation: '||age_valuation||
             ', stop_date: '||stop_date||', years_before_pension:'|| years_before_pension||
             ', error: '||error||', all_sum: '||all_summ||', error: '||sqlerrm);
      end;
    end loop;
  end disability_with_mortality;
  
  procedure childcare(iid_calc pls_integer)
  is
    curr_summ number(19,2);
    all_summ number(19,2);
  begin
/*
ЕСЛИ(ИЛИ(G8<F8;G8<Summary!$B$30);"ERROR";12*H8*(G8-Summary!$B$30)/365,25)
  G8: StopDate
  F8: AppointDate
  Summary!$B$30: v_calculation_date
  H8: sum_pay
*/
    all_summ:=0;
    log('ChildCare стартовал');
    for cur in( select ad.*, rowid
                from sswh.aktuar_dependant ad
                where ad.mnth=v_date_calculate
                and   substr(ad.rfpm_id,1,4)='0705'
               )
    loop
      if cur.appointdate<cur.stopdate and v_date_calculate<cur.stopdate
        then
          curr_summ:=12*cur.sum_pay*get_days(cur.stopdate,v_date_calculate)/365.25;
        else
          curr_summ:=0;
      end if;
--      raise_application_error(-20000, 'curr_summ: '||curr_summ||chr(10)||'v_date_calculate: '||v_date_calculate);

      all_summ:=all_summ+curr_summ;
      print_line(iid_calc, '0', cur.pnpt_id, cur.RFPM_ID, curr_summ, cur.stopdate);
    end loop;
    log('ChildCare завершил работу успешно. Общая сумма: '||all_summ);
  end childcare;

  procedure proc_childcare(iid_calc pls_integer, idate date)
  is
  begin
    on_print:='Y';
    v_rfpm:='0705';
    v_date_calculate:=idate;
    childcare(iid_calc);
  end;

---
  procedure unemployment(iid_calc pls_integer)
  is
    curr_summ number(19,2);
    all_summ number(19,2);
  begin
/*
ЕСЛИ(ИЛИ(G9<F9;G9<Summary!$B$30);"ERROR";H9*(G9-Summary!$B$30)/30,25)
  G9: StopDate
  F9: AppointDate
  Summary!$B$30: v_calculation_date
  H9: sum_pay
*/
    all_summ:=0;
    for cur in( select *
                from sswh.aktuar_dependant ad
                where ad.mnth=v_date_calculate
                and   substr(ad.rfpm_id,1,4)=v_rfpm
               )
    loop
      if cur.appointdate<cur.stopdate and v_date_calculate<cur.stopdate
        then
          curr_summ:=cur.sum_pay*get_days(cur.stopdate,v_date_calculate)/30.25;
        else
          curr_summ:=0;
      end if;
/*
      raise_application_error(-20000, 'curr_summ: '||curr_summ||chr(10)||
                                      'v_date_calculate: '||v_date_calculate||chr(10)||
                                      'get_days: '||get_days(cur.stopdate,v_date_calculate));
*/
      all_summ:=all_summ+curr_summ;
      print_line(iid_calc, '0', cur.pnpt_id, cur.RFPM_ID, curr_summ, cur.stopdate);
    end loop;
--    return all_summ;
  end unemployment;

  procedure proc_unemployment(iid_calc pls_integer, idate date)
  is
  begin
    on_print:='Y';
    v_rfpm:='0703';
    v_date_calculate:=idate;
    unemployment(iid_calc);
  end proc_unemployment;

  procedure proc_disability_without_mortality(iid_calc pls_integer, idate date)
  is
  begin
    on_print:='Y';
    v_rfpm:='0702';
    v_date_calculate:=idate;
    disability_without_mortality(iid_calc);
  end;

  procedure proc_disability_with_mortality(iid_calc pls_integer, idate date)
  is
  begin
    on_print:='Y';
    v_rfpm:='0702';
    v_date_calculate:=trunc(idate,'MM');
    disability_with_mortality(iid_calc);
  end proc_disability_with_mortality;

  procedure proc_BW_1(iid_calc pls_integer, idate date)
  is
  begin
    on_print:='Y';
    v_rfpm:='07010101';
    v_date_calculate:=idate;
    get_result_BW_1(iid_calc);
  end proc_BW_1;

  procedure proc_BW_2(iid_calc pls_integer, idate date)
  is
  begin
    on_print:='Y';
    v_rfpm:='07010102';
    v_date_calculate:=idate;
    get_result_BW_2(iid_calc);
  end proc_BW_2;

  procedure proc_BW_3(iid_calc pls_integer, idate date)
  is
  begin
    on_print:='Y';
    v_rfpm:='07010103';
    v_date_calculate:=idate;
    get_result_BW_3(iid_calc);
  end proc_BW_3;

  procedure proc_BW_4(iid_calc pls_integer, idate date)
  is
  begin
    on_print:='Y';
    v_rfpm:='07010104';
    v_date_calculate:=idate;
    get_result_BW_4(iid_calc);
  end proc_BW_4;

begin
  execute immediate 'alter session set NLS_DATE_FORMAT = "dd.mm.yyyy"';
  v_date_calculate:=trunc(sysdate,'MM');
  is_pnpt:='Y';
  on_print:='N';
/*  
  grant select on sswh.aktuar_dependant to shamil;
  grant select on sswh.aktuar_dependant_parms to shamil;
  grant select on sswh.person to shamil;
  grant execute on sswh.util to shamil;
  grant select on sswh.aktuar_target_model_disability to shamil;
*/  
end  aktuar_2020;
/
