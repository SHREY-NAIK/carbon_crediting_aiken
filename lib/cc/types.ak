use aiken/crypto.{VerificationKeyHash}

pub type PaymentKeyHash =
  VerificationKeyHash

pub type StakeKeyHash =
  VerificationKeyHash

pub type CreatorDatum {
  name: ByteArray,
  creator: (PaymentKeyHash, StakeKeyHash),
}

pub type CreditHolderDatum {
  name: ByteArray,
  creditHolder: (PaymentKeyHash, StakeKeyHash),
  emission: Int,
}

pub type VerifierDatum {
  name: ByteArray,
  verifier: (PaymentKeyHash, StakeKeyHash),
  emission: Int,
}

pub type CustomerDatum {
  name: ByteArray,
  customer: (PaymentKeyHash, StakeKeyHash),
  emission: Int,
}

// ## Redeemer

pub type CCRedeemer {
  Register
  Purchase
  Mint
  Burn
}
