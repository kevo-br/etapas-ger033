-- =====================================================================
-- Site de etapas de projeto — estrutura completa do banco (modelo)
--
-- Use em um projeto NOVO do Supabase: SQL Editor > New query > cole tudo > Run.
-- Depois rode o dados.sql do projeto (feito à mão ou pelo gerador.html).
--
-- Junta, numa ordem só, o que no GER033 foi rodado em quatro etapas
-- (supabase.sql, supabase_cronograma.sql, supabase_unificar.sql e
-- supabase_tipos_status.sql). Não cria nenhum dado.
--
-- Tabelas
--   etapas_fases        fases do cronograma (com início e fim)
--   etapas_grupos       frentes de trabalho (título, descrição, "por que falta")
--   cronograma_tarefas  tarefas de cada fase; cada uma numa frente
--   etapas_itens        itens de detalhe; cada um numa frente e pendurado numa tarefa
--
-- Regras de acesso (chave pública do site)
--   todos leem tudo; só as colunas "feito" e "em_andamento" de tarefas e
--   itens podem ser alteradas. Textos, criação e exclusão só pelo painel.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Tabelas
-- ---------------------------------------------------------------------
create table if not exists public.etapas_fases (
  id           text primary key,
  ordem        int  not null,
  titulo       text not null,
  titulo_curto text not null,
  inicio       date,
  fim          date
);

create table if not exists public.etapas_grupos (
  id         text primary key,
  ordem      int  not null,
  titulo     text not null,
  descricao  text,
  nota       text            -- "por que falta"; aparece enquanto a frente não termina
);

create table if not exists public.cronograma_tarefas (
  id            text primary key,
  fase_id       text not null references public.etapas_fases(id) on delete cascade,
  grupo_id      text references public.etapas_grupos(id) on delete set null,
  ordem         int  not null,
  texto         text not null,
  duracao       text,
  inicio        date,
  fim           date,
  responsavel   text,
  tipo          text check (tipo in ('analise', 'desenvolvimento', 'validacao')),
  depende_de    text[] not null default '{}',   -- ids das tarefas predecessoras
  feito         boolean not null default false,
  em_andamento  boolean not null default false,
  atualizado_em timestamptz not null default now()
);

create table if not exists public.etapas_itens (
  id            text primary key,
  grupo_id      text not null references public.etapas_grupos(id) on delete cascade,
  tarefa_id     text references public.cronograma_tarefas(id) on delete set null,
  ordem         int  not null,
  texto         text not null,
  tipo          text check (tipo in ('analise', 'desenvolvimento', 'validacao')),
  feito         boolean not null default false,
  em_andamento  boolean not null default false,
  atualizado_em timestamptz not null default now()
);

create index if not exists cronograma_tarefas_fase_idx on public.cronograma_tarefas (fase_id, ordem);
create index if not exists etapas_itens_grupo_idx      on public.etapas_itens (grupo_id, ordem);
create index if not exists etapas_itens_tarefa_idx     on public.etapas_itens (tarefa_id);

-- ---------------------------------------------------------------------
-- Data e hora da última alteração sempre pelo relógio do banco
-- ---------------------------------------------------------------------
create or replace function public.etapas_marca_hora()
returns trigger
language plpgsql
as $$
begin
  new.atualizado_em := now();
  return new;
end;
$$;

drop trigger if exists cronograma_tarefas_hora on public.cronograma_tarefas;
create trigger cronograma_tarefas_hora
  before update on public.cronograma_tarefas
  for each row execute function public.etapas_marca_hora();

drop trigger if exists etapas_itens_hora on public.etapas_itens;
create trigger etapas_itens_hora
  before update on public.etapas_itens
  for each row execute function public.etapas_marca_hora();

-- ---------------------------------------------------------------------
-- Segurança: RLS + permissão por coluna
-- ---------------------------------------------------------------------
alter table public.etapas_fases       enable row level security;
alter table public.etapas_grupos      enable row level security;
alter table public.cronograma_tarefas enable row level security;
alter table public.etapas_itens       enable row level security;

drop policy if exists "fases: todos leem" on public.etapas_fases;
create policy "fases: todos leem" on public.etapas_fases for select using (true);

drop policy if exists "grupos: todos leem" on public.etapas_grupos;
create policy "grupos: todos leem" on public.etapas_grupos for select using (true);

drop policy if exists "tarefas: todos leem" on public.cronograma_tarefas;
create policy "tarefas: todos leem" on public.cronograma_tarefas for select using (true);

drop policy if exists "tarefas: todos marcam" on public.cronograma_tarefas;
create policy "tarefas: todos marcam" on public.cronograma_tarefas
  for update using (true) with check (true);

drop policy if exists "itens: todos leem" on public.etapas_itens;
create policy "itens: todos leem" on public.etapas_itens for select using (true);

drop policy if exists "itens: todos marcam" on public.etapas_itens;
create policy "itens: todos marcam" on public.etapas_itens
  for update using (true) with check (true);

revoke all on public.etapas_fases       from anon, authenticated;
revoke all on public.etapas_grupos      from anon, authenticated;
revoke all on public.cronograma_tarefas from anon, authenticated;
revoke all on public.etapas_itens       from anon, authenticated;

grant select on public.etapas_fases       to anon, authenticated;
grant select on public.etapas_grupos      to anon, authenticated;
grant select on public.cronograma_tarefas to anon, authenticated;
grant select on public.etapas_itens       to anon, authenticated;

grant update (feito, em_andamento) on public.cronograma_tarefas to anon, authenticated;
grant update (feito, em_andamento) on public.etapas_itens       to anon, authenticated;

-- ---------------------------------------------------------------------
-- Tempo real: quem está com o site aberto vê as mudanças sem recarregar
-- ---------------------------------------------------------------------
do $$
declare
  t text;
begin
  foreach t in array array['etapas_fases', 'etapas_grupos', 'cronograma_tarefas', 'etapas_itens'] loop
    if not exists (select 1 from pg_publication_tables
                   where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end;
$$;
