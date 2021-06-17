create or replace package sadmin as

  /* TODO enter package declarations (types, exceptions, methods etc) here */
    procedure clear(iid_registration in number);
    procedure list_workstation_new(iid_pc number, iid_region number, iip_addr varchar2, inum_device number, itype_device char);
    procedure list_workstation_upd(iid_pc number, iip_addr varchar2, iactive char, inum_device number, itype_device char);
    procedure list_workstation_del(iid_pc number);

    procedure region_new(iid_region number, ilang_territory varchar2, iregion_name varchar2, iregion_name_kaz varchar2);
    procedure region_upd(iid_region number, iactive char, ilang_territory varchar2, iregion_name varchar2, iregion_name_kaz varchar2);
    procedure region_del(iid_region number);

    procedure grp_new(iid_group number, iid_type_group number, iname varchar2, idescription varchar2);
    procedure grp_upd(iid_group number, iid_type_group number, iactive char,  iname varchar2, idescription varchar2);
    procedure grp_del(iid_group number);

    procedure types_group_new(iid_type_group number, igroup_type varchar2);
    procedure types_group_upd(iid_type_group number, igroup_type varchar2);
    procedure types_group_del(iid_type_group number);


    procedure emp_new(iid_emp number, iid_region number, iid_pc number,
                        ilanguage varchar2, iusername varchar2,
                        ipassword varchar2, iattr varchar2, iname varchar2,
                        ilast_name varchar2, imiddlename varchar2, idescr varchar2);
    procedure emp_upd(iid_emp number, iid_region number, iid_pc number,
                        iactive char, ilanguage varchar2, iusername varchar2,
                        ipassword varchar2, iattr varchar2, iname varchar2,
                        ilast_name varchar2, imiddlename varchar2, idescr varchar2);
    procedure emp_del(iid_emp number);

    procedure members_group_employee_new(iid_group number, iid_emp number);
    procedure members_group_employee_upd(iid_group number, iid_emp number);
    procedure members_group_employee_del(iid_group number, iid_emp number);

