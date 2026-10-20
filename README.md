# Etapas do GER033

Site com a árvore de etapas do projeto GER033 (Analista Virtual do Mapa Diário). Qualquer pessoa com o link marca e desmarca os itens. As marcações ficam num banco Supabase e aparecem sozinhas para quem estiver com a página aberta.

- `index.html`: o site inteiro (visual, lógica e a configuração do Supabase no bloco `ETAPAS_CONFIG`).
- `supabase.sql`: cria as tabelas, as regras de acesso e a carga inicial das etapas.

## 1. Criar o banco no Supabase

1. Entre em [supabase.com](https://supabase.com) e crie um projeto (plano Free; região **South America (São Paulo)**). Guarde a senha do banco que ele pedir.
2. No menu lateral, abra **SQL Editor**, clique em **New query**, cole todo o conteúdo de `supabase.sql` e clique em **Run**. Deve aparecer "Success. No rows returned".
3. Confira em **Table Editor**: as tabelas `etapas_grupos` (11 linhas) e `etapas_itens` (25 linhas) devem estar lá.

### Cronograma (fases)

Depois do `supabase.sql`, rode também o `supabase_cronograma.sql` (mesmo caminho: SQL Editor > New query > Run). Ele cria:

- `etapas_fases`: as 4 fases do cronograma, com início e fim;
- `cronograma_tarefas`: as tarefas de cada fase, com datas, duração, responsável e `feito`;
- a coluna `fase_id` em `etapas_grupos`, que diz em qual fase cada frente aparece.

Com isso o site ganha a aba **Cronograma** e o filtro por fase, que vale nas duas abas. Sem esse script, o site continua mostrando só as frentes.

## 2. Ligar o site ao banco

1. Em **Project Settings > Data API**, copie a **Project URL** (algo como `https://abcdefgh.supabase.co`).
2. Em **Project Settings > API Keys**, copie a chave **publishable** (começa com `sb_publishable_`). Em projetos antigos ela se chama **anon public**.
3. Abra `index.html`, procure `ETAPAS_CONFIG` e troque os dois valores:

   ```js
   window.ETAPAS_CONFIG = {
     url: "https://abcdefgh.supabase.co",
     chave: "sb_publishable_..."
   };
   ```

4. Abra o `index.html` no navegador para testar: as etapas devem carregar, e marcar um item deve mostrar "Tudo salvo".

Nunca coloque no site a chave **secret** (ou **service_role**): ela ignora as regras de acesso.

## 3. Publicar no GitHub Pages 

1. No GitHub, crie um repositório novo e **público**, por exemplo `etapas-ger033`, sem README.
2. Na pasta `site-etapas`, envie os arquivos:

   ```bash
   git remote add origin https://github.com/kevo-br/etapas-ger033.git
   git push -u origin main
   ```

3. No repositório, vá em **Settings > Pages**, escolha **Deploy from a branch**, branch `main`, pasta `/ (root)` e salve.
4. Em 1 ou 2 minutos o endereço aparece no topo da página de Pages (algo como `https://kevo-br.github.io/etapas-ger033/`). O andamento fica na aba **Actions**.

Cada commit no `main` republica o site em cerca de 1 minuto.

## Como editar o conteúdo

Os textos ficam no banco, então não precisa mexer no site:

- **Mudar título, descrição ou "por que falta" de uma frente:** Table Editor > `etapas_grupos`, edite a célula. A coluna `nota` é o "por que falta" e só aparece enquanto a frente não estiver concluída.
- **Incluir um item:** Table Editor > `etapas_itens` > **Insert row**. Preencha `id` (único, por exemplo `agente-6`), `grupo_id` (o `id` da frente), `ordem` e `texto`.
- **Incluir uma frente:** insira em `etapas_grupos` e depois os itens dela em `etapas_itens`.
- **Remover:** apague a linha no Table Editor. Apagar uma frente apaga os itens dela.

Quem está com o site aberto vê essas mudanças sem recarregar.

## Segurança

- Pelo site, qualquer pessoa com o link pode **ler** tudo e **marcar/desmarcar** itens. Ela não consegue mudar textos, criar nem apagar nada. Isso é garantido pelas regras do `supabase.sql` (RLS e permissão só na coluna `feito`).
- A data da última alteração vem do relógio do banco.
- Se alguém bagunçar as marcações, corrija pelo Table Editor ou pelo próprio site.
