# Calibração para o Brasil

**Status: levantamento em andamento, de 14 de novembro de 2026.** Este arquivo reúne as estimativas publicadas que vão definir as faixas dos parâmetros do modelo do Brasil. O modelo aberto continua partindo dos parâmetros do livro; as duas estimativas de comércio já lidas no original e a reação das carteiras calibrada na seção 5 podem ser aplicadas na tela, pelo botão "Usar as estimativas brasileiras disponíveis".

O levantamento segue as regras do `PROTOCOL.md`: cada faixa vem de uma estimativa publicada, com a fonte, e valem como evidência estudos revisados por pares e estudos técnicos de bancos centrais e de institutos de pesquisa. Dados oficiais descrevem a economia, mas não são estimativas de comportamento.

## Como ler

A coluna "Lida" diz o quanto da fonte foi de fato lido neste levantamento.

| Marca | Significado |
| --- | --- |
| Texto | O documento original foi aberto e os números foram tirados dele |
| Resumo | Só o resumo ou a página do artigo foi lida |
| Secundária | O número vem de uma notícia que cita a fonte oficial, não da própria fonte |
| Título | O número apareceu só no título de um resultado de busca. Não serve como fonte |
| Não lida | A fonte foi localizada, mas não aberta |

Nenhum número marcado como "Secundária", "Título" ou "Não lida" pode entrar no modelo antes de ser conferido no documento original.

## 1. Comércio exterior

No modelo, as exportações reais respondem à renda do resto do mundo (`eps2`) e ao preço relativo (`eps1`), e as importações reais respondem à renda doméstica (`mu2`) e ao preço relativo (`mu1`).

| Parâmetro | Livro | Estimativa para o Brasil | Fonte | Lida |
| --- | --- | --- | --- | --- |
| `eps2`, exportações e renda mundial | 1 | 0,98 no modelo preferido; de 0,92 a 1,19 entre as especificações | Schettini, Squeff e Gouvêa (2012) | Texto |
| `eps1`, exportações e câmbio real | 0,7 | 0,01 no modelo preferido, não significativo; de −0,04 a 0,11 entre as especificações | Schettini, Squeff e Gouvêa (2012) | Texto |
| Velocidade de ajuste das exportações | sem defasagem | Desequilíbrios corrigidos em cerca de três trimestres | Schettini, Squeff e Gouvêa (2012) | Texto |
| `mu2`, importações e renda doméstica | 1 | de 1,43 a 1,55 no modelo escolhido pelos autores; de 2,22 a 3,89 nas estimativas de cointegração | Santos, Cieplinski, Pimentel e Bhering (2017) | Texto |
| `mu1`, importações e preço relativo | 0,7 | 0,55 no modelo escolhido pelos autores; de 0,37 a 0,55 entre as especificações | Santos, Cieplinski, Pimentel e Bhering (2017) | Texto |
| `mu1` em estudos anteriores | 0,7 | 0,17: uma depreciação real de 1% reduz o volume importado em 0,17% | Minella e Souza-Sobrinho (2009), citado em Santos e coautores | Citação indireta |

A amostra de Santos e coautores é trimestral, do primeiro trimestre de 1996 ao segundo de 2013. Os autores explicam a resposta baixa das importações pela composição: bens intermediários, combustíveis e alguns serviços somam quase dois terços das importações e têm pouco ou nenhum substituto nacional. Uma das tabelas traz coeficientes de preço positivos depois de 2002, que o texto não discute.

A amostra de Schettini, Squeff e Gouvêa é trimestral, de 1995 a 2009. Os próprios autores avisam que as estatísticas t de uma das tabelas não são confiáveis, então a falta de significância do câmbio é uma indicação, não uma conclusão firme.

**Por que isso importa.** No modelo, o câmbio flutuante corrige a conta corrente porque uma moeda mais fraca aumenta as exportações e reduz as importações. Os livros de economia internacional resumem isso na condição de Marshall-Lerner: a correção funciona quando as duas respostas ao preço, somadas, passam de 1. No livro de Godley e Lavoie a soma é 1,4. Pelas estimativas brasileiras lidas aqui, ela fica em torno de 0,56 (0,01 das exportações mais 0,55 das importações), e entre 0,33 e 0,66 nos extremos das faixas. Isso pesa diretamente na tese T5.

