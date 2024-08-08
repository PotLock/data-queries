-- Number of Project Registrations Per v1 Pot https://flipsidecrypto.xyz/Lordking/q/Z8WUTvJ5gdZm/pot---project-registration && https://flipsidecrypto.xyz/Lordking/potlock-UD3Flm?tabIndex=3


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
----------------------------------------------------------------------------
, pot as (
            select 
                  distinct "POT_Name" ,
                  call.BLOCK_TIMESTAMP::date as "Date",
                  count( call.SIGNER_ID) as "Projects Registered in POT"
            
            from near.core.fact_actions_events_function_call call 
                inner join raw_data  
                      on call.RECEIVER_ID="POT_Contract"
            where     ACTION_NAME ='FunctionCall'
                  and METHOD_NAME='assert_can_apply_callback'
                  and call.RECEIVER_ID in (select 
                                            distinct RECEIVER_ID
                                      from near.core.fact_actions_events_function_call
                                      where tx_hash in (select distinct tx_hash from near.core.fact_actions_events_function_call where METHOD_NAME ='is_registered' and RECEIVER_ID='registry.potlock.near'))
                  and RECEIPT_SUCCEEDED ='TRUE'
            group by 1,2 order by 3 desc 
)


select 
      "POT_Name" ,
      "Date",
      sum("Projects Registered in POT") over (partition by "POT_Name" order by "Date" asc ) as "POTS"
from pot 
