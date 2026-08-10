# GIF Search

Extensão local do Raycast: busca GIFs no [GIPHY](https://giphy.com), mostra as prévias num
grid com scroll infinito, e cola, copia ou baixa o escolhido.

Mesmo formato da `wallpaper-picker`: `<Grid>` alimentado por `useFetch` com a URL como função
da página, `throttle` na busca e `keepPreviousData` para o grid não piscar.

## A chave da API

**É o único passo obrigatório.** Pegue uma em
[developers.giphy.com/dashboard](https://developers.giphy.com/dashboard/) (grátis, basta criar
um app do tipo *API*) e cole na preferência **GIPHY API Key** — o Raycast pede na primeira vez
que você abrir o comando, e depois dá para editar com `⌘,` em cima da extensão.

A chave fica como preferência, e não como constante no código, de propósito: o Raycast guarda
no keychain do macOS, então ela nunca entra neste repositório. Se ela virasse uma variável em
`src/`, o primeiro `git commit` publicaria a chave junto.

Sem chave a API responde `401`, e com chave inválida `403`. Os dois casos viram a mesma
mensagem legível no lugar de um erro cru de fetch — veja `parseGiphyResponse` em
`src/lib/giphy.ts`.

## Instalação

```bash
cd raycast-extensions/gif-search && npm install && npm run dev
```

Depois é só `⌃C`. A extensão fica registrada no Raycast permanentemente.

## Ações

| Atalho | Ação |
|---|---|
| `⏎` | Cola a URL do GIF no app da frente |
| `⌘⏎` | Copia a URL |
| `⌘⇧M` | Copia como Markdown |
| `⌘⇧D` | Baixa o GIF para a pasta configurada |
| `⌘⇧O` | Abre no GIPHY |

## Preferências

Rating (`g`/`pg`/`pg-13`/`r`, padrão `g`), pasta de download (padrão `~/Downloads`) e três
controles do tamanho do GIF no grid:

| Preferência | Padrão | Efeito |
|---|---|---|
| **Grid Columns** | 3 | Menos colunas, células maiores |
| **Cell Shape** | Square | Formato da célula; a maioria dos GIFs é quadrada |
| **Scaling** | Fill | `Fill` ocupa a célula inteira e corta as bordas; `Contain` mostra o GIF todo, menor |

Se os GIFs parecerem pequenos, mexa nessa ordem: colunas → shape → scaling.

## Notas

- **Busca vazia mostra o trending**, para o grid abrir populado em vez de tela branca.
- **Renditions**: o GIPHY não garante os mesmos tamanhos para todo GIF, então `previewUrl`
  desce uma cadeia de fallback (`fixed_width_downsampled` → `fixed_width` → `preview_gif` →
  `downsized` → `original`) em vez de confiar numa chave só. Pelo mesmo motivo o parâmetro
  `bundle` não é usado: ele corta renditions da resposta.
- **Limites da API**: `q` no máximo 50 caracteres e `offset` no máximo 4999 — os dois são
  respeitados no `buildUrl`, então o scroll infinito para sozinho em vez de tomar erro.
- **`author` no `package.json`** está com um placeholder, igual à outra extensão. O `ray lint`
  acusa até você trocar pelo seu handle; não afeta `build` nem o uso local.
