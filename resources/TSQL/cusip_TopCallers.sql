CREATE PROCEDURE [dbo].[cusip_TopCallers]
(
	@i_Dashboard BIT = 1
)
AS
BEGIN

-- Select top callers for the current month, per JP

DECLARE
	@FirstOfMonth SMALLDATETIME,
	@CurrentDate SMALLDATETIME = CAST(GETDATE() AS SMALLDATETIME)

SELECT @FirstOfMonth = DATEADD(day,-DATEPART(day,@CurrentDate)+1,@CurrentDate)

SELECT
	TOP 10 *
FROM
(
	SELECT
		ab.Company,
		COUNT(m.mrid) CompanyTickets
	FROM
		MASTER4 m
	INNER JOIN
		MASTER4_ABDATA ab
	ON
		ab.mrID = m.mrID
	WHERE
		m.mrSUBMITDATE <= @CurrentDate
	AND
		m.mrSUBMITDATE >= @FirstOfMonth
	AND
		m.mrSTATUS <> '_DELETED_'
	AND
		(m.mrASSIGNEES LIKE 'Support %' OR m.mrASSIGNEES LIKE '% Support %')
	GROUP BY
		ab.Company
) A
ORDER BY
	CompanyTickets DESC

IF @i_Dashboard <> 1
BEGIN
	SELECT
		ab.Company,
		m.mrID
	FROM
		MASTER4 m
	INNER JOIN
		MASTER4_ABDATA ab
	ON
		ab.mrID = m.mrID
	WHERE
		m.mrSUBMITDATE <= @CurrentDate
	AND
		m.mrSUBMITDATE >= @FirstOfMonth
	AND
		m.mrSTATUS <> '_DELETED_'
	AND
		(m.mrASSIGNEES LIKE 'Support %' OR m.mrASSIGNEES LIKE '% Support %')
	ORDER BY
		ab.Company, m.mrID
END

END