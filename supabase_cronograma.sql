-- =====================================================================
-- Etapas do GER033 — fases e tarefas do cronograma
-- Rode este script UMA vez no SQL Editor, depois do supabase.sql.
--
-- etapas_fases        : as 4 fases do cronograma (com datas)
-- cronograma_tarefas  : as tarefas de cada fase (datas, responsável, feito)
-- etapas_grupos.fase_id : em qual fase cada frente se encaixa
--
-- Mesmas regras do resto: pelo site todos leem e só a coluna "feito"
-- das tarefas pode ser alterada.
-- =====================================================================

create table if not exists public.etapas_fases (
  id           text primary key,
  ordem        int  not null,
  titulo       text not null,
  titulo_curto text not null,
  inicio       date,
  fim          date
);

create table if not exists public.cronograma_tarefas (
  id            text primary key,
  fase_id       text not null references public.etapas_fases(id) on delete cascade,
  ordem         int  not null,
  texto         text not null,
  duracao       text,
  inicio        date,
  fim           date,
  responsavel   text,
  feito         boolean not null default false,
  atualizado_em timestamptz not null default now()
);

create index if not exists cronograma_tarefas_fase_idx on public.cronograma_tarefas (fase_id, ordem);

alter table public.etapas_grupos
  add column if not exists fase_id text references public.etapas_fases(id) on delete set null;

-- Data e hora da alteração pelo relógio do banco (reaproveita a função do supabase.sql)
drop trigger if exists cronograma_tarefas_hora on public.cronograma_tarefas;
create trigger cronograma_tarefas_hora
  before update on public.cronograma_tarefas
  for each row execute function public.etapas_itens_marca_hora();

-- Segurança
alter table public.etapas_fases       enable row level security;
alter table public.cronograma_tarefas enable row level security;

drop policy if exists "fases: todos leem" on public.etapas_fases;
create policy "fases: todos leem" on public.etapas_fases for select using (true);

drop policy if exists "tarefas: todos leem" on public.cronograma_tarefas;
create policy "tarefas: todos leem" on public.cronograma_tarefas for select using (true);

drop policy if exists "tarefas: todos marcam" on public.cronograma_tarefas;
create policy "tarefas: todos marcam" on public.cronograma_tarefas
  for update using (true) with check (true);

revoke all on public.etapas_fases       from anon, authenticated;
revoke all on public.cronograma_tarefas from anon, authenticated;
grant select on public.etapas_fases       to anon, authenticated;
grant select on public.cronograma_tarefas to anon, authenticated;
grant update (feito) on public.cronograma_tarefas to anon, authenticated;
-- a coluna nova de etapas_grupos herda o "select" que já existe na tabela

-- Tempo real
do $$
begin
  if not exists (select 1 from pg_publication_tables
                 where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'cronograma_tarefas') then
    alter publication supabase_realtime add table public.cronograma_tarefas;
  end if;
  if not exists (select 1 from pg_publication_tables
                 where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'etapas_fases') then
    alter publication supabase_realtime add table public.etapas_fases;
  end if;
end;
$$;

-- ---------------------------------------------------------------------
-- Carga: fases e tarefas do cronograma (MS Project, % concluída 100 = feito)
-- ---------------------------------------------------------------------
insert into public.etapas_fases (id, ordem, titulo, titulo_curto, inicio, fim) values
  ('det', 1, 'Detecção de anomalias',                                       'Detecção de anomalias',     '2026-05-12', '2026-07-28'),
  ('val', 2, 'Validação e justificativa',                                   'Validação e justificativa', '2026-07-22', '2026-10-06'),
  ('res', 3, 'Resumo e insights do Mapa',                                   'Resumo e insights',         '2026-09-30', '2026-12-15'),
  ('int', 4, 'Interação do usuário com uma plataforma para esclarecimentos', 'Interação do usuário',      '2026-12-16', '2026-12-23')
on conflict (id) do nothing;

