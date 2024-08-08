-- v1 Pot Approval Status https://flipsidecrypto.xyz/Lordking/q/0qcorMbGCtvm/pot---approval-status && https://flipsidecrypto.xyz/Lordking/potlock-UD3Flm?tabIndex=3
with

raw as (
      SELECT livequery.live.udf_api(
            'GET',
            'https://api.flipsidecrypto.com/api/v2/queries/7aee8471-1543-4e18-9f44-c93a0b02434f/data/latest',
            {'accept': 'application/json'},{}) as response)

,raw_data as (
SELECT
      VALUE:"POT_Name" as "POT_Name" ,
      VALUE:"POT_Contract" as "POT_Contract" 

        FROM raw,LATERAL FLATTEN (input => response:data)
)

select 
            distinct 
            split(call.BLOCK_TIMESTAMP,' ')[0] as "Time",
            "POT_Name" ,
            call.ARGS:project_id as "Project",
            call.ARGS:status as "Status",
            call.ARGS:notes as "Note",
            call.TX_HASH as "Transaction"

      
      from near.core.fact_actions_events_function_call call inner join raw_data
            on call.RECEIVER_ID = "POT_Contract"
      where ACTION_NAME ='FunctionCall'
            and METHOD_NAME='chef_set_application_status'
            and RECEIPT_SUCCEEDED ='TRUE'
      --and call.tx_hash ='4poZ22uUgn2AwoZPtQRAjyUrQ9wjq7AWffyDex2ha3LP'
      and call.RECEIVER_ID ilike '%.potfactory.potlock.near%'
order by 1 desc 

