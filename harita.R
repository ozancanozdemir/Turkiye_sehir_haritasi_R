## ggplot2 Kullanarak R'da T�rkiye �ehir Haritas� �izdirmek

 
library(tidyverse)
library(sp) # Konumsal (Spatial) veri i�in
library(ggplot2)


tr1<- readRDS("ililce.rds") #reading a spatial data
plot(tr1)

ankara=tr1%>%subset(NAME_1=="Ankara")
plot(ankara)

ankara@data %>% as_tibble() %>% head(10) 

ankdata<-fortify(ankara)

head(ankdata)

library(readxl)
nufus<-read_excel("ankaranufus.xlsx")
head(nufus)



(ankara@data$NAME_2)


nufus$�lce


  
x <- "Ozancan"
gsub("an","on",x)


ankara@data$NAME_2<-gsub("�ultan Ko�hisar" ,"�erefliko�hisar",ankara@data$NAME_2)
(ankara@data$NAME_2)


nufus%>%as_tibble


ilcenufus<- data_frame(id = rownames(ankara@data), �lce = ankara@data$NAME_2) %>% left_join(nufus, by = "�lce")
ilcenufus

final_map <- left_join(ankdata, ilcenufus, by = "id")
head(final_map)


table(ilcenufus$id)


table(final_map$id)

str(ilcenufus)

ilcenufus$id=as.character(as.numeric(ilcenufus$id)+1)



head(ilcenufus)


final_map1 <- left_join(ankdata, ilcenufus, by = "id")
head(final_map1)



ggplot(final_map1) +geom_polygon( aes(x = long, y = lat, group = group, fill = Nufus), color = "grey") +
coord_map() +theme_void() + labs(title = "Ankara'n�n �l�elere G�re N�fus Da��l�m�",subtitle = "Kaynak: T�rkiye Istatistik Kurumu",caption="Twitter/@OzancanOzdemir") +
scale_fill_gradient(low = "pink", high = "red",na.value = "white") +
theme(plot.title = element_text(hjust = 0.5),plot.subtitle = element_text(hjust = 0.5))


