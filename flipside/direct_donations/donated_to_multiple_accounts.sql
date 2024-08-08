-- Whether a donor on the Direct Donation Contract (donate.potlock.near) supported multiple projects  
-- https://flipsidecrypto.xyz/wownorth/q/mViZKGB9rVnx/donations-and-whether-donors-are-supporting-multiple-projects-across-all-donation && https://flipsidecrypto.xyz/wownorth/plotlock-plotlock-A36Irq?tabIndex=2
-- TO:Do add against each lists.potlock.near to define projects 

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
)

select signer_id,
       count(DISTINCT receiver_id) as supporting_projects_count,
       sum(deposit) as total_donated
from qmain
group by signer_id
order by TOTAL_DONATED DESC


--      sum(donation_amount) as total_donation


 