-- =====================================================================
-- Etapas do GER033 — estrutura no Supabase
-- Rode este script inteiro uma vez no SQL Editor do projeto.
--
-- etapas_grupos : as frentes (título, descrição, "por que falta")
-- etapas_itens  : os itens que se marcam e desmarcam
--
-- Quem abre o site (chave pública) pode LER tudo e alterar SÓ a coluna
-- "feito" dos itens. Textos, novos itens e exclusões ficam para quem
-- entra no painel do Supabase.
-- =====================================================================

create table if not exists public.etapas_grupos (
  id         text primary key,
  ordem      int  not null,
  titulo     text not null,
  descricao  text,
  nota       text
);

create table if not exists public.etapas_itens (
  id            text primary key,
  grupo_id      text not null references public.etapas_grupos(id) on delete cascade,
  ordem         int  not null,
  texto         text not null,
  feito         boolean not null default false,
  atualizado_em timestamptz not null default now()
);

create index if not exists etapas_itens_grupo_idx on public.etapas_itens (grupo_id, ordem);

-- Data e hora da alteração sempre pelo relógio do banco
create or replace function public.etapas_itens_marca_hora()
returns trigger
language plpgsql
as $$
begin
  new.atualizado_em := now();
  return new;
end;
$$;

drop trigger if exists etapas_itens_hora on public.etapas_itens;
create trigger etapas_itens_hora
  before update on public.etapas_itens
  for each row execute function public.etapas_itens_marca_hora();

-- ---------------------------------------------------------------------
-- Segurança (Row Level Security + permissões por coluna)
-- ---------------------------------------------------------------------
alter table public.etapas_grupos enable row level security;
alter table public.etapas_itens  enable row level security;

drop policy if exists "grupos: todos leem" on public.etapas_grupos;
create policy "grupos: todos leem" on public.etapas_grupos
  for select using (true);

drop policy if exists "itens: todos leem" on public.etapas_itens;
create policy "itens: todos leem" on public.etapas_itens
  for select using (true);

drop policy if exists "itens: todos marcam" on public.etapas_itens;
create policy "itens: todos marcam" on public.etapas_itens
  for update using (true) with check (true);

revoke all on public.etapas_grupos from anon, authenticated;
revoke all on public.etapas_itens  from anon, authenticated;
grant select on public.etapas_grupos to anon, authenticated;
grant select on public.etapas_itens  to anon, authenticated;
grant update (feito) on public.etapas_itens to anon, authenticated;

-- ---------------------------------------------------------------------
-- Tempo real: quem está com o site aberto vê a marcação dos outros
-- ---------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_publication_tables
                 where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'etapas_itens') then
    alter publication supabase_realtime add table public.etapas_itens;
  end if;
  if not exists (select 1 from pg_publication_tables
                 where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'etapas_grupos') then
    alter publication supabase_realtime add table public.etapas_grupos;
  end if;
end;
$$;

