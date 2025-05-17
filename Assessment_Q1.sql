-- Retrieving customers who have both savings and investment accounts

SELECT 
    u.id AS owner_id,                                 -- Unique identifier for each customer
    CONCAT(u.first_name, ' ', u.last_name) AS full_name, -- Full name of the customer
    SUM(p.is_regular_savings) AS savings_count,       -- Total number of regular savings plans the customer has
    SUM(p.is_a_fund) AS investment_count,             -- Total number of investment plans the customer has
    SUM(s.confirmed_amount) AS total_deposits         -- Total confirmed deposits made by the customer
FROM adashi_staging.users_customuser AS u
JOIN adashi_staging.plans_plan AS p                   -- Joining with the plans table to get savings and investment details
ON u.id = p.owner_id
JOIN adashi_staging.savings_savingsaccount AS s       -- Joining with the savings account table to get deposits information
ON u.id = s.owner_id
GROUP BY u.id, full_name                              -- Grouping by customer to aggregate savings, investments, and deposits
HAVING savings_count > 0 AND investment_count > 0;    -- Filtering for customers who have both at least one savings and one investment account
