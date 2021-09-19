{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE DeriveAnyClass      #-}
{-# LANGUAGE DeriveGeneric       #-}
{-# LANGUAGE FlexibleContexts    #-}
{-# LANGUAGE NoImplicitPrelude   #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}
{-# LANGUAGE TypeApplications    #-}
{-# LANGUAGE TypeFamilies        #-}
{-# LANGUAGE TypeOperators       #-}
{-# OPTIONS_GHC -fno-warn-unused-imports #-}

module Plutus.Contracts.Gift where

import           Control.Monad          hiding (fmap)
import           Data.Aeson             (FromJSON, ToJSON)
import           Data.Map               as Map
import           Data.Void              (Void)
import           GHC.Generics           (Generic)
import           Plutus.Contract
import qualified PlutusTx
import           PlutusTx.Prelude       hiding (Semigroup(..), unless)
import           Ledger                 hiding (singleton)
import           Ledger.Constraints     as Constraints
import           Playground.Contract    (printJson, printSchemas, ensureKnownCurrencies, stage, ToSchema)
import           Playground.TH          (mkKnownCurrencies, mkSchemaDefinitions)
import           Playground.Types       (KnownCurrency (..))
import           Prelude                (IO, Semigroup (..), String, undefined)
import           Control.Monad          (void)
import           Data.Text              as Text
import qualified Ledger.Ada             as Ada
import qualified Ledger.Constraints     as Constraints
import qualified Ledger.Typed.Scripts   as Scripts
import qualified Prelude                as Haskell
import           Schema
import           Wallet.Emulator.Wallet
import Text.Printf

data MyRedeemer = MyRedeemer
    { flag1 :: Bool
    , flag2 :: Bool
    } deriving (Generic, FromJSON, ToJSON, ToSchema)

PlutusTx.unstableMakeIsData ''MyRedeemer

{-# INLINABLE mkValidator #-}
-- This should validate if and only if the two Booleans in the redeemer are equal!
mkValidator :: () -> MyRedeemer -> ScriptContext -> Bool
mkValidator _ (MyRedeemer a b) _ = traceIfFalse "Really should think of something" $ a==b

data Typed
instance Scripts.ValidatorTypes Typed where
    type instance DatumType Typed = ()
    type instance RedeemerType Typed = MyRedeemer

typedValidator :: Scripts.TypedValidator Typed
typedValidator = Scripts.mkTypedValidator @Typed
    $$(PlutusTx.compile [|| mkValidator ||])
    $$(PlutusTx.compile [|| wrap ||])
    where
        wrap = Scripts.wrapValidator @() @MyRedeemer

validator :: Validator
validator = Scripts.validatorScript typedValidator

valHash :: Ledger.ValidatorHash
valHash = Scripts.validatorHash typedValidator

scrAddress :: Ledger.Address
scrAddress = scriptAddress validator

type GiftSchema =
            Endpoint "give" Integer
        .\/ Endpoint "grab" MyRedeemer

give :: AsContractError e => Integer -> Contract w s e () 
give amount = do 
    let tx = mustPayToTheScript () $ Ada.lovelaceValueOf amount
    ledgerTx <- submitTxConstraints typedValidator tx
    void $ awaitTxConfirmed $ txId ledgerTx
    
    

grab :: forall w s e. AsContractError e => MyRedeemer -> Contract w s e ()
grab r = do 
    utxos <- utxoAt scrAddress
    let orefs   = fst <$> Map.toList utxos
        lookups = Constraints.unspentOutputs utxos      <>
                  Constraints.otherScript validator
        tx :: TxConstraints Void Void
        tx      = mconcat [mustSpendScriptOutput oref $ Redeemer $ PlutusTx.toBuiltinData r | oref <- orefs]
    ledgerTx <- submitTxConstraintsWith  @Void lookups tx
    void $ awaitTxConfirmed $ txId ledgerTx

give' :: Promise () GiftSchema Text ()
give' = endpoint @"give" give

grab' :: Promise () GiftSchema Text ()
grab' = endpoint @"grab" grab

gift :: AsContractError e => Contract () GiftSchema Text e
gift = do
    selectList [give', grab'] >> gift

mkSchemaDefinitions ''GiftSchema

mkKnownCurrencies []