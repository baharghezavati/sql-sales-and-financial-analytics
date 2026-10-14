# 📊 Financial & Operations Data Analytics (SQL & MySQL)

## 📌 Project Overview
This project demonstrates end-to-end relational database analysis for business reporting, client invoice management, and HR analytics. Using MySQL Workbench, structured SQL queries were executed to extract business insights, build database views for financial tracking, and apply window functions for organizational benchmarking.

---

## 🔑 Key Analytics & SQL Capabilities Covered
* **Relational Schema Design & Data Integrity:** Normalization, Primary/Foreign Key relationships.
* **Complex Multi-Table Joins (`JOIN` / `USING`):** Combining transactional data across clients, invoices, and payment channels.
* **Aggregations & Financial Views (`CREATE VIEW`, `SUM`, `GROUP BY`):** Building persistent analytical views for tracking outstanding balances.
* **Advanced Window Functions (`RANK() OVER`):** Ranking salary distributions and identifying specific salary percentiles/benchmarks.

---

## 🛠 Database Schema
The relational database consists of 5 interconnected entities:
1. `clients` - Customer demographic data
2. `invoices` - Billing records, invoice totals, and payment balances
3. `payments` - Transaction history and timestamps
4. `payment_methods` - Payment channels (Credit Card, Bank Transfer, E-Transfer)
5. `employees` - HR records and compensation data

---

## 🚀 Business Questions Answered & SQL Implementation

### 1. Client Balance & Outstanding Debt Analysis
**Business Need:** Identify high-risk accounts with overdue balances to optimize collection strategies.

```sql
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
```

**Query Output:**

| client_id | client_name | total_invoiced | outstanding_balance |
| :--- | :--- | :--- | :--- |
| 2 | Bison Transport | 39000.00 | 14000.00 |
| 4 | North West Company | 31000.00 | 16000.00 |
| 1 | Canada Life Assurance | 20500.00 | 4500.00 |
| 3 | Wawanesa Insurance | 9500.00 | 0.00 |
| 5 | Paterson Grain | 6200.00 | 0.00 |

---

### 2. Payment Audit & Channel Analysis
**Business Need:** Reconcile incoming transactions with specific payment gateways.

```sql
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
```

**Query Output:**

| payment_date | invoice_id | amount | client_name | payment_status_method |
| :--- | :--- | :--- | :--- | :--- |
| 2026-03-10 | 7 | 6200.00 | Paterson Grain | Credit Card |
| 2026-02-20 | 2 | 4000.00 | Canada Life Assurance | Credit Card |
| 2026-02-18 | 6 | 15000.00 | North West Company | Bank Transfer |
| 2026-02-10 | 5 | 9500.00 | Wawanesa Insurance | E-Transfer |
| 2026-01-25 | 3 | 25000.00 | Bison Transport | Bank Transfer |
| 2026-01-15 | 1 | 12000.00 | Canada Life Assurance | Bank Transfer |

---

### 3. HR Compensation Benchmarking (2nd Highest Salary)
**Business Need:** Evaluate compensation distribution using SQL Window Functions (`RANK`).

```sql
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
```

**Query Output:**

| employee_id | first_name | last_name | job_title | salary | rank_salary |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 3 | Michael | Brown | Financial Controller | 85000.00 | 2 |

---

## 💻 Tech Stack & Tools
* **Database:** MySQL 8.0 / MySQL Workbench
* **Language:** Structured Query Language (SQL)
* **Key Constructs:** Views, Subqueries, Multi-Joins, Aggregate Functions, Window Functions (`RANK`).
