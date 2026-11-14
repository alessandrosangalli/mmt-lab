# Protocolo: a MMT funciona no Brasil?

**Status: rascunho 0.2, ainda não pré-registrado.** Este texto só passa a valer como pré-registro quando receber a tag `protocol-v1` no git. Até lá, as formulações podem mudar livremente.

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
8. **Confirmatório separado de exploratório.** Só a análise descrita no critério pré-registrado gera veredito. Qualquer análise feita depois de ver os dados é publicada com o rótulo "exploratória" e não muda o veredito.
9. **Conhecimento prévio declarado.** Quando quem escreve o critério já conhece, mesmo que aproximadamente, o dado que vai testá-lo, isso é declarado na tese, junto com o resultado esperado. Nesses casos o pré-registro vale menos, e o texto diz isso.
10. **Posição prévia declarada.** Antes da tag `protocol-v1`, o mantenedor do projeto registra neste arquivo a sua opinião prévia sobre a MMT.

## 3. Padrão de evidência

As regras desta seção existem para que o resultado dependa o mínimo possível de escolhas de quem faz a análise.

### 3.1 Tipos de afirmação

Cada tese é classificada, porque cada tipo admite um tipo diferente de teste.

| Tipo | O que é | Como se testa |
| --- | --- | --- |
| Identidade | Verdadeira por definição contábil | Não se testa: audita-se se os dados fecham. Não informa nada sobre causa |
| Institucional | Depende de leis, contratos e composição de ativos | Com documentos e dados de composição |
| Causal | Afirma que uma coisa provoca outra | Exige estratégia de identificação; correlação não basta |
| Contrafactual | Afirma o efeito de uma política que não foi adotada | Só por modelo, com toda a incerteza do modelo declarada |

### 3.2 Hierarquia de fontes

Da mais forte para a mais fraca, para sustentar uma afirmação empírica:

1. Meta-análises e revisões sistemáticas revisadas por pares.
2. Estudos empíricos revisados por pares, com preferência para os que identificam causalidade.
3. Estudos técnicos e textos para discussão de bancos centrais, do IPEA e de universidades.
4. Livros dos autores de cada escola.
5. Artigos de opinião.

Livros e artigos de opinião servem para registrar o que cada lado afirma. Não contam como evidência de que a afirmação é verdadeira.

### 3.3 Premissas e parâmetros

- A faixa plausível de cada parâmetro vem de estimativas publicadas para o Brasil, com a fonte citada. Quando não houver estimativa brasileira, usa-se a faixa internacional e isso é declarado.
- Nenhum parâmetro é ajustado para produzir um resultado. A calibração usa apenas dados anteriores ao episódio que será previsto.
- O resultado é sempre apresentado para toda a faixa plausível, nunca para um único valor escolhido.

### 3.4 Limites de um modelo

- Um veredito de "lógica" vale dentro do modelo usado. Para reduzir a dependência de um único modelo, o marco M5 repete as teses causais em um modelo rival, de outra escola.
- Com poucos episódios históricos, um placar de previsão é evidência fraca. Ele é publicado com esse aviso.
- Teses contrafactuais, como a T7, nunca recebem veredito na dimensão "evidência".

## 4. Escala de veredito

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

## 5. O que conta como MMT

Para este protocolo, "MMT" é o conjunto de afirmações defendidas na obra de L. Randall Wray, Stephanie Kelton, William Mitchell, Warren Mosler, Pavlina Tcherneva, Scott Fullwiler e Éric Tymoigne. No debate brasileiro, André Lara Resende defende posições próximas em vários pontos, e é citado onde isso acontece, sem ser tratado como porta-voz da MMT.

Onde esses autores divergem entre si, a tese registra a divergência.

### Onde está a opinião dos economistas

Em março de 2019, o painel de economistas do IGM Forum, da Universidade de Chicago, avaliou duas frases: que países que se endividam na própria moeda não deveriam se preocupar com déficits, porque sempre podem criar moeda para financiar a dívida; e que esses países podem financiar quanto gasto real quiserem criando moeda. Dos 38 que responderam, nenhum concordou com qualquer das duas (Kent A. Clark Center, 2019).

