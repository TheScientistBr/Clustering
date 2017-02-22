# defining a function to check if package are installed
is.installed <- function(mypkg) is.element(mypkg, installed.packages()[,1]) 
set.seed(1608)
# To calculate age 
age_years <- function(earlier, later)
{
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

# Verify if the packages needed are intalled
if(!is.installed("cluster"))
        install.packages("cluster")

if(!is.installed("factoextra"))
        install.packages("factoextra")

if(!is.installed("xlsx"))
        install.packages("xlsx")

if(!is.installed("ggplot2"))
        install.packages("ggplot2", dep = TRUE)

if(!is.installed("lazyeval"))
        install.packages("lazyeval", dep = TRUE)

library("ggplot2")
library("cluster")
library("factoextra")
library("nnet")
library("ClustOfVar")
require("xlsx")

mydata <- read.xlsx("datasets/Dataset-CodeChallengeDataScientist.xlsx", 
                    sheetName  = "Dados",endRow = 200)
head(mydata,3)
mydata <- data.frame(mydata,stringsAsFactors = TRUE)

# mydataBKP <- mydata
# mydata <- mydataBKP

# Remove any missing value (i.e, NA values for not available)
mydata <- na.omit(mydata)

# Scale variables and change content
mydata$DATA_NASCIMENTO <- age_years(as.Date(mydata$DATA_NASCIMENTO),as.Date(Sys.Date()))
mydata$GEO_REFERENCIA <- scale(mydata$GEO_REFERENCIA)
mydata$VALOR_01 <- scale(mydata$VALOR_01)
mydata$VALOR_02 <- scale(mydata$VALOR_02)
mydata$VALOR_03 <- scale(mydata$VALOR_03)
mydata$VALOR_04 <- scale(mydata$VALOR_04)


# View the firt 3 rows
head(mydata, n = 3)

a <- mydata[,c(4:6,11)]
x <- mydata[,c(2,3,7:10)]
tree <- hclustvar(x,a)
plot(stab <- stability(tree),main="Stability of the partitions")

plot(tree)
nrCluster <- which.is.max(stab$meanCR)

rect.hclust(tree, k=nrCluster, border="red")



boxplot(stab$matCR, main="Dispersão do índice Rand ajustado")
groups <- cutree(tree, k=nrCluster)


library(mclust)
fit <- Mclust(mydata)
plot(fit, what = "class")
fit <-MclustDA(data = x,class = sort(a$PROFISSAO),modelType = "EDDA")
plot(fit, what = "scatterplot")
plot(fit, what = "classification")
class <- a$PERFIL
table(class)
MclustDA(x,class)
unlist(cvMclustDA(fit, nfold = 10)[2:3])

# K-Means Clustering with k clusters

fit <- kmeans(x, nrCluster) 
fit$size
plot(x$GEO_REFERENCIA, col = fit$cluster)
points(fit$centers, col="orange", pch=8)


# outro

tree <- hclustvar(x,a)
plot(tree)
ph <- cutreevar(tree,k = nrCluster)
summary(ph$var)


# get cluster means 
aggregate(mydata,by=list(fit$cluster),FUN=mean)
# append cluster assignment
myNewdata <- data.frame(mydata, fit$cluster)

# Cluster Plot against 1st 2 principal components

# vary parameters for most readable graph
pca <- princomp(x, cor=T)
pc.comp <- pca$scores
pc.comp1 <- -1*pc.comp[,1]
pc.comp2 <- -1*pc.comp[,2]
newComp <- cbind(pc.comp1, pc.comp2)
cl <- kmeans(newComp, nrCluster)
plot(pc.comp1, pc.comp2,col=cl$cluster)
points(cl$centers, pch=16)
       
library(cluster) 
clusplot(mydata, fit$cluster, color=TRUE, shade=TRUE, labels=4, lines=0, 
         main = "Gráfico de Cluster Bivariável (de um Objeto de Particionamento)")

fit <- kmeans(x, centers = nrCluster) 
fit$size
clusplot(mydata, fit$cluster, color=TRUE, shade=TRUE, labels=4, lines=0)

# Centroid Plot against 1st 2 discriminant functions
library(fpc)
plotcluster(groups, fit$cluster)


library(fpc)
cluster.stats(mydata, fit$cluster, fit$cluster, clustering = 6)

clPairs(fit, class)

fit <- densityMclust(x)
summary(fit)
plot(fit, what = "density", data = mydata, breaks = 15)
