### Testing the group methods  --- some also happens in ./Class+Meth.R

## for R_DEFAULT_PACKAGES=NULL :
library(stats)
library(utils)

library(Matrix)
source(system.file("test-tools.R", package = "Matrix"))# identical3() etc
assertErrV <- function(e) tools::assertError(e, verbose=TRUE)

cat("doExtras:",doExtras,"\n")
options(nwarnings = 1e4)

set.seed(2001)

mm <- Matrix(rnorm(50 * 7), ncol = 7)
xpx <- crossprod(mm)# -> "factors" in mm !
round(xpx, 3) # works via "Math2"

y <- rnorm(nrow(mm))
xpy <- crossprod(mm, y)
res <- solve(xpx, xpy)
signif(res, 4) # 7 x 1 Matrix

stopifnot(all(signif(res) == signif(res, 6)),
	  all(round (xpx) == round (xpx, 0)))

## exp(): component wise
signif(dd <- (expm(xpx) - exp(xpx)) / 1e34, 3)# 7 x 7

validObject(xpx)
validObject(xpy)
validObject(dd)

## "Math" also, for log() and [l]gamma() which need special treatment
stopifnot(exprs = {
    identical(exp(res)@x, exp(res@x))
    identical(log(abs(res))@x, log(abs((res@x))))
    identical(lgamma(res)@x, lgamma(res@x))
})

## "Arith" / "Ops"
M <- Matrix(1:12, 4,3)
m <- cbind(4:1)
stopifnot(exprs = {
    identical(M*m, M*c(m)) # M*m failed in Matrix_1.3-3 pre-release:
    identical(m*M, c(m)*M)
    ## M*m: Error in eval(....) : object 'x1' not found
    isValid(M1 <- M[, 1, drop=FALSE], "dgeMatrix")
    identical(M*M1, M*M1[,1]) # M*M1 failed ..
    identical(M-M1, M-M1[,1])
    identical(M/M1, M/M1[,1])
    identical(M1*M, M1[,1]*M)
    identical(M1-M, M1[,1]-M)
    identical(M1/M, M1[,1]/M)
})



###--- sparse matrices ---------

mC <- Matrix(c(0, 0, 2:0), 3, 5)
sm <- sin(mC)
stopifnot(class(sm) == class(mC), class(mC) == class(mC^2),
          dim(sm) == dim(mC),
          class(0 + 100*mC) == class(mC),
          all.equal(0.1 * ((0 + 100*mC)/10), mC),
          all.equal(sqrt(mC ^ 2), mC),
          identical(mC^2, mC * mC),
          identical(mC*2, mC + mC)
          )

x <- Matrix(rbind(0,cbind(0, 0:3,0,0,-1:2,0),0))
x # sparse
(x2 <- x + 10*t(x))
stopifnot(is(x2, "sparseMatrix"),
          identical(x2, t(x*10 + t(x))),
	  identical(x, as((x + 10) - 10, "CsparseMatrix")))

(px <- Matrix(x^x - 1))#-> sparse again
stopifnot(px@i == c(3,4,1,4),
          px@x == c(3,26,-2,3))

## From: "Florent D." .. Thu, 23 Feb 2012 -- bug report
##---> MM:  Make a regression test:
tst <- function(n, i = 1) {
    stopifnot(i >= 1, n >= i)
    D <- .sparseDiagonal(n)
    ee <- numeric(n) ; ee[i] <- 1
    stopifnot(all(D - ee == diag(n) - ee),
              all(D * ee == diag(n) * ee),
              all(ee - D == ee - diag(n)),
              {C <- (ee / D == ee / diag(n)); all(is.na(C) | C)},
              TRUE)
}
nn <- if(doExtras) 27 else 7
tmp <- sapply(1:nn, tst) # failed in Matrix 1.0-4
i <- sapply(1:nn, function(i) sample(i,1))
tmp <- mapply(tst, n= 1:nn, i= i)# failed too

