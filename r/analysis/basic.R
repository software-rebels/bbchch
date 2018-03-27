#Load Libaries###########################

if(!require(data.table)){install.packages("data.table")}
if(!require(dplyr)){install.packages("dplyr")}
if(!require(ggplot2)){install.packages("ggplot2")}
if(!require(beanplot)){install.packages("beanplot")}
if(!require(effsize)){install.packages("effsize")}
if(!require(scales)){install.packages("scales")}
if(!require(colorRamps)){install.packages("colorRamps")}
if(!require(RColorBrewer)){install.packages("RColorBrewer")}
if(!require(ggthemes)){install.packages("ggthemes")}

#Loading raw data
build_data <- fread("../../travistorrent_8_2_2017.csv")

#Build Commit Graph ##################################

df_commit_graph <- unique(build_data[,c("tr_build_id", "git_prev_built_commit","git_trigger_commit","tr_status","gh_project_name","gh_build_started_at")])
df_commit_graph$git_trigger_commit <- substr(df_commit_graph$git_trigger_commit, 1, 8)
df_commit_graph$git_prev_built_commit <- substr(df_commit_graph$git_prev_built_commit, 1, 8)
n_distinct(df_commit_graph$git_trigger_commit)

DT=copy(df_commit_graph)
DT$git_trigger_commit <- as.factor(DT$git_trigger_commit)
setorder(DT,-tr_build_id)
DT_stats <- DT[,.N,by=git_trigger_commit]
problematic_commits <- DT_stats[N>1,,]$git_trigger_commit

problematic_builds <- DT[(git_trigger_commit %in% problematic_commits),.(tr_build_id),]
#Using write table instead of write csv to exclude column names
write.table(unique(problematic_builds),
            file = "../../results/problematic_builds.csv",
            sep=",",
            row.names=FALSE,
            col.names = FALSE)

event_types <- fread("../../results/event_type.csv")
colnames(event_types)<- c("build_id","event_type")

setkey(event_types, build_id)
setkey(problematic_builds, tr_build_id)

common_builds <- event_types[problematic_builds, nomatch=0]

event_types <- fread("../../results/event_type_all.csv")
colnames(event_types)<- c("build_id","event_type","tag")
head(event_types)
n_distinct(event_types[event_type %in% c("pull_request"),.(build_id),])
event_types[,.N,by=event_type]
setkey(event_types,build_id)
setkey(DT,tr_build_id)
DT <- event_types[DT]

DT[build_id=='155423746',,]
DT[git_trigger_commit=='2c717421']
DT[is.na(tag),tag:='null']
temp <- DT[!(event_type %in% c("cron","api")),,]
#676414
nrow(temp)
DT <- temp[tag=='null',,]
nrow(DT)
#656677

setorder(DT, build_id)

head(DT)
#should fix this to get the correct commit
DT <- DT[, head(.SD, 1), keyby = .(git_trigger_commit)]
n_distinct(DT$git_trigger_commit)

DT <- DT[, !c("event_type","tag"), with=FALSE]

#Using write table instead of write csv to exclude column names
write.table(DT,
          file = "../../results/commit_graph.csv",
          sep=",",
          row.names=FALSE,
          col.names = FALSE)

#Sequence Counts Analysis for passively ignored #############################################
seq_count <- fread("../../results/seq_counts_full.csv")
colnames(seq_count) <- c("commit","project_name", "chain_length","broken_time","start_build","end_build")
seq_count$project_name <- as.factor(seq_count$project_name)
seq_count$commit <- as.factor(seq_count$commit)
seq_count$broken_time <- seq_count$broken_time
summary(seq_count)

#In 13,102 builds that were not immediately fixed, several commits appear before the fix does.
nrow(seq_count[chain_length>1])
n_distinct(seq_count[chain_length>1]$project_name)
n_distinct(seq_count[broken_time>60 & chain_length>1]$project_name)
seq_count <- seq_count[broken_time>60 & chain_length>1]

