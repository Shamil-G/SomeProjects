create or replace package load_table
is

-- Created by S.Gusseynov 2019-2020

function exec(i_table_name in varchar2, isrc in varchar2) return pls_integer;
function index_off(itable_name varchar2, reload_from in date) return pls_integer;
procedure index_on(itable_name varchar2);
procedure shrink_table(itable_name in varchar2, iforce in char default 'N');

end load_table;
/
create or replace package body load_table
is
  info    load_tables_status%rowtype;
  e_errm  varchar2(1024);
  v_count_ins pls_integer default 0;

  procedure log(iobj in varchar, iaction in varchar2, ierror in nvarchar2 := '');

  procedure log(iobj in varchar, iaction in varchar2, ierror in nvarchar2)
  is
  PRAGMA AUTONOMOUS_TRANSACTION;
  begin
    insert into log_load_tables values(CURRENT_TIMESTAMP, iobj, iaction, ierror);
    commit;
  end log;
  
  procedure shrink_table(itable_name in varchar2, iforce in char)
  is
  begin
    if to_char(sysdate,'D')=6 or iforce='Y' then
      dbms_application_info.set_module('SHRINK TABLE '||itable_name,'Упаковываем таблицу');
      execute immediate 'ALTER TABLE '||itable_name||' ENABLE ROW MOVEMENT';    
      log(itable_name, 'SHRINK TABLE', 'ALTER TABLE '||itable_name||' SHRINK SPACE');
      execute immediate 'ALTER TABLE '||itable_name||' SHRINK SPACE';
    end if;
  end;

  function index_off(itable_name varchar2, reload_from in date)
    return pls_integer
  is
  begin
    dbms_application_info.set_module('LOAD_TABLE','Отключаем индексы для: '||itable_name);
    begin
      select * into info from load_tables_status lt where lt.table_name = itable_name;
      exception when no_data_found then null; -- Если вызываем из внешней процедуры, то можем получить прерывание на не зарегистрированную таблицу
    end;
    
    for current_constraint in (
              select 'ALTER TABLE '||itable_name||' DISABLE CONSTRAINT '||a.CONSTRAINT_NAME command
              from user_constraints a
              where table_name = itable_name
              and status = 'ENABLED'
              )
    loop
      log(itable_name, 'Отключаем CONSTRAINT',current_constraint.command);
      begin
        EXECUTE immediate current_constraint.command;
        if SQLCODE>0 then
            -- Ошибка, без отключенных индексов лучше таблицы не загружать
            log ( itable_name, 'Ошибка отключения CONSTRAINT '||sqlcode, current_constraint.command);
            return 0;
        end if;
        return 1;
        exception when others then 
            log ( itable_name, 'Ошибка отключения CONSTRAINT '||sqlcode, current_constraint.command);
            return 0;
      end;
    end loop;

    -- Отключим глоабльные индексы
    for global_index in (select 'alter index '||index_name||' unusable' as command
          from all_indexes ai
          where table_name = itable_name
          and partitioned='NO'
          and table_owner='SSWH'
          and status!='UNUSABLE'
          order by ai.UNIQUENESS desc, index_name
        )
    loop
      log(itable_name, 'Отключаем глобальный индекс', global_index.command );
      begin
        execute immediate global_index.command;
        if SQLCODE>0 then
            -- Ошибка, без отключенных индексов лучше таблицы не загружать
            log ( itable_name, 'Ошибка отключения глобального индекса '||sqlcode, global_index.command);
            return 0;
        end if;
        exception when others then 
          log ( itable_name, 'Ошибка отключения глобального индекса '||sqlcode, global_index.command);
      end;
    end loop;

    -- Отключим индексы партиций
    FOR partition_index IN
        ( SELECT
                  'alter table '||table_name||' modify partition '||partition_name||' unusable local indexes' as command,
                  table_name, partition_name, high_value,
                  partition_position
        FROM user_tab_partitions t
        WHERE TABLE_NAME = upper(itable_name)
        order by partition_position desc
    )
    LOOP
      if  ( 
            info.part_type!='DATE' -- Если партиции не по дате
            or
            (
            info.part_type='DATE'
            and
            to_date( substr(partition_index.high_value,11,10), 'yyyy-mm-dd' ) > trunc(reload_from,'YEAR')
            )
          )
      then
        -- Отключаем партиционированный индекс, возвращается SQLCODE
        -- Быстрей Truncate работает ?
        log( partition_index.table_name, 'Отключаем партицию',partition_index.command);
        execute immediate partition_index.command;
        if SQLCODE>0 then
            -- Ошибка, без отключенных индексов лучше таблицы не загружать
            log ( itable_name, 'Ошибка отключения партиций '||sqlcode, partition_index.command);
            return 0;
        end if;
      else
        exit;
      end if;
    END LOOP;

    return 1;
  end index_off;

  procedure index_on(itable_name varchar2)
  is
  begin
    log(itable_name, 'Начинаем перестройку индексов');
    dbms_application_info.set_module('LOAD_TABLE->BUILD INDEX', itable_name);
    
    FOR current_index IN
    (
        select * from
        (
          SELECT 'ALTER INDEX '||INDEX_NAME||' REBUILD ONLINE PARALLEL' build_command, ui.index_name index_name, uniqueness
            FROM    user_indexes ui
            WHERE table_owner='SSWH'
            and table_name = itable_name
            and status = 'UNUSABLE'
            and partitioned='NO'
          UNION ALL
          SELECT 'ALTER INDEX '||index_name||' REBUILD PARTITION '||partition_name||' ONLINE PARALLEL', uip.index_name, 'partition' uniqueness
            FROM    user_ind_PARTITIONS uip
            WHERE   status = 'UNUSABLE'
            and   index_name in (select index_name from all_indexes where table_name = itable_name)
          UNION ALL
          SELECT 'ALTER INDEX '||index_name||' REBUILD SUBPARTITION '||subpartition_name||' ONLINE PARALLEL', uis.index_name, 'subpartition' uniqueness
            FROM    user_ind_SUBPARTITIONS uis
            WHERE   status = 'UNUSABLE'
            and   index_name in (select index_name from all_indexes where table_name = itable_name)
        ) order by uniqueness desc, build_command
    )
    LOOP
      begin
        log(itable_name, 'Перестраиваем индекс '||current_index.index_name,current_index.build_command);
        EXECUTE immediate current_index.build_command;
      exception when others then
                e_errm:=sqlerrm;
                log(itable_name, 'Ошибка перестройки индекса: '||e_errm, current_index.build_command);
      end;
    END LOOP;

    --/* Зачем в аналитической системе PRIMARY KEY ??
    --  Гусейнов Ш.А. 10.02.2020
    if v_count_ins < 2048 then
        for current_constraint in (
                  select 'ALTER TABLE '||itable_name||' ENABLE CONSTRAINT '||a.CONSTRAINT_NAME command
                  from user_constraints a
                  where table_name = itable_name
                  and status = 'DISABLED'
                  )
        loop
          log(itable_name, 'Включаем PRIMARY KEY',current_constraint.command);
          EXECUTE immediate current_constraint.command;
        end loop;
    end if;
    --*/

    log(itable_name,'Перестройка индексов завершена');
  end index_on;


  function exec(i_table_name in varchar2, isrc in varchar2) return pls_integer
