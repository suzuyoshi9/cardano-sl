{-# LANGUAGE DerivingStrategies #-}

module Lang.Name
       ( Letter(getLetter)
       , unsafeMkLetter
       , Name(..)
       , unsafeMkName
       ) where

import           Universum

import           Prelude (Show (..))

import           Data.Char (isAlpha)
import           Data.Coerce (coerce)
import qualified Data.List.NonEmpty as NonEmpty
import           Data.List.Split (splitWhen)
import qualified Data.Text.Buildable as Buildable
import           Test.QuickCheck.Arbitrary.Generic (Arbitrary (..), genericArbitrary, genericShrink)
import           Test.QuickCheck.Gen (suchThat)

-- | Invariant: @isAlpha . getLetter = const True@
newtype Letter = Letter { getLetter :: Char }
    deriving (Eq, Ord, Show, Generic)

unsafeMkLetter :: Char -> Letter
unsafeMkLetter = Letter

instance Arbitrary Letter where
    arbitrary = Letter <$> arbitrary `suchThat` isAlpha

newtype Name = Name (NonEmpty (NonEmpty Letter))
    deriving stock   (Eq, Ord)
    deriving newtype (Generic)

unsafeMkName :: [String] -> Name
unsafeMkName = coerce . fmap NonEmpty.fromList . NonEmpty.fromList

-- TODO: dunno where the instance is and where it's should be
instance Arbitrary a => Arbitrary (NonEmpty a) where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary Name where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Buildable Name where
    build
        = foldMap (fromString . toList)
        . NonEmpty.intersperse ('-' :| [])
        . fromLetterNENE
      where
        fromLetterNENE :: Name -> NonEmpty (NonEmpty Char)
        fromLetterNENE = coerce

instance Show Name where
    showsPrec n = showsPrec n . pretty

-- | Unsafe, requires manual validation.
instance IsString Name where
    fromString = unsafeMkName . splitWhen (=='-')
