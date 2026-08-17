USE banking_analysis;


-- ============================================================
-- 1. DATABASE & TABLE CHECK
-- ============================================================

SHOW TABLES;

SELECT 'account_status' AS table_name, COUNT(*) AS row_count
FROM account_status

UNION ALL
SELECT 'account_types', COUNT(*) FROM account_types

UNION ALL
SELECT 'accounts', COUNT(*) FROM accounts

UNION ALL
SELECT 'addresses', COUNT(*) FROM addresses

UNION ALL
SELECT 'branches', COUNT(*) FROM branches

UNION ALL
SELECT 'customer', COUNT(*) FROM customer

UNION ALL
SELECT 'loan', COUNT(*) FROM loan

UNION ALL
SELECT 'loan_status', COUNT(*) FROM loan_status

UNION ALL
SELECT 'transaction_types', COUNT(*) FROM transaction_types

UNION ALL
SELECT 'transactions', COUNT(*) FROM transactions;


-- ============================================================
-- 2. DATA STRUCTURE CHECK
-- ============================================================

DESCRIBE customer;
DESCRIBE accounts;
DESCRIBE addresses;
DESCRIBE loan;
DESCRIBE transactions;
DESCRIBE account_status;
DESCRIBE account_types;
DESCRIBE branches;
DESCRIBE loan_status;
DESCRIBE transaction_types;


-- ============================================================
-- 3. REFERENTIAL INTEGRITY CHECK
-- ============================================================

-- Accounts → Customers
SELECT COUNT(*) AS orphan_accounts_customers
FROM accounts a
LEFT JOIN customer c
    ON a.CustomerID = c.CustomerID
WHERE c.CustomerID IS NULL;


-- Accounts → Account Types
SELECT COUNT(*) AS orphan_accounts_types
FROM accounts a
LEFT JOIN account_types at
    ON a.AccountTypeID = at.AccountTypeID
WHERE at.AccountTypeID IS NULL;


-- Accounts → Account Status
SELECT COUNT(*) AS orphan_accounts_status
FROM accounts a
LEFT JOIN account_status s
    ON a.AccountStatusID = s.AccountStatusID
WHERE s.AccountStatusID IS NULL;


-- Loans → Accounts
SELECT COUNT(*) AS orphan_loans_accounts
FROM loan l
LEFT JOIN accounts a
    ON l.AccountID = a.AccountID
WHERE a.AccountID IS NULL;


-- Loans → Loan Status
SELECT COUNT(*) AS orphan_loans_status
FROM loan l
LEFT JOIN loan_status ls
    ON l.LoanStatusID = ls.LoanStatusID
WHERE ls.LoanStatusID IS NULL;


-- Transactions → Origin Accounts
SELECT COUNT(*) AS orphan_transaction_origin
FROM transactions t
LEFT JOIN accounts a
    ON t.AccountOriginID = a.AccountID
WHERE a.AccountID IS NULL;


-- Transactions → Destination Accounts
SELECT COUNT(*) AS orphan_transaction_destination
FROM transactions t
LEFT JOIN accounts a
    ON t.AccountDestinationID = a.AccountID
WHERE a.AccountID IS NULL;


-- Transactions → Transaction Types
SELECT COUNT(*) AS orphan_transaction_types
FROM transactions t
LEFT JOIN transaction_types tt
    ON t.TransactionTypeID = tt.TransactionTypeID
WHERE tt.TransactionTypeID IS NULL;


-- Transactions → Branches
SELECT COUNT(*) AS orphan_transaction_branches
FROM transactions t
LEFT JOIN branches b
    ON t.BranchID = b.BranchID
WHERE b.BranchID IS NULL;


-- Branches → Addresses
SELECT COUNT(*) AS orphan_branch_addresses
FROM branches b
LEFT JOIN addresses a
    ON b.AddressID = a.AddressID
WHERE a.AddressID IS NULL;


