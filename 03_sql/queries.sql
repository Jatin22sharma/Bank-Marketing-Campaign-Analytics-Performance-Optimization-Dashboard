USE bank_campaign;

-- Q1: Overall campaign response rate
SELECT
COUNT(*) AS total_contacts,
SUM(y_binary) AS subscribed,
ROUND(100.0 * SUM(y_binary) / COUNT(*), 2) AS response_rate_pct
FROM campaigns;

-- Q2: Response rate by contact method (your future A/B groups)
SELECT
contact,
COUNT(*) AS contacts,
SUM(y_binary) AS subscribed,
ROUND(100.0 * SUM(y_binary) / COUNT(*), 2) AS response_rate_pct
FROM campaigns
GROUP BY contact
ORDER BY response_rate_pct DESC;

-- Q3: Response rate by job category
SELECT
job,
COUNT(*) AS total,
ROUND(100.0 * SUM(y_binary) / COUNT(*), 2) AS response_rate_pct
FROM campaigns
GROUP BY job
ORDER BY response_rate_pct DESC;

-- Q4: Response rate by age band (window function)
SELECT
CASE
WHEN age < 30 THEN 'Under 30'
WHEN age BETWEEN 30 AND 45 THEN '30-45'
WHEN age BETWEEN 46 AND 60 THEN '46-60'
ELSE 'Over 60'
END AS age_band,
COUNT(*) AS total,
ROUND(100.0 * SUM(y_binary) / COUNT(*), 2) AS response_rate_pct
FROM campaigns
GROUP BY age_band
ORDER BY response_rate_pct DESC;

-- Q5: Campaign effectiveness by number of contacts made
SELECT
campaign AS num_contacts,
COUNT(*) AS customers,
ROUND(100.0 * SUM(y_binary) / COUNT(*), 2) AS response_rate_pct
FROM campaigns
WHERE campaign <= 10
GROUP BY campaign
ORDER BY campaign;

-- Q6: Running cumulative subscription count by month (CTE + window function)
WITH monthly AS (
SELECT
month,
SUM(y_binary) AS monthly_subs
FROM campaigns
GROUP BY month
)
SELECT
month,
monthly_subs,
SUM(monthly_subs) OVER (ORDER BY FIELD(month,
'jan','feb','mar','apr','may','jun',
'jul','aug','sep','oct','nov','dec')) AS cumulative_subs
FROM monthly;

-- Q7: Best performing job + contact combination (multi-table style JOIN on derived)
SELECT
job, contact,
COUNT(*) AS contacts,
ROUND(100.0 * SUM(y_binary) / COUNT(*), 2) AS response_rate_pct
FROM campaigns
GROUP BY job, contact
HAVING COUNT(*) > 100
ORDER BY response_rate_pct DESC
LIMIT 10;

-- Q8: Impact of previous campaign outcome on current response
SELECT
poutcome,
COUNT(*) AS total,
ROUND(100.0 * SUM(y_binary) / COUNT(*), 2) AS response_rate_pct
FROM campaigns
GROUP BY poutcome
ORDER BY response_rate_pct DESC;

-- Q9: Balance tier segmentation (RANK window function)
WITH balance_tiers AS (
SELECT *,
CASE
WHEN balance < 0 THEN 'Negative'
WHEN balance < 500 THEN 'Low'
WHEN balance < 2000 THEN 'Medium'
ELSE 'High'
END AS balance_tier
FROM campaigns
),
tier_stats AS (
SELECT
balance_tier,
COUNT(*) AS total,
ROUND(100.0 * SUM(y_binary) / COUNT(*), 2) AS response_rate_pct
FROM balance_tiers
GROUP BY balance_tier
)
SELECT *, RANK() OVER (ORDER BY response_rate_pct DESC) AS tier_rank
FROM tier_stats;

-- Q10: Month-over-month response rate with LAG comparison
WITH monthly_rates AS (
SELECT
month,
ROUND(100.0 * SUM(y_binary) / COUNT(*), 2) AS response_rate_pct,
COUNT(*) AS contacts
FROM campaigns
GROUP BY month
)
SELECT
month, contacts, response_rate_pct,
LAG(response_rate_pct) OVER (ORDER BY FIELD(month,
'jan','feb','mar','apr','may','jun',
'jul','aug','sep','oct','nov','dec')) AS prev_month_rate,
ROUND(response_rate_pct -
LAG(response_rate_pct) OVER (ORDER BY FIELD(month,
'jan','feb','mar','apr','may','jun',
'jul','aug','sep','oct','nov','dec')), 2) AS mom_change
FROM monthly_rates;