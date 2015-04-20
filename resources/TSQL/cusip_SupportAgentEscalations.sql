USE [Footprints]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[cusip_SupportAgentEscalations] 
AS
BEGIN

	SET NOCOUNT ON

	SELECT 
		m.mrID,
		CAST(m.mrUPDATEDATE AS SMALLDATETIME) [Timestamp],
		CAST((DATEDIFF(MINUTE,CAST(m.mrUPDATEDATE AS SMALLDATETIME),GETDATE()) / 60) AS VARCHAR) + ':' + RIGHT('00' + RTRIM(CAST((DATEDIFF(MINUTE,CAST(m.mrUPDATEDATE AS SMALLDATETIME),GETDATE()) % 60) AS VARCHAR)),2) Age,
		RIGHT(i.StatusDisplayName,LEN(i.StatusDisplayName) - 12) [Status]
	FROM 
		MASTER4 m
	INNER JOIN
		MASTER4_ISSUESTATUS i
	ON
		i.IssueStatusName = m.mrSTATUS
	WHERE
		m.mrSTATUS IN ('Escalated__b__u__bDevelopment','Escalated__b__u__bCBSW__bDevelopment','Escalated__b__u__bTier__b2')
	ORDER BY
		m.mrUPDATEDATE

	SET NOCOUNT OFF

END
