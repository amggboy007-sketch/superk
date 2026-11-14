create extension if not exists pgcrypto;

create table if not exists public.branches (
  id uuid primary key default gen_random_uuid(), code text unique not null, name text not null,
  is_active boolean not null default true, created_at timestamptz not null default now()
);
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade, username text unique not null,
  display_name text not null default '', role text not null default 'staff' check (role in ('admin','staff')),
  is_active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.branch_memberships (
  id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade, role text not null default 'staff' check (role in ('admin','manager','staff')),
  created_at timestamptz not null default now(), unique(branch_id,user_id)
);
create table if not exists public.categories (
 id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id) on delete cascade,
 name text not null, created_at timestamptz not null default now(), unique(branch_id,name)
);
create table if not exists public.products (
 id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id) on delete cascade,
 category_id uuid references public.categories(id) on delete set null, sku text, barcode text, name text not null,
 unit text not null default 'ชิ้น', cost numeric(14,2) not null default 0, price numeric(14,2) not null default 0,
 quantity numeric(14,3) not null default 0, min_quantity numeric(14,3) not null default 0,
 is_active boolean not null default true, created_by uuid references public.profiles(id),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create unique index if not exists products_branch_sku_unique on public.products(branch_id,sku) where sku is not null and sku<>'';
create unique index if not exists products_branch_barcode_unique on public.products(branch_id,barcode) where barcode is not null and barcode<>'';
create table if not exists public.inventory_movements (
 id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id) on delete cascade,
 product_id uuid not null references public.products(id) on delete cascade, quantity_delta numeric(14,3) not null,
 movement_type text not null check (movement_type in ('opening','purchase','sale','adjustment','return','transfer_in','transfer_out')),
 note text, user_id uuid references public.profiles(id), created_at timestamptz not null default now()
);
create table if not exists public.sales (
 id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id) on delete cascade,
 receipt_no text, subtotal numeric(14,2) not null default 0, discount numeric(14,2) not null default 0,
 total numeric(14,2) not null default 0, payment_method text, status text not null default 'completed',
 created_by uuid references public.profiles(id), created_at timestamptz not null default now()
);
create table if not exists public.sale_items (
 id uuid primary key default gen_random_uuid(), sale_id uuid not null references public.sales(id) on delete cascade,
 product_id uuid references public.products(id) on delete set null, product_name text not null,
 quantity numeric(14,3) not null, unit_price numeric(14,2) not null, line_total numeric(14,2) not null
);
create table if not exists public.employee_jobs (
 id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id) on delete cascade,
 user_id uuid references public.profiles(id) on delete set null, title text not null, description text,
 status text not null default 'pending' check (status in ('pending','in_progress','done','cancelled')),
 due_at timestamptz, created_by uuid references public.profiles(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.activity_logs (
 id uuid primary key default gen_random_uuid(), branch_id uuid references public.branches(id) on delete set null,
 user_id uuid references public.profiles(id) on delete set null, action text not null, detail jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
create table if not exists public.chat_rooms (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 admin_user_id uuid not null references public.profiles(id) on delete cascade, branch_id uuid references public.branches(id) on delete set null,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(user_id,admin_user_id)
);
create table if not exists public.chat_messages (
 id uuid primary key default gen_random_uuid(), room_id uuid not null references public.chat_rooms(id) on delete cascade,
 sender_id uuid not null references public.profiles(id) on delete cascade,
 message_type text not null default 'text' check (message_type in ('text','image','audio')),
 body text, attachment_path text, attachment_mime text, created_at timestamptz not null default now(),
 expires_at timestamptz not null default (now()+interval '3 days'), read_at timestamptz,
 check (body is not null or attachment_path is not null)
);
create index if not exists memberships_user_branch_idx on public.branch_memberships(user_id,branch_id);
create index if not exists products_branch_name_idx on public.products(branch_id,name);
create index if not exists movements_branch_created_idx on public.inventory_movements(branch_id,created_at desc);
create index if not exists jobs_branch_status_idx on public.employee_jobs(branch_id,status);
create index if not exists chat_messages_room_created_idx on public.chat_messages(room_id,created_at desc);

insert into public.branches(code,name) values ('HQ','สำนักงานใหญ่'),('SALAYA','ศาลายา') on conflict(code) do nothing;

alter table public.branches enable row level security;
alter table public.profiles enable row level security;
alter table public.branch_memberships enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.inventory_movements enable row level security;
alter table public.sales enable row level security;
alter table public.sale_items enable row level security;
alter table public.employee_jobs enable row level security;
alter table public.activity_logs enable row level security;
alter table public.chat_rooms enable row level security;
alter table public.chat_messages enable row level security;

create or replace function public.super_k_is_admin() returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.profiles where id=auth.uid() and role='admin' and is_active); $$;
create or replace function public.super_k_has_branch(p_branch uuid) returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.branch_memberships where user_id=auth.uid() and branch_id=p_branch); $$;

