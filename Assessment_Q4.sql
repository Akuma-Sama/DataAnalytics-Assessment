-- Question 4: Estimate Customer Lifetime Value (CLV)
-- Objective: Calculate CLV using account tenure and transaction volume

-- Assumptions:
-- - Profit per transaction = 0.1% of confirmed transaction amount
-- - CLV formula: (total_transactions / tenure_months) * 12 * avg_profit_per_transaction

-- Step 1: Join users and transactions; compute tenure and profit per transaction in a CTE
WITH transactions_tenure_profit AS (
    SELECT u.id,  -- Customer ID
           CONCAT(u.first_name, ' ', u.last_name) AS full_name,  -- Customer's full name
           TIMESTAMPDIFF(MONTH, u.created_on, CURDATE()) AS tenure_months,  -- Account tenure in months
           s.confirmed_amount,  -- Amount confirmed in transaction
           (0.001 * s.confirmed_amount) AS profit_per_transaction  -- Profit per transaction (0.1% of amount)
    FROM adashi_staging.users_customuser AS u
    JOIN adashi_staging.savings_savingsaccount AS s
    ON u.id = s.owner_id
)

-- Step 2: Aggregate by customer to compute total transactions and average profit in a CTE
, customers_transactions_and_profit AS (
    SELECT id,  -- Customer ID
           full_name,  -- Customer's full name
           tenure_months,  -- Account tenure in months
           COUNT(*) AS total_transactions,  -- Total number of transactions
           AVG(profit_per_transaction) AS avg_profit  -- Average profit per transaction
    FROM transactions_tenure_profit
    GROUP BY id
)

-- Step 3: Compute Estimated CLV per customer using the simplified formula
SELECT id,  -- Customer ID
       full_name,  -- Customer's full name
       tenure_months,  -- Account tenure in months
       total_transactions,  -- Total transactions made by customer
       ROUND(((total_transactions / tenure_months) * 12 * avg_profit), 2) AS clv  -- Estimated CLV calculation
FROM customers_transactions_and_profit
WHERE tenure_months > 0  -- Prevent zero division error
ORDER BY clv DESC;  -- Sort by CLV in descending order