**O que o modelo faz com essas estimativas.** As duas premissas podem ser trocadas na tela. Com todos os outros parâmetros no valor do livro e um aumento pequeno do gasto público, de 16 para 17:

| Premissas de comércio | Câmbio no período 40 | Câmbio no período 120 | Conta corrente no período 120 |
| --- | --- | --- | --- |
| Do livro (0,70 e 0,70) | 0,909 | 0,885 | −0,003: fechou |
| Estimativas brasileiras (0,01 e 0,55) | 0,812 | 0,464 | −0,887: continua abrindo |

Com as estimativas brasileiras, a moeda perde mais da metade do valor em 120 períodos e a conta corrente não fecha. Com um aumento maior do gasto, para 18, o modelo deixa de ter solução no período 110; para 20, no período 69. Um corte de gasto faz o contrário: a moeda se valoriza sem parar.

O mapa de premissas da tela mostra o quadro completo: a economia se estabiliza quando as duas respostas somam bem mais que 1 e deixa de ter solução quando somam bem menos, com a fronteira perto de 1.

**O que isso não mostra.** Não é um resultado sobre o Brasil, por quatro razões. As carteiras, o consumo e o tamanho relativo dos países continuam com os valores do livro. As estimativas medem a resposta em poucos trimestres, e a resposta do comércio ao câmbio costuma crescer com o tempo. No modelo, a renda do resto do mundo não reage. E a faixa das estimativas é larga: estudos anteriores encontram respostas das importações ainda menores, e outros, maiores que 1.

## 2. Repasse do câmbio aos preços

No modelo, o câmbio chega aos preços de importação por `nu1m` e daí ao nível de preços doméstico, na proporção do peso dos importados.

| Medida | Estimativa para o Brasil | Fonte | Lida |
| --- | --- | --- | --- |
| IPCA, 12 meses | 0,10: uma depreciação de 10% eleva o IPCA em cerca de 1,0 ponto | Banco Central (2026), boxe do RPM de março | Texto |
| IPCA, 24 meses | 0,16: cerca de 1,6 ponto | A mesma | Texto |
| Modelos semiestruturais do BC, quatro trimestres | 0,10 no IPCA, 0,07 nos preços livres, 0,18 nos administrados | A mesma | Texto |
| Alimentação no domicílio | 0,26 em 12 meses, 0,33 em 24 | A mesma | Texto |
| Bens industriais | cerca de 0,12 em 12 meses | A mesma | Texto |
| Serviços | próximo de zero | A mesma | Texto |
| Dependência do estado da economia | Menor com a economia abaixo do potencial e com expectativas ancoradas; maior em depreciações grandes | Banco Central (2018), Estudo Especial 26 | Texto |

A amostra do boxe de 2026 vai de julho de 2006 a dezembro de 2025, e o próprio texto diz que os intervalos de confiança de 90% são amplos.

**Como usar.** O alvo de calibração não é `nu1m` sozinho: é a resposta do nível de preços doméstico do modelo a uma depreciação, que deve ficar entre 0,10 e 0,16 no horizonte de um a dois anos. Com os parâmetros do livro, o modelo fica abaixo disso: no cenário de gasto público 20, a moeda perde 36% do valor e o nível de preços sobe 1,2%, um repasse de cerca de 0,03. O modelo calibrado precisa de um repasse três a cinco vezes maior.

## 3. Consumo

No modelo, as famílias gastam uma fração `alpha1` da renda disponível esperada e uma fração `alpha2` da riqueza.

