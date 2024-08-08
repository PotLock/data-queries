-- Project Balance When Register on Deprecate registry.potlock.near contract (checks lists.potlock.near) now (essetially an array of registries) 
-- https://flipsidecrypto.xyz/wownorth/q/QdSKm83RIT_x/project-balance-upon-time-of-registration-sub3 && https://flipsidecrypto.xyz/wownorth/plotlock-plotlock-A36Irq?tabIndex=2


WITH txns as 
(select  distinct tx_hash, transaction_fee as tx_fee
 from near.core.fact_transactions b 
where (tx_receiver = 'registry.potlock.near'
-- change this to lists.potlock.near -- https://potlock.org/list-docs
  or   tx_signer = 'registry.potlock.near')
  and tx_succeeded = TRUE)
,
qmain as (
select  block_timestamp,
        b.tx_hash,
        signer_id,
        --args,
        deposit  / 1e24 as deposit
 from near.core.fact_actions_events_function_call b, txns
where b.tx_hash = txns.tx_hash
  and method_name = 'register'
),

txns_donate as 
(select  distinct a.tx_hash, transaction_fee as tx_fee
 from near.core.fact_actions_events_function_call a, near.core.fact_transactions b 
where receiver_id = 'donate.potlock.near'
  and method_name = 'donate'
  and a.tx_hash = b.tx_hash
  and tx_succeeded = TRUE)
,
qmain_donate as (
select  block_timestamp,
        b.action_name,
        signer_id,
        receiver_id,
        try_parse_json(b.action_data):"deposit"::float / 1e24 as deposit,
        txns_donate.tx_fee::float / 1e24 as tx_fee
 from near.core.fact_actions_events b, txns_donate
where b.tx_hash = txns_donate.tx_hash
  and b.action_name = 'Transfer'
  and b.receiver_id <> b.signer_id
  and receiver_id <> 'impact.sputnik-dao.near'
),

project_created as (
select signer_id, min(block_timestamp) as project_create
from qmain
group by signer_id),

count_donation AS (
  SELECT p.signer_id, COALESCE(SUM(q.deposit), 0) AS total_balance
  FROM project_created p
  LEFT JOIN qmain_donate q ON p.signer_id = q.receiver_id
  GROUP BY p.signer_id
)
-- record balance of each project upon registration
-- get average balance of project upon registration


-- get highest balance and which project
select signer_id,total_balance
from count_donation
ORDER BY total_balance DESC
limit 1
