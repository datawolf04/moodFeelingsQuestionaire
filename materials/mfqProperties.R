############################################
# mfqProperties.R
#
# Author: SFW
############################################

library(tidyverse)

scores <- data.frame(
  'Assessment'= c(rep('MFQ-Child-Long',2),rep('MFQ-Parent-Long',2),rep('MFQ-Child-Short',2),rep('MFQ-Parent-Short',2)),
  'Group'= rep(c('Pediatric', 'Psychiatric'),4),
  'mu'= c(15,24,15,26,4.6,7.1,2.1,5.7),
  'sigma' = c(11,14,11,14,4.6,5.2,3.2,4.8)
)

cutoffs <- data.frame(
  'Assessment'= c(rep('MFQ-Child-Long',3),rep('MFQ-Parent-Long',3),rep('MFQ-Child-Short',3),rep('MFQ-Parent-Short',2)),
  'Range'= c(rep(c('Normal','Elevated','High'),3),'Normal','High'),
  'Low'= c(0,27,30,0,27,29,0,8,12,0,11),
  'High' = c(27,30,66,27,29,28,8,12,26,11,26)
)

scorePlot <- function(ptScore,assessmentName){
  plotScores <- scores |> filter(Assessment==assessmentName) |> select(!Assessment) |> 
    mutate(Group = fct_rev(Group))
  plotCutoffs <- cutoffs |> filter(Assessment==assessmentName)

  # 2. Generate a grid of X values to calculate densities manually
  xmax = max(plotCutoffs$High)
  x_values <- seq(0, xmax, length.out = 100)

  # 3. Create a combined data frame with densities
  plot_data <- pmap_dfr(plotScores, function(Group, mu, sigma) {
    data.frame(
      x = x_values,
      density = dnorm(x_values, mean = mu, sd = sigma),
      grp = Group
    )
  })

  del = -0.005
  if(assessmentName=='MFQ-Parent-Short'){
    rangeCmap = c('#00ffc83f','#ff000063')
  } else {
    rangeCmap = c('#00ffc83f','#1916d434','#ff000063')
  }
    
  # 4. Plot the pre-calculated densities
  ggplot(plot_data) +
    geom_vline(aes(xintercept=ptScore),linetype='dashed',color='#000000') +
    geom_line(aes(x = x, y = density, color = grp), linewidth = 1) + 
    geom_area(aes(x = x, y = density, fill = grp), position = 'identity', alpha=0.25) +
    labs(x="Score",y="",color="", fill="", title=assessmentName) +
    theme_minimal() + 
    theme(
      legend.position="inside",legend.position.inside=c(0.9,0.9),
      axis.text.y = element_blank()) +
    geom_text(data = plotCutoffs,
      mapping = aes(x = (Low+High)/2, y=del, label=Range), 
      show.legend = FALSE) +
    geom_segment(
      aes(x=Low, xend=High, y=del), plotCutoffs, color=rangeCmap,
      linewidth=5) 
}

# scorePlot(13, "MFQ-Child-Short")
# scorePlot(15, "MFQ-Child-Long")
# scorePlot(15, "MFQ-Parent-Short")
# scorePlot(15, "MFQ-Parent-Long")