-- ---------------------------------------------------------------------
-- Carga inicial (estado do site em 20/10/2026)
-- ---------------------------------------------------------------------
insert into public.etapas_grupos (id, ordem, titulo, descricao, nota) values
  ('base',    1,  'Base de dados do mapa', null, null),
  ('conf',    2,  'Conferência diária automática', null, null),
  ('email',   3,  'E-mail organizado e explicado', null, null),
  ('limites', 4,  'Limites de variação em tabela', null, null),
  ('views',   5,  'Views iniciais para a Paipe', null, null),
  ('acesso',  6,  'Acesso da Paipe à nossa base de dados', null, null),
  ('alertas', 7,  'Registrar alertas e erros para a mensageria',
     'A conferência grava cada alerta e erro numa tabela de ocorrências; a mensageria lê essa tabela e avisa a equipe pelo WhatsApp, sem repetir o que já foi avisado.',
     'A estrutura está desenhada e o código está em fase inicial: ainda faltam revisão, testes e implantação. O envio depende da reestruturação das notificações, que está com o Vinicius (Frente A).'),
  ('apex',    8,  'Criar a página APEX',
     'Uma página para consultar a conferência no celular, quase um espelho do e-mail.',
     'Foi iniciada, mas com o remanejamento das demandas do projeto ficou para um segundo momento. Será a última etapa do desenvolvimento interno, porque reúne tudo o que está no e-mail numa visualização de acesso mais fácil.'),
  ('tiago',   9,  'Incluir as conferências do Tiago no e-mail',
     'Levar para o e-mail a conferência que o Tiago (suporte) ainda faz à mão de madrugada, para pegar os erros mais graves antes da revisão da equipe gerencial.',
     'Primeiro foi desenvolvida a validação do mapa que a equipe gerencial fazia em planilha. Concluída essa parte, entra a validação feita pelo Tiago.'),
  ('tabela',  10, 'Criar a tabela detalhada para o agente de IA',
     'Uma tabela nova com mais detalhes das informações do mapa, além da página principal, para o agente da Paipe consumir.',
     'Aguarda a finalização dos dados enviados por e-mail; depois disso, esta etapa começa. Ela libera a Paipe para a parte detalhada dos laudos; a parte macro já pode começar com as views que existem.'),
  ('agente',  11, 'Explicações e laudos do agente de IA (Paipe)',
     'A Paipe confere os números do mapa e alimenta a IA deles, para explicar os movimentos, justificar os números e gerar os laudos. Nessa fase ela deve pedir bastante apoio nas fórmulas e nos números do mapa.',
     'Aguardando o cronograma da Paipe; as etapas deles entram aqui quando chegar. Pelo combinado, começam pelos laudos macro, com as views que já existem, e a parte detalhada espera a tabela nova e a view dela.')
on conflict (id) do nothing;

insert into public.etapas_itens (id, grupo_id, ordem, texto, feito) values
  ('base-1',    'base',    1, 'Tabelas com os números da página principal do mapa, por dia e totais do mês', true),
  ('base-2',    'base',    2, 'Procedure e rotina de carga diária', true),
  ('base-3',    'base',    3, 'Regras e queries de validação', true),
  ('conf-1',    'conf',    1, 'Roda toda madrugada, logo depois da carga do mapa', true),
  ('conf-2',    'conf',    2, 'Confere carteira, entrada de pedidos, faturamento, pronto e programados, estoques, prazo e preço médio e alterações retroativas', true),
  ('conf-3',    'conf',    3, 'Envia o resultado completo em um único e-mail', true),
  ('email-1',   'email',   1, 'Blocos agrupados em seções por assunto', true),
  ('email-2',   'email',   2, 'Cada bloco tem um texto explicando o que valida e de onde vem o dado', true),
  ('email-3',   'email',   3, 'Regras mostradas em formato de fórmula, com a conta aberta', true),
  ('limites-1', 'limites', 1, 'Tolerância de cada validação cadastrada na MPD_CONF_DIA_VARIACAO', true),
  ('limites-2', 'limites', 2, 'Ajuste sem mexer no código; validações sem limite aparecem como informativas', true),
  ('views-1',   'views',   1, 'Views de exposição sobre as tabelas atuais do mapa', true),
  ('agente-1',  'acesso',  1, 'Acesso liberado pela nossa infra', true),
  ('alertas-1', 'alertas', 1, 'Tabela de ocorrências gravada pela conferência', false),
  ('alertas-2', 'alertas', 2, 'Log das alterações de limite: quem mudou, quando e por quê', false),
  ('alertas-3', 'alertas', 3, 'Mensageria lendo as ocorrências e avisando pelo WhatsApp', false),
  ('apex-1',    'apex',    1, 'Página espelhando o conteúdo do e-mail', false),
  ('tiago-1',   'tiago',   1, 'Validações do Tiago incluídas no e-mail', false),
  ('tiago-2',   'tiago',   2, 'Documento de regras e contextos atualizado com as novas validações', false),
  ('tabela-1',  'tabela',  1, 'Tabela com mais detalhes das informações do mapa', false),
  ('tabela-2',  'tabela',  2, 'View da tabela nova, como as que já existem', false),
  ('agente-4',  'agente',  1, 'Cronograma da Paipe recebido e etapas adicionadas aqui', false),
  ('agente-5',  'agente',  2, 'Conferência dos números do mapa pela Paipe, com apoio nas fórmulas', false),
  ('agente-2',  'agente',  3, 'Explicação dos movimentos e justificativa dos números', false),
  ('agente-3',  'agente',  4, 'Geração dos laudos', false)
on conflict (id) do nothing;
