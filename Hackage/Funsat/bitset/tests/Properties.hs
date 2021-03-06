module Properties where

import Prelude hiding ( null )
import Data.BitSet
import Data.Foldable ( foldl' )
import Data.List ( nub )
import Test.QuickCheck
import qualified Data.List as List



main :: IO ()
main = do
  check config prop_size
  check config prop_size_insert
  check config prop_size_delete
  check config prop_insert
  check config prop_delete
  check config prop_insDelIdempotent
  check config prop_delDelIdempotent
  check config prop_insInsIdempotent
  check config prop_extensional
  check config prop_empty

config = defaultConfig{ configMaxTest = 1000 }

-- * Quickcheck properties

prop_size xs =
    trivial (List.null uxs) $
    length uxs == size (foldr insert empty uxs)
        where uxs = nub (map abs xs) :: [Int]

prop_size_insert x s =
    trivial (null s) $
    if xa `member` s then size s == size s'
    else size s + 1 == size s'
  where s' = insert xa s
        xa = abs x :: Int

prop_size_delete x s =
    trivial (null s) $
    if xa `member` s then size s - 1 == size s'
    else size s == size s'
  where s' = delete xa s
        xa = abs x :: Int

prop_insert x s = xa `member` insert xa s
    where xa = abs x :: Int

prop_delete x s = not $ xa `member` delete xa s
    where xa = abs x :: Int

prop_insDelIdempotent x s =
    classify (not (xa `member` s)) "passed guard" $
    not (xa `member` s) ==>
    s == (delete xa . insert xa) s
  where xa = abs x :: Int

prop_delDelIdempotent x s =
    classify (xa `member` s) "x in s" $
    classify (not (xa `member` s)) "x not in s" $
    delete xa s == (delete xa . delete xa $ s)
  where xa = abs x :: Int

prop_insInsIdempotent x s = insert xa s == (insert xa . insert xa) s
    where xa = abs x :: Int

prop_extensional xs = and $ map (`member` s) xsa
    where s   = foldr insert empty xsa
          xsa = map abs xs :: [Int]

prop_empty x = not $ xa `member` empty
    where xa = abs x :: Int



instance (Arbitrary a, Hash a) => Arbitrary (BitSet a) where
    arbitrary = sized $ \n ->
                do xs <- vector n
                   return $ foldl' (flip insert) empty xs
