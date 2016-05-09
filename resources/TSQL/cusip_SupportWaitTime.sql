USE [Footprints]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[cusip_SupportWaitTime] 
AS 
BEGIN

DECLARE @Today SMALLDATETIME = (SELECT CAST(GETDATE() AS DATE))
DECLARE @StartTime DATETIME = DATEADD(hour,7,@Today)
DECLARE @EndTime DATETIME = DATEADD(hour,18,@Today)

CREATE TABLE #OpenTickets
(
	mrID INT,
	Age INT,
	mrStatus VARCHAR(128)
)
INSERT INTO #OpenTickets
(
	mrID,
	mrStatus
)
SELECT
	mrID,
	mrSTATUS
FROM
	MASTER4
WHERE
	(mrASSIGNEES LIKE 'Support%' OR mrASSIGNEES LIKE ' Support%')
AND
	mrSTATUS IN ('_REQUEST_','Open','Contact__bAttempted','Open__b__u__bTime__bSensitive','Scheduled__bCall')
AND
	(
		Scheduled__bCall IS NULL 
	OR
		(
			Scheduled__bCall >= @StartTime
		AND 
			Scheduled__bCall <= @EndTime
		)
	)

--Set open times
UPDATE
	#OpenTickets
SET
	Age = DATEDIFF(minute,A.mrTIMESTAMP,(GETDATE()))
FROM
	#OpenTickets o
CROSS APPLY
(
	SELECT
		TOP 1 fh.mrTIMESTAMP
	FROM
		MASTER4_FIELDHISTORY fh
	WHERE
		fh.mrID = o.mrID
	AND
		fh.mrNEWFIELDVALUE IN ('_REQUEST_','Open')
	ORDER BY
		fh.mrSEQUENCE DESC
) A

--Update for contact attempted
UPDATE
	#OpenTickets
SET
	Age = A.Age
FROM
(
	SELECT
		o.mrID,
		DATEDIFF(minute,MAX(fh.mrTIMESTAMP),(GETDATE())) Age
	FROM
		#OpenTickets o
	INNER JOIN
		MASTER4 m
	ON
		m.mrID = o.mrID
	INNER JOIN
		MASTER4_FIELDHISTORY fh
	ON
		fh.mrID = o.mrID
	WHERE
		m.mrSTATUS IN ('Contact__bAttempted')
	AND
		fh.mrNEWFIELDVALUE = 'Contact__bAttempted'
	GROUP BY
		o.mrID
) A
INNER JOIN
	#OpenTickets o
ON
	o.mrID = A.mrID

--Update for open - time sensitive
UPDATE
	#OpenTickets
SET
	Age = A.Age
FROM
(
	SELECT
		o.mrID,
		DATEDIFF(minute,m.Scheduled__bCall,(GETDATE())) Age
	FROM
		#OpenTickets o
	INNER JOIN
		MASTER4 m
	ON
		m.mrID = o.mrID
	WHERE
		m.mrSTATUS IN ('Open__b__u__bTime__bSensitive')
) A
INNER JOIN
	#OpenTickets o
ON
	o.mrID = A.mrID

--Update for scheduled call
UPDATE
	#OpenTickets
SET
	Age = A.Age
FROM
(
	SELECT
		o.mrID,
		DATEDIFF(minute,m.Scheduled__bCall,(GETDATE())) Age
	FROM
		#OpenTickets o
	INNER JOIN
		MASTER4 m
	ON
		m.mrID = o.mrID
	WHERE
		m.mrSTATUS IN ('Scheduled__bCall')
) A
INNER JOIN
	#OpenTickets o
ON
	o.mrID = A.mrID

SELECT
	CASE
		WHEN ISNULL(MAX(Age),0) < 0 THEN 0
		ELSE ISNULL(MAX(Age),0)
	END
FROM
	#OpenTickets

DROP TABLE #OpenTickets

END
