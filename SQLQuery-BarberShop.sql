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



-- 1. Вернуть ФИО всех барберов салона
SELECT full_name
FROM barbers;

-- 2. Вернуть информацию о всех синьор-барберах
SELECT *
FROM barbers
WHERE position = 'синьор-барбер';

-- 3. Вернуть информацию о всех барберах, которые могут предоставить услугу традиционного бритья бороды
SELECT b.*
FROM barbers b
JOIN services s ON b.barber_id = s.barber_id
WHERE s.service_name = 'традиционне бритья бороди';

-- 4. Вернуть информацию о всех барберах, которые могут предоставить конкретную услугу. Информация о требуемой услуге предоставляется в качестве параметра
CREATE PROCEDURE GetBarbersByService (@service_name NVARCHAR(100))
AS
BEGIN
    SELECT b.*
    FROM barbers b
    JOIN services s ON b.barber_id = s.barber_id
    WHERE s.service_name = @service_name;
END;

-- 5. Вернуть информацию о всех барберах, которые работают свыше указанного количества лет. Количество лет передаётся в качестве параметра
CREATE PROCEDURE GetBarbersByExperience (@years INT)
AS
BEGIN
    SELECT *
    FROM barbers
    WHERE DATEDIFF(year, hire_date, GETDATE()) > @years;
END;

-- 6. Вернуть количество синьор-барберов и количество джуниор-барберов
SELECT position, COUNT(*)
FROM barbers
GROUP BY position;

-- 7. Вернуть информацию о постоянных клиентах. Критерий постоянного клиента: был в салоне заданное количество раз. Количество передаётся в качестве параметра
CREATE PROCEDURE GetRegularClients (@visit_count INT)
AS
BEGIN
    SELECT v.client_id, c.full_name, COUNT(*) as visits_count
    FROM visits v
    JOIN clients c ON v.client_id = c.client_id
    GROUP BY v.client_id, c.full_name
    HAVING COUNT(*) >= @visit_count;
END;

--  8. Запретить возможность удаления информации о чиф-барбере, если не добавлен второй чиф-барбер
CREATE TRIGGER PreventChiefBarberDeletion
ON barbers
INSTEAD OF DELETE
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM barbers WHERE position = 'чиф-барбер' AND barber_id IN (SELECT deleted.barber_id FROM deleted))
    BEGIN
        RAISERROR ('Неможливо видалити інформацію про чиф-барбера без наявності другого чиф-барбера.', 16, 1);
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        DELETE FROM barbers WHERE barber_id IN (SELECT deleted.barber_id FROM deleted);
    END
END;

-- 9. Запретить добавлять барберов младше 21 года.
CREATE TRIGGER PreventUnderageBarberInsertion
ON barbers
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE DATEDIFF(year, inserted.date_of_birth, GETDATE()) < 21)
    BEGIN
        RAISERROR ('Неможливо додати барбера молодше 21 року.', 16, 1);
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        INSERT INTO barbers (full_name, gender, phone_number, email, date_of_birth, hire_date, position, feedback, rating)
        SELECT full_name, gender, phone_number, email, date_of_birth, hire_date, position, feedback, rating
        FROM inserted;
    END
END;
