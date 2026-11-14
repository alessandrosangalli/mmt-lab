# Calibração para o Brasil

**Status: levantamento parcial, de 14 de novembro de 2026.** Este arquivo reúne as estimativas publicadas que vão definir as faixas dos parâmetros do modelo do Brasil. Ele ainda não muda nenhum número do código: o modelo aberto continua com os parâmetros do livro.

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
| `mu2`, importações e renda doméstica | 1 | Lacuna | Santos e coautores, "Por que a elasticidade-preço das importações é baixa no Brasil?" | Não lida |
| `mu1`, importações e preço relativo | 0,7 | Lacuna. O título do estudo indica que é baixa | A mesma | Não lida |

A amostra de Schettini, Squeff e Gouvêa é trimestral, de 1995 a 2009. Os próprios autores avisam que as estatísticas t de uma das tabelas não são confiáveis, então a falta de significância do câmbio é uma indicação, não uma conclusão firme.

**Por que isso importa.** A diferença em `eps1` é a maior encontrada até aqui. No livro, uma moeda 10% mais fraca aumenta as exportações em 7%; pela estimativa brasileira, quase não aumenta. No modelo, é esse aumento das exportações que faz o câmbio flutuante corrigir a conta corrente. Se ele é fraco, a correção depende mais da queda das importações e da renda. Isso pesa diretamente na tese T5. É uma consequência a testar no modelo calibrado, não uma conclusão.

**O que o modelo faz com essa estimativa.** A premissa já pode ser trocada na tela. Com todos os outros parâmetros no valor do livro e um aumento do gasto público de 16 para 20:

| Resposta das exportações ao câmbio | Câmbio no período 40 | Conta corrente no período 40 | Desfecho em 120 períodos |
| --- | --- | --- | --- |
| 0,70, o valor do livro | 0,701 | −0,27 | A conta corrente volta a zero e a moeda se estabiliza em 0,64 |
| 0,01, a estimativa brasileira | 0,535 | −1,36 | A moeda continua caindo e o modelo deixa de ter solução no período 108 |

Isso mostra o que a premissa faz dentro deste modelo, com os demais parâmetros do livro. Não é um resultado sobre o Brasil: as importações, as carteiras e o tamanho relativo dos países ainda não foram calibrados, e qualquer um deles pode mudar o desfecho.

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
| `alpha2`, consumo e riqueza | Lacuna: nenhuma estimativa brasileira localizada | | |

O livro usa `alpha1` de 0,75. As estimativas brasileiras cobrem de 0,37 a 1,00 conforme o período e o método, então a faixa plausível é larga, e essa largura tem de aparecer no resultado.

## 4. Governo

| Medida | Valor | Fonte | Lida |
| --- | --- | --- | --- |
| Carga tributária bruta do governo geral, 2025 | 32,4% do PIB | Tesouro Nacional, citado pela imprensa | Secundária |
| Dívida Pública Federal, julho de 2026 | R$ 9,288 trilhões | Tesouro Nacional, citado pela Agência Brasil | Secundária |
| Parcela da dívida federal ligada ao câmbio | 3,65% | A mesma | Secundária |
| Parcela ligada à Selic | 51,11% | A mesma | Secundária |
| Parcela ligada a índices de preços | 26,02% | A mesma | Secundária |
| Parcela prefixada | 19,22% | A mesma | Secundária |
| Dívida interna em poder de não residentes | 9,82% | A mesma | Secundária |
| Dívida bruta do governo geral, setembro de 2026 | 82,9% do PIB | Banco Central | Título |
| Consumo do governo, em % do PIB | Lacuna | IBGE, Contas Nacionais | Não lida |

A alíquota `theta` do modelo incide sobre a renda e os juros recebidos, então a carga tributária em % do PIB é o alvo certo para ela. O livro usa 20%.

**Sobre a tese T2.** A parcela cambial de 3,65% é o tipo de dado que o critério de T2 vai testar. O protocolo já declarava que quem redigiu o critério sabia que essa parcela é pequena. Este número foi visto depois de o critério ser escrito, em fonte secundária, e não substitui a análise com a série do Tesouro.

## 5. Carteiras e mobilidade de capital

No modelo, oito parâmetros `lambda` dizem como as famílias de cada país dividem a riqueza entre dinheiro, títulos domésticos e títulos do outro país, e quanto essa divisão reage aos juros.

| Medida | Livro | Indicação para o Brasil | Fonte | Lida |
| --- | --- | --- | --- | --- |
| Parcela dos títulos domésticos em poder do exterior | cerca de 25% | 9,82% da dívida federal interna | Tesouro Nacional, citado pela Agência Brasil | Secundária |
| Parcela da riqueza das famílias em títulos estrangeiros | 25% | Lacuna. A posição internacional de investimento do Banco Central é a fonte a consultar | | Não lida |
| Reação da carteira a um ponto de juro | 5 pontos da riqueza | Lacuna: nenhuma estimativa direta localizada | | |
| Reação do câmbio ao diferencial de juros | não se aplica | Coeficiente de 1,90 na equação de paridade do modelo do BC, com intervalo de 0,77 a 3,22 | Banco Central (2024), boxe do Relatório de Inflação de junho | Texto |