-- ============================================================
-- 4. DUPLICATE RECORD CHECK
-- ============================================================

SELECT
    'customer' AS table_name,
    COUNT(*) - COUNT(DISTINCT CustomerID) AS duplicate_ids
FROM customer

UNION ALL

SELECT
    'accounts',
    COUNT(*) - COUNT(DISTINCT AccountID)
FROM accounts

UNION ALL

SELECT
    'transactions',
    COUNT(*) - COUNT(DISTINCT TransactionID)
FROM transactions

UNION ALL

SELECT
    'loan',
    COUNT(*) - COUNT(DISTINCT LoanID)
FROM loan

UNION ALL

SELECT
    'branches',
    COUNT(*) - COUNT(DISTINCT BranchID)
FROM branches

UNION ALL

SELECT
    'addresses',
    COUNT(*) - COUNT(DISTINCT AddressID)
FROM addresses;


-- ============================================================
-- 5. DATA CLEANING
-- ============================================================

-- Create backups before cleaning

CREATE TABLE transactions_backup AS
SELECT *
FROM transactions;

CREATE TABLE customer_backup AS
SELECT *
FROM customer;

CREATE TABLE accounts_backup AS
SELECT *
FROM accounts;

CREATE TABLE loan_backup AS
SELECT *
FROM loan;

CREATE TABLE addresses_backup AS
SELECT *
FROM addresses;


-- Create cleaned tables

CREATE TABLE transactions_clean AS
SELECT DISTINCT *
FROM transactions;

CREATE TABLE customer_clean AS
SELECT DISTINCT *
FROM customer;

CREATE TABLE accounts_clean AS
SELECT DISTINCT *
FROM accounts;

CREATE TABLE loan_clean AS
SELECT DISTINCT *
FROM loan;

CREATE TABLE addresses_clean AS
SELECT DISTINCT *
FROM addresses;


-- ============================================================
-- 6. NULL VALUE CHECK
-- ============================================================

SELECT
    'customer_clean' AS table_name,
    SUM(CustomerID IS NULL) AS CustomerID_NULL,
    SUM(FirstName IS NULL) AS FirstName_NULL,
    SUM(LastName IS NULL) AS LastName_NULL,
    SUM(DateOfBirth IS NULL) AS DateOfBirth_NULL,
    SUM(AddressID IS NULL) AS AddressID_NULL,
    SUM(CustomerTypeID IS NULL) AS CustomerTypeID_NULL
FROM customer_clean;


SELECT
    'accounts_clean' AS table_name,
    SUM(AccountID IS NULL) AS AccountID_NULL,
    SUM(CustomerID IS NULL) AS CustomerID_NULL,
    SUM(AccountTypeID IS NULL) AS AccountTypeID_NULL,
    SUM(AccountStatusID IS NULL) AS AccountStatusID_NULL,
    SUM(Balance IS NULL) AS Balance_NULL,
    SUM(OpeningDate IS NULL) AS OpeningDate_NULL
FROM accounts_clean;


SELECT
    'loan_clean' AS table_name,
    SUM(LoanID IS NULL) AS LoanID_NULL,
    SUM(AccountID IS NULL) AS AccountID_NULL,
    SUM(LoanStatusID IS NULL) AS LoanStatusID_NULL,
    SUM(PrincipalAmount IS NULL) AS PrincipalAmount_NULL,
    SUM(InterestRate IS NULL) AS InterestRate_NULL,
    SUM(StartDate IS NULL) AS StartDate_NULL,
    SUM(EstimatedEndDate IS NULL) AS EstimatedEndDate_NULL
FROM loan_clean;


SELECT
    'transactions_clean' AS table_name,
    SUM(TransactionID IS NULL) AS TransactionID_NULL,
    SUM(AccountOriginID IS NULL) AS AccountOriginID_NULL,
    SUM(AccountDestinationID IS NULL) AS AccountDestinationID_NULL,
    SUM(TransactionTypeID IS NULL) AS TransactionTypeID_NULL,
    SUM(Amount IS NULL) AS Amount_NULL,
    SUM(TransactionDate IS NULL) AS TransactionDate_NULL,
    SUM(BranchID IS NULL) AS BranchID_NULL,
    SUM(Description IS NULL) AS Description_NULL
