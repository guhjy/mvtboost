
#' #' Marginal plots for metboost objects
#' #' 
#' #' The fitted values are plotted against one or two predictors. Note that
#' #' that this is not a partial dependence plot.
#' #' 
#' #' @param x metboost object
#' #' @param X matrix of predictors
#' #' @param id name or index of grouping variable
#' #' @param i.var index or names of variables to plot over (can include id index)
#' #' @param n.trees nubmer of trees (default min(x$best.trees))
#' #' @param ... unused
#' #' @export
#' #' @importFrom ggplot2 ggplot geom_line geom_point aes_string xlab ylab geom_tile facet_wrap
#' plot.metboost <- function(x, X, id, i.var, n.trees=min(x$best.trees), ...){
#'   
#'   if(all(is.character(i.var))){
#'     i.var <- match(i.var, colnames(X))
#'   }
#'   if(is.character(id)){
#'     id <- match(id, colnames(X))
#'   }
#'   
#'   # use yhat from x at n.trees?
#'   yhat <- x$yhat[, n.trees]
#'   Xnew <- X[, i.var]
#'   var.names <- colnames(Xnew)[i.var]
#'   d <- data.frame(y=yhat, Xnew)
#'   f.factor <- sapply(Xnew, is.factor)
#'   
#'   if(length(i.var) == 1){
#'     g <- ggplot(d, aes_string(y="y", x=var.names)) +
#'       geom_point() + geom_line()
#'   } else if(length(i.var) == 2){
#'     if(!f.factor[1] && !f.factor[2]){
#'       g <- ggplot(d, aes_string(x=var.names[1], y=var.names[2], z="y")) + 
#'         geom_tile(aes_string(fill="y")) +
#'         xlab(var.names[i.var[1]]) +
#'         ylab(var.names[i.var[2]])
#'     }
#'     if(f.factor[2]){
#'       g <- ggplot(d, aes_string(y="y", x=var.names[1])) +
#'         geom_point() + geom_line() +
#'         facet_wrap(var.names[2]) + 
#'         ylab(paste("f(", var.names[i.var[1]], ",",var.names[i.var[2]], ")", sep = ""))
#'     }
#'     if(f.factor[1]){
#'       g <- ggplot(d, aes_string(y="y", x=var.names[2])) +
#'         geom_point() + geom_line() +
#'         facet_wrap(var.names[1]) + 
#'         ylab(paste("f(", var.names[i.var[1]], ",",var.names[i.var[2]], ")", sep = ""))
#'     }
#'   } else {
#'     stop("set return.grid=TRUE to make a custom graph")
#'   }
#'   print(g)
#'   return(g)
#' }


