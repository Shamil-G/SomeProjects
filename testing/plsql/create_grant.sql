set echo on
spool create_grant.log

grant references, select ON secmgr.emp to test_operator;
grant references, select ON secmgr.grp to test_operator;
grant references, select ON secmgr.members_group_employee to test_operator;
grant references, select ON secmgr.region to test_operator;
grant references, select on secmgr.list_workstation to test_operator;

grant select on secmgr.log_testing to test_operator, testing;
grant select, update on secmgr.questions_for_testing to testing;

grant references, select ON test_operator.questions to secmgr;
grant references, select ON test_operator.replies to secmgr;
grant references, select ON test_operator.themes to secmgr;
grant references, select ON test_operator.testing to secmgr;
grant references, select, insert on secmgr.questions_for_testing to test_operator;
grant references, select on secmgr.emp to test_operator;
grant references, select on secmgr.region to test_operator;
grant references, select on secmgr.list_workstation to test_operator;

grant select ON test_operator.questions to testing;
grant select ON test_operator.replies to testing;
grant select ON test_operator.themes to testing;
grant select on test_operator.testing to testing;
grant select on test_operator.users_bundle_composition to testing;
grant select on test_operator.users_bundle_config to testing;
grant select on test_operator.persons to secmgr, testing;
grant select on test_operator.Registration to secmgr, testing;

grant connect to secmgr, test_operator, testing;
grant create any context to secmgr, test_operator, testing;
grant create view to secmgr;

quit