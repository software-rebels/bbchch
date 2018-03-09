if(!require(hexbin)){install.packages("hexbin")}
ps_df <- fread("../../results/passively_skipped.csv")
colnames(ps_df) <- c("commit","branch_count", "commits_until_fixed")
length(ps_df$commits_until_fixed)
hexbinplot(commits_until_fixed ~ branch_count, data=subset(ps_df, commits_until_fixed>1), aspect=1, )
hexbinplot(commits_until_fixed ~ branch_count, data=ps_df, aspect=1)+theme(text = element_text(size=16))