summary(seq_count[,.N,by=.(project_name,commit)])
proj_with_multiple_seqs <- unique(seq_count[,.N,by=project_name][N>5,,]$project_name)

seq_count$broken_time <- seq_count$broken_time/60

seq_count_median <- seq_count[, lapply(.SD, median), by=.(project_name), .SDcols=c("broken_time","chain_length")]

#setorder(seq_count,-broken_time)
#seq_count_max_time <- seq_count[, head(.SD, 1), keyby = .(project_name)]
seq_count_max <- seq_count[, lapply(.SD, max), by=.(project_name), .SDcols=c("broken_time","chain_length")]

summary(seq_count_max)
n_distinct(seq_count_max$project_name)
summary(seq_count_max[broken_time>24,,])
n_distinct(seq_count_max[broken_time>24,,]$project_name)
summary(seq_count_max[broken_time>24*7,,])
n_distinct(seq_count_max[broken_time>24*7,,]$project_name)
summary(seq_count_max[broken_time>24*30,,])
n_distinct(seq_count_max[broken_time>24*30,,]$project_name)
summary(seq_count_max[broken_time>24*365,,])
n_distinct(seq_count_max[broken_time>24*365,,]$project_name)

# Median Range 2 - 26
summary(seq_count_median[(project_name %in% seq_count_max[broken_time>24,,]$project_name)])
# Median Range 2 - 26
summary(seq_count_median[(project_name %in% seq_count_max[broken_time>24*7,,]$project_name)])
# Median Range 2 - 12.50
summary(seq_count_median[(project_name %in% seq_count_max[broken_time>24*30,,]$project_name)])
# Median Range 2 - 12.50
summary(seq_count_median[(project_name %in% seq_count_max[broken_time>24*365,,]$project_name)])
summary(seq_count_median$chain_length)
#setorder(seq_count,broken_time)
#seq_count_min_time <- seq_count[, head(.SD, 1), keyby = .(project_name)]
seq_count_min <- seq_count[, lapply(.SD, min), by=.(project_name), .SDcols=c("broken_time","chain_length")]

seq_count_median$value_type<-as.factor("median")
seq_count_max$value_type<-as.factor("max")
seq_count_min$value_type<-as.factor("min")

summary(seq_count)


# head(seq_count)
# seq_count <- seq_count[,Med_cl:=NULL]
# setorder(seq_count,-chain_length)
# seq_count[, Max_cl:= max(chain_length), project_name]
# seq_count[, Med_cl= as.numeric(median(chain_length)), project_name]
# seq_count$project_name <- factor(seq_count$project_name , levels=unique(seq_count$project_name[order(-seq_count$Max_cl)]), ordered=TRUE)
# head(seq_count)
# theme_set(theme_tufte())
# g <- ggplot(seq_count, aes(project_name, chain_length))
# g + geom_tufteboxplot() + 
#   theme(axis.text.x = element_text(angle=65, vjust=0.6)) + 
#   scale_y_log10() + 
#   labs(title="Failure Sequence Length grouped by Project Name",
#        x="Project Name",
#        y="Failure Sequence Length")
# 
# g <- ggplot(seq_count, aes(project_name, broken_time))
# g + geom_tufteboxplot() + 
#   theme(axis.text.x = element_text(angle=65, vjust=0.6)) + 
#   labs(title="Failure Sequence Length grouped by Project Name",
#        x="Project Name",
#        y="Broken Time")
# 

# broken time graph######

setorder(seq_count_min,broken_time)
seq_count_min$point_colour<-1:length(seq_count_min$project_name)
colors = seq_count_min[,.(project_name,point_colour)]
seq_count_min[,c('point_colour'):=NULL]
setkey(colors,project_name)
setkey(seq_count_min,project_name)
setkey(seq_count_median,project_name)
setkey(seq_count_max,project_name)

