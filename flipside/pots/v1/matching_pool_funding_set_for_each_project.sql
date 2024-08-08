-- Amount of Funding Set Per Matching Pool for Projects in v1 Pots https://flipsidecrypto.xyz/Lordking/q/127QzL8yRsC8/54bb3087-31aa-4dc5-b565-f6c2729e3d77 && https://flipsidecrypto.xyz/Lordking/potlock-UD3Flm?tabIndex=5

---------------------------------------------------------------------
-- L1 Set funding  👉 57b4bee1-6047-48b3-98da-1490b7a5fff4

with 
raw as (
      SELECT livequery.live.udf_api(
            'GET',
            'https://api.flipsidecrypto.com/api/v2/queries/57b4bee1-6047-48b3-98da-1490b7a5fff4/data/latest',
            {'accept': 'application/json'},{}) as response)

,raw_data as (
SELECT
      VALUE:"Time" as "Time" ,
      VALUE:"POT" as "POT" ,
      VALUE:"Payouts Info" as "Payouts Info"  ,
      VALUE:"Transaction" as "Transaction" 
        FROM raw,LATERAL FLATTEN (input => response:data)
)
---------------------------------------------------------------------
-- L1 POT INFO 👉 7aee8471-1543-4e18-9f44-c93a0b02434f
 
,raw_pot as (
      SELECT livequery.live.udf_api(
            'GET',
            'https://api.flipsidecrypto.com/api/v2/queries/7aee8471-1543-4e18-9f44-c93a0b02434f/data/latest',
            {'accept': 'application/json'},{}) as response)

,raw_data_pot as (SELECT
      VALUE:"POT_Name" as "POT_Name" ,
      VALUE:"POT_Contract" as "POT_Contract" 
        FROM raw_pot,LATERAL FLATTEN (input => response:data)
)

----------------------------------------------------------------------------
,pot as ( SELECT
              VALUE :project_id as "Project" ,
              round(VALUE :amount/1e24,2) as "Amount" ,
              "Transaction",
              "Time",
              "POT"
          FROM
             raw_data,
             LATERAL FLATTEN (
                    input => "Payouts Info"
             ) 
)
---------------------------------------------------------
select 
      "Project",
      "Amount",
      --round("Amount"* avg(PRICE)) as "Amount (USD)",
      round("Amount"*(select avg(PRICE) from near.price.ez_prices_hourly where date_trunc('minute',HOUR) = (select max(date_trunc('minute',HOUR)) from near.price.ez_prices_hourly) and  SYMBOL='wNEAR' )) as "Current value (USD)",
       "POT_Name"
from pot inner join raw_data_pot 
on "POT_Contract"  = "POT"
group by 1,2,4 order by 2 desc 

 