CREATE DATABASE Service
USE Service


--Section 1. DDL (30 pts)
CREATE TABLE Users
(
	Id INT PRIMARY KEY IDENTITY,
	Username VARCHAR(30) UNIQUE NOT NULL,
	Password VARCHAR(50) NOT NULL,
	Name VARCHAR(50),
	Birthdate DATETIME,
	Age INT CHECK(Age BETWEEN 14 AND 110),
	Email VARCHAR(50) NOT NULL
)

CREATE TABLE Departments
(
	Id INT PRIMARY KEY IDENTITY,
	Name VARCHAR(50) NOT NULL
)

CREATE TABLE Employees
(
	Id INT PRIMARY KEY IDENTITY,
	FirstName VARCHAR(25),
	LastName VARCHAR(25),
	Birthdate DATETIME,
	Age INT CHECK(Age BETWEEN 18 AND 110),
	DepartmentId INT FOREIGN KEY REFERENCES Departments(Id)
)

CREATE TABLE Categories
(
	Id INT PRIMARY KEY IDENTITY,
	Name VARCHAR(50) NOT NULL,
	DepartmentId INT FOREIGN KEY REFERENCES Departments(Id) NOT NULL
)

CREATE TABLE Status
(
	Id INT PRIMARY KEY IDENTITY,
	Label VARCHAR(30) NOT NULL
)

CREATE TABLE Reports
(
	Id INT PRIMARY KEY IDENTITY,
	CategoryId INT FOREIGN KEY REFERENCES Categories(Id) NOT NULL,
	StatusId INT FOREIGN KEY REFERENCES Status(Id) NOT NULL,
	OpenDate DATETIME NOT NULL,
	CloseDate DATETIME,
	Description VARCHAR(200) NOT NULL,
	UserId INT FOREIGN KEY REFERENCES Users(Id) NOT NULL,
	EmployeeId INT FOREIGN KEY REFERENCES Employees(Id)
)


--Section 2. DML (10 pts)
--2. Insert
INSERT INTO Employees (FirstName, LastName, Birthdate, DepartmentId)
VALUES ('Marlo', 'O''Malley', '1958-9-21', 1),
		('Niki', 'Stanaghan', '1969-11-26', 4),
		('Ayrton', 'Senna', '1960-03-21', 9),
		('Ronnie', 'Peterson', '1944-02-14', 9),
		('Giovanna', 'Amati', '1959-07-20', 5)

INSERT INTO Reports (CategoryId, StatusId, OpenDate, CloseDate, Description,UserId, EmployeeId)
VALUES (1, 1, '2017-04-13', NULL, 'Stuck Road on Str.133', 6, 2),
		(6, 3, '2015-09-05', '2015-12-06', 'Charity trail running', 3, 5),
		(14, 2, '2015-09-07', NULL, 'Falling bricks on Str.58', 5, 2),
		(4, 3, '2017-07-03', '2017-07-06', 'Cut off streetlight on Str.11', 1, 1)

--3. Update
UPDATE Reports
SET CloseDate = GETDATE()
WHERE CloseDate IS NULL

--4. Delete
DELETE FROM Reports
WHERE StatusId = 4


--Section 3. Querying (40 pts)
--5. Unassigned Reports
SELECT
	Description,
	 FORMAT(OpenDate, 'dd-MM-yyyy') AS Date
FROM Reports 
WHERE EmployeeId IS NULL
ORDER BY OpenDate,
		 Description




--6. Reports & Categories
SELECT
	R.Description,
	C.Name AS [CategoryName]
FROM Reports AS R
JOIN Categories AS C ON R.CategoryId = C.Id
ORDER BY R.Description,
		 C.Name

--7. Most Reported Category
SELECT TOP(5)
	C.Name AS [CategoryName],
	COUNT(R.Id) AS [ReportsNumber]
FROM Reports AS R
JOIN Categories AS C ON R.CategoryId = C.Id
GROUP BY C.Name
ORDER BY [ReportsNumber] DESC,
		 [CategoryName]

--8. Birthday Report
SELECT 
	U.Username,
	C.Name AS [CategoryName]
FROM Reports AS R
LEFT JOIN Users AS U ON R.UserId = U.Id
LEFT JOIN Categories AS C ON R.CategoryId = C.Id
WHERE DATEPART(DAY, R.OpenDate) = DATEPART(DAY, U.Birthdate)
	  AND DATEPART(MONTH, R.OpenDate) = DATEPART(MONTH, U.Birthdate)
ORDER BY U.Username,
		 [CategoryName]



--9. Users per Employee
SELECT
	CONCAT(E.FirstName, ' ', E.LastName) AS [FullName],
	COUNT(R.UserId) AS [UsersCount]
FROM Reports AS R
JOIN Users AS U ON R.UserId = U.Id
RIGHT JOIN Employees AS E ON R.EmployeeId = E.Id
GROUP BY CONCAT(E.FirstName, ' ', E.LastName)
ORDER BY [UsersCount] DESC,
		 [FullName]

--10. Full Info
SELECT
	IIF(R.EmployeeId IS NULL, 'None',
					CONCAT(E.FirstName, ' ', E.LastName)) AS [Employee],
	IIF(R.EmployeeId IS NULL, 'None', D.Name) AS [Department],
	C.Name AS [Category],
	R.Description,
	FORMAT(R.OpenDate, 'dd.MM.yyyy') AS [OpenDate],
	S.Label AS [Status],
	IIF(U.Name IS NULL, 'None', U.Name)AS [User]
FROM Reports AS R
LEFT JOIN Employees AS E ON R.EmployeeId = E.Id
LEFT JOIN Departments AS D ON E.DepartmentId = D.Id
JOIN Categories AS C ON R.CategoryId = C.Id
JOIN Status AS S ON R.StatusId = S.Id
JOIN Users AS U ON R.UserId = U.Id
ORDER BY E.FirstName DESC,
		 E.LastName DESC,
		 [Department],
		 [Category],
		 R.Description,
		 [OpenDate],
		 [Status],
		 [User]



--Section 4. Programmability (20 pts)
--11. Hours to Complete
GO
CREATE FUNCTION udf_HoursToComplete(@StartDate DATETIME, @EndDate DATETIME)
RETURNS INT
AS
BEGIN
	
	IF (@StartDate IS NULL OR @EndDate IS NULL)
	BEGIN
		RETURN 0
	END

	RETURN DATEDIFF(HOUR, @StartDate, @EndDate)
END

SELECT dbo.udf_HoursToComplete(OpenDate, CloseDate) AS TotalHours
   FROM Reports



--12. Assign Employee
GO
CREATE PROCEDURE usp_AssignEmployeeToReport(@EmployeeId INT, @ReportId INT)
AS
DECLARE @getEmployeeDepartment INT = (SELECT DepartmentId FROM Employees WHERE Id = @EmployeeId)
DECLARE @getReportsDepartment INT = (SELECT
										C.DepartmentId
									 FROM Reports AS R
									 JOIN Categories AS C ON R.CategoryId = C.Id
									 WHERE R.Id = @ReportId)

IF (@getEmployeeDepartment <> @getReportsDepartment)
BEGIN
	;THROW 51000, 'Employee doesn''t belong to the appropriate department!', 1
END

UPDATE Reports
SET EmployeeId = @EmployeeId
WHERE Id = @ReportId