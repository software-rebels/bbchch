if(!require(data.table)){install.packages("data.table")}
if(!require(dplyr)){install.packages("dplyr")}
if(!require(ggplot2)){install.packages("ggplot2")}
if(!require(beanplot)){install.packages("beanplot")}
if(!require(effsize)){install.packages("effsize")}

install.packages("Rcmdr")

# copied from MLA and .txt extension removed from the 3rd column
plugin_data <- fread("../../results/pluginoutput.txt", 
                     sep=";", 
                     stringsAsFactors=TRUE,
                     header=FALSE,
                     col.names = c("failure_type","failure_subtype","job_id"))

plugin_data[,.N , by = .(failure_type)]

plugin_data[failure_type=='GOAL_FAILED' & failure_subtype=='UNKNOWN']

write.table(unique(plugin_data[failure_type=='NO_LOG',get("job_id")]),
          file = "../../results/jobs_with_nolog.csv",
          row.names = FALSE,
          col.names = FALSE)

# this is to find out what needs to be skipped
write.table(unique(plugin_data[failure_type!='NO_LOG',get("job_id")]),
            file = "../../results/jobs_without_nolog.csv",
            row.names = FALSE,
            col.names = FALSE)

#Remove no log ones because, they will be merged in the 2nd iteration
plugin_data <- plugin_data[failure_type!='NO_LOG']

#2nd iteration
plugin_data2 <- fread("../../results/pluginoutput2.txt", 
                     sep=";", 
                     stringsAsFactors=TRUE,
                     header=FALSE,
                     col.names = c("failure_type","failure_subtype","job_id"))

plugin_data2[,.N , by = .(failure_type)]
plugin_data2[,.N , by = .(failure_subtype)]


l = list(plugin_data, plugin_data2)
plugin_data <- rbindlist(l, use.names=TRUE, fill=TRUE)

plugin_data[,.N , by = .(failure_type)]
plugin_data[,.N , by = .(failure_subtype)]

# overriding the file to ge the remaining 1554 No_log cases
write.table(unique(plugin_data[failure_type=='NO_LOG',get("job_id")]),
            file = "../../results/jobs_with_nolog.csv",
            row.names = FALSE,
            col.names = FALSE)

write.table(unique(plugin_data[failure_type!='NO_LOG',get("job_id")]),
            file = "../../results/jobs_without_nolog.csv",
            row.names = FALSE,
            col.names = FALSE)
