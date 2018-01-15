if(!require(data.table)){install.packages("data.table")}
if(!require(dplyr)){install.packages("dplyr")}
if(!require(ggplot2)){install.packages("ggplot2")}
if(!require(beanplot)){install.packages("beanplot")}
if(!require(effsize)){install.packages("effsize")}

# copied from MLA and .txt extension removed from the 3rd column
plugin_data <- fread("../../results/pluginoutput.txt", 
                     sep=";", 
                     stringsAsFactors=TRUE,
                     header=FALSE,
                     col.names = c("failure_type","failure_subtype","job_id"))
