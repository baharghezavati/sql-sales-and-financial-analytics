-- =====================================================================
-- Financial & Operations Analytics: database schema and sample data
-- Engine: MySQL 8.0 (tested logic also on SQLite). All data is FICTIONAL.
-- Run this file first, then queries.sql.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS sales_analytics;
USE sales_analytics;

-- Drop existing tables (child tables first)
DROP VIEW  IF EXISTS sales_by_balances;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS invoices;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS clients;
DROP TABLE IF EXISTS payment_methods;

-- 1. Clients
CREATE TABLE clients (
    client_id INT PRIMARY KEY AUTO_INCREMENT,
    name      VARCHAR(100) NOT NULL,
    city      VARCHAR(50),
    state     VARCHAR(50)
);

-- 2. Payment methods
CREATE TABLE payment_methods (
    payment_method_id INT PRIMARY KEY AUTO_INCREMENT,
    name              VARCHAR(50) NOT NULL
);

-- 3. Invoices (payment_total = amount received so far)
CREATE TABLE invoices (
    invoice_id    INT PRIMARY KEY AUTO_INCREMENT,
    client_id     INT NOT NULL,
    invoice_total DECIMAL(10,2) NOT NULL,
    payment_total DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    invoice_date  DATE NOT NULL,
    due_date      DATE NOT NULL,
    FOREIGN KEY (client_id) REFERENCES clients(client_id)
);

-- 4. Payments
CREATE TABLE payments (
    payment_id     INT PRIMARY KEY AUTO_INCREMENT,
    client_id      INT NOT NULL,
    invoice_id     INT NOT NULL,
    payment_date   DATE NOT NULL,
    amount         DECIMAL(10,2) NOT NULL,
    payment_method INT NOT NULL,
    FOREIGN KEY (client_id)      REFERENCES clients(client_id),
    FOREIGN KEY (invoice_id)     REFERENCES invoices(invoice_id),
    FOREIGN KEY (payment_method) REFERENCES payment_methods(payment_method_id)
);

-- 5. Employees
CREATE TABLE employees (
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name  VARCHAR(50),
    last_name   VARCHAR(50),
    job_title   VARCHAR(50),
    salary      DECIMAL(10,2),
    department  VARCHAR(50)
);

-- =====================================================================
-- Sample data (fictional companies and people)
-- =====================================================================
INSERT INTO clients (name, city, state) VALUES
('Red River Assurance', 'Winnipeg', 'MB'),
('Prairie Freight Lines', 'Winnipeg', 'MB'),
('Assiniboine Mutual Insurance', 'Winnipeg', 'MB'),
('Northern Trade Company', 'Winnipeg', 'MB'),
('Harvest Plains Grain', 'Winnipeg', 'MB'),
('Lakeside Dental Group', 'Winnipeg', 'MB'),
('Forks Hospitality', 'Winnipeg', 'MB'),
('Polar Tech Services', 'Winnipeg', 'MB'),
('Midland Construction', 'Brandon', 'MB'),
('Brandon Ag Supply', 'Brandon', 'MB'),
('Steinbach Manufacturing', 'Steinbach', 'MB'),
('Northern Lights Energy', 'Thompson', 'MB');

INSERT INTO payment_methods (name) VALUES
('Credit Card'),
('Bank Transfer'),
('E-Transfer'),
('Cheque');

