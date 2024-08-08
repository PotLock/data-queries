-- Weight Change for Each Stamp https://flipsidecrypto.xyz/wownorth/q/0ENDCL_yW4zW/stamp-weight-change-check && https://flipsidecrypto.xyz/wownorth/plotlock-plotlock-A36Irq

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
    near.core.fact_actions_events_function_call b,
    txns
  where
    b.tx_hash = txns.tx_hash
),

main as (
  SELECT
    block_timestamp,
    signer_id,
    method_name,
    SPLIT_PART(PARSE_JSON(ARGS) :provider_id, ':', 1) AS contract_address,
    SPLIT_PART(PARSE_JSON(ARGS) :provider_id, ':', 2) AS check_type,
    COALESCE(TRY_PARSE_JSON(ARGS):provider.default_weight, 0)::INT AS weight
  from 
    qmain
  where receiver_id = 'v1.nadabot.near'
),

weight_change_time as (
SELECT
  check_type,
  weight,
  block_timestamp,
  ROW_NUMBER() OVER (PARTITION BY check_type, weight, DATE(block_timestamp) ORDER BY block_timestamp DESC) AS rn
FROM main
)

SELECT
check_type,
weight,
MAX(block_timestamp) AS weight_change_time
FROM weight_change_time
WHERE rn = 1
GROUP BY check_type, weight
ORDER BY check_type, weight_change_time
