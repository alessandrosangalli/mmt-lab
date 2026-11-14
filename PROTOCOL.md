# Protocolo: a MMT funciona no Brasil?

**Status: rascunho 0.1, ainda não pré-registrado.** Este texto só passa a valer como pré-registro quando receber a tag `protocol-v1` no git. Até lá, as formulações podem mudar livremente.

## 1. A pergunta

O Laboratório MMT existe para responder, de forma reproduzível, à pergunta: **a Teoria Monetária Moderna (MMT) funciona no Brasil?**

"Funciona" não é testável como está. Por isso a pergunta é quebrada em sete teses que a MMT afirma e que podem ser confrontadas com a economia brasileira. A resposta final é um veredito por tese, não um sim ou não.

Uma simulação não prova uma teoria: ela mostra as consequências das premissas que recebe. O que este projeto se propõe a mostrar é de quais premissas cada conclusão depende, de um jeito que defensores e críticos consigam conferir.

## 2. Regras

1. **Critério antes do dado.** Para cada tese, o critério de aprovação é escrito neste arquivo e marcado com uma tag no git antes de qualquer dado real entrar na análise daquela tese.
2. **Mudança deixa rastro.** Depois da tag, um critério só muda em uma nova versão do protocolo, com a justificativa registrada no histórico ao fim deste arquivo.
3. **Todo resultado é publicado.** Vereditos desfavoráveis à MMT, favoráveis à MMT e "não testável" têm o mesmo destaque.
4. **Só dados públicos.** Séries do Banco Central, do IBGE e do Tesouro Nacional, guardadas no repositório com data e hash.
5. **Todo número tem link.** Cada resultado aponta para o cenário, a versão do modelo e a versão dos dados que o geraram.
6. **Revisão pelos dois lados.** Antes da versão 1.0, cada teste é revisado por pelo menos um economista defensor e um crítico da MMT. Discordâncias que não se resolvem viram premissas ajustáveis, com o nome de cada posição.
7. **Formulação reconhecível.** Cada tese deve ser reconhecida como correta por quem a defende, e cada objeção por quem a faz.

## 3. Escala de veredito

Cada tese recebe um veredito em três dimensões.

| Dimensão | Pergunta |
| --- | --- |
| Lógica | A tese se sustenta em um modelo contábil coerente do Brasil? |
| Evidência | Os dados brasileiros são compatíveis com ela? |
| Sensibilidade | Em que parte das premissas plausíveis ela vale, e em que parte quebra? |

Os vereditos possíveis são quatro.

| Veredito | Significado |
| --- | --- |
| Vale | Passa no critério pré-registrado em toda a faixa plausível de premissas |
| Vale sob condições | Passa em parte da faixa; as condições são listadas |
| Não vale | Não passa no critério na faixa plausível de premissas |
| Não testável | O método deste projeto não permite decidir; o motivo é explicado |

## 4. O que conta como MMT

Para este protocolo, "MMT" é o conjunto de afirmações defendidas na obra de L. Randall Wray, Stephanie Kelton, William Mitchell, Warren Mosler, Pavlina Tcherneva, Scott Fullwiler e Éric Tymoigne. No debate brasileiro, André Lara Resende defende posições próximas em vários pontos, e é citado onde isso acontece, sem ser tratado como porta-voz da MMT.

Onde esses autores divergem entre si, a tese registra a divergência.

## 5. As sete teses

As teses vão da menos à mais contestada. Em cada uma, "critério" fica pendente até a etapa indicada no plano.

### T1. Saldos setoriais

**Formulação.** Em qualquer período, o déficit do setor público é igual à soma do superávit do setor privado doméstico com o superávit do resto do mundo em relação ao país. Um superávit público exige, portanto, déficit de algum outro setor.

**Quem afirma.** Wray (2024); Mitchell, Wray e Watts (2019). A contabilidade vem de Godley e Lavoie (2007).

**Objeção.** Quase ninguém contesta a identidade. A crítica é que ela não diz nada sobre causalidade: não mostra que o déficit público causa a poupança privada, nem o contrário. Palley (2015) sustenta que essa parte da MMT reafirma a macroeconomia keynesiana estabelecida.

**O que será testado.** Se a identidade fecha nos dados brasileiros e com qual discrepância estatística. A leitura causal fica fora desta tese e entra em T4 e T5.

**Critério.** Pendente. Marco M1, semana 4.

### T2. Solvência em moeda própria

**Formulação.** Um governo que emite a própria moeda e deve nessa moeda não pode ser forçado a dar calote por falta de dinheiro. O calote em moeda própria é sempre uma escolha.

**Quem afirma.** Wray (2024); Kelton (2020). Para o Brasil, Lara Resende (2023) afirma que a dívida pública brasileira é interna e denominada em moeda nacional.

**Objeção.** Mankiw (2020) aceita que o governo sempre pode emitir para pagar, mas argumenta que as conclusões de política mais novas da MMT não decorrem dessa premissa. Evitar o calote com emissão pode custar inflação, e um governo pode preferir o calote. A tese também só cobre a parcela da dívida de fato denominada em reais.