seq_count_min <- seq_count_min[colors,nomatch=0]
seq_count_median <- seq_count_median[colors,nomatch=0]
seq_count_max <- seq_count_max[colors,nomatch=0]
full_df <- rbind(seq_count_max,seq_count_median)

#we only consider projects with at least 5 sequences for the graph
full_df <- full_df[(project_name %in% proj_with_multiple_seqs)]
# ggplot(data=full_df, aes(x=value_type, group=point_colour, y=broken_time,  color=point_colour)) +
#   geom_point(alpha=0.2, size=3)+
#   theme_bw()+
#   scale_y_log10(breaks=c(1,1e1,1e2,1e3,1e4,1e5,1e6))+
#   scale_colour_gradient2(low="red", high="blue",
#                          limits=c(1, 1022), midpoint=1022/2, mid="yellow")+
#   theme(legend.position="none")
full_df$project_name <- factor(full_df$project_name , levels=unique(full_df$project_name[order(-full_df$broken_time)]), ordered=TRUE)
# full_df$value_type <- factor(full_df$value_type, levels=c('min','max','median'))
# full_df$broken_time <- full_df$broken_time/60

theme_set(theme_few())
g <- ggplot(full_df, aes(x=project_name,y=broken_time,fill=value_type)) + 
  geom_bar(stat="identity", position = "identity", alpha=1)+
  # scale_fill_brewer(palette="Greys", name="Distribution", direction = -1) +
  scale_fill_manual(values=c("black","lightgrey"))+
  # scale_fill_colorblind()+
  scale_y_continuous(name="Broken Time (in log scale)", 
                     breaks=c(1,24,24*7,24*30,24*365),
                     labels=c("1 Hour","1 Day","1 Week", "1 Month","1 Year"),
                              trans="log10")+
  # scale_y_log10("Broken Time (in logscale)")+
  theme(legend.position = c(0.8, 0.8),
        legend.title = element_blank(),
        legend.background = element_rect(size=0.25,colour ="black"),
        # axis.title.x=element_blank(),
        # axis.text.x=element_blank(),
        # axis.ticks.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank(),
        axis.text=element_text(size=8),
        axis.title=element_text(size=8),
        legend.text=element_text(size=8)
  )
g+coord_flip()+
  geom_hline(yintercept = 24, size = 0.5, linetype=2, color="black")+
  geom_hline(yintercept = 24*7, size = 0.5, linetype=2, color ="grey")+
  geom_hline(yintercept = 24*30, size = 0.5, linetype=2, color ="grey")+
  geom_hline(yintercept = 24*365, size = 0.5, linetype=2, color ="grey")
  # annotate(geom = "text", x = 18, y = 24, label = "1 Day", vjust=-1, color = "red", angle = -90)
ggsave("broken_time_all.pdf", width = 4, height = 2.5)


full_df[which.max(full_df$broken_time),]
seq_count[project_name=='orbeon/orbeon-forms' & broken_time>10145*60,,]
build_data[git_trigger_commit %like% "^7ef1ae5a",,]$tr_build_id

n_distinct(full_df$project_name)

full_df[which.max(full_df$chain_length),]
seq_count[project_name=='orbeon/orbeon-forms' & chain_length==485,,]

10145/24

#chain length graph ##########################

full_df$project_name <- factor(full_df$project_name , levels=unique(full_df$project_name[order(-full_df$chain_length)]), ordered=TRUE)


theme_set(theme_few())
ggplot(full_df, aes(x=project_name,y=chain_length,fill=value_type)) + 
  geom_bar(stat="identity", position = "identity", alpha=1)+
  # scale_fill_brewer(palette="Greys", name="Distribution", direction = -1) +
  scale_fill_manual(values=c("black","lightgrey"))+
  # scale_fill_colorblind()+
  scale_y_log10("Length of failed build sequence")+
  theme(legend.position = c(0.8, 0.8),
        legend.title = element_blank(),
        legend.background = element_rect(size=0.25,colour ="black"),
        axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.text=element_text(size=8),
        axis.title=element_text(size=8),
        legend.text=element_text(size=8)
  )