insert into public.cronograma_tarefas (id, fase_id, ordem, texto, duracao, inicio, fim, responsavel, feito) values
  ('det-01', 'det',  1, 'Levantamento de requisitos e entendimento do Mapa Diário',                         '3 dias',  '2026-05-12', '2026-05-14', 'Eberton',       true),
  ('det-02', 'det',  2, 'Mapeamento das fontes de dados',                                                    '4 dias',  '2026-05-15', '2026-05-20', 'Eberton',       true),
  ('det-03', 'det',  3, 'Definição de SETUP de desenvolvimento interno',                                     '10 dias', '2026-05-20', '2026-06-02', 'Hartz; Ebraim', true),
  ('det-04', 'det',  4, 'Definição das anomalias',                                                           '10 dias', '2026-06-03', '2026-06-16', 'Eberton',       true),
  ('det-05', 'det',  5, 'Regras de conferência, validações e critérios de inconsistência',                   '15 dias', '2026-06-17', '2026-07-07', 'Eberton',       true),
  ('det-06', 'det',  6, 'Reunião com a Paipe',                                                               '0 dias',  '2026-05-13', '2026-05-13', 'Eberton',       true),
  ('det-07', 'det',  7, 'Estruturação da lógica de cruzamento com dados de sistema',                         '0 dias',  '2026-06-08', '2026-06-08', 'Paipe',         false),
  ('det-08', 'det',  8, 'Desenvolvimento do Analista Virtual',                                               '0 dias',  '2026-05-13', '2026-05-13', 'Paipe',         false),
  ('det-09', 'det',  9, 'Configuração dos resumos comparativos mês atual vs. ano anterior',                  '0 dias',  '2026-05-13', '2026-05-13', 'Paipe',         false),
  ('det-10', 'det', 10, 'Testes internos, validação com usuários internos e ajustes',                        '35 dias', '2026-05-13', '2026-06-30', 'Eberton',       false),
  ('det-11', 'det', 11, 'Mapeamento de estruturas necessárias para atendimento de alertas (inclusive SMS)',  '15 dias', '2026-07-01', '2026-07-21', null,            false),
  ('det-12', 'det', 12, 'Documentação e disponibilização da solução',                                        '5 dias',  '2026-07-22', '2026-07-28', 'Eberton',       false),

  ('val-01', 'val',  1, 'Levantamento de requisitos e entendimento das fontes de dados e regras de conferência', '15 dias', '2026-07-22', '2026-08-11', 'Eberton', false),
  ('val-02', 'val',  2, 'Definição dos critérios de inconsistência',                                         '0 dias',  '2026-08-11', '2026-08-11', 'Paipe',         false),
  ('val-03', 'val',  3, 'Estruturação da lógica de cruzamento com dados de sistema',                         '0 dias',  '2026-08-11', '2026-08-11', 'Paipe',         false),
  ('val-04', 'val',  4, 'Desenvolvimento do Analista Virtual',                                               '0 dias',  '2026-08-11', '2026-08-11', 'Paipe',         false),
  ('val-05', 'val',  5, 'Configuração dos resumos comparativos',                                             '0 dias',  '2026-08-11', '2026-08-11', 'Paipe',         false),
  ('val-06', 'val',  6, 'Testes internos, validação com usuários internos e ajustes',                        '35 dias', '2026-08-12', '2026-09-29', 'Eberton',       false),
  ('val-07', 'val',  7, 'Documentação e disponibilização da solução',                                        '5 dias',  '2026-09-30', '2026-10-06', 'Eberton',       false),

  ('res-01', 'res',  1, 'Levantamento de requisitos e entendimento das fontes de dados e regras',            '15 dias', '2026-09-30', '2026-10-20', 'Eberton',       false),
  ('res-02', 'res',  2, 'Definição dos critérios de cruzamento dos dados e estruturação da lógica',          '0 dias',  '2026-10-20', '2026-10-20', 'Paipe',         false),
  ('res-03', 'res',  3, 'Desenvolvimento do Analista Virtual',                                               '0 dias',  '2026-10-20', '2026-10-20', 'Paipe',         false),
  ('res-04', 'res',  4, 'Configuração dos resumos comparativos',                                             '0 dias',  '2026-10-20', '2026-10-20', 'Paipe',         false),
  ('res-05', 'res',  5, 'Testes internos, validação com usuários internos e ajustes',                        '35 dias', '2026-10-21', '2026-12-08', 'Eberton',       false),
  ('res-06', 'res',  6, 'Documentação e disponibilização da solução',                                        '5 dias',  '2026-12-09', '2026-12-15', 'Eberton',       false),

  ('int-01', 'int',  1, 'Levantamento de requisitos e entendimento das fontes de dados e regras',            '1 dia',   '2026-12-16', '2026-12-16', 'Paipe',         false),
  ('int-02', 'int',  2, 'Definição dos critérios de cruzamento dos dados e estruturação da lógica',          '1 dia',   '2026-12-17', '2026-12-17', 'Paipe',         false),
  ('int-03', 'int',  3, 'Desenvolvimento do Analista Virtual',                                               '1 dia',   '2026-12-18', '2026-12-18', 'Paipe',         false),
  ('int-04', 'int',  4, 'Configuração dos resumos comparativos',                                             '1 dia',   '2026-12-21', '2026-12-21', 'Paipe',         false),
  ('int-05', 'int',  5, 'Testes internos, validação com usuários internos e ajustes',                        '1 dia',   '2026-12-22', '2026-12-22', 'Eberton',       false),
  ('int-06', 'int',  6, 'Documentação e disponibilização da solução',                                        '1 dia',   '2026-12-23', '2026-12-23', 'Eberton',       false)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------
-- Em qual fase cada frente se encaixa (proposta; ajuste no Table Editor,
-- coluna fase_id de etapas_grupos, se quiser outro encaixe)
-- ---------------------------------------------------------------------
update public.etapas_grupos set fase_id = 'det'
 where id in ('base', 'conf', 'email', 'limites', 'alertas', 'tiago', 'apex', 'views', 'acesso');
update public.etapas_grupos set fase_id = 'val'
 where id in ('tabela', 'agente');
