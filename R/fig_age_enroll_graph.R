#Header-------------------------------------------------------------------------

  rm(list=ls())
  library(tidyverse)
  
  #Data path
  path <- "C:/Users/XPS/Desktop/Research/Thesis Research/Remittance/code/modeldata/"; setwd(path)
  
  # Path to Save Graphs
  wpath <- "C:/Users/XPS/Desktop/Research/Thesis Research/Remittance/graphs/" 
  
  
  #Read 2018 child data
  i2018 <- read.csv("i2018.csv")
  
  #Read education data
  educ_all <- read.csv(paste0(path,"educ_all.csv")) 

#Clean Dataset------------------------------------------------------------------
  
  #Get Children aged 5 to 18
  educ_ch <- filter(educ_all, age >= 6 & age <= 24)
  
  #Get enrollment rates by agegroup
  educ_age <- educ_ch %>% 
    group_by(age) %>%
    summarise(enrollment = mean(enroll))
   

#Graph--------------------------------------------------------------------------
  
  ggplot(educ_age, aes(x= age, y = enrollment))+
    geom_line()+
    geom_vline(xintercept = 16, color = "red")+
    geom_vline(xintercept = 18, color = "red")+
    geom_text(x= 16, y = 0.08, label = "Grade 9", color = "red")+
    geom_text(x= 18, y = 0.08, label = "Grade 10", color = "red")+
    theme_minimal()+
    theme(plot.title = element_text(hjust = 0.5),
          panel.grid.minor.x = element_blank(),
          panel.grid.major.x = element_blank())+
    scale_x_continuous(breaks = c(6:24))+
    labs(title = "Proportion Enrolled by Age",
         x = "Age",
         y = "Proportion Enrolled")
  
  ggsave( filename = paste0(wpath,"propenrollage.png")) 
  
  