(lsy <- new("lsyMatrix", Dim = c(2L,2L), x=c(TRUE,FALSE,TRUE,TRUE)))
nsy <- as(lsy, "nMatrix")
(t1  <- new("ltrMatrix", Dim = c(1L,1L), x = TRUE))
(t2  <- new("ltrMatrix", Dim = c(2L,2L), x = rep(TRUE,4)))
stopifnot(all(lsy), # failed in Matrix 1.0-4
          all(nsy), #  dito
	  all(t1),  #   "
          ## ok previously (all following):
          !all(t2),
          all(sqrt(lsy) == 1)
          , identical(-nsy, -lsy) # "-" failed up to 2025 (<= 1.7.2)
          , as.logical( -t1 == -1)
          , isValid(-t2, "triangularMatrix")
          , all(- as(lsy, "sparseMatrix") == -1)
          )
dsy <- lsy+1

D3 <- Diagonal(x=4:2); L7 <- Diagonal(7) > 0
validObject(xpp <- pack(round(xpx,2)))
lsp <- xpp > 0
(dsyU <- .diag2dense(D3, ".", "s"))
 lsyU <- .diag2dense(Diagonal(5) > 0, ".", "s")
str(lsyU)
stopifnot({
    isValid(dsyU,               "dsyMatrix") && dsyU@uplo == "U"
    isValid(dsyL <- t(dsyU),    "dsyMatrix") && dsyL@uplo == "L"
    isValid(dspU <- pack(dsyU), "dspMatrix") && dspU@uplo == "U"
    isValid(dspL <- pack(dsyL), "dspMatrix") && dspL@uplo == "L"
    identical(dspU, t(dspL))
    isValid(lsyU,               "lsyMatrix") && lsyU@uplo == "U"
    isValid(lsyL <- t(lsyU),    "lsyMatrix") && lsyL@uplo == "L"
    isValid(lspU <- pack(lsyU), "lspMatrix") && lspU@uplo == "U"
    isValid(lspL <- pack(lsyL), "lspMatrix") && lspL@uplo == "L"
    identical(lspL, t(lspU))
    ##
    ## log(x, <base>) -- was mostly *wrong* upto 2019-10 [Matrix <= 1.2-17]
    all.equal(log(abs(dsy), 2), log2(abs(dsy)))
    all.equal(log(abs(dsyL),2), log2(abs(dsyL)))
    all.equal(log(abs(dspU),2), log2(abs(dspU)))
    all.equal(log(abs(dspL),2), log2(abs(dspL)))
    ## These always worked, as {0,1} -> {-Inf,0} independent of 'base':
    all.equal(log(abs(lsy), 2), log2(abs(lsy)))
    all.equal(log(abs(lsyL),2), log2(abs(lsyL)))
    all.equal(log(abs(lspU),2), log2(abs(lspU)))
    all.equal(log(abs(lspL),2), log2(abs(lspL)))
    ##
    all.equal(log(abs(res), 2), log2(abs(res)))
    all.equal(log(abs(xpy), 2), log2(abs(xpy)))
    all.equal(log(abs(xpp), 2), log2(abs(xpp)))
    all.equal(log(abs( D3), 2), log2(abs( D3)))
    all.equal(log(abs( L7), 2), log2(abs( L7)))
})
showProc.time()

## is.finite() -- notably for symmetric packed / uplo="L" with NA :
spU <- new("dspMatrix", Dim = c(3L, 3L), x = c(0, NA, 0, NA, NA, 0),           uplo = "U")
sU  <- new("dsyMatrix", Dim = c(3L, 3L), x = c(1, NA, NA, NA, 1, NA, 8, 2, 1), uplo = "U")
sL  <- t(sU)
spL <- t(spU)
trU <- triu(spU)
trL <- tril(spL)
stopifnot(exprs = {
    spL@uplo == "L"
    trU@uplo == "U"
    trL@uplo == "L"
    identical(trU, triu(spL))
    identical(trL, tril(spU))
})
isU <- is.finite(sU)
isL <- is.finite(sL)
stopifnot(exprs = {
    identical(isU, t(isL))
    all(isU == isL)
    which(!isU, arr.ind = TRUE) == c(2:1, 1:2)
})
isFu <- is.finite(spU)
isFl <- is.finite(spL)
isFtu <- is.finite(trU)
isFtl <- is.finite(trL)
stopifnot(exprs = {
    all(isFu == diag(TRUE, 3))
    all(isFu == isFl) # has failed till 2022-06-11
    isTriangular(isFtu)
    isTriangular(isFtl)
    identical(rep(TRUE, 6), pack(tril(isFtu))@x)
    identical(rep(TRUE, 6), pack(triu(isFtl))@x)
})

