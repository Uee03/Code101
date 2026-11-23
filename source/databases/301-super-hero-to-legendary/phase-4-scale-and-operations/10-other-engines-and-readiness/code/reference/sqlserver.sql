-- Reference only (T-SQL for SQL Server 2022 or later). NOT run by this lesson.
-- The same tasks as lesson.sql; compare each statement with its PostgreSQL form.
-- GO is a batch separator understood by sqlcmd and SQL Server Management Studio, not a T-SQL statement.
CREATE SCHEMA app;
GO
CREATE TABLE app.customers (
    customer_id bigint IDENTITY(1,1) NOT NULL,
    email nvarchar(320) NOT NULL,
    CONSTRAINT pk_customers PRIMARY KEY (customer_id)
);
GO
CREATE TABLE app.orders (
    order_id bigint IDENTITY(1,1) NOT NULL,
    customer_id bigint NOT NULL,
    total decimal(12,2) NOT NULL,
    created_at datetime2 NOT NULL CONSTRAINT df_orders_created DEFAULT SYSUTCDATETIME(),
    CONSTRAINT pk_orders PRIMARY KEY (order_id),
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES app.customers (customer_id)
);
GO
SELECT 'abc' + 'def' AS concat_plus, CONCAT('abc', 'def') AS concat_function;
SELECT CASE WHEN 'abc' = 'ABC' THEN 1 ELSE 0 END AS equals_with_a_case_insensitive_collation;
SELECT n FROM (VALUES (1), (2), (3), (4), (5)) AS t(n) ORDER BY n OFFSET 1 ROWS FETCH NEXT 2 ROWS ONLY;
SELECT TOP (2) n FROM (VALUES (1), (2), (3), (4), (5)) AS t(n) ORDER BY n;
GO
CREATE OR ALTER PROCEDURE app.place_order
    @customer_id bigint,
    @total decimal(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO app.orders (customer_id, total)
        OUTPUT inserted.order_id
        VALUES (@customer_id, @total);
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
EXEC app.place_order @customer_id = 1, @total = 12.50;
