CREATE OR REPLACE PACKAGE SECMGR.GSEC_CTX AS

/* TODO enter package declarations (types, exceptions, methods etc) here */
PROCEDURE init;
PROCEDURE setDebug(level simple_integer);
PROCEDURE set(name_parm in varchar2, value_parm in varchar2);
PROCEDURE clear(name_parm in varchar2);
function get(name_parm in varchar2) return varchar2;
function getDebug return simple_integer;
PROCEDURE setProduction(level char);
function getProduction return char;


END GSEC_CTX;
/

CREATE OR REPLACE PACKAGE BODY SECMGR.GSEC_CTX AS

procedure set(name_parm in varchar2, value_parm in varchar2)
is
begin
  secmgr.sec_ctx.log(1, iappname=>'Tester',
            ioperation=>'gsec_ctx',
            imodule=>'set',
            imessage=> 'name_parm='||name_parm||' : '||value_parm);

  DBMS_SESSION.set_context(NAMESPACE =>'GSEC_CTX', ATTRIBUTE => name_parm, VALUE => value_parm);
end set;
function get(name_parm in varchar2) return varchar2
is
begin
  secmgr.sec_ctx.log(1, iappname=>'Tester',
            ioperation=>'gsec_ctx',
            imodule=>'get',
            imessage=> 'name_parm='||name_parm );
  return coalesce(sys_context('GSEC_CTX',name_parm),'');
end get;
procedure clear(name_parm in varchar2)
is
begin
  secmgr.sec_ctx.log(1, iappname=>'Tester',
            ioperation=>'gsec_ctx',
            imodule=>'clear',
            imessage=> 'name_parm='||name_parm );
  DBMS_SESSION.clear_context(NAMESPACE =>'GSEC_CTX', ATTRIBUTE => name_parm);
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

END GSEC_CTX;
/
