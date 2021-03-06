-- | 
-- Defines Log-domain probability density functions


{-# LANGUAGE ViewPatterns, NoMonomorphismRestriction, FlexibleInstances #-}
module Math.Probably.PDF where

import qualified Math.Probably.Student as S
import Control.Spoon
import Control.DeepSeq
import qualified Data.Vector.Storable as VS

-- | The type of probablility density functions
type PDF a = a->Double

instance Show (a->Double) where
    show f = error "Math.Prob.PDF: showing function" 

instance Eq (a->Double) where
    f == g = error "Math.Prob.PDF: comparing functions!"

instance Num a => Num (a->Double) where
    f + g = \x-> f x + g x
    f * g = \x-> f x * g x
    f - g = \x-> f x - g x
    abs f = \x -> abs (f x)
    signum f = \x-> signum $ f x
    fromInteger = error $ "Math.Prob.PDF: frominteger on function"

-- | Uniform distributions
uniform :: (Real a, Fractional a) => a-> a-> PDF a
uniform from to = \x-> if x>=from && x <=to
                               then log $ realToFrac $ 1/(to-from )
                               else 0

--http://en.wikipedia.org/wiki/Normal_distribution
-- | Normal distribution
gauss :: (Real a, Floating a) => a-> a-> PDF a
gauss mean sd x = realToFrac $ negate $ (x-mean)**2/(2*sd*sd) + log(sd*sqrt(2*pi))

-- | Normal distribution by variance
normal :: (Real a, Floating a) => a-> a-> a -> a
normal = normalLogPdf 

normalLogPdf :: (Real a, Floating a) => a-> a-> a -> a
normalLogPdf mean variance x
   = ((log 1)-(0.500*(log ((2.000*pi)*variance))))-(((x-mean)**2)/(2*variance))


-- | Normal distribution, specialised for Doubles
gaussD :: Double -> Double-> PDF Double
gaussD mean sd x = negate $ (x-mean)**2/(2*sd*sd) + log(sd*sqrt(2*pi))

gammafun = exp . S.gammaln

-- | <http://en.wikipedia.org/wiki/Gamma_distribution>
gammaD :: Double -> Double -> PDF Double
gammaD k theta x = log $ x**(k-1)*(exp(-x/theta)/(theta**k*(exp (S.gammaln k))))

invGammaD :: Double -> Double -> PDF Double
invGammaD a b x =log $ (b**a/gammafun a)*(1/x)**(a+1)*exp(-b/x)


logNormal m var x = negate $ log (x*sqrt(2*pi*var)) + (log x - m)**2 / (2*var)

logNormalD :: Double -> Double-> PDF Double
logNormalD = logNormal

-- | Beta distribution 
beta a b x = log $ (recip $ S.beta a b) * x ** (a-1) * (1-x) ** (b-1)

-- | Binomial distribution. This is the Probability Mass Function, not PDF
binomial :: Int -> Double -> PDF Int
binomial n p k = 
    let realk = realToFrac k
    in log (realToFrac (choose (toInteger n) (toInteger k))) + realk * log( p ) + (realToFrac $ n-k) * log( (1-p) )
 where --http://blog.plover.com/math/choose.html
   choose :: Integer -> Integer -> Integer
   choose n 0 = 1
   choose 0 k = 0
   choose (n) (k) |  k > n `div` 2 = choose n (n-k)
                  |  otherwise = (choose (n-1) (k-1)) * (n) `div` (k)

-- | the joint distribution of two independent distributions
zipPdfs :: Num a => PDF a -> PDF b -> PDF (a,b)
zipPdfs fx fy (x,y) = fx x + fy y

-- | the multiplication of two PDFS
mulPdf :: Num a => PDF a -> PDF a -> PDF a
mulPdf d1 d2 = \x -> (d1 x + d2 x)

--instance Num a => Num (PDF a) where

{-
   
instance NFData (Matrix Double) 
   where rnf mat = mapMatrix (\x-> x `seq` 1.0::Double) mat `seq` ()

-- | multivariate normal
multiNormal :: Vector Double -> Matrix Double -> PDF (Vector Double)
multiNormal mu sigma = 
  let k = realToFrac $ dim mu
      invSigma =  inv sigma 
      mat1 = head . head . toLists
  in \x-> log (recip ((2*pi)**(k/2) * sqrt(det sigma))) + (mat1 $ negate $ 0.5*(asRow $ x-mu) `multiply` invSigma `multiply` (asColumn $ x-mu) ) 


multiNormalByInv :: Double -> Matrix Double -> Vector Double -> PDF (Vector Double)
multiNormalByInv lndet invSigma mu = 
  let k = realToFrac $ dim mu
      mat1 = head . head . toLists
  in \x-> log 1 - (k/2)*log (2*pi) - lndet/2 + (mat1 $ negate $ 0.5*(asRow $ x-mu) `multiply` invSigma `multiply` (asColumn $ x-mu) ) 

multiNormalByInvFixCov ::  Matrix Double -> Vector Double -> PDF (Vector Double)
multiNormalByInvFixCov invSigma mu = 
  let k = realToFrac $ dim mu
      mat1 = head . head . toLists
  in \x-> (mat1 $ negate $ 0.5*(asRow $ x-mu) `multiply` invSigma `multiply` (asColumn $ x-mu) ) 


multiNormalIndep :: Vector Double -> Vector Double -> PDF (Vector Double)
multiNormalIndep vars mus xs= VS.sum $ VS.zipWith3 (\var mu x -> normalLogPdf mu var x) vars mus xs


{-mu1 = 2 |> [0, 0::Double]
sig1 = (2><2)[1::Double, 0,
              0, 1]

tst = multiNormal mu1 sig1 mu1
tsta = inv sig1
tstb = det sig1
tstc = let mu = mu1
           sigma = sig1 
           x = mu1
           invSigma = inv sigma
       in (asRow $ x-mu) `multiply` invSigma `multiply` (asColumn $ x-mu)  -}


posdefify m = 
   let (eigvals, eigvecM) = eigSH $ mkSym {- $ trace (show m) -}  m
       n = rows m
       eigValsVecs = map f $ zip (toList eigvals) (toColumns eigvecM)
       f (val,vec) = (abs val,vec)
       q = fromColumns $ map snd eigValsVecs
       bigLambda = diag $ fromList $ map fst eigValsVecs
   in mkSym $ q `multiply` bigLambda `multiply` inv q

mkSym m = buildMatrix (rows m) (cols m)$ \(i,j) ->if i>=j then m @@>(i,j) 
                                                           else m @@>(j,i) 

-}