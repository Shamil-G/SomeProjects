CREATE OR REPLACE PACKAGE GSEC_CTX AS

/* TODO enter package declarations (types, exceptions, methods etc) here */
PROCEDURE init;
procedure set_session_id(iid_session in number);
PROCEDURE setDebug(level simple_integer);
PROCEDURE set(iid_session in number, name_parm in varchar2, value_parm in varchar2);
PROCEDURE set(iid_session in number);
PROCEDURE clear(iid_session in number);
function get(iid_session in number, name_parm in varchar2) return varchar2;
function get(iid_session in number) return varchar2;
function getDebug return simple_integer;
PROCEDURE setProduction(level char);
function getProduction return char;


END GSEC_CTX;
/

CREATE OR REPLACE PACKAGE BODY GSEC_CTX AS

procedure set_session_id(iid_session in number)
is
begin
  DBMS_SESSION.SET_IDENTIFIER(iid_session);
end;


--    DBMS_SESSION.SET_CONTEXT(
--     namespace  => 'global_hr_ctx',
--     attribute  => sec_level_attr,
--     value      => sec_level_val,
--     username   => USER,
--     client_id  => session_id_global);

procedure set(iid_session in number, name_parm in varchar2, value_parm in varchar2)
is
begin
  secmgr.sec_ctx.log(1, iappname=>'Tester',
            ioperation=>'gsec_ctx',
            imodule=>'set',
            imessage=> 'id_session='||iid_session||', name_parm='||name_parm||' : '||value_parm);
  set_session_id(iid_session);
  DBMS_SESSION.set_context(
    NAMESPACE =>'GSEC_CTX',
    ATTRIBUTE => name_parm,
    VALUE => value_parm,
    client_id  => iid_session );
end set;

procedure set(iid_session in number)
is
begin
  secmgr.sec_ctx.log(1, iappname=>'Tester',
            ioperation=>'gsec_ctx',
            imodule=>'set',
            imessage=> 'id_session='||iid_session);
  set_session_id(iid_session);
  DBMS_SESSION.set_context(
    NAMESPACE =>'GSEC_CTX',
    ATTRIBUTE => 'id_registration',
    VALUE => iid_session,
    client_id  => iid_session );
end set;

function get(iid_session in number) return varchar2
is
begin
  secmgr.sec_ctx.log(1, iappname=>'Tester',
            ioperation=>'gsec_ctx',
            imodule=>'get',
            imessage=> 'iid_session='||iid_session );
  set_session_id(iid_session);
  return coalesce(sys_context('GSEC_CTX','Control'),'');
end get;

function get(iid_session in number, name_parm in varchar2) return varchar2
is
begin
  secmgr.sec_ctx.log(1, iappname=>'Tester',
            ioperation=>'gsec_ctx',
            imodule=>'get',
            imessage=> 'name_parm='||name_parm );
  set_session_id(iid_session);
  return coalesce(sys_context('GSEC_CTX',name_parm),'');
end get;

procedure clear(iid_session in number)
is
begin
  secmgr.sec_ctx.log(1, iappname=>'Tester',
            ioperation=>'gsec_ctx',
            imodule=>'clear',
            imessage=> 'name_parm='||iid_session );
  set_session_id(iid_session);
  DBMS_SESSION.clear_identifier;
  DBMS_SESSION.clear_context(NAMESPACE =>'GSEC_CTX', ATTRIBUTE => iid_session);
end clear;

Procedure INIT
is
begin
  for cur in ( select * from secmgr.gparams )
  loop
    DBMS_SESSION.clear_context(NAMESPACE =>'GSEC_CTX', ATTRIBUTE => cur.name);
    DBMS_SESSION.set_context(NAMESPACE =>'GSEC_CTX', ATTRIBUTE => cur.name, VALUE => cur.value);
  end loop;
end INIT;

PROCEDURE setProduction(level char)
is begin
  DBMS_SESSION.CLEAR_CONTEXT(NAMESPACE =>'GSEC_CTX', ATTRIBUTE => 'Production');
  DBMS_SESSION.set_context(NAMESPACE =>'GSEC_CTX', ATTRIBUTE => 'Production',VALUE => level);
end;

function getProduction return char
is begin
    return nvl(sys_context('gsec_ctx','Production'),'Y');
end;

PROCEDURE setDebug(level simple_integer)
is begin
  DBMS_SESSION.CLEAR_CONTEXT(NAMESPACE =>'GSEC_CTX', ATTRIBUTE => 'Debug');
  DBMS_SESSION.set_context(NAMESPACE =>'GSEC_CTX', ATTRIBUTE => 'Debug',VALUE => level);
end;

function getDebug
return simple_integer
is
begin
    return nvl(sys_context('gsec_ctx','debug'),4);
end;

begin
--   CREATE OR REPLACE CONTEXT gsec_ctx USING secmgr.gsec_ctx ACCESSED GLOBALLY;
null;
END GSEC_CTX;
/
