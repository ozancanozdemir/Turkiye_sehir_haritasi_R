**```ggplot2``` ile R'da Şehir Haritası Çizdirmek**

Herkese merhabalar!

Bundan yaklaşık iki sene önce  R'da ```maps```ve ```ggplot2``` paketleri kullanılarak Türkiye siyasi haritasının çizimini anlatmıştım. Konu ile ilgili tutoriala [buradan](http://users.metu.edu.tr/ozancan/harita.html) ulaşabilirsiniz. 

Şimdi ise işi biraz daha detaylandırıyoruz, bu sefer sadece  ```ggplot2``` paketi kullanarak bir şehrin ve ilçelerinin haritasını çizdirip, belirli bir değişkenin büyüklüğüne göre renklendireceğiz. 

Kullanacağımız spatial datayı [GADM](https://gadm.org/download_country_v3.html)'dan indiriyoruz. 

İlk olarak Türkiye’yi seçip, dosya formatı olarak da  ```R (SpatialPolygonsDataFrame) ``` (yani .rds) ’i seçiyoruz. 

**Not:** Buradan indireceğiniz veriyi ticari amaçla kullanamazsınız.

Ardından ekranınıza her bir R dosyasının yanında yazan  ```level 0 ```,  ```level 1 ``` ve  ```level 2 ``` seçeneklerini göreceksiniz. Bunlardan  ```level 0 ```, il ve ilçelerin olmadığı sadece Türkiye ülke sınırlarının yer aldığı dosyadır.Öte yandan  ```level 1 ``` il sınırlarının dahil olduğu,  ```level 2 ``` ise ilçe sınırlarının da dahil olduğu dosyadır. Bu örnekte il ve ilçe sınırlarıyla ilgilendiğimiz için biz  ```level 2 ``` i indiriyoruz.

İlk önce ```ggplot2``` paketine ek veri düzenlenmesi ve okumasında kullanacağımız ```tidyverse``` ve ```sp``` paketlerini de yüklüyoruz. 

```{r,warning=FALSE,message=FALSE}
library(tidyverse)
library(sp) # Konumsal (Spatial) veri için
library(ggplot2)
```


Daha sonra verimizi ```readRDS``` fonksiyonu ile okutuyoruz. 

```{r}
tr1<- readRDS("ililce.rds") #reading a spatial data
plot(tr1)
```
Verinizi okuttuktan sonra plot komutu ile kolayca görselleştirebilirsiniz, ancak başlıkta da belirtildiği gibi biz bu görselleştirmeyi ggplot2 kütüphanesinin komutlarını kullanarak yapacağız.


Bu tutorial'da Ankara ilini çizdireceğiz. Okuttuğumuz veri setinde il isimleri **NAME_1** başlığı altında depolanmaktadır. tidyverse paketi altındaki subset komutunu kullanarak bu değişkenden Ankara'yı seçeceğiz. 

```{r}
ankara=tr1%>%subset(NAME_1=="Ankara")
plot(ankara)
```

İşte Ankara'nın ilçelere göre haritası, ama işimiz burada bitmiyor. Bu haritayı ilçelerin büyüklüğüne göre renklendireceğiz ve başlık vs gibi detaylar ekleyeceğiz. 

Önce datanın içeriğini göstermek istiyorum.


```{r}
ankara@data %>% as_tibble() %>% head(10) 
```

Datayı tibble dosyası haline getirdik, böylece ilerleyen aşamalarda ```tidyverse``` içerisinde yer alan ```tidyr``` kütüphanesindeki ```left_join``` komutunun kullanımını kolaylaştırdık. Ardından ```head``` komutu ile datanın ilk 10 satırına göz attık.

+ ```GID_0``` : Ülke Kimlik Numarası

+ ```GID_1``` : Şehirlerin kimlik numaraları, bu numaraları plaka kodları ile karıştırmayın.

+ ```GID_2``` : İlçelerin kimlik numaraları

Aynı şekilde,

+ ```NAME_0``` : Ülke ismi

+ ```NAME_1``` : Şehir isimleri

+ ```NAME_2``` : İlçe İsimleri


Elimizdeki tibble/spatial datayı ```data.frame``` objesi haline getirmeliyiz, bunun içinde ```ggplot2``` paketi altındaki ```fortify``` fonksiyonu yardımıyla s3 objemizi df yapacağız. 

```{r}
ankdata<-fortify(ankara)
```

```{r}
head(ankdata)
```

Şimdi ise TÜİK'ten elde ettiğim Ankara ilçeleri nüfus verisini okutuyorum. Elimdeki veri **.xlsx** objesi olduğu için ```readxl``` komutu yardımıyla bu datayı okutuyorum.

```{r}
library(readxl)
nufus<-read_excel("ankaranufus.xlsx")
head(nufus)
```


Bu noktada karşımıza ufak bir problem çıkıyor.

```{r}
(ankara@data$NAME_2)
```
```{r}
nufus$İlce
```

Görüldüğü üzere spatial data ve okuttuğumuz datada  isimleri içinde farklılıklar var. Örn: Şultan Koçhisar ve Şereflikoçhisar. Bu sorunun çözümü için ise ```gsub``` fonksiyonunu kullanacağız. Bu fonksiyon karakter yapısındaki bir değişkenin içerisinde yer alan bir ya da birden fazla harfin değiştirilmesinde kullanılan bir fonksiyon.

**Örnek**

```{r}
x <- "Ozancan"
gsub("an","on",x)
```
```{r}
ankara@data$NAME_2<-gsub("Şultan Koçhisar" ,"Şereflikoçhisar",ankara@data$NAME_2)
(ankara@data$NAME_2)
```
Gördüğünüz gibi sorun çözüldü. :) 

