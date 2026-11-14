create schema if not exists app_private;
revoke all on schema app_private from public,anon,authenticated;
create or replace function app_private.apply_inventory_movement() returns trigger language plpgsql security definer set search_path='' as $$
declare next_qty numeric(14,3);
begin
  update public.products set quantity=quantity+new.quantity_delta,updated_at=now()
  where id=new.product_id and branch_id=new.branch_id returning quantity into next_qty;
  if not found then raise exception 'Product not found in the selected branch'; end if;
  if next_qty<0 then raise exception 'Insufficient stock: resulting quantity cannot be negative'; end if;
  return new;
end; $$;
revoke all on function app_private.apply_inventory_movement() from public,anon,authenticated;
drop trigger if exists inventory_movement_updates_product on public.inventory_movements;
create trigger inventory_movement_updates_product after insert on public.inventory_movements for each row execute function app_private.apply_inventory_movement();
