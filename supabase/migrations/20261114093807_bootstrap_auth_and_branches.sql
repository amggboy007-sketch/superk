insert into public.branches(name,code) values ('สำนักงานใหญ่','HQ'),('ศาลายา','SALAYA') on conflict(code) do nothing;
create or replace function public.super_k_handle_new_user() returns trigger language plpgsql security definer set search_path=public,pg_temp as $$
declare first_user boolean; new_username text;
begin
  perform pg_advisory_xact_lock(hashtext('super_k_first_admin_bootstrap'));
  select not exists(select 1 from public.profiles) into first_user;
  new_username := case when first_user then 'kiangkai' else coalesce(nullif(new.raw_user_meta_data->>'username',''),split_part(new.email,'@',1)) end;
  insert into public.profiles(id,username,display_name,role) values(new.id,new_username,coalesce(nullif(new.raw_user_meta_data->>'display_name',''),new_username),case when first_user then 'admin' else 'staff' end);
  if first_user then insert into public.branch_memberships(branch_id,user_id,role) select b.id,new.id,'admin' from public.branches b where b.is_active; end if;
  return new;
end; $$;
drop trigger if exists super_k_on_auth_user_created on auth.users;
create trigger super_k_on_auth_user_created after insert on auth.users for each row execute function public.super_k_handle_new_user();
revoke all on function public.super_k_handle_new_user() from public,anon,authenticated;
