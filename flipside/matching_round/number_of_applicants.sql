-- forked from wownorth / quadratic funding contract number of applicants @ https://flipsidecrypto.xyz/wownorth/q/LDcIWpQNTsdI/quadratic-funding-contract-number-of-applicants

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
    near.core.fact_actions_events_function_call b,
    txns
  where
    b.tx_hash = txns.tx_hash
),
qmain_sub as (
  select
    signer_id,
    receiver_id,
    method_name,
    deposit
  from
    qmain
) -- select DISTINCT method_name from qmain_sub
-- where receiver_id = 'creatives.v1.potfactory.potlock.near'

select
  count(*)
from
  qmain_sub
where
  method_name = 'apply'