-- Reto Mibanco: ledger for Doña Rosa's shop.
-- The demo currently has no Supabase Auth user-to-shop mapping. Keep access
-- server-side through the service role until an owner-scoped policy exists.

create table if not exists public.mensajes (
  id uuid primary key default gen_random_uuid(),
  id_mensaje text unique,
  dia text,
  mensaje text,
  transcripcion text,
  telegram_chat_id text,
  telegram_update_id bigint unique,
  created_at timestamptz default now()
);

create table if not exists public.transacciones (
  id uuid primary key default gen_random_uuid(),
  id_mensaje text references public.mensajes(id_mensaje) on delete cascade,
  tipo text check (tipo in ('venta', 'gasto', 'fiado', 'cobro_fiado')),
  producto text,
  cantidad numeric(10,2),
  monto numeric(10,2) null,
  requiere_confirmacion boolean default false,
  cliente_deudor text null,
  orden int,
  created_at timestamptz default now()
);

create table if not exists public.deudas (
  id uuid primary key default gen_random_uuid(),
  id_transaccion_origen uuid references public.transacciones(id),
  cliente text,
  producto text,
  monto_original numeric(10,2),
  saldo_pendiente numeric(10,2),
  estado text default 'PENDIENTE'
);

create index if not exists transacciones_mensaje_orden_idx
  on public.transacciones (id_mensaje, orden);

create index if not exists deudas_cliente_estado_idx
  on public.deudas (cliente, estado);

alter table public.mensajes enable row level security;
alter table public.transacciones enable row level security;
alter table public.deudas enable row level security;

-- Explicit grants are required for Data API access on newer Supabase projects.
grant usage on schema public to service_role;
grant select, insert, update, delete on table
  public.mensajes, public.transacciones, public.deudas
  to service_role;

drop policy if exists mensajes_service_all on public.mensajes;
create policy mensajes_service_all
  on public.mensajes for all to service_role
  using (true) with check (true);

drop policy if exists transacciones_service_all on public.transacciones;
create policy transacciones_service_all
  on public.transacciones for all to service_role
  using (true) with check (true);

drop policy if exists deudas_service_all on public.deudas;
create policy deudas_service_all
  on public.deudas for all to service_role
  using (true) with check (true);

