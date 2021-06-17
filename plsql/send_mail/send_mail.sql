CREATE OR REPLACE PROCEDURE SYS.send_mail (p_to    IN VARCHAR2,
                                       p_from      IN VARCHAR2,
                                       p_pass      IN VARCHAR2,
                                       p_subject   IN VARCHAR2,
                                       p_message   IN VARCHAR2,
                                       p_smtp_host IN VARCHAR2,
                                       p_smtp_port IN NUMBER DEFAULT 587)
AS
  boundary VARCHAR2(50) := '-----7D81B75CCC90DFRW4F7A1CBD';
  crlf         VARCHAR2(2)  := utl_tcp.CRLF; -- chr(13)||chr(10);
  v_mime       varchar2(10) := 'text/html';
  mail_conn   UTL_SMTP.connection;
  nls_charset varchar2(16);
  l_user varchar2(64) default '42500@gfss.kz';
  l_pass varchar2(64) default 'Gfss2020!@';
  l_subject varchar2(128) default 'Робот по обращениям 42500';
  l_reply UTL_SMTP.REPLY;
  l_replies UTL_SMTP.REPLIES;
BEGIN
  select value into nls_charset from nls_database_parameters where parameter='NLS_CHARACTERSET';

  l_user:=UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode( UTL_RAW.cast_to_raw (p_from)));
  l_pass:=UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode ( UTL_RAW.cast_to_raw (p_pass)));
  l_subject:= '=?utf-8?B?' || UTL_RAW.CAST_TO_VARCHAR2(UTL_ENCODE.BASE64_ENCODE(UTL_RAW.CAST_TO_RAW(p_subject))) || '?=';

  l_reply := UTL_SMTP.open_connection( host=>p_smtp_host,
                                         port=>p_smtp_port,
                                         c => mail_conn,
                                         tx_timeout=>null,
                                         wallet_path =>'file:/opt/oracle/database/19.3.0.0/admin/gfss/gfss_smtp',
                                         wallet_password => 'wallet123',
                                         secure_connection_before_smtp => false );
  IF l_reply.code != 220
    THEN
      raise_application_error(-20000, 'utl_smtp.open_connection: '||l_reply.code||' - '||l_reply.text);
  END IF;

  l_reply:=utl_smtp.starttls(mail_conn);
  IF l_reply.code != 220
  THEN
    raise_application_error(-20000, 'utl_smtp.starttls: '||l_reply.code||' - '||l_reply.text);
  END IF;

  l_replies:=utl_smtp.Ehlo(mail_conn, p_smtp_host);

   for x IN 1 .. l_replies.count
   loop
     dbms_output.put_line(l_replies(x).text);
     IF INSTR(l_replies(x).text,'AUTH')>0 then -- If server supply authorization
          utl_smtp.command(mail_conn, 'AUTH LOGIN');
          utl_smtp.command(mail_conn,l_user);
          utl_smtp.command(mail_conn,l_pass);
        exit;
    END IF;
  end loop;

  UTL_SMTP.mail(mail_conn, p_from);
  UTL_SMTP.rcpt(mail_conn, p_to);

--/*
  utl_smtp.open_data(mail_conn); -- open data sheet
  utl_smtp.write_data(mail_conn, 'Date: ' || to_char(sysdate, 'Dy, DD Mon YYYY hh24:mi:ss','NLS_DATE_LANGUAGE = ''american''') || crlf);

  utl_smtp.write_data(mail_conn, 'From: ');
  utl_smtp.write_data(mail_conn, p_from);
  utl_smtp.write_data(mail_conn, crlf );
--*/
  utl_smtp.write_data(mail_conn, 'Subject: '|| l_subject || crlf );

--
  utl_smtp.write_data(mail_conn, 'To: ');
  utl_smtp.write_data(mail_conn, p_to);
  utl_smtp.write_data(mail_conn, crlf );

  utl_smtp.write_data(mail_conn, 'MIME-version: 1.0' || crlf );
  utl_smtp.write_data(mail_conn, 'Content-Type: multipart/mixed;'|| crlf );
  utl_smtp.write_data(mail_conn, ' boundary="'||boundary||'"'|| crlf );
  utl_smtp.write_data(mail_conn, crlf );

    --Message
  utl_smtp.write_data(mail_conn, '--'|| boundary || crlf );
  utl_smtp.write_data(mail_conn, 'Content-Type: '||v_mime||'; charset="utf-8"'|| crlf );
  utl_smtp.write_data(mail_conn, 'Content-Transfer-Encoding: 8bit'|| crlf );
  utl_smtp.write_data(mail_conn, crlf );
  utl_smtp.write_raw_data(mail_conn, utl_raw.cast_to_raw(CONVERT(p_message,'UTF8')));
  utl_smtp.write_data(mail_conn, crlf );
  utl_smtp.write_data(mail_conn, crlf );

  utl_smtp.write_data(mail_conn, '--' || boundary || '--');

--  UTL_SMTP.data(mail_conn, p_message || UTL_TCP.crlf || UTL_TCP.crlf);

  utl_smtp.close_data(mail_conn);
  UTL_SMTP.quit(mail_conn);
  exception when others then
      utl_smtp.close_data(mail_conn);
      UTL_SMTP.quit(mail_conn);
      raise_application_error(-20000,'Error: '||nls_charset||', user: '||l_user||', pass: '||l_pass||' : '||sqlerrm);
END;
