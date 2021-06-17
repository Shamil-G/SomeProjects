create or replace function getOrganization( co in varchar2 ) return varchar2
is
Result varchar2(64);
begin
  case when co = 'ts' then Result:='“епловые сети';
       when co = 'es' then Result:='Ёлектрические сети';
       when co = 'eo' then Result:='Ёлектрические сети/электроснабжающие организации';
       else    Result:='';
  end case;
  return Result;
end;
/
