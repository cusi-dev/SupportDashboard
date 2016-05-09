USE [Footprints]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[cusip_SupportMetricsReport]
(
	@i_Today SMALLDATETIME
	,@i_Period VARCHAR(8)
)
AS

BEGIN
SET NOCOUNT ON

-- weekday holidays
CREATE TABLE #Holidays
(
	OffDate SMALLDATETIME
)
INSERT INTO #Holidays
SELECT '2013-01-01'
UNION
SELECT '2013-05-27'
UNION
SELECT '2013-07-04'
UNION
SELECT '2013-09-02'
UNION
SELECT '2013-11-28'
UNION
SELECT '2013-11-29'
UNION
SELECT '2013-12-25'
UNION

SELECT '2014-01-01'
UNION
SELECT '2014-05-26'
UNION
SELECT '2014-07-04'
UNION
SELECT '2014-09-01'
UNION
SELECT '2014-11-27'
UNION
SELECT '2014-11-28'
UNION
SELECT '2014-12-25'
UNION
SELECT '2014-12-26'
UNION

SELECT '2015-01-01'
UNION
SELECT '2015-05-25'
UNION
SELECT '2015-07-03'
UNION
SELECT '2015-09-07'
UNION
SELECT '2015-11-26'
UNION
SELECT '2015-11-27'
UNION
SELECT '2015-12-25'
UNION

SELECT '2016-01-01'
UNION
SELECT '2016-05-30'
UNION
SELECT '2016-07-04'
UNION
SELECT '2016-09-05'
UNION
SELECT '2016-11-24'
UNION
SELECT '2016-11-25'
UNION
SELECT '2016-12-26'


CREATE TABLE #tmpMetrics
(
	Period VARCHAR(24)
	,GroupName VARCHAR(4)
	,ClosedTickets INT
	,NewTickets INT
	,AverageResponseTime INT
	,SLA30 INT
	,SLA60 INT
	,SLA61 INT
	,InboundTickets INT
)

INSERT INTO #tmpMetrics
EXEC cusip_SupportMetrics @i_Today=@i_Today, @i_Period=@i_Period

CREATE TABLE #MetricsReport
(
	Period VARCHAR(24)
	,ClosedTickets INT
	,AgentCount INT
	,NewTickets INT
	,NewCBSW INT
	,NewUMS INT
	,ARTAll INT
	,ARTAllFormatted NVARCHAR(10)
	,ARTCBSW INT
	,ARTCBSWFormatted NVARCHAR(10)
	,ARTUMS INT
	,ARTUMSFormatted NVARCHAR(10)
	,SLA30All INT
	,SLA60All INT
	,SLA61All INT
	,SLA30CBSW INT
	,SLA60CBSW INT
	,SLA61CBSW INT
	,SLA30UMS INT
	,SLA60UMS INT
	,SLA61UMS INT
	,InboundTicketsAll INT
	,InboundTicketsCBSW INT
	,InboundTicketsUMS INT
	,NewCBSWPerc DECIMAL(5,1)			-- CBSW % of all new tickets
	,NewUMSPerc DECIMAL(5,1)			-- UMS % of all new tickets
	,SLA30Perc DECIMAL(5,1)				-- % of new tickets in SLA30
	,SLA60Perc DECIMAL(5,1)				-- % of new tickets in SLA60
	,SLA61Perc DECIMAL(5,1)				-- % of new tickets in SLA61
	,SLA30CBSWPerc DECIMAL(5,1)			-- % of CBSW tickets in SLA30
	,SLA60CBSWPerc DECIMAL(5,1)			-- % of CBSW tickets in SLA60
	,SLA61CBSWPerc DECIMAL(5,1)			-- % of CBSW tickets in SLA61
	,SLA30UMSPerc DECIMAL(5,1)			-- % of UMS tickets in SLA30
	,SLA60UMSPerc DECIMAL(5,1)			-- % of UMS tickets in SLA60
	,SLA61UMSPerc DECIMAL(5,1)			-- % of UMS tickets in SLA61
	,InboundTicketsAllPerc DECIMAL(5,1)	-- inbound % of all new tickets
	,InboundTicketsCBSWPerc DECIMAL(5,1)-- % of CBSW tickets inbound
	,InboundTicketsUMSPerc DECIMAL(5,1)	-- % of UMS tickets inbound
)

INSERT INTO #MetricsReport
(
	Period
	,ClosedTickets
	,AgentCount
	,NewTickets
	,ARTAll
	,ARTAllFormatted
	,SLA30All
	,SLA60All
	,SLA61All
	,InboundTicketsAll
)
SELECT
	Period
	,ClosedTickets
	,0
	,NewTickets
	,AverageResponseTime
	,CAST(AverageResponseTime / 60 AS NVARCHAR) + ':' + RIGHT('0' + CAST(AverageResponseTime % 60 AS NVARCHAR), 2)
	,SLA30
	,SLA60
	,SLA61
	,InboundTickets
FROM
	#tmpMetrics
WHERE
	GroupName = 'ALL'
