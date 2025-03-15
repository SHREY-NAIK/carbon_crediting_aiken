use aiken/crypto.{VerificationKeyHash}
use cardano/assets.{PolicyId}
use cardano/transaction.{OutputReference, Transaction}
use cc
use cc/types.{
  CCRedeemer, CreatorDatum, CreditHolderDatum, CustomerDatum, VerifierDatum,
}

validator carbon_crediting(
  customer: VerificationKeyHash,
  creator: VerificationKeyHash,
  verifier: VerificationKeyHash,
  creditHolder: VerificationKeyHash,
  self_script: PolicyId,
) {
  spend(
    datum: Option<Data>,
    redeemer: CCRedeemer,
    o_ref: OutputReference,
    tx: Transaction,
  ) {
    cc.validate_spend_cc(
      creator,
      verifier,
      creditHolder,
      customer,
      datum,
      redeemer,
      self_script,
      o_ref,
      tx,
    )
  }

  mint(datum: Option<Data>, redeemer: CCRedeemer, tx: Transaction) {
    cc.validate_mint_cc(
      customer,
      creator,
      verifier,
      creditHolder,
      redeemer,
      datum,
      self_script,
      tx,
    )
  }

  else(_) {
    fail
  }
}
