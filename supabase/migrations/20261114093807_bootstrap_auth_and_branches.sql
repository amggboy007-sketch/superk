create or replace function public.super_k_handle_new_user() returns trigger language plpgsql security definer set search_path=public,auth as $$
declare is_first boolean; uname text; admin_id uuid;
begin
  select not exists(select 1 from public.profiles) into is_first;
  uname := case when is_first then 'kiangkai' else coalesce(nullif(new.raw_user_meta_data->>'username',''),split_part(new.email,'@',1)) end;
  if exists(select 1 from public.profiles where username=uname) then uname := uname || '_' || left(new.id::text,6); end if;
  insert into public.profiles(id,username,display_name,role) values(new.id,uname,coalesce(new.raw_user_meta_data->>'display_name',uname),case when is_first then 'admin' else 'staff' end);
  if is_first then
    insert into public.branch_memberships(branch_id,user_id,role) select id,new.id,'admin' from public.branches where is_active;
  end if;
  return new;
end; $$;
drop trigger if exists on_auth_user_created_super_k on auth.users;
create trigger on_auth_user_created_super_k after insert on auth.users for each row execute function public.super_k_handle_new_user();
revoke all on function public.super_k_handle_new_user() from public,anon,authenticated;
