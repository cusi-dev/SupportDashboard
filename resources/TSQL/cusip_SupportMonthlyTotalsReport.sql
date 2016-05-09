USE [Footprints]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[cusip_SupportMonthlyTotalsReport]

AS

BEGIN

CREATE TABLE #tmpMonthlyNewTickets
(
	MonthNumber INT,
	MonthAbbv NVARCHAR(20),
	YearNumber INT,
	TicketCount INT,
	UMSCount INT,
	CBSWCount INT,
	ResponseTime INT,
	SLA60 INT
)

INSERT INTO #tmpMonthlyNewTickets
(
	MonthNumber,
	MonthAbbv,
	YearNumber,
	TicketCount,
	UMSCount,
	CBSWCount
)
SELECT
	DATEPART(MONTH,m.mrSUBMITDATE) tMonthNo,
	CONVERT(CHAR(3),m.mrSUBMITDATE,0) tMonth,
	DATEPART(YEAR,m.mrSUBMITDATE) tYear,
	COUNT(m.mrID) tCount,
	SUM(
		CASE
			WHEN a.Application = 'UMS' THEN 1
			ELSE 0
		END
	),
	SUM(
		CASE
			WHEN a.Application = 'CBSW' THEN 1
			ELSE 0
		END
	)
FROM
	master4 m
INNER JOIN
	MASTER4_ABDATA a
ON
	a.mrID=m.mrID
WHERE
	m.mrSTATUS NOT IN (
		'_DELETED_',
		'_PENDING_SOLUTION_',
		'_SOLVED_',
		'Draft__bSolution'
	)
AND
	(mrASSIGNEES LIKE 'Support%' OR mrASSIGNEES LIKE ' Support%')
GROUP BY
	DATEPART(YEAR,m.mrSUBMITDATE),DATEPART(MONTH,m.mrSUBMITDATE),CONVERT(CHAR(3),m.mrSUBMITDATE,0)
ORDER BY
	tYear, tMonth

SELECT
	MonthAbbv,
	YearNumber,
	TicketCount,
	UMSCount,
	CBSWCount
FROM
	#tmpMonthlyNewTickets
ORDER BY
	YearNumber, MonthNumber

DROP TABLE #tmpMonthlyNewTickets

END
