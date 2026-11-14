# Laboratório MMT

Um laboratório no navegador para responder, de forma reproduzível, à pergunta **"a MMT funciona no Brasil?"**. É escrito em [Elm](https://elm-lang.org) e inspirado no [Minsky](https://sourceforge.net/projects/minsky/), de Steve Keen.

O projeto está no começo. A versão atual demonstra só a contabilidade básica, com o modelo SIM.

## Versão atual

O laboratório roda três modelos de Godley e Lavoie (*Monetary Economics*, 2007), escolhidos na tela. Os parâmetros são os do livro: eles mostram como a contabilidade funciona, e não descrevem a economia brasileira.

**SIM (cap. 3).** Três setores (famílias, empresas e governo) e um único ativo: o dinheiro que o governo emite quando gasta.

```
Y  = C + G                       o PIB é tudo o que se gasta
T  = θ · Y                       impostos sobre a renda
YD = Y − T                       renda disponível
C  = α1 · YD + α2 · H(anterior)  consumo das famílias
ΔH = YD − C  =  G − T            o déficit vira dinheiro das famílias
```

**PC (cap. 4).** Acrescenta títulos públicos, um banco central e a taxa de juros. As famílias dividem a riqueza entre dinheiro e títulos, o banco central compra os títulos que sobram, e o juro é o que o banco central decidir. As equações estão em `src/Model/Pc.elm`. Os parâmetros de carteira vêm do livro e só fazem sentido com juros baixos, por isso o controle de juros para em 6%.

**OPEN (cap. 12, modelo OPENFLEX).** Dois países trocam mercadorias e compram títulos um do outro, com câmbio flutuante. Há preços de importação e de exportação, então a taxa de câmbio chega ao nível de preços doméstico. Você controla a política do país doméstico; o outro não muda. São 65 variáveis por período, resolvidas por passadas sucessivas (`Sfc.Solver`). Com políticas extremas o modelo deixa de ter solução, e a tela diz em que período isso acontece. O código do modelo é gerado a partir de uma lista de equações; veja `tools/openflex/`.

No modelo aberto, quatro **premissas** contestadas viram controles na tela: a resposta das exportações ao câmbio, a resposta das importações ao preço, o repasse do câmbio aos preços de importação e a reação das carteiras aos juros. Cada uma mostra o valor do livro e o que se sabe para o Brasil. Elas valem por cenário, então dá para comparar a mesma política sob duas premissas.

Na tela você monta um **cenário**: a política inicial (gasto público G, alíquota θ e, no modelo PC, a taxa de juros r), mudanças de política datadas e o número de períodos. Os gráficos mostram o PIB, a riqueza das famílias e os saldos setoriais em cada período, e no modelo aberto também a taxa de câmbio e o nível de preços; ao escolher um período, você vê a tabela de Godley e o balanço dele. Dá para comparar dois cenários: as curvas aparecem sobrepostas, e uma tabela mostra a diferença entre eles no período escolhido.

O modelo e o cenário ficam codificados em um link, que reproduz exatamente o mesmo experimento:

```
?v=pc-1&g=20&t=20&i=2.5&n=80&p=16&c=15:30:20:3.5
```

| Campo | Significado |
| --- | --- |
| `v` | Modelo e versão (`sim-1`, `pc-1`, `open-1`). Muda sempre que o mesmo cenário passaria a dar números diferentes |
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
| `Scenario` | Um experimento repetível: política inicial, mudanças datadas e horizonte |
| `Engine` | A interface que todo modelo implementa e o laço que roda um cenário por ela |
| `Model.Sim`, `Model.Pc` | Os modelos fechados, como funções puras |
| `Model.OpenFlex` | Economia aberta com câmbio flutuante (cap. 12): dois países, comércio, títulos dos dois lados e preços. Código gerado |
| `Model.Open` | O mesmo modelo como a tela o mostra: o país doméstico, com o outro país como resto do mundo |
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
