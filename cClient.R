'Preparação do ambiente para execução

Estou usando a Linguagem R neste experimento por questões de comodidade. O dieal é não ficar preso a uma ferramenta. Outras opções de clusterização, como o Cluto, podem ser vantajosas em situações com dados mais volumosos.

A versão da Linguagem R segue abaixo:
'       
  
version


'### Uma função para validar os pacotes necessário se estão instalados

As informações encontradas são armazenadas em cache (pela biblioteca) para a sessão R eo argumento de campos especificados e atualizadas somente se o diretório da biblioteca de nível superior tiver sido alterado, por exemplo, instalando ou removendo um pacote. Se as informações em cache ficarem confusas, ela pode ser atualizada executando installed.packages (noCache = TRUE). O objetivo aqui é manter a reprodutibilidade do experimento.

'
is.installed <- function(mypkg) is.element(mypkg, installed.packages()[,1]) 



'### Uma Função para calcular a idade dos cliente de acordo com sua data de nacimento

Esta função converte, em tempo de execução, a idade de cada cliente.
Esta função não é exatamente necessária, mas demonstra uma transformação do dados. Isso pode ocorrer em outros momentos e em outros dados dependendo da situação. Algo contruído para essa tarefa especificamente.

'
age_years <- function(earlier, later) {
        lt <- data.frame(earlier, later)
        age <- as.numeric(format(lt[,2],format="%Y")) - as.numeric(format(lt[,1],format="%Y"))
        
        dayOnLaterYear <- ifelse(format(lt[,1],format="%m-%d")!="02-29",
                                 as.Date(paste(format(lt[,2],format="%Y"),"-",format(lt[,1],format="%m-%d"),sep="")),
                                 ifelse(as.numeric(format(later,format="%Y")) %% 400 == 0 | as.numeric(format(later,format="%Y")) %% 100 != 0 & as.numeric(format(later,format="%Y")) %% 4 == 0,
                                        as.Date(paste(format(lt[,2],format="%Y"),"-",format(lt[,1],format="%m-%d"),sep="")),
                                        as.Date(paste(format(lt[,2],format="%Y"),"-","02-28",sep=""))))
        
        age[which(dayOnLaterYear > lt$later)] <- age[which(dayOnLaterYear > lt$later)] - 1
        
        age
}

'### Verificando se os pacotes necessários estão instalados
'
if(!is.installed("ggplot2"))
        install.packages("ggplot2", dep = TRUE)

if(!is.installed("cluster"))
        install.packages("cluster")

if(!is.installed("factoextra"))
        install.packages("factoextra")

if(!is.installed("nnet"))
        install.packages("nnet", dep = TRUE)

if(!is.installed("xlsx"))
        install.packages("xlsx")

if(!is.installed("lazyeval"))
        install.packages("lazyeval", dep = TRUE)

if(!is.installed("RCurl"))
        install.packages("RCurl", dep = TRUE)

if(!is.installed("fpc"))
        install.packages("fpc", dep = TRUE)

if(!is.installed("clValid"))
        install.packages("clValid", dep = TRUE)

if(!is.installed("ClustOfVar"))
        install.packages("ClustOfVar", dep = TRUE)

'### Carrega os pacotes necessários para a execução

As mensagens e avisos foram retiradas ou suprimidas para efeito de apresentação.
Os erros serão mostrados caso algum seja encontrado durante a carga da biblioteca.

'
library("ggplot2")
library("cluster")
library("factoextra")
library("nnet")
library("ClustOfVar")
library("lazyeval")
library("fpc")
require("xlsx")
require("RCurl")


'**Inicializa ambiente de pesquisa reprodutível**
        
        Não há problemas em alterar o valor abaixo, desde que isso não seja feito no mesmo experimento, o objetivo aqui, mais uma vez é a reprodutibilidade.

'
set.seed(1608)

'## Carga do Dataset

O arquivo está no formato MS Excel, a planilha de interesse é a "Dados".
A variável maxLoad é usada para limitar a carga, pois originalmente o volume de linhas não são recomendadas para efeitos de teste. Eu usei a variável com tamanho de 51, mas para a clusterização de todo dataset o conteúdo deve ser NULL.

