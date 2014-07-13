## Function to calculate optimal bandwidth per Imbens, Guido and Karthik 
## Kalyanaraman, "Optimal Bandwith Choice for the Regression Discontinuity
## Estimator",
## Review of Economic Studies, forthcoming
rd_opt_bw <- function(y, X, c=0, C_k=3.4375) {
    
    ### (1) Estimation of density (f.hat.c) and
    ### conditional variance (S.hat_c ^ 2) 
    Sx <- sd(X)
    N <- length(X)
    N.pos <- sum(X >= c)
    N.neg <- sum(X < c)
    h1 <- 1.84 * Sx * (N ^ -0.2)
    
    ## Calculate the number of units on either side of the threshold,
    ## and the average outcomes on either side.
    i_plus  <- (X <= c + h1) & (X >= c)
    i_minus <- (X >= c - h1) & (X < c)
    
    ## Estimate the density of the forcing variable at the cutpoint
    f.hat.c <- (sum(i_plus) + sum(i_minus))/(2 * N * h1)
    
    ## Take the average of the conditional variances of Yi given
    ## Xi = x, at x = c, from the left and the right
    sigmas <- mean(c(y[i_plus] - mean(y[i_plus], na.rm=TRUE), 
                     y[i_minus] - mean(y[i_minus]), na.rm=TRUE)^2,
                   na.rm=TRUE)
    
    #   Step 2: Estimation of second derivatives $\hat{m}_{+}^{(2)}(c)$ and
    #   $\hat{m}_{-}^{(2)}(c)$ --------- To estimate the curvature at the threshold,
    #   we first need to choose bandwidths $h_{2,+}$ and $h_{2,−}$. We choose these
    #   bandwidths based on an estimate of $\hat{m}^3(c)$, obtained by fitting a
    #   global cubic with a jump at the threshold. We estimate this global cubic
    #   regression function by dropping observations with covariate values below the
    #   median of the covariate for observations with covariate values below the
    #   threshold, and dropping observations with covariate values above the median
    #   of the covariate for observations with covariate values above the threshold.
    #   For the observations with $X_i < c$ ($X_i \geq c$), the median of
    #   the forcing variable is `r median(X[X<c])` (`r median(X[X>=c])`). Next, we
    #   estimate, using the data with $X_i \in$ `r median(X[X<c])` (`r median(X[X>=c])`), the polynomial
    #   regression function of order three, with a jump at the threshold of c:
    #   
    step_2_data <- as.data.frame(cbind(y, X, X_d=X-c))
    step_2_lm <- lm(y ~ X_d+ I(X_d^2) + I(X_d^3) + (X>=c), data=step_2_data,
                    subset=X >= median(X[X<c]) & X <= median(X[X>=c]))
    m3hat.c <- 6 * coef(step_2_lm)[4]
    
    h2.pos  <- ((sigmas / (f.hat.c * m3hat.c ^ 2)) ^ (1/7) *
        3.56 * (N.pos ^ (-1/7)))
    h2.neg <- ((sigmas / (f.hat.c * m3hat.c ^ 2)) ^ (1/7) *
        3.56 * (N.neg ^ (-1/7)))
    
    ## Given the pilot bandwidths h2.pos and h2.neg, we estimate the
    ## curvature m(2)(c) by a local quadratic
    lm.h2.pos <- lm(y ~ X + I(X^2), data=step_2_data, 
                    subset= X >= c & X <= h2.pos + c)
    m2hat.pos.c <- 2 * coef(lm.h2.pos)[3]
    N2.pos <- length(lm.h2.pos$residuals)
    
    lm.h2.neg <- lm(y ~ X + I(X^2), data=step_2_data, 
                    subset= X >= c - h2.neg & X < c)
    m2hat.neg.c <- 2 * coef(lm.h2.neg)[3]
    N2.neg <- length(lm.h2.neg$residuals)
    
    ### (3) Calculation of regulation terms and optimal h.
    r.hat.pos <- (720 * sigmas) / (N2.pos * h2.pos ^ 4)
    r.hat.neg <- (720 * sigmas) / (N2.neg * h2.neg ^ 4)
    
    ### (3) Calculation of regulation terms and optimal h.
    
    h.opt <- C_k*((2*sigmas/(f.hat.c*
        ((m2hat.pos.c-m2hat.neg.c)^2+r.hat.pos+r.hat.neg)))^(1/5))*(N^(-1/5))
    return(as.double(h.opt))
}