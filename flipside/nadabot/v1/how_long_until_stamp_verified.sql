-- how long it takes for stamp to be verified https://flipsidecrypto.xyz/wownorth/q/AN45eIoBkpZM/how-long-it-takes-an-account-to-be-verified && https://flipsidecrypto.xyz/wownorth/plotlock-plotlock-A36Irq

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
having total_weight >= (select thresh from threshold)
order by total_weight desc),

add_stamp as (
select block_timestamp,
       signer_id,
       method_name,
       contract_address,
       check_type,
       weight
from main
where method_name = 'add_stamp'   
),

verified_stamp as (
select block_timestamp,
       signer_id,
       method_name,
       contract_address,
       check_type,
       weight
from main
where method_name = 'verify_stamp_callback' 
),

combined as (
select a.*, v.block_timestamp as verified_time, 
      v.weight as verified_weight,
      DATEDIFF(second,a.block_timestamp,v.block_timestamp) as time_cost
from add_stamp a
join verified_stamp v on v.signer_id = a.signer_id 
  and a.check_type = v.check_type
)
-- check if it been add
select avg(time_cost) 
from combined