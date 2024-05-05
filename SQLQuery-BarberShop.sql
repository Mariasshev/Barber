use [master];
go

if db_id('Barber') is not null
begin
	drop database [Barber];
end
go

create database [Barber];
go

use [Barber];
go

CREATE TABLE barbers (
    barber_id INT PRIMARY KEY,
    full_name NVARCHAR(100),
    gender NVARCHAR(10),
    phone_number NVARCHAR(20),
    email NVARCHAR(100),
    date_of_birth DATE,
    hire_date DATE,
    position NVARCHAR(50),
    feedback NVARCHAR(MAX),
    rating NVARCHAR(20)
);

CREATE TABLE services (
    service_id INT PRIMARY KEY,
    barber_id INT,
    service_name NVARCHAR(100),
    price FLOAT,
    duration INT,
    FOREIGN KEY (barber_id) REFERENCES barbers(barber_id)
);

CREATE TABLE schedules (
    schedule_id INT PRIMARY KEY,
    barber_id INT,
    availability_date DATE,
    availability_time TIME,
    client_id INT,
    FOREIGN KEY (barber_id) REFERENCES barbers(barber_id),
    FOREIGN KEY (client_id) REFERENCES clients(client_id)
);

CREATE TABLE clients (
    client_id INT PRIMARY KEY,
    full_name NVARCHAR(100),
    phone_number NVARCHAR(20),
    email NVARCHAR(100),
    feedback NVARCHAR(MAX),
    rating NVARCHAR(20)
);

CREATE TABLE visits (
    visit_id INT PRIMARY KEY,
    client_id INT,
    barber_id INT,
    service_id INT,
    visit_date DATE,
    total_cost FLOAT,
    feedback NVARCHAR(MAX),
    rating NVARCHAR(20),
    FOREIGN KEY (client_id) REFERENCES clients(client_id),
    FOREIGN KEY (barber_id) REFERENCES barbers(barber_id),
    FOREIGN KEY (service_id) REFERENCES services(service_id)
);



-- 1. ������� ��� ���� �������� ������
SELECT full_name
FROM barbers;

-- 2. ������� ���������� � ���� ������-��������
SELECT *
FROM barbers
WHERE position = '������-������';

-- 3. ������� ���������� � ���� ��������, ������� ����� ������������ ������ ������������� ������ ������
SELECT b.*
FROM barbers b
JOIN services s ON b.barber_id = s.barber_id
WHERE s.service_name = '����������� ������ ������';

-- 4. ������� ���������� � ���� ��������, ������� ����� ������������ ���������� ������. ���������� � ��������� ������ ��������������� � �������� ���������
CREATE PROCEDURE GetBarbersByService (@service_name NVARCHAR(100))
AS
BEGIN
    SELECT b.*
    FROM barbers b
    JOIN services s ON b.barber_id = s.barber_id
    WHERE s.service_name = @service_name;
END;

-- 5. ������� ���������� � ���� ��������, ������� �������� ����� ���������� ���������� ���. ���������� ��� ��������� � �������� ���������
CREATE PROCEDURE GetBarbersByExperience (@years INT)
AS
BEGIN
    SELECT *
    FROM barbers
    WHERE DATEDIFF(year, hire_date, GETDATE()) > @years;
END;

-- 6. ������� ���������� ������-�������� � ���������� �������-��������
SELECT position, COUNT(*)
FROM barbers
GROUP BY position;

-- 7. ������� ���������� � ���������� ��������. �������� ����������� �������: ��� � ������ �������� ���������� ���. ���������� ��������� � �������� ���������
CREATE PROCEDURE GetRegularClients (@visit_count INT)
AS
BEGIN
    SELECT v.client_id, c.full_name, COUNT(*) as visits_count
    FROM visits v
    JOIN clients c ON v.client_id = c.client_id
    GROUP BY v.client_id, c.full_name
    HAVING COUNT(*) >= @visit_count;
END;

--  8. ��������� ����������� �������� ���������� � ���-�������, ���� �� �������� ������ ���-������
CREATE TRIGGER PreventChiefBarberDeletion
ON barbers
INSTEAD OF DELETE
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM barbers WHERE position = '���-������' AND barber_id IN (SELECT deleted.barber_id FROM deleted))
    BEGIN
        RAISERROR ('��������� �������� ���������� ��� ���-������� ��� �������� ������� ���-�������.', 16, 1);
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        DELETE FROM barbers WHERE barber_id IN (SELECT deleted.barber_id FROM deleted);
    END
END;

-- 9. ��������� ��������� �������� ������ 21 ����.
CREATE TRIGGER PreventUnderageBarberInsertion
ON barbers
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE DATEDIFF(year, inserted.date_of_birth, GETDATE()) < 21)
    BEGIN
        RAISERROR ('��������� ������ ������� ������� 21 ����.', 16, 1);
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        INSERT INTO barbers (full_name, gender, phone_number, email, date_of_birth, hire_date, position, feedback, rating)
        SELECT full_name, gender, phone_number, email, date_of_birth, hire_date, position, feedback, rating
        FROM inserted;
    END
END;
