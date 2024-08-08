-- how many humans above current human score https://flipsidecrypto.xyz/wownorth/q/UVxV9fkvnWNT/weight-threshold and https://flipsidecrypto.xyz/wownorth/plotlock-plotlock-A36Irq

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

temp as (
  select signer_id,sum(weight) as total_weight
  from main
  where method_name = 'verify_stamp_callback'
  group by signer_id
  order by total_weight desc
),

threshold as (
select TRY_PARSE_JSON(ARGS):default_human_threshold::INT as thresh
from qmain
where thresh is not null 

)

select *
from ( select count(*) as above
       from temp
       where total_weight >= (select thresh from threshold)) a, 
     (select avg(total_weight) as average_weight
       from temp) b, threshold c