--  procedure exec(itable_name in varchar2, col_name in varchar2, remove_index in char, rollback_days in number, rollback_mnth in number)
  is
  v_month date;
  v_day pls_integer default 0;
  v_count pls_integer;
  cmd_del varchar2(1024);
  cmd_ins varchar2(1024);
  itable_name varchar2(64);
  begin
    itable_name:=upper(i_table_name);
    select * into info from load_tables_status lt where lt.table_name = itable_name;
    log(itable_name, '------->  Начата заливка таблицы');
    log(itable_name, '-----  Включаем параллельный DML');
    execute immediate 'ALTER SESSION ENABLE PARALLEL DML';
        
    if coalesce(info.mnth_rollback,0) > 0 then
        v_month:=add_months(trunc(info.last_success_date, 'MONTH'), - (floor(months_between(sysdate,info.last_success_date))+info.mnth_rollback));
        cmd_del:= 'delete /*+parallel(4)*/ from '||itable_name||' t where trunc('||info.col_name||',''MONTH'') >= '''||to_char(v_month,'dd.mm.yyyy')||'''';
        cmd_ins:= 'insert /*+append*/ into '||itable_name||' select /*parallel(4)*/ * from loader.'||coalesce(isrc,itable_name)||
                  ' where trunc('||info.col_name||',''MONTH'') >= '''||to_char(v_month,'dd.mm.yyyy')||'''';
        if info.part_type='DATE' then 
          cmd_ins:=cmd_ins||' and trunc('||info.col_name||',''YEAR'') < add_months(sysdate,18)';
        end if;
    else if coalesce(info.days_rollback,0) > 0 then
        v_day := extract (day from sysdate);
        if itable_name='PNPD_DOCUMENT' and v_day<info.days_rollback 
          then
           v_month:=trunc(add_months(sysdate,-1), 'MM');
        else
           v_month:=trunc(sysdate, 'DD')-floor(sysdate-info.last_success_date+info.days_rollback);
        end if;
--        v_month:=trunc(info.last_success_date, 'DD')-info.days_rollback;
        cmd_del:= 'delete /*+parallel(4)*/ from '||itable_name||' t where trunc('||info.col_name||',''DD'') >= '''||to_char(v_month,'dd.mm.yyyy')||'''';
        cmd_ins:= 'insert /*+append*/ into '||itable_name||' select /*parallel(4)*/ * from loader.'||coalesce(isrc,itable_name)||
                  ' where trunc('||info.col_name||',''DD'') >= '''||to_char(v_month,'dd.mm.yyyy')||'''';
        if info.part_type='DATE' then 
          cmd_ins:=cmd_ins||' and trunc('||info.col_name||',''YEAR'') < add_months(sysdate,18)';
        end if;
    else
        v_month:='';
        cmd_del:='truncate table  '||itable_name;
        cmd_ins:='insert /*+append*/ into '||itable_name||' select /*parallel(4)*/ * from loader.'||coalesce(isrc,itable_name);
    end if;
    end if;
    if cmd_ins is null then
      return 1;
    end if;

    dbms_application_info.set_module('LOAD_TABLE -> '||itable_name,'Отключаем индексы');
    if coalesce(info.mnth_rollback,0)=0 and
       coalesce(info.days_rollback,0)=0
       then
          log(itable_name, 'Очищаем данные', cmd_del);
          execute immediate cmd_del;
          -- После TRUNCATE индексы автоматически включаются, поэтому их отключаем здесь
          if info.remove_index = 'Y' then
            if index_off(itable_name, v_month)=0 then
              return 0;
            end if;
          end if;
    else
        if info.remove_index = 'Y' then
          if index_off(itable_name, v_month)=0 then
            return 0;
          end if;
        end if;

        log(itable_name, 'Очищаем данные', cmd_del);
        dbms_application_info.set_module('LOAD_TABLE -> '||itable_name,'Удаляем записи');
        
        execute immediate cmd_del;
          v_count:=SQL%rowcount;
        log(itable_name, 'Удалено записей: '||v_count);
    end if;

    commit;
    
    if coalesce(info.parallel,1)=0 then
          log(itable_name, '----- Отключаем параллельный DML');
          execute immediate 'ALTER SESSION DISABLE PARALLEL DML';
    end if;
    -- Начинаем заливку данных
    dbms_application_info.set_module('LOAD_TABLE -> '||itable_name,'Вставляем записи');
    log(itable_name, 'Добавляем данные', cmd_ins);
    execute immediate cmd_ins;
    -- Окончание заливки
    v_count_ins:=SQL%rowcount;
    log(itable_name, 'Загружено записей: '||v_count_ins);
    commit;

    log(itable_name, '----- Включаем параллельный DML');
    execute immediate 'ALTER SESSION ENABLE PARALLEL DML';

    if info.remove_index = 'Y' then
       dbms_application_info.set_module('LOAD_TABLE -> '||itable_name,'Перестраиваем индексы');
       index_on(itable_name);
    end if;
    log(itable_name, '=====>  Заливка таблицы завершена');
    return 1;
    exception when others then
        begin
              e_errm:=sqlerrm;
              insert into log_load_tables values(CURRENT_TIMESTAMP, itable_name, 'Ошибка ', e_errm);
              commit;
              return 0;
        end;
  end;
  
  begin
    execute immediate 'alter session set sort_area_size=50000000';
    execute immediate 'alter session set sort_area_retained_size=50000000';
end load_table;
/
