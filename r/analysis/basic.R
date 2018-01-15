if(!require(data.table)){install.packages("data.table")}
if(!require(dplyr)){install.packages("dplyr")}
if(!require(ggplot2)){install.packages("ggplot2")}
if(!require(beanplot)){install.packages("beanplot")}
if(!require(effsize)){install.packages("effsize")}

packageVersion("data.table")


#Loading raw data
build_data <- fread("../../travistorrent_8_2_2017.csv")

n_distinct(build_data[git_trigger_commit==tr_original_commit & gh_is_pr == "TRUE",get("tr_build_id")])
table(build_data[git_trigger_commit!=tr_original_commit,get("gh_is_pr")])
lf <- unique(build_data[,c("tr_build_id", "git_prev_built_commit","git_trigger_commit","tr_status")])
colnames(lf) <- paste("l", colnames(lf), sep = "_")
rf <- unique(build_data[,c("tr_build_id", "git_prev_built_commit","git_trigger_commit","tr_status")])
colnames(rf) <- paste("r", colnames(rf), sep = "_")

setkey(lf, l_git_trigger_commit)
setkey(rf, r_git_prev_built_commit)

x_joined <- lf[rf, nomatch=0]
x_joined[,branch_count := .N,by= .(l_git_trigger_commit)]
x_failed <- x_joined[l_tr_status!="passed", head(.SD,1) , by = l_git_trigger_commit]

x_ff <- x_joined[l_tr_status!="passed" & r_tr_status!="passed", head(.SD,1) , by = l_git_trigger_commit]

hist(x_ff[branch_count>1 & branch_count < 12]$branch_count,breaks=10)
hist_ff <- x_ff[branch_count>1 & branch_count < 12,.(ff_N = .N),by=branch_count]

hist(x_failed[branch_count>1 & branch_count < 12]$branch_count,breaks=10)
hist_f <- x_failed[branch_count>1 & branch_count < 12,.(f_N = .N),by=branch_count]

summary(x_joined[,.N,by= .(l_git_trigger_commit)])
hist(x_joined[,.N,by= .(l_git_trigger_commit)][N>1 & N<12,,]$N, breaks=10)
table(x_joined[,.N,by= .(l_git_trigger_commit)][N>1,,]$N)

hist_a <- x_joined[,.N,by= .(l_git_trigger_commit)][N>1 & N<12,.(a_N = .N),by=N]

setkey(hist_a, N)
setkey(hist_f, branch_count)
setkey(hist_ff, branch_count)

x_af <- hist_a[hist_f, nomatch=0]
x_aff <- x_af[hist_ff, nomatch=0]

x_af$perc <- with(x_af,  f_N/a_N)

colnames(x_aff) <- c("branch_count","all_builds","failed_builds","failed_builds_after_branching")
dfm <- melt(x_aff[,c('branch_count','failed_builds_after_branching','failed_builds','all_builds')],id.vars = 1,
            value.name = "instance_count")

ggplot(dfm,aes(x = branch_count,y = instance_count)) + 
  geom_bar(aes(fill = variable),stat = "identity",position = "dodge") +
  scale_x_continuous(breaks=0:11) +
  scale_y_log10()

########################################

#basics
n_distinct(build_data[,get("gh_project_name")])
n_distinct(build_data[,get("tr_build_id")])

# List of all Maven projects to be used by plugin analyzer
write.csv(unique(build_data[tr_log_analyzer=='java-maven',get("gh_project_name")]),
          file = "../../results/all_maven_projects.csv",
          row.names=FALSE)

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

nrow(build_data[,.N,by="gh_project_name"])

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

df3 <- build_data[,head(.SD,1) , by = tr_build_id][,.N,by=.(gh_project_name,tr_status,gh_is_pr)][, `perc` := `N` / sum( `N` ) * 100,by=.(gh_project_name,gh_is_pr)]
head(df3[gh_project_name=="rails/rails"])
df3$tr_status <- as.factor(df3$tr_status)
df3$gh_is_pr <- as.factor(df3$gh_is_pr)

# Beanplot
beanplot(perc ~ gh_is_pr+tr_status, data = df3, ll = 0.02, na.rm = TRUE,
         main = "Percentage of outcomes in non-PR and PR builds", ylab = "Percentage", xlab = "Build Status", side = "both" ,
         border = NA, col = list(c("lightblue", "black"), c("purple", "black")), log="", bw="nrd0", ylim = c(1, 100))
