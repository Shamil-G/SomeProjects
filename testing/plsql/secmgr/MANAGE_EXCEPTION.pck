CREATE OR REPLACE PACKAGE MANAGE_EXCEPTION AS

procedure del_registration(id_reg in number);

procedure del_person(iid_person in number);

procedure del_all_registration;

END MANAGE_EXCEPTION;
/

CREATE OR REPLACE PACKAGE BODY MANAGE_EXCEPTION AS

procedure del_registration(id_reg in number)
is
begin
  delete from TEST_OPERATOR.questions_for_testing qt where qt.id_registration=id_reg;
  delete from TEST_OPERATOR.users_bundle_composition bc where bc.id_registration=id_reg;
  delete from TEST_OPERATOR.users_bundle_config bc where bc.id_registration=id_reg;
--  delete from test_operator.print_result_history pr where pr.id_registration=id_reg;
  delete from TEST_OPERATOR.testing t where t.id_registration=id_reg;
  delete from TEST_OPERATOR.registration r where r.id_registration=id_reg;
  commit;
end del_registration;

procedure del_person(iid_person in number)is
begin
    for cur in ( select id_registration
                    from TEST_OPERATOR.registration r
                    where r.id_person=iid_person)
    loop
        del_registration(cur.id_registration);
    end loop;
    delete from TEST_OPERATOR.persons p where p.id_person=iid_person;
    commit;
end;

procedure del_all_registration
is
begin
  delete from TEST_OPERATOR.questions_for_testing qt;
  delete from TEST_OPERATOR.users_bundle_composition bc;
  delete from TEST_OPERATOR.users_bundle_config bc;
  delete from TEST_OPERATOR.testing t;
  delete from TEST_OPERATOR.registration r;
end;

END MANAGE_EXCEPTION;
/
