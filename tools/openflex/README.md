# Gerador do modelo OPENFLEX

O arquivo `src/Model/OpenFlex.elm` é gerado a partir de uma única lista de equações, `equations.txt`. A mesma lista produz um protótipo em JavaScript, que roda em segundos e serviu para conferir os números antes de o código Elm existir.

| Arquivo | O que faz |
| --- | --- |
| `equations.txt` | As equações, uma por linha, na ordem em que são resolvidas, com o número de cada uma no livro |
| `gen.js` | Lê a lista e a traduz para JavaScript e para Elm |
| `model.js` | O protótipo: resolve os períodos, acha o estado estacionário e confere a contabilidade |
| `emit.js` | Escreve o módulo Elm e imprime os números usados nos testes |
| `steady.json` | O estado estacionário da linha de base, calculado pelo protótipo |
| `explore-brazil.js` | Teste exploratório: leva os parâmetros aos poucos para proporções brasileiras e mostra onde o modelo repousa. Os resultados estão em `CALIBRATION.md`, seção 8 |
| `calibrate.js` | Calcula um ponto de repouso diretamente, como um sistema de equações, com parâmetros livres escolhidos para reproduzir proporções-alvo. Com `node tools/openflex/calibrate.js`, imprime o repouso do livro e o de proporções brasileiras |

Para refazer tudo, com o Node instalado:

```sh
node tools/openflex/model.js
node tools/openflex/emit.js src/Model/OpenFlex.elm
npx elm-format --yes src/Model/OpenFlex.elm
```

## De onde vêm as equações

Da replicação do capítulo 12 de Godley e Lavoie (2007) no pacote [`sfcr`](https://github.com/joaomacalos/sfcr), arquivo `vignettes/articles/gl9-open12.Rmd`. O livro não foi consultado diretamente.

## O que foi conferido

- O estado estacionário calculado bate com os valores iniciais publicados, com diferença relativa de até 0,007%, que é o arredondamento desses valores.
- A matriz de transações do país doméstico fecha em zero em todos os períodos dos cenários testados.
- O código Elm reproduz os números do protótipo com sete casas, inclusive o período em que um cenário deixa de ter solução.

Os cenários do livro só aparecem como gráficos na referência, então as trajetórias não foram comparadas número a número com uma fonte externa.
