-- forked from brian-terra / Donation Receivers - sputnik-dao only @ https://flipsidecrypto.xyz/brian-terra/q/vID6_6Kl35D-/donation-receivers---sputnik-dao-only

--recurring donor's first and last donations, as well as their amounts
with txns as 
(select  distinct tx_hash, transaction_fee as tx_fee
 from near.core.fact_transactions b 
where (tx_receiver = 'registry.potlock.near'
  or   tx_signer = 'registry.potlock.near')
  and tx_succeeded = TRUE)
,
qmain as (
select  block_timestamp,
        b.tx_hash,
        signer_id,
        --args,
        deposit  / 1e24 as deposit
 from near.core.fact_actions_events_function_call b, txns
where b.tx_hash = txns.tx_hash
  and method_name = 'register'
),
txns_donate as 
(select distinct a.tx_hash, transaction_fee as tx_fee
 from near.core.fact_actions_events_function_call a, near.core.fact_transactions b 
where receiver_id = 'donate.potlock.near'
  and method_name = 'donate'
  and a.tx_hash = b.tx_hash
  and tx_succeeded = TRUE
),
qmain_donate as (
select  block_timestamp,
        signer_id,
        receiver_id,
        try_parse_json(b.action_data):"deposit"::float / 1e24 as deposit,
        txns_donate.tx_fee::float / 1e24 as tx_fee
 from near.core.fact_actions_events b, txns_donate
where b.tx_hash = txns_donate.tx_hash
  and b.action_name = 'Transfer'
  and b.receiver_id <> b.signer_id
  and receiver_id <> 'impact.sputnik-dao.near'
),
first_donation as (
select  distinct signer_id,
        first_value(block_timestamp) over (partition by signer_id, date(block_timestamp) order by block_timestamp) as first_donation_date, 
        deposit as first_amount_donated
from qmain_donate
),
last_donation as (
select  distinct signer_id, 
        last_value(block_timestamp) over (partition by signer_id, date(block_timestamp) order by block_timestamp) as last_donation_date, 
        deposit as last_amount_donated
from qmain_donate
)

select  signer_id, 
        first_donation_date, 
        first_amount_donated, 
        last_donation_date,
        last_amount_donated,
        case 
           when last_donation_date >= current_date - interval '14 days' then 'Yes' 
           else 'No' 
       end as actively_donating
from (
      select signer_id,
             first_donation_date, 
             first_amount_donated, 
             last_donation_date,
             last_amount_donated,
             row_number() over (partition by signer_id order by last_donation_date desc) as rn
      from (
            select fd.signer_id,
                   fd.first_donation_date, 
                   fd.first_amount_donated, 
                   ld.last_donation_date,
                   ld.last_amount_donated
            from first_donation fd
            join last_donation ld on fd.signer_id = ld.signer_id;
           ) sub
      ) sub2
where rn = 1;
