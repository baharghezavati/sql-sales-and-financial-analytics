# Financial and Operations Analytics in SQL (MySQL)

A SQL portfolio project that answers business questions about client invoicing, payments, receivables and employee compensation. It uses joins, views, CTEs, window functions, `CASE` logic and data-quality checks on a small relational database (5 tables). **All data is fictional.**

## Key findings
- **Collection rate is 65%.** Of $412,700 invoiced, $268,300 has been collected and $144,400 is still outstanding.
- **Unpaid money is concentrated.** The top 3 clients hold 64.7% of the outstanding balance, and the top 5 hold 84.3%. Forks Hospitality alone owes $42,000 (29.1%).
- **Most of the open balance is old.** 72.0% ($104,000 across 12 invoices) is more than 90 days past due.
- **Payment channels:** Bank Transfer brings in 53.7% of collected cash; E-Transfer only 6.1%.
- **Slow payers:** Steinbach Manufacturing takes 42 days on average; Forks Hospitality pays 5 of its 9 payments after the due date.
- **`RANK` vs `DENSE_RANK`:** two employees are tied for the highest salary, so `RANK` skips rank 2 entirely. `DENSE_RANK` correctly returns the second-highest salary: Lucas Bouchard, $88,000.
- **Data quality:** all 5 integrity checks return 0 problem rows.

## Database
| Table | Description |
|---|---|
| `clients` | 12 clients (name, city, province); 2 have no invoices yet |
| `invoices` | 36 invoices with total, amount paid, invoice date and due date |
| `payments` | 26 payments linked to an invoice, client and payment method |
| `payment_methods` | Credit Card, Bank Transfer, E-Transfer, Cheque |
| `employees` | 14 employees with title, department and salary |

## SQL skills demonstrated
| Skill | Where |
|---|---|
| `LEFT JOIN` with `COALESCE` (keep clients with no invoices) | Query 1 |
| Views (`CREATE VIEW`) | Query 1 |
| CTEs (`WITH`) | Queries 2, 3, 4 |
| Window functions: `SUM() OVER`, `LAG`, `RANK`, `DENSE_RANK`, `PARTITION BY` | Queries 2, 4, 7, 8 |
| `CASE` bucketing (aging analysis) | Query 3 |
| Date functions (`DATE_FORMAT`, `DATEDIFF`) | Queries 3, 4, 6 |
| Multi-table joins and conditional aggregation | Queries 5, 6 |
| Data validation with `UNION ALL` and `HAVING` | Query 9 |

## Business questions and results
The "as of" date for aging is 2026-09-30.

### 1. How much has each client been invoiced, paid and still owes?
Uses a view and a `LEFT JOIN`, so clients without invoices appear with 0 instead of disappearing.

```sql
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
```

| client_id | client_name | invoices | total_invoiced | total_paid | outstanding_balance |
|---|---|---|---|---|---|
| 7 | Forks Hospitality | 10 | $98,200 | $56,200 | $42,000 |
| 4 | Northern Trade Company | 4 | $67,800 | $37,500 | $30,300 |
| 9 | Midland Construction | 4 | $50,400 | $29,300 | $21,100 |
| 10 | Brandon Ag Supply | 2 | $14,400 | $0 | $14,400 |
| 2 | Prairie Freight Lines | 2 | $39,000 | $25,000 | $14,000 |
| 11 | Steinbach Manufacturing | 2 | $12,700 | $5,200 | $7,500 |
| 5 | Harvest Plains Grain | 3 | $31,000 | $24,200 | $6,800 |
| 1 | Red River Assurance | 4 | $47,500 | $43,000 | $4,500 |
| 6 | Lakeside Dental Group | 1 | $3,800 | $0 | $3,800 |
| 3 | Assiniboine Mutual Insurance | 4 | $47,900 | $47,900 | $0 |
| 12 | Northern Lights Energy | 0 | $0 | $0 | $0 |
| 8 | Polar Tech Services | 0 | $0 | $0 | $0 |

