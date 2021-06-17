create or replace procedure check_test(iid_registration in number)
is
begin
  gsec_ctx.set(iid_registration,'ctl');
end check_test;