| Medida | Estimativa para o Brasil | Fonte | Lida |
| --- | --- | --- | --- |
| Parcela da renda nas mãos de quem consome a renda corrente | de 0,70 a 0,75 em dados trimestrais de 1991 a 2012; 0,94 em dados anuais de 1947 a 2012 | Lopes (2017) | Resumo e tabelas descritas no texto |
| A mesma medida em estudos anteriores | de 0,70 a 0,90 (Reis e coautores, 1998); cerca de 0,85 (Gomes, 2004) | Citados em Lopes (2017) | Citação indireta |
| Propensão a consumir de longo prazo | cerca de 0,9 | Lopes (2017) | Resumo e tabelas descritas no texto |
| Propensão a consumir de curto prazo | cerca de 1,00 de 1947 a 1987; cerca de 0,37 de 1988 a 2012 | Lopes (2017) | Resumo e tabelas descritas no texto |
| `alpha2`, consumo e riqueza | Sem estimativa do consumo total. Evidência parcial: a cada R$ 1 de riqueza liberada no saque do FGTS de 2017, o gasto no cartão de crédito sobe cerca de R$ 0,04 | Brunelli, Martins e Carvalho (2025) | Resumo |

O estudo do FGTS acompanha cerca de 164 mil trabalhadores formais endividados, de agosto de 2016 a maio de 2018, e só enxerga o que passa pelo registro de crédito do Banco Central. O número mede gasto no cartão, não consumo total, e os próprios resultados agregados não são estatisticamente significativos. Serve como indicação de que o efeito existe e é pequeno, não como valor para `alpha2`, que no livro é 0,13333.

O livro usa `alpha1` de 0,75. As estimativas brasileiras cobrem de 0,37 a 1,00 conforme o período e o método, então a faixa plausível é larga, e essa largura tem de aparecer no resultado.

## 4. Governo

| Medida | Valor | Fonte | Lida |
| --- | --- | --- | --- |
| Carga tributária bruta do governo geral, 2025 (preliminar) | 32,40% do PIB; 32,22% em 2024 | Tesouro Nacional, Boletim da Carga Tributária de 2025 | Texto |
| Carga por base, 2025 | Bens e serviços 13,78%; renda, lucros e ganhos de capital 9,16%; contribuições sociais 6,72%; propriedade 1,73% do PIB | A mesma | Texto |
| Consumo do governo, 2024 | 18,8% do PIB | IBGE, Contas Nacionais Trimestrais do 2º trimestre de 2025 | Texto |
| Dívida Pública Federal, setembro de 2026 | R$ 9,383 trilhões: R$ 9,037 trilhões de dívida interna e R$ 345,4 bilhões de externa | Ministério da Fazenda, nota de novembro de 2026 sobre o Relatório Mensal da Dívida | Texto |
| Parcela externa da dívida federal | 3,68% em setembro; 3,75% em agosto | A mesma nota; Tesouro Nacional, Relatório Mensal da Dívida de agosto de 2026, tabela 2.1 | Texto |
| Parcela ligada à Selic | 51,60% em setembro; 52,74% em agosto | As mesmas | Texto |
| Parcela ligada a índices de preços | 23,59% em setembro; 23,22% em agosto | As mesmas | Texto |
| Parcela prefixada | 21,14% em setembro; 20,31% em agosto | As mesmas | Texto |
| Dívida interna em poder de não residentes | 9,91% em agosto. A nota de setembro traz 9,58% sem dizer a base | Relatório Mensal da Dívida de agosto de 2026, seção 2.3.2 | Texto |
| Custo médio da dívida federal em 12 meses | 12,63% ao ano em setembro: 13,03% a interna e 2,49% a externa | Ministério da Fazenda, nota de novembro de 2026 | Texto |
| Prazo médio da dívida federal | 4,10 anos | A mesma | Texto |
| Dívida bruta do governo geral, junho de 2026 | 81,9% do PIB, ou R$ 10,8 trilhões | Banco Central, nota de estatísticas fiscais de 31 de julho de 2026 | Texto |
| Dívida líquida do setor público, junho de 2026 | 68,5% do PIB | A mesma | Texto |
| Juros nominais do setor público em 12 meses, até junho de 2026 | 8,80% do PIB, ou R$ 1.160,5 bilhões | A mesma | Texto |
| Déficit nominal do setor público em 12 meses, até junho de 2026 | 9,99% do PIB | A mesma | Texto |
| Déficit primário do setor público em 12 meses, até junho de 2026 | 1,19% do PIB | A mesma | Texto |
| Os mesmos números fiscais em setembro de 2026 | Dívida bruta de 82,9% do PIB; juros de 8,99%; déficit nominal de 9,51% | Banco Central, citado pela imprensa | Secundária |