FROM transactions_clean;


-- ============================================================
-- 7. DATA QUALITY CHECKS
-- ============================================================

-- Negative account balances
SELECT
    AccountID,
    CustomerID,
    Balance,
    AccountTypeID,
    AccountStatusID,
    OpeningDate
FROM accounts_clean
WHERE Balance < 0
ORDER BY Balance;


-- Negative transaction amounts
SELECT COUNT(*) AS negative_amount_records
FROM transactions_clean
WHERE Amount < 0;


-- Negative loan principal amounts
SELECT COUNT(*) AS negative_principal_records
FROM loan_clean
WHERE PrincipalAmount < 0;


-- Negative interest rates
SELECT COUNT(*) AS negative_interest_rate_records
FROM loan_clean
WHERE InterestRate < 0;


-- ============================================================
-- 8. DATE VALIDATION
-- ============================================================

SELECT COUNT(*) AS invalid_transaction_dates
FROM transactions_clean
WHERE STR_TO_DATE(
    LEFT(TransactionDate, 19),
    '%Y-%m-%d %H:%i:%s'
) IS NULL;


-- ============================================================
-- 9. BUSINESS ANALYSIS
-- ============================================================

-- Q1: Overall Transaction Activity

-- 1A. Overall transaction statistics
SELECT
    COUNT(*) AS total_transactions,
    SUM(Amount) AS total_transaction_amount,
    AVG(Amount) AS average_transaction_amount,
    MIN(Amount) AS minimum_transaction_amount,
    MAX(Amount) AS maximum_transaction_amount
FROM transactions_clean;


-- 1B. Transaction activity over time
SELECT
    YEAR(
        STR_TO_DATE(
            TransactionDate,
            '%Y-%m-%d %H:%i:%s.%f'
        )
    ) AS transaction_year,
    COUNT(*) AS transaction_count,
    SUM(Amount) AS total_transaction_amount,
    AVG(Amount) AS average_transaction_amount
FROM transactions_clean
WHERE TRIM(TransactionDate) <> ''
GROUP BY transaction_year
ORDER BY transaction_year;


-- Q2: High-Value Transactions

WITH ranked_transactions AS (
    SELECT
        TransactionID,
        AccountOriginID,
        AccountDestinationID,
        Amount,
        TransactionDate,
        PERCENT_RANK() OVER (
            ORDER BY Amount
        ) AS amount_percentile
    FROM transactions_clean
)

SELECT
    TransactionID,
    AccountOriginID,
    AccountDestinationID,
    Amount,
    TransactionDate,
    'High Value' AS transaction_category
FROM ranked_transactions
WHERE amount_percentile >= 0.90
ORDER BY Amount DESC;


-- Q3: Abnormal Spending Behavior

WITH transaction_history AS (
    SELECT
        TransactionID,
        AccountOriginID,
        TransactionDate,
        Amount,

        LAG(Amount) OVER (
            PARTITION BY AccountOriginID
            ORDER BY TransactionDate
        ) AS previous_amount,

        LEAD(Amount) OVER (
            PARTITION BY AccountOriginID
            ORDER BY TransactionDate
        ) AS next_amount

    FROM transactions_clean
    WHERE TRIM(TransactionDate) <> ''
)

SELECT
    TransactionID,
    AccountOriginID,
    TransactionDate,
    Amount,
    previous_amount,
    next_amount,
    Amount - previous_amount AS amount_change,

    ROUND(
        (
            (Amount - previous_amount)
            / NULLIF(previous_amount, 0)
        ) * 100,
        2
    ) AS percentage_change

FROM transaction_history
WHERE previous_amount IS NOT NULL
  AND Amount > previous_amount * 2