AND
	Period NOT IN (SELECT OffDate FROM #Holidays)
ORDER BY
	Period

--CBSW tickets
UPDATE
	#MetricsReport
SET
	NewCBSW = t.NewTickets
	,ARTCBSW = t.AverageResponseTime
	,ARTCBSWFormatted = CAST(AverageResponseTime / 60 AS NVARCHAR) + ':' + RIGHT('0' + CAST(AverageResponseTime % 60 AS NVARCHAR), 2)
	,SLA30CBSW = t.SLA30
	,SLA60CBSW = t.SLA60
	,SLA61CBSW = t.SLA61
	,InboundTicketsCBSW = t.InboundTickets
FROM
	#tmpMetrics t
INNER JOIN
	#MetricsReport m
ON
	m.Period = t.Period
WHERE
	t.Period NOT IN (SELECT OffDate FROM #Holidays)
AND
	t.GroupName = 'CBSW'

--UMS tickets
UPDATE
	#MetricsReport
SET
	NewUMS = t.NewTickets
	,ARTUMS = t.AverageResponseTime
	,ARTUMSFormatted = CAST(AverageResponseTime / 60 AS NVARCHAR) + ':' + RIGHT('0' + CAST(AverageResponseTime % 60 AS NVARCHAR), 2)
	,SLA30UMS = t.SLA30
	,SLA60UMS = t.SLA60
	,SLA61UMS = t.SLA61
	,InboundTicketsUMS = t.InboundTickets
FROM
	#tmpMetrics t
INNER JOIN
	#MetricsReport m
ON
	m.Period = t.Period
WHERE
	t.Period NOT IN (SELECT OffDate FROM #Holidays)
AND
	t.GroupName = 'UMS'

--Percentages
UPDATE
	#MetricsReport
SET
	--Aggregate
	SLA30Perc = CASE WHEN m.NewTickets <> 0 THEN m.SLA30All / CAST(m.NewTickets AS DECIMAL) * 100 ELSE 0 END
	,SLA60Perc = CASE WHEN m.NewTickets <> 0 THEN m.SLA60All / CAST(m.NewTickets AS DECIMAL) * 100 ELSE 0 END
	,SLA61Perc = CASE WHEN m.NewTickets <> 0 THEN m.SLA61All / CAST(m.NewTickets AS DECIMAL) * 100 ELSE 0 END
	,InboundTicketsAllPerc = CASE WHEN m.NewTickets <> 0 THEN m.InboundTicketsAll / CAST(m.NewTickets AS DECIMAL) * 100 ELSE 0 END
	--CBSW
	,NewCBSWPerc = CASE WHEN m.NewTickets <> 0 THEN m.NewCBSW / CAST(m.NewTickets AS DECIMAL) * 100 ELSE 0 END
	,SLA30CBSWPerc = CASE WHEN m.NewCBSW <> 0 THEN m.SLA30CBSW / CAST(m.NewCBSW AS DECIMAL) * 100 ELSE 0 END
	,SLA60CBSWPerc = CASE WHEN m.NewCBSW <> 0 THEN m.SLA60CBSW / CAST(m.NewCBSW AS DECIMAL) * 100 ELSE 0 END
	,SLA61CBSWPerc = CASE WHEN m.NewCBSW <> 0 THEN m.SLA61CBSW / CAST(m.NewCBSW AS DECIMAL) * 100 ELSE 0 END
	,InboundTicketsCBSWPerc = CASE WHEN m.NewTickets <> 0 THEN m.InboundTicketsCBSW / CAST(m.NewTickets AS DECIMAL) * 100 ELSE 0 END
	--UMS
	,NewUMSPerc = CASE WHEN m.NewTickets <> 0 THEN m.NewUMS / CAST(m.NewTickets AS DECIMAL) * 100 ELSE 0 END
	,SLA30UMSPerc = CASE WHEN m.NewUMS <> 0 THEN m.SLA30UMS / CAST(m.NewUMS AS DECIMAL) * 100 ELSE 0 END
	,SLA60UMSPerc = CASE WHEN m.NewUMS <> 0 THEN m.SLA60UMS / CAST(m.NewUMS AS DECIMAL) * 100 ELSE 0 END
	,SLA61UMSPerc = CASE WHEN m.NewUMS <> 0 THEN m.SLA61UMS / CAST(m.NewUMS AS DECIMAL) * 100 ELSE 0 END
	,InboundTicketsUMSPerc = CASE WHEN m.NewTickets <> 0 THEN m.InboundTicketsUMS / CAST(m.NewTickets AS DECIMAL) * 100 ELSE 0 END
FROM
	#MetricsReport m

-- Get ticket counts for full day
DECLARE @d DATETIME
DECLARE c_Tickets CURSOR FOR
SELECT Period FROM #MetricsReport ORDER BY Period

OPEN c_Tickets
FETCH NEXT FROM c_Tickets INTO @d

WHILE @@FETCH_STATUS = 0
BEGIN
	-- For weekdays other than Monday, get the actual 24-hour-day's count
	IF DATEPART(dw, @d) <> 2
	BEGIN
		UPDATE
			#MetricsReport
		SET
			NewTickets = A.Tickets
		FROM
		(
			SELECT
				COUNT(m.mrID) Tickets
			FROM
				MASTER4 m
			WHERE
				mrSUBMITDATE BETWEEN @d AND DATEADD(SECOND,-1,DATEADD(DAY, 1, @d))
			AND
				mrSTATUS NOT IN (
					'_DELETED_',
					'_PENDING_SOLUTION_',
					'_SOLVED_',
					'Draft__bSolution'
				)
			AND
				(mrASSIGNEES LIKE 'Support%' OR mrASSIGNEES LIKE ' Support%')
		) A
		WHERE
			Period = @d

		UPDATE
			#MetricsReport
		SET
			NewUMS = A.Tickets
		FROM
		(
			SELECT
				COUNT(m.mrID) Tickets
			FROM
				MASTER4 m
			INNER JOIN
				MASTER4_ABDATA a
			ON
				a.mrID = m.mrID
			WHERE
				mrSUBMITDATE BETWEEN @d AND DATEADD(SECOND,-1,DATEADD(DAY, 1, @d))
			AND
				mrSTATUS NOT IN (
					'_DELETED_',
					'_PENDING_SOLUTION_',
					'_SOLVED_',
					'Draft__bSolution'
				)
			AND
				(mrASSIGNEES LIKE 'Support%' OR mrASSIGNEES LIKE ' Support%')
			AND
				a.Application = 'UMS'
		) A
		WHERE
			Period = @d

		UPDATE
			#MetricsReport
		SET
			NewCBSW = A.Tickets
		FROM
		(
			SELECT
				COUNT(m.mrID) Tickets
			FROM
				MASTER4 m
			INNER JOIN
				MASTER4_ABDATA a
			ON
				a.mrID = m.mrID
			WHERE
				mrSUBMITDATE BETWEEN @d AND DATEADD(SECOND,-1,DATEADD(DAY, 1, @d))
			AND
				mrSTATUS NOT IN (
					'_DELETED_',
					'_PENDING_SOLUTION_',
					'_SOLVED_',
					'Draft__bSolution'
				)
			AND
				(mrASSIGNEES LIKE 'Support%' OR mrASSIGNEES LIKE ' Support%')
			AND
				a.Application = 'CBSW'
		) A
		WHERE
			Period = @d
	END
	ELSE -- For non-holiday Mondays, also include any Saturday and Sunday submissions
	BEGIN
		UPDATE
			#MetricsReport
		SET
			NewTickets = A.Tickets
		FROM
		(
			SELECT
				COUNT(m.mrID) Tickets
			FROM
				MASTER4 m
			WHERE
				mrSUBMITDATE BETWEEN DATEADD(DAY, -2, @d) AND DATEADD(SECOND,-1,DATEADD(DAY, 1, @d))
			AND
				mrSTATUS NOT IN (
					'_DELETED_',
					'_PENDING_SOLUTION_',
					'_SOLVED_',
					'Draft__bSolution'
				)
			AND
				(mrASSIGNEES LIKE 'Support%' OR mrASSIGNEES LIKE ' Support%')
		) A
		WHERE
			Period = @d

		UPDATE
			#MetricsReport
		SET
			NewUMS = A.Tickets
		FROM
		(
			SELECT
				COUNT(m.mrID) Tickets
			FROM
				MASTER4 m
			INNER JOIN
				MASTER4_ABDATA a
			ON
				a.mrID = m.mrID
			WHERE
				mrSUBMITDATE BETWEEN DATEADD(DAY, -2, @d) AND DATEADD(SECOND,-1,DATEADD(DAY, 1, @d))
			AND
				mrSTATUS NOT IN (
					'_DELETED_',
					'_PENDING_SOLUTION_',
					'_SOLVED_',
					'Draft__bSolution'
				)
			AND
				(mrASSIGNEES LIKE 'Support%' OR mrASSIGNEES LIKE ' Support%')
			AND
				a.Application = 'UMS'
		) A
		WHERE
			Period = @d

		UPDATE
			#MetricsReport
		SET
			NewCBSW = A.Tickets
		FROM
		(
			SELECT
				COUNT(m.mrID) Tickets
			FROM
				MASTER4 m
			INNER JOIN
				MASTER4_ABDATA a
			ON
				a.mrID = m.mrID
			WHERE
				mrSUBMITDATE BETWEEN DATEADD(DAY, -2, @d) AND DATEADD(SECOND,-1,DATEADD(DAY, 1, @d))
			AND
				mrSTATUS NOT IN (
					'_DELETED_',
					'_PENDING_SOLUTION_',
					'_SOLVED_',
					'Draft__bSolution'
				)
			AND
				(mrASSIGNEES LIKE 'Support%' OR mrASSIGNEES LIKE ' Support%')
			AND
				a.Application = 'CBSW'
		) A
		WHERE
			Period = @d
	END

	-- 
	-- Now, go back and separately pick up any submissions on holidays.
	-- 

	FETCH NEXT FROM c_Tickets INTO @d
END

CLOSE c_Tickets
DEALLOCATE c_Tickets

SELECT * FROM #MetricsReport ORDER BY Period

SET NOCOUNT OFF
END
