USE [Footprints]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[cusip_SupportMetrics]
(
	@i_Today SMALLDATETIME,
	@i_Period VARCHAR(8),
	@i_Dashboard BIT = 1
)
AS

BEGIN
SET NOCOUNT ON

DECLARE @ShiftStartTime TIME = '07:00:00'
DECLARE @ShiftEndTime TIME = '18:00:00'

DECLARE @ThisPeriodStart DATETIME
DECLARE @NextPeriodStart DATETIME

IF @i_Period = 'YEAR'
BEGIN
	SET @ThisPeriodStart = DATEADD(year,DATEDIFF(year,0,CAST(@i_Today AS DATETIME)),0)
	SET @NextPeriodStart = DATEADD(YEAR,1,@ThisPeriodStart)
END
ELSE IF @i_Period = 'MONTH'
BEGIN
	SET @ThisPeriodStart = DATEADD(month,DATEDIFF(month,0,CAST(@i_Today AS DATETIME)),0)
	SET @NextPeriodStart = DATEADD(MONTH,1,@ThisPeriodStart)
END
ELSE -- 'DAY' or something else that we'll treat as a day
BEGIN
	SET @ThisPeriodStart = CAST(@i_Today AS DATETIME)
	SET @NextPeriodStart = DATEADD(day,1,@ThisPeriodStart)
END

DECLARE @MetricGroups TABLE (
	idx INT IDENTITY(1,1),
	MetricGroup VARCHAR(4)
)
INSERT INTO @MetricGroups 
	SELECT 'ALL' UNION
	SELECT 'UMS' UNION 
	SELECT 'CBSW'

DECLARE @ThisMetricGroup VARCHAR(4)
DECLARE @i INT = 0
DECLARE @cnt INT
SELECT @cnt = COUNT(MetricGroup) FROM @MetricGroups

CREATE TABLE #tmpART
(
	mrID INT,
	OpenTime DATETIME,
	InProgressTime DATETIME,
	ResponseTime INT
)

CREATE TABLE #ARTReportDetail
(
	mrID INT,
	OpenTime DATETIME,
	InProgressTime DATETIME,
	ResponseTime INT
)

CREATE TABLE #ResponseMetrics
(
	Period VARCHAR(24),
	GroupName VARCHAR(4),
	ClosedTickets INT,
	NewTickets INT,
	AverageResponseTime INT,
	SLA30 INT,
	SLA60 INT,
	SLA61 INT,
	InboundTickets INT,
    ChatTickets INT
)

------------------------------------------------
-- DAYS
------------------------------------------------
DECLARE @Day DATETIME = @ThisPeriodStart
DECLARE @NextDay DATETIME
DECLARE @DayInt INT 

