create or replace procedure create_first_user_admin
AS
BEGIN
insert into secmgr.types_group values(1,'Сотрудники');
insert into secmgr.grp values(1, 1, 'Y', sysdate, 'secmgr', 'Администратор безопасности');
insert into secmgr.emp (ID_EMP, ID_REGION, ID_PC, ACTIVE, DATE_OP, LANGUAGE, USERNAME, PASSWORD, NAME, LASTNAME, MIDDLENAME, DESCR)
   values(1, null, null, 'Y', sysdate, 'ru', 'admin', 'admin', 'Администратор', null, null, 'Учетная запись по умолчанию');
insert into secmgr.members_group_employee values(1,1);
END;