showProc.time()
set.seed(111)
local({
    for(i in 1:(if(doExtras) 20 else 5)) {
        M <- rspMat(n=1000, 200, density = 1/20)
        v <- rnorm(ncol(M))
        m <- as(M,"matrix")
        stopifnot(all(t(M)/v == t(m)/v))
        cat(".")
    }});cat("\n")

## Now just once, with a large such matrix:
local({
    n <- 100000; m <- 30000
    AA <- rspMat(n, m, density = 1/20000)
    v <- rnorm(m)
    st <- system.time({
        BB <- t(AA)/v # should happen *fast*
        stopifnot(dim(BB) == c(m,n), is(BB, "sparseMatrix"))
    })
    str(BB)
    print(st)
    if(Sys.info()[["sysname"]] == "Linux") {
        mips <- try(as.numeric(sub(".*: *", '',
                               grep("bogomips", readLines("/proc/cpuinfo"),
                                    ignore.case=TRUE, # e.g. ARM : "BogoMIPS"
                                    value=TRUE)[[1]])))
        print(mips)
        if(is.numeric(mips) && all(mips) > 0 && doExtras)
                                        # doExtras: valgrind (2023-07-26) gave large 'st[1]'
        stopifnot(st[1] < 1000/mips)# ensure there was no gross inefficiency
    }
})


###----- Compare methods ---> logical Matrices ------------
l3 <- upper.tri(matrix(, 3, 3))
(ll3 <- Matrix(l3))
dt3 <- (99* Diagonal(3) + (10 * ll3 + Diagonal(3)))/10
(dsc <- crossprod(ll3))
stopifnot(identical(ll3, t(t(ll3))),
	  identical(dsc, t(t(dsc))))
stopifnotValid(ll3, "ltCMatrix")
stopifnotValid(dsc, "dsCMatrix")
stopifnotValid(dsc + 3 * Diagonal(nrow(dsc)), "dsCMatrix")
stopifnotValid(dt3, "triangularMatrix")    # remained triangular
stopifnotValid(dt3 > 0, "triangularMatrix")# ditto


(lm1 <- dsc >= 1) # now ok
(lm2 <- dsc == 1) # now ok
nm1 <- as(lm1, "nMatrix")
(nm2 <- as(lm2, "nMatrix"))

stopifnot(validObject(lm1), validObject(lm2),
          validObject(nm1), validObject(nm2),
          identical(dsc, dsc * as(lm1, "dMatrix")))

crossprod(lm1) # lm1: "lsC*"
cnm1 <- crossprod(nm1, boolArith = FALSE)
stopifnot(is(cnm1, "symmetricMatrix"), ## whereas the %*% is not:
	  Q.eq(cnm1, nm1 %*% nm1))
dn1 <- as(nm1, "denseMatrix")
stopifnot(all(dn1 == nm1))

