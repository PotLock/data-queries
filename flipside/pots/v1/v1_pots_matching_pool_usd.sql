-- USD Value of Matching Pools in v1 Pots https://flipsidecrypto.xyz/Lordking/q/RN6If7UCSubV/4f4cd51b-73d5-4d5c-b39c-053caea37b45 && https://flipsidecrypto.xyz/Lordking/potlock-UD3Flm?tabIndex=4



with 
raw as (
      SELECT livequery.live.udf_api(
            'GET',
            'https://api.flipsidecrypto.com/api/v2/queries/9286c080-e487-4fb3-a969-7b6d6bad991d/data/latest',
            {'accept': 'application/json'},{}) as response)

,raw_data as (SELECT
      VALUE:"POT_Name" as "POT_Name" ,
      VALUE:"Deposited (near)" as "Deposited (near)" ,
      VALUE:"Deposited (USD)" as "Deposited (USD)" ,
      VALUE:"Current value (USD) of Sponsorship" as "Current value (USD) of Sponsorship" ,
      VALUE:"Transaction" as "Transaction" ,
      VALUE:"Sponsor" as "Sponsor" 

        FROM raw,LATERAL FLATTEN (input => response:data)
)
select 
        "POT_Name",
        count(distinct "Transaction") as "# Transactions (Sponsorship)" ,
        count(distinct "Sponsor") as "# Sponsor" ,
        sum("Deposited (near)") as "Deposited (near)",
        sum("Current value (USD) of Sponsorship") as "Current value (USD)"
from raw_data
group by 1 
order by 5 desc 