Os números da dívida federal foram conferidos na nota oficial do Ministério da Fazenda e no relatório de agosto do Tesouro. O relatório de setembro, em PDF, não foi localizado. A nota fiscal do Banco Central de setembro não pôde ser aberta nesta sessão; a de junho foi lida e é a que vale até lá.

A alíquota `theta` do modelo incide sobre a renda e os juros recebidos, então a carga tributária em % do PIB é o alvo certo para ela. O livro usa 20%.

### Contas nacionais

| Medida, 2024 | % do PIB | Fonte | Lida |
| --- | --- | --- | --- |
| Consumo das famílias | 63,8 | IBGE, Contas Nacionais Trimestrais do 2º trimestre de 2025 | Texto |
| Consumo do governo | 18,8 | A mesma | Texto |
| Formação bruta de capital fixo | 17,0 | A mesma, calculado dos valores correntes | Texto |
| Exportações de bens e serviços | 18,0 | A mesma, calculado dos valores correntes | Texto |
| Importações de bens e serviços | 17,5 | A mesma, calculado dos valores correntes | Texto |

No estado estacionário do livro, as importações são cerca de 12% da renda e o consumo do governo, 16%. O modelo não tem investimento, que no Brasil é 17% do PIB.

### Contas externas

| Medida | Valor | Fonte | Lida |
| --- | --- | --- | --- |
| Conta corrente em 12 meses, até junho de 2026 | déficit de US$ 61,4 bilhões, ou 2,46% do PIB | Banco Central, nota para a imprensa de 28 de julho de 2026 | Texto |
| Reservas internacionais, fim de junho de 2026 | US$ 367,6 bilhões | A mesma | Texto |

**Sobre a tese T2.** A parcela externa de 3,68% é o tipo de dado que o critério de T2 vai testar. O protocolo já declarava que quem redigiu o critério sabia que essa parcela é pequena. Este número foi visto depois de o critério ser escrito e não substitui a análise com a série de dez anos do Tesouro.

## 5. Carteiras e mobilidade de capital

No modelo, oito parâmetros `lambda` dizem como as famílias de cada país dividem a riqueza entre dinheiro, títulos domésticos e títulos do outro país, e quanto essa divisão reage aos juros.

| Medida | Livro | Indicação para o Brasil | Fonte | Lida |
| --- | --- | --- | --- | --- |
| Parcela dos títulos domésticos em poder do exterior | cerca de 25% | 9,91% da dívida federal interna em agosto de 2026 | Tesouro Nacional, Relatório Mensal da Dívida de agosto de 2026 | Texto |
| Parcela da riqueza das famílias em títulos estrangeiros | 25% | Lacuna. A posição internacional de investimento do Banco Central é a fonte a consultar | | Não lida |
| Reação da carteira a um ponto de juro | 5 pontos da riqueza | Sem estimativa direta. Calibração indireta: 0,5, na faixa de 0,15 a 0,8 (ver abaixo) | Este levantamento | |
| Reação do câmbio ao diferencial de juros | não se aplica | Coeficiente de 1,90 na equação de paridade do modelo do BC, com intervalo de 0,77 a 3,22 | Banco Central (2024), boxe do Relatório de Inflação de junho | Texto |

### Quanto o câmbio responde aos juros no Brasil