**O que será testado.** A composição da dívida pública brasileira por moeda e por indexador ao longo do tempo, e qual parcela fica fora do alcance da tese.

**Critério.** Pendente. Marco M1, semana 4.

### T3. O juro é escolha de política

**Formulação.** A taxa básica é fixada pelo banco central, e as taxas dos títulos públicos em moeda própria seguem a expectativa do mercado sobre essa taxa. O mercado não impõe o custo da dívida a um emissor soberano.

**Quem afirma.** Fullwiler (Working Paper 53). Para o Brasil, Lara Resende (2023) afirma que o Banco Central controla integralmente a taxa básica e que as taxas longas seguem a expectativa sobre ela.

**Objeção.** Muinhos (2023) responde que os juros longos se movem antes da Selic, que o prêmio de risco é real e que os poupadores podem deixar de financiar a dívida se a taxa for fixada baixa demais. Palley (2015) argumenta que a recomendação de política de juros da MMT tenderia a gerar instabilidade.

**O que será testado.** Como a curva de juros longa e o câmbio no Brasil reagem a mudanças da Selic e a mudanças do quadro fiscal.

**Critério.** Pendente. Marco M1, semana 4. Esta é uma questão econométrica difícil, e "não testável" é um resultado possível.

### T4. O limite do gasto é a inflação

**Formulação.** O limite do gasto público é a capacidade real da economia, não a disponibilidade de dinheiro. O gasto deficitário gera inflação de demanda quando a economia está perto do pleno uso de recursos; abaixo disso, eleva produção e emprego.

**Quem afirma.** Kelton (2020); Wray (2024).

**Objeção.** Palley (2015) argumenta que a MMT simplifica demais a tarefa de chegar ao pleno emprego sem inflação e ignora os dilemas da curva de Phillips: a inflação sobe antes do pleno emprego. Muinhos (2023) sustenta que, no Brasil, as expectativas de inflação dependem do câmbio e do hiato do produto, e cita 2011 a 2013 e 2020 a 2022 como períodos em que juros baixos alimentaram a inflação. A indexação e a inércia inflacionária brasileiras agravam a objeção.

**O que será testado.** No modelo do Brasil com inércia inflacionária, em que faixa de premissas um aumento de gasto eleva a produção sem acelerar a inflação. Os episódios de 2015 a 2016 e de 2020 a 2022 servem de confronto.

**Critério.** Pendente. Marco M4, antes da etapa A.

### T5. Câmbio flutuante dá espaço de política

**Formulação.** Com câmbio flutuante e dívida em moeda própria, o governo tem espaço para conduzir as políticas fiscal e monetária com foco no pleno emprego. O câmbio absorve os choques externos.

**Quem afirma.** Wray (2024). Deos e Gerioni (2022) defendem que governos que emitem a própria moeda e devem nela, como o brasileiro, podem definir sua política com autonomia, em grau que varia de país para país.

**Objeção.** Vernengo e Pérez Caldentey (2020) consideram a MMT incompleta quando aplicada a países em desenvolvimento. A literatura brasileira da hierarquia de moedas, como descrita por Deos e Gerioni (2022), sustenta que países periféricos não conseguem conduzir políticas monetária e fiscal com autonomia, porque suas moedas têm baixa liquidez internacional. Palley (2015) aponta os dilemas de uma economia aberta. Para o Brasil, o canal concreto é: o déficit desvaloriza o real, e o câmbio repassa aos preços.

**O que será testado.** No modelo de economia aberta, quanto o câmbio responde ao gasto e quanto do câmbio chega aos preços, com faixas de repasse cambial estimadas para o Brasil.

**Critério.** Pendente. Marco M4, antes da etapa A.

### T6. Juro alto é arma fraca e cara contra a inflação

**Formulação.** Elevar os juros é um instrumento fraco e custoso contra a inflação. Juros altos aumentam a renda de juros que o governo paga ao setor privado e o custo da dívida, o que pode sustentar a demanda e piorar o quadro fiscal.

**Quem afirma.** Forstater e Mosler (2005). Para o Brasil, Lara Resende (2023) argumenta que a alta de juros eleva o serviço da dívida e piora o quadro fiscal que ela pretendia responder, de forma circular.

**Divergência interna.** Os autores da MMT variam na força dessa afirmação. A versão testada aqui é a moderada: o canal da renda de juros existe e pode ser relevante. A versão forte, de que juros altos aumentam a inflação, será avaliada como caso extremo da mesma premissa.

**Objeção.** É a visão dominante nos bancos centrais que o juro reduz a demanda e a inflação; Mankiw (2020) representa a posição dos livros-texto. Muinhos (2023) cita episódios brasileiros em que juros mantidos baixos alimentaram a inflação.

**O que será testado.** No modelo do Brasil, o tamanho do canal da renda de juros contra o freio dos juros sobre crédito e consumo, com o peso real dos juros pagos na renda privada brasileira.

**Critério.** Pendente. Marco M4, antes da etapa A.

