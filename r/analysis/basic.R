if(!require(data.table)){install.packages("data.table")}
if(!require(dplyr)){install.packages("dplyr")}
if(!require(ggplot2)){install.packages("ggplot2")}

#Loading raw data
build_data <- fread("../../travistorrent_8_2_2017.csv")

# how many jobs in build? how many of them failed? (Only in failed builds)
failed_job_data <- fread("../../results/job_failure_level.csv", 
                         header=FALSE, 
                         col.names = c("job_id","p_id","p_name","all_jobs","failed_jobs"))

# (Results of jobs + Did developers silenced the failures) For all builds
allow_failure_status <- fread("../../results/allow_failure_status.csv", 
                         header=FALSE, 
                         col.names = c("p_name","build_id","build_result","build_status","job_result","allow_failure"))

#List of projects with failed builds
write.csv(unique(build_data[tr_status=="failed",
                            get("gh_project_name")]), 
          file = "../../results/projects_with_failed_builds.csv",
          row.names=FALSE)

write.csv(unique(build_data[tr_status=="failed",
                            get("tr_build_id","gh_project_name")]), 
          file = "../../results/failed_build_ids.csv",
          row.names=FALSE)

write.csv(unique(build_data[,get("tr_build_id")]), 
          file = "../../results/all_build_ids.csv",
          row.names=FALSE)

#All maven builds 108555
write.csv(unique(build_data[tr_log_analyzer=='java-maven',get("tr_build_id")]), 
          file = "../../results/all_maven_build_ids.csv",
          row.names=FALSE)

#All maven jobs  315827
build_data[,.N , by = .(tr_log_analyzer)]

failed_job_data <- within(failed_job_data, perc <- 100*failed_jobs/all_jobs)
summary(failed_job_data)
quantile(failed_job_data$perc, 0.447)
#Result1: Not all jobs fail in at least 44% of the failed builds

# Percentage of pull requests
df1 <- build_data[, head(.SD,1) , by = tr_build_id][,.N,by="gh_is_pr"]
df1$Perc <- df1$N / sum(df1$N) * 100

# Percentage of build status based on pull requests or not
df2 <- build_data[, head(.SD,1) , by = tr_build_id][,.N,by=.(tr_status,gh_is_pr)][, `perc` := `N` / sum( `N` ) * 100,by='gh_is_pr']
#Result2: If it's a PR, build passing rate is slightly higher.

# In 13 instances, job failed but build passed for some unknown reason.
allow_failure_status[job_result=="1" & build_result=="0" & allow_failure==FALSE,.N,by=.(p_name,build_id)]
# In 2 instances, job errored but build passed for some unknown reason.
allow_failure_status[job_result=="2" & build_result=="0" & allow_failure==FALSE,.N,by=.(p_name,build_id)]

df3 <- allow_failure_status[,.N,by=.(job_result,allow_failure)][, `perc` := `N` / sum( `N` ) * 100,by='job_result']
df4 <- allow_failure_status[build_result=="0",.N,by=.(job_result,allow_failure)][, `perc` := `N` / sum( `N` ) * 100,by='job_result']
# 12% of passed builds have an ignored failure
length(unique(subset(allow_failure_status,build_result=='0' & job_result != '0')$build_id))


ignored_jobs <- allow_failure_status[build_result=='0' & job_result != '0' & allow_failure == TRUE,.N,by= .(build_id)]
hist(ignored_jobs$N)