| Medida | Estimativa | Fonte | Lida |
| --- | --- | --- | --- |
| Câmbio no dia da decisão do Copom, por ponto de surpresa na Selic | Valorização de 3,4%, significativa a 10%; de 2,5% a 4,2% entre as especificações | Vicente, Marins e Gaglianone (2021), tabelas 1 e 2 | Texto |
| A mesma medida, com juros de um dígito | Sem efeito significativo, com poucas observações | A mesma | Texto |
| Câmbio mensal e diferencial de juros, 2000 a 2014 | Coeficiente de −2,94, com intervalo de 95% de −5,18 a −0,70: juro maior, moeda mais forte, o contrário do que a paridade descoberta prevê | Cieplinski, Braga e Summa (2017), p. 413 | Texto |
| A mesma relação, por regime | Períodos calmos: cerca de −1,5, pouco significativo. Crises (2002, 2008, 2011): positivo, de 1,4 a 6,8 | A mesma, tabela 5 | Texto |
| Câmbio e choques de juros identificados em dados diários | Altas de juros valorizam a moeda; tamanho não lido | Gonçalves, Rodrigues e Genta (2025) | Resumo |
| Entrada de estrangeiros na bolsa, 1995 a 2005 | Responde ao retorno das ações, ao risco-país, ao câmbio e à Selic; sem coeficientes lidos, e os autores dizem que o modelo não serve para previsão | Franzen, Meurer, Gonçalves e Seabra (2009) | Resumo |

A amostra de Vicente, Marins e Gaglianone é diária, de janeiro de 2006 a agosto de 2020, com 116 reuniões do Copom, das quais só 29 tiveram surpresa diferente de zero. A estimativa se apoia em poucos eventos.

O estudo de Ebeke e Lu (2014), do FMI, foi aberto e descartado: trata a participação de estrangeiros como causa dos juros, não como resposta a eles, e não traz resultado para o Brasil.

### A calibração indireta

Nenhum estudo lido mede o parâmetro do modelo, que é quanto da riqueza troca de título. Os estudos medem a consequência: quanto o câmbio se move. Então o valor foi escolhido para o modelo reproduzir essa consequência. Com os demais parâmetros no valor do livro e o juro doméstico subindo de 3% para 4%:

| Reação das carteiras | Câmbio no 1º período | No 4º | No 20º | No 40º |
| --- | --- | --- | --- | --- |
| 0 | 0,0% | −2,6% | −12,0% | −18,0% |
| 0,5 | +2,7% | −0,5% | −11,9% | −19,0% |
| 1 | +5,4% | +1,7% | −11,8% | −20,0% |
| 5, o valor do livro | +30,1% | +20,5% | −11,2% | −27,8% |

A resposta imediata é quase proporcional ao parâmetro, cerca de 5,3% por unidade. A faixa medida no dia do Copom, de 2,5% a 4,2%, corresponde a valores entre 0,5 e 0,8. O limite inferior do coeficiente de paridade do Banco Central, 0,77, lido como percentual por ponto, corresponde a 0,15. O valor adotado é 0,5, com faixa de 0,15 a 0,8. O valor do livro, 5, está dez vezes acima do que os dados brasileiros sustentam.

**O que muda nos resultados.** Com 0,5, o modelo deixa de ser hipersensível aos juros: um juro de 5% passa a ter solução nos 120 períodos, onde com o valor do livro deixava de ter no período 30. Um juro de 6% ainda deixa de ter solução, no período 84. Os resultados do gasto público não mudam em nada, porque o gasto não mexe no diferencial de juros: a tabela da seção 1 vale igual.

**Um resultado do modelo a registrar.** Em todas as linhas, a alta de juros acaba desvalorizando a moeda, entre 18% e 28% no período 40, qualquer que seja a reação das carteiras. O juro maior aumenta os pagamentos ao exterior e a renda das famílias, e as duas coisas abrem a conta corrente. É uma propriedade do modelo com os parâmetros do livro, não um resultado sobre o Brasil, e pesa na tese T6.

**Limites desta calibração.** São quatro. A medida é do dia da decisão, e o período do modelo é um trimestre ou um ano. A medida é de uma surpresa, e o modelo não distingue surpresa de mudança esperada. Os oito parâmetros de carteira foram movidos juntos, com o mesmo valor para os dois países. E Cieplinski, Braga e Summa mostram que a relação muda de sinal nas crises, o que um parâmetro fixo não reproduz. A calibração foi feita com os resultados do modelo à vista, e isso tem de ser declarado quando o critério de T5 e T6 for pré-registrado.

## 6. Parâmetros do modelo rival (marco M5)

O boxe do Banco Central de junho de 2024 traz os coeficientes do modelo semiestrutural de pequeno porte. Eles são a base do modelo rival, que não é calibrado por nós: usa os valores publicados.