legend("topleft", fill = c("lightblue", "purple"),
       legend = unique(df3$gh_is_pr))


setkey(df3,gh_is_pr,gh_project_name,tr_status)
df3_filled <- df3[CJ(unique(gh_is_pr), unique(gh_project_name), unique(tr_status))]

f <- df3_filled[tr_status=='canceled',]
wilcox.test(f[gh_is_pr=="FALSE",perc], f[gh_is_pr=="TRUE",perc], paired = TRUE)
cliff.delta(f[gh_is_pr=="FALSE",perc],f[gh_is_pr=="TRUE",perc])

f <- df3_filled[tr_status=='failed',]
wilcox.test(f[gh_is_pr=="FALSE",perc], f[gh_is_pr=="TRUE",perc], paired = TRUE)
cliff.delta(f[gh_is_pr=="FALSE",perc],f[gh_is_pr=="TRUE",perc])

f <- df3_filled[tr_status=='errored',]
wilcox.test(f[gh_is_pr=="FALSE",perc], f[gh_is_pr=="TRUE",perc], paired = TRUE)
cliff.delta(f[gh_is_pr=="FALSE",perc],f[gh_is_pr=="TRUE",perc])

f <- df3_filled[tr_status=='passed',]
wilcox.test(f[gh_is_pr=="FALSE",perc], f[gh_is_pr=="TRUE",perc], paired = TRUE)
cliff.delta(f[gh_is_pr=="FALSE",perc],f[gh_is_pr=="TRUE",perc])

setkey(failed_builds,gh_is_pr,gh_project_name)
failed_builds_filled <- failed_builds[CJ(unique(gh_is_pr), unique(gh_project_name))]
length(failed_builds_filled[gh_is_pr=="TRUE",perc])
length(failed_builds_filled[gh_is_pr=="FALSE",perc])
n_distinct(df3[,get("gh_project_name")])
wilcox.test(failed_builds_filled[gh_is_pr=="FALSE",perc], failed_builds_filled[gh_is_pr=="TRUE",perc], paired = TRUE)


# Beanplot
beanplot(N ~ gh_is_pr+tr_status, data = df3, ll = 0.02, na.rm = TRUE,
         main = "", ylab = "Percentage", side = "both" ,
         border = NA, col = list(c("lightblue", "black"), c("purple", "black")), log="y", bw="nrd0", ylim = c(1, 12000))
legend("topleft", fill = c("lightblue", "purple"),
       legend = unique(df3$gh_is_pr))



# In 13 instances, job failed but build passed for some unknown reason.
allow_failure_status[job_result=="1" & build_result=="0" & allow_failure==FALSE,.N,by=.(p_name,build_id)]
# In 2 instances, job errored but build passed for some unknown reason.
allow_failure_status[job_result=="2" & build_result=="0" & allow_failure==FALSE,.N,by=.(p_name,build_id)]

df3 <- allow_failure_status[,.N,by=.(job_result,allow_failure)][, `perc` := `N` / sum( `N` ) * 100,by='job_result']
df4 <- allow_failure_status[build_result=="0",.N,by=.(job_result,allow_failure)][, `perc` := `N` / sum( `N` ) * 100,by='job_result']
# 12% of passed builds have an ignored failure
length(unique(subset(allow_failure_status,build_result=='0' & job_result != '0')$build_id))

#How many ignored failed builds are there in passing builds
ignored_jobs <- allow_failure_status[build_result=='0' & job_result != '0' & allow_failure == TRUE,.N,by= .(build_id)][N<20,,]
hist(ignored_jobs$N, breaks=20, xlab="No. of ignored failed jobs", main="Ignored failed jobs in passing jobsets")

#What percentage of ignored failed builds are there in passing builds
hist(allow_failure_status[build_result=='0',.(perc=sum(job_result != '0' & allow_failure == TRUE)*100/.N),by=.(build_id)][perc>0,,]$perc,
     breaks=15, xlab="Percentage of ignored failed jobs", main="Ignored failed jobs in passing jobsets")

# (Results of jobs + Did developers silenced the failures) For all builds
maven_job_status <- fread("../../results/maven_build_status_analysis.csv", 
                              header=FALSE, 
                              sep = ";",
                              col.names = c("job_id","status","build_duration","missing_dependencies"))
summary(maven_job_status)
maven_job_status$status <- as.factor(maven_job_status$status)
maven_job_status[,.N,by=.(status)]
