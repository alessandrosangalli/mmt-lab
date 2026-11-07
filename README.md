# Laboratório MMT

Um simulador no navegador para ver na prática a contabilidade por trás da Teoria Monetária Moderna (MMT). É escrito em [Elm](https://elm-lang.org) e inspirado no [Minsky](https://sourceforge.net/projects/minsky/), de Steve Keen.

## Versão 0: o modelo SIM

A versão 0 implementa o modelo SIM de Godley e Lavoie (*Monetary Economics*, 2007, cap. 3). São três setores (famílias, empresas e governo) e um único ativo: o dinheiro que o governo emite quando gasta.

```
Y  = C + G                       o PIB é tudo o que se gasta
T  = θ · Y                       impostos sobre a renda
YD = Y − T                       renda disponível
C  = α1 · YD + α2 · H(anterior)  consumo das famílias
ΔH = YD − C  =  G − T            o déficit vira dinheiro das famílias
```

Na tela você controla o gasto público (G) e a alíquota de imposto (θ), avança os períodos e acompanha:

- um gráfico do PIB e do dinheiro guardado pelas famílias;
- a **tabela de Godley** do período, em que toda linha e toda coluna somam zero;
- o balanço, em que a dívida do governo e o dinheiro das famílias aparecem como o mesmo número.

O modelo inteiro é a função pura `passo` em `src/Main.elm`.

## Como rodar

**Sem instalar nada:** abra [ellie-app.com/new](https://ellie-app.com/new), cole o conteúdo de `src/Main.elm` e clique em *Compile*.

**No computador**, com o [Elm 0.19.1](https://guide.elm-lang.org/install/elm.html) instalado:

```sh
elm reactor
```

Depois abra `http://localhost:8000/src/Main.elm`.

Para gerar uma página única:

```sh
elm make src/Main.elm --optimize --output=index.html
```

A cada push, o GitHub Actions compila o projeto e guarda o `index.html` gerado como artefato do workflow.

## Próximos passos

- Cenários prontos para comparar políticas lado a lado
- Inflação
- Emprego garantido (Job Guarantee)

## Referências

- Wynne Godley e Marc Lavoie, *Monetary Economics: An Integrated Approach to Credit, Money, Income, Production and Wealth*. Palgrave Macmillan, 2007.
- [Minsky](https://sourceforge.net/projects/minsky/), simulador de dinâmica de sistemas com tabelas de Godley.