| Equação | Coeficiente | Moda | Intervalo de 90% |
| --- | --- | --- | --- |
| Demanda (IS) | Hiato defasado | 0,85 | 0,70 a 0,95 |
| Demanda (IS) | Hiato do juro real | 0,44 | 0,21 a 0,66 |
| Demanda (IS) | Resultado primário | 0,030 | 0,027 a 0,032 |
| Demanda (IS) | Hiato do produto mundial | 0,054 | 0 a 0,23 |
| Preços livres (Phillips) | Inércia dos preços livres | 0,24 | 0,02 a 0,38 |
| Preços livres (Phillips) | Inércia do IPCA | 0,38 | 0,13 a 0,69 |
| Preços livres (Phillips) | Inflação importada | 0,023 | 0,006 a 0,039 |
| Preços livres (Phillips) | Variação do câmbio | 0,011 | 0 a 0,025 |
| Preços livres (Phillips) | Hiato do produto | 0,120 | 0,072 a 0,198 |
| Regra de juros | Desvio das expectativas em relação à meta | 2,03 | 1,47 a 2,64 |
| Câmbio (paridade) | Diferencial de juros | 1,90 | 0,77 a 3,22 |
| Expectativas | Inércia | 0,75 | 0,68 a 0,82 |

O modelo é trimestral e foi estimado do quarto trimestre de 2003 ao quarto de 2023. Uma segunda leitura do boxe recuperou a estrutura de cada equação:

| Equação | O que explica | Com o quê |
| --- | --- | --- |
| Demanda (IS) | Hiato do produto | As próprias defasagens, o hiato do juro real esperado em 12 meses, o resultado primário ajustado pelo ciclo e o hiato do produto mundial |
| Preços livres (Phillips) | Inflação trimestral dos preços livres | Inércia, expectativas de quatro trimestres à frente, inflação importada das commodities em reais, variação do câmbio defasada em um trimestre, hiato do produto e clima |
| Regra de juros | Meta da Selic | As duas defasagens da própria Selic (1,48 e −0,58) e o desvio das expectativas em relação à meta. Não há termo de hiato |
| Câmbio (paridade) | Variação trimestral do câmbio | Diferencial entre o juro doméstico e o dos Estados Unidos, anualizados e ajustados pelo risco-país (CDS de cinco anos), e a depreciação de longo prazo dada pela diferença entre as metas de inflação |
| Expectativas | Expectativa de inflação quatro trimestres à frente | A própria defasagem (0,75), o termo consistente com o modelo (0,11) e a inflação passada (0,021) |

A leitura automática continua perdendo os símbolos matemáticos, então os sinais de cada termo e a posição exata das defasagens ainda precisam ser copiados do documento original antes de o modelo rival ser escrito.

## 7. O que falta

| Lacuna | Onde procurar |
| --- | --- |
| Efeito da riqueza no consumo (`alpha2`) | Só há evidência parcial, de gasto no cartão. Falta uma estimativa do consumo total |
| Composição das carteiras (`lambda`) | Posição internacional de investimento do Banco Central (a nota mensal só traz fluxos) |
| Resposta do câmbio aos juros em horizonte de trimestres | Os estudos lidos medem o dia da decisão ou o mês. Falta a resposta ao longo de um ano |
| Margem e participação dos salários (`phi`) | IBGE, Contas Econômicas Integradas |
| Juros doméstico e externo por trimestre | Séries do Banco Central |
| Números fiscais de setembro de 2026, ainda "Secundária" | Nota de estatísticas fiscais do Banco Central de outubro de 2026, no original |
| Resposta do comércio no longo prazo | Estudos que separem curto e longo prazo; as estimativas lidas são de poucos trimestres |
| Sinais e defasagens exatas das equações do modelo do BC | Boxe de junho de 2024, no original |

## 8. Decisões da calibração

### Decidido: o período do modelo é um trimestre

Três razões, todas tiradas das fontes lidas:

1. As estimativas brasileiras de comércio são trimestrais, e o modelo do Banco Central, que será o rival, também.
2. A Selic cabe no modelo. Uma taxa de 15% ao ano é cerca de 3,6% por trimestre, dentro da faixa em que o modelo tem solução. Com período anual, ela ficaria fora.
3. A dívida fica na escala certa. Uma dívida bruta de 82% do PIB anual é cerca de 3,3 vezes o PIB de um trimestre.

A consequência é que juros, velocidades de ajuste e a razão entre estoques e fluxos passam a ser lidos por trimestre.

### Primeiro teste: o modelo consegue repousar em proporções brasileiras

Teste exploratório no protótipo, com o período lido como trimestre. Os parâmetros foram levados aos poucos do livro para: carga tributária de 32,4%, juro doméstico de 3,6% e externo de 1% por trimestre, reação das carteiras de 0,5 e consumo de 5% da riqueza por trimestre. O modelo chegou a um ponto de repouso:

| Proporção | No repouso encontrado | Brasil |
| --- | --- | --- |
| Dívida pública sobre o PIB trimestral | 3,2 | cerca de 3,3 |
| Parcela da dívida em poder do exterior | 11% | 9,9% |
| Importações sobre o PIB | 11% | 17,5% |
| Consumo do governo sobre o PIB | 25% | 18,8% |
| Arrecadação sobre o PIB | 36% | 32,4% |

A dívida e a parcela do exterior ficam perto das brasileiras sem terem sido alvo direto, o que é um bom sinal. As outras três proporções ainda estão fora. O teste também mostra o limite do método: várias combinações de parâmetros perderam a solução no caminho, e com as respostas brasileiras de comércio nenhuma chegou ao repouso. Isso não prova que o repouso não existe. Prova que deixar o modelo correr não serve para achá-lo.

O valor de 5% para o consumo da riqueza não vem de estimativa. Ele sai da contabilidade: no repouso, a razão entre riqueza e renda disponível é fixada pelos dois parâmetros de consumo, e 5% é o valor que leva a dívida à escala brasileira. É calibração por razão entre estoque e fluxo, e precisa ser declarada assim.

### O que falta decidir e fazer

1. **Calcular o repouso diretamente.** Resolver o estado estacionário como um sistema de equações, com as proporções brasileiras como alvo, em vez de esperar o modelo convergir.
2. **O outro país.** No livro, os dois países são iguais. Para o Brasil, o resto do mundo é muito maior. Isso exige reescalar o segundo país ou torná-lo exógeno.
3. **Defasagens.** O livro não tem defasagem nas exportações; a estimativa brasileira indica ajuste em três trimestres.
4. **Crescimento.** O modelo do livro repousa com déficit zero. O Brasil tem déficit nominal perto de 10% do PIB, com a economia e os preços crescendo. Um repouso sem crescimento não reproduz isso.

## Referências

