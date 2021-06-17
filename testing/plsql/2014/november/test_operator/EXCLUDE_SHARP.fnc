create or replace function exclude_sharp(str in nvarchar2)
return nvarchar2
as
pos simple_integer:=0;
var nvarchar2(2000);
begin
    pos:=instr( str, '#',1,1);
    if pos>0 then
       var:=substr(str,1,pos-1);
    else
       return str;
    end if;
    return var;
end;
/
