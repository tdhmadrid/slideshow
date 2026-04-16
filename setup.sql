-- ══════════════════════════════════════════════════
--  MenuSlide — Setup SQL para Supabase
--  Ejecuta esto en: Supabase Dashboard → SQL Editor
-- ══════════════════════════════════════════════════

-- 1. TABLA PLATOS
create table if not exists platos (
  id        uuid primary key default gen_random_uuid(),
  nombre    text not null,
  precio    text,
  desc      text,
  url       text,
  tipo      text default 'url',     -- 'storage' | 'url'
  activo    boolean default true,
  orden     integer default 0,
  created_at timestamptz default now()
);

-- 2. TABLA CONFIG (una sola fila)
create table if not exists config (
  id          uuid primary key default gen_random_uuid(),
  restaurant  text default 'Mi Restaurante',
  moneda      text default '€',
  tiempo      integer default 6,     -- segundos por foto
  created_at  timestamptz default now()
);

-- Insertar config inicial si no existe
insert into config (restaurant, moneda, tiempo)
select 'Mi Restaurante', '€', 6
where not exists (select 1 from config);

-- 3. HABILITAR REALTIME en ambas tablas
alter publication supabase_realtime add table platos;
alter publication supabase_realtime add table config;

-- 4. ROW LEVEL SECURITY (RLS)
-- La TV solo necesita leer (anon key)
-- El admin escribe con service role key

alter table platos enable row level security;
alter table config enable row level security;

-- Lectura pública (para la TV con anon key)
create policy "Lectura pública platos"
  on platos for select
  using (true);

create policy "Lectura pública config"
  on config for select
  using (true);

-- Escritura solo con service role (admin)
-- La service role bypasa RLS automáticamente, no hace falta policy extra.
-- Si quieres usar solo anon key en admin (menos seguro), añade:
-- create policy "Escritura anon platos" on platos for all using (true) with check (true);
-- create policy "Escritura anon config" on config for all using (true) with check (true);

-- 5. STORAGE BUCKET para fotos
insert into storage.buckets (id, name, public)
values ('menu-fotos', 'menu-fotos', true)
on conflict (id) do nothing;

-- Política de lectura pública para el bucket
create policy "Fotos públicas"
  on storage.objects for select
  using (bucket_id = 'menu-fotos');

-- Política de subida (service role la bypasa, pero por si usas anon):
create policy "Subida de fotos"
  on storage.objects for insert
  with check (bucket_id = 'menu-fotos');

create policy "Borrado de fotos"
  on storage.objects for delete
  using (bucket_id = 'menu-fotos');
