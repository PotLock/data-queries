-- Protocol Fee based on v1 Pot Contract https://flipsidecrypto.xyz/Lordking/q/dXroIBc4OjDH/protocol-fee---scan && https://flipsidecrypto.xyz/Lordking/potlock-UD3Flm?tabIndex=2
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
), 
donation as 
          (select 
                  distinct 
                  BLOCK_TIMESTAMP,
                  DEPOSIT/1e24 as DEPOSIT ,
                  TX_HASH,
                  TX_SIGNER
          
          from  near.core.fact_transfers transfers
          where  TX_RECEIVER = 'donate.potlock.near'
                and PREDECESSOR_ID = 'donate.potlock.near'
                and TX_SUCCEEDED = TRUE 
                and RECEIVER_ID ='impact.sputnik-dao.near'
          )

,donations as 
        (select 
        distinct 
                donation.BLOCK_TIMESTAMP,
                donation.DEPOSIT as impact_DEPOSIT ,
                donation.TX_HASH,
                donation.TX_SIGNER,
                transfers.RECEIVER_ID ,
                transfers.DEPOSIT/1e24 as project_DEPOSIT ,
                transfers.TX_RECEIVER
        
        from  near.core.fact_transfers transfers inner join donation
              on donation.tx_hash = transfers.tx_hash 
        where transfers.PREDECESSOR_ID = 'donate.potlock.near'
              and TX_SUCCEEDED = TRUE 
              and RECEIVER_ID != 'impact.sputnik-dao.near'
        )
,donation_pot as 
          (select 
                  distinct 
                  BLOCK_TIMESTAMP,
                  DEPOSIT/1e24 as DEPOSIT ,
                  TX_HASH,
                  TX_SIGNER
          
          from  near.core.fact_transfers transfers
          where  TX_RECEIVER ilike '%.v1.potfactory.potlock.near%'
                and PREDECESSOR_ID ilike '%.v1.potfactory.potlock.near%'
                and TX_SUCCEEDED = TRUE 
                and RECEIVER_ID ='impact.sputnik-dao.near'
                and DEPOSIT !=0
          )

,donations_pot as 
        (select 
        distinct 
                donation.BLOCK_TIMESTAMP,
                donation.DEPOSIT as impact_DEPOSIT ,
                donation.TX_HASH,
                donation.TX_SIGNER,
                transfers.RECEIVER_ID ,
                transfers.DEPOSIT/1e24 as project_DEPOSIT ,
                transfers.TX_RECEIVER
        
        from  near.core.fact_transfers transfers inner join donation_pot donation
              on donation.tx_hash = transfers.tx_hash 
        where transfers.PREDECESSOR_ID ilike '%.v1.potfactory.potlock.near%'
              and TX_SUCCEEDED = TRUE --and donation.tx_hash ='CPWBPPCrSj6eSWE5Wkg3ghnoVF9bZ3aCuV85XeyEXx1W'
              and RECEIVER_ID != 'impact.sputnik-dao.near' and RECEIVER_ID != SIGNER_ID 
                and transfers.DEPOSIT !=0

        )
,
together as (
      select distinct * from donations_pot
      union 
      select distinct * from donations

)

select 
      distinct split(BLOCK_TIMESTAMP,' ')[0] as "Time",
       coalesce ("POT_Name",TX_RECEIVER) as "Source",
      TX_SIGNER as "Donors",
      impact_DEPOSIT as "Protocol Fee (near)" ,
      project_DEPOSIT as "Donated to projects (near)",
      RECEIVER_ID as "Project", 
      TX_HASH as "Transaction" 
from together left join raw_data 
      on "POT_Contract"= TX_RECEIVER
order by 1 desc 


 

 

 

