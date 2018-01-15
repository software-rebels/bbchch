# Import Library
if(!require(beanplot)){install.packages("beanplot")}

# Import data
desLen <- read.csv(
    file = "desLen_4projects.csv", sep=',', header=T)
desLen$project <- factor(desLen$project, levels = c("OpenStack", "AOSP", "LibreOffice", "Eclipse"))

# Beanplot
beanplot(length ~ weight+project, data = desLen[which(desLen$length>0),], ll = 0, na.rm = TRUE,
         main = "", ylab = "Length", side = "both" ,
         border = NA, col = list(c("lightblue", "white"), c("purple", "white")), log="y", bw="nrd0", ylim = c(1, 500))
legend("topleft", fill = c("lightblue", "purple"),
       legend = c("a", "b"))