**Esta é a maior lacuna.** A reação da carteira aos juros é o parâmetro que mais mexe nos resultados do modelo aberto: com o valor do livro, um ponto de juro valoriza a moeda em 30%. Não há estimativa direta para o Brasil neste levantamento. O coeficiente de paridade do Banco Central dá uma disciplina indireta: no modelo calibrado, a reação do câmbio ao diferencial de juros deveria ficar na faixa que o BC estima.

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

A leitura automática do boxe perdeu os símbolos matemáticos, então os sinais e a forma exata de cada equação não estão registrados aqui. Eles precisam ser copiados do documento original antes de o modelo rival ser escrito.

## 7. O que falta

| Lacuna | Onde procurar |
| --- | --- |
| Elasticidades das importações (`mu1`, `mu2`) | Santos e coautores, já localizado; estudos do IPEA com as contas trimestrais |
| Efeito da riqueza no consumo (`alpha2`) | Literatura brasileira de consumo; pode não existir estimativa |
| Composição e sensibilidade das carteiras (`lambda`) | Posição internacional de investimento e estatísticas de fluxos de capital do Banco Central; literatura de paridade de juros para o Brasil |
| Pesos das contas nacionais (consumo do governo, importações e exportações em % do PIB) | IBGE, Contas Nacionais Trimestrais |
| Margem e participação dos salários (`phi`) | IBGE, Contas Econômicas Integradas |
| Juros doméstico e externo e duração do período do modelo | Séries do Banco Central; decisão de usar trimestre ou ano |
| Números marcados como "Secundária" ou "Título" | Documentos originais do Tesouro Nacional e do Banco Central |
| Sinais e forma das equações do modelo do BC | Boxe de junho de 2024, no original |

## 8. Decisões que a calibração exige

1. **Período do modelo.** As estimativas brasileiras são trimestrais. O modelo do livro não diz se o período é um trimestre ou um ano. A escolha muda a leitura de juros e de velocidades de ajuste.
2. **O outro país.** No livro, os dois países são iguais. Para o Brasil, o resto do mundo é muito maior. Isso exige reescalar o segundo país ou torná-lo exógeno.
3. **Defasagens.** O livro não tem defasagem nas exportações; a estimativa brasileira indica ajuste em três trimestres.
4. **Estado estacionário.** O modelo calibrado precisa reproduzir as proporções brasileiras (carga tributária, peso dos importados, dívida sobre o PIB) no ponto de partida.

## Referências

- Banco Central do Brasil (2018). [Repasse cambial sob a ótica de um modelo semiestrutural](https://www.bcb.gov.br/conteudo/relatorioinflacao/EstudosEspeciais/Repasse_cambial_sob_a_otica_de_um_modelo_semiestrutural.pdf). Estudo Especial 26/2018.
- Banco Central do Brasil (2024). [Atualização dos modelos semiestruturais de pequeno porte](https://www.bcb.gov.br/content/ri/relatorioinflacao/202406/ri202406b12p.pdf). Boxe do Relatório de Inflação, junho de 2024, p. 97-107.
- Banco Central do Brasil (2026). [Repasse cambial: estimativas por projeções locais](https://www.bcb.gov.br/content/ri/relatorioinflacao/202603/rpm202603b8p.pdf). Boxe do Relatório de Política Monetária, março de 2026, p. 65-69.
- Lopes, L. S. (2017). [Testando teorias para o consumo agregado no Brasil](https://www.scielo.br/j/neco/a/jhrqCyvzyVBHLnMmCj6XVtb/?lang=pt). *Nova Economia*, 27(1), 209-240.
- Santos, C. H. M. e coautores. [Por que a elasticidade-preço das importações é baixa no Brasil?](https://www.eco.unicamp.br/images/arquivos/artigos/3517/05Santos.pdf) *Economia e Sociedade*. Localizado, não lido.
- Schettini, B. P., Squeff, G. C. e Gouvêa, R. R. (2012). [Estimativas da função exportações brasileiras agregadas com dados das Contas Nacionais Trimestrais, 1995-2009](https://revistas.usp.br/ecoa/article/view/46197). *Economia Aplicada*, 16(1), 167-196.
- Tesouro Nacional. Carga tributária bruta do governo geral de 2025, citada em [notícia de 8 de agosto de 2026](https://www.itatiaia.com.br/economia/carga-tributaria-bruta-governo-geral-avanca-32-4-pib-tesouro-nacional/).
- Tesouro Nacional. Relatório Mensal da Dívida de julho de 2026, citado em [notícia da Agência Brasil de 26 de agosto de 2026](https://www.acessa.com/economia/2026/08/338013-divida-publica-sobe-022-em-julho-e-supera-rs-92-trilhoes.html).
