-- Weight Change on NEAR Social Profile Check After Reductions https://flipsidecrypto.xyz/wownorth/q/askRi_2zSDJQ/weight-change-affect-of-has_complete_profile_check-detail && https://flipsidecrypto.xyz/wownorth/plotlock-plotlock-A36Irq

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
select weight
from main
where check_type = 'has_complete_profile_check'
order by block_timestamp desc
limit 1
),

threshold as (
select TRY_PARSE_JSON(ARGS):default_human_threshold::INT as thresh
from qmain
where thresh is not null ),

updated_main as (select m.*,
  case 
    when (check_type = 'has_complete_profile_check' and m.weight != w.weight) then w.weight
    else m.weight 
  end as adjusted_weight
from main m, weight_change_time w),

human_list_previouse as (
select signer_id,sum(weight) as total_weight
from main
where method_name = 'verify_stamp_callback'  
group by signer_id
having total_weight >= (select thresh from threshold)
order by total_weight desc),

human_list_current as (
select signer_id,sum(adjusted_weight) as total_weight
from updated_main
where method_name = 'verify_stamp_callback'  
group by signer_id
having total_weight >= (select thresh from threshold)
order by total_weight desc)

-- select count(hp.*) as previouse_count, count(hc.*) as current_count
-- from human_list_previouse hp, human_list_current hc

select block_timestamp,
    signer_id,contract_address,check_type,weight,adjusted_weight
from updated_main
where adjusted_weight != weight and method_name = 'verify_stamp_callback'
