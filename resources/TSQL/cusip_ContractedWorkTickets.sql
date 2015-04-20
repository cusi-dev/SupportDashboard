USE [Footprints]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[cusip_ContractedWorkTickets]
AS
BEGIN

	SELECT 
		COUNT(m.mrid) AS Tickets,
		ma.[Application] 
	FROM 
		master4 m
	INNER JOIN 
		MASTER4_ABDATA ma
	ON 
		ma.mrID=m.mrID
	WHERE 
		Contracted__bWork = 'on'
	AND 
		mrASSIGNEES LIKE 'Support%'
	AND 
		mrSTATUS <> '_DELETED_'
	AND 
		mrSTATUS NOT IN ('Closed','Resolved')
	GROUP BY
		ma.[Application] 

END
