use aiken/crypto.{VerificationKeyHash}
use cardano/assets.{PolicyId}
use cardano/transaction.{OutputReference, Transaction}
use cc
use cc/types.{
  CCRedeemer, CreatorDatum, CreatorDatum, CustomerDatum, VerifierDatum,
}

validator campaign(
  customer: VerificationKeyHash,
  creator: VerificationKeyHash,
  nonce: OutputReference,
  verifier: VerificationKeyHash,
  creditHolder: VerificationKeyHash,
) {
  spend(
    datum: Option<Data>,
    redeemer: CCRedeemer,
    o_ref: OutputReference,
    tx: Transaction,
  ) {
    crowdfunding.validate_spend_campaign(
      self_script,
      customer,
      verifier,
      creditHolder,
      creator,
      datum,
      redeemer,
      o_ref,
      tx,
    )
  }

  mint(datum: Option<Data>, policy_id self_script: PolicyId, tx: Transaction) {
    crowdfunding.validate_mint_campaign(
      customer,
      verifier,
      creditHolder,
      creator,
      nonce,
      datum,
      self_script,
      tx,
    )
  }

  else(_) {
    fail
  }
}
