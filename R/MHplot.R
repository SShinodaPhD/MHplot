MHplot <- function(mat, legend = FALSE){
  alp <- 1/10^4	#Haldane prior
  N <- sum(mat)
  R <- nrow(mat)

  pmat <- mat/N
  posmat <- matrix(0, R, R)
  for(i in 1:R){
    for(j in 1:R){
      posmat[i,j] <- (mat[i,j] + alp)/(N + alp*R^2)
    }
  }

  G1 <- G2 <- posG1 <- posG2 <- numeric(R-1)
  for(i in 1:(R-1)){
    for(s in 1:i){
      for(t in (i+1):R){
        G1[i] <- G1[i] + pmat[s,t]
        posG1[i] <- posG1[i] + posmat[s,t]
      }
    }
    for(s in (i+1):R){
      for(t in 1:i){
        G2[i] <- G2[i] + pmat[s,t]
        posG2[i] <- posG2[i] + posmat[s,t]
      }
    }
  }
  Gc1 <- G1/(G1 + G2)
  Gc2 <- G2/(G1 + G2)
  posGc1 <- posG1/(posG1 + posG2)
  posGc2 <- posG2/(posG1 + posG2)
  Delta <- sum(G1 + G2)
  posDelta <- sum(posG1 + posG2)
  Ga1 <- G1/Delta
  Ga2 <- G2/Delta

  gamma <- posA <- posB <- numeric(R-1)
  GAMMA <- 0
  for(i in 1:(R-1)){
    nu1 <- sqrt(Gc1[i])-sqrt(1/2)
    nu2 <- sqrt(Gc2[i])-sqrt(1/2)
    posnu1 <- sqrt(posGc1[i])-sqrt(1/2)
    posnu2 <- sqrt(posGc2[i])-sqrt(1/2)

    gamma[i] <- ( (2+sqrt(2))/2 * ( nu1^2 + nu2^2 ) )^(1/2)
    GAMMA <- GAMMA + (Ga1[i]+Ga2[i])*gamma[i]

    posC <- posnu1^2 + posnu2^2
    posA[i] <- 1/(2*sqrt(posC))*(2*posC + posnu1[i]*posGc2[i]/sqrt(posGc1[i]) - posnu2[i]*sqrt(posGc2[i]) )
    posB[i] <- 1/(2*sqrt(posC))*(2*posC - posnu1[i]*sqrt(posGc1[i]) + posnu2[i]*posGc1[i]/sqrt(posGc2[i]) )
  }

  varGAMMA <- 0
  for(k in 1:(R-1)){
    for(l in (k+1):R){
      Dkl <- Dlk <- 0
      for(i in 1:(R-1)){
        if( k <= i & l >= i +1){
          Dkl <- Dkl + 1/posDelta*sqrt((2+sqrt(2))/2) * posA[i]
          Dlk <- Dlk + 1/posDelta*sqrt((2+sqrt(2))/2) * posB[i]
        }
      }
      Dkl <- Dkl - (l-k)/posDelta*GAMMA
      Dlk <- Dlk - (l-k)/posDelta*GAMMA
      varGAMMA <- varGAMMA + posmat[k,l]*Dkl^2 + posmat[l,k]*Dlk^2
    }
  }
  seGAMMA <- sqrt(varGAMMA/N)
  CIl <- GAMMA - qnorm(0.975)*seGAMMA
  CIu <- GAMMA + qnorm(0.975)*seGAMMA

  size <- Ga1 +Ga2
  modsize <- size*20	#modified point size
  tmp01 <- tibble(Gc1, Gc2, modsize, gamma) %>% round(3) %>% mutate(flg=case_when(Gc1 < Gc2 ~ "0", Gc1 >= Gc2 ~ "1"))

  nr <- R-1
  tmp02 <- list()
  for(i in 1:nr){
    ssize <- tmp01$modsize[i]
    scolor <- "red"
    if(tmp01$flg[i]=="1") scolor <- "blue"

    tmp03 <- tmp01[i,] %>% ggplot(aes(x=Gc1,y=Gc2)) + geom_point(shape=21, size=ssize, color=scolor, fill=scolor, alpha=0.2) +
      geom_segment(x=0,y=1,xend=1/2,yend=1/2,color='red',linewidth=0.01,linetype=2) + geom_segment(x=1/2,y=1/2,xend=1,yend=0,color='blue',linewidth=0.01,linetype=2) +
      geom_text(aes(x=0.65, y=0.75,label=gamma), size=4, color=scolor) +
      theme_void() + theme(panel.border = element_rect(linewidth=0.5)) +
      scale_y_continuous(breaks=c(0, 0.25, 0.5, 0.75, 1.0), limits=c(0,1.05)) +
      scale_x_continuous(breaks=c(0, 0.25, 0.5, 0.75, 1.0), limits=c(0,1.05))

    tmp02 <- c(tmp02, list(tmp03))
  }

  tmp04 <- c(GAMMA, CIl, CIu) %>% round(3)
  grid.newpage()
  pushViewport(viewport(
    x=0.52, y=0.52,
    w=0.75, h=0.75,
    xscale=c(0,nr), yscale=c(0,nr),
    layout=grid.layout(nr, nr))
  )
  for(i in 1:nr){
    print(tmp02[[i]], vp=viewport(layout.pos.row=nr+1-i, layout.pos.col=i))
  }
  grid.rect()
  grid.xaxis(at=1:nr - 1/2, label=F)
  grid.text(1:nr, x=(seq(0, 1, length.out=(nr+1))+1/nr/2)[-(nr+1)], y=-0.05)
  grid.yaxis(at=1:nr - 1/2, label=F)
  grid.text(1:nr, x=-0.05, y=(seq(0, 1, length.out=(nr+1))+1/nr/2)[-(nr+1)])
  grid.text(expression(italic(G[1(i)]^c)), y=-0.11, gp=gpar(fontsize=12))
  grid.text(expression(italic(G[2(i)]^c)), x=-0.11, gp=gpar(fontsize=12), rot = 90)
  if(legend==TRUE){
    grid.text(bquote(hat(Gamma) == .(tmp04[1])), x=0.01, y=0.95, just="left")
    grid.text(paste("95%CI = [", tmp04[2], ", ", tmp04[3], "]", sep=""), x=0.01, y=0.85, just="left")
  }
  return(recordPlot())
}