ggsave("seq_length_all.pdf", width = 4, height = 2.5)


# setorder(seq_count_min,chain_length)
# seq_count_min_time$point_colour<-1:length(seq_count_min$project_name)
# colors = seq_count_min[,.(project_name,point_colour)]
# seq_count_min[,c('point_colour'):=NULL]
# seq_count_max[,c('point_colour'):=NULL]
# seq_count_median[,c('point_colour'):=NULL]
# setkey(colors,project_name)
# setkey(seq_count_min,project_name)
# setkey(seq_count_median,project_name)
# setkey(seq_count_max,project_name)
# 
# seq_count_min <- seq_count_min[colors,nomatch=0]
# seq_count_median <- seq_count_median[colors,nomatch=0]
# seq_count_max <- seq_count_max[colors,nomatch=0]
# 
# full_df <- rbind(seq_count_min,seq_count_median,seq_count_max)
# 
# ggplot(data=full_df, aes(x=value_type, group=point_colour, y=chain_length,  color=point_colour)) +
#   geom_point(alpha=0.5, size=3)+
#   geom_line()+
#   theme_bw()+
#   scale_y_log10()+
#   scale_colour_gradient2(low="red", high="blue",
#                          limits=c(1, 1022), midpoint=1022/2, mid="yellow")+
#   theme(legend.position="none")
# 
# head(full_df)


#parralel branches vs breakge#############################################
lf <- unique(build_data[,c("tr_build_id", "git_prev_built_commit","git_trigger_commit","tr_status")])
lf <- lf[, head(.SD, 1), keyby = .(git_trigger_commit)]
rf <- copy(lf)
colnames(lf) <- paste("l", colnames(lf), sep = "_")
colnames(rf) <- paste("r", colnames(rf), sep = "_")

setkey(lf, l_git_trigger_commit)
setkey(rf, r_git_prev_built_commit)

x_joined <- lf[rf, nomatch=0]

x_joined[,branch_count := .N,by= .(l_git_trigger_commit)]

#isolating examples
x_joined[l_tr_status!="passed" & r_tr_status!="passed" & branch_count > 1]

x_failed <- x_joined[l_tr_status!="passed", head(.SD,1) , by = l_git_trigger_commit]

x_ff <- x_joined[l_tr_status!="passed" & r_tr_status!="passed", head(.SD,1) , by = l_git_trigger_commit]

# Checking how it looks 
hist(x_ff[branch_count>1]$branch_count,breaks=10)
hist(x_failed[branch_count>1]$branch_count,breaks=10)

hist_ff <- x_ff[branch_count>1,.(ff_N = .N),by=branch_count]
hist_f <- x_failed[branch_count>1,.(f_N = .N),by=branch_count]

hist_a <- x_joined[,.N,by= .(l_git_trigger_commit)][,.(a_N = .N),by=N]

setkey(hist_a, N)
setkey(hist_f, branch_count)
setkey(hist_ff, branch_count)

x_af <- hist_a[hist_f, nomatch=0]
x_aff <- x_af[hist_ff, nomatch=0]

#Many breakages persist after branching
sum(x_aff$all_builds)
sum(x_aff$failed_builds)
sum(x_aff$failed_builds_after_branching)
sum(x_aff$failed_builds)/sum(x_aff$all_builds)
sum(x_aff$failed_builds_after_branching)/sum(x_aff$failed_builds)

x_aff$perc_f <- with(x_af,  f_N*100/a_N)
x_aff$perc_ff <- with(x_aff,  ff_N*100/a_N)

#Last 2 columns should be percentages and should not have spaces. But this is easier than struggling to change legend labels (Just R things)
colnames(x_aff) <- c("branch_count","all_builds","failed_builds","failed_builds_after_branching","Failed","Failed After Branching")
dfm <- melt(x_aff[,c('branch_count','Failed After Branching','Failed')],id.vars = 1,
            value.name = "Percentage")

