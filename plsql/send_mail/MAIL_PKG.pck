CREATE OR REPLACE PACKAGE MAIL_PKG IS
-- --------------------------------------------------------------------------
--
-- FOR Example 
--
-- Name         : MAIL_PKG
-- Author       : Nekrasov Alexander
-- Description  : Mail package, send email with attachments
-- Ammedments   :
--   When         Who         What
--   ===========  ==========  =================================================
--   22-JAN-2010  Nekrasov A.  Initial Creation
--   26-MAY-2010  Nekrasov A.  Update package bugs
-- --------------------------------------------------------------------------

/* EXAMPLE:

 1) Short text email

    BEGIN
      MAIL_PKG.SEND( 'a.ivanov@yourcomany.ru','Test subject', 'Some message!');
  END;

 2) Extension Email with attacments

    BEGIN
   MAIL_PKG.SET_MAILSERVER ('localhost',25);
   MAIL_PKG.SET_AUTH ('a.nekrasov','password');
   MAIL_PKG.ADD_ATTACHMENT( 'ODPDIR'
               ,'girl3d.jpeg'
               ,'image/jpeg'
              );
   MAIL_PKG.SEND( mailto => 'A. Ivanov <a.ivanov@yourcomany.ru>, O.Petrov <o.petrov@yourcompany.ru>'
                , subject => 'Test subject'
          , message => 'Some <b>bold</b> message!'
          , mailfrom => 'Oracle Notify <no-reply@yourcompany.ru>'
                  , mimetype => 'text/html'
          , priority => 1
                );
  END;
*/

 -- SET_MAILSERVER:
 --  Set up mail server for send emails. Default Localhost
 -- IN
 -- MAILSERVER is ip or url of mail server
 -- MAILPORT is port for mail server. Default 25
 PROCEDURE SET_MAILSERVER ( mailserver varchar2
                          , mailport number default 587
                          );

 -- SET_AUTH
 --  Set authorization on smtp server
 -- IN
 -- AUTH_USER is authorization user
 -- AUTH_PASS is password for AUTH_USER
 --
 -- Execute SET_AUTH(); -- for disable authorization
 PROCEDURE SET_AUTH (  auth_user varchar2 default null
                     , auth_pass varchar2 default null
                          );

 -- ENCODE:
 --  Encodes string to email compatible view
 -- IN
 -- STR is string to convert
 -- TP is type of convert:
 --    B - is base64 encoding
 FUNCTION ENCODE( str IN VARCHAR2
                , tp IN VARCHAR2 DEFAULT 'Q') RETURN VARCHAR2;

 -- PREPARE
 --  Prepare configs for email.
 PROCEDURE PREPARE;

 -- ADD_RCPT
 --  Add recipient to recipients list exploded by  ','
 -- STR is variable with recipients
 -- RCPTMAIL is recipient mail added to STR
 -- RCPTNAME is recipient name added to STR
 -- Example: str='user1@domain.ru' rcptmail='user2@domain.ru'
 --  after => str='user1@domain.ru, user2@domain.ru'
 PROCEDURE ADD_RCPT( str IN OUT VARCHAR2
                   , rcptmail IN VARCHAR2
           , rcptname IN VARCHAR2 DEFAULT NULL);

 -- ADD_ATTACHMENT
 --  Add attachment to attachments list to email
 -- IN
 -- DIRNAME is logical link to access physical directories of server. See DBA_DIRECTORIES table
 -- FILENAME is name of file to attach
 -- MIMETYPE is mime-type for sended file
 -- NAME is name for attached file for email. Default eq FILENAME
 PROCEDURE ADD_ATTACHMENT ( dirname IN varchar2
                          , filename IN varchar2
              , mimetype IN varchar2 DEFAULT 'text/plain'
                          , name IN varchar2 DEFAULT NULL
                           );
 -- SEND
 --  Send email with attachments to recipient
 -- IN
 -- MAILTO is name and email addresses of recipients ( ex. "user@domain.com"
 --       , "User Name <user@domain.com>", "User1 <user1@domain>, User2 <user2@domain>")
 -- SUBJECT is subject of email
 -- MESSAGE is message of email
 -- MAILFROM is name and email of sender. (ex. "no-reply@domain", "Notify system <no-reply@domain>")
 -- MIMETYPE is mime-type of message. Available values is 'text/plain' and 'text/html'
 -- PRIORITY is priority of mail (1 - High, 2 - Highest, 3 - Normal, 4 - Lowest, 5 - Low)
 
 PROCEDURE GET_RFBN (refcur out sys_refcursor);
 
 PROCEDURE SEND ( branch IN VARCHAR2
        , subject IN VARCHAR2
        , message IN VARCHAR2
                , mailfrom IN VARCHAR2 DEFAULT NULL
        , mimetype IN VARCHAR2 DEFAULT 'text/plain'
        , priority IN NUMBER DEFAULT NULL
                );
