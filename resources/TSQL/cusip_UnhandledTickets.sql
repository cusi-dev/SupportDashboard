USE [Footprints]
GO
/****** Object:  StoredProcedure [dbo].[cusip_UnhandledTickets]    Script Date: 3/25/2015 8:09:37 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[cusip_UnhandledTickets]
AS
BEGIN

	--SELECT TOP (20)
	--	UnhandledTickets
	--FROM
	--	[tblCusiMetricsUnhandledTickets]
	--ORDER BY
	--	[DateCaptured]
	--DESC

	SELECT 
		COUNT(*) AS Tickets 
	FROM 
		MASTER4 m
	INNER JOIN
		MASTER4_ABDATA ma
	ON
		m.mrid=ma.mrID
	WHERE 
		m.mrSTATUS NOT IN ('Escalated__b__u__bTier__b2','Escalated__b__u__bDevelopment','Escalated__b__u__bCBSW__bDevelopment','Assigned','In__bProgress','Closed','Resolved', '_DELETED_', 'Client__bAcceptance', 'Contracted__bWork', 'Development', 'Pending')
	AND 
		m.mrASSIGNEES = 'Support'
	AND 
	(
			Scheduled__bCall IS NULL
		OR
			Scheduled__bCall < DATEADD(day,1,CAST(GETDATE() AS DATE))
	)

END
