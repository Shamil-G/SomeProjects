create or replace package article is

  -- Author  : ГУСЕЙНОВ_Ш
  -- Created : 20.10.2020 16:44:06
  -- Purpose : test python
  
  -- Public type declarations
  procedure new(ititle in char, iintro in varchar2, itext in varchar2);
  procedure del(iid in number);
  procedure upd(iid in number, ititle in char, iintro in varchar2, itext in varchar2);

end article;
/
create or replace package body article is

  procedure new(ititle in char, iintro in varchar2, itext in varchar2)
  is
  msg varchar2(1000);
  begin
    msg:='INS Получено: '||ititle || ' : ' || iintro || ' : '||itext;
    insert into protocol values(sysdate, msg);
    commit;
    insert into articles(id, title, intro, text, dat) values(seq_article.nextval, ititle, iintro, itext, sysdate);
    commit;
  end new;

  procedure del(iid in number)
  is
  msg varchar2(64);
  begin
    msg:='DEL Удалена статья : '||iid;
    insert into protocol values(sysdate, msg);
    commit;
    delete from articles a where a.id = iid;
    commit;
  end del;

  procedure upd(iid in number, ititle in char, iintro in varchar2, itext in varchar2)
  is
  msg varchar2(1000);
  begin
    msg:='UPD Получено: '||ititle || ' : ' || iintro || ' : '||itext;
    insert into protocol values(sysdate, msg);
    commit;
    update articles a
           set a.title=ititle,
               a.intro=iintro,
               a.text=itext,
               a.dat=sysdate
    where a.id = iid;
    commit;
  end upd;

begin
  null;
  -- Initialization
end article;
/
