rm(list = ls())
Sys.setenv(JAVA_HOME = 'C:\\Program Files\\Java\\jdk1.8.0_172')

library(twitteR)
library(ROAuth)

library(tm)
library(stringr)
library(KoNLP)
library(igraph)

useSejongDic()

source("twitterOAuth.R") #Ʈ���� API�� ���������� ���� �������� �����

setup_twitter_oauth(consumer_key, consumer_secret, access_token, access_secret)

tweets <- searchTwitter("from:[Ʈ����ID]", n = 500)
tweets_df <- twListToDF(tweets)

result <- tweets_df$text

stuff_to_remove <- c("http[s]?://[[:alnum:].\\/]+", "@[\\w]*", "#[\\w]*", "<.*>", "'s")
stuff_to_remove <- paste(stuff_to_remove, sep = "|", collapse = "|")

result <- str_replace_all(result, stuff_to_remove, "")
#result
for (i in seq_along(result)) {
    result[i] <- gsub("RT : ", "", result[i])
    result[i]<- gsub("\n", " ", result[i])
}
#result

text <- VCorpus(VectorSource(result))

for (i in seq_along(text)) {
    text[[i]]$content <- paste(text[[i]]$content, collapse = " ")
}

text <- tm_map(text, removePunctuation)
text <- tm_map(text, removeNumbers)
text <- tm_map(text, stripWhitespace)

for (i in seq_along(text)) {
    nouns <- extractNoun(text[[i]]$content)
    nouns <- nouns[nchar(nouns) > 2]
    text[[i]]$content <- paste(nouns, collapse = " ")
}
#text


text_tdm <- TermDocumentMatrix(text, control = list(tokenize = "scan", wordLengths = c(2, 7)))
#text_tdm
#inspect(text_tdm)

tds <- weightTfIdf(text_tdm)
M <- t(as.matrix(tds))
g <- cor(M)
diag(g) <- 0
g[is.na(g)] <- 0
g[g < 0.4] <- 0
rownames(g) <- colnames(g) <- Terms(tds1)
g1 <- graph_from_adjacency_matrix(g, weighted = TRUE)

wc <- walktrap.community(g1)

plot(wc, g1, edge.curved = .1, vertex.label.cex = 0.7, edge.color = "grey",
     vertex.frame.color = "grey", vertex.size = 0, vertex.shape = "none", vertex.color = "white",
     main = paste0("�ֱ� Ʈ�� 500���� ���������� TF-IDF ��Ʈ��ũ Ŀ�´�Ƽ"))