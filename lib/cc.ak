use aiken/collection/dict
use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use cardano/address.{Address, Script, VerificationKey}
use cardano/assets.{Lovelace, PolicyId}
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, Transaction,
}
use cc/types.{
  Burn, CCRedeemer, CreatorDatum, CreditHolderDatum, CustomerDatum, Mint,
  Purchase, Register, VerifierDatum,
}
use cc/utils
use config

pub fn validate_spend_campaign(
  creator: VerificationKeyHash,
  verifier: VerificationKeyHash,
  creditHolder: VerificationKeyHash,
  customer: VerificationKeyHash,
  datum: Option<Data>,
  cc_action: CCRedeemer,
  o_ref: OutputReference,
  tx: Transaction,
) -> Bool {
  expect Some(Input { output: Output { address, .. }, .. }) =
    tx.inputs |> transaction.find_input(o_ref)
  expect Script(self_script) = address.payment_credential

  when (datum, cc_action) is {
    // Register Customer:
    (Some(current_datum), Register) ->
      if current_datum is CustomerDatum {
        tx |> validate_register_customer(current_datum, creator, customer)
      } else {
        fail @"Invalid Customer Datum Type! Must be CustomerDatum"
      }
    // Register Verifier:
    (Some(current_datum), Register) ->
      if current_datum is verifier_datum: VerifierDatum {
        tx
          |> validate_register_verifier(verifier_datum, creator, verifier)
      } else {
        fail @"Invalid Verifier Datum Type! Must be VerifierDatum"
      }

    // Register Credit_holder:
    (Some(current_datum), Register) ->
      if current_datum is creditholder_datum: CreditHolderDatum {
        tx
          |> validate_register_credit_holder(
              creditholder_datum,
              creator,
              creditHolder,
            )
      } else {
        fail @"Invalid CreditHolder Datum Type! Must be CreditHolderDatum"
      }

    //if datum customer action purchase
    (Some(current_datum), Purchase) ->
      if current_datum is customer_datum: CustomerDatum {
        tx |> validate_purchase(customer_datum, customer, verifier)
      } else {
        fail @"Invalid Customer Datum Type! Must be CustomerDatum"
      }
  }
}

pub fn validate_mint_campaign(
  customer: VerificationKeyHash,
  creator: VerificationKeyHash,
  verifier: VerificationKeyHash,
  creditHolder: VerificationKeyHash,
  nonce: OutputReference,
  creditholder_datum: CreditHolderDatum,
  self_script: PolicyId,
  tx: Transaction,
) -> Bool {
  // if datum is creditHolder Action Mint
  when (datum, CCRedeemer) is {
    (Some(current_datum), Mint) ->
      if current_datum is creditholder_datum: CreditHolderDatum {
        tx
          |> mint_CC(
              self_script,
              CreditHolderDatum,
              creditHolder: VerificationKeyHash,
              verifier,
            )
      } else {
        fail @"Invalid CreditHolder Datum Type! Must be CreditHolderDatum"
      }
    // if datum is customer Action burn && mint nft
    (Some(current_datum), Burn) ->
      if current_datum is customer_datum: CustomerDatum {
        tx |> validate_burn(self_script, CustomerDatum, verifier)
      } else {
        fail @"Invalid Customer Datum Type! Must be CustomerDatum"
      }
  }
}

// ## Validation Functions

//register customer
fn validate_register_customer(
  tx: Transaction,
  customer_datum: CustomerDatum,
  creator: VerificationKeyHash,
  customer: VerificationKeyHash,
) -> Bool {
  let is_signed_by_creator = tx |> must_be_signed_by(creator)
  expect CustomerDatum { name, customer: (pkh, _), emission } = customer_datum
  expect customer == pkh
  if emission > 1 {
    True
  } else {
    // Valid case
    fail @"Emission must be greater than 1"
  }
}

//register verifier
fn validate_register_verifier(
  tx: Transaction,
  verifier_datum: VerifierDatum,
  creator: VerificationKeyHash,
  verifier: VerificationKeyHash,
) -> Bool {
  let is_signed_by_creator = tx |> must_be_signed_by(creator)
  expect VerifierDatum { name, verifier: (pkh, _), emission } = verifier_datum
  expect verifier == pkh
  if emission == 1 {
    True
  } else {
    // Valid case
    fail @"Emission must be greater than 1"
  }
}

//register credit holder
fn validate_register_credit_holder(
  tx: Transaction,
  creditholder_datum: CreditHolderDatum,
  creator: VerificationKeyHash,
  creditHolder: VerificationKeyHash,
) -> Bool {
  let is_signed_by_creator = tx |> must_be_signed_by(creator)
  expect CreditHolderDatum { name, creditHolder: (pkh, _), emission } =
    creditholder_datum
  expect creditHolder == pkh
  if emission < 1 {
    True
  } else {
    // Valid case
    fail @"Emission must be greater than 1"
  }
}

//validate purchase
fn validate_purchase(
  tx: Transaction,
  customer_datum: CustomerDatum,
  verifier: VerificationKeyHash,
  customer: VerificationKeyHash,
) -> Bool {
  let is_signed_by_customer = tx |> must_be_signed_by(customer)
  let is_signed_by_verifier = tx |> must_be_signed_by(verifier)
  expect CustomerDatum { name, customer: (pkh, _), emission } = customer_datum
  expect customer == pkh
  if emission > 1 {
    True
  } else {
    // Valid case
    fail @"Emission must be greater than 1"
  }
}

//Mint tokens
fn must_mint_CC_token(
  tx: Transaction,
  self_script: PolicyId,
  creditHolder: VerificationKeyHash,
  verifier: VerificationKeyHash,
) -> Bool {
  let [Pair(asset_name, ammount)] =
    tx.mint |> assets.tokens(self_script) |> dict.to_pairs()
  let is_signed_by_credit_holder =
    tx |> ( must_be_signed_by(creditHolder) && must_be_signed_by(verifier) )
}

//Burn tokens
fn validate_burn(
  tx: Transaction,
  self_script: PolicyId,
  CustomerDatum,
  verifier,
  customer,
) -> Bool {
  let minted_tokens = tx.mint |> assets.tokens(self_script) |> dict.to_pairs()
  ([Pair(config.carbon_token, -Int)] == minted_tokens)?
  let is_signed_by_credit_holder =
    tx |> ( must_be_signed_by(customer) && must_be_signed_by(verifier) )
  if CustomerDatum.emission < 1 {
    tx |> mint_nft(self_script, CustomerDatum)
  } else {
    fail @"Invalid tx"
  }
}

//Mint nft and validate send to customer address
fn mint_nft(
  tx: Transaction,
  self_script: PolicyId,
  asset_name: ByteArray,
  utxo_ref: OutputReference,
  CustomerDatum,
) -> Bool {
  let [Pair(asset_name, ammount)] =
    tx.mint |> assets.tokens(self_script) |> dict.to_pairs()
  let is_signed_by_credit_holder = tx |> must_be_signed_by(customer)
  let customer_address = utils.address_from_tuple(CustomerDatum)
  let c_address =
    fn(Output { address, value, .. }) { expect c_address == customer_address }
}

fn must_be_signed_by(tx: Transaction, signer: VerificationKeyHash) -> Bool {
  ([signer] == tx.extra_signatories)?
}
