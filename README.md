# Laboratório MMT

Um laboratório no navegador para responder, de forma reproduzível, à pergunta **"a MMT funciona no Brasil?"**. É escrito em [Elm](https://elm-lang.org) e inspirado no [Minsky](https://sourceforge.net/projects/minsky/), de Steve Keen.

O projeto está no começo. A versão atual demonstra só a contabilidade básica, com o modelo SIM.

## Versão atual: o modelo SIM

O modelo SIM vem de Godley e Lavoie (*Monetary Economics*, 2007, cap. 3). São três setores (famílias, empresas e governo) e um único ativo: o dinheiro que o governo emite quando gasta.

```
Y  = C + G                       o PIB é tudo o que se gasta
T  = θ · Y                       impostos sobre a renda
YD = Y − T                       renda disponível
C  = α1 · YD + α2 · H(anterior)  consumo das famílias
ΔH = YD − C  =  G − T            o déficit vira dinheiro das famílias
```

Na tela você monta um **cenário**: a política inicial (gasto público G e alíquota θ), mudanças de política datadas e o número de períodos. O gráfico mostra o PIB e o dinheiro guardado pelas famílias em cada período; ao escolher um período, você vê a tabela de Godley e o balanço dele.

O cenário inteiro fica codificado em um link, que reproduz exatamente o mesmo experimento:

```
?v=sim-1&g=20&t=20&n=80&p=16&c=15:30:20
```

| Campo | Significado |
| --- | --- |
| `v` | Versão do modelo. Muda sempre que o mesmo cenário passaria a dar números diferentes |
| `g`, `t` | Gasto e alíquota iniciais |
| `n` | Número de períodos |
| `p` | Período em foco |
| `c` | Mudanças de política, como `período:gasto:alíquota`, separadas por vírgula |

## Organização do código

O código é em inglês; a interface é em português.

| Módulo | O que faz |
| --- | --- |
| `Sfc.Matrix` | Matriz de transações. Cada fluxo sai de um setor e entra em outro, então as linhas somam zero por construção |
| `Model.Sim` | O modelo SIM como funções puras |
| `Scenario` | Um experimento repetível: política inicial, mudanças datadas e horizonte |
| `Link` | Leitura e escrita de um cenário na URL |
| `Format` | Formatação de números |
| `Style` | Folha de estilo da página |
| `Main` | Estado da tela e desenho |

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

Os testes conferem os números do primeiro período, que as contas de todos os setores fecham em zero para qualquer política, e que o PIB converge para G ÷ θ. Conferem também que um cenário sobrevive intacto à ida e volta por um link, e que um link malformado nunca quebra a página.

## Integração contínua

A cada push, o GitHub Actions roda os testes, confere a formatação com `elm-format` e compila o site. Na branch `main`, o site é publicado no GitHub Pages.

## Licença

[GPL v3](LICENSE).

## Referências

- Wynne Godley e Marc Lavoie, *Monetary Economics: An Integrated Approach to Credit, Money, Income, Production and Wealth*. Palgrave Macmillan, 2007.
- [Minsky](https://sourceforge.net/projects/minsky/), simulador de dinâmica de sistemas com tabelas de Godley.
