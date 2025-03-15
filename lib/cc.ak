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

pub fn validate_spend_cc(
  creator: VerificationKeyHash,
  verifier: VerificationKeyHash,
  creditHolder: VerificationKeyHash,
  customer: VerificationKeyHash,
  datum: Option<Data>,
  cc_action: CCRedeemer,
  self_script: policy_id,
  o_ref: OutputReference,
  tx: Transaction,
) -> Bool {
  expect Some(Input { output: Output { address, .. }, .. }) =
    tx.inputs |> transaction.find_input(o_ref)
  expect Script(self_script) = address.payment_credential

  when (datum, cc_action) is {
    // Register-related actions:
    (Some(current_datum), Register) ->
      if current_datum is CustomerDatum {
        tx |> validate_register_customer(current_datum, creator, customer)
      } else if current_datum is verifier_datum: VerifierDatum {
        tx |> validate_register_verifier(verifier_datum, creator, verifier)
      } else if current_datum is creditholder_datum: CreditHolderDatum {
        tx
          |> validate_register_credit_holder(
              creditholder_datum,
              creator,
              creditHolder,
            )
      } else {
        fail @"Invalid Datum Type! Must be CustomerDatum, VerifierDatum, or CreditHolderDatum"
      }

    // Purchase action:
    (Some(current_datum), Purchase) ->
      if current_datum is customer_datum: CustomerDatum {
        tx |> validate_purchase(customer_datum, customer, verifier)
      } else {
        fail @"Invalid Customer Datum Type! Must be CustomerDatum"
      }

    // Catch-all for unhandled patterns:
    _ -> fail @"Unsupported action or missing datum"
  }
}

pub fn validate_mint_cc(
  customer: VerificationKeyHash,
  creator: VerificationKeyHash,
  verifier: VerificationKeyHash,
  creditHolder: VerificationKeyHash,
  cc_action: CCRedeemer,
  datum: Option<Data>,
  self_script: PolicyId,
  tx: Transaction,
) -> Bool {
  // if datum is creditHolder Action Mint
  when (datum, cc_action) is {
    (Some(current_datum), Mint) ->
      if current_datum is creditholder_datum: CreditHolderDatum {
        tx |> mint_cc(self_script, creditHolder, creditholder_datum, verifier)
      } else {
        fail @"Invalid CreditHolder Datum Type! Must be CreditHolderDatum"
      }
    (Some(current_datum), Burn) ->
      if current_datum is customer_datum: CustomerDatum {
        tx |> validate_burn(self_script, customer, customer_datum, verifier)
      } else {
        fail @"Invalid Customer Datum Type! Must be CustomerDatum"
      }
    _ -> fail @"Unsupported action or missing datum"
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
fn mint_cc(
  tx: Transaction,
  self_script: PolicyId,
  creditHolder: VerificationKeyHash,
  creditholder_datum: CreditHolderDatum,
  verifier: VerificationKeyHash,
) -> Bool {
  let minted_tokens = tx.mint |> assets.tokens(self_script) |> dict.to_pairs()
  let is_signed_by_credit_holder = tx |> must_be_signed_by(creditHolder)
  let is_signed_by_verifier = tx |> must_be_signed_by(verifier)
  expect CreditHolderDatum { name, creditHolder: (pkh, _), emission } =
    creditholder_datum
  expect creditHolder == pkh
  when minted_tokens is {
    [Pair(carbon_token, _)] ->
      if is_signed_by_credit_holder && is_signed_by_verifier {
        True
      } else {
        // Valid minting case
        fail @"Missing required signatures or invalid amount"
      }

    _ -> fail @"Minting must involve exactly one token pair"
  }
}

//Burn tokens
fn validate_burn(
  tx: Transaction,
  self_script: PolicyId,
  customer: VerificationKeyHash,
  customer_datum: CustomerDatum,
  verifier: VerificationKeyHash,
) -> Bool {
  let minted_tokens = tx.mint |> assets.tokens(self_script) |> dict.to_pairs()
  expect CustomerDatum { name, customer: (pkh, _), emission } = customer_datum
  let is_valid_tokens =
    when minted_tokens is {
      [Pair(carbon_token, amount)] -> amount < 0
      // Ensure the value is negative
      _ -> False
    }
  // No valid token pair found
  if is_valid_tokens && emission < 1 {
    tx |> mint_nft(self_script, customer, customer_datum)
  } else {
    fail @"Invalid tx"
  }
}

//Mint nft and validate send to customer address
fn mint_nft(
  tx: Transaction,
  self_script: PolicyId,
  customer: VerificationKeyHash,
  customer_datum: CustomerDatum,
) -> Bool {
  let minted_tokens = tx.mint |> assets.tokens(self_script) |> dict.to_pairs()
  let outputs = tx.outputs
  expect CustomerDatum { name, customer: (pkh, skh), emission } = customer_datum
  let tuple = customer_datum.customer
  let customer_address = utils.address_from_tuple(tuple)
  let carbonnft = config.carbonnft

  // Iterate through transaction outputs and find the matching output
  when outputs is {
    [Output { address, value, .. }] -> {
      // Destructure customer_datum to extract pkh and emission
      expect customer == pkh

      // Convert `customer` tuple into an address and compare with extracted address
      if address == customer_address {
        // Perform further checks for minted tokens
        if minted_tokens == [Pair(carbonnft, 1)] {
          let is_signed_by_customer = tx |> must_be_signed_by(customer)
          if is_signed_by_customer {
            True
          } else {
            // Fail if the transaction is not signed by the customer
            fail @"Transaction not signed by credit holder"
          }
        } else {
          // Fail if the minted tokens do not match the expected tokens
          fail @"Minted tokens do not match the expected Carbon NFT"
        }
      } else {
        // Fail if the transaction output address does not match the customer's address
        fail @"Transaction output address does not match customer address"
      }
    }
    _ ->
      // Fail if no matching outputs are found
      fail @"No matching output found in transaction outputs"
  }
}

fn must_be_signed_by(tx: Transaction, signer: VerificationKeyHash) -> Bool {
  ([signer] == tx.extra_signatories)?
}