end sadmin;
/
create or replace package body sadmin as

  procedure clear(iid_registration in number)
  is
  begin
     delete from secmgr.questions_for_testing qt
     where qt.id_registration=iid_registration;
     
     delete from test_operator.users_bundle_composition uc
     where uc.id_registration=iid_registration;

     delete from test_operator.users_bundle_config ucf
     where ucf.id_registration=iid_registration;
     
     delete from test_operator.testing ts
     where ts.id_registration=iid_registration;
     
     delete from test_operator.registration r
     where r.id_registration=iid_registration;
     commit;
  end;
  
  procedure list_workstation_new(iid_pc number, iid_region number, iip_addr varchar2, inum_device number, itype_device char) as
  begin
    /* TODO implementation required */
    insert into list_workstation(id_pc , id_region , ip_addr , active, num_device , type_device, date_op )
    values(iid_pc , iid_region , iip_addr , 'Y', inum_device , itype_device, sysdate );
    commit;
  end list_workstation_new;

  procedure list_workstation_upd(iid_pc number, iip_addr varchar2, iactive char, inum_device number, itype_device char) as
  begin
    /* TODO implementation required */
    update list_workstation l
    set   l.ip_addr=iip_addr,
            l.active=iactive,
            l.num_device=inum_device,
            l.type_device=itype_device,
            l.date_op=sysdate
    where l.id_pc=iid_pc;
    commit;
  end list_workstation_upd;

  procedure list_workstation_del(iid_pc number) as
  begin
    /* TODO implementation required */
    update list_workstation l
    set   l.active='N',
          l.date_op=sysdate
    where l.id_pc=iid_pc;
    commit;
  end list_workstation_del;

    procedure region_new(iid_region number, ilang_territory varchar2, iregion_name varchar2, iregion_name_kaz varchar2)
    as
    begin
    insert into region(id_region, active, lang_territory, region_name, region_name_kaz, date_op)
    values(iid_region , 'Y',ilang_territory, iregion_name , iregion_name_kaz , sysdate);
    commit;
    end region_new;

    procedure region_upd(iid_region number, iactive char, ilang_territory varchar2, iregion_name varchar2, iregion_name_kaz varchar2)
    as
    begin
    update region r
    set r.active=iactive,
        r.lang_territory=ilang_territory,
        r.region_name=iregion_name,
        r.region_name_kaz=iregion_name_kaz,
        r.date_op=sysdate
    where r.id_region=iid_region;
    commit;
    end region_upd;

    procedure region_del(iid_region number) as
    begin
    update region r
    set r.active='N',
        r.date_op=sysdate
    where r.id_region=iid_region;
    commit;

    end region_del;

    procedure grp_new(iid_group number, iid_type_group number, iname varchar2, idescription varchar2)
    as
    begin
    insert into grp (id_group , id_type_group, active, date_op, name , descr )
    values(iid_group , iid_type_group, 'Y', sysdate, iname , idescription );
    commit;
    end grp_new;

    procedure grp_upd(iid_group number, iid_type_group number, iactive char, iname varchar2, idescription varchar2)
    as
    begin
    update grp g
    set g.active=iactive,
        g.id_type_group=iid_type_group,
        g.date_op=sysdate,
        g.name=iname,
        g.descr=idescription
    where g.id_group=iid_group;
    commit;
    end grp_upd;

    procedure grp_del(iid_group number) as
    begin
        update grp g
        set g.active='N'
        where g.id_group=iid_group;
        commit;
    end grp_del;

    procedure types_group_new(iid_type_group number, igroup_type varchar2)
    as
    begin
    insert into types_group (id_type_group , group_type)
    values(iid_type_group , igroup_type);
    commit;
    end types_group_new;

    procedure types_group_upd(iid_type_group number, igroup_type varchar2)
    as
    begin
    update types_group g
    set g.group_type=igroup_type
    where g.id_type_group=iid_type_group;
    commit;
    end types_group_upd;

    procedure types_group_del(iid_type_group number)
    as
    begin
    null;
    end types_group_del;


    procedure emp_new(iid_emp number, iid_region number, iid_pc number,
                        ilanguage varchar2, iusername varchar2,
                        ipassword varchar2, iattr varchar2, iname varchar2,
                        ilast_name varchar2, imiddlename varchar2, idescr varchar2)
    as
    begin
    insert into emp(id_emp, id_region, id_pc,
                    active, language , date_op,
                    username, password , attr,
                    name, lastname, middlename, descr)
    values(iid_emp, iid_region, iid_pc,
            'Y', ilanguage, sysdate,
            iusername, ipassword, iattr,
            iname, ilast_name , imiddlename , idescr );
    commit;
    end emp_new;

    procedure emp_upd(iid_emp number, iid_region number, iid_pc number,
                        iactive char, ilanguage varchar2, iusername varchar2,
                        ipassword varchar2, iattr varchar2, iname varchar2,
                        ilast_name varchar2, imiddlename varchar2, idescr varchar2)
    as
    begin
    update emp e
    set e.id_region=iid_region,
        e.id_pc=iid_pc,
        e.active=iactive,
        e.language=ilanguage,
        e.username=iusername,
        e.password=ipassword,
        e.attr=iattr,
        e.name=iname,
        e.lastname=ilast_name,
        e.middlename=imiddlename,
        e.descr=idescr
    where e.id_emp=iid_emp;
    commit;
    end emp_upd;

    procedure emp_del(iid_emp number) as
    begin
    update emp e
    set e.active='N'
    where e.id_emp=iid_emp;
    commit;
    end emp_del;

    procedure members_group_employee_new(iid_group number, iid_emp number)
	as
	begin
		insert into members_group_employee(id_group, id_emp)
		values(iid_group,iid_emp);
	commit;
	end members_group_employee_new;

    procedure members_group_employee_upd(iid_group number, iid_emp number)
	as
	begin
	null;
	end members_group_employee_upd;

    procedure members_group_employee_del(iid_group number, iid_emp number)
	as
	begin
	if(iid_group is not null and iid_emp is not null)
        then
		delete from members_group_employee m
		where m.id_group=iid_group
		and   m.id_emp=iid_emp;
	end if;
	if(iid_group is null and iid_emp is not null)
        then
		delete from members_group_employee m
		where m.id_emp=iid_emp;
	end if;
	commit;
	end members_group_employee_del;


end sadmin;
/
