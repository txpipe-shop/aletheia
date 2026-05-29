use aiken/collection/dict
use aiken/collection/list
use aletheia/unsafe_transaction.{
  Mint, Publish, Spend, UnsafeInput, UnsafeOutput, UnsafePropose,
  UnsafeScriptPurpose, UnsafeTransaction, Vote, Withdraw,
}
use cardano/assets
use cardano/transaction.{Input, Output, ScriptPurpose, Transaction}

pub fn unsafe_input_to_input(input: UnsafeInput) -> Input {
  Input {
    output_reference: input.output_reference,
    output: unsafe_output_to_output(input.output),
  }
}

/// Convert an `UnsafeOutput` into a stdlib `Output`.
pub fn unsafe_output_to_output(output: UnsafeOutput) -> Output {
  Output {
    address: output.address,
    value: assets.from_asset_list(output.value),
    datum: output.datum,
    reference_script: output.reference_script,
  }
}

/// Convert an `UnsafeScriptPurpose` into a stdlib `ScriptPurpose`.
///
/// # Panics
///
/// - when `Publish { at }` is negative (Index must be non-negative).
/// - when the `UnsafePropose` variant is reached (not yet supported; needs
///   `ProposalProcedure` type).
pub fn unsafe_script_purpose_to_script_purpose(
  purpose: UnsafeScriptPurpose,
) -> ScriptPurpose {
  when purpose is {
    Mint(policy_id) -> ScriptPurpose.Mint(policy_id)
    Spend(output_ref) -> ScriptPurpose.Spend(output_ref)
    Withdraw(credential) -> ScriptPurpose.Withdraw(credential)
    Publish { at, certificate } -> {
      expect at >= 0
      ScriptPurpose.Publish { at, certificate }
    }
    Vote(voter) -> ScriptPurpose.Vote(voter)
    UnsafePropose { .. } ->
      // UnsafePropose uses `Never` for `proposal_procedure`, making it
      // uninhabited. This branch is unreachable.
      fail @"UnsafePropose not supported yet"
  }
}

pub fn unsafe_redeemers_to_redeemers(
  redeemers: List<Pair<UnsafeScriptPurpose, Data>>,
) -> List<Pair<ScriptPurpose, Data>> {
  list.map(
    redeemers,
    fn(pair) {
      let Pair(purpose, data) = pair
      Pair(unsafe_script_purpose_to_script_purpose(purpose), data)
    },
  )
}

/// Convert an `UnsafeTransaction` into a stdlib `Transaction`.
///
/// `votes` and `proposal_procedures` are hardcoded to empty lists
/// because they are typed as `Never` in `UnsafeTransaction`.
pub fn unsafe_transaction_to_transaction(
  unsafe_tx: UnsafeTransaction,
) -> Transaction {
  Transaction {
    inputs: list.map(unsafe_tx.inputs, unsafe_input_to_input),
    reference_inputs: list.map(
      unsafe_tx.reference_inputs,
      unsafe_input_to_input,
    ),
    outputs: list.map(unsafe_tx.outputs, unsafe_output_to_output),
    fee: unsafe_tx.fee,
    mint: assets.from_asset_list(unsafe_tx.mint),
    certificates: unsafe_tx.certificates,
    withdrawals: unsafe_tx.withdrawals,
    validity_range: unsafe_tx.validity_range,
    extra_signatories: unsafe_tx.extra_signatories,
    redeemers: unsafe_redeemers_to_redeemers(unsafe_tx.redeemers),
    datums: dict.from_pairs(unsafe_tx.datums),
    id: unsafe_tx.id,
    votes: [],
    proposal_procedures: [],
    current_treasury_amount: unsafe_tx.current_treasury_amount,
    treasury_donation: unsafe_tx.treasury_donation,
  }
}
