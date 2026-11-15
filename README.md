# Laboratório MMT

Um laboratório no navegador para responder, de forma reproduzível, à pergunta **"a MMT funciona no Brasil?"**. É escrito em [Elm](https://elm-lang.org) e inspirado no [Minsky](https://sourceforge.net/projects/minsky/), de Steve Keen.

O projeto está no começo. A versão atual demonstra só a contabilidade básica, com o modelo SIM.

## Versão atual

O laboratório roda quatro modelos, escolhidos na tela. Três usam os parâmetros de Godley e Lavoie (*Monetary Economics*, 2007): mostram como a contabilidade funciona, e não descrevem a economia brasileira. O quarto é o primeiro passo da calibração para o Brasil.

**SIM (cap. 3).** Três setores (famílias, empresas e governo) e um único ativo: o dinheiro que o governo emite quando gasta.

```
Y  = C + G                       o PIB é tudo o que se gasta
T  = θ · Y                       impostos sobre a renda
YD = Y − T                       renda disponível
C  = α1 · YD + α2 · H(anterior)  consumo das famílias
ΔH = YD − C  =  G − T            o déficit vira dinheiro das famílias
```

**PC (cap. 4).** Acrescenta títulos públicos, um banco central e a taxa de juros. As famílias dividem a riqueza entre dinheiro e títulos, o banco central compra os títulos que sobram, e o juro é o que o banco central decidir. As equações estão em `src/Model/Pc.elm`. Os parâmetros de carteira vêm do livro e só fazem sentido com juros baixos, por isso o controle de juros para em 6%.

**OPEN (cap. 12, modelo OPENFLEX).** Dois países trocam mercadorias e compram títulos um do outro, com câmbio flutuante. Há preços de importação e de exportação, então a taxa de câmbio chega ao nível de preços doméstico. Você controla a política do país doméstico; o outro não muda. São 69 variáveis por período, resolvidas por passadas sucessivas (`Sfc.Solver`). Com políticas extremas o modelo deixa de ter solução, e a tela diz em que período isso acontece. O código do modelo é gerado a partir de uma lista de equações; veja `tools/openflex/`.

**BRASIL (o OPENFLEX com ponto de partida brasileiro).** As equações do livro, com três acréscimos: transferências do governo às famílias, investimento estrangeiro direto e crescimento. Cada período é um trimestre, e tudo é medido em relação à tendência, com o PIB real crescendo 2,3% ao ano e os preços 4,6%. A economia parte de uma trajetória de crescimento equilibrado com proporções brasileiras: consumo do governo de 19,1% do PIB, importações de 17,5%, exportações de 17,8%, dívida pública de 82% do PIB anual, 9,9% dela com o exterior, e juro de 3,5% por trimestre. Receita, juros, transferências, déficit do governo e déficit da conta corrente não são alvos e caem perto dos números oficiais. As premissas começam nos valores brasileiros já conferidos e estão ancoradas na partida: mudam a força das reações, não o ponto de partida. É uma calibração parcial; o `CALIBRATION.md` diz de onde vem cada número e o que falta. O ponto de partida é calculado por `tools/openflex/brazil.js`.

No modelo aberto, quatro **premissas** contestadas viram controles na tela: a resposta das exportações ao câmbio, a resposta das importações ao preço, o repasse do câmbio aos preços de importação e a reação das carteiras aos juros. Cada uma mostra o valor do livro e o que se sabe para o Brasil, e um botão aplica os valores brasileiros já conferidos: as duas estimativas de comércio; a reação das carteiras, calibrada para reproduzir a resposta do câmbio aos juros medida no Brasil, com o período lido como um trimestre; e o repasse do câmbio aos importados, calibrado para reproduzir o repasse aos preços ao consumidor. Elas valem por cenário, então dá para comparar a mesma política sob duas premissas.

O **mapa de premissas** roda o cenário para cada combinação de duas premissas, em uma grade de 11 por 11, e mostra em quais a economia se estabiliza, em quais ainda está se ajustando no último período e em quais o modelo deixa de ter solução. Tocar em um quadrado leva aquelas premissas para o cenário. Cada premissa com estimativas brasileiras lidas traz a faixa que elas cobrem. O mapa destaca os quadrados dentro da faixa nos dois eixos e conta como eles terminam: é a resposta que não depende de um único valor de cada premissa. Uma opção faz o mapa cobrir só essa faixa, em 11 passos.

O **multiverso** vai além de duas premissas: a cada publicação, o CI roda o modelo BRASIL com todas as combinações das quatro premissas dentro das faixas publicadas, para cinco mudanças de política, e publica o resultado em [`multiverse.html`](https://alessandrosangalli.github.io/mmt-lab/multiverse.html) e `multiverse.json`. O programa é `src/Batch.elm`, sem tela, rodado por `tools/multiverse/run.js`.

Na tela você monta um **cenário**: a política inicial (gasto público G, alíquota θ e, no modelo PC, a taxa de juros r), mudanças de política datadas e o número de períodos. Os gráficos mostram o PIB, a riqueza das famílias e os saldos setoriais em cada período, e no modelo aberto também a taxa de câmbio e o nível de preços; ao escolher um período, você vê a tabela de Godley e o balanço dele. Dá para comparar dois cenários: as curvas aparecem sobrepostas, e uma tabela mostra a diferença entre eles no período escolhido.

O modelo e o cenário ficam codificados em um link, que reproduz exatamente o mesmo experimento:

```
?v=pc-1&g=20&t=20&i=2.5&n=80&p=16&c=15:30:20:3.5
```

| Campo | Significado |
| --- | --- |
| `v` | Modelo e versão (`sim-1`, `pc-1`, `open-1`, `brazil-5`). Muda sempre que o mesmo cenário passaria a dar números diferentes |
| `g`, `t`, `i` | Gasto, alíquota e taxa de juros iniciais |
| `n` | Número de períodos |
| `p` | Período em foco |
| `c` | Mudanças de política, como `período:gasto:alíquota:juros`, separadas por vírgula |
| `x` | Premissas diferentes do padrão do modelo, como `nome:valor`, separadas por vírgula |
| `bg`, `bt`, `bi`, `bc`, `bx` | O mesmo para o cenário B, quando há comparação. O número de períodos é compartilhado |

Links antigos, sem o campo de juros, continuam abrindo.

## Documentos do projeto

- [`PROTOCOL.md`](PROTOCOL.md): as sete teses, as regras do pré-registro e o padrão de evidência.
- [`CALIBRATION.md`](CALIBRATION.md): as estimativas publicadas para o Brasil que vão definir os parâmetros, com o que já foi conferido e o que falta.

## Organização do código

O código é em inglês; a interface é em português.

| Módulo | O que faz |
| --- | --- |
| `Sfc.Matrix` | Matriz de transações. Cada fluxo sai de um setor e entra em outro, então as linhas somam zero por construção |
| `Policy` | O que o governo e o banco central decidem em um período |
| `Premise` | Uma premissa contestada de um modelo, com faixa, valor padrão e explicação |
| `Multiverse` | Roda o mesmo cenário sob muitas combinações de premissas e classifica o desfecho de cada uma |
| `Scenario` | Um experimento repetível: política inicial, mudanças datadas e horizonte |
| `Engine` | A interface que todo modelo implementa e o laço que roda um cenário por ela |
| `Model.Sim`, `Model.Pc` | Os modelos fechados, como funções puras |
| `Model.OpenFlex` | Economia aberta com câmbio flutuante (cap. 12): dois países, comércio, títulos dos dois lados e preços. Código gerado |
| `Model.Open` | O mesmo modelo como a tela o mostra: o país doméstico, com o outro país como resto do mundo |
| `Model.Brazil`, `Model.BrazilRest` | O mesmo modelo partindo de uma trajetória de crescimento com proporções brasileiras. O ponto de partida é código gerado |
| `Sfc.Solver` | Resolve um período cujas equações dependem umas das outras, e devolve erro quando não há solução |
| `Models` | O catálogo de modelos disponíveis na tela |
| `Link` | Leitura e escrita do modelo e dos cenários na URL |
| `Chart` | Gráfico de linhas responsivo |
| `Format` | Formatação de números |
| `Style` | Folha de estilo da página |
| `Main` | Estado da tela e desenho |

Para acrescentar um modelo, basta implementar `Engine.Model` e registrá-lo em `Models`. A tela não muda.

## Como rodar

Com o [Elm 0.19.1](https://guide.elm-lang.org/install/elm.html) instalado:

```sh
elm reactor
```

Depois abra `http://localhost:8000/src/Main.elm`.

Para gerar o site como o CI gera:

```sh
elm make src/Main.elm --optimize --output=dist/elm.js
cp public/index.html dist/index.html
```

Para rodar os testes:

```sh
npx elm-test
```

Os testes conferem, para políticas sorteadas, que as contas de todos os setores fecham em zero em todos os modelos, que o superávit privado espelha o saldo do governo, que cada modelo converge para o seu estado estacionário calculado em forma fechada, e que um modelo e seus cenários sobrevivem intactos à ida e volta por um link.

## Integração contínua

A cada push, o GitHub Actions roda os testes, confere a formatação com `elm-format` e compila o site. Na branch `main`, o site é publicado no GitHub Pages.

## Licença

[GPL v3](LICENSE).

## Referências

- Wynne Godley e Marc Lavoie, *Monetary Economics: An Integrated Approach to Credit, Money, Income, Production and Wealth*. Palgrave Macmillan, 2007.
- [Minsky](https://sourceforge.net/projects/minsky/), simulador de dinâmica de sistemas com tabelas de Godley.
