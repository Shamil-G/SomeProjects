--load boss group person
insert into post_person ( id_post, active, short_descr, TYPE_EMP, type_emp_kaz )
values (1, 'Y', 'Руководство', 'Лица, относящиеся к первым руководителям, ответственным за энергохозяйство и безопасность', 'Лица, относящиеся к первым руководителям, ответственным за энергохозяйство и безопасность');

insert into post_person ( id_post, active, short_descr, TYPE_EMP, type_emp_kaz )
values (2, 'Y', 'Исполнители', 'Лица, подчиненные первым руководителям, ответственным за энергохозяйство и безопасность', 'Лица, подчиненные первым руководителям, ответственным за энергохозяйство и безопасность');

--load electro group person
insert into position_person ( id_position, active, short_descr, TYPE_EMP, type_emp_kaz )
values (1, 'Y', 'Не специалисты', 'Не специалисты', 'Не специалисты');

insert into position_person ( id_position, active, short_descr, TYPE_EMP, type_emp_kaz )
values (2, 'Y', 'Э-Технический', 'Электротехнический', 'Электротехнический');

insert into position_person ( id_position, active, short_descr, TYPE_EMP, type_emp_kaz )
values (3, 'Y', 'Э-Технологический', 'Электротехнологический', 'Электротехнологический');

--load access class
--insert into class_position ( id_class, active, short_descr, short_descr_kaz )
--values (1, 'Y', 'группа I', 'группа I');

insert into class_position ( id_class, active, short_descr, short_descr_kaz )
values (2, 'Y', 'группа II', 'группа II');

insert into class_position ( id_class, active, short_descr, short_descr_kaz )
values (3, 'Y', 'группа III', 'группа III');

insert into class_position ( id_class, active, short_descr, short_descr_kaz )
values (4, 'Y', 'группа IV', 'группа IV');

insert into class_position ( id_class, active, short_descr, short_descr_kaz )
values (5, 'Y', 'группа V', 'группа V');

--load type_organization
insert into type_ORGANIZATIONS(id_group_organization, active, short_descr,  name_organization, name_organization_kaz)
values(1, 'Y', 'ТЭЦ', 'Тепловая электростанция', 'Тепловая электростанция');

insert into type_organizations(id_group_organization, active, short_descr,  name_organization, name_organization_kaz)
values(2, 'Y', 'ГРЭС', 'Гидроэлектростанция', 'Гидроэлектростанция');

insert into type_organizations(id_group_organization, active,  short_descr,  name_organization, name_organization_kaz)
values(3, 'Y', 'ГТЭС', 'Газотурбинная электростанция', 'Газотурбинная электростанция');

insert into type_organizations(id_group_organization, active, short_descr,  name_organization, name_organization_kaz)
values(4, 'Y', 'ЭС', 'Электрические сети', 'Электрические сети');

insert into type_organizations(id_group_organization, active, short_descr,  name_organization, name_organization_kaz)
values(5, 'Y', 'ТС', 'Тепловые сети', 'Тепловые сети');

insert into type_organizations(id_group_organization, active, short_descr,  name_organization, name_organization_kaz)
values(6, 'Y', 'ЭСО', 'Энергоснабжающая организация', 'Энергоснабжающая организация');

--load tasks
insert into tasks ( id_theme, id_assignment, date_createion, active, order_num, short_descr, descr, descr_kaz )
values (1, null, sysdate, 'Y', 1, 'ПТЭ', 'Правила технической эксплуатации электрических станций и сетей', 'Правила технической эксплуатации электрических станций и сетей');

insert into tasks ( id_theme, id_assignment, date_createion, active, order_num, short_descr, descr, descr_kaz )
values (2, null, sysdate, 'Y', 2, 'ПТБ', 'Правила техники безопасности при эксплуатации электроустановок', 'Правила техники безопасности при эксплуатации электроустановок');

insert into tasks ( id_theme, id_assignment, date_createion, active, order_num, short_descr, descr, descr_kaz )
values (3, null, sysdate, 'Y', 3, 'ПТБт', 'Правила техники безопасности при эксплуатации тепломеханического оборудования электростанций и тепловых сетей', 'Правила техники безопасности при эксплуатации тепломеханического оборудования электростанций и тепловых сетей');




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