### 2. Which clients make up most of the money we are still owed?
Window functions give each client's share and the running (cumulative) share.

| client_name | outstanding_balance | pct_of_total | cumulative_pct |
|---|---|---|---|
| Forks Hospitality | $42,000 | 29.1% | 29.1% |
| Northern Trade Company | $30,300 | 21.0% | 50.1% |
| Midland Construction | $21,100 | 14.6% | 64.7% |
| Brandon Ag Supply | $14,400 | 10.0% | 74.7% |
| Prairie Freight Lines | $14,000 | 9.7% | 84.3% |
| Steinbach Manufacturing | $7,500 | 5.2% | 89.5% |
| Harvest Plains Grain | $6,800 | 4.7% | 94.3% |
| Red River Assurance | $4,500 | 3.1% | 97.4% |
| Lakeside Dental Group | $3,800 | 2.6% | 100.0% |

### 3. How old are the unpaid balances? (receivables aging)
`CASE` groups open invoices by days past due.

| aging_bucket | invoices | balance | pct_of_open_balance |
|---|---|---|---|
| Not yet due | 1 | $14,800 | 10.2% |
| 1-30 days past due | 1 | $18,000 | 12.5% |
| 61-90 days past due | 2 | $7,600 | 5.3% |
| 90+ days past due | 12 | $104,000 | 72.0% |

### 4. How do billings and collections move month by month?
CTEs build both series, `LAG` gives month-over-month change, and `SUM() OVER` gives running totals.

| report_month | invoiced | collected | invoiced_mom_pct | running_invoiced | running_collected |
|---|---|---|---|---|---|
| 2026-01 | $110,600 | $37,000 | - | $110,600 | $37,000 |
| 2026-02 | $101,300 | $78,700 | -8.4% | $211,900 | $115,700 |
| 2026-03 | $34,500 | $53,300 | -65.9% | $246,400 | $169,000 |
| 2026-04 | $79,000 | $30,000 | 129.0% | $325,400 | $199,000 |
| 2026-05 | $11,400 | $29,300 | -85.6% | $336,800 | $228,300 |
| 2026-06 | $28,700 | $7,600 | 151.8% | $365,500 | $235,900 |
| 2026-07 | $12,000 | $18,000 | -58.2% | $377,500 | $253,900 |
| 2026-08 | $20,400 | $12,000 | 70.0% | $397,900 | $265,900 |
| 2026-09 | $14,800 | $2,400 | -27.5% | $412,700 | $268,300 |

### 5. Which payment methods bring in the most money?
| payment_method | payments | amount_collected | pct_of_collected |
|---|---|---|---|
| Bank Transfer | 13 | $144,200 | 53.7% |
| Credit Card | 7 | $80,700 | 30.1% |
| Cheque | 3 | $27,000 | 10.1% |
| E-Transfer | 3 | $16,400 | 6.1% |

### 6. How fast do clients pay?
| client_name | payments | avg_days_to_pay | late_payments |
|---|---|---|---|
| Steinbach Manufacturing | 1 | 42.0 | 1 |
| Midland Construction | 2 | 40.0 | 2 |
| Forks Hospitality | 9 | 31.9 | 5 |
| Assiniboine Mutual Insurance | 4 | 30.3 | 2 |
| Northern Trade Company | 3 | 24.3 | 2 |
| Red River Assurance | 4 | 14.0 | 1 |
| Harvest Plains Grain | 2 | 9.5 | 0 |
| Prairie Freight Lines | 1 | 5.0 | 0 |

### 7. Who are the biggest clients by revenue?
| client_name | total_invoiced | revenue_rank | pct_of_revenue |
|---|---|---|---|
| Forks Hospitality | $98,200 | 1 | 23.8% |
| Northern Trade Company | $67,800 | 2 | 16.4% |
| Midland Construction | $50,400 | 3 | 12.2% |
| Assiniboine Mutual Insurance | $47,900 | 4 | 11.6% |
| Red River Assurance | $47,500 | 5 | 11.5% |
| Prairie Freight Lines | $39,000 | 6 | 9.4% |
| Harvest Plains Grain | $31,000 | 7 | 7.5% |
| Brandon Ag Supply | $14,400 | 8 | 3.5% |
| Steinbach Manufacturing | $12,700 | 9 | 3.1% |
| Lakeside Dental Group | $3,800 | 10 | 0.9% |