Autores ligados à MMT responderam que as duas frases não representam a teoria, que aponta a inflação e os recursos reais como limite. As teses abaixo seguem a formulação dos próprios autores da MMT, e não a das frases do painel. O resultado do painel fica registrado como indicação de que as versões fortes, sem limite, não têm apoio entre economistas acadêmicos.

## 6. As sete teses

As teses vão da menos à mais contestada.

### T1. Saldos setoriais

**Tipo.** Identidade.

**Formulação.** Em qualquer período, o déficit do setor público é igual à soma do superávit do setor privado doméstico com o superávit do resto do mundo em relação ao país. Um superávit público exige, portanto, déficit de algum outro setor.

**Quem afirma.** Wray (2024); Mitchell, Wray e Watts (2019). A contabilidade vem de Godley e Lavoie (2007).

**Objeção.** Quase ninguém contesta a identidade. A crítica é que ela não diz nada sobre causalidade: não mostra que o déficit público causa a poupança privada, nem o contrário. Palley (2015) sustenta que a MMT reafirma a macroeconomia keynesiana estabelecida.

**O que refutaria.** Nada: uma identidade não pode ser refutada por dados. Dados que não fecham indicam erro de medida, não erro da tese.

**Critério (auditoria).**

- Dados: Contas Econômicas Integradas do IBGE, com a capacidade ou necessidade de financiamento de cada setor institucional e do resto do mundo, em base anual.
- Conta: a soma da capacidade ou necessidade de financiamento de todos os setores, incluído o resto do mundo, em % do PIB, para cada ano disponível.
- Resultado: a auditoria passa se o valor absoluto da soma for de até 0,1% do PIB em todos os anos. O site mostra a série dos três saldos (público, privado e externo).
- Conferência cruzada, sem aprovação ou reprovação: a necessidade de financiamento do governo nas contas do IBGE é comparada ao resultado nominal do setor público apurado pelo Banco Central. As duas fontes têm coberturas diferentes, então a diferença é reportada e explicada, não julgada.

**Veredito possível.** Só na dimensão "lógica". O texto do veredito deve dizer que a tese não informa nada sobre causa e que a leitura causal está em T4 e T5.

**Conhecimento prévio.** O resultado esperado é que a auditoria passe, porque as contas nacionais são construídas para fechar. A disponibilidade exata das tabelas do IBGE ainda precisa ser confirmada; se elas não existirem nesse formato, o critério será revisto antes da tag.

### T2. Solvência em moeda própria

**Tipo.** Institucional, com um núcleo lógico.

**Formulação.** Um governo que emite a própria moeda e deve nessa moeda não pode ser forçado a dar calote por falta de dinheiro. O calote em moeda própria é sempre uma escolha.

**Quem afirma.** Wray (2024); Kelton (2020). Para o Brasil, Lara Resende (2023) afirma que a dívida pública brasileira é interna e denominada em moeda nacional.

**Objeção.** Mankiw (2020) aceita que o governo sempre pode emitir para pagar, mas argumenta que as conclusões de política mais novas da MMT não decorrem dessa premissa. Evitar o calote com emissão pode custar inflação, e um governo pode preferir o calote. Reinhart e Rogoff (2011) reúnem a história dos calotes soberanos em dívida doméstica e da relação entre dívida doméstica e inflação: governos de fato escolhem não pagar. A tese também só cobre a parcela da dívida denominada em reais.

**O que refutaria.** O núcleo lógico ("não pode ser forçado") não é refutável por dados, e isso é declarado. O que os dados podem mostrar é o alcance: quanto da dívida brasileira está fora da tese por estar ligada a moeda estrangeira.

**Critério.**

