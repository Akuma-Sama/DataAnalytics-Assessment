-- Using Common Table Expressions (CTEs) to calculate transaction frequency per customer

-- First CTE: Calculate the average number of transactions per month per owner
WITH avg_transactions_per_month_per_owner AS (
    SELECT 
        owner_id,
        ROUND(AVG(num_transactions_per_month)) AS avg_monthly_transactions
    FROM (
        -- Aggregating monthly transaction counts for each owner
        SELECT 
            owner_id,
            YEAR(transaction_date) AS transaction_year,
            MONTH(transaction_date) AS transaction_month,
            COUNT(*) AS num_transactions_per_month
        FROM adashi_staging.savings_savingsaccount
        GROUP BY owner_id, transaction_year, transaction_month
    ) AS num_transactions_per_month
    GROUP BY owner_id
),

-- Second CTE: Categorizing owners based on their transaction frequency
avg_transactions_with_frequency AS (
    SELECT *,
        CASE 
            WHEN avg_monthly_transactions <= 2 THEN 'Low Frequency'        -- Owners with 2 or fewer transactions per month
            WHEN avg_monthly_transactions < 10 THEN 'Medium Frequency'    -- Owners with 3 to 9 transactions per month
            ELSE 'High Frequency'                                         -- Owners with 10 or more transactions per month
        END AS frequency_category
    FROM avg_transactions_per_month_per_owner
)

-- Final Query: Summarizing transaction frequency distribution
SELECT 
    frequency_category,                                   -- Transaction frequency category
    COUNT(owner_id) AS customer_count,          -- Number of customers in each frequency category
    ROUND(AVG(avg_monthly_transactions)) AS avg_transactions_per_month  -- Average transactions per category
FROM avg_transactions_with_frequency
GROUP BY frequency_category;