END MAIL_PKG;
/
CREATE OR REPLACE PACKAGE BODY MAIL_PKG
IS

 mailserver VARCHAR2(30):='192.168.1.11';
 mailport INTEGER:=587;
 auth_user VARCHAR2(50) := 'callback@gfss.kz'; 
 auth_pass VARCHAR2(50) := '1Qaz2Wsx'; 
 crlf         VARCHAR2(2)  := utl_tcp.CRLF; -- chr(13)||chr(10);

 type attach_row is record ( dirname varchar2(30)
                           , filename  varchar2(30)
                           , name  varchar2(30)
               , mimetype varchar2(30)
                           );
 type attach_list is table of attach_row;
 attachments attach_list;

 type rcpt_row is record ( rcptname varchar2(100)
                     , rcptmail varchar2(50)
           );
 type rcpt_list is table of rcpt_row;

 PROCEDURE SET_MAILSERVER ( mailserver varchar2
                          , mailport number default 587
                          ) IS
 BEGIN
  MAIL_PKG.mailserver := mailserver;
  MAIL_PKG.mailport := mailport;
 END;

 PROCEDURE SET_AUTH (  auth_user varchar2 default null
                     , auth_pass varchar2 default null
                          ) IS
 BEGIN
   MAIL_PKG.auth_user := auth_user;
   MAIL_PKG.auth_pass := auth_pass;
 END;

 FUNCTION ENCODE(str IN VARCHAR2, tp IN VARCHAR2 DEFAULT 'Q') RETURN VARCHAR2 IS
 BEGIN
   IF tp='B' THEN
     RETURN '=?utf-8?b?'|| UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(UTL_RAW.cast_to_raw (CONVERT (SUBSTR(str,1,24), 'UTF8'))))|| '?='
       || CASE WHEN SUBSTR(str,25) IS NOT NULL THEN crlf || ' '|| ENCODE(SUBSTR(str,25),tp) END;
   ELSIF tp='Q' THEN
     RETURN '=?utf-8?q?' || UTL_RAW.cast_to_varchar2(utl_encode.QUOTED_PRINTABLE_ENCODE(utl_raw.cast_to_raw(CONVERT (SUBSTR(str,1,8), 'UTF8') ))) || '?='
       || CASE WHEN SUBSTR(str,9) IS NOT NULL THEN crlf || ' '|| ENCODE(SUBSTR(str,9),tp) END;
   ELSE
     RETURN str;
   END IF;
 END;

 PROCEDURE PREPARE
 IS
 BEGIN
   MAIL_PKG.attachments:=MAIL_PKG.attach_list();
 END;

 PROCEDURE ADD_RCPT( str IN OUT VARCHAR2
                   , rcptmail IN VARCHAR2
           , rcptname IN VARCHAR2 DEFAULT NULL) IS
  rcpt varchar2(255);
 BEGIN
  rcpt:=CASE WHEN rcptname is null THEN
          rcptmail
    ELSE
      trim(replace(replace(rcptname,',',' '),';',' '))||' <'|| rcptmail ||'>'
    END;
  IF trim(str) is NULL THEN
     str :=  trim(rcpt);
  ELSE
     str := str||', '||trim(rcpt);
  END IF;
 END;

 PROCEDURE ADD_ATTACHMENT ( dirname IN varchar2
                          , filename IN varchar2
              , mimetype IN varchar2 DEFAULT 'text/plain'
                          , name IN varchar2 DEFAULT NULL
                           )
 IS
  v_fl BFILE :=BFILENAME(dirname,filename);
 BEGIN
   IF DBMS_LOB.FILEEXISTS (v_fl)=1 THEN
      MAIL_PKG.attachments.extend;
      MAIL_PKG.attachments(MAIL_PKG.attachments.count).dirname:=dirname;
      MAIL_PKG.attachments(MAIL_PKG.attachments.count).filename:=filename;
      MAIL_PKG.attachments(MAIL_PKG.attachments.count).name:=nvl(name,filename);
      MAIL_PKG.attachments(MAIL_PKG.attachments.count).mimetype:=mimetype;
   ELSE
      RAISE_APPLICATION_ERROR(-20001, 'File is not exists');
   END IF;
 END;

 FUNCTION CREATE_RCPT_LIST(mailto IN VARCHAR2) RETURN MAIL_PKG.rcpt_list IS
  v_mailto VARCHAR2(4096) := replace(mailto,';',',')||',';
  pntr INTEGER;
  buf VARCHAR2(255);
  rcptmail VARCHAR2(255);
  rcptlist MAIL_PKG.rcpt_list:=MAIL_PKG.rcpt_list();
 BEGIN
  FOR maxrcptnts IN 1..50
  LOOP
     pntr:=INSTR(v_mailto,','); buf := substr(v_mailto,1,pntr-1);
     IF pntr>0 THEN
     IF INSTR(buf,'<')>0 AND INSTR(buf,'>')>0 THEN
       rcptmail:= SUBSTR(buf,INSTR(buf,'<')+1,INSTR(SUBSTR(buf,INSTR(buf,'<')+1),'>')-1);
     IF rcptmail IS NOT NULL THEN
          rcptlist.extend;
        rcptlist(rcptlist.count).rcptmail := TRIM(rcptmail);
        rcptlist(rcptlist.count).rcptname := TRIM(SUBSTR(buf,1,INSTR(buf,'<')-1));
       END IF;
       ELSE
       rcptmail := TRIM(buf);
     IF rcptmail IS NOT NULL THEN
           rcptlist.extend;
       rcptlist(rcptlist.count).rcptmail:= TRIM(rcptmail);
     END IF;
     END IF;
   ELSE
     EXIT;
   END IF;
   v_mailto := substr(v_mailto,pntr+1);
   END LOOP;
   RETURN rcptlist;
 END;


