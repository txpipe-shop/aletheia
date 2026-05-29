use aiken/crypto.{DataHash, ScriptHash, VerificationKeyHash}
use cardano/address.{Address, Credential}
use cardano/assets.{AssetName, Lovelace, PolicyId}
use cardano/certificate.{Certificate}
use cardano/governance.{TransactionId, Voter}
use cardano/transaction.{Datum, OutputReference, ValidityRange}

// Transaction type definitions matching the plutus.json blueprint.
//
// These are the domain types used by the off-chain TypeScript code
// (via @blaze-cardano/sdk) to convert raw Cardano transactions into
// structured Plutus data for on-chain validation.

pub type UnsafeInput {
  output_reference: OutputReference,
  output: UnsafeOutput,
}

/// An output of the transaction.
pub type UnsafeOutput {
  address: Address,
  value: Pairs<PolicyId, Pairs<AssetName, Int>>,
  datum: Datum,
  reference_script: Option<ScriptHash>,
}

/// Mirrors ScriptPurpose from the Aiken stdlib with an additional
/// `UnsafePropose` variant for governance proposals.
pub type UnsafeScriptPurpose {
  Mint(PolicyId)
  Spend(OutputReference)
  Withdraw(Credential)
  Publish { at: Int, certificate: Certificate }
  Vote(Voter)
  UnsafePropose { at: Int, proposal_procedure: Never }
}

/// The full transaction context passed to the on-chain validator.
///
/// Fields typed as `Never` (`votes`, `proposal_procedures`) are
/// intentionally unsupported and are hardcoded to empty defaults
/// during conversion to the stdlib `Transaction`.
pub type UnsafeTransaction {
  inputs: List<UnsafeInput>,
  reference_inputs: List<UnsafeInput>,
  outputs: List<UnsafeOutput>,
  fee: Lovelace,
  mint: Pairs<PolicyId, Pairs<AssetName, Int>>,
  certificates: List<Certificate>,
  withdrawals: Pairs<Credential, Lovelace>,
  validity_range: ValidityRange,
  extra_signatories: List<VerificationKeyHash>,
  redeemers: Pairs<UnsafeScriptPurpose, Data>,
  datums: Pairs<DataHash, Data>,
  id: TransactionId,
  votes: Never,
  proposal_procedures: Never,
  current_treasury_amount: Option<Lovelace>,
  treasury_donation: Option<Lovelace>,
}
