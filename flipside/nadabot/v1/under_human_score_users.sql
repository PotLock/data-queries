-- Under Human Score Users https://flipsidecrypto.xyz/wownorth/q/rUcctM30Qnp1/not-human && https://flipsidecrypto.xyz/wownorth/plotlock-plotlock-A36Irq

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
    receiver_id,
    method_name,
    deposit,
    SPLIT_PART(PARSE_JSON(ARGS) :provider_id, ':', 1) AS contract_address,
    SPLIT_PART(PARSE_JSON(ARGS) :provider_id, ':', 2) AS check_type,
    COALESCE(TRY_PARSE_JSON(ARGS):provider.default_weight, 0)::INT AS weight
  from 
    qmain
  where receiver_id = 'v1.nadabot.near'
),

threshold as (
select TRY_PARSE_JSON(ARGS):default_human_threshold::INT as thresh
from qmain
where thresh is not null ),

not_human_list as (
select signer_id,sum(weight) as total_weight
from main
where method_name = 'verify_stamp_callback'  
group by signer_id
having total_weight < (select thresh from threshold)
order by total_weight desc)

select m.signer_id,CONCAT(m.contract_address,':',m.check_type) as contactAD_checktype, m.weight
from main m
where m.signer_id in (select signer_id from not_human_list) and method_name = 'verify_stamp_callback' 
order by m.signer_id


