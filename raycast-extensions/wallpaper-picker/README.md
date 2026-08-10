# Wallpaper Picker

Extensão local do Raycast: busca wallpapers no [wallhaven](https://wallhaven.cc), mostra as
miniaturas num grid com scroll infinito, e aplica o escolhido em todos os monitores
re-sincronizando a paleta do pywal.

Existe porque a sketchybar não tem campo de texto, grid nem scroll nos popups — o Raycast
tem os três de graça, e já está rodando.

## Instalação

```bash
cd raycast-extensions/wallpaper-picker && npm install && npm run dev
```

Depois é só `⌃C`. A extensão fica registrada no Raycast permanentemente; o dev server só é
necessário para hot reload enquanto se mexe no código.

## Como funciona

`src/search-wallpapers.tsx` monta um `<Grid>` alimentado por `useFetch`, cuja URL é uma
função da página — é isso que devolve o objeto `pagination` que dá o scroll infinito. Busca
vazia cai no toplist do mês, para o grid abrir populado.

Ao escolher um wallpaper, `src/lib/apply.ts` baixa o full res para a pasta configurada e
delega para `scripts/set_wallpaper.sh -y` do próprio repo, que aplica em todos os displays e
chama o `sync_colors.sh` — que por sua vez recarrega a sketchybar. A extensão não duplica
nada dessa lógica.

## Preferências

Configuráveis na UI do Raycast: caminho dos dotfiles, pasta de wallpapers, resolução mínima,
número de colunas e uma API key opcional do wallhaven (só necessária para conteúdo restrito
e limite maior que os 45 req/min padrão).

## Notas

- **`author` no `package.json`**: está com um placeholder. O `ray lint` valida esse campo
  contra a API do Raycast e vai acusar erro até você trocar pelo seu handle real. Não afeta
  `ray build` nem o uso local — só importa para publicar na store.
- **Permissão de Automação**: na primeira vez que a extensão aplicar um wallpaper, o macOS
  vai pedir autorização para o Raycast controlar o System Events. Se negar, o
  `set_wallpaper.sh` aborta sem mexer nas cores.
