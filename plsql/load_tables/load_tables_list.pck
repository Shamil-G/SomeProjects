create or replace package load_tables_list Is
  procedure list_1;
  procedure list_2;
  procedure list_3;
end load_tables_list;
/
create or replace package body load_tables_list Is

  p_Err rptb_schedule.errors%Type;



  procedure exec(irowid in rowid, itable_name in varchar2, isrc varchar2)
  is
    new_runtime date;
    stream      number(1);
  begin
    Update load_tables_status t
    Set t.beg_time = Sysdate,
        t.end_time = '',
        t.state = 1,
        t.info = 'Начата обработка'
    Where t.rowid = irowid;
    Commit;

    select trunc(case when substr(t.freq,1,1)='D' then trunc(sysdate,'DD')-trunc(t.runtime,'DD')+trunc(t.runtime,'MI')+to_number(substr(t.freq,2))
                                   when substr(t.freq,1,1)='M' then add_months(trunc(sysdate,'DD')-trunc(t.runtime,'DD')+trunc(t.runtime,'MI'),to_number(substr(t.freq,2)))
                                   when substr(t.freq,1,1)='Y' then add_months(trunc(sysdate,'DD')-trunc(t.runtime,'DD')+trunc(t.runtime,'MI'),12) end, 'MI'
                ),
           t.stream
    into new_runtime, stream
    from load_tables_status t 
    Where t.rowid = irowid;
    
    new_runtime := case when stream = 1 
                        then case when to_char(new_runtime,'D')=7 then new_runtime+1
                                  when to_char(new_runtime,'D')=6 then new_runtime+2
                                  else new_runtime end
                        when stream = 2
                        then case when to_char(new_runtime,'D')=7 then new_runtime+1
                                  else new_runtime end
                        else new_runtime end;
                        
    if load_table.exec(itable_name,isrc)!=0 then

        Update load_tables_status t
        Set t.state = 2,
            t.runtime = new_runtime,
            t.last_success_date = sysdate,
            t.end_time = Sysdate,
            info = Null
         Where t.rowid = irowid;
         commit;
    end if;

    Exception
      When Others Then
          p_Err := substr(Sqlerrm, 1, 1000);
          Rollback;
          Update load_tables_status t Set t.end_time = Sysdate, t.state=100, info = p_Err Where t.rowid = irowid;
          Commit;
  end;

  procedure list_1 is
  Begin
    For i In (Select t.rowid rwd, t.*
              From load_tables_status t
              Where to_char(coalesce(t.runtime,trunc(sysdate)), 'HH24:MI')<to_char(sysdate, 'HH24:MI')
              and coalesce(t.runtime, sysdate) <= sysdate -- Если дата загрузки наступила
              and trunc(runtime,'DD') >= trunc(sysdate,'MM') -- Прошедшие Месяцы не учитывать
              and trunc(coalesce(t.last_success_date, sysdate-1),'DD')<trunc(sysdate,'DD') -- Если сегодня загружали, то больше не надо
              and state < 3
              and coalesce(stream,1) = 1  -- LIST_1
              and   0 = ( select count(t2.beg_time)      -- Если задачи уже запущены - ничего не делать
                          from load_tables_status t2
                          where trunc(t2.beg_time,'MM')=trunc(sysdate,'MM')
                          and coalesce(stream,1) = 1
                          and state=1
                        )
              and sysdate > trunc(sysdate,'Y')+4            -- Исключить первые 4 дня Нового Года
                 -- Ограничения на работу по дням недели
              and to_char(sysdate,'D') in ('1', '2','3','4','5') -- Работать всегда в рабочие дни
              Order By t.priority desc
         )
    Loop
      exec(i.rwd, i.table_name, i.src);
    End Loop;
  end list_1;
  
  procedure list_2 is
  Begin
    For i In (Select t.rowid rwd, t.*
              From load_tables_status t
              Where to_char(coalesce(t.runtime,trunc(sysdate)), 'HH24:MI')<to_char(sysdate, 'HH24:MI')
              and coalesce(t.runtime, sysdate) <= sysdate -- Если дата загрузки наступила
              and trunc(runtime,'DD') >= trunc(sysdate,'MM') -- Прошедшие Месяцы не учитывать
              and trunc(coalesce(t.last_success_date, sysdate-1),'DD')<trunc(sysdate,'DD') -- Если сегодня загружали, то больше не надо
              and state < 3
              and coalesce(stream,1) = 2  -- LIST_2
              and   0 = ( select count(t2.beg_time)      -- Если задачи уже запущены - ничего не делать
                          from load_tables_status t2
                          where trunc(t2.beg_time,'MM')=trunc(sysdate,'MM')
                          and coalesce(stream,1) = 2
                          and state=1
                        )
              and sysdate > trunc(sysdate,'Y')+4            -- Исключить первые 4 дня Нового Года
                 -- Ограничения на работу по дням недели
              and to_char(sysdate,'D') in ('1', '2','3','4','5','6') -- Работать всегда в рабочие дни
              Order By t.priority desc
         )
    Loop
      exec(i.rwd, i.table_name, i.src);
    End Loop;
  end list_2;  

  procedure list_3 is
  Begin
    For i In (Select t.rowid rwd, t.*
              From load_tables_status t
              Where to_char(coalesce(t.runtime,trunc(sysdate)), 'HH24:MI')<to_char(sysdate, 'HH24:MI')
              and coalesce(t.runtime, sysdate) <= sysdate -- Если дата загрузки наступила
              and trunc(runtime,'DD') >= trunc(sysdate,'MM') -- Прошедшие Месяцы не учитывать
              and trunc(coalesce(t.last_success_date, sysdate-1),'DD')<trunc(sysdate,'DD') -- Если сегодня загружали, то больше не надо
              and state < 3
              and coalesce(stream,1) = 3  -- LIST_3
              and   0 = ( select count(t2.beg_time)      -- Если задачи уже запущены - ничего не делать
                          from load_tables_status t2
                          where trunc(t2.beg_time,'MM')=trunc(sysdate,'MM')
                          and coalesce(stream,1) = 3
                          and state=1
                        )
              and sysdate > trunc(sysdate,'Y')+4            -- Исключить первые 4 дня Нового Года
                 -- Ограничения на работу по дням недели
              and to_char(sysdate,'D') in ('1', '2','3','4','5','7') -- Работать всегда в рабочие дни
              Order By t.priority desc
         )
    Loop
      exec(i.rwd, i.table_name, i.src);
    End Loop;
  end list_3;  

end load_tables_list;
/