create policy branches_read_member on public.branches for select to authenticated using (public.super_k_is_admin() or public.super_k_has_branch(id));
create policy profiles_read_self_or_admin on public.profiles for select to authenticated using (id=auth.uid() or public.super_k_is_admin());
create policy profiles_update_self_or_admin on public.profiles for update to authenticated using (id=auth.uid() or public.super_k_is_admin()) with check (id=auth.uid() or public.super_k_is_admin());
create policy memberships_read_self_or_admin on public.branch_memberships for select to authenticated using (user_id=auth.uid() or public.super_k_is_admin());
create policy categories_read_member on public.categories for select to authenticated using (public.super_k_is_admin() or public.super_k_has_branch(branch_id));
create policy products_read_member on public.products for select to authenticated using (public.super_k_is_admin() or public.super_k_has_branch(branch_id));
create policy movements_read_member on public.inventory_movements for select to authenticated using (public.super_k_is_admin() or public.super_k_has_branch(branch_id));
create policy sales_read_member on public.sales for select to authenticated using (public.super_k_is_admin() or public.super_k_has_branch(branch_id));
create policy sale_items_read_member on public.sale_items for select to authenticated using (exists(select 1 from public.sales s where s.id=sale_id and (public.super_k_is_admin() or public.super_k_has_branch(s.branch_id))));
create policy jobs_read_member on public.employee_jobs for select to authenticated using (public.super_k_is_admin() or public.super_k_has_branch(branch_id));
create policy logs_read_admin on public.activity_logs for select to authenticated using (public.super_k_is_admin());
create policy rooms_read_participant on public.chat_rooms for select to authenticated using (user_id=auth.uid() or admin_user_id=auth.uid() or public.super_k_is_admin());
create policy rooms_insert_user on public.chat_rooms for insert to authenticated with check (user_id=auth.uid());
create policy messages_read_participant on public.chat_messages for select to authenticated using (exists(select 1 from public.chat_rooms r where r.id=room_id and (r.user_id=auth.uid() or r.admin_user_id=auth.uid() or public.super_k_is_admin())));
create policy messages_insert_participant on public.chat_messages for insert to authenticated with check (sender_id=auth.uid() and exists(select 1 from public.chat_rooms r where r.id=room_id and (r.user_id=auth.uid() or r.admin_user_id=auth.uid() or public.super_k_is_admin())));

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values ('super-k-chat','super-k-chat',false,10485760,array['image/jpeg','image/png','image/webp','audio/webm','audio/mp4','audio/mpeg','audio/ogg']) on conflict(id) do nothing;
create policy chat_storage_read on storage.objects for select to authenticated using (bucket_id='super-k-chat' and exists(select 1 from public.chat_messages m join public.chat_rooms r on r.id=m.room_id where m.attachment_path=name and (r.user_id=auth.uid() or r.admin_user_id=auth.uid() or public.super_k_is_admin())));
create policy chat_storage_insert on storage.objects for insert to authenticated with check (bucket_id='super-k-chat' and auth.uid()::text=split_part(name,'/',1));