theme_set(theme_bw())
(p = ggplot(dfm,aes(x = branch_count,y = Percentage/100)) + 
  geom_bar(aes(fill = variable),stat = "identity",position = "identity", color="black", alpha=.3) +
  labs(x="# of Branches", y="Percentage of Builds", fill="Type of Builds:")+
  scale_y_continuous(labels = scales::percent)+
  theme_bw()+
  scale_x_continuous(breaks=0:12) +
  theme(axis.text=element_text(size=8),
        axis.title=element_text(size=8),
        legend.title=element_text(size=8),
        legend.text=element_text(size=8),
        legend.background = element_rect(size=0.25, linetype="solid",colour ="black"),
        legend.position="bottom"
        ))
(p = p + scale_fill_grey(start = 0, end = .9))

ggsave("parallel_branches_vs_build_failures_perc.pdf", width = 4, height = 3)

##importing/exporting basic stats for further analysis######################################

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
write.csv(unique(build_data[tr_status!="passed",
                            get("gh_project_name")]), 
          file = "../../results/projects_with_failed_builds.csv",
          row.names=FALSE)
#1276 vs 1252
#n_distinct(build_data[tr_status!="passed",get("gh_project_name")])

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

#pull requests and breakage###############################################################################

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
         main =  NULL, ylab = "Percentage", xlab = "Build Status", side = "both" ,
         border = NA, col = list(c("lightgrey", "black"), c("darkgrey", "black")), log="", bw="nrd0", ylim = c(1, 100))