-- Loop for each day in the selected period
WHILE @Day < @NextPeriodStart
BEGIN

	-- Loop for each metric group within the day
	WHILE @i < @cnt
	BEGIN

		SET @i = @i + 1
		SELECT @ThisMetricGroup = MetricGroup FROM @MetricGroups WHERE idx=@i

		SET @NextDay = DATEADD(DAY,1,@Day)

		-- Only gather numbers for weekdays
		IF DATENAME(dw,@Day) NOT IN ('Saturday','Sunday')
		BEGIN
			SET @DayInt = CAST(@Day AS INT)

			INSERT INTO #ResponseMetrics
			(
				Period,
				GroupName
			)
			SELECT 
				CONVERT(VARCHAR(12),@Day,101),
				(SELECT MetricGroup FROM @MetricGroups WHERE idx=@i)

			UPDATE
				#ResponseMetrics
			SET
				ClosedTickets = ISNULL(A.TicketCount,0)
			FROM
			(
				SELECT 
					COUNT(fh.mrid) TicketCount
				FROM 
					MASTER4_FIELDHISTORY fh
				INNER JOIN 
					MASTER4 m
				ON 
					m.mrID=fh.mrID
				INNER JOIN
					MASTER4_ABDATA ma
				ON
					m.mrID=ma.mrID
				WHERE 
					m.mrSTATUS<>'_DELETED_'
				AND
					fh.mrFIELDNAME='mrStatus'
				AND
					fh.mrNEWFIELDVALUE IN ('Closed')
				AND
					fh.mrTIMESTAMP >= @Day
				AND
					fh.mrTIMESTAMP < @NextDay
				AND
					ma.[Application] LIKE '%'+(CASE WHEN @ThisMetricGroup='ALL' THEN '' ELSE @ThisMetricGroup END)+'%'
				AND
					(m.mrASSIGNEES LIKE 'Support%' OR m.mrASSIGNEES like '% Support%')
			) A
			WHERE
				Period = @Day
			AND
				GroupName = @ThisMetricGroup

			UPDATE
				#ResponseMetrics
			SET
				NewTickets = ISNULL(A.TicketCount,0)
			FROM
			(
				SELECT 
					COUNT(*) AS TicketCount
				FROM 
					MASTER4 m
				INNER JOIN
					MASTER4_ABDATA ma
				ON
					m.mrid=ma.mrID
				WHERE 
					m.mrSTATUS<>'_DELETED_'
				AND
					m.mrSUBMITDATE >= @Day
				AND
					m.mrSUBMITDATE < @NextDay
				AND
					ma.[Application] LIKE '%'+(CASE WHEN @ThisMetricGroup='ALL' THEN '' ELSE @ThisMetricGroup END)+'%'
				AND
					(mrASSIGNEES LIKE 'Support%' OR mrASSIGNEES LIKE '% Support%')
			) A
			WHERE
				Period = @Day
			AND
				GroupName = @ThisMetricGroup

			UPDATE
				#ResponseMetrics
			SET
				InboundTickets = ISNULL(A.TicketCount,0)
			FROM
			(
				SELECT
					COUNT(*) TicketCount
				FROM (
					SELECT 
						fh.mrid
					FROM 
						MASTER4_FIELDHISTORY fh
					INNER JOIN 
						MASTER4 m
					ON 
						m.mrID=fh.mrID
					INNER JOIN
						MASTER4_ABDATA ma
					ON
						m.mrID=ma.mrID
					WHERE 
						fh.mrFIELDNAME='mrStatus'
					AND
						fh.mrNEWFIELDVALUE IN ('Closed')
					AND
						m.First__bContact__bResolution = 'on'
					AND
						m.mrSTATUS<>'_DELETED_'
					AND
						fh.mrTIMESTAMP >= @Day
					AND
						fh.mrTIMESTAMP < @NextDay
					AND
						ma.[Application] LIKE '%'+(CASE WHEN @ThisMetricGroup='ALL' THEN '' ELSE @ThisMetricGroup END)+'%'
					AND
						(m.mrASSIGNEES LIKE 'Support%' OR m.mrASSIGNEES like '% Support%')
					GROUP BY
						fh.mrID
				) B
			) A
			WHERE
				Period = @Day
			AND
				GroupName = @ThisMetricGroup

			UPDATE
				#ResponseMetrics
			SET
				ChatTickets = ISNULL(A.TicketCount,0)
			FROM
			(
				SELECT
					COUNT(*) TicketCount
				FROM (
					SELECT 
						fh.mrid
					FROM 
						MASTER4_FIELDHISTORY fh
					INNER JOIN 
						MASTER4 m
					ON 
						m.mrID=fh.mrID
					INNER JOIN
						MASTER4_ABDATA ma
					ON
						m.mrID=ma.mrID
					WHERE 
						fh.mrFIELDNAME='mrStatus'
					AND
						fh.mrNEWFIELDVALUE IN ('Closed')
					AND
						m.Chat__bResolution = 'on'
					AND
						m.mrSTATUS<>'_DELETED_'
					AND
						fh.mrTIMESTAMP >= @Day
					AND
						fh.mrTIMESTAMP < @NextDay
					AND
						ma.[Application] LIKE '%'+(CASE WHEN @ThisMetricGroup='ALL' THEN '' ELSE @ThisMetricGroup END)+'%'
					AND
						(m.mrASSIGNEES LIKE 'Support%' OR m.mrASSIGNEES like '% Support%')
					GROUP BY
						fh.mrID
				) B
			) A
			WHERE
				Period = @Day
			AND
				GroupName = @ThisMetricGroup

			INSERT INTO #tmpART
			(
				mrID,
				OpenTime
			)
			SELECT
				m.mrID,
				m.mrSUBMITDATE
			FROM
				MASTER4 m
			INNER JOIN
				MASTER4_ABDATA ma
			ON
				m.mrID=ma.mrID
			WHERE
				m.mrSUBMITDATE >= @Day
			AND
				m.mrSUBMITDATE < @NextDay
			AND
				m.mrSTATUS <> '_DELETED_'
			AND
			(
					m.Contracted__bWork = 'off'
				OR
					m.Contracted__bWork IS NULL
			)
			AND
				(m.mrASSIGNEES LIKE 'Support%' OR m.mrASSIGNEES like '% Support%')
			-- Ticket creation date within "workspace time"
			AND
				CONVERT(TIME,m.mrSUBMITDATE) >= @ShiftStartTime
			AND
				CONVERT(TIME,m.mrSUBMITDATE) <= @ShiftEndTime
			AND
				ma.[Application] LIKE '%'+(CASE WHEN @ThisMetricGroup='ALL' THEN '' ELSE @ThisMetricGroup END)+'%'
			GROUP BY
				m.mrID,
				m.mrSUBMITDATE
			ORDER BY
				m.mrID

			DELETE FROM
				#tmpART
			WHERE
				mrID IN
				(
					SELECT
						t.mrID
					FROM
						#tmpART t
					INNER JOIN
						MASTER4_FIELDHISTORY fh
					ON
						fh.mrID=t.mrID
					WHERE
						fh.mrFIELDNAME = 'mrStatus'
					AND
						fh.mrOLDFIELDVALUE IS NULL
					AND
						fh.mrNEWFIELDVALUE IN 
						(
							'Open__b__u__bTime__bSensitive',
							'Scheduled__bCall'
						)
					GROUP BY
						t.mrID
				)

			UPDATE
				#tmpART
			SET
				InProgressTime = A.InProgressTime
			FROM
			(
				SELECT
					t.mrID,
					MIN(fh.mrTIMESTAMP) InProgressTime
				FROM
					#tmpART t
				INNER JOIN
					MASTER4_FIELDHISTORY fh
				ON
					fh.mrID=t.mrID
				WHERE
					fh.mrFIELDNAME = 'mrStatus'
				--AND
				--	(fh.mrOLDFIELDVALUE IN ('Open','_REQUEST_') OR fh.mrOLDFIELDVALUE IS NULL)
				AND
					fh.mrNEWFIELDVALUE IN 
					(
						--'_DELETED_',
						--'_INACTIVE_',
						--'_PENDING_SOLUTION_',
						--'_REQUEST_',
						--'_SOLVED_',
						'Assigned',
						'Client__bAcceptance',
						'Closed',
						'Contact__bAttempted',
						--'Contracted__bWork',
						--'Contracted__bWork__bPending__bVersion__bRelease',
						--'Customer__bReponse',
						'Deployment',
						'Development',
						--'Draft__bSolution',
						'Escalated__b__u__bCBSW__bDevelopment',
						'Escalated__b__u__bCWP__bDevelopment',
						'Escalated__b__u__bDevelopment',
						'Escalated__b__u__bMgmt',
						'Escalated__b__u__bOther',
						'Escalated__b__u__bTier__b2',
						'In__bProgress',
						--'Open',
						'Open__b__u__bTime__bSensitive',
						'Pending',
						'Pending__b__u__bClient__bAcceptance',
						'Pending__b__u__bClient__bResponse',
						'Pending__b__u__bClient__bUpgrade',
						'Pending__b__u__bDev__bComplete',
						'Pending__b__u__bDev__bIn__bProgress',
						'Pending__b__u__bVersion__bRelease',
						'Reopened',
						'Resolved',
						--'Rollover',
						'Scheduled__bCall'
					)
				GROUP BY
					t.mrID
			) A
			INNER JOIN
				#tmpART
			ON
				#tmpART.mrID=A.mrID

			UPDATE
				#tmpART
			SET
				ResponseTime = DATEDIFF(MINUTE, OpenTime, ISNULL(InProgressTime,GETDATE()))

			UPDATE
				#ResponseMetrics
			SET
				AverageResponseTime = a.AverageResponseTime,
				SLA30 = A.SLA30,
				SLA60 = A.SLA60,
				SLA61 = A.SLA61
			FROM
			(
				SELECT 
					ISNULL(AVG(t.ResponseTime),0) AverageResponseTime
					,ISNULL(SUM(CASE
						WHEN t.ResponseTime <= 30 THEN 1
						ELSE 0
					END),0) SLA30
					,ISNULL(SUM(CASE
						WHEN t.ResponseTime > 30 AND t.ResponseTime <= 60 THEN 1
						ELSE 0
					END),0) SLA60
					,ISNULL(SUM(CASE
						WHEN t.ResponseTime > 60 OR t.ResponseTime IS NULL THEN 1
						ELSE 0
					END),0) SLA61
				FROM
					#tmpART t
			) A
			WHERE
				Period = @Day
			AND
				GroupName = @ThisMetricGroup

		END

		IF @ThisMetricGroup <> 'ALL'
		BEGIN
			INSERT INTO
				#ARTReportDetail
			SELECT
				*
			FROM
				#tmpART
		END

		TRUNCATE TABLE #tmpART

	END --WHILE
	SET @i = 0

	SET @Day = @NextDay
END

SELECT * FROM #ResponseMetrics
ORDER BY Period, GroupName

IF @i_Dashboard <> 1
	SELECT * FROM #ARTReportDetail ORDER BY mrID

DROP TABLE #ResponseMetrics

SET NOCOUNT OFF
END
