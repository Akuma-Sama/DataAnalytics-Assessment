# DATA ANALYST ASSESSMENT README

This document provides detailed explanations of the SQL queries written for the questions in data analyst assessment, along with the challenges encountered and their solutions.

## Table of Contents
1. Query 1: High value customers with multiple products
2. Query 2: Transaction Frequency Analysis
3. Query 3: Account Inactivity Alert
4. Query 4: Customer Lifetime Value Estimation
5. Challenges and Solutions

   
## Query 1: High value customers with multiple products

### Objective
Identify customers who have both savings and investment accounts and summarize their account information.

### Approach
This query uses multiple table joins to connect user data with their savings and investment accounts, then filters for customers who have at least one of each account type.

### Key Components
- **Table Joins**: Connected three tables (users, plans, and savings accounts) using customer ID as the common field
- **Aggregation**: Used `SUM()` to count the number of savings and investment accounts per customer
- **Filtering**: Applied a `HAVING` clause to include only customers with at least one savings and one investment account
- **Result**: The query returns the customer ID, full name, number of savings accounts, number of investment accounts, and total deposit amount

### Logic
1. The query starts by joining user data with their associated plans and savings accounts
2. For each user, we count their savings accounts (`is_regular_savings`) and investment accounts (`is_a_fund`)
3. We also calculate the total confirmed deposits they've made
4. Using the `HAVING` clause, we filter to include only customers who have both types of accounts

## Query 2: Transaction Frequency Analysis

### Objective
Analyze customer transaction frequency and categorize customers based on their transaction patterns.

### Approach
This query uses Common Table Expressions (CTEs) to break down the analysis into logical steps:
1. Calculate average monthly transactions per customer
2. Categorize customers into frequency bands
3. Summarize the distribution of customers across these categories

### Key Components
- **Nested Subquery**: First aggregates transactions by customer and month
- **avg_transactions_per_month_per_owner CTE**: Calculates the average monthly transactions for each customer
- **avg_transactions_with_frequency CTE**: Categorizes customers into Low frequency (≤2), Medium frequency (3-9), or High frequency (≥10) frequency
- **Final Query**: Groups customers by frequency category and provides summary statistics

### Logic
1. The innermost query calculates how many transactions each customer made in each month
2. The avg_transactions_per_month_per_owner CTE calculates each customer's average monthly transactions
3. The avg_transactions_with_frequency CTE categorizes customers based on their transaction frequency
4. The final query counts customers in each category and calculates the average number of transactions per category

## Query 3: Account Inactivity Alert

### Objective
Identify active accounts (savings or investments) that have had no inflow transactions in the last 365 days.

### Approach
This query uses a CTE to first identify account types, then, joins this with transaction data to determine account inactivity.

### Key Components
- **CTE for Account Classification**: Creates a lookup table that classifies accounts as either 'investment' or 'savings'
- **Date Functions**: Uses `DATEDIFF()` to calculate days since the last transaction
- **Filtering**: Includes only transactions within the last 365 days
- **Aggregation**: Uses `MAX(transaction_date)` to find the most recent transaction for each account

### Logic
1. The account_classification CTE classifies each account as either an investment or savings account based on the values of `is_a_fund` and `is_regular_savings`
2. The main query joins this classification with transaction data
3. For each account, we find the most recent transaction date
4. We calculate how many days have passed since the last transaction
5. The results are grouped by account ID and owner ID to provide a complete view of account activity

## Query 4: Customer Lifetime Value Estimation

### Objective
Calculate the estimated Customer Lifetime Value (CLV) based on account tenure and transaction history.

### Approach
This query uses multiple CTEs to:
1. Join customer data with their transactions and calculate profit per transaction
2. Aggregate transaction data by customer
3. Calculate CLV using a formula based on transaction frequency and profitability

### Key Components
- **Time Calculation**: Uses `TIMESTAMPDIFF()` to determine account tenure in months
- **Multi-level CTEs**: Breaks complex calculations into manageable steps
- **CLV Formula**: Calculates CLV as `(transactions_per_month * 12 * avg_profit_per_transaction)`
- **Sorting**: Orders results by CLV in descending order to highlight high-value customers

### Logic
1. The transactions_tenure_profit CTE joins customer data with transaction data and calculates:
   - Account tenure in months
   - Profit per transaction (assumed as 0.1% of transaction amount)
2. The customers_transactions_and_profit CTE aggregates customer transaction data to determine:
   - Total number of transactions per customer
   - Average profit per transaction
3. The final query calculates CLV using the formula:
   - Monthly transaction rate (total transactions ÷ tenure) × 12 months × average profit
4. Results are filtered to exclude customers with zero tenure and sorted to highlight highest-value customers

## Challenges and Solutions

### 1. MySQL Instead of Microsoft SQL
**Challenge:** Having to use MySQL instead of Microsoft SQL Server resulted in syntax differences that needed to be addressed.

**Solution:** Adapted queries to use MySQL-specific functions:
- Used `CURDATE()` instead of SSMS `GETDATE()` to get current date
- Used `TIMESTAMPDIFF()` for interval calculations
- Adjusted string concatenation to use `CONCAT()` instead of `+` operator

### 2. Timeout Issues with Large Database
**Challenge:** The large database size (78MB) caused query timeout issues during execution.

**Solution:** Increased the MySQL packet size to accommodate larger data transfers:
```sql
SET GLOBAL max_allowed_packet = 209715200; -- 200MB
```
This configuration change allowed the database to handle larger result sets without timing out.

### 3. Performance Optimization for Large Dataset
**Challenge:** Query performance suffered due to the size of the dataset.

**Solution:** Limited result sets for testing and development:
```sql
LIMIT 1000
```
This approach allowed for faster query testing and refinement before running against the full dataset.

### 4. Lack of Clarity Between Tasks and Scenarios
**Challenge:** Some tasks lacked clear correlation with their intended scenarios, making it difficult to determine the exact requirements.

**Solution:**
- Made reasonable assumptions based on available data and business context
- Added detailed comments to explain the logic and reasoning behind each query
- Used descriptive column names and aliases to make query results more understandable
- Structured queries with clear, logical progression to make the analysis transparent

- For example, in question 3, I wrote my query to give the task output as number of days inactive after last transaction within the last 365 days. But if I was to follow the scenario, the query will be different and the query I wrote for that is outlined below. It shows the number of days after last transaction before the last 365 days (> 1 year)

```sql
-- Step 1: Identify account types from the `plans_plan` table
-- We are filtering only active accounts classified as either:
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
-- Ensure we only consider accounts with no transactions in the last 365 days
WHERE DATEDIFF(CURDATE(), s.transaction_date) > 365
GROUP BY s.plan_id, s.owner_id; -- Group by account ID and owner for accurate results
```


These solutions ensured that despite the challenges, the queries were able to provide meaningful business insights from the available data.


## Note
1. The 'adashi_assessment.sql' file provided was used to create the database used in writing the queries.
2. MYSQL 8.0 was used to write the queries.
