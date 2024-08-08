-- information about checks https://flipsidecrypto.xyz/wownorth/q/2PUrYuIOOgpU/checks-information && https://flipsidecrypto.xyz/wownorth/plotlock-plotlock-A36Irq

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
    PARSE_JSON(ARGS) :provider_id AS contract_address_check_type,
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

),

ranked_data AS (
    SELECT 
        contract_address_check_type,
        weight,
        block_timestamp,
        ROW_NUMBER() OVER (PARTITION BY contract_address_check_type ORDER BY block_timestamp DESC) AS rn
    FROM 
        main
    WHERE 
        method_name = 'verify_stamp_callback' 
        AND check_type != 'has_complete_social_profile_check'
)
SELECT 
    case 
      when contract_address_check_type like '%connected_to_lens%' then 'Lens Profile Verification'
      when contract_address_check_type like '%connected_to_twitter%' then 'X Profile Verification'
      when contract_address_check_type like '%six_month_old%' then 'Six Months Old Account Check'
      when contract_address_check_type like '%is_human_bool%' then 'I-Am-Human'
      when contract_address_check_type like '%has_complete_profile_check%' then 'Complete NEAR Social'
      when contract_address_check_type like '%has_gov_id_sbt%' then 'Holonym ZK ID (Unique Government ID)'
      when contract_address_check_type like '%has_phone_sbt%' then 'Holonym ZK ID (Unique Phone)'
      when contract_address_check_type like '%connected_to_5_contracts%' then 'Five Contract Connections'
      else 'Farcaster Profile Verification'
      end as check_name,
    contract_address_check_type,
    weight,
    block_timestamp
FROM 
    ranked_data
WHERE 
    rn = 1;
