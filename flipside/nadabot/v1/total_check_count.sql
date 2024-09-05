-- Modified inner join under qmain cts, and updated final where clause
-- Updates enable the query to run efficiently under 600s constraint of flipside

WITH txns as (
  select
    distinct tx_hash,
    transaction_fee as tx_fee
  from
    near.core.fact_transactions b
  where
    (
      tx_receiver = 'v1.nadabot.near'
      or tx_signer = 'v1.nadabot.near'
      and tx_succeeded = TRUE
    )
),
qmain as (
  select
    block_timestamp,
    ARGS,
    b.tx_hash,
    signer_id,
    ACTION_NAME,
    receiver_id,
    method_name,
    --args,
    deposit / 1e24 as deposit
  from
    near.core.fact_actions_events_function_call b
    inner join txns
  where
    b.tx_hash = txns.tx_hash
),
main as (
  SELECT
    block_timestamp,
    signer_id,
    receiver_id,
    method_name,
    deposit,
    SPLIT_PART(PARSE_JSON(ARGS) :provider_id, ':', 1) AS contract_address,
    SPLIT_PART(PARSE_JSON(ARGS) :provider_id, ':', 2) AS check_type
  from
    qmain
)

select
  count(DISTINCT check_type) as check_type_count
from
  main
where
  method_name = 'add_stamp'
  and check_type != 'has_complete_profile_check'