# This R file contains the code to create the dataset of all migrants in 2018
# "indivcode.R" uses the dataset "mig2018.csv" created using this file
# "miggraphs.R" uses the dataset "mig2018.csv" and "abs18.csv" created using this file

#Header -------------------------------------------------------------------------
rm(list=ls())
library(tidyverse)

# Path where survey data is located
path <- "C:/Users/XPS/Desktop/Research/Thesis Research/Remittance/code/data";setwd(path)

#Path to write migration data
w2path <- "C:/Users/XPS/Desktop/Research/Thesis Research/Remittance/code/modeldata/"


#--------------------------------------------------------------------------------

# Read Survey Data
df_list <- lapply(list.files(path), read.csv) 
names(df_list) <- gsub(".csv", "", list.files(path))
list2env(df_list, envir = .GlobalEnv)

rm(list = ls()[grepl("2016|2017",ls())]) #Remove 2016 and 2017 data

# Prepare HH members dataset----------------------------------------------------
  
  #Read Individual dataset
  colni <- c('member_id', 'hhid', 'psu','vdc','district', 's01q01', 's01q02', 's01q03', 's01q06a')
  ir2018 <- `2018Section_1`[,colni]
  
  #Get HH characteristics  
  hh18 <- ir2018 %>% 
    group_by(hhid) %>% 
    summarize(n_mem = n()) %>% #Number of members
    left_join(select(`2018Section_0`,hhid, wt_hh, s00q15, s00q17), #Ethnicity and Religion
              by = "hhid") 
  
  #Merge HH characteristics 
  i18 <- ir2018 %>% left_join( hh18,by = "hhid") %>%
    #Rename Columns
    rename(rship =s01q01 , gender = s01q02 , age = s01q03, ethn = s00q15, 
           relig = s00q17, athome = s01q06a) 
    
  
# Prepare Current Migrants dataset-----------------------------------------------------
  
  #Get Absentee data
  mig18 <- `2018Section_11` %>%
    select(hhid:member_id, s11q00d, #IDs and migration status from last year
           s11q01c:s11q02b, #Gender, Age, Educ and destination
           s11q04a_1:s11q04a_11, #Initial Reasons for moving
           s11q05a, s11q05b, s11q05c, #Current Primary activities in destination
           s11q07a, s11q07c)  # Remittance
  
  #Rename
  mig18 <- rename(mig18, sts = s11q00d, gender = s11q01c, age = s11q01d, 
                  educbg = s11q01e, in_grade = s11q01f, p_grade = s11q01g, #Educ Status, Current Grade, Passed Grade
                  bdest = s11q02, ldest = s11q02a, intdest = s11q02b,  #Local Vs Intl, and destination within each
                  act = s11q05a, job = s11q05b, inc = s11q05c, #Job and Income in destination
                  sendrem = s11q07a, remamt = s11q07c) # Remittance 
  
  #Create  Reason of leaving category column
        #Rename columns
        mig18 <- rename(mig18, marriage = s11q04a_1, `follow family` = s11q04a_2, 
                        `otherfamily` = s11q04a_3,education = s11q04a_4, training = s11q04a_5, 
                        `looking for work` = s11q04a_6,`start new job/business` = s11q04a_7, 
                        `job transfer` = s11q04a_8, `conflict` = s11q04a_9, 
                        `natural disaster` = s11q04a_10, `easier life` = s11q04a_11,
                        )
        
        #Create column for reason
        mig18 <- mig18 %>% mutate(reason = case_when(marriage == "Yes" ~ "marriage",
                                               `follow family` == "Yes" ~ "follow family",
                                               otherfamily == "Yes" ~ "otherfamily",
                                               education == "Yes" ~ "education",
                                               training == "Yes" ~ "training",
                                               `looking for work` == "Yes" ~ "looking for work",
                                               `start new job/business` == "Yes" ~ "start new job/business",
                                               `job transfer` == "Yes" ~ "job transfer",
                                               conflict == "Yes" ~ "conflict",
                                               `natural disaster` == "Yes" ~ "natural disaster",
                                               `easier life` == "Yes" ~ "easier life",
                                               TRUE ~ "Other"))
        #Drop migrants that returned
        mig18 <- filter(mig18, sts != "No")
        
        #Drop old columns
        mig18a <- select(mig18, hhid:member_id, gender: intdest, act:inc)
        
        #Create seperate dataset for Remittances
        mig18b <- select(mig18, hhid:member_id, gender: intdest, act:inc, sendrem, remamt)
        


      
           