# grid.metboost <- function(x, X, id, i.var=1,
#                            n.trees=min(x$best.trees, na.rm=T), 
#                            continuous.resolution=20,
#                            return.grid=FALSE, ...){
#   
#   if(all(is.character(i.var))){
#     i.var <- match(i.var, colnames(X))
#   }
#   if(is.character(id)){
#     id <- match(id, colnames(X))
#   }
#   grid.levels <- vector("list", length(i.var))
#   for(i in seq_along(i.var)){
#     if(is.numeric(X[,i.var[i]])){
#       grid.levels[[i]] <- seq(min(X[,i.var[i]]), max(X[,i.var[i]]), length.out=continuous.resolution)
#     } else {
#       grid.levels[[i]] <- levels(X[,i.var[i]])
#     }
#   }
#   
#   if(ncol(X) > length(i.var)){
#     
#     # average over other predictors
#     
#     # This is very slow. The inner loop here is slow (predict.metboost) and it
#     # gets bad if newX is very large
#     #for(i in 1:nrow(newX)){
#     #  d <- data.frame(newX[rep(i, nrow(X)), ], X[,-i.var])
#     #  yhat[i] <- mean(predict(x, newdata=d, newid=id)$yhat)
#     #}
#     
#     # final grid using averaged predictions
#     grid <- expand.grid(grid.levels[seq_along(i.var)])
#     
#     # create big x matrix for prediction, which contains nrow(grid) copies of the data
#     
#     # individual id varies fastest
#     grid.levels <- append(list(1:nrow(X)), grid.levels) 
#     newX <- expand.grid(grid.levels)
#     nrows <- nrow(grid)
#     bigX <- dplyr::bind_rows(lapply(1:nrows, 
#                    function(i, i.var){X[,-i.var,drop=F]}, i.var=i.var))
#     newid <- rep(X[,id], times=nrows)    
#     newX <- cbind(newX, bigX, id=newid)    
#     colnames(newX) <- c("iid", colnames(X)[i.var], colnames(X)[-i.var], "id")
#     
#     yhat_long <- predict(x, newdata=newX, id="id", M=n.trees)$yhat 
#     loc <- rep(1:nrow(grid), each=nrow(X))
#     yhat <- tapply(yhat_long, INDEX = loc, FUN = mean)
#   } else {
#     # just compute predictions for grid, no averaging
#     grid <- expand.grid(grid.levels)
#     colnames(grid) <- colnames(X)[i.var]
#     grid$id <- X[,id]
#     yhat <- predict(x, newdata=grid, id="id", M=n.trees)$yhat
#   }
#   grid$y <- yhat
#   
#   if(return.grid){
#     return(grid)
#   }
#  
#   if(length(i.var) == 1){
#     g <- ggplot(d=grid, aes(y=y, x=Var1)) +
#       geom_point() + geom_line() +
#       xlab(colnames(X)[i.var])
#   } else if(length(i.var) == 2){
#     d <- grid
#     var.names <- colnames(X)[i.var]
#     colnames(d) <- c("X1", "X2", "y")
#     f.factor <- sapply(d, is.factor)
#     
#     if(!f.factor[1] && !f.factor[2]){
#       g <- ggplot(d, aes(X1, X2, z=y)) + geom_tile(aes(fill=y)) +
#         xlab(var.names[i.var[1]]) +
#         ylab(var.names[i.var[2]])
#     }
#     if(f.factor[2]){
#       g <- ggplot(d, aes(y=y, x=X1)) +
#         geom_point() + geom_line() +
#         facet_wrap(~X2) + 
#         ylab(paste("f(", var.names[i.var[1]], ",",var.names[i.var[2]], ")", sep = ""))
#     }
#     if(f.factor[1]){
#       g <- ggplot(d, aes(y=y, x=X2)) +
#         geom_point() + geom_line() +
#         facet_wrap(~X1) + 
#         ylab(paste("f(", var.names[i.var[1]], ",",var.names[i.var[2]], ")", sep = ""))
#     }
#   } else {
#     stop("set return.grid=TRUE to make a custom graph")
#   }
#   print(g)
#   return(g)
# }

#' plot metboost performance
#' @param x metboost object
#' @param threshold absolute differences in error less than this threshold is optimal
#' @param lag lag of the differences in error across iterations
#' @param ... arguments passed to plot
#' @export
#' @importFrom graphics abline legend lines title
perf.metboost <- function(x, threshold = 0, lag = 1, ...){
  M <- length(x$train.err)
  ymax <- c(max(x$test.err, x$train.err, x$oob.err, na.rm = T))
  ymin <- c(min(x$test.err, x$train.err, x$oob.err, na.rm = T))
  
  best.iter <- best_iter(x, threshold = threshold, lag = lag)
  
  plot(x = 1:M, y = x$train.err, type = "l", ylim = c(ymin, ymax), ylab = "error", ...)
  lines(x = 1:M, y = x$test.err, col = "red", lty = 2)
  lines(x = 1:M, y = x$oob.err, col = "blue")
  lines(x = 1:M, y = x$cv.err, col = "red")
  
  abline(v = best.iter)
  
  legend("top", legend = c("train", "test", "oob", "cv"), 
         col = c("black", "red", "blue", "red"),
         lty = c(1, 2, 1, 1), bty = "n")
  x$best.params$err <- formatC(signif(x$best.params$err[[1]], digits=3), digits=3,format="fg", flag="#")
  paramstring <- paste0(names(x$best.params), " = ", x$best.params, collapse = ", ")
  title(sub = paramstring)
}


best_iter <- function(x, threshold, lag, smooth = FALSE){
  err <- x$cv.err
  err <- err[!is.na(err)]
  if(smooth) err <- smooth(err)
  
  best.iter <- which(abs(diff(err, lag = lag)) < threshold)
  
  if(length(best.iter) == 0){
    best.iter <- which.min(x$cv.err)
  } else {
    best.iter <- min(best.iter)
  }
}


