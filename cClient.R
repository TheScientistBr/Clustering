'Prepara��o do ambiente para execu��o

Estou usando a Linguagem R neste experimento por quest�es de comodidade. O dieal � n�o ficar preso a uma ferramenta. Outras op��es de clusteriza��o, como o Cluto, podem ser vantajosas em situa��es com dados mais volumosos.

A vers�o da Linguagem R segue abaixo:
'       
  
version


'### Uma fun��o para validar os pacotes necess�rio se est�o instalados

As informa��es encontradas s�o armazenadas em cache (pela biblioteca) para a sess�o R eo argumento de campos especificados e atualizadas somente se o diret�rio da biblioteca de n�vel superior tiver sido alterado, por exemplo, instalando ou removendo um pacote. Se as informa��es em cache ficarem confusas, ela pode ser atualizada executando installed.packages (noCache = TRUE). O objetivo aqui � manter a reprodutibilidade do experimento.

'
is.installed <- function(mypkg) is.element(mypkg, installed.packages()[,1]) 



'### Uma Fun��o para calcular a idade dos cliente de acordo com sua data de nacimento

Esta fun��o converte, em tempo de execu��o, a idade de cada cliente.
Esta fun��o n�o � exatamente necess�ria, mas demonstra uma transforma��o do dados. Isso pode ocorrer em outros momentos e em outros dados dependendo da situa��o. Algo contru�do para essa tarefa especificamente.

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

'### Verificando se os pacotes necess�rios est�o instalados
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

'### Carrega os pacotes necess�rios para a execu��o

As mensagens e avisos foram retiradas ou suprimidas para efeito de apresenta��o.
Os erros ser�o mostrados caso algum seja encontrado durante a carga da biblioteca.

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


'**Inicializa ambiente de pesquisa reprodut�vel**
        
        N�o h� problemas em alterar o valor abaixo, desde que isso n�o seja feito no mesmo experimento, o objetivo aqui, mais uma vez � a reprodutibilidade.

'
set.seed(1608)

'## Carga do Dataset

O arquivo est� no formato MS Excel, a planilha de interesse � a "Dados".
A vari�vel maxLoad � usada para limitar a carga, pois originalmente o volume de linhas n�o s�o recomendadas para efeitos de teste. Eu usei a vari�vel com tamanho de 51, mas para a clusteriza��o de todo dataset o conte�do deve ser NULL.

'
maxLoad <- NULL
mydata <- read.xlsx("datasets/Dataset-CodeChallengeDataScientist.xlsx", 
                    sheetName  = "Dados",endRow = maxLoad)
head(mydata,3)
mydata <- data.frame(mydata,stringsAsFactors = TRUE)


'### Limpeza e arruma��o dos dados

Remove dados n�o dispon�veis (NA), caso existam, e executa a normaliza��o das vari�veis quantitativas.

'
mydata <- na.omit(mydata)

# scale � uma fun��o gen�rica cujo m�todo padr�o centra e / ou escala as colunas de uma matriz num�rica

mydata$DATA_NASCIMENTO <- age_years(as.Date(mydata$DATA_NASCIMENTO),as.Date(Sys.Date()))
mydata$GEO_REFERENCIA <- scale(mydata$GEO_REFERENCIA)
mydata$VALOR_01 <- scale(mydata$VALOR_01)
mydata$VALOR_02 <- scale(mydata$VALOR_02)
mydata$VALOR_03 <- scale(mydata$VALOR_03)
mydata$VALOR_04 <- scale(mydata$VALOR_04)

# Alterando os nomes das colunas para melhor visualiza��o gr�fica
names(mydata) <- c("ID","GEO","Age","Prof","Gen","EstCiv","V1","V2","V3","V4","Per")

# Ap�s o processamento, logo abaixo s�o mostradas as mesmas tr�s primeiras linhas normalizadas

head(mydata,3)

# Clusterizando
# Existem v�rias abordagens para a clusteriza��o, como por exemplo, M�todos de Particionamento, M�todos Hier�rquicos, M�todos Baseados em Densidade, M�todos Baseados em Grid, M�todos Baseados em Modelos (Model-based). Neste documento, descreverei tr�s: **aglomera��o hier�rquica, particionamento e Model-based.** Embora n�o haja melhores solu��es para o problema de determinar o n�mero de aglomerados a extrair, ou melhor, quantos clusters, optamos pelas abordagens abaixo.
# Modelo hier�rquico
# Conjunto hier�rquico ascendente de um conjunto de vari�veis. 

