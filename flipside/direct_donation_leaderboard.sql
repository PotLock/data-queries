
---------------------------------------------------------------------
-- L1 fail_receipts 👉 8dcb1456-c2a7-4e2d-b794-57000ac1f752
-- from https://flipsidecrypto.xyz/Lordking/q/uGF5B9TE6HoN/direct-donation---donors-leaderboard and https://flipsidecrypto.xyz/Lordking/potlock-UD3Flm?tabIndex=1
with 
raw as (
      SELECT livequery.live.udf_api(
            'GET',
            'https://api.flipsidecrypto.com/api/v2/queries/8dcb1456-c2a7-4e2d-b794-57000ac1f752/data/latest',
            {'accept': 'application/json'},{}) as response)

,raw_data as (
SELECT
      VALUE:"TX_HASH" as "TX_HASH" 
        FROM raw,LATERAL FLATTEN (input => response:data)
),
donation as 
          (select 
          
                 
                distinct call.SIGNER_ID as SIGNER_ID,
                call.DEPOSIT/pow(10,24) as DEPOSIT,
                round(call.DEPOSIT/pow(10,24)* avg(PRICE_USD)) as USD,
                round(call.DEPOSIT/pow(10,24)*(select avg(PRICE_USD) from near.price.fact_prices where date_trunc('minute',TIMESTAMP) = (select max(date_trunc('minute',TIMESTAMP)) from near.price.fact_prices) and  SYMBOL='wNEAR' )) as current_usd,
                call.ARGS:recipient_id as recipient_id,
                call.ARGS:bypass_protocol_fee,
                call.ARGS:message as message,
                call.ARGS:referrer_id as referrer_id ,
                call.TX_HASH 
          
           from near.core.fact_actions_events_function_call call inner join near.core.fact_transfers transfers
                      on call.tx_hash = transfers.tx_hash
                inner join near.price.fact_prices
                      on (date_trunc('minute',TIMESTAMP) = date_trunc('minute',call.BLOCK_TIMESTAMP) and date_trunc('day',TIMESTAMP) = date_trunc('day',call.BLOCK_TIMESTAMP))
          where call.receiver_id = 'donate.potlock.near'
                and method_name = 'donate'
                and ACTION_NAME='FunctionCall'
                and TX_SUCCEEDED = TRUE 
                and SYMBOL ='wNEAR'
                and call.tx_hash not in (select distinct tx_hash from raw_data )
          group by 1,2,4,5,6,7,8,9
          )
select 
      SIGNER_ID as "Donor",
      sum(DEPOSIT) as "Deposit (near)",
      sum(USD) as "Deposit (USD)",
      sum(current_usd) as "Current value (USD)",
      count(distinct recipient_id) as "Donated to",
      --call.ARGS:bypass_protocol_fee as "Bypass protocol fee",
      count(distinct message) as "Message" ,
      count( referrer_id)  as "Referrals  used" ,
      count(distinct TX_HASH) as "Transaction"
from donation
group by 1 
order by 2 desc 






  -- and TX_SUCCEEDED = TRUE
  -- and RECIPIENT_ID='potlock.near'
  -- and SIGNER_ID='root.near'

 

