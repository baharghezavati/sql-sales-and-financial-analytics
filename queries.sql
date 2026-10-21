-- =====================================================================
-- Financial & Operations Analytics: business questions in SQL
-- Engine: MySQL 8.0. Run schema.sql first.
-- "As of" date for aging and overdue analysis: 2026-09-30.
-- =====================================================================

USE sales_analytics;

-- =====================================================================
-- 1. CLIENT BALANCES (view)
-- Question: how much has each client been invoiced, paid, and still owes?
-- LEFT JOIN keeps clients that have no invoices yet (they show 0, not missing).
-- =====================================================================
DROP VIEW IF EXISTS sales_by_balances;

CREATE VIEW sales_by_balances AS
SELECT
    c.client_id,
    c.name                                              AS client_name,
    COUNT(i.invoice_id)                                 AS invoices,
    COALESCE(SUM(i.invoice_total), 0)                   AS total_invoiced,
    COALESCE(SUM(i.payment_total), 0)                   AS total_paid,
    COALESCE(SUM(i.invoice_total - i.payment_total), 0) AS outstanding_balance
FROM clients c
LEFT JOIN invoices i USING (client_id)
GROUP BY c.client_id, c.name;

SELECT *
FROM sales_by_balances
ORDER BY outstanding_balance DESC, client_name;

-- =====================================================================
-- 2. OUTSTANDING BALANCE CONCENTRATION
-- Question: which few clients make up most of the money we are still owed?
-- Uses window functions for share of total and cumulative share.
-- =====================================================================
WITH open_balances AS (
    SELECT client_name, outstanding_balance
    FROM sales_by_balances
    WHERE outstanding_balance > 0
)
SELECT
    client_name,
    outstanding_balance,
    ROUND(100.0 * outstanding_balance / SUM(outstanding_balance) OVER (), 1) AS pct_of_total,
    ROUND(100.0 * SUM(outstanding_balance) OVER (ORDER BY outstanding_balance DESC, client_name)
                / SUM(outstanding_balance) OVER (), 1)                      AS cumulative_pct
FROM open_balances
ORDER BY outstanding_balance DESC, client_name;

-- =====================================================================
-- 3. RECEIVABLES AGING
-- Question: how old are the unpaid balances?
-- CASE buckets invoices by days past due, as of 2026-09-30.
-- =====================================================================
WITH params AS (
    SELECT DATE('2026-09-30') AS as_of
),
open_invoices AS (
    SELECT
        i.invoice_id,
        i.invoice_total - i.payment_total AS balance,
        DATEDIFF(p.as_of, i.due_date)     AS days_past_due
    FROM invoices i
    CROSS JOIN params p
    WHERE i.invoice_total > i.payment_total
)
SELECT
    CASE
        WHEN days_past_due <= 0  THEN 'Not yet due'
        WHEN days_past_due <= 30 THEN '1-30 days past due'
        WHEN days_past_due <= 60 THEN '31-60 days past due'
        WHEN days_past_due <= 90 THEN '61-90 days past due'
        ELSE '90+ days past due'
    END                    AS aging_bucket,
    COUNT(*)               AS invoices,
    SUM(balance)           AS balance,
    ROUND(100.0 * SUM(balance) / SUM(SUM(balance)) OVER (), 1) AS pct_of_open_balance
FROM open_invoices
GROUP BY
    CASE
        WHEN days_past_due <= 0  THEN 'Not yet due'
        WHEN days_past_due <= 30 THEN '1-30 days past due'
        WHEN days_past_due <= 60 THEN '31-60 days past due'
        WHEN days_past_due <= 90 THEN '61-90 days past due'
        ELSE '90+ days past due'
    END
ORDER BY MIN(days_past_due);

-- =====================================================================
-- 4. MONTHLY INVOICED VS COLLECTED
-- Question: how do billings and cash collections move month by month?
-- CTEs build both series, a month list covers months with only one of them,
-- LAG gives month-over-month change, SUM() OVER gives running totals.
-- =====================================================================
WITH monthly_invoiced AS (
    SELECT DATE_FORMAT(invoice_date, '%Y-%m') AS ym, SUM(invoice_total) AS invoiced
    FROM invoices
    GROUP BY DATE_FORMAT(invoice_date, '%Y-%m')
),
monthly_collected AS (
    SELECT DATE_FORMAT(payment_date, '%Y-%m') AS ym, SUM(amount) AS collected
    FROM payments
    GROUP BY DATE_FORMAT(payment_date, '%Y-%m')
),
months AS (
    SELECT ym FROM monthly_invoiced
    UNION
    SELECT ym FROM monthly_collected
),
combined AS (
    SELECT
        m.ym,
        COALESCE(mi.invoiced, 0)  AS invoiced,
        COALESCE(mc.collected, 0) AS collected
    FROM months m
    LEFT JOIN monthly_invoiced  mi ON mi.ym = m.ym
    LEFT JOIN monthly_collected mc ON mc.ym = m.ym
)
SELECT
    ym                                                    AS report_month,
    invoiced,
    collected,
    ROUND(100.0 * (invoiced - LAG(invoiced) OVER (ORDER BY ym))
                / LAG(invoiced) OVER (ORDER BY ym), 1)    AS invoiced_mom_pct,
    SUM(invoiced)  OVER (ORDER BY ym)                     AS running_invoiced,
    SUM(collected) OVER (ORDER BY ym)                     AS running_collected
