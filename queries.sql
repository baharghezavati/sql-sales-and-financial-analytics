USE sales_analytics;

-- =================================================================
-- 1. CLIENT FINANCIAL SUMMARY (Total Sales & Outstanding Balances)
-- Purpose: Calculate total invoiced sales and remaining unpaid balance per client.
-- =================================================================
CREATE VIEW sales_by_balances AS
SELECT 
    c.client_id, 
    c.name AS client_name, 
    SUM(i.invoice_total) AS total_invoiced,
    SUM(i.invoice_total - i.payment_total) AS outstanding_balance
FROM clients c
JOIN invoices i USING (client_id)
GROUP BY c.client_id, c.name
ORDER BY outstanding_balance DESC;

-- =================================================================
-- 2. PAYMENT TRANSACTIONS & METHOD TRACKING
-- Purpose: Audit invoice payment details along with payment methods used.
-- =================================================================
SELECT 
    p.date AS payment_date, 
    p.invoice_id, 
    p.amount, 
    c.name AS client_name, 
    pm.name AS payment_status_method
FROM payments p
JOIN clients c ON p.client_id = c.client_id
JOIN payment_methods pm ON p.payment_method = pm.payment_method_id
ORDER BY p.date DESC;

-- =================================================================
-- 3. SALARY RANKING  (Window Functions)
-- Purpose: Rank employee compensation within the organization to identify key benchmarks.
-- =================================================================
-- Get employees ranked by salary
SELECT 
    employee_id,
    first_name,
    last_name,
    job_title,
    department,
    salary,
    RANK() OVER (ORDER BY salary DESC) AS salary_rank
FROM employees;

-- Query to find the 2nd Highest Salary 
SELECT * 
FROM (
    SELECT 
        employee_id,
        first_name,
        last_name,
        job_title,
        salary,
        RANK() OVER (ORDER BY salary DESC) AS rank_salary
    FROM employees
) AS ranked_salary
WHERE rank_salary = 2;