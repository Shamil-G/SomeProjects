--load boss group person
insert into post_person ( id_post, active, short_descr, TYPE_EMP, type_emp_kaz )
values (1, 'Y', '�����������', '����, ����������� � ������ �������������, ������������� �� ��������������� � ������������', '����, ����������� � ������ �������������, ������������� �� ��������������� � ������������');

insert into post_person ( id_post, active, short_descr, TYPE_EMP, type_emp_kaz )
values (2, 'Y', '�����������', '����, ����������� ������ �������������, ������������� �� ��������������� � ������������', '����, ����������� ������ �������������, ������������� �� ��������������� � ������������');

--load electro group person
insert into position_person ( id_position, active, short_descr, TYPE_EMP, type_emp_kaz )
values (1, 'Y', '�� �����������', '�� �����������', '�� �����������');

insert into position_person ( id_position, active, short_descr, TYPE_EMP, type_emp_kaz )
values (2, 'Y', '�-�����������', '������������������', '������������������');

insert into position_person ( id_position, active, short_descr, TYPE_EMP, type_emp_kaz )
values (3, 'Y', '�-���������������', '����������������������', '����������������������');

--load access class
--insert into class_position ( id_class, active, short_descr, short_descr_kaz )
--values (1, 'Y', '������ I', '������ I');

insert into class_position ( id_class, active, short_descr, short_descr_kaz )
values (2, 'Y', '������ II', '������ II');

insert into class_position ( id_class, active, short_descr, short_descr_kaz )
values (3, 'Y', '������ III', '������ III');

insert into class_position ( id_class, active, short_descr, short_descr_kaz )
values (4, 'Y', '������ IV', '������ IV');

insert into class_position ( id_class, active, short_descr, short_descr_kaz )
values (5, 'Y', '������ V', '������ V');

--load type_organization
insert into type_ORGANIZATIONS(id_group_organization, active, short_descr,  name_organization, name_organization_kaz)
values(1, 'Y', '���', '�������� ��������������', '�������� ��������������');

insert into type_organizations(id_group_organization, active, short_descr,  name_organization, name_organization_kaz)
values(2, 'Y', '����', '�������������������', '�������������������');

insert into type_organizations(id_group_organization, active,  short_descr,  name_organization, name_organization_kaz)
values(3, 'Y', '����', '������������� ��������������', '������������� ��������������');

insert into type_organizations(id_group_organization, active, short_descr,  name_organization, name_organization_kaz)
values(4, 'Y', '��', '������������� ����', '������������� ����');

insert into type_organizations(id_group_organization, active, short_descr,  name_organization, name_organization_kaz)
values(5, 'Y', '��', '�������� ����', '�������� ����');

insert into type_organizations(id_group_organization, active, short_descr,  name_organization, name_organization_kaz)
values(6, 'Y', '���', '���������������� �����������', '���������������� �����������');

--load tasks
insert into tasks ( id_theme, id_assignment, date_createion, active, order_num, short_descr, descr, descr_kaz )
values (1, null, sysdate, 'Y', 1, '���', '������� ����������� ������������ ������������� ������� � �����', '������� ����������� ������������ ������������� ������� � �����');

insert into tasks ( id_theme, id_assignment, date_createion, active, order_num, short_descr, descr, descr_kaz )
values (2, null, sysdate, 'Y', 2, '���', '������� ������� ������������ ��� ������������ ����������������', '������� ������� ������������ ��� ������������ ����������������');

insert into tasks ( id_theme, id_assignment, date_createion, active, order_num, short_descr, descr, descr_kaz )
values (3, null, sysdate, 'Y', 3, '����', '������� ������� ������������ ��� ������������ ������������������ ������������ �������������� � �������� �����', '������� ������� ������������ ��� ������������ ������������������ ������������ �������������� � �������� �����');




declare
num simple_integer:=1;
begin
  for cOrg in ( select * from type_ORGANIZATIONS )
  loop
      for cRuk in ( select * from post_person )
      loop
          for cEl in ( select * from position_person )
          loop
              for cGRTB in ( select * from class_position )
              loop
		          insert into assignment (id_assignment, id_group_organization, id_post, id_position, id_class)
			      values(num, cOrg.id_group_organization, cRuk.id_post, cEl.id_position, cGRTB.id_class);
                  num:=num+1;
              end loop;
          end loop;
      end loop;
  end loop;
end;

commit
/