FROM combined
ORDER BY ym;

-- =====================================================================
-- 5. PAYMENT METHOD MIX
-- Question: which payment channels bring in the most money?
-- =====================================================================
SELECT
    pm.name                       AS payment_method,
    COUNT(p.payment_id)           AS payments,
    COALESCE(SUM(p.amount), 0)    AS amount_collected,
    ROUND(100.0 * COALESCE(SUM(p.amount), 0) / SUM(SUM(p.amount)) OVER (), 1) AS pct_of_collected
FROM payment_methods pm
LEFT JOIN payments p ON p.payment_method = pm.payment_method_id
GROUP BY pm.payment_method_id, pm.name
ORDER BY amount_collected DESC;

-- =====================================================================
-- 6. HOW FAST DO CLIENTS PAY?
-- Question: which clients pay slowest, and how many payments arrive after the due date?
-- =====================================================================
SELECT
    c.name                                                    AS client_name,
    COUNT(*)                                                  AS payments,
    ROUND(AVG(DATEDIFF(p.payment_date, i.invoice_date)), 1)   AS avg_days_to_pay,
    SUM(CASE WHEN p.payment_date > i.due_date THEN 1 ELSE 0 END) AS late_payments
FROM payments p
JOIN invoices i ON i.invoice_id = p.invoice_id
JOIN clients  c ON c.client_id  = i.client_id
GROUP BY c.client_id, c.name
ORDER BY avg_days_to_pay DESC, client_name;

-- =====================================================================
-- 7. CLIENT REVENUE RANKING
-- Question: who are the biggest clients by invoiced revenue, and what share is each?
-- =====================================================================
SELECT
    client_name,
    total_invoiced,
    DENSE_RANK() OVER (ORDER BY total_invoiced DESC)                   AS revenue_rank,
    ROUND(100.0 * total_invoiced / SUM(total_invoiced) OVER (), 1)     AS pct_of_revenue
FROM sales_by_balances
WHERE total_invoiced > 0
ORDER BY revenue_rank, client_name;

-- =====================================================================
-- 8. SALARY ANALYSIS (window functions)
-- 8a. RANK vs DENSE_RANK when salaries are tied
-- =====================================================================
SELECT
    first_name,
    last_name,
    department,
    salary,
    RANK()       OVER (ORDER BY salary DESC) AS rank_salary,
    DENSE_RANK() OVER (ORDER BY salary DESC) AS dense_rank_salary
FROM employees
ORDER BY salary DESC, last_name;

-- 8b. Second-highest salary overall.
-- DENSE_RANK is correct here: with RANK, two people tied at the top mean rank 2 does not exist.
SELECT employee_id, first_name, last_name, job_title, department, salary
FROM (
    SELECT
        employee_id, first_name, last_name, job_title, department, salary,
        DENSE_RANK() OVER (ORDER BY salary DESC) AS salary_rank
    FROM employees
) AS ranked
WHERE salary_rank = 2;

-- 8c. Top earner(s) in each department
SELECT department, first_name, last_name, job_title, salary
FROM (
    SELECT
        department, first_name, last_name, job_title, salary,
        DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS dept_rank
    FROM employees
) AS ranked
WHERE dept_rank = 1
ORDER BY department, last_name;

-- 8d. Department compensation summary
SELECT
    department,
    COUNT(*)              AS employees,
    ROUND(AVG(salary), 0) AS avg_salary,
    MIN(salary)           AS min_salary,
    MAX(salary)           AS max_salary
FROM employees
GROUP BY department
ORDER BY avg_salary DESC;

-- =====================================================================
-- 9. DATA QUALITY CHECKS
-- Each check returns the number of problem rows. Expected result: 0 for all.
-- =====================================================================
SELECT 'Invoice payment_total differs from sum of its payments' AS check_name,
       COUNT(*) AS problem_rows
FROM (
    SELECT i.invoice_id
    FROM invoices i
    LEFT JOIN payments p ON p.invoice_id = i.invoice_id
    GROUP BY i.invoice_id, i.payment_total
    HAVING i.payment_total <> COALESCE(SUM(p.amount), 0)
) AS t1
UNION ALL
SELECT 'Invoice paid more than its total',
       COUNT(*)
FROM invoices
WHERE payment_total > invoice_total
UNION ALL
SELECT 'Payment dated before its invoice',
       COUNT(*)
FROM payments p
JOIN invoices i ON i.invoice_id = p.invoice_id
WHERE p.payment_date < i.invoice_date
UNION ALL
SELECT 'Payment client differs from invoice client',
       COUNT(*)
FROM payments p
JOIN invoices i ON i.invoice_id = p.invoice_id
WHERE p.client_id <> i.client_id
UNION ALL
SELECT 'Duplicate client names',
       COUNT(*)
FROM (
    SELECT name
    FROM clients
    GROUP BY name
    HAVING COUNT(*) > 1
) AS t2;