- Banco Central do Brasil (2018). [Repasse cambial sob a ótica de um modelo semiestrutural](https://www.bcb.gov.br/conteudo/relatorioinflacao/EstudosEspeciais/Repasse_cambial_sob_a_otica_de_um_modelo_semiestrutural.pdf). Estudo Especial 26/2018.
- Banco Central do Brasil (2024). [Atualização dos modelos semiestruturais de pequeno porte](https://www.bcb.gov.br/content/ri/relatorioinflacao/202406/ri202406b12p.pdf). Boxe do Relatório de Inflação, junho de 2024, p. 97-107.
- Banco Central do Brasil (2026). [Repasse cambial: estimativas por projeções locais](https://www.bcb.gov.br/content/ri/relatorioinflacao/202603/rpm202603b8p.pdf). Boxe do Relatório de Política Monetária, março de 2026, p. 65-69.
- Brunelli, A., Martins, B. e Carvalho, C. (2025). [Liquidity or Wealth? Consumption, Debt, and Financial Fragility After a Windfall](https://www.bcb.gov.br/content/publicacoes/WorkingPaperSeries/WP634.pdf). Banco Central do Brasil, Working Paper 634.
- Cieplinski, A., Braga, J. e Summa, R. (2017). [Uma avaliação acerca da falha empírica do teorema da paridade descoberta da taxa de juros entre o Real e o Dólar](https://www.eco.unicamp.br/images/arquivos/artigos/3546/05Cieplinski.pdf). *Economia e Sociedade*, 26(2), 401-426.
- Franzen, A., Meurer, R., Gonçalves, C. E. S. e Seabra, F. (2009). [Determinantes do fluxo de investimentos de portfólio para o mercado acionário brasileiro](https://revistas.usp.br/ee/pt_BR/article/view/35973). *Estudos Econômicos*, 39(2), 301-328.
- Gonçalves, C., Rodrigues, M. e Genta, F. (2025). [Monetary Policy and Inflation Expectations: High-Frequency Evidence from Brazil](https://www.imf.org/en/publications/wp/issues/2025/02/28/monetary-policy-and-inflation-expectations-high-frequency-evidence-from-brazil-562685). IMF Working Paper 2025/048.
- Lopes, L. S. (2017). [Testando teorias para o consumo agregado no Brasil](https://www.scielo.br/j/neco/a/jhrqCyvzyVBHLnMmCj6XVtb/?lang=pt). *Nova Economia*, 27(1), 209-240.
- Banco Central do Brasil (2026). [Estatísticas do setor externo, nota para a imprensa de 28 de julho de 2026](https://www.bcb.gov.br/content/estatisticas/hist_estatisticassetorexterno/202607_Texto_de_estatisticas_do_setor_externo.pdf).
- IBGE (2025). [Contas Nacionais Trimestrais, 2º trimestre de 2025](https://agenciadenoticias.ibge.gov.br/media/com_mediaibge/arquivos/568f71479261775bd98e8c2a84ae9f32.pdf).
- Santos, C. H. M., Cieplinski, A., Pimentel, D. M. e Bhering, G. (2017). [Por que a elasticidade-preço das importações é baixa no Brasil? Evidências a partir das desagregações das importações por categorias de uso](https://www.eco.unicamp.br/images/arquivos/artigos/3517/05Santos.pdf). *Economia e Sociedade*, 26(1), 141-164.
- Schettini, B. P., Squeff, G. C. e Gouvêa, R. R. (2012). [Estimativas da função exportações brasileiras agregadas com dados das Contas Nacionais Trimestrais, 1995-2009](https://revistas.usp.br/ecoa/article/view/46197). *Economia Aplicada*, 16(1), 167-196.
- Vicente, J. V. M., Marins, J. T. M. e Gaglianone, W. P. (2021). [Impacts of the Monetary Policy Committee Decisions on the Foreign Exchange Rate in Brazil](https://www.bcb.gov.br/pec/wps/ingl/wps552.pdf). Banco Central do Brasil, Working Paper 552. Publicado na *Brazilian Review of Finance*, 20(2), 2022.
- Tesouro Nacional. [Estimativa da Carga Tributária Bruta do Governo Geral, 2025](https://cdn.tesouro.gov.br/sistemas-internos/apex/producao/sistemas/thot/arquivos/publicacoes/54334_1699660/Boletim_CTB_2025.pdf).
- Ministério da Fazenda (2026). [Dívida Pública Federal totaliza R$ 9,383 trilhões em setembro](https://www.gov.br/fazenda/pt-br/assuntos/noticias/2026/novembro/divida-publica-federal-totaliza-r-9-383-trilhoes-em-setembro).
- Tesouro Nacional (2026). [Relatório Mensal da Dívida, agosto de 2026](https://cdn.tesouro.gov.br/sistemas-internos/apex/producao/sistemas/thot/arquivos/publicacoes/55919_1762808/Texto_RMD_Ago_26.pdf).
- Banco Central do Brasil (2026). [Estatísticas fiscais, nota para a imprensa de 31 de julho de 2026](https://www.bcb.gov.br/content/estatisticas/hist_estatisticasfiscais/202607_Texto_de_estatisticas_fiscais.pdf).
- Banco Central do Brasil. Estatísticas fiscais de setembro de 2026, citadas em [notícia de 29 de outubro de 2026](https://sbtnews.sbt.com.br/noticia/economia/bc-divida-publica-chega-a-82-9-do-pib-em-setembro).
