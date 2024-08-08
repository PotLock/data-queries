-- Chef Set Payouts on Pots -- still need to process payouts https://flipsidecrypto.xyz/Lordking/q/zIJYNI2s0LHf/57b4bee1-6047-48b3-98da-1490b7a5fff4 && https://flipsidecrypto.xyz/Lordking/potlock-UD3Flm?tabIndex=5


select 
      distinct call.BLOCK_TIMESTAMP as "Time",
      call.RECEIVER_ID as "POT",
      call.ARGS:payouts as "Payouts Info" ,
      call.TX_HASH as "Transaction"
from near.core.fact_actions_events_function_call call 

where     ACTION_NAME='FunctionCall'
      and METHOD_NAME='chef_set_payouts'
      and call.RECEIVER_ID ilike '%.potfactory.potlock.near%'
      and RECEIPT_SUCCEEDED ='TRUE'






 