PROCEDURE GET_RFBN (refcur out sys_refcursor) is
  
begin
  open refcur for
  select * from S_BRANCH_EMAIL t
  order by t.rfbn_id;
  
end;

 PROCEDURE SEND ( branch IN VARCHAR2
        , subject IN VARCHAR2
        , message IN VARCHAR2
        , mailfrom IN VARCHAR2 DEFAULT NULL
        , mimetype IN VARCHAR2 DEFAULT 'text/plain'
        , priority IN NUMBER DEFAULT NULL
                )
 IS
   v_Mail_Conn  utl_smtp.Connection;
   boundary VARCHAR2(50) := '-----7D81B75CCC90DFRW4F7A1CBD';
   vFile BFILE;
   vRAW RAW(32767);
   amt CONSTANT BINARY_INTEGER := 48; -- 48bytes binary convert to 128bytes of base64.
   v_amt BINARY_INTEGER;
   ps BINARY_INTEGER := 1;
   v_mime VARCHAR2(30);
   mailto varchar2(50);
   reply UTL_SMTP.REPLY;
   replies UTL_SMTP.REPLIES;
   rcptlist MAIL_PKG.rcpt_list;
   sndr MAIL_PKG.rcpt_row;
 BEGIN
   
   begin
    Select s.branch_email into mailto
    from s_branch_email s
    where s.rfbn_id = branch;
    exception when no_data_found then
      RAISE_APPLICATION_ERROR(-20001, 'Филиал ' ||branch ||' не найден!');
    end;
    
    
    rcptlist:=create_rcpt_list(mailto);
  IF rcptlist.count=0 THEN
      RAISE_APPLICATION_ERROR(-20001, 'Recipients requered');
  END IF;
    IF mimetype<>'text/html' and mimetype<>'text/plain' THEN
      RAISE_APPLICATION_ERROR(-20001, 'MimeType must be "text/html" or "text/plain"');
    ELSE
      v_mime:=mimetype;
    END IF; 
     -- utl_http.set_wallet('file:c:\wallet', 'd2zVr4d2');
      
     reply := UTL_SMTP.OPEN_CONNECTION(host                          => mailserver,
                                         port                          => mailport,
                                         c                             => v_Mail_Conn,
                                         tx_timeout                    => null,
                                         wallet_path                   =>  'file:c:\wallet',
                                         wallet_password               => 'd2zVr4d2',
                                         secure_connection_before_smtp => FALSE
         
         );
    IF reply.code != 220
      THEN
        raise_application_error(-20000, 'utl_smtp.open_connection: '||reply.code||' - '||reply.text);
      END IF;
      
 /*   v_Mail_Conn := utl_smtp.Open_Connection(                  
                   host => mailserver,
                   port => mailport,
                   
                        tx_timeout  => 500,
                   wallet_path => 'file:WALLETS',
                   wallet_password => 'd2zVr4d2',
                   secure_connection_before_smtp => FALSE
                   );*/
