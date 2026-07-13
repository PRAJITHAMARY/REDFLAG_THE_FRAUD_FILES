SELECT COUNT(*) FROM redflag.transactions;

-- ===========================================
-- UNLOX MINOR PROJECT 3
-- RedFlag: The Fraud Files
-- Name: Prajitha Mary J
-- ===========================================

-- PATTERN 1 : Velocity Fraud
-- identified users with 30 or more transactions in a single day

SELECT user_id, DATE(txn_time) AS transaction_date, COUNT(txn_id) AS total_transactions FROM transactions 
GROUP BY user_id, DATE(txn_time) HAVING COUNT(txn_id) >= 30 ORDER BY total_transactions DESC;

-- PATTERN 2 : Round Amount Clustering
-- identified users with 15 or more round-amount transactions

SHOW COLUMNS FROM transactions;

SELECT txn_id, user_id, amount, txn_time, payment_mode, city FROM transactions 
WHERE amount = ROUND(amount) ORDER BY amount DESC;

-- PATTERN 3 : Card Testing
-- identified users with 30 or more transactions below Rs.10 in a single day

SELECT user_id, COUNT(txn_id) AS failed_card_transactions FROM transactions WHERE payment_mode = 'CARD' 
AND status = 'FAILED' GROUP BY user_id HAVING COUNT(txn_id) >= 5 ORDER BY failed_card_transactions DESC;

-- PATTERN 4 : Failed Then Succeeded
-- identified users with failed transactions followed by a successful transaction within 10 minutes

SELECT t1.user_id, t1.txn_time AS failed_time, t2.txn_time AS success_time FROM transactions t1 
JOIN transactions t2 ON t1.user_id = t2.user_id WHERE t1.status = 'FAILED' AND t2.status = 'SUCCESS' 
AND t2.txn_time > t1.txn_time ORDER BY t1.user_id, t1.txn_time;

SELECT DISTINCT status FROM transactions;

-- PATTERN 5 : Odd Hour Concentration
-- identified users who performed 80% or more of their transactions between 2:00AM and 5:00AM

SELECT txn_id, user_id, amount, txn_time, payment_mode, city FROM transactions 
WHERE HOUR(txn_time) BETWEEN 0 AND 5 ORDER BY txn_time;

-- PATTERN 6 : MULE ACCOUNTS
-- identified users with 8 or more credit transactions

SELECT user_id, COUNT(*) AS credit_transactions FROM transactions WHERE txn_type = 'CREDIT' 
GROUP BY user_id HAVING COUNT(*) >= 8 ORDER BY credit_transactions DESC;

-- PATTERN 7 : REFUND ABUSE
-- identified users whose refund transactions exceeded 40% of their total transactions

SELECT DISTINCT txn_type FROM transactions;

SELECT DISTINCT status FROM transactions;

SELECT user_id, COUNT(*) AS total_transactions, SUM(CASE WHEN txn_type = 'REFUND' THEN 1 ELSE 0 END) AS refund_transactions,
ROUND((SUM(CASE WHEN txn_type = 'REFUND' THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2) AS refund_percentage
FROM transactions GROUP BY user_id HAVING refund_percentage > 40 ORDER BY refund_percentage DESC;

-- PATTERN 8 : MERCHANT COLLUSION
-- identified merchants receiving transactions from 5 or fewer users

SELECT merchant_id, COUNT(DISTINCT user_id) AS unique_users, SUM(amount) AS total_amount
FROM transactions GROUP BY merchant_id HAVING COUNT(DISTINCT user_id) <= 5 ORDER BY total_amount DESC;

-- PATTERN 9 : JUST UNDER THRESHOLD
-- identified users who made 10 or more transactions of Rs.9999

SELECT user_id, COUNT(*) AS transaction_count FROM transactions WHERE amount = 9999
GROUP BY user_id HAVING COUNT(*) >= 10 ORDER BY transaction_count DESC;

-- PATTERN 10 : DORMANT THEN ACTIVE
-- identified users who were inactive for 90 or more days before becoming active again

SELECT user_id, MIN(txn_time) AS first_transaction, MAX(txn_time) AS last_transaction, DATEDIFF(MAX(txn_time), MIN(txn_time)) 
AS inactive_days FROM transactions GROUP BY user_id HAVING DATEDIFF(MAX(txn_time), MIN(txn_time)) >= 90 ORDER BY inactive_days DESC;

-- PATTERN 11 : VELOCITY SPIKE
-- identified users whose monthly transaction count was at least five times their average monthly transactions

WITH monthly_transactions AS (
    SELECT
        user_id,
        DATE_FORMAT(txn_time, '%Y-%m') AS transaction_month,
        COUNT(*) AS monthly_count
    FROM transactions
    GROUP BY user_id, DATE_FORMAT(txn_time, '%Y-%m')
),
average_transactions AS (
    SELECT
        user_id,
        AVG(monthly_count) AS average_count
    FROM monthly_transactions
    GROUP BY user_id
)

SELECT
    m.user_id,
    m.transaction_month,
    m.monthly_count,
    ROUND(a.average_count,2) AS average_count
FROM monthly_transactions m
JOIN average_transactions a
ON m.user_id = a.user_id
WHERE m.monthly_count >= (5 * a.average_count)
ORDER BY m.monthly_count DESC;

-- PATTERN 12 : GEOGRAPHIC IMPOSSIBILITY
-- identified users who made transactions from different cities within one hour

SELECT DISTINCT
    t1.user_id,
    t1.city AS city_1,
    t2.city AS city_2,
    t1.txn_time AS first_transaction,
    t2.txn_time AS second_transaction
FROM transactions t1
JOIN transactions t2
ON t1.user_id = t2.user_id
WHERE t1.city <> t2.city
AND t1.txn_time < t2.txn_time
AND TIMESTAMPDIFF(MINUTE, t1.txn_time, t2.txn_time) <= 60
ORDER BY t1.user_id, t1.txn_time;
