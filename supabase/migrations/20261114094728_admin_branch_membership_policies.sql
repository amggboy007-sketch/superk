drop function if exists public.admin_set_branch_membership(uuid,uuid,text);
create policy memberships_admin_manage on public.branch_memberships for all to authenticated
using (exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin' and p.is_active))
with check (exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin' and p.is_active));
grant insert,update,delete on public.branch_memberships to authenticated;