INSERT INTO invoices (client_id, invoice_total, payment_total, invoice_date, due_date) VALUES
(1, 12000.00, 12000.00, '2026-01-10', '2026-02-10'),
(1, 8500.00, 4000.00, '2026-02-15', '2026-03-15'),
(2, 25000.00, 25000.00, '2026-01-20', '2026-02-20'),
(2, 14000.00, 0.00, '2026-03-01', '2026-04-01'),
(3, 9500.00, 9500.00, '2026-02-01', '2026-03-01'),
(4, 31000.00, 15000.00, '2026-02-10', '2026-03-10'),
(5, 6200.00, 6200.00, '2026-03-05', '2026-04-05'),
(7, 3800.00, 3800.00, '2026-01-08', '2026-02-07'),
(4, 22500.00, 15700.00, '2026-01-17', '2026-02-16'),
(7, 6800.00, 6800.00, '2026-01-21', '2026-02-20'),
(7, 22500.00, 15700.00, '2026-01-27', '2026-02-26'),
(3, 18000.00, 18000.00, '2026-01-28', '2026-02-27'),
(7, 14800.00, 14800.00, '2026-02-10', '2026-03-12'),
(1, 4500.00, 4500.00, '2026-02-21', '2026-03-23'),
(4, 7500.00, 0.00, '2026-02-21', '2026-03-23'),
(7, 7500.00, 7500.00, '2026-02-25', '2026-03-27'),
(5, 18000.00, 18000.00, '2026-02-26', '2026-03-28'),
(11, 7500.00, 0.00, '2026-03-09', '2026-04-08'),
(9, 6800.00, 6800.00, '2026-03-29', '2026-04-28'),
(9, 22500.00, 22500.00, '2026-04-13', '2026-05-13'),
(1, 22500.00, 22500.00, '2026-04-16', '2026-05-16'),
(9, 18000.00, 0.00, '2026-04-22', '2026-05-22'),
(5, 6800.00, 0.00, '2026-04-25', '2026-05-25'),
(10, 9200.00, 0.00, '2026-04-27', '2026-05-27'),
(7, 4500.00, 4500.00, '2026-05-10', '2026-06-09'),
(6, 3800.00, 0.00, '2026-05-10', '2026-06-09'),
(9, 3100.00, 0.00, '2026-05-22', '2026-06-21'),
(7, 3100.00, 3100.00, '2026-06-02', '2026-07-02'),
(3, 18000.00, 18000.00, '2026-06-04', '2026-07-04'),
(7, 2400.00, 0.00, '2026-06-20', '2026-07-20'),
(10, 5200.00, 0.00, '2026-06-28', '2026-07-28'),
(4, 6800.00, 6800.00, '2026-07-07', '2026-08-06'),
(11, 5200.00, 5200.00, '2026-07-18', '2026-08-17'),
(3, 2400.00, 2400.00, '2026-08-09', '2026-09-08'),
(7, 18000.00, 0.00, '2026-08-25', '2026-09-24'),
(7, 14800.00, 0.00, '2026-09-20', '2026-10-20');

INSERT INTO payments (client_id, invoice_id, payment_date, amount, payment_method) VALUES
(1, 1, '2026-01-15', 12000.00, 2),
(2, 3, '2026-01-25', 25000.00, 2),
(7, 10, '2026-02-09', 6800.00, 2),
(3, 12, '2026-02-09', 18000.00, 1),
(3, 5, '2026-02-10', 9500.00, 3),
(7, 8, '2026-02-17', 3800.00, 2),
(4, 9, '2026-02-17', 15700.00, 2),
(4, 6, '2026-02-18', 15000.00, 2),
(1, 2, '2026-02-20', 4000.00, 1),
(7, 13, '2026-02-21', 5900.00, 2),
(7, 11, '2026-03-01', 15700.00, 2),
(5, 7, '2026-03-10', 6200.00, 1),
(7, 13, '2026-03-11', 8900.00, 2),
(5, 17, '2026-03-12', 18000.00, 4),
(1, 14, '2026-03-26', 4500.00, 4),
(7, 16, '2026-04-16', 4500.00, 3),
(7, 16, '2026-04-29', 3000.00, 2),
(1, 21, '2026-04-29', 22500.00, 1),
(9, 19, '2026-05-04', 6800.00, 2),
(9, 20, '2026-05-27', 22500.00, 2),
(7, 28, '2026-06-09', 3100.00, 2),
(7, 25, '2026-06-14', 4500.00, 4),
(3, 29, '2026-07-24', 18000.00, 1),
(4, 32, '2026-08-10', 6800.00, 1),
(11, 33, '2026-08-29', 5200.00, 1),
(3, 34, '2026-09-28', 2400.00, 3);

INSERT INTO employees (first_name, last_name, job_title, salary, department) VALUES
('John', 'Smith', 'Data Analyst', 68000.00, 'Analytics'),
('Sarah', 'Connor', 'Senior BI Developer', 92000.00, 'Analytics'),
('Michael', 'Brown', 'Financial Controller', 85000.00, 'Finance'),
('Emily', 'Davis', 'Operations Manager', 78000.00, 'Operations'),
('David', 'Wilson', 'Junior Analyst', 58000.00, 'Analytics'),
('Priya', 'Patel', 'Analytics Manager', 92000.00, 'Analytics'),
('Liam', 'Nguyen', 'Accountant', 64000.00, 'Finance'),
('Olivia', 'Martin', 'Financial Analyst', 72000.00, 'Finance'),
('Noah', 'Tremblay', 'Operations Coordinator', 56000.00, 'Operations'),
('Ava', 'Campbell', 'Logistics Analyst', 61000.00, 'Operations'),
('Ethan', 'Roy', 'Sales Representative', 59000.00, 'Sales'),
('Mia', 'Fraser', 'Sales Representative', 59000.00, 'Sales'),
('Lucas', 'Bouchard', 'Sales Manager', 88000.00, 'Sales'),
('Chloe', 'Singh', 'Data Analyst', 68000.00, 'Analytics');
