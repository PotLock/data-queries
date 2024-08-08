-- number of users per check https://flipsidecrypto.xyz/wownorth/q/0oL54J7OcEQI/number-of-user-per-check && https://flipsidecrypto.xyz/wownorth/plotlock-plotlock-A36Irq
WITH txns as 
(select  distinct tx_hash, transaction_fee as tx_fee
 from near.core.fact_transactions b 
where (tx_receiver = 'v1.nadabot.near'
  or   tx_signer = 'v1.nadabot.near'
  and tx_succeeded = TRUE))
,
qmain as (
select  block_timestamp,
        ARGS,
        b.tx_hash,
        signer_id,
        ACTION_NAME,
        receiver_id,
        method_name,
        --args,
        deposit  / 1e24 as deposit
 from near.core.fact_actions_events_function_call b, txns
where b.tx_hash = txns.tx_hash
),

main as (
SELECT
    block_timestamp,
    signer_id,
    receiver_id,
    method_name,
    deposit,
    SPLIT_PART(PARSE_JSON(ARGS):provider_id, ':', 1) AS contract_address,
    SPLIT_PART(PARSE_JSON(ARGS):provider_id, ':', 2) AS check_type
from qmain),

second as (select contract_address,check_type,count(*) as user_count
from main
where method_name = 'verify_stamp_callback'
group by check_type,contract_address
order by user_count desc)

select * 
from second
where check_type in (select DISTINCT check_type from main where method_name = 'add_stamp')
order by user_count DESC

