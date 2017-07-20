USE [Footprints]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[cusip_UnhandledTickets]
(
	@i_Dashboard BIT = 1
)
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
		m.mrSTATUS NOT IN (
			'Escalated__b__u__bTier__b2',
			'Escalated__b__u__bDevelopment',
			'Escalated__b__u__bCBSW__bDevelopment',
			'Assigned',
			'In__bProgress',
			'Closed',
			'Resolved',
			'_DELETED_',
			'Client__bAcceptance',
			'Contracted__bWork',
			'Development',
			'Pending',
			'Deployment'
		)
	AND
		(m.mrASSIGNEES LIKE 'Support%' OR m.mrASSIGNEES LIKE '% Support%')
	AND --Empty scheduled call time or the scheduled call time is before now.
	(
			Scheduled__bCall IS NULL
		OR
			Scheduled__bCall < GETDATE()
	)

	IF @i_Dashboard <> 1
	BEGIN
		SELECT 
			m.* 
		FROM 
			MASTER4 m
		INNER JOIN
			MASTER4_ABDATA ma
		ON
			m.mrid=ma.mrID
		WHERE 
			m.mrSTATUS NOT IN (
				'Escalated__b__u__bTier__b2',
				'Escalated__b__u__bDevelopment',
				'Escalated__b__u__bCBSW__bDevelopment',
				'Assigned',
				'In__bProgress',
				'Closed',
				'Resolved',
				'_DELETED_',
				'Client__bAcceptance',
				'Contracted__bWork',
				'Development',
				'Pending',
				'Deployment'
			)
		AND
			(m.mrASSIGNEES LIKE 'Support%' OR m.mrASSIGNEES LIKE '% Support%')
		AND --Empty scheduled call time or the scheduled call time is before now.
		(
				Scheduled__bCall IS NULL
			OR
			    Scheduled__bCall < GETDATE()
		)
	END
END
