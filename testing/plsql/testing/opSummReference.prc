create or replace procedure opSummReference
is
v_id_organization number;
v_id_kind_testing number;
v_id_category_for_position number;
is_start boolean default true;
begin
 for cur in ( select r.*, rownum
              from registration r
              where r.id_registration>=84
              and rownum<3
              order by r.id_organization, r.id_kind_testing, r.id_category_for_position
             )
 loop
      if is_start
        or v_id_organization!=cur.id_organization
        or v_id_kind_testing!=cur.id_kind_testing
        or v_id_category_for_position!=cur.id_category_for_position
      then
        dbms_output.put_line('น;ิศฮ;'||getPivotTheme(cur.id_organization, cur.id_kind_testing, cur.id_category_for_position));
        v_id_organization:=cur.id_organization;
        v_id_kind_testing:=cur.id_kind_testing;
        v_id_category_for_position:=cur.id_category_for_position;
      end if;
      dbms_output.put_line(cur.rownum||';'||getFIO(cur.id_person)||';'||result_pivot(cur.id_registration));
 end loop;
end opSummReference;
/
