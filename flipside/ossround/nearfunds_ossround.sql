-- forked from Open Source Round Donors => Full detailed table of donors and donations 🔥 @ https://flipsidecrypto.xyz/edit/queries/1b90bc8e-20b1-4600-baac-52ce5186e304
-- https://flipsidecrypto.xyz/Lordking/q/Iptp6BET-ak0/nearfunds.near

WITH 
raw AS (
    SELECT livequery.live.udf_api(
        'GET',
        'https://api.flipsidecrypto.com/api/v2/queries/be311ae4-a85a-4a0e-a65c-2125e93afb5d/data/latest',
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
 

