create or replace function getOrganization( co in varchar2 ) return varchar2
is
Result varchar2(64);
begin
  case when co = 'ts' then Result:='�������� ����';
       when co = 'es' then Result:='������������� ����';
       when co = 'eo' then Result:='������������� ����/����������������� �����������';
       else    Result:='';
  end case;
  return Result;
end;
/
