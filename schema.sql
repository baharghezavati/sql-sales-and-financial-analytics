-- Create Database
CREATE DATABASE IF NOT EXISTS sales_analytics;
USE sales_analytics;

-- Drop existing tables
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS invoices;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS clients;
DROP TABLE IF EXISTS payment_methods;

-- 1. Clients Table
CREATE TABLE clients (
    client_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    city VARCHAR(50),
    state VARCHAR(50)
);

-- 2. Payment Methods Table
CREATE TABLE payment_methods (
    payment_method_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL
);

-- 3. Invoices Table
CREATE TABLE invoices (
    invoice_id INT PRIMARY KEY AUTO_INCREMENT,
    client_id INT,
    invoice_total DECIMAL(10,2) NOT NULL,
    payment_total DECIMAL(10,2) DEFAULT 0.00,
    invoice_date DATE,
    due_date DATE,
    FOREIGN KEY (client_id) REFERENCES clients(client_id)
);

-- 4. Payments Table
CREATE TABLE payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    client_id INT,
    invoice_id INT,
    date DATE,
    amount DECIMAL(10,2) NOT NULL,
    payment_method INT,
    FOREIGN KEY (client_id) REFERENCES clients(client_id),
    FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id),
    FOREIGN KEY (payment_method) REFERENCES payment_methods(payment_method_id)
);

-- 5. Employees Table
CREATE TABLE employees (
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    job_title VARCHAR(50),
    salary DECIMAL(10,2),
    department VARCHAR(50)
);

-- Seed Data
INSERT INTO clients (name, city, state) VALUES
('Canada Life Assurance', 'Winnipeg', 'MB'),
('Bison Transport', 'Winnipeg', 'MB'),
('Wawanesa Insurance', 'Winnipeg', 'MB'),
('North West Company', 'Winnipeg', 'MB'),
('Paterson Grain', 'Winnipeg', 'MB');

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
(5, 6200.00, 6200.00, '2026-03-05', '2026-04-05');

INSERT INTO payments (client_id, invoice_id, date, amount, payment_method) VALUES
(1, 1, '2026-01-15', 12000.00, 2),
(1, 2, '2026-02-20', 4000.00, 1),
(2, 3, '2026-01-25', 25000.00, 2),
(3, 5, '2026-02-10', 9500.00, 3),
(4, 6, '2026-02-18', 15000.00, 2),
(5, 7, '2026-03-10', 6200.00, 1);

INSERT INTO employees (first_name, last_name, job_title, salary, department) VALUES
('John', 'Smith', 'Data Analyst', 68000.00, 'Analytics'),
('Sarah', 'Connor', 'Senior BI Developer', 92000.00, 'Analytics'),
('Michael', 'Brown', 'Financial Controller', 85000.00, 'Finance'),
('Emily', 'Davis', 'Operations Manager', 78000.00, 'Operations'),
('David', 'Wilson', 'Junior Analyst', 58000.00, 'Analytics');