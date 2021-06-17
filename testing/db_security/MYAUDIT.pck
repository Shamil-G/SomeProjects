create or replace package myAudit is

procedure initAudit(ischema in varchar2, iobject in varchar2,
          istatement_types in varchar2,
          iaudit_condition in varchar2,
          iaudit_column in varchar2,
          iaudit_column_opts in varchar2,
          ipolicy_name in varchar2,
          iaudit_trail  in varchar2);
procedure addPolicy(ischema in varchar2, iobject in varchar2, ipolicy_name in varchar2);
procedure dropPolicy(ischema in varchar2, iobject in varchar2, ipolicy_name in varchar2);
procedure enablePolicy(ischema in varchar2, iobject in varchar2, ipolicy_name in varchar2);
procedure disablePolicy(ischema in varchar2, iobject in varchar2, ipolicy_name in varchar2);

function rls_control(
  schema_var IN VARCHAR2,
  table_var  IN VARCHAR2
) return varchar2;

procedure add_rls_policy(ischema in varchar2, iobject in varchar2, itypes in varchar2);
procedure drop_rls_policy(ischema in varchar2, iobject in varchar2);

end myAudit;
/

create or replace package body myAudit is


--GRANT EXECUTE ON dbms_fga TO uwclass;
--GRANT select ON dba_audit_policies TO uwclass;
--GRANT select ON dba_fga_audit_trail TO uwclass;
--SELECT name, value FROM gv$parameter WHERE name LIKE '%audit%';

procedure initAudit(ischema in varchar2, iobject in varchar2,
          istatement_types in varchar2,
          iaudit_condition in varchar2,
          iaudit_column in varchar2,
          iaudit_column_opts in varchar2,
          ipolicy_name in varchar2,
          iaudit_trail  in varchar2)
is
 begin
--   dbms_fga.add_policy (
--      object_schema=>ischema,
--      object_name=>iobject,
--      policy_name=> case when ipolicy_name is null then 'myPolicy' else ipolicy_name end,
--      statement_types => case when istatement_types is null then 'INSERT, UPDATE, DELETE, SELECT' else istatement_types end,
--      audit_condition   => iaudit_condition, --'BALANCE >= 3000',
--      audit_column    => iaudit_column, --'IDANSWER',
--      audit_column_opts => case when iaudit_column_opts is not null then iaudit_column_opts else DBMS_FGA.ALL_COLUMNS end, --DBMS_FGA.ALL_COLUMNS,
--      audit_trail       => case when iaudit_trail is not null then iaudit_trail else DBMS_FGA.DB end
--  );
   dbms_fga.add_policy (
      object_schema=>ischema,
      object_name=>iobject,
      policy_name=> case when ipolicy_name is null then 'myPolicy' else ipolicy_name end,
      statement_types => case when istatement_types is null then 'INSERT, UPDATE, DELETE, SELECT' else istatement_types end,
      audit_column    => iaudit_column --'IDANSWER',
      );

end initAudit;
procedure addPolicy(ischema in varchar2, iobject in varchar2,
          ipolicy_name in varchar2)
is
 begin
--   dbms_fga.add_policy (
--      object_schema=>ischema,
--      object_name=>iobject,
--      policy_name=> case when ipolicy_name is null then 'myPolicy' else ipolicy_name end,
--      statement_types => case when istatement_types is null then 'INSERT, UPDATE, DELETE, SELECT' else istatement_types end,
--      audit_condition   => iaudit_condition, --'BALANCE >= 3000',
--      audit_column    => iaudit_column, --'IDANSWER',
--      audit_column_opts => case when iaudit_column_opts is not null then iaudit_column_opts else DBMS_FGA.ALL_COLUMNS end, --DBMS_FGA.ALL_COLUMNS,
--      audit_trail       => case when iaudit_trail is not null then iaudit_trail else DBMS_FGA.DB end
--  );
   dbms_fga.add_policy (
      object_schema=>ischema,
      object_name=>iobject,
      policy_name=> case when ipolicy_name is null then 'myPolicy' else ipolicy_name end,
      statement_types => 'INSERT, UPDATE, DELETE, SELECT'
      );

end addPolicy;

procedure dropPolicy(ischema in varchar2, iobject in varchar2, ipolicy_name in varchar2)
is
begin
   dbms_fga.drop_policy (
      object_schema=>ischema,
      object_name=>iobject,
      policy_name=>case when ipolicy_name is null then 'myPolicy' else ipolicy_name end
   );
end dropPolicy;
procedure enablePolicy(ischema in varchar2, iobject in varchar2, ipolicy_name in varchar2)
is
begin
   dbms_fga.enable_policy (
      object_schema => ischema,
      object_name => iobject,
      policy_name => case when ipolicy_name is null then 'myPolicy' else ipolicy_name end,
      enable => TRUE
   );
end enablePolicy;
procedure disablePolicy(ischema in varchar2, iobject in varchar2, ipolicy_name in varchar2)
is
begin
   dbms_fga.enable_policy (
      object_schema => ischema,
      object_name => iobject,
      policy_name => case when ipolicy_name is null then 'myPolicy' else ipolicy_name end,
      enable => FALSE
   );
end disablePolicy;

function rls_control(
  schema_var IN VARCHAR2,
  table_var  IN VARCHAR2
)
return varchar2
is
BEGIN
return sys_context('sec_ctx','app_user');
end rls_control;

procedure add_rls_policy(ischema in varchar2, iobject in varchar2, itypes in varchar2)
is
BEGIN
  DBMS_RLS.ADD_POLICY(
  object_schema   => ischema,
  object_name     => iobject,
  policy_name     => 'control_policy',
  function_schema  => 'shamil',
  policy_function => 'myaudit.rls_control',
  statement_types => itypes);
end add_rls_policy;

procedure drop_rls_policy(ischema in varchar2, iobject in varchar2 )
is
BEGIN
  DBMS_RLS.DROP_POLICY(
  object_schema   => ischema,
  object_name     => iobject,
  policy_name     => 'control_policy');
end drop_rls_policy;

end myAudit;
/
