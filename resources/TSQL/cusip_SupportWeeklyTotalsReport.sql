USE [Footprints]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[cusip_SupportWeeklyTotalsReport]

AS

BEGIN

CREATE TABLE #tmpWeeklyNewTickets
(
	WeekNumber INT,
	YearNumber INT,
	TicketCount INT
)

INSERT INTO #tmpWeeklyNewTickets
SELECT 
	DATEPART(WEEK,mrsubmitdate) tWeek,
	DATEPART(YEAR,mrsubmitdate) tYear,
	COUNT(mrid) tCount
FROM
	master4
WHERE
	mrSTATUS NOT IN (
		'_DELETED_',
		'_PENDING_SOLUTION_',
		'_SOLVED_',
		'Draft__bSolution'
	)
AND
	(mrASSIGNEES LIKE 'support%' OR mrASSIGNEES LIKE ' support%')
GROUP BY
	DATEPART(YEAR,mrsubmitdate),DATEPART(WEEK,mrsubmitdate)
ORDER BY
	tYear, tWeek

CREATE TABLE #WeeklyNewTickets
(
	WeekNumber INT,
	YearNumber INT,
	TicketCount INT
)
INSERT INTO #WeeklyNewTickets
SELECT
	*
FROM
	#tmpWeeklyNewTickets t
WHERE
	t.WeekNumber <> 53

DECLARE @Year INT
DECLARE c_Year CURSOR FOR
SELECT DISTINCT YearNumber FROM #WeeklyNewTickets

OPEN c_Year
FETCH NEXT FROM c_Year INTO @Year

WHILE @@FETCH_STATUS = 0
BEGIN
	IF NOT EXISTS (
		SELECT
			1
		FROM
			#WeeklyNewTickets
		WHERE
			WeekNumber = 1
		AND
			YearNumber = @Year
	) AND EXISTS (
		SELECT
			1
		FROM
			#WeeklyNewTickets
		WHERE
			WeekNumber = 1
		AND
			YearNumber = @Year - 1
	)
	BEGIN
		INSERT INTO
			#WeeklyNewTickets
		(
			WeekNumber,
			YearNumber,
			TicketCount
		)
		VALUES
		(
			1,
			@Year,
			0
		)
	END
	UPDATE
		#WeeklyNewTickets
	SET
		TicketCount = ISNULL(TicketCount, 0) + (
			SELECT
				ISNULL(TicketCount, 0)
			FROM
				#tmpWeeklyNewTickets
			WHERE
				YearNumber = @Year - 1
			AND
				WeekNumber = 53
		)
	WHERE
		WeekNumber = 1
	AND
		YearNumber = @Year

	FETCH NEXT FROM c_Year INTO @Year
END

CLOSE c_Year
DEALLOCATE c_Year

SELECT
	*
FROM
	#WeeklyNewTickets
ORDER BY
	YearNumber, WeekNumber

END