Şimdi bu iki datayı birbiriyle birleştireceğiz, ancak bunun için önce nüfus datasını da tibble objesi haline getirmeliyiz. 


```{r}
nufus%>%as_tibble
```


Artık ```left_join``` kullanarak iki datayı da birleştirebiliriz.

```{r}
ilcenufus<- data_frame(id = rownames(ankara@data), İlce = ankara@data$NAME_2) %>% left_join(nufus, by = "İlce")
ilcenufus
```

Şimdi her ilçenin ID'sine karşılık gelecek şekilde nüfusularını da ekledik. 

Artık son aşama. ```ggplot2``` kullanarak haritalama işlemi yapmak istiyorsanız elinizdeki datada mutlaka lattitude ve longitude değerleri olmak zorunda. Bu yüzden birkez daha ```left_join``` kullanarak bir önceki stepte oluşturduğumuz dataya ilçelerim lattitude ve longitude değerlerini ekliyoruz.


```{r}
final_map <- left_join(ankdata, ilcenufus, by = "id")
head(final_map)
```
 Ops! Bir hatayla karşılaştık. İlçe ve nüfus değişkenleri datamıza eklenmemiş.Bunun sebebi muhtemelen ortak değişkenimiz olan ID elbette. 
 
 Eğer üst dataki ID ile final_map'teki ID değerlerine bakarsak, ufak bir sorun olduğunu göreceğiz. 
 
```{r}
table(ilcenufus$id)
```
 

```{r}
table(final_map$id)
```
İki çıktıdan anlaşıldığı üzere ```ankdata``` objesindeki id değerleri ```ilcenufus``` id değerlerinden bir fazla. O halde ```ilcenufus``` datasının id değerlerine 1 eklersek bu sorunu çözebiliriz. 

```{r}
str(ilcenufus)
```
```ilcenufus``` datasında id karakter objesi olarak duruyor, onu numeric'e çevirip 1 ekleyip daha sonra karater yapmalıyız. 
```{r}
ilcenufus$id=as.character(as.numeric(ilcenufus$id)+1)
```

```{r}
head(ilcenufus)
```
Sorun halloldu! :) 

```{r}
final_map1 <- left_join(ankdata, ilcenufus, by = "id")
head(final_map1)
```

```{r}
ggplot(final_map1) +geom_polygon( aes(x = long, y = lat, group = group, fill = Nufus), color = "grey") +
coord_map() +theme_void() + labs(title = "Ankara'nın İlçelere Göre Nüfus Dağılımı",subtitle = "Kaynak: Türkiye Istatistik Kurumu",caption="Twitter/@OzancanOzdemir") +
scale_fill_gradient(low = "pink", high = "red",na.value = "white") +
theme(plot.title = element_text(hjust = 0.5),plot.subtitle = element_text(hjust = 0.5))
```

Soru ve görüşlerinizi **ozancan@metu.edu.tr** adresine gönderebilirsiniz. 
