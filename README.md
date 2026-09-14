# Reminder Countdown

Widget de barra para Omarchy que mostra uma contagem regressiva para o proximo
`omarchy reminder`.

Ele foi feito para resolver um uso simples: criar reminders rapidos e conseguir
ver, direto na top bar, quanto falta para o proximo lembrete tocar.

## O que ele faz

- Mostra o tempo restante ate o reminder mais proximo.
- Quando existem varios reminders, sempre acompanha o que vence primeiro.
- Depois que um reminder vence, passa automaticamente a contar o proximo.
- Mantem um sinalizador piscando (`!`) quando um reminder venceu.
- O sinalizador continua piscando ate voce clicar no widget.
- Toca o som de notificacao duas vezes em sequencia quando um reminder vence.
- Usa a API publica do Omarchy: `omarchy-reminder show --json`.
- Nao altera arquivos em `/usr/share/omarchy`.

Exemplos de exibicao:

```text
󰢌 0:58
󰢌 12:34
󰢌 ! 1:59
󰢌 !
```

Significado:

| Exibicao | Significado |
| --- | --- |
| `󰢌 0:58` | Existe um reminder ativo e faltam 58 segundos. |
| `󰢌 12:34` | Existe um reminder ativo e faltam 12 minutos e 34 segundos. |
| `󰢌 ! 1:59` | Um reminder venceu e ainda ha outro reminder contando. |
| `󰢌 !` | Um reminder venceu e nao ha outro timer ativo. |

## Como funciona

O plugin roda dentro do `omarchy-shell`, como um `bar-widget` normal do
Omarchy.

A cada segundo ele executa:

```bash
omarchy-reminder show --json
```

Esse comando retorna a lista de reminders ativos. O plugin escolhe o item com
menor `remainingSeconds` e mostra esse tempo na barra.

Para detectar que um reminder venceu, o plugin guarda um snapshot dos reminders
vistos anteriormente. Quando um reminder que estava no snapshot desaparece da
lista depois do horario esperado, o plugin ativa o estado `expiredPending`.

Esse estado e independente do countdown atual. Por isso, se voce tiver dois
reminders:

```bash
omarchy reminder 1 "Escovar os dentes"
omarchy reminder 3 "Tomar banho"
```

quando o primeiro vencer:

- a notificacao normal do Omarchy aparece;
- o plugin toca o som de notificacao duas vezes;
- o countdown passa para o reminder de 3 minutos;
- o sinalizador `!` fica piscando ate voce clicar no widget.

## Usabilidade

### Clique no widget

O comportamento depende do estado atual:

| Estado | Clique |
| --- | --- |
| Sinalizador piscando | Limpa apenas o sinalizador visual. |
| Reminder ativo, sem sinalizador | Mostra a lista de reminders via `omarchy-reminder show`. |
| Sem reminders ativos | Abre o fluxo interativo de criar reminder. |

Limpar o sinalizador nao cancela o proximo reminder. Ele apenas remove o aviso
visual de que um reminder anterior ja venceu.

### Hover

Ao passar o mouse por cima, o tooltip mostra:

- o nome do reminder atual;
- o tempo restante;
- o horario previsto;
- ou o reminder que venceu, quando o sinalizador esta ativo.

### Som

Quando um reminder vence, o plugin toca este som duas vezes em sequencia:

```bash
pw-play /usr/share/sounds/freedesktop/stereo/complete.oga
```

Esse som e disparado pelo plugin quando ele detecta que um reminder ativo
desapareceu da lista de `omarchy-reminder show --json` depois do horario
esperado. A notificacao visual continua sendo exibida pelo Omarchy.

Para testar o som manualmente:

```bash
pw-play /usr/share/sounds/freedesktop/stereo/complete.oga
```

## Configuracoes

As configuracoes ficam na entrada do widget em:

```text
~/.config/omarchy/shell.json
```

Exemplo:

```json
{
  "id": "mat-reminder-countdown",
  "showLabel": false,
  "hideWhenEmpty": true
}
```

### `showLabel`

Define se o texto do reminder aparece junto com o tempo.

```json
"showLabel": false
```

Com `false`, a barra fica compacta:

```text
󰢌 4:32
```

Com `true`, mostra uma versao curta do nome:

```text
󰢌 Cafe 4:32
```

Nomes longos sao encurtados para manter a barra organizada.

### `hideWhenEmpty`

Define se o widget some quando nao ha reminders ativos.

```json
"hideWhenEmpty": true
```

Com `true`, o widget aparece apenas quando ha countdown ou alerta pendente.

Com `false`, o widget fica sempre visivel. Quando nao ha reminders, clicar nele
abre o fluxo para criar um novo reminder.

## Posicionamento na barra

O widget pode ficar em `left`, `center` ou `right`.

Use o comando do Omarchy:

```bash
omarchy bar move mat-reminder-countdown --section left
```

ou:

```bash
omarchy bar move mat-reminder-countdown --section right
```

Tambem e possivel mover manualmente o bloco no `shell.json` para uma das
listas:

```json
"layout": {
  "left": [],
  "center": [],
  "right": []
}
```

## Instalacao

Este plugin deve ficar em:

```text
~/.config/omarchy/plugins/mat-reminder-countdown/
```

A estrutura esperada e:

```text
mat-reminder-countdown/
├── BarWidget.qml
├── manifest.json
└── README.md
```

Depois de copiar a pasta, valide o plugin:

```bash
omarchy plugin validate ~/.config/omarchy/plugins/mat-reminder-countdown
```

Habilite o plugin:

```bash
omarchy plugin enable mat-reminder-countdown
```

Se ele nao aparecer imediatamente, recarregue o shell:

```bash
omarchy restart shell
```

## Exemplo de uso

Criar um reminder simples:

```bash
omarchy reminder 5 "Tomar cafe"
```

Criar dois reminders:

```bash
omarchy reminder 1 "Escovar os dentes"
omarchy reminder 3 "Tomar banho"
```

Fluxo esperado:

1. O widget mostra o countdown para "Escovar os dentes".
2. Quando esse reminder vence, a notificacao do Omarchy aparece.
3. O plugin toca o som de notificacao duas vezes.
4. O widget passa a mostrar o countdown para "Tomar banho".
5. O sinalizador `!` fica piscando.
6. Ao clicar no widget, o `!` some e o countdown continua.

## Limitacoes

- O sinalizador pendente e um estado local do `omarchy-shell`.
- Se o shell for reiniciado, esse estado visual pendente e perdido.
- O plugin nao cancela, edita ou remove reminders.
- O plugin depende do comando `omarchy-reminder show --json`.
- O som depende de `pw-play` e do arquivo
  `/usr/share/sounds/freedesktop/stereo/complete.oga`.

## Arquivos importantes

| Arquivo | Funcao |
| --- | --- |
| `manifest.json` | Declara o plugin para o Omarchy Shell. |
| `BarWidget.qml` | Implementa o widget da barra, countdown e sinalizador. |
| `README.md` | Documentacao do plugin. |

## Comandos uteis

Listar reminders ativos:

```bash
omarchy reminder show
```

Listar reminders ativos em JSON:

```bash
omarchy reminder show --json
```

Limpar todos os reminders:

```bash
omarchy reminder clear
```

Validar o plugin

```bash
omarchy plugin validate ~/.config/omarchy/plugins/mat-reminder-countdown
```