'
maxLoad <- NULL
mydata <- read.xlsx("datasets/Dataset-CodeChallengeDataScientist.xlsx", 
                    sheetName  = "Dados",endRow = maxLoad)
head(mydata,3)
mydata <- data.frame(mydata,stringsAsFactors = TRUE)


'### Limpeza e arrumação dos dados

Remove dados não disponíveis (NA), caso existam, e executa a normalização das variáveis quantitativas.

'
mydata <- na.omit(mydata)

# scale é uma função genérica cujo método padrão centra e / ou escala as colunas de uma matriz numérica

mydata$DATA_NASCIMENTO <- age_years(as.Date(mydata$DATA_NASCIMENTO),as.Date(Sys.Date()))
mydata$GEO_REFERENCIA <- scale(mydata$GEO_REFERENCIA)
mydata$VALOR_01 <- scale(mydata$VALOR_01)
mydata$VALOR_02 <- scale(mydata$VALOR_02)
mydata$VALOR_03 <- scale(mydata$VALOR_03)
mydata$VALOR_04 <- scale(mydata$VALOR_04)

# Alterando os nomes das colunas para melhor visualização gráfica
names(mydata) <- c("ID","GEO","Age","Prof","Gen","EstCiv","V1","V2","V3","V4","Per")

# Após o processamento, logo abaixo são mostradas as mesmas três primeiras linhas normalizadas

head(mydata,3)

# Clusterizando
# Existem várias abordagens para a clusterização, como por exemplo, Métodos de Particionamento, Métodos Hierárquicos, Métodos Baseados em Densidade, Métodos Baseados em Grid, Métodos Baseados em Modelos (Model-based). Neste documento, descreverei três: **aglomeração hierárquica, particionamento e Model-based.** Embora não haja melhores soluções para o problema de determinar o número de aglomerados a extrair, ou melhor, quantos clusters, optamos pelas abordagens abaixo.
# Modelo hierárquico
# Conjunto hierárquico ascendente de um conjunto de variáveis. 

'As variáveis podem ser quantitativas, qualitativas ou uma distribuição de ambas. O critério de agregação é a diminuição da homogeneidade para o cluster que está sendo mesclado. A homogeneidade de um cluster é a soma da razão de correlação (para variáveis qualitativas) e da correlação quadrática (para variáveis quantitativas) entre as variáveis e o centro do cluster (centroide) que é o primeiro componente principal de PCA mix. 

PCA mix é definido para uma distribuição de variáveis qualitativas e quantitativas e inclui análises de componentes principais comuns (**PCA**) e análise de correspondência múltipla (**MCA**) como casos especiais. Os valores em falta são substituídos por médias para variáveis quantitativas e por zeros na matriz de indicadores para a variável qualitativa.

**Vamos separar o dataset em duas partes, qualitativa como "a" e quantitativa como "x"**
        Vamos também ignorar o ID do cliente para efietos de clusterização, poiis queremos nesse momento entender o dataset e como ele se comporta.

'
a <- mydata[,c(4:6,11)]
x <- mydata[,c(2,3,7:10)]
mydata <- mydata[,2:11]

### Número de cluster encontrados, ou aglomerações

tree <- hclustvar(x,a)
stab <- stability(tree, graph = FALSE, B = 10)


# **Número de Cluster sugeridos**
        
nrCluster <- which.is.max(stab$meanCR)
nrCluster

# Número de Cluster sugeridos em formato gráfico**
        

plot(stab)

### CLuster Dendrogram
# Um dendrograma (do grego dendro "árvore" e gramma "desenho") é um diagrama de árvore freqüentemente usado para ilustrar o arranjo dos clusters produzidos por agrupamento hierárquico. Dendrogramas são freqüentemente usados em biologia computacional para ilustrar o agrupamento de genes ou amostras, às vezes em cima de heatmaps. (Wikipédia).
#Em nosso caso os clusters são mostrados dentro dos blocos vermelhos. 

plot(tree)
rect.hclust(tree, k=nrCluster, border="red")


### Índice Rand ajustado


boxplot(stab$matCR, main="Dispersão do índice Rand ajustado")

