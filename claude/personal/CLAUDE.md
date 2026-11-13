# Preferências gerais

## Planos
- Quando eu pedir para montar um plano (de implementação, de análise, etc.), **não crie
  arquivo `.md` dentro da pasta do projeto**. Devolva o plano na própria conversa, como
  no modo de planejamento. Depois de executados, esses arquivos viram lixo no projeto.

## Notificações (notifyq)
- Existe o comando `notifyq` para me avisar com uma notificação do sistema:
  `notifyq add "Título" -s "Subtítulo" [--in 10m | --at 18:30]`. Só o título é obrigatório.
- Use **apenas** quando eu pedir explicitamente para avisar ("me avise quando terminar",
  "acompanhe o pipeline e me notifique") ou quando eu sair e você ficar esperando algo longo
  que eu pedi para acompanhar. Não notifique ao fim de cada resposta.
- Para acompanhar algo (pipeline, deploy, build), faça o polling ou use um monitor em
  background e rode `notifyq add` quando o resultado sair, seja sucesso ou falha. Coloque o
  resultado no título (ex.: "Pipeline falhou") e o nome do projeto ou job no subtítulo.
- Se precisar de uma decisão minha e eu estiver fora, notifique antes de ficar esperando.