### T7. Emprego garantido

**Formulação.** Um programa de emprego garantido, que oferece trabalho a um salário fixo a quem quiser, elimina o desemprego involuntário e funciona como âncora de preços, ao criar um estoque regulador de trabalho.

**Quem afirma.** Mitchell e Wray (Working Paper 39); Tcherneva (2020).

**Objeção.** Mejia e Albrecht (2022) concluem, em um modelo de consistência temporal, que o emprego garantido não ajuda a estabilizar preços quando se consideram os incentivos de quem decide a política. Palley (2015) aponta dificuldades de economia política. Há ainda as questões de custo e de execução.

**O que será testado.** Só por simulação, porque não há experiência brasileira em escala: o efeito sobre desemprego, inflação e custo fiscal em % do PIB, em toda a faixa de premissas.

**Critério.** Pendente. Marco M6, antes da etapa A.

## 6. Referências

A coluna "Conferida" indica se a referência foi aberta e lida durante a redação deste rascunho. Antes da tag `protocol-v1`, todas precisam ser conferidas, com página ou trecho.

| Referência | Conferida |
| --- | --- |
| Deos, S. e Gerioni, E. (2022). [Macroeconomic policy under a managed floating exchange rate regime: a critical appraisal of the International Currency Hierarchy literature](https://www.eco.unicamp.br/images/arquivos/artigos/TD/TD428.pdf). Texto para Discussão 428, IE/Unicamp. | Sim, resumo |
| Forstater, M. e Mosler, W. (2005). The Natural Rate of Interest Is Zero. *Journal of Economic Issues*, 39(2). | Não |
| Fullwiler, S. [Interest Rates and Fiscal Sustainability](https://tools.bard.edu/wwwmedia/resources/files/1265/WP%2053%20-%20Interest%20Rates%20and%20Fiscal%20Sustainability%20-%20Fullwiler.pdf). Working Paper 53. | Só localizada |
| Godley, W. e Lavoie, M. (2007). *Monetary Economics*. Palgrave Macmillan. | Não |
| Kelton, S. (2020). *The Deficit Myth*. PublicAffairs. | Não |
| Lara Resende, A. (2023). [O precipício fiscal e a realidade](https://bresserpereira.org.br/23.02-precipicio-fiscal-e-realidade.pdf). *Valor Econômico*, 7 fev. 2023. | Sim |
| Mankiw, N. G. (2020). [A Skeptic's Guide to Modern Monetary Theory](https://www.nber.org/papers/w26650). *AEA Papers and Proceedings*, 110, 141-144. | Sim, resumo |
| Mejia, J. e Albrecht, B. C. (2022). [On price stability with a job guarantee](https://digitalcommons.kennesaw.edu/facpubs/6344). *Contemporary Economic Policy*. | Sim, resumo |
| Mitchell, W. e Wray, L. R. [Full Employment Through Job Guarantee](https://tools.bard.edu/wwwmedia/resources/files/1251/WP%2039%20-%20Full%20Employment%20Through%20Job%20Guarantee%20-%20Mitchell%20_%20Wray.pdf). Working Paper 39. | Só localizada |
| Mitchell, W., Wray, L. R. e Watts, M. (2019). *Macroeconomics*. Red Globe Press. | Não |
| Muinhos, M. K. (2023). [As falácias da MMT e de Lara Resende](https://eesp.fgv.br/sites/default/files/uploads/centros/macrolab/as-falacias-da-mmt-e-de-lara-resende.pdf). Broadcast/Agência Estado, 16 fev. 2023. | Sim |
| Palley, T. (2015). [Money, Fiscal Policy, and Interest Rates: A Critique of Modern Monetary Theory](https://econpapers.repec.org/RePEc:taf:revpoe:v:27:y:2015:i:1:p:1-23). *Review of Political Economy*, 27(1), 1-23. | Sim, resumo |
| Tcherneva, P. (2020). *The Case for a Job Guarantee*. Polity. | Não |
| Vernengo, M. e Pérez Caldentey, E. (2020). [Modern Money Theory (MMT) in the Tropics: Functional Finance in Developing Countries](https://econpapers.repec.org/RePEc:mes:challe:v:63:y:2020:i:6:p:332-348). *Challenge*, 63(6), 332-348. | Sim, resumo |
| Wray, L. R. (2024). [Modern Money Theory: A Primer on Macroeconomics for Sovereign Monetary Systems](https://www.palgrave.com/book/10.1007/978-3-031-47884-0). Palgrave Macmillan. | Só localizada |

A resposta dos autores da MMT a Palley também deve ser lida antes da versão 1: Tymoigne, É. e Wray, L. R. (2015). [Modern Money Theory: A Reply to Palley](https://econpapers.repec.org/RePEc:taf:revpoe:v:27:y:2015:i:1:p:24-44). *Review of Political Economy*, 27(1), 24-44.

## 7. Histórico

| Versão | Data | Mudança |
| --- | --- | --- |
| 0.1 | 14 nov. 2026 | Primeiro rascunho das sete teses, sem critérios |