ORDER BY percentage_change DESC;


-- Q4: Suspicious Transactions & Risk Levels

WITH ranked_transactions AS (
    SELECT
        TransactionID,
        AccountOriginID,
        AccountDestinationID,
        TransactionDate,
        Amount,

        PERCENT_RANK() OVER (
            ORDER BY Amount
        ) AS amount_percentile

    FROM transactions_clean
    WHERE TRIM(TransactionDate) <> ''
),

transaction_history AS (
    SELECT
        TransactionID,
        AccountOriginID,
        AccountDestinationID,
        TransactionDate,
        Amount,
        amount_percentile,

        LAG(Amount) OVER (
            PARTITION BY AccountOriginID
            ORDER BY TransactionDate
        ) AS previous_amount

    FROM ranked_transactions
),

risk_analysis AS (
    SELECT
        *,
        
        CASE
            WHEN amount_percentile >= 0.90 THEN 1
            ELSE 0
        END AS high_value_flag,

        CASE
            WHEN previous_amount IS NOT NULL
             AND Amount > previous_amount * 2
            THEN 1
            ELSE 0
        END AS spike_flag

    FROM transaction_history
)

SELECT
    TransactionID,
    AccountOriginID,
    AccountDestinationID,
    TransactionDate,
    Amount,
    previous_amount,

    CASE
        WHEN high_value_flag = 1
         AND spike_flag = 1
            THEN 'Critical'

        WHEN high_value_flag = 1
          OR spike_flag = 1
            THEN 'High'

        ELSE 'Low'
    END AS risk_level,

    CASE
        WHEN high_value_flag = 1
         AND spike_flag = 1
            THEN 'High-value transaction + unusual spending spike'

        WHEN high_value_flag = 1
            THEN 'High-value transaction'

        WHEN spike_flag = 1
            THEN 'Unusual spending spike'

        ELSE 'Normal'
    END AS suspicious_reason

FROM risk_analysis
WHERE high_value_flag = 1
   OR spike_flag = 1

ORDER BY
    CASE
        WHEN high_value_flag = 1
         AND spike_flag = 1 THEN 1

        WHEN high_value_flag = 1
          OR spike_flag = 1 THEN 2

        ELSE 3
    END,
    Amount DESC;


-- Q5: Loan Risk / Overdue Loans

-- 5A. Overdue loan details
SELECT
    LoanID,
    AccountID,
    LoanStatusID,
    PrincipalAmount,
    InterestRate,
    StartDate,
    EstimatedEndDate,

    CASE
        WHEN LoanStatusID = 1 THEN 'Active'
        WHEN LoanStatusID = 2 THEN 'Paid Off'
        WHEN LoanStatusID = 3 THEN 'Overdue'
        ELSE 'Unknown'
    END AS LoanStatus,

    CASE
        WHEN LoanStatusID = 3
            THEN 'High Risk - Overdue'
        ELSE 'Normal'
    END AS LoanRiskLevel

FROM loan_clean

ORDER BY
    CASE
        WHEN LoanStatusID = 3 THEN 1
        ELSE 2
    END,
    PrincipalAmount DESC;


-- 5B. Accounts with highest overdue loan risk
SELECT
    AccountID,
    COUNT(*) AS overdue_loans,
    SUM(PrincipalAmount) AS total_overdue_principal,
    AVG(InterestRate) AS average_interest_rate
FROM loan_clean
WHERE LoanStatusID = 3
GROUP BY AccountID
ORDER BY total_overdue_principal DESC;


-- 5C. Overall overdue loan percentage
SELECT
    COUNT(*) AS total_loans,

    SUM(
        CASE
            WHEN LoanStatusID = 3 THEN 1
            ELSE 0
        END
    ) AS overdue_loans,

    ROUND(
        SUM(
            CASE
                WHEN LoanStatusID = 3 THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS overdue_loan_percentage

FROM loan_clean;