## Particionamento
# K-means clustering é o método de particionamento mais popular. Exige que o analista especifique o número de clusters a serem extraídos. Um gráfico da soma de quadrados de grupos por número de aglomerados extraídos pode ajudar a determinar o número apropriado de clusters. O analista procura uma curva na trama semelhante a um teste de análise fatorial.
## K-Means Clustering with k clusters
### PCA - Principal Component Analisys
# Para a conveniência da visualização, tomamos os dois primeiros componentes principais como as novas variáveis de característica e realizamos k-means somente nestes dados bidimensionais.

pca <- princomp(x, cor=T)
pc.comp <- pca$scores
pc.comp1 <- -1*pc.comp[,1]
pc.comp2 <- -1*pc.comp[,2]
newComp <- cbind(pc.comp1, pc.comp2)
cl <- kmeans(newComp, nrCluster)
plot(pc.comp1, pc.comp2,col=cl$cluster,xlab = "Componente 1", ylab = "Componente 2",
     main = "KMeans & PCA")
points(cl$centers, pch=16)

# Tamanho dos clusters

cl$size

'
O algorítmo kmeans executa a análise de agrupamento e fornece os resultados de agrupamento e seus centroides, para ser exato, o vetor centróide (ou seja, a média) para cada cluster.
Observa-se aqui que um dos clusters está linearmente separável dos demais. Os outros estão coesos. Observa-se também que quanto maior o valor da primeira componente, mais esparço ficam os elementos do cluster, isso pode justificar essa separabilidade.
Sugerimos o uso de regressão linear, ou quadrática dependendo dos resultados da linear, para identificar relações entre as variáveis qualitativas, como por exemplo a idade ou perfil com as variáveis quantitativas (valor_01, valor_02 ...) que não são identificadas nominalmente.
'

fit <- kmeans(x, nrCluster) 
fit$size
clusplot(mydata, fit$cluster, color=TRUE, shade=TRUE, labels=4, lines=0,main = "Clusters e seus centroides",xlab = "Componente 1", ylab = "Componente 2")

## Model-based Clustering
# Na abordagem Model-based clustering, cada componente de uma densidade de distribuição finita é geralmente associado a um grupo ou cluster. A maioria das aplicações assume que todas as densidades de componentes surgem da mesma família de distribuição paramétrica, embora isto não necessite ser o caso em geral. Um modelo popular é o modelo de distribuição gaussiana (GMM), que assume uma distribuição gaussiana (multivariada).
### BIC
# As abordagens Model-based assumem uma variedade de modelos de dados e aplicam a estimativa de máxima verossimilhança e os critérios de Bayes para identificar o modelo e o número de clusters mais prováveis. Especificamente, seleciona o modelo ótimo de acordo com BIC para EM inicializado por agrupamento hierárquico para modelos de distribuição Gaussiana parametrizada. Uma escolha do modelo e o número de aglomerados com o maior BIC

library(mclust)
fit <- Mclust(mydata)

plot(fit, what = "BIC", ylim = range(fit$BIC[,-(1:2)], na.rm = TRUE),
     legendArgs = list(x = "bottomleft"))

'Na chamada de função Mclust() acima são fornecidos a matriz de dados, o número de mix de componentes e a parametrização de covariância, todos são selecionados usando o critério de informação bayesiano
(BIC - Bayesian Information Criterio). Um resumo mostrando os três modelos e um gráfico BIC para todos os modelo obtidos. No último gráfico, ajustamos o intervalo do eixo y para remover aqueles com valores BIC mais baixos. Há uma indicação clara do mix de três componentes com covariâncias com formas diferentes mas com o mesmo volume e orientação (EVE). 
'
### Classificação

plot(fit, what = "class", ylim = range(fit$classification[,-(1:2)], na.rm = TRUE))

### Densidade
# Na abordagem baseada em modelos de clustering, cada componente de uma densidade de distribuição finita é geralmente associada a um grupo ou cluster. A maioria das aplicações assume que todas as densidades de componentes surgem da mesma família de distribuição paramétrica, embora isto não necessite ser o caso em geral.

plot(fit, what = "density", ylim = range(fit$density[,-(1:2)], na.rm = TRUE))

## Redução de dimensionalidade
# Métodos eficientes de redução de dimensionalidade de dados representados em elevada dimensão são importantes, não apenas para viabilizar a visualização de dados em dimensões adequadas para a percepção humana, como também em sistemas automáticos de reconhecimento de padrões, como por exemplo, na eliminação de características redundantes.
### Clustering

