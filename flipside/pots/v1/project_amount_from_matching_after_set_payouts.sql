-- Set Funding & Project Amount Per Pot https://flipsidecrypto.xyz/Lordking/q/zFDxkxe8yDPT/cbb8e2bd-cd4e-4ed3-91f1-9316ebc3dad2 && https://flipsidecrypto.xyz/Lordking/potlock-UD3Flm?tabIndex=5

---------------------------------------------------------------------
-- L1 Set funding  👉 54bb3087-31aa-4dc5-b565-f6c2729e3d77

with 
raw as (
      SELECT livequery.live.udf_api(
            'GET',
            'https://api.flipsidecrypto.com/api/v2/queries/54bb3087-31aa-4dc5-b565-f6c2729e3d77/data/latest',
            {'accept': 'application/json'},{}) as response)

,raw_data as (
SELECT
      VALUE:"Project Id" as "Project Id" ,
      VALUE:"Amount" as "Amount" ,
      VALUE:"Current value (USD)" as "Current value (USD)"  ,
      VALUE:"POT_Name" as "POT_Name" 
        FROM raw,LATERAL FLATTEN (input => response:data)
)
select 
    "POT_Name"  as "POT",
    count(distinct "Project Id") as "Project Id",
    sum("Amount") as "Amount",
    min("Amount") as "Min Amount",
    max("Amount") as "Max Amount",
    avg("Amount") as "Average-Amount",
    sum("Amount") * (select avg(PRICE_USD) from near.price.fact_prices where date_trunc('minute',TIMESTAMP) = (select max(date_trunc('minute',TIMESTAMP)) from near.price.fact_prices) and  SYMBOL='wNEAR' ) as "Current value (USD)"
from raw_data
group by 1;
