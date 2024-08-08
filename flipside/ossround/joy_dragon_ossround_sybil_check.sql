-- from https://flipsidecrypto.xyz/Lordking/q/7MFzKIdXEx9L/joydragon.near && https://flipsidecrypto.xyz/Lordking/potlock-open-source-round-3Yh2Qo?tabIndex=2
WITH 
raw AS (
    SELECT livequery.live.udf_api(
        'GET',
        'https://api.flipsidecrypto.com/api/v2/queries/3c4c013f-a19f-449f-98a6-f340eec59356/data/latest',
        {'accept': 'application/json'}, {}) AS response
),
raw_data AS (
    SELECT
        VALUE:"Signer" AS "Signer",
        VALUE:"Time" AS "Wallet Age",
        VALUE:"Parent" AS "Wallet Parent",
        VALUE:"Poroject" AS "Project",
        VALUE:"Type" AS "Verification Type",
        VALUE:"twitter" AS "Twitter handle",
        VALUE:"social" AS "Near Social handle",
        VALUE:"human" AS "Human (SBT)",
        VALUE:"age(month)" AS "age(month)",
        VALUE:"Contracts" AS "Contracts",
        VALUE:"Transfer" AS "Transfer"
    FROM raw, LATERAL FLATTEN (input => response:data)
)
SELECT * 
FROM raw_data
order by split("Wallet Age",' days')[0]::int asc 
 

 

