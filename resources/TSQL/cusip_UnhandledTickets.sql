USE [Footprints]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[cusip_UnhandledTickets]
AS
BEGIN

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
	AND --First filter all non-support tickets
		m.mrASSIGNEES LIKE 'Support%' 
	AND --Check for Support as the only assignee after stripping CCs (which always come at the end of the assignee string)
		RTRIM(LEFT(m.mrASSIGNEES,(
					CASE 
						WHEN CHARINDEX('cc',m.mrAssignees) > 0 THEN CHARINDEX('cc',m.mrAssignees) - 1
						ELSE LEN(m.mrAssignees)
					END
		))) = 'Support'
	AND --Empty scheduled call time or the scheduled call time is before tomorrow.
	(
			Scheduled__bCall IS NULL
		OR
			Scheduled__bCall < DATEADD(day,1,CAST(GETDATE() AS DATE))
	)

END
