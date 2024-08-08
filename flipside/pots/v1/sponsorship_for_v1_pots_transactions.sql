-- Sponsorship Transactions for v1 Pots https://flipsidecrypto.xyz/Lordking/q/f_DmEnHF3vef/9286c080-e487-4fb3-a969-7b6d6bad991d && https://flipsidecrypto.xyz/Lordking/potlock-UD3Flm?tabIndex=4
---------------------------------------------------------------------
-- L1 POT INFO 👉 7aee8471-1543-4e18-9f44-c93a0b02434f

with 
raw as (
      SELECT livequery.live.udf_api(
            'GET',
            'https://api.flipsidecrypto.com/api/v2/queries/7aee8471-1543-4e18-9f44-c93a0b02434f/data/latest',
            {'accept': 'application/json'},{}) as response)

,raw_data as (SELECT
      VALUE:"POT_Name" as "POT_Name" ,
      VALUE:"POT_Contract" as "POT_Contract" 
        FROM raw,LATERAL FLATTEN (input => response:data)
)
---------------------------------------------------------------------------


select 
      distinct
      call.SIGNER_ID as "Sponsor",
      split(call.BLOCK_TIMESTAMP,' ')[0] as "Time",
      "POT_Name",
      call.ARGS:bypass_protocol_fee as  "bypass_protocol_fee" ,
      call.DEPOSIT/pow(10,24) as "Deposited (near)",
      round(call.DEPOSIT/pow(10,24)* avg(PRICE_USD)) as "Deposited (USD)",
      round(call.DEPOSIT/pow(10,24)*(select avg(PRICE_USD) from near.price.fact_prices where date_trunc('minute',TIMESTAMP) = (select max(date_trunc('minute',TIMESTAMP)) from near.price.fact_prices) and  SYMBOL='wNEAR' )) as "Current value (USD) of Sponsorship",
      call.TX_HASH as "Transaction"

from near.core.fact_actions_events_function_call call 
    inner join raw_data 
        on call.RECEIVER_ID="POT_Contract"
    inner join near.price.fact_prices
        on (date_trunc('minute',TIMESTAMP) = date_trunc('minute',call.BLOCK_TIMESTAMP) and date_trunc('day',TIMESTAMP) = date_trunc('day',call.BLOCK_TIMESTAMP))

where  RECEIPT_SUCCEEDED ='TRUE'
      and ACTION_NAME ='FunctionCall'
      and METHOD_NAME='donate'
      and call.ARGS:matching_pool ='true'
      and SYMBOL ='wNEAR'
group by 1,2,3,4,5,7,8
order by 3,  5 desc 