'As vari�veis podem ser quantitativas, qualitativas ou uma distribui��o de ambas. O crit�rio de agrega��o � a diminui��o da homogeneidade para o cluster que est� sendo mesclado. A homogeneidade de um cluster � a soma da raz�o de correla��o (para vari�veis qualitativas) e da correla��o quadr�tica (para vari�veis quantitativas) entre as vari�veis e o centro do cluster (centroide) que � o primeiro componente principal de PCA mix. 

PCA mix � definido para uma distribui��o de vari�veis qualitativas e quantitativas e inclui an�lises de componentes principais comuns (**PCA**) e an�lise de correspond�ncia m�ltipla (**MCA**) como casos especiais. Os valores em falta s�o substitu�dos por m�dias para vari�veis quantitativas e por zeros na matriz de indicadores para a vari�vel qualitativa.

**Vamos separar o dataset em duas partes, qualitativa como "a" e quantitativa como "x"**
        Vamos tamb�m ignorar o ID do cliente para efietos de clusteriza��o, poiis queremos nesse momento entender o dataset e como ele se comporta.

'
a <- mydata[,c(4:6,11)]
x <- mydata[,c(2,3,7:10)]
mydata <- mydata[,2:11]

### N�mero de cluster encontrados, ou aglomera��es

tree <- hclustvar(x,a)
stab <- stability(tree, graph = FALSE, B = 10)


# **N�mero de Cluster sugeridos**
        
nrCluster <- which.is.max(stab$meanCR)
nrCluster

# N�mero de Cluster sugeridos em formato gr�fico**
        

plot(stab)

### CLuster Dendrogram
# Um dendrograma (do grego dendro "�rvore" e gramma "desenho") � um diagrama de �rvore freq�entemente usado para ilustrar o arranjo dos clusters produzidos por agrupamento hier�rquico. Dendrogramas s�o freq�entemente usados em biologia computacional para ilustrar o agrupamento de genes ou amostras, �s vezes em cima de heatmaps. (Wikip�dia).
#Em nosso caso os clusters s�o mostrados dentro dos blocos vermelhos. 

plot(tree)
rect.hclust(tree, k=nrCluster, border="red")


### �ndice Rand ajustado


boxplot(stab$matCR, main="Dispers�o do �ndice Rand ajustado")

## Particionamento
# K-means clustering � o m�todo de particionamento mais popular. Exige que o analista especifique o n�mero de clusters a serem extra�dos. Um gr�fico da soma de quadrados de grupos por n�mero de aglomerados extra�dos pode ajudar a determinar o n�mero apropriado de clusters. O analista procura uma curva na trama semelhante a um teste de an�lise fatorial.
## K-Means Clustering with k clusters
### PCA - Principal Component Analisys
# Para a conveni�ncia da visualiza��o, tomamos os dois primeiros componentes principais como as novas vari�veis de caracter�stica e realizamos k-means somente nestes dados bidimensionais.

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
O algor�tmo kmeans executa a an�lise de agrupamento e fornece os resultados de agrupamento e seus centroides, para ser exato, o vetor centr�ide (ou seja, a m�dia) para cada cluster.
Observa-se aqui que um dos clusters est� linearmente separ�vel dos demais. Os outros est�o coesos. Observa-se tamb�m que quanto maior o valor da primeira componente, mais espar�o ficam os elementos do cluster, isso pode justificar essa separabilidade.
Sugerimos o uso de regress�o linear, ou quadr�tica dependendo dos resultados da linear, para identificar rela��es entre as vari�veis qualitativas, como por exemplo a idade ou perfil com as vari�veis quantitativas (valor_01, valor_02 ...) que n�o s�o identificadas nominalmente.
'

fit <- kmeans(x, nrCluster) 
fit$size
clusplot(mydata, fit$cluster, color=TRUE, shade=TRUE, labels=4, lines=0,main = "Clusters e seus centroides",xlab = "Componente 1", ylab = "Componente 2")

## Model-based Clustering
# Na abordagem Model-based clustering, cada componente de uma densidade de distribui��o finita � geralmente associado a um grupo ou cluster. A maioria das aplica��es assume que todas as densidades de componentes surgem da mesma fam�lia de distribui��o param�trica, embora isto n�o necessite ser o caso em geral. Um modelo popular � o modelo de distribui��o gaussiana (GMM), que assume uma distribui��o gaussiana (multivariada).
### BIC
# As abordagens Model-based assumem uma variedade de modelos de dados e aplicam a estimativa de m�xima verossimilhan�a e os crit�rios de Bayes para identificar o modelo e o n�mero de clusters mais prov�veis. Especificamente, seleciona o modelo �timo de acordo com BIC para EM inicializado por agrupamento hier�rquico para modelos de distribui��o Gaussiana parametrizada. Uma escolha do modelo e o n�mero de aglomerados com o maior BIC