dsc[2,3] <- NA ## now has an NA (and no longer is symmetric)
##          ----- and "everything" is different
## also add "non-structural 0":
dsc@x[1] <- 0
dsc
dsc/ 5
dsc + dsc
dsc - dsc
dsc + 1 # -> no longer sparse
Tsc <- as(dsc, "TsparseMatrix")
dsc. <- drop0(dsc)
stopifnot(Q.eq(dsc., Matrix((dsc + 1) - 1)),
	  identical(as(-Tsc,"CsparseMatrix"), (-1) * Tsc),
	  identical(-dsc., (-1) * dsc.),
	  identical3(-Diagonal(3), Diagonal(3, -1), (-1) * Diagonal(3)),
	  Q.eq(dsc., Matrix((Tsc + 1) -1)), # ok (exact arithmetic)
	  Q.eq(0 != dsc, dsc != Matrix(0, 3, 3)),
	  Q.eq(0 != dsc, dsc != c(0,0)) # with a warning ("not multiple ..")
	  )
str(lm1 <- dsc >= 1) # now ok (NA in proper place, however:
lm1 ## NA used to print as ' ' , now 'N'
(lm2 <- dsc == 1)# ditto
stopifnot(identical(crossprod(lm1),# "lgC": here works!
                    crossprod(as(lm1, "dMatrix"))),
          identical(lm2, lm1 & lm2),
	  identical(lm1, lm1 | lm2))

ddsc <- kronecker(Diagonal(7), dsc)
isValid(ddv <- rowSums(ddsc, sparseResult=TRUE), "sparseVector")
sv <- colSums(kC <- kronecker(mC,kronecker(mC,mC)), sparseResult=TRUE)
EQ <- ddv == rowSums(ddsc)
na.ddv <- is.na(ddv)
sM <- Matrix(pmax(0, round(rnorm(50*15, -1.5), 2)), 50,15)
stopifnot(sv == colSums(kC), is.na(as.vector(ddv)) == na.ddv,
          isValid(sM/(-7:7), "CsparseMatrix"),
	  all(EQ | na.ddv))

## Subclasses (!)
setClass("m.spV", contains = "dsparseVector")
(m.ddv <- as(ddv, "m.spV"))
stopifnot(all.equal(m.ddv, ddv, check.class = FALSE))# failed
setClass("m.dgC", contains = "dgCMatrix")
(m.mC <- as(mC, "m.dgC"))
stopifnot(all(m.mC == mC))
## 2-level inheritance (R-forge Matrix bug #6185)
## https://r-forge.r-project.org/tracker/index.php?func=detail&aid=6185&group_id=61&atid=294
setClass("Z", representation(zz = "list"))
setClass("C", contains = c("Z", "dgCMatrix"))
setClass("C2", contains = "C")
setClass("C3", contains = "C2")
(cc <- as(mC, "C"))
c2 <- as(mC, "C2")
c3 <- as(mC, "C3")
 # as(*, "matrix") of these __fail__ in  R < 3.5.0
                               # before R_check_class_and_super() became better :
    print(c2)
    print(c3)
## ==> Error in asMethod(object) : invalid class of object to as_cholmod_sparse
stopifnot(identical(cc > 0, mC > 0 -> m.gt.0), ## cc > 0 - gave error in Matrix <= 1.2-11
          identical(c2 > 0, m.gt.0),
          identical(c3 > 0, m.gt.0))

## Just for print "show":
z <- round(rnorm(77), 2)
z[sample(77,10)] <- NA
(D <- Matrix(z, 7)) # dense
z[sample(77,15)] <- 0
(D <- Matrix(z, 7)) # sparse
abs(D) >= 0.5       # logical sparse

## For the checks below, remove some and add a few more objects:
rm(list= ls(pattern="^.[mMC]?$"))
T3 <- Diagonal(3) > 0; stopifnot(T3@diag == "U") # "uni-diagonal"
validObject(dtp <- pack(as(dt3, "denseMatrix")))
stopifnot(exprs = {
    isValid(lsC <- as(lsp, "CsparseMatrix"), "lsCMatrix")
    ## 0-extent matrices {fixes in Feb.2019}:
    isValid(L00 <- L7[FALSE,FALSE], "ldiMatrix")
    isValid(x60 <- x2[,FALSE],      "dgCMatrix")
    identical(t(x60), x06 <- x2[FALSE,])
    isValid(x00 <- x06[,FALSE],     "dgCMatrix")
    isValid(sv0 <- as(x06, "sparseVector"), "dsparseVector")
})

