-- Pot Leaderboard https://flipsidecrypto.xyz/Lordking/q/T11btTfy51PI/pot---pot-status && https://flipsidecrypto.xyz/Lordking/potlock-UD3Flm?tabIndex=3



with 
raw_budget as (
      SELECT livequery.live.udf_api(
            'GET',
            'https://api.flipsidecrypto.com/api/v2/queries/4f4cd51b-73d5-4d5c-b39c-053caea37b45/data/latest',
            {'accept': 'application/json'},{}) as response)

,raw_budget_data as (
SELECT
      VALUE:"POT_Name" as "POT_Names" ,
      VALUE:"Current value (USD)" as "Current value (USD)" 
        FROM raw_budget,LATERAL FLATTEN (input => response:data)
)
-------------------------------------------------------------------------
,raw as (
      SELECT livequery.live.udf_api(
            'GET',
            'https://api.flipsidecrypto.com/api/v2/queries/7aee8471-1543-4e18-9f44-c93a0b02434f/data/latest',
            {'accept': 'application/json'},{}) as response)

,raw_data as (
SELECT
      VALUE:"POT_Name" as "POT_Name" ,
      VALUE:"POT_Contract" as "POT_Contract" ,
      VALUE:"Max_Projects" as "Max_Projects" ,
      VALUE:"Application_Start" as "Application_Start" ,
      VALUE:"Application_End" as "Application_End" ,
      VALUE:"Public_Round_Start" as "Public_Round_Start" ,
      VALUE:"Public_Round_End" as "Public_Round_End" ,

 --... | Application_Start | Application_End |Public_Round_Start | Public_Round_End| cooldown | payout ...
      case 
          when current_date <= "Application_Start" then datediff('day',split(current_date::date,' ')[0],"Application_Start")||' days to application starts' 
          when current_date between "Application_Start" and "Application_End" then datediff('day',split(current_date::date,' ')[0],"Application_End")||' days to application ends' 
          when current_date between "Public_Round_Start" and "Public_Round_End" then datediff('day',split(current_date::date,' ')[0],"Public_Round_End")||' days to public round ends' 
          when current_date::date > "Public_Round_End"::date +7 then 'Paid'
          else 'cooldown'
          end as "Timeline"


        FROM raw,LATERAL FLATTEN (input => response:data)
)
-------------------------------------------------------------------------
, pot as (
select 
      "POT_Name" ,
      count( call.SIGNER_ID) as "Projects Registered in POT",
      "Max_Projects" ,
      "Current value (USD)" as "Current value (USD) of matching pool" ,
      "Timeline",
      "POT_Contract" 


from near.core.fact_actions_events_function_call call 
    inner join raw_data 
        on call.RECEIVER_ID="POT_Contract"
    inner join raw_budget_data
        on "POT_Name"="POT_Names"

where     ACTION_NAME ='FunctionCall'
      and METHOD_NAME='assert_can_apply_callback'
      and call.RECEIVER_ID in (select 
                                distinct RECEIVER_ID
                          from near.core.fact_actions_events_function_call
                          where tx_hash in (select distinct tx_hash from near.core.fact_actions_events_function_call where METHOD_NAME ='is_registered' and RECEIVER_ID='registry.potlock.near'))
      and RECEIPT_SUCCEEDED ='TRUE'
group by 1,5,3,4,6 order by 2 desc )



,status as (
select 
      sum(case when status ='Approved' then 1 else 0 end) as Approved ,
      sum(case when status !='Approved' then 1 else 0 end) as Rejected ,
      RECEIVER_ID
from 
      (select 
            distinct 
            call.BLOCK_TIMESTAMP,
            call.RECEIVER_ID ,
            call.ARGS:project_id as project_id,
            call.ARGS:status as status,
            call.DEPOSIT/1e24 as DEPOSIT,
            call.TX_HASH ,
            call.ARGS:notes as notes
      
      from near.core.fact_actions_events_function_call call 
      where ACTION_NAME ='FunctionCall'
            and METHOD_NAME='chef_set_application_status'
            and RECEIPT_SUCCEEDED ='TRUE'
      --and call.tx_hash ='4poZ22uUgn2AwoZPtQRAjyUrQ9wjq7AWffyDex2ha3LP'
      and call.RECEIVER_ID ilike '%.potfactory.potlock.near%'
      )
group by 3
)

select 
      "POT_Name" ,
      "Projects Registered in POT",
      coalesce (Approved,0) as "Approved",
      coalesce (Rejected,0) as "Rejected",
      "Projects Registered in POT" - ( "Approved" + "Rejected") as "Pending",
      "Max_Projects" ,
      "Current value (USD) of matching pool" ,
      "Timeline",
      "POT_Contract" 

from status right join pot 
    on "POT_Contract" = RECEIVER_ID
order by 2 desc 