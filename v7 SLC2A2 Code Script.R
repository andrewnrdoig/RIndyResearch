
  ##To Do
  #We have improved the sample/patient matching system to clear mismatches. However, there were two patients whose expression was #not present. Removing those rows by index around line 104 is not super robust. If the data changes this will need to be #manually checked.
  #Load Libraries
library(tidyverse) 
library(survminer)
library(survival)
library(ggplot2)
library(rlang)
library(rmarkdown)
library(knitr)
library(coin)

#Data Wrangling
#Data Wrangling

#Import patient clinical data into a tibble
all_clin_data <- read_tsv("data\\cesc_tcga\\data_bcr_clinical_data_patient.txt", 
                          col_names = TRUE, skip = 4)

#THIS IS THE EXPRESSION DATA THAT WE NEED!
#Import median RNA Seq v2 expression z scores median data
all_expression_median_Zscores <- read_tsv("data\\cesc_tcga\\data_RNA_Seq_v2_mRNA_median_Zscores.txt",
                                          col_names = TRUE)

#order clinical data by patient id name
cesc_clin_data <- all_clin_data
cesc_clin_data <- cesc_clin_data[order(cesc_clin_data$PATIENT_ID),]

#Generate a list of SCL2A2 zscore expression data
zscore_SLC2A2 <- filter(all_expression_median_Zscores, Hugo_Symbol == "SLC2A2")

#generate a list of SLC2A1 zscore expression data
zscore_SLC2A1 <- filter(all_expression_median_Zscores, Hugo_Symbol == "SLC2A1")

#Sort zscore expression data by sample name, convert to a longer form, SLC2A2
zscore_SLC2A1 <- gather(zscore_SLC2A1, key = "Sample", value = "zscore_expression_medians", 3:308)
zscore_SLC2A1 <- zscore_SLC2A1[order(zscore_SLC2A1$Sample),]
zscore_SLC2A1 <- rename(zscore_SLC2A1, SLC2A1_zscore_expression_medians = zscore_expression_medians)


#Sort zscore expression data by sample name, convert to a longer form, SLC2A1
zscore_SLC2A2 <- gather(zscore_SLC2A2, key = "Sample", value = "zscore_expression_medians", 3:308)
zscore_SLC2A2 <- zscore_SLC2A2[order(zscore_SLC2A2$Sample),]
zscore_SLC2A2 <- rename(zscore_SLC2A2, SLC2A2_zscore_expression_medians = zscore_expression_medians)


#Create a new tibble for the final data. We will sort from this list, and then do a sample ID check to load it with expression data.

cesc_survival_data <- tibble(
  patient_id = cesc_clin_data$PATIENT_ID,
  age = as.numeric(cesc_clin_data$AGE),
  histiological_diagnosis = cesc_clin_data$HISTOLOGICAL_DIAGNOSIS,
  survival_status = as.numeric(substring(cesc_clin_data$OS_STATUS,1,1)),
  survival_time = as.numeric(cesc_clin_data$OS_MONTHS),
  
  #zscore_SLC2A1_sampleid = zscore_SLC2A1$Sample,
  #zscore_value_SLC2A1 = zscore_SLC2A1$zscore_expression_medians,
  
  #zscore_SLC2A2_sampleid = zscore_SLC2A2$Sample,
  #zscore_value_SLC2A2 = zscore_SLC2A2$zscore_expression_medians,
  
  
)


#Manipulate Data Frame
#remove non-Cervical Squamous Cell Carcinoma Patients from final data frame
cesc_survival_data <- filter(cesc_survival_data, histiological_diagnosis == "Cervical Squamous Cell Carcinoma")

#Label samples with sample number from expression data
zscore_SLC2A1$sample_number <- str_sub(zscore_SLC2A1$Sample, -2,-1)
zscore_SLC2A2$sample_number <- str_sub(zscore_SLC2A2$Sample, -2,-1)

#Remove extraneous samples
zscore_SLC2A1 <- filter(zscore_SLC2A1, sample_number == "01")
zscore_SLC2A2 <- filter(zscore_SLC2A2, sample_number == "01")

#generate a column of patient names inferred from sample ID
zscore_SLC2A1$patient_id <- str_sub(zscore_SLC2A1$Sample, 1,12)
zscore_SLC2A2$patient_id <- str_sub(zscore_SLC2A2$Sample, 1,12)

#add the SLC2A1 expression data that has been cleaned to the #final survival analysis data frame
cesc_survival_data <- left_join(cesc_survival_data,zscore_SLC2A1,by="patient_id")
cesc_survival_data <- left_join(cesc_survival_data,zscore_SLC2A2,by="patient_id")

#remove rows with missing data
cesc_survival_data <- cesc_survival_data[-c(118, 222), ]


#Manipulate data

#Create quartile groupings of expression of SLC2A1 zscore
cesc_survival_data <- cesc_survival_data %>% mutate(zscore_value_SLC2A1_quartile = ntile(cesc_survival_data$SLC2A1_zscore_expression_medians, 4))

#Create quartile groupings of expression of SLC2A2 means
cesc_survival_data <- cesc_survival_data %>% mutate(zscore_value_SLC2A2_quartile = ntile(cesc_survival_data$SLC2A2_zscore_expression_medians, 4))

#convert the numeric quartile data into vector data for use by cox regression
cesc_survival_data$zscore_value_SLC2A1_quartile <- factor(cesc_survival_data$zscore_value_SLC2A1_quartile,
                                                          levels = c("1","2","3","4"),
                                                          labels = c("Low Exp.", "Med. Low Exp.", "Med. High Exp.", "High Exp."))