showProc.time()

### Consider "all" Matrix classes
cl <- sapply(ls(), function(.) class(get(.)))
Mcl <- cl[vapply(cl, extends, "Matrix",       FUN.VALUE=NA) |
          vapply(cl, extends, "sparseVector", FUN.VALUE=NA)]
table(unlist(Mcl))
## choose *one* of each class:
## M.objs <- names(Mcl[!duplicated(Mcl)])
## choose all
M.objs <- names(Mcl) # == the ls() from above
Mat.objs <- M.objs[vapply(M.objs, function(nm) is(get(nm), "Matrix"), NA)]
MatDims <- t(vapply(Mat.objs, function(nm) dim(get(nm)), 0:1))
## Nice summary info :
Mcl <- sapply(Mcl, as.vector) # dropping "package" attributes
noquote(cbind(Mcl[Mat.objs], format(MatDims)))

## dtCMatrix, uplo="L" :
(CtL <- t(as(Diagonal(x=4:2), "CsparseMatrix")))
m2 <- cbind(c(0, NA, NA),
            c(0,  0, NA), 0)
op <- options(Matrix.verbose = 2)
r <- CtL > m2 # failed in Matrix <= 1.4-1, with
## Compare <Csparse> -- "dtCMatrix" > "dtCMatrix" :
stopifnot(identical(is.na(m2), unname(as.matrix(is.na(r)))), diag(r), isDiagonal(triu(r)))
M <- new("dtCMatrix", i = c(0L, 0:1, 0:2), p = c(0:1, 3L, 6L),
         x = c(10,1, 10,1, 1,10), Dim = c(3L, 3L), uplo = "U")
m2 <- matrix(c(0, NA, NA, 0, 0, NA, 0, 0, 0), 3)
r <- M & m2 # failed in Matrix <= 1.4-1
assert.EQ.mat(M        | m2 -> ro,
              as.mat(M)| m2, tol=0)
D4 <- Diagonal(x=0+ 4:2)
rd <- D4 | m2 # gave  invalid class "ltTMatrix" object: uplo='U' must not have sparse entries below the diagonal
M2 <- Matrix(m2); T2 <- Matrix:::.diag2T.smart(D4, M2, kind="l")
stopifnot(exprs = {
    all(!r)
    ## fix in .do.Logic.lsparse() {needed uplo="L"}
    identical(rd,    T2                   |    M2)
    identical(rd, as(T2, "CsparseMatrix") | as(M2, "lMatrix"))
})

options(op)

