-- Question 3: Alert for Account Inactivity
-- Objective: Identify all active accounts (either savings or investments)
-- that have had no inflow transactions in the last 365 days.

-- Step 1: Identify account types from the `plans_plan` table
-- filtering only active accounts classified as either:
-- - Investment (is_a_fund = 1 and is_regular_savings = 0)
-- - Savings (is_regular_savings = 1)

WITH account_classification AS (
    SELECT id,
           is_a_fund,
           is_regular_savings,
           -- Determine account type based on given conditions
           CASE 
               WHEN is_a_fund = 1 AND is_regular_savings = 0 THEN 'investment'
               ELSE 'savings'
           END AS account_type
    FROM adashi_staging.plans_plan
    -- Select only accounts that qualify as investment or savings
    WHERE is_a_fund = 1 OR is_regular_savings = 1
)

-- Step 2: Join savings accounts with account types and compute inactivity
SELECT s.plan_id,  -- Account ID
       s.owner_id, -- Owner of the account
       a.account_type, -- Type of account (investment or savings)
       MAX(s.transaction_date) AS last_transaction_date, -- Last recorded transaction date
       DATEDIFF(CURDATE(), MAX(s.transaction_date)) AS inactivity_days -- Days since last transaction
FROM adashi_staging.savings_savingsaccount AS s
JOIN account_classification AS a
ON s.plan_id = a.id -- Matching accounts with their corresponding types
-- Ensure we only consider accounts with transactions in the last 365 days
WHERE DATEDIFF(CURDATE(), s.transaction_date) <= 365
GROUP BY s.plan_id, s.owner_id; -- Group by account ID and owner for accurate results