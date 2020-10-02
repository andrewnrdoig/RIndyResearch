## load libraries
library(cBioPortalData)
library(httr)
library(dplyr)
library(stringr)
library(ggplot2)
library(MultiAssayExperiment)
library(S4Vectors)
library(UpSetR)
library(tidyverse)

###########################################Generate cBio API
cbio <- cBioPortal()
cbio

#Convenience function that downloads and creates an MAE automatically
CESC_Multiassay <- cBioDataPack(cancer_study_id = 'cesc_tcga')
View(CESC_Multiassay)
#CESC_Multiassay # look at all the experiments which are available

#Get clinical data
all_clinical_data <- clinicalData(cbio, studyId = "cesc_tcga")
View(all_clinical_data)

#Create subset for looking at number of mutations versus fraction genome altered



fga_mutation.number <- tibble(
   all_clinical_data[9],
   all_clinical_data[11]
)

ggplot() +
  geom_jitter(
    data = fga_mutation.number, 
    aes(x = as.numeric(FRACTION_GENOME_ALTERED),
        Y = as.numeric(MUTATION_COUNT)))
        


##Lets plot a chart that looks at the total mutation count
ggplot(data = all_clinical_data) + 
  geom_point(mapping = aes (x = MUTATION_COUNT, Y = FRACTION_GENOME_ALTERED))






ggplot() +
  geom_bar(
    data = all_clinical_data,
    aes(x = as.numeric(MUTATION_COUNT)),
    color = 'royalblue',
    fill = 'royalblue',
    na.rm = T,
    width = 0.8
  ) +
  theme_bw() +
  scale_x_continuous() +
  labs(x = "Number of Mutations", y = "Patients with that mutation count", title = "Number of Mutations")



#Retrieve all the clinical data from all of the study participants
#get all the clinical data for the patients
#all.clinics <- cbio$getAllClinicalDataInStudyUsingGET(studyId = "cesc_tcga")
#all.clinics <- httr::content(all.clinics)
#all.clinics <- data.frame(matrix(
#  unlist(all.clinics),
#  nrow = length(all.clinics),
#  byrow = T)) #Convert to matrix again for easier handling

#all.clinics[, c(1, 2, 3)] = NULL
#head(all.clinics) #Generates one gian data fram with all of the clinical attributes, according to sample? dunno exactly


#Output mutation count
#############################################
#This method may deliver the same as the retrive all clinical data block listed abovev
#all_clinical_data <- clinicalData(cbio, studyId = 'cesc_tcga')
#head(all_clinical_data)

##Retrieve all the clinical data from all of the study participants

#all.clinics.cerv <- cbio$getAllClinicalDataInStudyUsingGET(studyId = "cesc_tcga")
#all.clinics.cerv <- httr::content(all.clinics.cerv)
#all.clinics.cerv <- data.frame(matrix(
#  unlist(all.clinics.cerv),
#  nrow = length(all.clinics.cerv),
#  byrow <- T)) ## convert again, easier handling

#all.clinics[, c(1, 2, 3)] = NULL
#head(all.clinics)


## list all Assays/Experiments for cesc_tcga
#Assays_available = molecularProfiles(api = cbio,
#                                     studyId = 'cesc_tcga',
#                                     projection = 'SUMMARY')
#Assay_Ids = Assays_available$molecularProfileId #Shows all a the assays #available for analysis, 9 for this study
#Assay_Ids # print



#Look at number of mutations versus fraction genome altered:
#FGA <-  all_clinical_data[all_clinical_data$X6 == "FRACTION_GENOME_ALTERED", ] ##Subset datafram
#mutation.count <- all_clinical_data[all_clinical_data$X6 == "MUTATION_COUNT", ] ##Subset data frame

#FGA = all.clinics[all.clinics$X6 == "FRACTION_GENOME_ALTERED", ]
#mutation.count = all.clinics[all.clinics$X6 == "MUTATION_COUNT", ]

#data.figure1 = merge(FGA[,c(1, 4)],
#                     mutation.count[,c(1,4)],
#                     by.x = "X4",
#                     by.y = "X4",
#                     all = T) ##Merge the two datat frame to prepare for plot
#colnames(data.figure1) = c("patient", "FGA", "mutation.count")
                     
                     
                     












#Trying to figure shit out type code
################################################################################
#Generate a mutation object, but not by the preferred method?
#CESC_mutations <- assays(CESC_Multiassay)['mutations_mskcc']
#View(CESC_mutations)

#Generate our final MultiAssayExperiment object with the assays of mutation and expression
#CESC_MAE = CESC_Multiassay[,, c("mutations_mskcc",
#                                  "mutations_extended")]
#upsetSamples(CESC_MAE)

#CESC_MUT = assays(CESC_Multiassay)["mutations_mskcc"]
#CESC_MUT_compact = as.data.frame(CESC_mutations@listData$mutations_mskcc)
#sampleMap(CESC_Multiassay)

#View(CESC_Multiassay)

#any(duplicated(rownames(CESC_Multiassay)))

#upsetSamples(CESC_Multiassay)



