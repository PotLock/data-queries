-- Average Time Until First Direct Donation After Project Creation https://flipsidecrypto.xyz/wownorth/q/ZN9u8tICEFqD/project-registration-until-first-donation && https://flipsidecrypto.xyz/wownorth/plotlock-plotlock-A36Irq?tabIndex=2
-- This is based on old registry contracts swithc to lists.potlock.near
-- forked from brian-terra / All Potlock Registers @ https://flipsidecrypto.xyz/brian-terra/q/_CbXCPpmisyW/all-potlock-registers

-- forked from All Potlock Donations @ https://flipsidecrypto.xyz/edit/queries/9297bc52-b0cc-4a3c-b2bc-dcd99993c7be

WITH txns as 
(select  distinct tx_hash, transaction_fee as tx_fee
 from near.core.fact_transactions b 
where (tx_receiver = 'registry.potlock.near'
  or   tx_signer = 'registry.potlock.near')
  -- change to lists.potlock.near (new registry and state was migrated)
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

first_donation as (
SELECT receiver_id, min(block_timestamp) as first_donate
from qmain_donate
group by receiver_id
),

main as (
SELECT DISTINCT
  p.signer_id,
  f.receiver_id,
  f.first_donate,
  DATEDIFF(day, p.project_create, f.first_donate) as time_difference
FROM project_created p
FULL OUTER JOIN first_donation f ON f.receiver_id = p.signer_id
WHERE NOT (p.signer_id IS NULL or f.receiver_id IS NULL)
)

select min(time_difference) as minimum,avg(time_difference) as average_time, max(time_difference) as maximum
from main
