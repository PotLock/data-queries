-- daily direct donations trends on potlock https://flipsidecrypto.xyz/Lordking/q/ImKy7HXDojOU/direct-donation---daily && https://flipsidecrypto.xyz/Lordking/potlock-UD3Flm?tabIndex=1
---------------------------------------------------------------------
-- L1 fail_receipts 👉 8dcb1456-c2a7-4e2d-b794-57000ac1f752

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
          
                 
                distinct 
                call.BLOCK_TIMESTAMP,
                call.SIGNER_ID as SIGNER_ID,
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
          group by 1,2,3,10,5,6,7,8,9
          )

, donations as 
          (select 
                BLOCK_TIMESTAMP::date as "date" ,
                count(distinct SIGNER_ID) as "Donor",
                sum(DEPOSIT) as "Donated (near)",
                sum(USD) as "Donated (USD)",
                sum(current_usd) as "Current value (USD)",
                count(distinct recipient_id) as "Donated to(projects)",
                --call.ARGS:bypass_protocol_fee as "Bypass protocol fee",
                count(distinct message) as "Message" ,
                count( referrer_id)  as "Referrals used" ,
                count(distinct TX_HASH) as "Transaction"
          from donation
          group by 1 
          order by 2 desc )

select 
      "date" ,
      "Donated (near)",
      "Donated (USD)",
      "Current value (USD)",
      "Donated to(projects)",
      "Message" ,
      "Referrals used" ,
      "Transaction",
      sum ("Donated (near)") over (order by "date" asc) as "Donated (near) growth",
      sum ("Donated (USD)") over (order by "date" asc) as "Donated (USD) growth",
      sum ("Current value (USD)") over (order by "date" asc) as "Current value (USD) growth",
      sum ("Donated to(projects)") over (order by "date" asc ) as "Donated to(projects) growth",
      sum ("Message") over (order by "date" asc) as "Message growth",
      sum ("Referrals used") over (order by "date" asc) as "Referrals used growth",
      sum ("Transaction") over (order by "date" asc) as "Transaction growth"
from donations 



 

 