if(doExtras || interactive()) { # save testing time

### Systematically look at all "Ops" group generics for "all" Matrix classes
### -------------- Main issue: Detect infinite recursion problems

mDims <- MatDims %*% (d.sig <- c(1, 1000)) # "dim-signature" to match against
m2num <- function(m) { if(is.integer(m)) storage.mode(m) <- "double" ; m }
M.knd <- Matrix:::.M.kind
cat("Checking all Ops group generics for a set of arguments:\n",
    "-------------------------------------------------------\n", sep='')
op <- options(warn = 2)#, error=recover)
for(gr in getGroupMembers("Ops")) {
  cat(gr,"\n",paste(rep.int("=",nchar(gr)),collapse=""),"\n", sep='')
  v0 <- if(gr == "Arith") numeric() else logical()
  for(f in getGroupMembers(gr)) {
    line <- strrep("-", nchar(f) + 2)
    cat(sprintf("%s\n%s :\n%s\n", line, dQuote(f), line))
    for(nm in M.objs) {
      if(doExtras) cat("  '",nm,"' ", sep="")
      M <- get(nm, inherits=FALSE)
      n.m <- NROW(M)
      cat("o")
      for(x in list(TRUE, -3.2, 0L, seq_len(n.m))) {
        cat(".")
        validObject(r1 <- do.call(f, list(M,x)))
        validObject(r2 <- do.call(f, list(x,M)))
        stopifnot(dim(r1) == dim(M), dim(r2) == dim(M),
                  allow.logical0 = TRUE)
      }
      ## M  o  0-length  === M :
      validObject(M0. <- do.call(f, list(M, numeric())))
      validObject(.M0 <- do.call(f, list(numeric(), M)))
      if(length(M)) # <non-0-extent M>  o  <0-length v> == 0-length v
	  stopifnot(identical(M0., v0), identical(.M0, v0))
      else if(is(M, "Matrix"))
	  stopifnot(identical(M0., as(M, if(gr == "Arith") "dMatrix" else "lMatrix")),
		    identical(M0., .M0))
      else # if(is(M, "sparseVector")) of length 0
	  stopifnot(identical(M0., v0), identical(.M0, v0))
      ## M  o  <sparseVector>
      x <- numeric(n.m)
      if(length(x)) x[c(1,length(x))] <- 1:2
      sv <- as(x, "sparseVector")
      cat("s.")
      validObject(r3 <- do.call(f, list(M, sv)))
      stopifnot(identical(dim(r3), dim(M)))
      if(doExtras && is(M, "Matrix")) { ## M o <Matrix>
        d <- dim(M)
        ds <- sum(d * d.sig)         # signature .. match with all other sigs
        match. <- ds == mDims        # (matches at least itself)
        cat("\nM o M:")
        for(oM in Mat.objs[match.]) {
          M2 <- get(oM)
          ##   R4 :=  M  f  M2
          validObject(R4 <- do.call(f, list(M, M2)))
          cat(".")
          for(M. in list(as.mat(M), M)) { ## two cases ..
            r4 <- m2num(as.mat(do.call(f, list(M., as.mat(M2)))))
            cat(",")
            if(!identical(r4, as.mat(R4))) {
              cat(sprintf("\n %s %s %s gave not identical r4 & R4:\n",
                          nm, f, oM));     print(r4); print(R4)
              C1 <- (eq <- R4 == r4) | (N4 <- as.logical((nr4 <- is.na(eq)) & !is.finite(R4)))
              if(isTRUE(all(C1)) || isTRUE(all.equal(as.mat(R4), r4,
                                                     tolerance = 1e-14)))
                  cat(sprintf(
                      " --> %s %s %s (ok): only difference is %s (matrix) and %s (Matrix)\n",
                      M.knd(M), f, M.knd(M2)
                    , paste(vapply(unique(r4[N4]), format, ""), collapse="/")
                    , paste(vapply(unique(R4[N4]), format, ""), collapse="/")
                      ))
              else if(isTRUE(all(eq | (nr4 & Matrix:::is0(R4)))))
                cat(" --> 'ok': only difference is 'NA' (matrix) and 0 (Matrix)\n")
              else stop("R4 & r4 differ \"too much\"")
            }
          }
          cat("i")
        }
      }
    }
    cat("\n")
  }
}
if(length(warnings())) print(summary(warnings()))
showProc.time()
options(op) # reset 'warn'
} # doExtras

###---- Now checking 0-length / 0-dim cases  <==> to R >= 3.4.0 !