#convert the numeric quartile data into vector data for use by cox regression
cesc_survival_data$zscore_value_SLC2A2_quartile <- factor(cesc_survival_data$zscore_value_SLC2A2_quartile,
                                                          levels = c("1","2","3","4"),
                                                          labels = c("Low Exp.", "Med. Low Exp.", "Med. High Exp.", "High Exp."))

#Compute median of SLC2A1
zscore_SLC2A1_median <- median(cesc_survival_data$SLC2A1_zscore_expression_medians)

#compute median of SLC22
zscore_SLC2A2_median <- median(cesc_survival_data$SLC2A2_zscore_expression_medians)


#generate a column of data which will tag the patient as either expressing SLC2A1 above the median or below the median
cesc_survival_data$SLC2A1_greater_lesser_median <- ifelse(cesc_survival_data$SLC2A1_zscore_expression_medians > zscore_SLC2A1_median, "More Than Median", "Less Than Median")

#generate a column of data which will tag the patient as either expressing SLC2A2 above the median or below the median
cesc_survival_data$SLC2A2_greater_lesser_median <- ifelse(cesc_survival_data$SLC2A2_zscore_expression_medians > zscore_SLC2A2_median, "More Than Median", "Less Than Median")


#convert the character less than greater than median expression data into factor data for use by survival function and cox regressions
cesc_survival_data$SLC2A1_greater_lesser_median <- factor(cesc_survival_data$SLC2A1_greater_lesser_median,
                                                          levels = c("Less Than Median","More Than Median"),
                                                          labels = c("Less Than Median","More Than Median"))

#convert the character less than greater than median expression data into factor data for use by survival function and cox regressions
cesc_survival_data$SLC2A2_greater_lesser_median <- factor(cesc_survival_data$SLC2A2_greater_lesser_median,
                                                          levels = c("Less Than Median","More Than Median"),
                                                          labels = c("Less Than Median","More Than Median"))
#Survival Analysis
#Survival Analysis

#Generate survival object
survival_object <- Surv(time = cesc_survival_data$survival_time, event = cesc_survival_data$survival_status)

#Fit the survival data to a curve that is defined by the quartiles of zscore SLC2A1
quartiles_SLC2A1_expression_survival_curve <- survfit(survival_object ~ zscore_value_SLC2A1_quartile, data = cesc_survival_data)

#Fit the survival data to a curve that is defined by the quartiles of zscore SLC2A2
quartiles_SLC2A2_expression_survival_curve <- survfit(survival_object ~ zscore_value_SLC2A2_quartile, data = cesc_survival_data)

#Fit survival data to a curve that is defined by the median greater lesser than values
greater_lesser_than_median_expression_curve_SLC2A1 <- survfit(survival_object ~ SLC2A1_greater_lesser_median, data = cesc_survival_data )

#Fit survival data to a curve that is defined by the median greater lesser than values
greater_lesser_than_median_expression_curve_SLC2A2 <- survfit(survival_object ~ SLC2A2_greater_lesser_median, data = cesc_survival_data )
#Ouput Section

###############################################################################################
###OUTPUT SECTION

#Generate a graph of survival object/expression quartile curve of zscore SLC2A1 median quartiles
ggsurvplot(quartiles_SLC2A1_expression_survival_curve, data = cesc_survival_data, 
           #conf.int = TRUE,
           pval = TRUE,
           fun = "pct",
           risk.table = TRUE,
           size = 1,
           linetype = "strata",
           #palette = c("#E7B800", "#2E9FDF"),
           legend = "bottom",
           legend.title = "Expression Quartiles",
           legend.labs = c("Low Exp.", "Med. Low Exp.", "Med. High Exp.", "High Exp."),
           caption = "SLC2A1 Expression Quartile Survival Curve"
)

#Generate a graph of survival object/expression quartile curve of zscore SLC2A2 median quartiles
ggsurvplot(quartiles_SLC2A2_expression_survival_curve, data = cesc_survival_data, 
           #conf.int = TRUE,
           pval = TRUE,
           fun = "pct",
           risk.table = TRUE,
           size = 1,
           linetype = "strata",
           #palette = c("#E7B800", "#2E9FDF"),
           legend = "bottom",
           legend.title = "Expression Quartiles",
           legend.labs = c("Low Exp.", "Med. Low Exp.", "Med. High Exp.", "High Exp."),
           caption = "SLC2A2 Expression Quartile Survival Curve"
)

#Generate a graph of survival object/expression greater or lesser than median curve of zscore SLC2A1 median
ggsurvplot(greater_lesser_than_median_expression_curve_SLC2A1, data = cesc_survival_data, 
           #conf.int = TRUE,
           pval = TRUE,
           fun = "pct",
           risk.table = TRUE,
           size = 1,
           linetype = "strata",
           #palette = c("#E7B800", "#2E9FDF"),
           legend = "bottom",
           # legend.title = "SLC2A1 Greater or Lesser than Median",
           legend.labs = c("Less than Median", "More than Median"),
           caption = "SLC2A1 Expression Median Survival Curve"
)           

#Generate a graph of survival object/expression greater or lesser than median curve of zscore SLC2A1 median
ggsurvplot(greater_lesser_than_median_expression_curve_SLC2A2, data = cesc_survival_data, 
           #conf.int = TRUE,
           pval = TRUE,
           fun = "pct",
           risk.table = TRUE,
           size = 1,
           linetype = "strata",
           #palette = c("#E7B800", "#2E9FDF"),
           legend = "bottom",
           #  legend.title = "SLC2A1 Greater or Lesser than Median",
           legend.labs = c("Less than Median", "More than Median"),
           caption = "SLC2A2 Expression Median Survival Curve"
           
)           