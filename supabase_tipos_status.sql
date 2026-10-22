-- =====================================================================
-- Etapas do GER033 — tipo (análise / desenvolvimento / validação),
-- "em andamento" e dependências entre tarefas
-- Rode este script UMA vez no SQL Editor, depois do supabase_unificar.sql.
--
--   tipo         : análise, desenvolvimento ou validação (itens e tarefas)
--   em_andamento : marca que a tarefa/item já começou (o site tem um botão)
--   depende_de   : tarefas que precisam estar concluídas antes desta
--                  (coluna "Predecessoras" do MS Project)
--
-- Regra de atraso no site: uma tarefa só aparece como "Atrasada" se o prazo
-- dela passou E tudo de que ela depende já está concluído. Se ainda falta
-- alguma predecessora, ela aparece como "Aguardando".
-- =====================================================================

alter table public.etapas_itens
  add column if not exists tipo text check (tipo in ('analise', 'desenvolvimento', 'validacao')),
  add column if not exists em_andamento boolean not null default false;

alter table public.cronograma_tarefas
  add column if not exists tipo text check (tipo in ('analise', 'desenvolvimento', 'validacao')),
  add column if not exists em_andamento boolean not null default false,
  add column if not exists depende_de text[] not null default '{}';

-- pelo site, além de "feito", agora dá para marcar "em andamento"
grant update (feito, em_andamento) on public.etapas_itens       to anon, authenticated;
grant update (feito, em_andamento) on public.cronograma_tarefas to anon, authenticated;

-- ---------------------------------------------------------------------
-- Tipo das tarefas do cronograma
-- ---------------------------------------------------------------------
update public.cronograma_tarefas set tipo = 'analise'
 where id in ('det-01', 'det-02', 'det-03', 'det-04', 'det-05', 'det-06', 'det-11',
              'val-01', 'val-02',
              'res-01', 'res-02',
              'int-01', 'int-02');

update public.cronograma_tarefas set tipo = 'desenvolvimento'
 where id in ('det-07', 'det-08', 'det-09',
              'val-03', 'val-04', 'val-05',
              'res-03', 'res-04',
              'int-03', 'int-04');

update public.cronograma_tarefas set tipo = 'validacao'
 where id in ('det-10', 'det-12',
              'val-06', 'val-07',
              'res-05', 'res-06',
              'int-05', 'int-06');

-- ---------------------------------------------------------------------
-- Tipo dos itens das frentes
-- ---------------------------------------------------------------------
update public.etapas_itens set tipo = 'analise'
 where id in ('base-3');

update public.etapas_itens set tipo = 'desenvolvimento'
 where id in ('base-1', 'base-2',
              'conf-1', 'conf-2', 'conf-3',
              'email-1', 'email-2', 'email-3',
              'limites-1', 'limites-2',
              'tiago-1',
              'alertas-1', 'alertas-2', 'alertas-3',
              'apex-1',
              'tabela-1', 'tabela-2',
              'views-1', 'agente-1', 'agente-2', 'agente-3');

update public.etapas_itens set tipo = 'validacao'
 where id in ('tiago-2', 'agente-5');

-- ---------------------------------------------------------------------
-- Dependências (Predecessoras do MS Project)
-- ---------------------------------------------------------------------
update public.cronograma_tarefas set depende_de = '{det-01}' where id = 'det-02';
update public.cronograma_tarefas set depende_de = '{det-03}' where id = 'det-04';
update public.cronograma_tarefas set depende_de = '{det-04}' where id = 'det-05';
update public.cronograma_tarefas set depende_de = '{det-09}' where id = 'det-10';
update public.cronograma_tarefas set depende_de = '{det-10}' where id = 'det-11';
update public.cronograma_tarefas set depende_de = '{det-11}' where id = 'det-12';

update public.cronograma_tarefas set depende_de = '{det-11}' where id = 'val-01';
update public.cronograma_tarefas set depende_de = '{val-01}' where id = 'val-02';
update public.cronograma_tarefas set depende_de = '{val-02}' where id = 'val-03';
update public.cronograma_tarefas set depende_de = '{val-03}' where id = 'val-04';
update public.cronograma_tarefas set depende_de = '{val-04}' where id = 'val-05';
update public.cronograma_tarefas set depende_de = '{val-05}' where id = 'val-06';
update public.cronograma_tarefas set depende_de = '{val-06}' where id = 'val-07';

update public.cronograma_tarefas set depende_de = '{val-06}' where id = 'res-01';
update public.cronograma_tarefas set depende_de = '{res-01}' where id = 'res-02';
update public.cronograma_tarefas set depende_de = '{res-02}' where id = 'res-03';
update public.cronograma_tarefas set depende_de = '{res-03}' where id = 'res-04';
update public.cronograma_tarefas set depende_de = '{res-04}' where id = 'res-05';
update public.cronograma_tarefas set depende_de = '{res-05}' where id = 'res-06';

-- a Interação começa quando a fase Resumo e insights inteira termina
update public.cronograma_tarefas set depende_de = '{res-01,res-02,res-03,res-04,res-05,res-06}' where id = 'int-01';
update public.cronograma_tarefas set depende_de = '{int-01}' where id = 'int-02';
update public.cronograma_tarefas set depende_de = '{int-02}' where id = 'int-03';
update public.cronograma_tarefas set depende_de = '{int-03}' where id = 'int-04';
update public.cronograma_tarefas set depende_de = '{int-04}' where id = 'int-05';
update public.cronograma_tarefas set depende_de = '{int-05}' where id = 'int-06';
