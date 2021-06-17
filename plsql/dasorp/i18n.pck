create or replace package i18n is

  -- Author  : цсяеимнб_ь
  -- Created : 08.02.2021 9:07:51
  -- Purpose : 
  
  
  -- Public function and procedure declarations
  function get_value(icode varchar2, ires_name varchar2) return nvarchar2;

end i18n;
/
create or replace package body i18n is

  -- Private type declarations
  function get_value(icode varchar2, ires_name varchar2) return nvarchar2
  is
    res i8n.res_value%type;
  begin
    select i.res_value into res from i8n i where i.res_code=icode and i.res_name=ires_name;
    return res;
    exception when no_data_found then return ires_name;
  end;
end i18n;
/