- Dados: Relatório Mensal da Dívida do Tesouro Nacional (composição da Dívida Pública Federal por indexador e a dívida externa) e séries do Banco Central de reservas internacionais e de swaps cambiais.
- Métrica principal, E: a parcela da Dívida Pública Federal denominada em moeda estrangeira ou indexada ao câmbio, no fim de cada um dos últimos dez anos completos.
- Métrica complementar, só reportada: a posição cambial líquida do setor público (reservas menos dívida externa pública e menos a exposição em swaps).
- Resultado:
  - "Vale no alcance brasileiro" se E ficar abaixo de 10% em todos os dez anos.
  - "Vale sob condições" se E ficar entre 10% e 30% em algum ano; a condição é a parcela exposta.
  - "Não vale para o Brasil" se E passar de 30% em algum ano.
- Os cortes de 10% e 30% são convenções fixadas agora. Não decorrem de teoria.

**Veredito possível.** Nas dimensões "lógica" e "evidência". O texto deve dizer que a tese trata só de calote forçado e não afirma que emitir é sem custo: os custos em inflação e câmbio estão em T4 e T5, e o prêmio de risco em T3.

**Conhecimento prévio.** Quem redigiu este critério já sabe que a parcela cambial da dívida federal tem sido pequena nos últimos anos. O resultado esperado é E abaixo de 10%. Por isso, este item funciona mais como registro de análise do que como teste cego.

### T3. O juro é escolha de política

**Tipo.** Causal.

**Formulação.** A taxa básica é fixada pelo banco central, e as taxas dos títulos públicos em moeda própria seguem a expectativa do mercado sobre essa taxa. O mercado não impõe o custo da dívida a um emissor soberano.

**Quem afirma.** Fullwiler (Working Paper 53). Para o Brasil, Lara Resende (2023) afirma que o Banco Central controla integralmente a taxa básica e que as taxas longas seguem a expectativa sobre ela.

**Objeção.** Muinhos (2023) responde que os juros longos se movem antes da Selic, que o prêmio de risco é real e que os poupadores podem deixar de financiar a dívida se a taxa for fixada baixa demais. Palley (2015) argumenta que a recomendação de política de juros da MMT tenderia a gerar instabilidade.

**O que refutaria.** Um prêmio nos juros longos, acima da trajetória esperada da Selic, que varie de forma sistemática com o quadro fiscal.

**Problema de identificação.** As duas posições explicam o mesmo fato de formas diferentes. Se os juros longos sobem depois de uma notícia fiscal ruim, um lado lê "o mercado impôs um prêmio" e o outro lê "o mercado passou a esperar uma Selic mais alta". Um estudo de eventos simples não separa as duas leituras. A experiência que separaria, o banco central fixar a taxa longa e sustentá-la, não existe no Brasil.

**Desenho preliminar.**

- Dados: taxas de swap DI de prazos longos, expectativas da pesquisa Focus para a Selic nos mesmos horizontes, e indicadores do quadro fiscal.
- Conta: o prêmio é a taxa de mercado menos a média da Selic esperada no mesmo prazo. Testa-se se o prêmio varia com os indicadores fiscais depois de descontada a Selic esperada.
- Complemento: revisão dos estudos publicados sobre risco fiscal e prêmio a termo no Brasil, seguindo a hierarquia da seção 3.2.

**Critério.** Em aberto. As variáveis, o período, a especificação e os cortes serão fixados com a revisão de um econometrista antes da tag. Se o desenho não resolver o problema de identificação, o veredito pré-registrado será "não testável", com a revisão da literatura apresentada como contexto.

### T4. O limite do gasto é a inflação

**Tipo.** Causal.

**Formulação.** O limite do gasto público é a capacidade real da economia, não a disponibilidade de dinheiro. O gasto deficitário gera inflação de demanda quando a economia está perto do pleno uso de recursos; abaixo disso, eleva produção e emprego.

**Quem afirma.** Kelton (2020); Wray (2024).

**Objeção.** Palley (2015) argumenta que a MMT simplifica demais a tarefa de chegar ao pleno emprego sem inflação e ignora os dilemas da curva de Phillips: a inflação sobe antes do pleno emprego. Muinhos (2023) sustenta que, no Brasil, as expectativas de inflação dependem do câmbio e do hiato do produto, e cita 2011 a 2013 e 2020 a 2022 como períodos em que juros baixos alimentaram a inflação. A indexação e a inércia inflacionária brasileiras agravam a objeção.