fit <- MclustDR(fit)
summary((fit))

# No sentido horário, a partir do canto superior esquerdo: BIC, classificação, incerteza e densidade aplicada ao exemplo simulado univariável. No gráfico de classificação, todos os dados são exibidos na parte inferior, com as classes separadas mostradas em diferentes níveis acima.

plot(fit, what = "pairs")

# Onde a incerteza é mostrada usando uma escala de cinza com regiões mais escuras indicando maior incerteza. Ambos traçam os dados para as duas primeiras direções. O diagrama de contorno das densidades de mistura para cada cluster (esquerda) e limites de clusterização (à direita)  para o conjunto de dados.

plot(fit, what = "boundaries", ngrid = 200)


# Validando 
library(clValid)
clmethods <- c("hierarchical","kmeans","pam")
mx<-as.matrix(x)
intern <- clValid(mx, nClust = nrCluster, clMethods = clmethods, 
                  validation = "internal",maxitems = length(x$V1))
summary(intern)

plot(intern)
stab <- clValid(mx, nClust = nrCluster, clMethods = clmethods, 
                validation = "stability",maxitems = length(x$V1))
optimalScores(stab)
summary(stab)
plot(stab)

# Inferência Estatística
# Com o objetivo de verificar a relação entre variáveis, nesta seção vamos usar a regressão linear. É chamada "linear" porque se considera que a relação da resposta às variáveis é uma função linear de alguns parâmetros. Os modelos de regressão que não são uma função linear dos parâmetros se chamam modelos de regressão não-linear. Sendo uma das primeiras formas de análise regressiva a ser estudada rigorosamente, e usada extensamente em aplicações práticas. Isso acontece porque modelos que dependem de forma linear dos seus parâmetros desconhecidos, são mais fáceis de ajustar que os modelos não-lineares aos seus parâmetros, e porque as propriedades estatísticas dos estimadores resultantes são fáceis de determinar.
# Apenas um exemplo
# A exploração deve ser realizada por todas as variáveis, o que inclui as variáveis qualitativas, o quanto essas categorias influenciam, ou são influenciadas por outras variáveis.O que queremos agora é saber quais variáveis são dependentes e quais são independentes.
#
# **Idade**
        
# Vamos tentar estabelecer alguma relação entre a idade e os valores do dataset. Primeiro criamos um modelo com essas variáveis.

model <- lm(mydata$Age ~ mydata$V1 + mydata$V2 + mydata$V3 + mydata$V4)

# Observe os valores de p (p-value).


print(model$coefficients)

# Embora os valores de correlaçãos sejam baixos, o valor_02 parece ter uma melhor relação com a idade dos clientes, o mesmo não ocorre com os outros valores, apesar da probabilidade estar abaixo de 0.001.
# O gráfico**

maxV <- max(mydata$V1,mydata$V2,mydata$V3,mydata$V4)
maxAge <- max(mydata$Age)
plot(mydata$V1, mydata$Age, col = "blue", pch = 19, 
     ylim = c(0,maxAge),  xlim = c(0,maxV), xlab = "Valores", ylab = "Idade")
par(new=TRUE)
legend("bottomright", xpd=TRUE, ncol=2, legend=c("V1", "V2", "V3", "V4"),
       fill=c("blue", "red", "green", "orange"), bty="n", pch = c(19,24,22,19))
par(new=TRUE)
plot(mydata$V2, mydata$Age, col = "red",  pch = 24, 
     ylim = c(0,maxAge),  xlim = c(0,maxV), xlab = "Valores", ylab = "Idade")
par(new=TRUE)
plot(mydata$V3, mydata$Age, col = "darkgreen", pch = 22,  
     ylim = c(0,maxAge),  xlim = c(0,maxV), xlab = "Valores", ylab = "Idade")
par(new=TRUE)
plot(mydata$V4, mydata$Age, col = "orange",  pch = 19,
     ylim = c(0,maxAge),  xlim = c(0,maxV), xlab = "Valores", ylab = "Idade")
abline(model)

# Tempo total de execução deste programa
        
end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken


