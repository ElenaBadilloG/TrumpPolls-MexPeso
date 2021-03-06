#######################################################################################################################################################
########################################  Trump Approval by Survey House #############################################################################
############################################### Elena Badillo Goicoechea, June 21 2017 ################################################################
# setwd("C:/YOUR_PREFERRED_WORKING_DIRECTORY")

#Required libraries

rm(list = ls()) #remove all previous work

library(data.table)
library(plyr)
library(dplyr)
library(reshape2)
library(ggplot2)
library(doBy)
library(scales)
library(zoo)
options(scipen = 999) #disable exponential notation for plots

fileURL<-"http://elections.huffingtonpost.com/pollster/api/v2/questions/00c%20-Pres-45-Trump%20-%20Job%20Approval%20-%20National/poll-responses-clean.tsv"
download.file(fileURL,destfile="./polls17.tsv")

# Full Polling Dataset (via HuffPost poll agregator)

poll<-read.table("./polls17.tsv", sep = '\t', header = TRUE)
poll$survey_house<-as.factor(gsub("/", "_", poll$survey_house)) #replace / to avoid symbol confusion
poll$survey_house<-as.factor(gsub(" ", "_", poll$survey_house))
poll$survey_house<-as.factor(gsub("Gravis_Marketing_Orlando_Political_Observer", "GM_Orlando_Political_Obs", poll$survey_house))
surveyHouses<-levels(poll$survey_house) #names of all surveyers


#Subset (All Adults) some publish "Likely Voters" or "Registered Voters" instead of Adults
pollsub <- subset(poll, poll$sample_subpopulation== "Adults" | poll$sample_subpopulation=="Likely Voters" | poll$sample_subpopulation=="Registered Voters")

# Average Approval by Survey House

pollAp_sh<-summaryBy(Approve ~ survey_house, data=pollsub,
                     FUN = list(mean, max, min, median, sd)) #by survey house
shm<-pollAp_sh[order(pollAp_sh$Approve.mean),] #order by min to max mean
dmean<-shm[,1:2]
colnames(dmean)<-c("Survey_House", "Approval")
dmean$Survey_House <- factor(dmean$Survey_House, levels = dmean$Survey_House[order(dmean$Approval)]) #ordenar factores para obtener colores ordenados

# Bar plot
library(RColorBrewer)

n<-nrow(dmean)
colfunc <- colorRampPalette(c("blue", "red"))
#plot(rep(1,n),col=colfunc(n),pch=19,cex=3)
polpalette<-colfunc(n) #own palette  where blue+dem, red-dem

gB<-ggplot(dmean, aes(x = Survey_House, y = Approval, fill = Survey_House)) + 
    geom_bar(stat = "identity") +
    scale_fill_manual(values=polpalette)+
    xlab("Survey House") + ylab("Trump Approval (%, avg)")+
    coord_cartesian(ylim=c(30,50))+
    ggtitle("Avg. Trump Approval Rating by Survey House (%)")+
    theme(plot.title = element_text(family = "Trebuchet", size=15,colour = "lightskyblue4",face="bold"),
          axis.text.x = element_text(size=10, angle=90), legend.position="none",
          axis.title = element_text(size=12),
          axis.text = element_text(size=12),
          plot.title = element_text(size=18))+
    annotate("text", x="AP-NORC", y=46, label= "less pro-Trump", colour="blue")+
    annotate("text", x="Zogby", y=46, label= "more pro-Trump", colour="red")
gB

ggsave(filename="Avg_App_by_Survey_House.jpg", width=11, height=7)

############# Individual Time Series 
k<-nrow(dmean)
polls<-data.frame(pollsub$end_date)
listdf <- list()
i<-c(1:k)
for (i in 1:k){
    polls<- subset(pollsub, pollsub$survey_house==surveyHouses[i])
    listdf[[i]] <-polls
    assign(paste(surveyHouses[i],sep="_"),polls)
}

Gallup<-Gallup[,c("end_date", "Approve")]
YG_Economist<-YouGov_Economist[,c("end_date", "Approve")]
Rasmussen<-Rasmussen[,c("end_date", "Approve")]
Ipsos_Reuters<-Ipsos_Reuters[,c("end_date", "Approve")]
Politico<-Politico_Morning_Consult[,c("end_date", "Approve")]
SurveyMonkey<-SurveyMonkey[,c("end_date", "Approve")]
options(warn=-1) #disable warnings

df <- join_all(list(Gallup,YG_Economist,Ipsos_Reuters,SurveyMonkey, Politico, Rasmussen), by = "end_date",type = "left", match = "all")
df<-data.frame(df)
colnames(df)<-c("Date", "Gallup","YG_Economist","Ipsos_Reuters","SurveyMonkey", "Politico", "Rasmussen")

for (j in 3:7){
    df[,j]<-na.approx(df[,j], na.rm = FALSE)
}

df<-melt(df, id="Date")

colnames(df) <- c("Date","SurveyHouse", "Approval")
ind<-match(c("Gallup","YouGov_Economist","Ipsos_Reuters","SurveyMonkey", "Politico_Morning_Consult", "Rasmussen"),dmean$Survey_House)
polpalette2<-polpalette[c(ind[1],ind[2],ind[3],ind[4],ind[5],ind[6])] #main sh colors

soft<-0.15
gM <- ggplot(df, aes(x = as.Date(Date),y = Approval, group=SurveyHouse, colour= SurveyHouse)) +
    scale_color_manual(values=polpalette2)+
    #geom_line(size=1, alpha=1)+
    geom_smooth(size=1, alpha=1,method="loess", span=soft, se=FALSE)+ #loess=Polynomial Regression Fitting
    coord_cartesian(ylim=c(30,60))+scale_x_date(date_breaks = "1 week")+
    ggtitle("Approval Rating by Main Survey Houses (smoothed avg., %)")+
    theme(plot.title = element_text(family = "Trebuchet", size=15,colour = "lightskyblue4",face="bold"),
          panel.grid.major = element_line(colour = "white"),
          panel.grid.minor = element_line(colour = "white"),
          axis.text.x =element_text(size  = 10,angle = 90, hjust = 1,  vjust = 1),
          axis.text.y =element_text(size  = 11))+
    labs(x="Date",y="Approval (%)")
gM

ggsave(filename="App_by_Main_Survey_House.jpg", width=11, height=7)
