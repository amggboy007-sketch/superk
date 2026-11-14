create or replace function public.admin_set_branch_membership(p_user_id uuid,p_branch_id uuid,p_role text default 'staff') returns void language plpgsql security definer set search_path=public,pg_temp as $$
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if not exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin' and p.is_active) then raise exception 'Only the system administrator can assign branch members'; end if;
  if p_role not in ('admin','manager','staff') then raise exception 'Invalid branch role'; end if;
  insert into public.branch_memberships(branch_id,user_id,role) values(p_branch_id,p_user_id,p_role)
  on conflict(branch_id,user_id) do update set role=excluded.role;
end; $$;
revoke all on function public.admin_set_branch_membership(uuid,uuid,text) from public,anon;
grant execute on function public.admin_set_branch_membership(uuid,uuid,text) to authenticated;