**Estado da evidência.** A primeira metade da tese, de que o gasto eleva a produção quando há ociosidade, tem apoio em estimativas de multiplicadores fiscais. Para o Brasil, Santos, Martins e Sanches (2026) estimam os maiores efeitos sobre o PIB para investimento público e benefícios sociais. A segunda metade, sobre quando a inflação aparece, é a parte em disputa, e depende de expectativas e de câmbio.

**O que refutaria.** Aceleração da inflação provocada por gasto com a economia claramente abaixo da capacidade, em uma faixa ampla das premissas plausíveis.

**O que será testado.** No modelo do Brasil com inércia inflacionária, em que faixa de premissas um aumento de gasto eleva a produção sem acelerar a inflação. Os episódios de 2015 a 2016 e de 2020 a 2022 servem de confronto.

**Critério.** Pendente. Marco M4, antes da etapa A.

### T5. Câmbio flutuante dá espaço de política

**Tipo.** Causal.

**Formulação.** Com câmbio flutuante e dívida em moeda própria, o governo tem espaço para conduzir as políticas fiscal e monetária com foco no pleno emprego. O câmbio absorve os choques externos.

**Quem afirma.** Wray (2024). Deos e Gerioni (2022) defendem que governos que emitem a própria moeda e devem nela, como o brasileiro, podem definir sua política com autonomia, em grau que varia de país para país.

**Objeção.** Vernengo e Pérez Caldentey (2020) consideram a MMT incompleta quando aplicada a países em desenvolvimento. A literatura brasileira da hierarquia de moedas, como descrita por Deos e Gerioni (2022), sustenta que países periféricos não conseguem conduzir políticas monetária e fiscal com autonomia, porque suas moedas têm baixa liquidez internacional. Palley (2015) aponta os dilemas de uma economia aberta. Para o Brasil, o canal concreto é: o déficit desvaloriza o real, e o câmbio repassa aos preços.

**Estado da evidência.** O repasse do câmbio aos preços no Brasil não é um número fixo. Um estudo do Banco Central (2018) estima que ele é menor com a economia abaixo do potencial e com expectativas ancoradas, e maior em depreciações grandes e com expectativas desancoradas. Isso pesa para os dois lados: o espaço de política existe em algumas condições e encolhe em outras.

**O que refutaria.** Um repasse cambial e uma resposta do câmbio ao gasto grandes o bastante para que, na maior parte da faixa plausível, a expansão fiscal gere mais inflação do que produção.

**O que será testado.** No modelo de economia aberta, quanto o câmbio responde ao gasto e quanto do câmbio chega aos preços, com o repasse dependente do estado da economia.

**Critério.** Pendente. Marco M4, antes da etapa A.

### T6. Juro alto é arma fraca e cara contra a inflação

**Tipo.** Causal.

**Formulação.** Elevar os juros é um instrumento fraco e custoso contra a inflação. Juros altos aumentam a renda de juros que o governo paga ao setor privado e o custo da dívida, o que pode sustentar a demanda e piorar o quadro fiscal.

**Quem afirma.** Forstater e Mosler (2005). Para o Brasil, Lara Resende (2023) argumenta que a alta de juros eleva o serviço da dívida e piora o quadro fiscal que ela pretendia responder, de forma circular.

**Divergência interna.** Os autores da MMT variam na força dessa afirmação. A versão testada aqui é a moderada: o canal da renda de juros existe e reduz a eficácia dos juros. A versão forte, de que juros altos aumentam a inflação, é avaliada como caso extremo da mesma premissa.

**Objeção.** É a visão dominante nos bancos centrais que o juro reduz a demanda e a inflação; Mankiw (2020) representa a posição dos livros-texto. Muinhos (2023) cita episódios brasileiros em que juros mantidos baixos alimentaram a inflação.

**Estado da evidência.** A versão forte tem a evidência contra ela. Rusnák, Havranek e Horvath (2013) reuniram cerca de mil estimativas de 70 estudos e concluíram que a alta de preços depois de um aperto monetário, que alguns estudos encontram, decorre em grande parte de modelos mal especificados; corrigido isso, os preços caem depois do aperto. Esses estudos são internacionais. O argumento da MMT para o Brasil é que o peso dos juros pagos pelo governo é aqui muito maior do que nos países dessas amostras, e essa é a parte que continua em aberto.

