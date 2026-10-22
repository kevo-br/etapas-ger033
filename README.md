# Etapas do GER033

Site com as etapas do projeto GER033 (Analista Virtual do Mapa Diário), em três visões dos mesmos itens: frentes de trabalho, cronograma e tipo. Qualquer pessoa com o link marca e desmarca os itens. As marcações ficam num banco Supabase e aparecem sozinhas para quem estiver com a página aberta.

- Site: https://kevo-br.github.io/etapas-ger033/
- **Guia completo** (como funciona, layout, banco e como fazer um projeto novo à mão ou de forma automática): [GUIA.md](GUIA.md)
- Gerador para projetos novos: https://kevo-br.github.io/etapas-ger033/modelo/gerador.html

## Arquivos

| Arquivo | Para quê |
|---|---|
| `index.html` | O site inteiro. O que muda de um projeto para outro fica no bloco `ETAPAS_CONFIG` |
| `GUIA.md` | Passo a passo completo |
| `supabase.sql`, `supabase_cronograma.sql`, `supabase_unificar.sql`, `supabase_tipos_status.sql` | Histórico do banco do GER033, nessa ordem. Não use em projetos novos |
| `modelo/schema.sql` | Estrutura completa do banco para um projeto novo |
| `modelo/gerador.html` | Converte o cronograma do MS Project em `dados.sql` e monta a configuração do `index.html` |
| `modelo/exemplo-*.txt` | Cronograma, itens e frentes do GER033 no formato que o gerador espera |

## Dia a dia

- **Marcar, desmarcar e pôr em andamento:** pelo site.
- **Textos, itens, tarefas, fases e frentes:** no Supabase, em Table Editor. Detalhes na seção 11 do [guia](GUIA.md#11-manutenção-do-dia-a-dia).
- **Segurança:** pelo site só dá para marcar (`feito` e `em_andamento`). Textos, criação e exclusão só pelo painel do Supabase.