legend("topleft", fill = c("lightgrey", "darkgrey"),
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


#core team member vs breakage################################################################

# Doing the same tests to decide being a core team member changes anything

# Percentage of builds by core team member
df1 <- build_data[, head(.SD,1) , by = tr_build_id][,.N,by="gh_by_core_team_member"]
df1$Perc <- df1$N / sum(df1$N) * 100

# Percentage of build status based on pull requests or not
df2 <- build_data[, head(.SD,1) , by = tr_build_id][,.N,by=.(tr_status,gh_is_pr)][, `perc` := `N` / sum( `N` ) * 100,by='gh_by_core_team_member']
#Result2: If it's a PR, build passing rate is slightly higher.

df3 <- build_data[,head(.SD,1) , by = tr_build_id][,.N,by=.(gh_project_name,tr_status,gh_by_core_team_member)][, `perc` := `N` / sum( `N` ) * 100,by=.(gh_project_name,gh_by_core_team_member)]
head(df3[gh_project_name=="rails/rails"])
df3$tr_status <- as.factor(df3$tr_status)
df3$gh_by_core_team_member <- as.factor(df3$gh_by_core_team_member)

# Beanplot
beanplot(perc ~ gh_by_core_team_member+tr_status, data = df3, ll = 0.02, na.rm = TRUE,
         main =  NULL, ylab = "Percentage", xlab = "Build Status", side = "both" ,
         border = NA, col = list(c("lightgrey", "black"), c("darkgrey", "black")), log="", bw="nrd0", ylim = c(1, 100))
legend("topleft", fill = c("lightgrey", "darkgrey"),
       legend = unique(df3$gh_by_core_team_member))


setkey(df3,gh_by_core_team_member,gh_project_name,tr_status)
df3_filled <- df3[CJ(unique(gh_by_core_team_member), unique(gh_project_name), unique(tr_status))]

f <- df3_filled[tr_status=='canceled',]
wilcox.test(f[gh_by_core_team_member=="FALSE",perc], f[gh_by_core_team_member=="TRUE",perc], paired = TRUE)
cliff.delta(f[gh_by_core_team_member=="FALSE",perc],f[gh_by_core_team_member=="TRUE",perc])

f <- df3_filled[tr_status=='failed',]
wilcox.test(f[gh_by_core_team_member=="FALSE",perc], f[gh_by_core_team_member=="TRUE",perc], paired = TRUE)
cliff.delta(f[gh_by_core_team_member=="FALSE",perc],f[gh_by_core_team_member=="TRUE",perc])

f <- df3_filled[tr_status=='errored',]
wilcox.test(f[gh_by_core_team_member=="FALSE",perc], f[gh_by_core_team_member=="TRUE",perc], paired = TRUE)
cliff.delta(f[gh_by_core_team_member=="FALSE",perc],f[gh_by_core_team_member=="TRUE",perc])

f <- df3_filled[tr_status=='passed',]
wilcox.test(f[gh_by_core_team_member=="FALSE",perc], f[gh_by_core_team_member=="TRUE",perc], paired = TRUE)
cliff.delta(f[gh_by_core_team_member=="FALSE",perc],f[gh_by_core_team_member=="TRUE",perc])

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

#ignored failed jobs #####################################################################################

# In 13 instances, job failed but build passed for some unknown reason.
allow_failure_status[job_result=="1" & build_result=="0" & allow_failure==FALSE,.N,by=.(p_name,build_id)]
# In 2 instances, job errored but build passed for some unknown reason.
allow_failure_status[job_result=="2" & build_result=="0" & allow_failure==FALSE,.N,by=.(p_name,build_id)]

df3 <- allow_failure_status[,.N,by=.(job_result,allow_failure)][, `perc` := `N` / sum( `N` ) * 100,by='job_result']
df4 <- allow_failure_status[build_result=="0",.N,by=.(job_result,allow_failure)][, `perc` := `N` / sum( `N` ) * 100,by='job_result']
# 12% of passed builds have an ignored failure
count_builds_passing_with_active_faioures = length(unique(subset(allow_failure_status,build_result=='0' & job_result != '0')$build_id))
count_all_builds_passing = length(unique(subset(allow_failure_status,build_result=='0')$build_id))
count_builds_passing_with_active_faioures/count_all_builds_passing

#How many ignored failed builds are there in passing builds
ignored_jobs <- allow_failure_status[build_result=='0' & job_result != '0' & allow_failure == TRUE,.N,by= .(build_id)][N<20,,]
hist(ignored_jobs$N, 
     breaks=20, 
     xlab="No. of ignored failed jobs", 
     main="Ignored failed jobs in passing jobsets",
     right = FALSE,
     labels = TRUE)

table(ignored_jobs$N)


p <- ggplot(ignored_jobs, aes(x=N))
p+ geom_histogram(binwidth = 1, colour = "black", fill = "white")+
  labs(y = "Frequency",
       x = "Number of Ignored Failed Jobs")+
  scale_x_continuous()+
   theme_bw()+ theme(
    axis.text=element_text(size=8),
    axis.title=element_text(size=8),
    legend.text=element_text(size=8)
  )
ggsave("ignored_failed_jobs.pdf", width = 4, height = 2.5)

#What percentage of ignored failed builds are there in passing builds
hist(allow_failure_status[build_result=='0',.(perc=sum(job_result != '0' & allow_failure == TRUE)*100/.N),by=.(build_id)][perc>0,,]$perc,
     breaks=15, xlab="Percentage of ignored failed jobs", main=NULL)

p <- ggplot(allow_failure_status[build_result=='0',.(perc=sum(job_result != '0' & allow_failure == TRUE)*100/.N),by=.(build_id)][perc>0,,], 
            aes(x=perc))
p+ geom_histogram(binwidth = 10, colour = "black", fill = "white")+
  labs(y = "Frequency",
       x = "Percentage of Ignored Failed Jobs")+
  scale_x_continuous(breaks = seq(0, 90, by = 10))+
  theme_bw()+ theme(
    axis.text=element_text(size=8),
    axis.title=element_text(size=8),
    legend.text=element_text(size=8)
  )
ggsave("percentage_ignored_failed_jobs.pdf", width = 4, height = 2.5)


# Signal-to-Noise Ratio Calculation ##############################
# Singal to noise ratio = (true build failures+true build successes)/(failse build failures+false build successes)

head(allow_failure_status)
unique(allow_failure_status[build_result!='0',.(p_name),])
#1494
snr_results = data.table(unique(build_data[tr_status!="passed",.(gh_project_name)]))
#1276
setkey(snr_results,gh_project_name)

all_passes = unique(build_data[tr_status=='passed',.(gh_project_name,tr_build_id),])
all_passes_count = all_passes[,.(ap=.N),by=.(gh_project_name)]
false_passes = unique(allow_failure_status[build_result=='0' & job_result != '0' & allow_failure == TRUE,.(p_name,build_id),])
false_passes_count = false_passes[,.(fp=.N),by=.(p_name)]
all_failures = unique(build_data[tr_status!='passed',.(gh_project_name,tr_build_id),])
all_failures_count = all_failures[,.(af=.N),by=.(gh_project_name)]

setkey(all_passes_count,gh_project_name)
setkey(false_passes_count,p_name)
setkey(all_failures_count,gh_project_name)

#this is to clean up residual from a previous run. not needed for computed ones ie tp
snr_results[,c('ap'):=NULL]
snr_results[,c('af'):=NULL]
snr_results[,c('fp'):=NULL]
# leftjoin Y[x]
snr_results <- all_passes_count[snr_results]
snr_results <- false_passes_count[snr_results]
snr_results <- all_failures_count[snr_results]
snr_results[is.na(snr_results)] <- 0;
#can use 'within' also here
snr_results$tp <- with(snr_results, ap-fp)
summary(snr_results)
summary(seq_count)
seq_count <- seq_count[,bcount:=.N,by=.(project_name,commit)]
max(seq_count$chain_length)
#plot begins (ignoring branches. bcount>0)
plot_snr <- function(j) {
  snr_global <- NULL
  threshold_b <- j
  # This is not changing based on threshold
  false_failures_count <-seq_count[bcount > threshold_b, sum(chain_length), by = project_name]
  names(false_failures_count) <- c("project_name", "ff")
  setkey(false_failures_count, project_name)
  #this is to clean up residual from a previous run. not needed for computed ones ie tp
  snr_results[, c('ff') := NULL]
  snr_results <- false_failures_count[snr_results]
  
  for (i in 1:max(seq_count$chain_length)) {
    threshold <- i
    
    false_failures_detected_count <-seq_count[chain_length > threshold & bcount > threshold_b, sum(chain_length), by = project_name]
    names(false_failures_detected_count) <- c("project_name", "ffd")
    setkey(false_failures_detected_count, project_name)
    
    
    
    #this is to clean up residual from a previous run. not needed for computed ones ie tp
    snr_results[, c('ffd') := NULL]
    snr_results <- false_failures_detected_count[snr_results]
    snr_results[is.na(snr_results)] <- 0
    
    snr_results$tf <- with(snr_results, af - ff)
    snr_results$ffu <- with(snr_results, ff-ffd)
    global_sums <-
      snr_results[, lapply(.SD, sum), .SDcols = -c("project_name")]
    snr <- with(global_sums, (tf + tp ) / (fp + ffu))
    nobs <- with(global_sums, (tf + tp + ffu+ fp))
    print(nobs)
    snr_global = rbind(snr_global, data.frame(threshold, snr,nobs))
  }
  summary(snr_global)
  # ggplot(data=snr_global, aes(x=threshold, y=snr)) +
  #   geom_line()+theme_bw()+labs(x = "Build Failure Sequence Length Threshold", y="Signal-to-Noise Ratio")
  
  p <- ggplot(snr_global, aes(x = threshold))
  p <- p + geom_line(aes(y = snr, colour = "SNR"))
  
  # adding the relative humidity data, transformed to match roughly the range of the temperature
  p <- p + geom_line(aes(y = nobs/80000, colour = "Observations"))
  
  # now adding the secondary axis, following the example in the help file ?scale_y_continuous
  # and, very important, reverting the above transformation
  p <- p + scale_y_continuous(sec.axis = sec_axis(~.*80000, name = "Observations"))
  
  # modifying colours and theme options
  p <- p + scale_colour_manual(values = c("blue", "red"))
  p <- p + labs(y = "Signal-to-Noise Ratio",
                x = "Build Failure Sequence Length Threshold",
                colour = "Parameter")
  p <- p + theme(legend.position = c(0.8, 0.9)) + theme_bw()
  p
}

#SNR for all cases
plot_snr(0)

#SNR only for branched cases
plot_snr(1)


plot_everything <- function(j) {
  snr_global <- NULL
  threshold_b <- j

  
  for (i in 1:max(seq_count$chain_length)) {
    threshold <- i
    
    false_failures_detected_count <-seq_count[chain_length > threshold & bcount > threshold_b, sum(chain_length), by = project_name]
    names(false_failures_detected_count) <- c("project_name", "ff")
    setkey(false_failures_detected_count, project_name)
    
    #this is to clean up residual from a previous run. not needed for computed ones ie tp
    snr_results[, c('ff') := NULL]
    snr_results <- false_failures_detected_count[snr_results]
    snr_results[is.na(snr_results)] <- 0
    
    snr_results$tf <- with(snr_results, af - ff)
    global_sums <-
      snr_results[, lapply(.SD, sum), .SDcols = -c("project_name")]
    snr <- with(global_sums, (tf + tp ) / (fp + ff))
    nobs <- with(global_sums, (tf + tp))
    print(global_sums$ff)
    snr_global = rbind(snr_global, data.frame(threshold, snr,nobs,threshold_b))
  }
  # ggplot(data=snr_global, aes(x=threshold, y=snr)) +
  #   geom_line()+theme_bw()+labs(x = "Build Failure Sequence Length Threshold", y="Signal-to-Noise Ratio")
  # 
  return(snr_global)

}

#SNR for all cases
result1 <- plot_everything(0)
result2 <- plot_everything(1)
res <- rbind(result1,result2)
res$threshold_b <- as.factor(res$threshold_b)
ggplot(data=res, aes(x=threshold, y=snr, group=threshold_b)) +
  geom_line()+theme_bw()+labs(x = "Build Failure Sequence Length Threshold", y="Signal-to-Noise Ratio")

p <- ggplot(res, aes(x = threshold))
p <- p + geom_line(aes(y = snr, colour = threshold_b,group=threshold_b))
# adding the relative humidity data, transformed to match roughly the range of the temperature
# p <- p + geom_line(aes(y = nobs/80000, colour =threshold_b,group=threshold_b), linetype="dashed") + scale_x_log10()
# # now adding the secondary axis, following the example in the help file ?scale_y_continuous
# # and, very important, reverting the above transformation
# p <- p + scale_y_continuous(sec.axis = sec_axis(~.*80000, name = "Observations")) + scale_x_log10()
# # modifying colours and theme options
p <- p + scale_colour_manual(values = c("darkgrey", "black"),labels = c("Overall", "Branches-only"))
p <- p + labs(y = "Signal-to-Noise Ratio",
              x = expression(paste("Build Failure Sequence Length Threshold (",t[c],")")),
              colour = "Parameter")
p <- p + theme_bw() +
  theme(legend.justification = c(1, 0), legend.position = c(1, 0), 
        legend.background = element_rect(size=0.5, linetype="solid", colour ="black"),
        axis.text=element_text(size=8),
        axis.title=element_text(size=8),
        legend.text=element_text(size=8)) 
p
ggsave("snr.pdf", width = 4, height = 2.5)








#Incomplete ##########

# (Results of jobs + Did developers silenced the failures) For all builds
maven_job_status <- fread("../../results/maven_build_status_analysis.csv", 
                              header=FALSE, 
                              sep = ";",
                              col.names = c("job_id","status","build_duration","missing_dependencies"))
summary(maven_job_status)
maven_job_status$status <- as.factor(maven_job_status$status)
maven_job_status[,.N,by=.(status)]

