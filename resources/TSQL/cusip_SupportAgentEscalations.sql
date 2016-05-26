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
		[Status] 'Escalation',
		COUNT(mrid) 'Count'
	FROM (
		SELECT
			m.mrID,
			CAST(m.mrUPDATEDATE AS SMALLDATETIME) [Timestamp],
			CAST((DATEDIFF(MINUTE,CAST(m.mrUPDATEDATE AS SMALLDATETIME),GETDATE()) / 60) AS VARCHAR) + ':' + RIGHT('00' + RTRIM(CAST((DATEDIFF(MINUTE,CAST(m.mrUPDATEDATE AS SMALLDATETIME),GETDATE()) % 60) AS VARCHAR)),2) Age,
			CASE
				WHEN LEFT(i.StatusDisplayName,9) = 'Escalated' THEN RIGHT(i.StatusDisplayName,LEN(i.StatusDisplayName) - 12)
				WHEN i.StatusDisplayName = 'Pending' AND m.Pending__bSub__ustatus = 'Backlog' THEN 'Pend-Backlog'
				WHEN i.StatusDisplayName = 'Pending' AND m.Pending__bSub__ustatus = 'Development' THEN 'Pend-Devel'
				ELSE i.StatusDisplayName
			END [Status]
		FROM
			MASTER4 m
		INNER JOIN
			MASTER4_ISSUESTATUS i
		ON
			i.IssueStatusName = m.mrSTATUS
		WHERE
		(
			m.mrSTATUS IN ('Escalated__b__u__bDevelopment','Escalated__b__u__bCBSW__bDevelopment','Escalated__b__u__bTier__b2','Escalated__b__u__bMgmt')
		OR
			(m.mrSTATUS = 'Pending' AND m.Pending__bSub__ustatus IN ('Backlog','Development'))
		)
		AND
			(mrASSIGNEES LIKE 'Support %' OR mrASSIGNEES LIKE '% Support %')
	) A
	GROUP BY
		[Status]

	SET NOCOUNT OFF

END
