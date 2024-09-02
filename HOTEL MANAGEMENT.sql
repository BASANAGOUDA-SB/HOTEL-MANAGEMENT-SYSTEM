-- Step 1: Show existing databases and create a new one
SHOW DATABASES;
CREATE DATABASE HOTEL_MANAGEMENT;
USE HOTEL_MANAGEMENT;
SHOW TABLES;

-- Step 2: Create the Guests table
CREATE TABLE Guests (
    guest_id INT PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(30),
    phone_number VARCHAR(15),
    address VARCHAR(200),
    city VARCHAR(100)
);

-- Step 3: Create the Bookings table
CREATE TABLE Bookings (
    booking_id INT PRIMARY KEY,
    guest_id INT,
    room_number INT,
    check_in_date DATE,
    check_out_date DATE,
    amount DECIMAL(10, 2),
    FOREIGN KEY (guest_id) REFERENCES Guests(guest_id)
);

-- Step 4: Insert data into the Guests table
INSERT INTO Guests (guest_id, first_name, last_name, email, phone_number, address, city) VALUES
(1, 'Ravi', 'Kumar', 'ravi.kumar@example.com', '9876543210', '123 MG Road', 'Bangalore'),
(2, 'Sita', 'Sharma', 'sita.sharma@example.com', '8765432109', '456 Park Street', 'Kolkata'),
(3, 'Anil', 'Mehta', 'anil.mehta@example.com', '7654321098', '789 Nehru Place', 'Delhi'),
(4, 'Pooja', 'Singh', 'pooja.singh@example.com', '6543210987', '101 Marine Drive', 'Mumbai'),
(5, 'Rahul', 'Patel', 'rahul.patel@example.com', '5432109876', '202 Ring Road', 'Ahmedabad'),
(6, 'Priya', 'Nair', 'priya.nair@example.com', '4321098765', '303 MG Road', 'Bangalore'),
(7, 'Vikas', 'Reddy', 'vikas.reddy@example.com', '3210987654', '404 Jubilee Hills', 'Mumbai'),
(8, 'Amit', 'Verma', 'amit.verma@example.com', '2109876543', '505 Civil Lines', 'Lucknow'),
(9, 'Kavita', 'Joshi', 'kavita.joshi@example.com', '1098765432', '606 Mall Road', 'Mumbai'),
(10, 'Sunil', 'Chopra', 'sunil.chopra@example.com', '1987654321', '707 Residency Road', 'Mumbai');

-- Step 5: Customer who made the most bookings
WITH GuestBookings AS (
    SELECT
        Guests.guest_id,
        CONCAT(Guests.first_name, ' ', Guests.last_name) AS full_name,
        COUNT(Bookings.booking_id) AS booking_count
    FROM
        Guests
    JOIN
        Bookings ON Guests.guest_id = Bookings.guest_id
    GROUP BY
        Guests.guest_id, Guests.first_name, Guests.last_name
),
RankedGuests AS (
    SELECT
        guest_id,
        full_name,
        booking_count,
        ROW_NUMBER() OVER (ORDER BY booking_count DESC) AS rank
    FROM
        GuestBookings
)
SELECT
    guest_id,
    full_name,
    booking_count
FROM
    RankedGuests
WHERE
    rank = 1;

-- Step 6: List the guests who have bookings from 25-June to July 1
SELECT DISTINCT B.guest_id,
    CONCAT(first_name, ' ', last_name) AS guest_name
FROM Guests G
INNER JOIN Bookings B ON G.guest_id = B.guest_id
WHERE check_in_date BETWEEN '2024-05-25' AND '2024-06-01';

-- Step 7: Find the total revenue generated from all bookings
ALTER TABLE Bookings RENAME COLUMN check_out_dtae TO check_out_date;

SELECT
    SUM(
        CASE 
            WHEN DATEDIFF(check_out_date, check_in_date) = 0 THEN 1
            ELSE DATEDIFF(check_out_date, check_in_date)
        END * amount
    ) AS total_revenue
FROM
    Bookings;

-- Step 8: Find the average stay duration of guests
WITH Stay AS (
    SELECT
        CASE
            WHEN DATEDIFF(check_out_date, check_in_date) = 0 THEN 1
            ELSE DATEDIFF(check_out_date, check_in_date)
        END AS stay_duration
    FROM
        Bookings
)
SELECT
    FORMAT(AVG(stay_duration * 1.0), 2) AS average_stay_duration
FROM
    Stay;

-- Step 9: Find guests who booked the same room multiple times
SELECT
    CONCAT(g.first_name, ' ', g.last_name) AS full_name,
    b.guest_id,
    b.room_number,
    COUNT(*) AS booking_count
FROM 
    Bookings b
INNER JOIN 
    Guests g ON b.guest_id = g.guest_id
GROUP BY
    g.first_name, g.last_name, b.guest_id, b.room_number
HAVING 
    COUNT(*) > 1;

-- Step 10: List out top 3 guests and amount of time spent
SELECT
    G.guest_id,
    CONCAT(G.first_name, ' ', G.last_name) AS full_name,
    SUM(
        CASE
            WHEN DATEDIFF(b.check_out_date, b.check_in_date) = 0 THEN 1
            ELSE DATEDIFF(b.check_out_date, b.check_in_date)
        END * b.amount
    ) AS total_amount_spent
FROM 
    Guests G
INNER JOIN 
    Bookings b ON G.guest_id = b.guest_id
GROUP BY 
    G.guest_id, G.first_name, G.last_name
ORDER BY 
    total_amount_spent DESC
LIMIT 3;

-- Step 11: Find the average total amount spent by guests who stayed more than 3 days
WITH LongStays AS (
    SELECT
        guest_id,
        CASE
            WHEN DATEDIFF(check_out_date, check_in_date) = 0 THEN 1
            ELSE DATEDIFF(check_out_date, check_in_date)
        END AS stay_duration,
        amount
    FROM
        Bookings
)
SELECT
    AVG(stay_duration * amount) AS total_amount_spent
FROM
    LongStays
WHERE
    stay_duration > 3;

-- Step 12: List all guests along with their total stay duration and amount across all bookings
WITH LongStays AS (
    SELECT
        a.guest_id,
        CONCAT(b.first_name, ' ', b.last_name) AS full_name,
        CASE
            WHEN DATEDIFF(a.check_out_date, a.check_in_date) = 0 THEN 1
            ELSE DATEDIFF(a.check_out_date, a.check_in_date)
        END AS stay_duration,
        a.amount
    FROM
        Bookings a
    INNER JOIN 
        Guests b ON a.guest_id = b.guest_id
)
SELECT
    guest_id,
    full_name,
    SUM(stay_duration) AS total_stay_days,
    SUM(stay_duration * amount) AS total_amount_spent
FROM
    LongStays
GROUP BY
    guest_id, full_name
ORDER BY
    guest_id;

-- Step 13: Find the city from where the most guests have stayed
SELECT 
    G.city,
    COUNT(G.guest_id) AS guest_count
FROM  
    Guests G
INNER JOIN 
    Bookings B ON G.guest_id = B.guest_id
GROUP BY 
    G.city
ORDER BY 
    guest_count DESC
LIMIT 1;
