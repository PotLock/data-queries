-- from https://flipsidecrypto.xyz/Lordking/q/gu23jvHTAQg8/nearscript1.near and https://flipsidecrypto.xyz/Lordking/potlock-open-source-round-3Yh2Qo?tabIndex=3
WITH 
raw AS (
    SELECT livequery.live.udf_api(
        'GET',
        'https://api.flipsidecrypto.com/api/v2/queries/d021e849-9d9a-48c8-a279-718ecd4b5b31/data/latest',
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
 

 

 