### 8. Salary analysis: `RANK` vs `DENSE_RANK`
Two employees share the top salary. `RANK` gives 1, 1, 3, so "rank = 2" would return nothing. `DENSE_RANK` gives 1, 1, 2.

| first_name | last_name | department | salary | rank_salary | dense_rank_salary |
|---|---|---|---|---|---|
| Sarah | Connor | Analytics | $92,000 | 1 | 1 |
| Priya | Patel | Analytics | $92,000 | 1 | 1 |
| Lucas | Bouchard | Sales | $88,000 | 3 | 2 |
| Michael | Brown | Finance | $85,000 | 4 | 3 |
| Emily | Davis | Operations | $78,000 | 5 | 4 |
| Olivia | Martin | Finance | $72,000 | 6 | 5 |
| Chloe | Singh | Analytics | $68,000 | 7 | 6 |
| John | Smith | Analytics | $68,000 | 7 | 6 |
| Liam | Nguyen | Finance | $64,000 | 9 | 7 |
| Ava | Campbell | Operations | $61,000 | 10 | 8 |
| Mia | Fraser | Sales | $59,000 | 11 | 9 |
| Ethan | Roy | Sales | $59,000 | 11 | 9 |
| David | Wilson | Analytics | $58,000 | 13 | 10 |
| Noah | Tremblay | Operations | $56,000 | 14 | 11 |

Second-highest salary (correct with `DENSE_RANK`):

| employee_id | first_name | last_name | job_title | department | salary |
|---|---|---|---|---|---|
| 13 | Lucas | Bouchard | Sales Manager | Sales | $88,000 |

Top earner(s) per department (`PARTITION BY`):

| department | first_name | last_name | job_title | salary |
|---|---|---|---|---|
| Analytics | Sarah | Connor | Senior BI Developer | $92,000 |
| Analytics | Priya | Patel | Analytics Manager | $92,000 |
| Finance | Michael | Brown | Financial Controller | $85,000 |
| Operations | Emily | Davis | Operations Manager | $78,000 |
| Sales | Lucas | Bouchard | Sales Manager | $88,000 |

Department compensation summary:

| department | employees | avg_salary | min_salary | max_salary |
|---|---|---|---|---|
| Analytics | 5 | $75,600 | $58,000 | $92,000 |
| Finance | 3 | $73,667 | $64,000 | $85,000 |
| Sales | 3 | $68,667 | $59,000 | $88,000 |
| Operations | 3 | $65,000 | $56,000 | $78,000 |

### 9. Data quality checks
Each check should return 0. They confirm that stored payment totals match the payments table, no invoice is overpaid, no payment is dated before its invoice, payment and invoice clients agree, and there are no duplicate clients.

| check_name | problem_rows |
|---|---|
| Invoice payment_total differs from sum of its payments | 0 |
| Invoice paid more than its total | 0 |
| Payment dated before its invoice | 0 |
| Payment client differs from invoice client | 0 |
| Duplicate client names | 0 |

## How to run
1. Open **MySQL Workbench** (MySQL 8.0 or later; window functions and CTEs need 8.0).
2. Open `schema.sql` and run it. It creates the `sales_analytics` database, tables and sample data.
3. Open `queries.sql` and run each statement on its own (place the cursor in the query and press `Ctrl+Enter`).

## Files
| File | Description |
|---|---|
| `schema.sql` | Database, tables and fictional sample data |
| `queries.sql` | 9 sections of business questions and data checks |
| `README.md` | Findings and results |

## Tools
MySQL 8.0, MySQL Workbench.