**O que refutaria.** Versão moderada: um canal de renda de juros desprezível diante do freio sobre crédito e consumo em toda a faixa plausível. Versão forte: inflação em queda depois de altas de juros, que é o que a meta-análise acima indica.

**O que será testado.** No modelo do Brasil, o tamanho do canal da renda de juros contra o freio dos juros sobre crédito e consumo, com o peso real dos juros pagos na renda privada brasileira.

**Critério.** Pendente. Marco M4, antes da etapa A.

### T7. Emprego garantido

**Tipo.** Contrafactual.

**Formulação.** Um programa de emprego garantido, que oferece trabalho a um salário fixo a quem quiser, elimina o desemprego involuntário e funciona como âncora de preços, ao criar um estoque regulador de trabalho.

**Quem afirma.** Mitchell e Wray (Working Paper 39); Tcherneva (2020).

**Objeção.** Mejia e Albrecht (2022) concluem, em um modelo de consistência temporal, que o emprego garantido não ajuda a estabilizar preços quando se consideram os incentivos de quem decide a política. Palley (2015) aponta dificuldades de economia política. Há ainda as questões de custo e de execução.

**O que refutaria.** Por ser contrafactual, a tese não pode ser refutada com dados brasileiros. O modelo pode mostrar em que faixa de premissas o programa pressiona salários e preços.

**O que será testado.** Só por simulação: o efeito sobre desemprego, inflação e custo fiscal em % do PIB, em toda a faixa de premissas. Não haverá veredito na dimensão "evidência".

**Critério.** Pendente. Marco M6, antes da etapa A.

## 7. Referências

A coluna "Conferida" indica o que foi lido durante a redação. "Resumo" significa que só o resumo ou a página do artigo foi lida. Antes da tag `protocol-v1`, todas precisam ser lidas no texto completo, e cada citação precisa de página ou trecho.