# Prepare and merge Past Migrants dataset---------------------------------------
        
  #Get Past Absentee data: People at home that migrated in the past 10 years
  pmig18 <- filter(`2018Section_11a`, s11aq01_1 == "Yes") %>% # Filter absentees
    #Select variables    
    select(hhid:member_id, #IDs 
    s11aq02, s11aq02a, s11aq02b, # Destination
    s11aq03a, s11aq03b, s11aq03c) # Primary activities in destination
        
  #Get Gender and Age data from Household Roster
    #*sum(pmig18$member_id %in% i18$member_id)  # <- Check
  pmig18 <- pmig18 %>% left_join(select(i18, member_id, age, gender), by = "member_id") 
  
  #Get Education data from Section 2 Education
    #*sum(pmig18$member_id %in% `2018Section_2`$member_id)  # <- Check
  pmig18 <- pmig18 %>% left_join(select(`2018Section_2`, member_id, s02q01,s02q02,s02q03), 
                                 by = "member_id")
        
  #Rename
  pmig18 <- rename(pmig18, 
            bdest = s11aq02, ldest = s11aq02a, intdest = s11aq02b,  #Local Vs Intl, and destination within each
            act = s11aq03a, job = s11aq03b, inc = s11aq03c, #Activity in destination
            educbg = s02q01, p_grade =  s02q02, in_grade = s02q03) #Education
            
        
  #Merge
  mig <- rbind(mig18a, pmig18)
  
  # Indicator for missing destination
  mig <- mig %>% mutate(bdest = case_when(bdest ==  "" ~ "missing", TRUE ~ bdest))
  

  
#Destination, Action and Education Variables-----------------------------------------------
  
  #Create destination column
  mig <- mig %>% 
    mutate(dest = case_when(bdest == "Locally (in Nepal)" ~ "Local",
                            bdest == "Overseas" & intdest == "India" ~ "India",
                            bdest == "Overseas" & intdest %in% 
                             c("Qatar", "Malaysia", "Malayasia", "United Arab Emirates", "Saudi Arabia") ~ "Gulf-Malaysia",
                            TRUE ~ "Other/Missing"))
  
  #Change Action Columns
  mig <- mig %>%
    mutate(act = case_when(act %in% c("Working", "Looking for Work")~ "Work",
                           act== "Education" ~ "Education",
                           TRUE ~ "Other/Missing")
           )
  
  
  #Clean Education Column 
  mig <- mig %>% 
    #Get education levels based on educational background
    mutate(educ = case_when(educbg == "Currently Attending School" ~ in_grade,
                                          educbg == "Attended School in the Past (no longer attending)" ~ p_grade,
                                          educbg == "Never Attended School" ~ "Never Attended School")) %>%
    #Rename rows with missing data; all missing rows have attended 
    mutate(educ = case_when(educ == "" ~ "Attended(Unknown)",
                             TRUE ~ educ)) %>%
    #Group Primary and Secondary
    mutate(educ = case_when( educ = educ %in% c("Pre school", "Class 1", "Class 2", "Class 3", "Class 4",
                                             "Class 5") ~ "Primary",
                               educ %in% c("Class 6", "Class 7", "Class 8", "Class 9",
                                             "Class 10", "SLC")~ "Secondary",
                              educ %in% c("Never Attended School", "Literate (Level less)") ~ "Not Attended",
                               TRUE ~ educ
    ))
  
  #Total Count
  mig$tot <- nrow(mig)
  

#WRITE DATA---------------------------------------------------------------------    
  #Write data for all migrants
  write.csv(mig, paste0(w2path, "mig18.csv"))
  
  #Write data for 2018 absentees (to create remittance graphs)
  write.csv(mig18b, paste0(w2path, "abs18.csv"))
  
  
#-------------------------------------------------------------------------------
  
  #Female Migrants in India
  fems_india <- mig %>% filter(gender == "Female", 
                         act == "Work", 
                         dest == "India"|dest == "Gulf-Malaysia")
  
  #Female Migrants in GUlf-Malaysia
  fems_gulf <- mig %>%filter(gender == "Female", 
                             act == "Work", 
                             dest == "Gulf-Malaysia")
  
  
  #All Female Migrants
  fems_all <- mig %>% filter(gender == "Female", 
                               act == "Work", 
                               dest == "India"|dest == "Gulf-Malaysia")
  
  
  #Female Migrants work in Gulf
  fems_work_gulf <- fems_gulf %>% 
    group_by(job) %>%
    summarise(prop = n()/nrow(fems_gulf))
  
  #Female Migrants work in India
  fems_work_india <- fems_india %>% 
    group_by(job) %>%
    summarise(prop = n()/nrow(fems_india))
  
  #Female Migrants work in Gulf
  fems_work_all <- fems_all %>% 
    group_by(job) %>%
    summarise(prop = n()/nrow(fems_all))
  
  #Female Migrants work in Gulf
  fems_work_all <- fems_all %>% 
    group_by(age) %>%
    summarise(prop = n()/nrow(fems_all))
  