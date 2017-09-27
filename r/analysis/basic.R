if(!require(data.table)){install.packages("data.table")}
if(!require(dplyr)){install.packages("dplyr")}
library(dplyr)
library(ggplot2)

#Loading data
build_data <- fread("../../travistorrent_8_2_2017.csv")

failed_job_data <- fread("../../results/job_failure_level.csv", 
                         header=FALSE, 
                         col.names = c("job_id","p_id","p_name","all_jobs","failed_jobs"))
allow_failure_status <- fread("../../results/allow_failure_status.csv", 
                         header=FALSE, 
                         col.names = c("p_name","build_id","build_result","build_status","job_result","allow_failure"))

dim(build_data)

unique(build_data[,get("tr_status")])
unique(build_data[,get("tr_log_status")])
unique(build_data[tr_status=="passed",get("build_successful")])

calc <- function(x) {
  data <- x
  w <- (sum(data$build_successful)  / count(data))
  w
}


aggr_res <- build_data %>% 
  group_by(tr_build_id) %>%
  do(data.frame(val=calc(.)))

length(build_data[tr_build_id=="106060"])
write.csv(unique(build_data[tr_status=="failed",
                            get("gh_project_name")]), 
          file = "../../results/projects_with_failed_builds.csv",
          row.names=FALSE)

n_distinct(build_data[tr_status=="failed",get("tr_build_id")])
n_distinct(build_data[,get("tr_build_id")])
unique(build_data[,get("tr_log_lan")])
build_data[,.N , by = tr_log_lan]
build_data[,.N , by = tr_log_analyzer]
write.csv(unique(build_data[tr_status=="failed",
                            get("tr_build_id","gh_project_name")]), 
          file = "../../results/failed_build_ids.csv",
          row.names=FALSE)

write.csv(unique(build_data[,get("tr_build_id")]), 
          file = "../../results/all_build_ids.csv",
          row.names=FALSE)

build_data[tr_build_id=="106176"]$gh_project_name

build_data[tr_job_id=="106190"]$tr_log_status

unique(build_data[tr_status=="passed",get("tr_log_status")])
dim(build_data)


aggr_res <- failed_job_data %>% 
  group_by(p_name) %>%
  do(data.frame(val=count(.)))

summary(aggr_res)


dim(failed_job_data)
n_distinct(failed_job_data$p_name)
failed_job_data <- within(failed_job_data, perc <- 100*failed_jobs/all_jobs)
summary(failed_job_data)
quantile(failed_job_data$perc, 0.447)


failed_job_data[, c("job_id","p_id","p_name","perc"):=NULL]
# failed_job_data[, c("job_id","p_id","p_name","all_jobs","failed_jobs"):=NULL]
mm <- melt(failed_job_data)
pl <- ggplot(mm,aes(x=variable, y=value))+
  geom_boxplot()
pl

# Percentage of pull requests
df1 <- build_data[, head(.SD,1) , by = tr_build_id][,.N,by="gh_is_pr"]
df1$Perc <- df1$N / sum(df1$N) * 100
df2 <- build_data[, head(.SD,1) , by = tr_build_id][,.N,by=.(tr_status,gh_is_pr)][, `perc` := `N` / sum( `N` ) * 100,by='gh_is_pr']

allow_failure_status[job_result=="1" & build_result=="0" & allow_failure==FALSE,.N,by=.(p_name,build_id)]

allow_failure_status[job_result=="2" & build_result=="0" & allow_failure==FALSE,.N,by=.(p_name,build_id)]
