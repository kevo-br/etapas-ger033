-- =====================================================================
-- Etapas do GER033 — lista única (frentes + cronograma)
-- Rode este script UMA vez no SQL Editor, depois do supabase.sql e do
-- supabase_cronograma.sql.
--
-- Depois dele:
--   * cada item das frentes fica pendurado numa tarefa do cronograma
--     (coluna etapas_itens.tarefa_id);
--   * cada tarefa do cronograma pertence a uma frente
--     (coluna cronograma_tarefas.grupo_id);
--   * uma tarefa com itens se conclui quando todos os itens estão marcados;
--     uma tarefa sem itens é marcada direto.
-- As duas abas do site passam a mostrar os mesmos itens.
-- =====================================================================

alter table public.etapas_itens
  add column if not exists tarefa_id text references public.cronograma_tarefas(id) on delete set null;

alter table public.cronograma_tarefas
  add column if not exists grupo_id text references public.etapas_grupos(id) on delete set null;

-- ---------------------------------------------------------------------
-- Frentes novas e a frente única da Paipe
-- ---------------------------------------------------------------------
insert into public.etapas_grupos (id, ordem, titulo, descricao, nota) values
  ('plan',   0,  'Planejamento e requisitos',
     'Levantamento de requisitos, setup do desenvolvimento e definições que abrem cada fase.',
     null),
  ('paipe',  11, 'Paipe: agente de IA',
     'Reunião, acesso e views para a Paipe, e as tarefas dela no cronograma: conferir os números do mapa, alimentar a IA, explicar os movimentos e gerar os laudos. Nessa fase ela deve pedir bastante apoio nas fórmulas e nos números do mapa.',
     'O acesso já foi liberado. A Paipe começa pelos laudos macro, com as views que já existem; a parte detalhada espera a tabela nova e a view dela. No cronograma, as tarefas da Paipe ainda estão como marcos, sem duração definida.'),
  ('testes', 12, 'Testes e documentação',
     'Testes internos, validação com usuários internos e documentação de cada fase.',
     null)
on conflict (id) do nothing;

-- itens das frentes "Views", "Acesso" e "Agente" passam para a frente Paipe
update public.etapas_itens set grupo_id = 'paipe'
 where id in ('views-1', 'agente-1', 'agente-2', 'agente-3', 'agente-5');
update public.etapas_itens set texto = 'Acesso da Paipe à nossa base liberado' where id = 'agente-1';

-- o cronograma já chegou: sai o item genérico
delete from public.etapas_itens where id = 'agente-4';

-- frentes que ficaram vazias
delete from public.etapas_grupos where id in ('views', 'acesso', 'agente');

-- ordem das frentes na aba "Frentes de trabalho"
update public.etapas_grupos set ordem = 1  where id = 'base';
update public.etapas_grupos set ordem = 2  where id = 'conf';
update public.etapas_grupos set ordem = 3  where id = 'email';
update public.etapas_grupos set ordem = 4  where id = 'limites';
update public.etapas_grupos set ordem = 5  where id = 'tiago';
update public.etapas_grupos set ordem = 6  where id = 'alertas';
update public.etapas_grupos set ordem = 7  where id = 'apex';
update public.etapas_grupos set ordem = 8  where id = 'tabela';

-- ---------------------------------------------------------------------
-- Em qual tarefa do cronograma cada item fica
-- ---------------------------------------------------------------------
update public.etapas_itens set tarefa_id = 'det-02' where id in ('base-1', 'base-2');
update public.etapas_itens set tarefa_id = 'det-05'
 where id in ('base-3', 'conf-1', 'conf-2', 'conf-3', 'email-1', 'email-2', 'email-3', 'limites-1', 'limites-2', 'tiago-1');
update public.etapas_itens set tarefa_id = 'det-07' where id in ('views-1', 'agente-1');
update public.etapas_itens set tarefa_id = 'det-11' where id in ('alertas-1', 'alertas-2', 'alertas-3');
update public.etapas_itens set tarefa_id = 'det-12' where id in ('apex-1', 'tiago-2');
update public.etapas_itens set tarefa_id = 'val-01' where id in ('tabela-1', 'tabela-2');
update public.etapas_itens set tarefa_id = 'val-03' where id = 'agente-5';
update public.etapas_itens set tarefa_id = 'val-04' where id = 'agente-2';
update public.etapas_itens set tarefa_id = 'res-03' where id = 'agente-3';

-- ---------------------------------------------------------------------
-- Em qual frente cada tarefa do cronograma aparece
-- ---------------------------------------------------------------------
update public.cronograma_tarefas set grupo_id = 'plan'
 where id in ('det-01', 'det-03', 'det-04', 'val-01', 'res-01');
update public.cronograma_tarefas set grupo_id = 'base'    where id = 'det-02';
update public.cronograma_tarefas set grupo_id = 'conf'    where id = 'det-05';
update public.cronograma_tarefas set grupo_id = 'alertas' where id = 'det-11';
update public.cronograma_tarefas set grupo_id = 'paipe'
 where id in ('det-06', 'det-07', 'det-08', 'det-09',
              'val-02', 'val-03', 'val-04', 'val-05',
              'res-02', 'res-03', 'res-04',
              'int-01', 'int-02', 'int-03', 'int-04');
update public.cronograma_tarefas set grupo_id = 'testes'
 where id in ('det-10', 'det-12', 'val-06', 'val-07', 'res-05', 'res-06', 'int-05', 'int-06');
