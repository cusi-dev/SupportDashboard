USE [Footprints]
GO
/****** Object:  StoredProcedure [dbo].[cusip_SupportResponseTime]    Script Date: 3/25/2015 8:07:36 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[cusip_SupportResponseTime] 
AS 
BEGIN

DECLARE @Today SMALLDATETIME = (SELECT CAST(GETDATE() AS DATE))
DECLARE @StartTime DATETIME = DATEADD(hour,7,@Today)
DECLARE @EndTime DATETIME = DATEADD(hour,18,@Today)

SELECT 
	ISNULL(DATEDIFF(minute,MIN(mrUPDATEDATE),(GETDATE())),0) AS WaitTime
FROM 
	master4 m
INNER JOIN
	MASTER4_ABDATA ma
ON
	m.mrid=ma.mrID
WHERE
	m.mrSTATUS IN ('_REQUEST_','Open','Contact__bAttempted') AND m.mrASSIGNEES LIKE 'Support%'
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
END
