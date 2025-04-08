---------------------International Bank Database Management----------------------------------------------------------------------------------
--1. Display the count of customers in each region who have done the transaction in the year 2020.
SELECT c.region_id, COUNT(c.customer_id) AS customer_count
FROM bank_customer.customers c
JOIN transaction t ON c.customer_id = t.customer_id
WHERE YEAR(t.txn_date) = 2020
GROUP BY c.region_id;

--2. Display the maximum and minimum transaction amount of each transaction type.
SELECT txn_type, MAX(txn_amount) AS max_amount, MIN(txn_amount) AS min_amount
FROM transaction
GROUP BY txn_type;

--3. Display the customer id, region name and transaction amount where transaction type is deposit and transaction amount > 2000.
SELECT c.customer_id, co.region_name, t.txn_amount
FROM bank_customer.transaction t
JOIN customers c ON t.customer_id = c.customer_id
JOIN continent co ON c.region_id = co.region_id
WHERE t.txn_type = 'deposit' AND t.txn_amount > 2000;

--4. Find duplicate records in the Customer table.
SELECT customer_id, COUNT(*) AS count
FROM bank_customer.customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

--5. Display the customer id, region name, transaction type and transaction amount for the minimum transaction amount in deposit.
SELECT T.customer_id, C.region_name, T.txn_type, T.txn_amount
FROM Transaction T
JOIN Customers CU ON T.customer_id = CU.customer_id
JOIN Continent C ON CU.region_id = C.region_id
WHERE T.txn_type = 'deposit' AND T.txn_amount = 
(SELECT MIN(txn_amount) FROM Transaction WHERE txn_type = 'deposit');

--6. Create a stored procedure to display details of customers in the Transaction table where the transaction 
--   date is greater than Jun 2020.
DELIMITER //

CREATE PROCEDURE DISPLAY()
BEGIN
    SELECT * FROM Transaction WHERE txn_date > '2020-06-30';
END //

DELIMITER ;
CALL DISPLAY();

--7. Create a stored procedure to insert a record in the Continent table.
DELIMITER //

CREATE PROCEDURE INSERT_Continent(IN region_id INT, IN region_name VARCHAR(20))
BEGIN
    INSERT INTO Continent (region_id, region_name) VALUES (region_id, region_name);
END //

DELIMITER ;
CALL INSERT_Continent(1, 'North America');

--8. Create a stored procedure to display the details of transactions that happened on a specific day.
DELIMITER //

CREATE PROCEDURE DISPLAY_T(IN DAY DATE)
BEGIN
    SELECT * FROM Transaction WHERE txn_date = DAY;
END //

DELIMITER ;
CALL DISPLAY_T('2020-01-25');

--9. Create a user defined function to add 10% of the transaction amount in a table.
DELIMITER //

CREATE FUNCTION ADD_10_PERCENT(AMOUNT DECIMAL(10,2))
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    RETURN AMOUNT * 1.10;
END //

DELIMITER ;
SELECT ADD_10_PERCENT(100.00) AS NewAmount;

--10. Create a user defined function to find the total transaction amount for a given transaction type.
DELIMITER //

CREATE FUNCTION TOTAL_TXN_AMT(txn_type VARCHAR(50))
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE TOTAL_AMT DECIMAL(10,2);
    SELECT SUM(txn_amount) INTO TOTAL_AMT FROM Transaction WHERE txn_type = txn_type;
    RETURN TOTAL_AMT;
END //

DELIMITER ;
SELECT TOTAL_TXN_AMT('deposit') AS TotalDepositAmount;

--11. Create a table value function which comprises the columns customer_id, region_id ,txn_date , txn_type , 
--    txn_amount which will retrieve data from the above table.
CREATE TABLE Transactions (
    customer_id INT,
    txn_date DATE,
    txn_type VARCHAR(50),
    txn_amount DECIMAL(10,2)
);
CALL RETRIEVE_DATA();

--12. Create a TRY...CATCH block to print a region id and region name in a single column.
DELIMITER //

CREATE PROCEDURE PRINT_REGION_DATA()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'Error fetching region data' AS ErrorMessage;
    END;

    SELECT CONCAT(region_id, ' ', region_name) AS RegionInfo FROM Continent;
END //

DELIMITER ;
CALL PRINT_REGION_DATA();

--13. Create a TRY...CATCH block to insert a value in the Continent table.
DELIMITER //

CREATE PROCEDURE INSERT_CONTINENT(IN p_region_id INT, IN p_region_name VARCHAR(50))
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'Error inserting data into Continent' AS ErrorMessage;
    END;

    INSERT INTO Continent (region_id, region_name) VALUES (p_region_id, p_region_name);
END //

DELIMITER ;
CALL INSERT_CONTINENT(5, 'Australia');

--14. Create a trigger to prevent deleting a table in a database.

CREATE TRIGGER PREVENT_TABLE_DELETE
ON DATABASE
FOR DROP_TABLE
AS
BEGIN
ROLLBACK;
PRINT 'Deletion of tables is not allowed!'
END; 

--15. Create a trigger to audit the data in a table.
DELIMITER //

CREATE TRIGGER trg_audit_transaction
AFTER INSERT ON Transactions
FOR EACH ROW
BEGIN
    INSERT INTO AuditTable (customer_id, txn_date, txn_type, txn_amount, operation)
    VALUES (NEW.customer_id, NEW.txn_date, NEW.txn_type, NEW.txn_amount, 'INSERT');
END //

DELIMITER ;

DELIMITER //

CREATE TRIGGER trg_audit_transaction_update
AFTER UPDATE ON Transactions
FOR EACH ROW
BEGIN
    INSERT INTO AuditTable (customer_id, txn_date, txn_type, txn_amount, operation)
    VALUES (NEW.customer_id, NEW.txn_date, NEW.txn_type, NEW.txn_amount, 'UPDATE');
END //

DELIMITER ;

DELIMITER //

CREATE TRIGGER trg_audit_transaction_delete
AFTER DELETE ON Transactions
FOR EACH ROW
BEGIN
    INSERT INTO AuditTable (customer_id, txn_date, txn_type, txn_amount, operation)
    VALUES (OLD.customer_id, OLD.txn_date, OLD.txn_type, OLD.txn_amount, 'DELETE');
END //

DELIMITER ;

--16. Display top n customers on the basis of transaction type.
SELECT customer_id, SUM(txn_amount) AS total_amount
FROM bank_customer.Transaction
WHERE txn_type = 'deposit'
GROUP BY customer_id
ORDER BY total_amount DESC
LIMIT 5;

--17. Create a pivot table to display the total purchase, withdrawal and
--deposit for all the customers.

SELECT customer_id,
SUM(CASE WHEN txn_type = 'purchase' THEN txn_amount ELSE 0 END) AS total_purchase,
SUM(CASE WHEN txn_type = 'withdrawal' THEN txn_amount ELSE 0 END) AS total_withdrawal,
SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE 0 END) AS total_deposit
FROM Transaction
GROUP BY customer_id;