## arithmetic, logic, and comparison (relop) for 0-extent arrays
(m <- Matrix(cbind(a=1[0], b=2[0])))
lM <- as(m, "lMatrix")
nM <- as(m, "nMatrix")
stopifnot(exprs = {
    identical(m, m + 1)
    identical(m, m + 1[0])
    identical(m, m + NULL)## now (2016-09-27) ok
    identical(m, lM+ 1L)
    identical(m, m+2:3) ## gave error "length does not match dimension"
    identical( -m, m)
    identical(-lM, m)
    identical(-nM, m)
    identical(lM, m & 1)
    identical(lM, m | 2:3) ## had Warning "In .... : data length exceeds size of matrix"
    identical(lM, m & TRUE [0])
    identical(lM, m | FALSE[0])
    identical(lM, m > NULL)
    identical(lM, m > 1)
    identical(lM, m > .1[0]) ## was losing dimnames
    identical(lM, m > NULL) ## was not-yet-implemented
    identical(lM, m <= 2:3)  ## had "wrong" warning
})
mm <- m[,c(1:2,2:1,2)]
assertErrV(m + mm) # ... non-conformable arrays
assertErrV(m | mm) # ... non-conformable arrays
## Matrix: ok ;  R : ok, in R >= 3.4.0
assertErrV(m == mm)
## in R <= 3.3.x, relop returned logical(0) and  m + 2:3  returned numeric(0)
##
## arithmetic, logic, and comparison (relop) -- inconsistency for 1x1 array o <vector >= 2>:
## FIXME: desired errors are _not_ thrown for ddiMatrix (when doDiag=TRUE)
(m1 <- Matrix(1, 1L, 1L, dimnames = list("Ro", "col"), doDiag = FALSE))
##    col
## Ro   1
## Before Sep.2016, here, Matrix was the *CONTRARY* to R:
assertErrV(m1  + 1:2)## M.: "correct" ERROR // R 3.4.0: "deprecated" warning (--> will be error)
assertErrV(m1  & 1:2)## gave 1 x 1 [TRUE]  -- now Error, as R
assertErrV(m1 <= 1:2)## gave 1 x 1 [TRUE]  -- now Error, as R
assertErrV(m1  & 1:2)## gave 1 x 1 [TRUE]  -- now Error, as R
assertErrV(m1 <= 1:2)## gave 1 x 1 [TRUE]  -- now Error, as R
##
##  arrays combined with NULL works now
stopifnot(identical(Matrix(3,1,1) + NULL, 3[0]))
stopifnot(identical(Matrix(3,1,1) > NULL, T[0]))
stopifnot(identical(Matrix(3,1,1) & NULL, T[0]))
## in R >= 3.4.0: logical(0) # with *no* warning and that's correct!

if(doExtras || interactive()) { # save testing time
mStop <- function(...) stop(..., call. = FALSE)
##
cat("Checking the Math (+ Math2) group generics for a set of arguments:\n",
    "------------ ==== ------------------------------------------------\n", sep='')
doStop <- function() mStop("**Math: ", f,"(<",class(M),">) of 'wrong' class ", dQuote(class(R)))
mM  <- getGroupMembers("Math")
mM2 <- getGroupMembers("Math2")
(mVec <- grep("^cum", mM, value=TRUE)) ## <<- are special: return *vector* for matrix input
for(f in c(mM, mM2)) {
  cat(sprintf("%-9s :\n %-7s\n", paste0('"',f,'"'), paste(rep("-", nchar(f)), collapse="")))
  givesVec <- f %in% mVec
  fn <- get(f)
  if(f %in% mM2) { fn0 <- fn ; fn <- function(x) fn0(x, digits=3) }
  for(nm in M.objs) {
    M <- get(nm, inherits=FALSE)
    is.m <- length(dim(M)) == 2
    cat("  '",nm,"':", if(is.m) "m" else "v", sep="")
    R <- fn(M)
    r <- fn(m <- if(is.m) as.mat(M) else as.vector(M))
    stopifnot(identical(dim(R), dim(r)))
    if(givesVec || !is.m) {
        assert.EQ(R, r, check.class = FALSE)
    } else { ## (almost always:) matrix result
        assert.EQ.mat(R, r, check.class = FALSE)
	## check preservation of properties, notably super class
	if(prod(dim(M)) > 1 && is(M, "diagonalMatrix"  ) && isDiagonal(R) && !is(R, "diagonalMatrix"  )) doStop()
	if(prod(dim(M)) > 1 && is(M, "triangularMatrix") && (iT <- isTriangular(R)) && attr(iT, "kind") == M@uplo &&
           !is(R, "triangularMatrix")) doStop()
    }
  }
  cat("\n")
}
showProc.time()

##
cat("Checking the Summary group generics for a set of arguments:\n",
    "------------ ======= ------------------------------------------------\n", sep='')
for(f in getGroupMembers("Summary")) {
  cat(sprintf("%-9s :\n %-7s\n", paste0('"',f,'"'), paste(rep("-", nchar(f)), collapse="")))
  givesVec <- f %in% mVec
  fn <- get(f)
  if(f %in% mM2) { fn0 <- fn ; fn <- function(x) fn0(x, digits=3) }
  for(nm in M.objs) {
    M <- get(nm, inherits=FALSE)
    is.m <- length(dim(M)) == 2
    cat("  '",nm,"':", if(is.m) "m" else "v", sep="")
    R <- fn(M)
    r <- fn(m <- if(is.m) as.mat(M) else as.vector(M))
    stopifnot(identical(dim(R), dim(r)))
    assert.EQ(R, r)
  }
  cat("\n")
  if(length(warnings())) print(summary(warnings()))
}
} # doExtras

