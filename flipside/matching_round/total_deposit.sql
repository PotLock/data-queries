-- Query to count the total deposit made, forked from wownorth @ https://flipsidecrypto.xyz/wownorth/q/uHwJR57jbCkK/10-000-matching-round

WITH txns as (
  select
    distinct tx_hash,
    transaction_fee as tx_fee
  from
    near.core.fact_transactions b
  where
    (
      tx_receiver = 'creatives.v1.potfactory.potlock.near'
      or tx_signer = 'creatives.v1.potfactory.potlock.near'
    )
    and tx_succeeded = TRUE
),
qmain as (
  select
    block_timestamp,
    b.tx_hash,
    signer_id,
    receiver_id,
    method_name,
    --args,
    deposit / 1e24 as deposit
  from
    near.core.fact_actions_events_function_call b
    inner join txns on b.tx_hash = txns.tx_hash
)

select
  sum(Deposit) as total_deposit
from
  qmain