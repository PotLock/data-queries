-- v1 Pot Overviews https://flipsidecrypto.xyz/Lordking/q/Hrc6nwE2NK9T/pot---pot-info && https://flipsidecrypto.xyz/Lordking/potlock-UD3Flm?tabIndex=3
-- Round Creator Not the Deployer, need to correct

with 
pot as (
        select *
        from (        select 
                      distinct call.tx_hash ,
                      call.BLOCK_TIMESTAMP,
                      call.RECEIVER_ID,
                      row_number() over (partition by call.RECEIVER_ID order by call.block_timestamp desc) as rank
                from near.core.fact_actions_events_function_call call
                where METHOD_NAME in ('admin_dangerously_set_pot_config') 
                      and ACTION_NAME ='FunctionCall'
                      and call.RECEIVER_ID ilike '%.potfactory.potlock.near%'
                      and RECEIPT_SUCCEEDED ='TRUE')
        where rank=1
)

select 
      distinct call.ARGS:update_args:pot_name as "POT_Name" ,
      call.RECEIVER_ID as "POT_Contract" ,
      call.ARGS:update_args:max_projects as "Max_Projects" ,
      call.SIGNER_ID as "POT_Creator" ,
      SPLIT(call.BLOCK_TIMESTAMP,' ')[0] as "Creation_Time" ,
      SPLIT(to_timestamp(call.ARGS:update_args:application_start_ms::int/1000),' ')[0] as "Application_Start" ,
      SPLIT(to_timestamp(call.ARGS:update_args:application_end_ms::int/1000),' ')[0] as "Application_End" ,
      datediff('day',"Application_Start","Application_End") as "Application_Period",
      call.ARGS:update_args:chef as "Chef" ,
      --call.ARGS:chef_fee_basis_points as "chef_fee_basis_points" ,
      SPLIT(to_timestamp(call.ARGS:update_args:public_round_start_ms::int/1000),' ')[0] as "Public_Round_Start" ,
      SPLIT(to_timestamp(call.ARGS:update_args:public_round_end_ms::int/1000),' ')[0] as "Public_Round_End" ,
      datediff('day',"Public_Round_Start","Public_Round_End") as "Public_Round_Period",
     -- --call.ARGS:referral_fee_matching_pool_basis_points as referral_fee_matching_pool_basis_points ,
     -- --call.ARGS:referral_fee_public_round_basis_points as referral_fee_public_round_basis_points ,
      call.ARGS:update_args:pot_description as "POT_Description" ,
      call.TX_HASH as "Transaction"
      

from near.core.fact_actions_events_function_call call 
where call.tx_hash in (select distinct tx_hash from pot )