/*   IF v_Mail_Conn.code != 220
      THEN
        raise_application_error(-20000, 'utl_smtp.open_connection: '||v_Mail_Conn.code||' - '||v_Mail_Conn.text);
      END IF;  */                 
                   
  reply :=  utl_smtp.starttls(v_Mail_Conn);
    IF reply.code != 220
  THEN
    raise_application_error(-20000, 'utl_smtp.starttls: '||reply.code||' - '||reply.text);
  END IF;     
    replies:=utl_smtp.Ehlo(v_Mail_Conn,MAIL_PKG.mailserver);
  if create_rcpt_list(mailfrom).count>0 then
    sndr := create_rcpt_list(mailfrom)(1);
  else
    sndr := create_rcpt_list( 'mail@' || UTL_INADDR.GET_HOST_NAME )(1); -- host from oracle-server
    -- sndr := create_rcpt_list( 'mail@' || substr(replies(1).text,1,instr(replies(1).text,' ')-1))(1); -- Addr from ehlo answer
    end if;

    if mail_pkg.auth_user is not null then
       for x IN 1 .. replies.count loop
       dbms_output.put_line(replies(x).text);
       IF INSTR(replies(x).text,'AUTH')>0 then -- If server supply authorization
            utl_smtp.command(v_Mail_Conn, 'AUTH LOGIN');
            utl_smtp.command(v_Mail_Conn,utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(auth_user))));
            utl_smtp.command(v_Mail_Conn,utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(auth_pass))));
      exit;
     END IF;
     end loop;
    end if;

    utl_smtp.Mail(v_Mail_Conn, sndr.rcptmail);
    FOR rcpts IN 1 .. rcptlist.count
  LOOP
    utl_smtp.Rcpt(v_Mail_Conn, rcptlist(rcpts).rcptmail);
  END LOOP;

    utl_smtp.open_data(v_Mail_Conn); -- open data sheet

  utl_smtp.write_data(v_Mail_Conn, 'Date: ' || to_char(sysdate, 'Dy, DD Mon YYYY hh24:mi:ss','NLS_DATE_LANGUAGE = ''american''') || crlf);
    utl_smtp.write_data(v_Mail_Conn, 'From: ');
  if sndr.rcptname is not null then
        utl_smtp.write_data(v_Mail_Conn, MAIL_PKG.ENCODE(sndr.rcptname) ||' <'|| sndr.rcptmail || '>');
  else
        utl_smtp.write_data(v_Mail_Conn, sndr.rcptmail);
  end if;
    utl_smtp.write_data(v_Mail_Conn, crlf );
    utl_smtp.write_data(v_Mail_Conn, 'Subject: '|| MAIL_PKG.ENCODE(subject) || crlf );
    utl_smtp.write_data(v_Mail_Conn, 'To: ');
    FOR rcpts IN 1 .. rcptlist.count
  LOOP
    if rcpts>1 then
       utl_smtp.write_data(v_Mail_Conn, ',');
    end if;
    if rcptlist(rcpts).rcptname is not null then
        utl_smtp.write_data(v_Mail_Conn, MAIL_PKG.ENCODE(rcptlist(rcpts).rcptname) ||' <'|| rcptlist(rcpts).rcptmail || '>');
    else
        utl_smtp.write_data(v_Mail_Conn, rcptlist(rcpts).rcptmail);
    end if;
  END LOOP;
    utl_smtp.write_data(v_Mail_Conn, crlf );

  IF priority IS NOT NULL and priority BETWEEN 1 AND 5 THEN
      utl_smtp.write_data(v_Mail_Conn, 'X-Priority: ' || priority || crlf );
  END IF;
    utl_smtp.write_data(v_Mail_Conn, 'MIME-version: 1.0' || crlf );
    utl_smtp.write_data(v_Mail_Conn, 'Content-Type: multipart/mixed;'|| crlf );
    utl_smtp.write_data(v_Mail_Conn, ' boundary="'||boundary||'"'|| crlf );
    utl_smtp.write_data(v_Mail_Conn, crlf );

    --Message
    utl_smtp.write_data(v_Mail_Conn, '--'|| boundary || crlf );
    utl_smtp.write_data(v_Mail_Conn, 'Content-Type: '||v_mime||'; charset="utf-8"'|| crlf );
    utl_smtp.write_data(v_Mail_Conn, 'Content-Transfer-Encoding: 8bit'|| crlf );
    utl_smtp.write_data(v_Mail_Conn, crlf );
    utl_smtp.write_raw_data(v_Mail_Conn, utl_raw.cast_to_raw(CONVERT(message,'UTF8')));
    utl_smtp.write_data(v_Mail_Conn, crlf );
    utl_smtp.write_data(v_Mail_Conn, crlf );

  --Attachments
  IF MAIL_PKG.attachments is not null THEN
    FOR x IN 1 .. MAIL_PKG.attachments.count LOOP
          utl_smtp.write_data(v_Mail_Conn, '--'|| boundary || crlf );
          utl_smtp.write_data(v_Mail_Conn, 'Content-Type: '||MAIL_PKG.attachments(x).mimetype||';'|| crlf );
          utl_smtp.write_data(v_Mail_Conn, ' name="');
      utl_smtp.write_raw_data(v_Mail_Conn,utl_raw.cast_to_raw(MAIL_PKG.attachments(x).name));
          utl_smtp.write_data(v_Mail_Conn, '"' || crlf);
          utl_smtp.write_data(v_Mail_Conn, 'Content-Transfer-Encoding: base64'|| crlf );
          utl_smtp.write_data(v_Mail_Conn, 'Content-Disposition: attachment;'|| crlf );
          utl_smtp.write_data(v_Mail_Conn, ' filename="' || MAIL_PKG.ENCODE(MAIL_PKG.attachments(x).name) || '"' || crlf);
          utl_smtp.write_data(v_Mail_Conn, crlf );
      vFile := BFILENAME(MAIL_PKG.attachments(x).dirname,MAIL_PKG.attachments(x).filename);
      dbms_lob.fileopen(vFile, dbms_lob.file_readonly);
      ps:=1; v_amt:=amt;
      LOOP
        BEGIN
          dbms_lob.read (vFile, v_amt, ps, vRAW);
        ps := ps + v_amt;
              utl_smtp.write_raw_data(v_Mail_Conn, UTL_ENCODE.base64_encode(vRAW));
        EXCEPTION
              WHEN no_data_found THEN
        EXIT;
      END;
      END LOOP;
      dbms_lob.fileclose(vFile);

          utl_smtp.write_data(v_Mail_Conn, crlf );
          utl_smtp.write_data(v_Mail_Conn, crlf );
    END LOOP;
  END IF;

    -- Final Boundary
    utl_smtp.write_data(v_Mail_Conn, '--' || boundary || '--');

    utl_smtp.close_data(v_Mail_Conn);
    utl_smtp.quit(v_Mail_Conn);
    
    --LOG
insert into callback_log(id,call_date,branch,call_phone)
       values(SEQ_CALLBACK.Nextval,sysdate,branch,message);
       commit;
       
  -- Clear attachments
    MAIL_PKG.attachments:=MAIL_PKG.attach_list();

 EXCEPTION
    WHEN OTHERS THEN
       BEGIN
         MAIL_PKG.attachments:=MAIL_PKG.attach_list();
     utl_smtp.rset(v_Mail_Conn);
       utl_smtp.quit(v_Mail_Conn);
     EXCEPTION WHEN OTHERS THEN NULL;
     END;
  RAISE;
 END;

BEGIN
  MAIL_PKG.attachments:=MAIL_PKG.attach_list();
END;
/