| Referência | Conferida |
| --- | --- |
| Banco Central do Brasil (2018). [Repasse cambial sob a ótica de um modelo semiestrutural](https://www.bcb.gov.br/conteudo/relatorioinflacao/EstudosEspeciais/Repasse_cambial_sob_a_otica_de_um_modelo_semiestrutural.pdf). Estudo Especial 26/2018. | Sim |
| Deos, S. e Gerioni, E. (2022). [Macroeconomic policy under a managed floating exchange rate regime: a critical appraisal of the International Currency Hierarchy literature](https://www.eco.unicamp.br/images/arquivos/artigos/TD/TD428.pdf). Texto para Discussão 428, IE/Unicamp. | Sim |
| Forstater, M. e Mosler, W. (2005). [The Natural Rate of Interest Is Zero](https://ideas.repec.org/a/mes/jeciss/v39y2005i2p535-542.html). *Journal of Economic Issues*, 39(2), 535-542. | Só a existência |
| Fullwiler, S. [Interest Rates and Fiscal Sustainability](https://tools.bard.edu/wwwmedia/resources/files/1265/WP%2053%20-%20Interest%20Rates%20and%20Fiscal%20Sustainability%20-%20Fullwiler.pdf). Working Paper 53. | Só a existência |
| Godley, W. e Lavoie, M. (2007). *Monetary Economics*. Palgrave Macmillan. | Não |
| Kelton, S. (2020). *The Deficit Myth*. PublicAffairs. | Não |
| Kent A. Clark Center (2019). [Modern Monetary Theory](https://kentclarkcenter.org/surveys/modern-monetary-theory/). Pesquisa do IGM Forum, 13 mar. 2019. | Sim |
| Lara Resende, A. (2023). [O precipício fiscal e a realidade](https://bresserpereira.org.br/23.02-precipicio-fiscal-e-realidade.pdf). *Valor Econômico*, 7 fev. 2023. | Sim |
| Mankiw, N. G. (2020). [A Skeptic's Guide to Modern Monetary Theory](https://www.nber.org/papers/w26650). *AEA Papers and Proceedings*, 110, 141-144. | Resumo |
| Mejia, J. e Albrecht, B. C. (2022). [On price stability with a job guarantee](https://digitalcommons.kennesaw.edu/facpubs/6344). *Contemporary Economic Policy*. | Resumo |
| Mitchell, W. e Wray, L. R. [Full Employment Through Job Guarantee](https://tools.bard.edu/wwwmedia/resources/files/1251/WP%2039%20-%20Full%20Employment%20Through%20Job%20Guarantee%20-%20Mitchell%20_%20Wray.pdf). Working Paper 39. | Só a existência |
| Mitchell, W., Wray, L. R. e Watts, M. (2019). *Macroeconomics*. Red Globe Press. | Não |
| Muinhos, M. K. (2023). [As falácias da MMT e de Lara Resende](https://eesp.fgv.br/sites/default/files/uploads/centros/macrolab/as-falacias-da-mmt-e-de-lara-resende.pdf). Broadcast/Agência Estado, 16 fev. 2023. | Sim |
| Palley, T. (2015). [Money, Fiscal Policy, and Interest Rates: A Critique of Modern Monetary Theory](https://econpapers.repec.org/RePEc:taf:revpoe:v:27:y:2015:i:1:p:1-23). *Review of Political Economy*, 27(1), 1-23. | Resumo |
| Reinhart, C. M. e Rogoff, K. S. (2011). [The Forgotten History of Domestic Debt](https://www.nber.org/papers/w13946). *Economic Journal*, 121(552), 319-350. | Resumo |
| Rusnák, M., Havranek, T. e Horvath, R. (2013). [How to Solve the Price Puzzle? A Meta-Analysis](https://www.cnb.cz/en/economic-research/research-publications/cnb-working-paper-series/How-to-Solve-the-Price-Puzzle-A-Meta-Analysis-00001). *Journal of Money, Credit and Banking*, 45(1), 37-70. | Resumo |
| Santos, H. R. S., Martins, G. K. e Sanches, M. S. (2026). [Ajuste via receita ou via gasto? Cenários de ajuste fiscal considerando estimativas de efeitos multiplicadores](https://revistas.usp.br/ee/article/view/229421). *Estudos Econômicos*, 56(1). | Resumo |
| Tcherneva, P. (2020). *The Case for a Job Guarantee*. Polity. | Não |
| Vernengo, M. e Pérez Caldentey, E. (2020). [Modern Money Theory (MMT) in the Tropics: Functional Finance in Developing Countries](https://econpapers.repec.org/RePEc:mes:challe:v:63:y:2020:i:6:p:332-348). *Challenge*, 63(6), 332-348. | Resumo |
| Wray, L. R. (2024). [Modern Money Theory: A Primer on Macroeconomics for Sovereign Monetary Systems](https://www.palgrave.com/book/10.1007/978-3-031-47884-0). Palgrave Macmillan. | Só a existência |

Leituras obrigatórias antes da versão 1:

- Tymoigne, É. e Wray, L. R. (2015). [Modern Money Theory: A Reply to Palley](https://econpapers.repec.org/RePEc:taf:revpoe:v:27:y:2015:i:1:p:24-44). *Review of Political Economy*, 27(1), 24-44. É a resposta dos autores da MMT à principal crítica citada aqui.
- Estudos brasileiros sobre multiplicadores fiscais em recessão e em expansão, para T4.
- Estudos do Banco Central sobre risco fiscal e prêmio a termo, para T3.

## 8. Histórico

| Versão | Data | Mudança |
| --- | --- | --- |
| 0.1 | 14 nov. 2026 | Primeiro rascunho das sete teses, sem critérios |
| 0.2 | 14 nov. 2026 | Padrão de evidência (tipos de afirmação, hierarquia de fontes, regras de parâmetros). Regras 8 a 10. Tipo, estado da evidência e condição de refutação em cada tese. Critérios de T1 e T2. Desenho preliminar e problema de identificação de T3. Pesquisa do IGM Forum. Seis referências novas |