## <Math>(x) behaved incorrectly in Matrix <= 1.4-1
## for unit diagonal 'x' when f(0) == 0 and f(1) != 1
Dn <- list(c("a", "b"), c("A", "B"))
udi <- new("ddiMatrix", Dim = c(2L, 2L), Dimnames = Dn, diag = "U")
utC <- new("dtCMatrix", Dim = c(2L, 2L), Dimnames = Dn, diag = "U",
           p = integer(3L))
utr <- new("dtrMatrix", Dim = c(2L, 2L), Dimnames = Dn, diag = "U",
           x = double(4L))
sinu <- `dimnames<-`(sin(diag(2L)), Dn)
for(u in list(udi, utC, utr))
    stopifnot(identical(as(sin(u), "matrix"), sinu))

## Originally in ../man/all-methods.Rd :
M <- Matrix(1:12 +0, 3,4)
all(M >= 1) # TRUE
any(M < 0 ) # FALSE
MN <- M; MN[2,3] <- NA; MN
all(MN >= 0) # NA
any(MN <  0) # NA
any(MN <  0, na.rm = TRUE) # -> FALSE
sM <- as(MN, "sparseMatrix")
stopifnot(all(M >= 1), !any(M < 0),
          all.equal((sM >= 1), as(MN >= 1, "sparseMatrix")),
          ## MN:
          any(MN < 2), !all(MN < 5),
          is.na(all(MN >= 0)), is.na(any(MN < 0)),
          all(MN >= 0, na.rm=TRUE), !any(MN < 0, na.rm=TRUE),
          ## same for sM :
          any(sM < 2), !all(sM < 5),
          is.na(all(sM >= 0)), is.na(any(sM < 0)),
          all(sM >= 0, na.rm=TRUE), !any(sM < 0, na.rm=TRUE)
         )

## prod(<symmetricMatrix>) does not perform multiplies in row/column order :
x4 <- new("dspMatrix", Dim = c(4L, 4L),
          x = c(171, 53, 79, 205, 100, 285, 98, 15, 99, 84))
p4   <- prod(   x4)
p4.  <- prod(as(x4, "generalMatrix"))
p4.. <- prod(as(x4, "matrix"))
stopifnot(all.equal(p4,  p4. , tolerance = 1e-15),
          all.equal(p4., p4.., tolerance = 1e-15))
all.equal(p4,  p4. , tolerance = 0)
all.equal(p4., p4.., tolerance = 0)
.Machine[["sizeof.longdouble"]]

## <Ops>  <matrix> o <sparseVector>  stopped working
(M73p <- L7[1:3,] + na.ddv) # 3 x 7 sparse Matrix of class "dgCMatrix"
m73 <- as.matrix(L7[1:3,])
(m73p <- m73 + na.ddv)
stopifnot(is(m73p, "sparseMatrix"),
          identical(m73p, na.ddv + m73),
          identical(m73p, M73p))
## badly failed, returning sparseVector  in Matrix 1.7.{0,1,2}




cat('Time elapsed: ', proc.time(),'\n') # for ``statistical reasons''
