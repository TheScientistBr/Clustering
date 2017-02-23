# Customer Cluster Analysis

## Unsupervised Machine Learning

**Delermando Branquinho Filho**

22 de fevereiro de 2017

# Introdução

Todo dia milhares de pessoas se tornam nosso clientes e a variabilidade de suas características é impressionante. São pessoas com características parecidas ou pessoas totalmente diferente. 

Este trabalho consiste em:

1 ) Agrupar os usuários, encontrando grupos bem definidos com características comuns.

2 ) Justificar o algoritmo de clusterização utilizado.

3 ) Apresentar métricas de performance do algoritmo utilizado.

4 ) Expor métricas de performance para avaliar os clusters obtidos.

5) Explicar os resultados.

A análise de cluster ou clustering é a tarefa de agrupar um conjunto de objetos de tal forma que os objetos no mesmo grupo (chamados de cluster) sejam mais parecidos (em algum sentido ou outro) uns com os outros do que com aqueles em outros grupos (clusters). É uma tarefa importante na fase exploratória de dados, e uma técnica comum para análise de dados estatísticos, usada em muitos campos, incluindo aprendizagem de máquina, reconhecimento de padrões, análise de imagem, recuperação de informação, bioinformática, compressão de dados e computação gráfica.

Análise de cluster em si não é um algoritmo específico, mas é a tarefa geral a ser resolvida. Pode ser alcançado por vários algoritmos que diferem significativamente em sua noção do que constitui um cluster e como encontrá-los eficientemente. As noções populares de clusters incluem grupos com pequenas distâncias entre os membros do cluster, áreas densas do espaço de dados, intervalos ou distribuições estatísticas particulares. Clustering pode, portanto, ser formulado como um problema de otimização multi-objetivo. O algoritmo de agrupamento apropriado e as configurações de parâmetros (incluindo valores como a função de distância a ser usada, um limite de densidade ou o número de clusters esperados) dependem do conjunto de dados individuais e do uso pretendido dos resultados. A análise de cluster como tal não é uma tarefa automática, mas um processo iterativo de descoberta de conhecimento ou otimização multi-objetivo interativa que envolve julgamento e falha. Muitas vezes é necessário modificar o pré-processamento de dados e os parâmetros do modelo até que o resultado obtenha as propriedades desejadas.

Neste documento, descreverei três das várias abordagens: aglomeração hierárquica, particionamento e model based. Embora não haja melhores soluções para o problema de determinar o número de aglomerados a extrair, são dadas várias abordagens abaixo.

O relatório completo pode ser visualizado em [RPubs](http://rpubs.com/delermando/CCA)
Uma apresentação simplificada do relatório pode ser acessada em [RPubs](http://rpubs.com/delermando/CCAapp)



--

[The Scientist](http://www.thescientist.com.br)