library(mclust)
fit <- Mclust(mydata)

plot(fit, what = "BIC", ylim = range(fit$BIC[,-(1:2)], na.rm = TRUE),
     legendArgs = list(x = "bottomleft"))

'Na chamada de fun��o Mclust() acima s�o fornecidos a matriz de dados, o n�mero de mix de componentes e a parametriza��o de covari�ncia, todos s�o selecionados usando o crit�rio de informa��o bayesiano
(BIC - Bayesian Information Criterio). Um resumo mostrando os tr�s modelos e um gr�fico BIC para todos os modelo obtidos. No �ltimo gr�fico, ajustamos o intervalo do eixo y para remover aqueles com valores BIC mais baixos. H� uma indica��o clara do mix de tr�s componentes com covari�ncias com formas diferentes mas com o mesmo volume e orienta��o (EVE). 
'
### Classifica��o

plot(fit, what = "class", ylim = range(fit$classification[,-(1:2)], na.rm = TRUE))

### Densidade
# Na abordagem baseada em modelos de clustering, cada componente de uma densidade de distribui��o finita � geralmente associada a um grupo ou cluster. A maioria das aplica��es assume que todas as densidades de componentes surgem da mesma fam�lia de distribui��o param�trica, embora isto n�o necessite ser o caso em geral.

plot(fit, what = "density", ylim = range(fit$density[,-(1:2)], na.rm = TRUE))

## Redu��o de dimensionalidade
# M�todos eficientes de redu��o de dimensionalidade de dados representados em elevada dimens�o s�o importantes, n�o apenas para viabilizar a visualiza��o de dados em dimens�es adequadas para a percep��o humana, como tamb�m em sistemas autom�ticos de reconhecimento de padr�es, como por exemplo, na elimina��o de caracter�sticas redundantes.
### Clustering

fit <- MclustDR(fit)
summary((fit))

# No sentido hor�rio, a partir do canto superior esquerdo: BIC, classifica��o, incerteza e densidade aplicada ao exemplo simulado univari�vel. No gr�fico de classifica��o, todos os dados s�o exibidos na parte inferior, com as classes separadas mostradas em diferentes n�veis acima.

plot(fit, what = "pairs")

# Onde a incerteza � mostrada usando uma escala de cinza com regi�es mais escuras indicando maior incerteza. Ambos tra�am os dados para as duas primeiras dire��es. O diagrama de contorno das densidades de mistura para cada cluster (esquerda) e limites de clusteriza��o (� direita)  para o conjunto de dados.

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

# Infer�ncia Estat�stica
# Com o objetivo de verificar a rela��o entre vari�veis, nesta se��o vamos usar a regress�o linear. � chamada "linear" porque se considera que a rela��o da resposta �s vari�veis � uma fun��o linear de alguns par�metros. Os modelos de regress�o que n�o s�o uma fun��o linear dos par�metros se chamam modelos de regress�o n�o-linear. Sendo uma das primeiras formas de an�lise regressiva a ser estudada rigorosamente, e usada extensamente em aplica��es pr�ticas. Isso acontece porque modelos que dependem de forma linear dos seus par�metros desconhecidos, s�o mais f�ceis de ajustar que os modelos n�o-lineares aos seus par�metros, e porque as propriedades estat�sticas dos estimadores resultantes s�o f�ceis de determinar.
# Apenas um exemplo
# A explora��o deve ser realizada por todas as vari�veis, o que inclui as vari�veis qualitativas, o quanto essas categorias influenciam, ou s�o influenciadas por outras vari�veis.O que queremos agora � saber quais vari�veis s�o dependentes e quais s�o independentes.
#
# **Idade**
        
# Vamos tentar estabelecer alguma rela��o entre a idade e os valores do dataset. Primeiro criamos um modelo com essas vari�veis.

model <- lm(mydata$Age ~ mydata$V1 + mydata$V2 + mydata$V3 + mydata$V4)

# Observe os valores de p (p-value).


print(model$coefficients)

# Embora os valores de correla��os sejam baixos, o valor_02 parece ter uma melhor rela��o com a idade dos clientes, o mesmo n�o ocorre com os outros valores, apesar da probabilidade estar abaixo de 0.001.
# O gr�fico**

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

# Tempo total de execu��o deste programa
        
end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken


