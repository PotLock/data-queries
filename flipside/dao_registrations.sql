-- Source https://flipsidecrypto.xyz/brian-terra/q/vID6_6Kl35D-/donation-receivers---sputnik-dao-only

-- forked from brian-terra / Donation Receivers - sputnik-dao only @ https://flipsidecrypto.xyz/brian-terra/q/vID6_6Kl35D-/donation-receivers---sputnik-dao-only

-- forked from All Potlock Donations - Top Donation Receivers @ https://flipsidecrypto.xyz/edit/queries/0acc3f34-f8ff-4d04-b86a-d72521870c60

-- forked from All Potlock Donations - Top Donors @ https://flipsidecrypto.xyz/edit/queries/6b803f1e-6de0-4998-b730-655658b17538

-- forked from All Potlock Donations @ https://flipsidecrypto.xyz/edit/queries/9297bc52-b0cc-4a3c-b2bc-dcd99993c7be

WITH txns as 
(select  distinct a.tx_hash, transaction_fee as tx_fee
 from near.core.fact_actions_events_function_call a, near.core.fact_transactions b 
where receiver_id = 'donate.potlock.near'
  and method_name = 'donate'
  and a.tx_hash = b.tx_hash
  and tx_succeeded = TRUE)
,
qmain as (
select  block_timestamp,
        signer_id,
        receiver_id,
        try_parse_json(b.action_data):"deposit"::float / 1e24 as deposit,
        txns.tx_fee::float / 1e24 as tx_fee
 from near.core.fact_actions_events b, txns
where b.tx_hash = txns.tx_hash
  and b.action_name = 'Transfer'
  and b.receiver_id <> b.signer_id
  and receiver_id <> 'impact.sputnik-dao.near'
  and receiver_id like '%sputnik%'
)

select receiver_id,
       sum(deposit) as total_donated
 from qmain
group by 1
order by 2 desc

--where receiver_id LIKE '%sputnik%'

--receiver_id like '' 
