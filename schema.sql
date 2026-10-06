CREATE DATABASE BloodDonorSystem;

USE BloodDonorSystem;
GO

/* =========================================================
   1. DONORS
   ========================================================= */

CREATE TABLE Donors (
    DonorID INT IDENTITY(1,1) PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    Gender VARCHAR(10) NOT NULL,
    BloodGroup VARCHAR(5) NOT NULL,
    Phone VARCHAR(15) NOT NULL,
    Email VARCHAR(100),
    City VARCHAR(100) NOT NULL,
    Latitude DECIMAL(10,7),
    Longitude DECIMAL(10,7),
    LastDonationDate DATE,

    CONSTRAINT CK_Donors_Gender
        CHECK (Gender IN ('Male', 'Female')),

    CONSTRAINT CK_Donors_BloodGroup
        CHECK (BloodGroup IN
        ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'))
);
GO


/* =========================================================
   2. HOSPITALS
   ========================================================= */

CREATE TABLE Hospitals (
    HospitalID INT IDENTITY(1,1) PRIMARY KEY,
    HospitalName VARCHAR(150) NOT NULL,
    ContactPerson VARCHAR(100) NOT NULL,
    Phone VARCHAR(15) NOT NULL,
    Email VARCHAR(100),
    City VARCHAR(100) NOT NULL,
    Address VARCHAR(250),
    Latitude DECIMAL(10,7),
    Longitude DECIMAL(10,7)
);
GO


/* =========================================================
   3. BLOOD BANKS
   ========================================================= */

CREATE TABLE BloodBanks (
    BloodBankID INT IDENTITY(1,1) PRIMARY KEY,
    BloodBankName VARCHAR(150) NOT NULL,
    Phone VARCHAR(15),
    Email VARCHAR(100),
    City VARCHAR(100) NOT NULL,
    Address VARCHAR(250),
    Latitude DECIMAL(10,7),
    Longitude DECIMAL(10,7)
);
GO


/* =========================================================
   4. DONATIONS
   ========================================================= */

CREATE TABLE Donations (
    DonationID INT IDENTITY(1,1) PRIMARY KEY,
    DonorID INT NOT NULL,
    DonationDate DATE NOT NULL,
    BloodGroup VARCHAR(5) NOT NULL,
    BloodBankID INT,
    Status VARCHAR(20) NOT NULL DEFAULT 'Completed',

    CONSTRAINT FK_Donations_Donors
        FOREIGN KEY (DonorID)
        REFERENCES Donors(DonorID),

    CONSTRAINT FK_Donations_BloodBanks
        FOREIGN KEY (BloodBankID)
        REFERENCES BloodBanks(BloodBankID),

    CONSTRAINT CK_Donations_BloodGroup
        CHECK (BloodGroup IN
        ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),

    CONSTRAINT CK_Donations_Status
        CHECK (Status IN ('Completed', 'Cancelled'))
);
GO


/* =========================================================
   5. BLOOD REQUESTS
   ========================================================= */

CREATE TABLE BloodRequests (
    RequestID INT IDENTITY(1,1) PRIMARY KEY,
    HospitalID INT NOT NULL,
    BloodGroup VARCHAR(5) NOT NULL,
    UnitsRequired INT NOT NULL,
    Urgency VARCHAR(20) NOT NULL,
    RequiredDate DATE NOT NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'Open',
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_BloodRequests_Hospitals
        FOREIGN KEY (HospitalID)
        REFERENCES Hospitals(HospitalID),

    CONSTRAINT CK_BloodRequests_BloodGroup
        CHECK (BloodGroup IN
        ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),

    CONSTRAINT CK_BloodRequests_Units
        CHECK (UnitsRequired > 0),

    CONSTRAINT CK_BloodRequests_Urgency
        CHECK (Urgency IN ('Critical', 'High', 'Normal')),

    CONSTRAINT CK_BloodRequests_Status
        CHECK (Status IN ('Open', 'Fulfilled', 'Cancelled'))
);
GO


/* =========================================================
   6. DONOR MATCHES
   ========================================================= */

CREATE TABLE DonorMatches (
    MatchID INT IDENTITY(1,1) PRIMARY KEY,
    RequestID INT NOT NULL,
    DonorID INT NOT NULL,
    DistanceKM DECIMAL(10,2),
    MatchScore DECIMAL(10,2),
    MatchStatus VARCHAR(20) NOT NULL DEFAULT 'Matched',
    MatchedAt DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_DonorMatches_Requests
        FOREIGN KEY (RequestID)
        REFERENCES BloodRequests(RequestID),

    CONSTRAINT FK_DonorMatches_Donors
        FOREIGN KEY (DonorID)
        REFERENCES Donors(DonorID),

    CONSTRAINT CK_DonorMatches_Status
        CHECK (MatchStatus IN
        ('Matched', 'Accepted', 'Rejected', 'Completed'))
);
GO


/* =========================================================
   7. NOTIFICATIONS
   ========================================================= */

CREATE TABLE Notifications (
    NotificationID INT IDENTITY(1,1) PRIMARY KEY,
    MatchID INT NOT NULL,
    DonorID INT NOT NULL,
    Message VARCHAR(500) NOT NULL,
    NotificationType VARCHAR(20) NOT NULL,
    SentAt DATETIME NOT NULL DEFAULT GETDATE(),
    DeliveryStatus VARCHAR(20) NOT NULL DEFAULT 'Sent',

    CONSTRAINT FK_Notifications_Matches
        FOREIGN KEY (MatchID)
        REFERENCES DonorMatches(MatchID),

    CONSTRAINT FK_Notifications_Donors
        FOREIGN KEY (DonorID)
        REFERENCES Donors(DonorID),

    CONSTRAINT CK_Notifications_Type
        CHECK (NotificationType IN ('SMS', 'Email')),

    CONSTRAINT CK_Notifications_Status
        CHECK (DeliveryStatus IN ('Sent', 'Failed'))
);
GO


USE BloodDonorSystem;
GO

/* ============================================================
   DONORS - 50 RECORDS
   ============================================================ */

INSERT INTO Donors
(FullName, Gender, BloodGroup, Phone, Email, City,
 Latitude, Longitude, LastDonationDate)
VALUES

('Rahul Patil','Male','O+','9000000001','rahul.patil@gmail.com',
 'Pune',18.5204,73.8567,'2026-01-01'),

('Priya Sharma','Female','A+','9000000002','priya.sharma@gmail.com',
 'Pune',18.5314,73.8446,'2026-04-20'),

('Amit Joshi','Male','B+','9000000003','amit.joshi@gmail.com',
 'Pune',18.5074,73.8077,'2025-12-01'),

('Sneha Patil','Female','O-','9000000004','sneha.patil@gmail.com',
 'Pune',18.5590,73.7868,'2026-01-10'),

('Rohit Kulkarni','Male','AB+','9000000005','rohit.k@gmail.com',
 'Pune',18.5362,73.8958,'2025-11-15'),

('Neha Deshmukh','Female','B-','9000000006','neha.d@gmail.com',
 'Pune',18.4890,73.8280,'2026-01-05'),

('Akash More','Male','O+','9000000007','akash.more@gmail.com',
 'Pune',18.5308,73.8470,'2025-12-10'),

('Pooja Jadhav','Female','A-','9000000008','pooja.j@gmail.com',
 'Pune',18.5167,73.8560,'2026-01-15'),

('Vikas Shinde','Male','O-','9000000009','vikas.s@gmail.com',
 'Pune',18.5450,73.9000,'2025-11-20'),

('Anjali Pawar','Female','AB-','9000000010','anjali.p@gmail.com',
 'Pune',18.5010,73.8500,'2026-01-20'),

('Sagar Chavan','Male','O+','9000000011','sagar.c@gmail.com',
 'Pune',18.5350,73.8600,'2025-10-15'),

('Kavita More','Female','A+','9000000012','kavita.m@gmail.com',
 'Pune',18.5100,73.8400,'2026-02-01'),

('Nikhil Pawar','Male','B+','9000000013','nikhil.p@gmail.com',
 'Pune',18.5000,73.8200,'2025-12-20'),

('Riya Desai','Female','O+','9000000014','riya.d@gmail.com',
 'Pune',18.5250,73.8500,'2026-01-25'),

('Karan Yadav','Male','A-','9000000015','karan.y@gmail.com',
 'Pune',18.5450,73.8300,'2025-11-10'),

('Meera Kulkarni','Female','B+','9000000016','meera.k@gmail.com',
 'Pune',18.5150,73.8100,'2026-02-10'),

('Aditya Patil','Male','O-','9000000017','aditya.p@gmail.com',
 'Pune',18.5350,73.8750,'2025-10-01'),

('Shreya Joshi','Female','AB+','9000000018','shreya.j@gmail.com',
 'Pune',18.4950,73.8400,'2026-02-15'),

('Vivek More','Male','O+','9000000019','vivek.m@gmail.com',
 'Pune',18.5500,73.8700,'2025-12-01'),

('Isha Shah','Female','A+','9000000020','isha.s@gmail.com',
 'Pune',18.5200,73.8100,'2026-01-10'),

('Manish Patil','Male','B-','9000000021','manish.p@gmail.com',
 'Pune',18.5050,73.8500,'2025-11-01'),

('Komal Jadhav','Female','O-','9000000022','komal.j@gmail.com',
 'Pune',18.5300,73.8200,'2026-01-05'),

('Tejas Kulkarni','Male','AB+','9000000023','tejas.k@gmail.com',
 'Pune',18.5450,73.8550,'2025-10-20'),

('Snehal More','Female','B+','9000000024','snehal.m@gmail.com',
 'Pune',18.5100,73.8700,'2026-02-20'),

('Pratik Shinde','Male','O+','9000000025','pratik.s@gmail.com',
 'Pune',18.5250,73.8800,'2025-12-15'),

('Aarti Patil','Female','A-','9000000026','aarti.p@gmail.com',
 'Pune',18.5400,73.8200,'2026-01-01'),

('Swapnil Joshi','Male','B+','9000000027','swapnil.j@gmail.com',
 'Pune',18.4900,73.8100,'2025-11-15'),

('Madhuri Deshmukh','Female','O+','9000000028','madhuri.d@gmail.com',
 'Pune',18.5150,73.8500,'2026-01-20'),

('Harshad Patil','Male','O-','9000000029','harshad.p@gmail.com',
 'Pune',18.5350,73.8100,'2025-10-10'),

('Nandini Shah','Female','AB-','9000000030','nandini.s@gmail.com',
 'Pune',18.5250,73.8300,'2026-02-01'),

('Ramesh Pawar','Male','A+','9000000031','ramesh.p@gmail.com',
 'Pune',18.5500,73.8500,'2025-12-01'),

('Simran Kaur','Female','B-','9000000032','simran.k@gmail.com',
 'Pune',18.5000,73.8600,'2026-01-15'),

('Omkar Jadhav','Male','O+','9000000033','omkar.j@gmail.com',
 'Pune',18.5150,73.8800,'2025-10-01'),

('Tanvi More','Female','A+','9000000034','tanvi.m@gmail.com',
 'Pune',18.5350,73.8400,'2026-02-05'),

('Sachin Patil','Male','B+','9000000035','sachin.p@gmail.com',
 'Pune',18.5050,73.8300,'2025-11-20'),

('Rutuja Joshi','Female','O-','9000000036','rutuja.j@gmail.com',
 'Pune',18.5250,73.8600,'2026-01-10'),

('Yash Desai','Male','AB+','9000000037','yash.d@gmail.com',
 'Pune',18.5400,73.8700,'2025-12-05'),

('Mrunal Patil','Female','B+','9000000038','mrunal.p@gmail.com',
 'Pune',18.5150,73.8300,'2026-02-10'),

('Rohan Shinde','Male','O+','9000000039','rohan.s@gmail.com',
 'Pune',18.5300,73.8600,'2025-10-15'),

('Vaishnavi More','Female','A-','9000000040','vaishnavi.m@gmail.com',
 'Pune',18.5000,73.8400,'2026-01-25'),

('Abhishek Patil','Male','B-','9000000041','abhishek.p@gmail.com',
 'Pune',18.5200,73.8700,'2025-11-10'),

('Sakshi Joshi','Female','O+','9000000042','sakshi.j@gmail.com',
 'Pune',18.5100,73.8500,'2026-02-01'),

('Mahesh Pawar','Male','O-','9000000043','mahesh.p@gmail.com',
 'Pune',18.5450,73.8400,'2025-10-20'),

('Payal Shah','Female','AB+','9000000044','payal.s@gmail.com',
 'Pune',18.5300,73.8300,'2026-01-05'),

('Ganesh Patil','Male','A+','9000000045','ganesh.p@gmail.com',
 'Pune',18.5150,73.8700,'2025-12-15'),

('Radhika More','Female','B+','9000000046','radhika.m@gmail.com',
 'Pune',18.5050,73.8600,'2026-02-15'),

('Deepak Joshi','Male','O+','9000000047','deepak.j@gmail.com',
 'Pune',18.5400,73.8500,'2025-11-05'),

('Amruta Patil','Female','O-','9000000048','amruta.p@gmail.com',
 'Pune',18.5200,73.8400,'2026-01-15'),

('Vishal Shinde','Male','AB-','9000000049','vishal.s@gmail.com',
 'Pune',18.5350,73.8500,'2025-10-10'),

('Pallavi Desai','Female','A+','9000000050','pallavi.d@gmail.com',
 'Pune',18.5000,73.8500,'2026-02-20');
GO


/* ============================================================
   HOSPITALS - 8 RECORDS
   ============================================================ */

INSERT INTO Hospitals
(HospitalName, ContactPerson, Phone, Email, City, Address,
 Latitude, Longitude)
VALUES

('City Care Hospital','Dr. Mehta','9110000001',
 'citycare@gmail.com','Pune','Shivaji Nagar',
 18.5300,73.8500),

('LifeLine Hospital','Dr. Sharma','9110000002',
 'lifeline@gmail.com','Pune','Kothrud',
 18.5074,73.8077),

('Ruby Emergency Hospital','Dr. Joshi','9110000003',
 'ruby@gmail.com','Pune','Sassoon Road',
 18.5200,73.8700),

('Sahyadri Hospital','Dr. Kulkarni','9110000004',
 'sahyadri@gmail.com','Pune','Deccan',
 18.5150,73.8400),

('Noble Hospital','Dr. Patil','9110000005',
 'noble@gmail.com','Pune','Hadapsar',
 18.5080,73.9260),

('Aditya Hospital','Dr. More','9110000006',
 'aditya@gmail.com','Pune','Aundh',
 18.5600,73.8100),

('Medicare Hospital','Dr. Pawar','9110000007',
 'medicare@gmail.com','Pune','Baner',
 18.5590,73.7868),

('Sunrise Hospital','Dr. Shah','9110000008',
 'sunrise@gmail.com','Pune','Viman Nagar',
 18.5679,73.9143);
GO


/* ============================================================
   BLOOD BANKS - 5 RECORDS
   ============================================================ */

INSERT INTO BloodBanks
(BloodBankName, Phone, Email, City, Address,
 Latitude, Longitude)
VALUES

('Pune Central Blood Bank','9210000001',
 'central@gmail.com','Pune','Shivaji Nagar',
 18.5305,73.8470),

('Life Blood Bank','9210000002',
 'life@gmail.com','Pune','Kothrud',
 18.5070,73.8070),

('Red Cross Blood Bank','9210000003',
 'redcross@gmail.com','Pune','Deccan',
 18.5150,73.8400),

('Hope Blood Bank','9210000004',
 'hope@gmail.com','Pune','Hadapsar',
 18.5080,73.9260),

('City Blood Centre','9210000005',
 'cityblood@gmail.com','Pune','Viman Nagar',
 18.5670,73.9140);
GO


/* ============================================================
   DONATION HISTORY - 60 RECORDS
   ============================================================ */

INSERT INTO Donations
(DonorID, DonationDate, BloodGroup, BloodBankID, Status)
VALUES

(1,'2026-01-01','O+',1,'Completed'),
(2,'2026-04-20','A+',1,'Completed'),
(3,'2025-12-01','B+',2,'Completed'),
(4,'2026-01-10','O-',3,'Completed'),
(5,'2025-11-15','AB+',2,'Completed'),
(6,'2026-01-05','B-',1,'Completed'),
(7,'2025-12-10','O+',1,'Completed'),
(8,'2026-01-15','A-',2,'Completed'),
(9,'2025-11-20','O-',3,'Completed'),
(10,'2026-01-20','AB-',3,'Completed'),

(11,'2025-10-15','O+',1,'Completed'),
(12,'2026-02-01','A+',2,'Completed'),
(13,'2025-12-20','B+',2,'Completed'),
(14,'2026-01-25','O+',1,'Completed'),
(15,'2025-11-10','A-',3,'Completed'),
(16,'2026-02-10','B+',2,'Completed'),
(17,'2025-10-01','O-',1,'Completed'),
(18,'2026-02-15','AB+',3,'Completed'),
(19,'2025-12-01','O+',1,'Completed'),
(20,'2026-01-10','A+',2,'Completed'),

(21,'2025-11-01','B-',3,'Completed'),
(22,'2026-01-05','O-',1,'Completed'),
(23,'2025-10-20','AB+',2,'Completed'),
(24,'2026-02-20','B+',3,'Completed'),
(25,'2025-12-15','O+',1,'Completed'),
(26,'2026-01-01','A-',2,'Completed'),
(27,'2025-11-15','B+',3,'Completed'),
(28,'2026-01-20','O+',1,'Completed'),
(29,'2025-10-10','O-',2,'Completed'),
(30,'2026-02-01','AB-',3,'Completed'),

(31,'2025-12-01','A+',1,'Completed'),
(32,'2026-01-15','B-',2,'Completed'),
(33,'2025-10-01','O+',1,'Completed'),
(34,'2026-02-05','A+',3,'Completed'),
(35,'2025-11-20','B+',2,'Completed'),
(36,'2026-01-10','O-',1,'Completed'),
(37,'2025-12-05','AB+',3,'Completed'),
(38,'2026-02-10','B+',2,'Completed'),
(39,'2025-10-15','O+',1,'Completed'),
(40,'2026-01-25','A-',3,'Completed'),

(41,'2025-11-10','B-',2,'Completed'),
(42,'2026-02-01','O+',1,'Completed'),
(43,'2025-10-20','O-',3,'Completed'),
(44,'2026-01-05','AB+',2,'Completed'),
(45,'2025-12-15','A+',1,'Completed'),
(46,'2026-02-15','B+',3,'Completed'),
(47,'2025-11-05','O+',1,'Completed'),
(48,'2026-01-15','O-',2,'Completed'),
(49,'2025-10-10','AB-',3,'Completed'),
(50,'2026-02-20','A+',1,'Completed'),

/* Additional historical donations */

(1,'2025-07-01','O+',1,'Completed'),
(7,'2025-06-01','O+',1,'Completed'),
(14,'2025-08-01','O+',2,'Completed'),
(19,'2025-07-15','O+',1,'Completed'),
(25,'2025-08-10','O+',3,'Completed'),
(33,'2025-06-15','O+',1,'Completed'),
(39,'2025-07-20','O+',2,'Completed'),
(42,'2025-08-15','O+',1,'Completed'),
(47,'2025-07-10','O+',3,'Completed'),
(4,'2025-07-05','O-',1,'Completed');
GO


/* ============================================================
   EMERGENCY BLOOD REQUESTS - 15 RECORDS
   ============================================================ */

INSERT INTO BloodRequests
(HospitalID, BloodGroup, UnitsRequired, Urgency,
 RequiredDate, Status)
VALUES

(1,'O+',2,'Critical','2026-09-01','Open'),

(2,'A+',1,'High','2026-09-01','Open'),

(3,'O-',3,'Critical','2026-09-01','Open'),

(4,'B+',2,'High','2026-09-02','Open'),

(5,'AB+',1,'Normal','2026-09-02','Open'),

(6,'O+',4,'Critical','2026-09-02','Open'),

(7,'A-',2,'High','2026-09-03','Open'),

(8,'B-',1,'Normal','2026-09-03','Open'),

(1,'O-',2,'Critical','2026-09-03','Open'),

(2,'B+',1,'High','2026-09-04','Open'),

(3,'AB+',2,'Normal','2026-09-04','Open'),

(4,'A+',3,'Critical','2026-09-04','Open'),

(5,'O+',2,'High','2026-09-05','Open'),

(6,'B-',2,'Normal','2026-09-05','Open'),

(7,'O-',1,'Critical','2026-09-05','Open');
GO


SELECT 'Donors' AS TableName, COUNT(*) AS TotalRecords
FROM Donors

UNION ALL

SELECT 'Hospitals', COUNT(*)
FROM Hospitals

UNION ALL

SELECT 'BloodBanks', COUNT(*)
FROM BloodBanks

UNION ALL

SELECT 'Donations', COUNT(*)
FROM Donations

UNION ALL

SELECT 'BloodRequests', COUNT(*)
FROM BloodRequests

UNION ALL

SELECT 'DonorMatches', COUNT(*)
FROM DonorMatches

UNION ALL

SELECT 'Notifications', COUNT(*)
FROM Notifications;

SELECT COUNT(*) AS TotalDonors
FROM Donors;

SELECT TOP 10 *
FROM Donors
ORDER BY DonorID DESC;

SELECT TOP 5 *
FROM Hospitals
ORDER BY HospitalID DESC;

SELECT TOP 5 *
FROM BloodRequests;

SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Donors'
ORDER BY ORDINAL_POSITION;

SELECT *
FROM DonorMatches
ORDER BY MatchID DESC;

SELECT *
FROM BloodRequests
ORDER BY RequestID DESC;

SELECT *
FROM DonorMatches
ORDER BY MatchID DESC;

SELECT
    RequestID,
    HospitalID,
    BloodGroup,
    UnitsRequired,
    Urgency,
    RequiredDate,
    Status
FROM BloodRequests
WHERE RequestID = 33;

SELECT
    d.DonorID,
    d.FullName,
    d.BloodGroup,
    d.Gender,
    d.LastDonationDate,
    dm.DistanceKM,
    dm.MatchScore
FROM DonorMatches dm
JOIN Donors d
    ON dm.DonorID = d.DonorID
WHERE dm.RequestID = 33
ORDER BY dm.DistanceKM;

SELECT
    RequestID,
    DonorID,
    DistanceKM,
    MatchScore,
    MatchStatus
FROM DonorMatches
WHERE RequestID = 34
ORDER BY MatchScore DESC;



SELECT
    dm.RequestID,
    d.DonorID,
    d.FullName,
    d.BloodGroup,
    dm.DistanceKM,
    dm.MatchScore,
    br.Urgency,
    dm.MatchStatus
FROM DonorMatches dm
JOIN Donors d
    ON dm.DonorID = d.DonorID
JOIN BloodRequests br
    ON dm.RequestID = br.RequestID
WHERE dm.RequestID = 34
ORDER BY dm.MatchScore DESC;

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Notifications'
ORDER BY ORDINAL_POSITION;

SELECT
    COLUMNPROPERTY(
        OBJECT_ID('Notifications'),
        'NotificationID',
        'IsIdentity'
    ) AS IsIdentity;

SELECT CAST(definition AS NVARCHAR(MAX)) AS AllowedNotificationTypes
FROM sys.check_constraints
WHERE name = 'CK_Notifications_Type';

SELECT
    NotificationID,
    MatchID,
    DonorID,
    Message,
    NotificationType,
    SentAt,
    DeliveryStatus
FROM Notifications
ORDER BY NotificationID DESC;


SELECT
    d.DonorID,
    d.FullName,
    COUNT(n.NotificationID) AS NotificationCount
FROM Donors d
LEFT JOIN Notifications n
    ON d.DonorID = n.DonorID
GROUP BY
    d.DonorID,
    d.FullName
ORDER BY
    NotificationCount DESC;

    SELECT
    MatchID,
    DonorID,
    MatchStatus
FROM DonorMatches
WHERE MatchID = 120;

USE BloodDonorSystem;

SELECT
    DonorID,
    FullName,
    BloodGroup,
    Phone,
    Email
FROM Donors
WHERE FullName = 'Amruta Patil';