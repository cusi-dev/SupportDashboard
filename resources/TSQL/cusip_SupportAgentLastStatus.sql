USE [Footprints]
GO
/****** Object:  StoredProcedure [dbo].[cusip_SupportAgentLastStatus]    Script Date: 4/24/2015 8:41:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[cusip_SupportAgentLastStatus] 
(
	@i_ExcludeTier2 BIT 
)
AS
BEGIN
	SET NOCOUNT ON

	SELECT 
		a.real_name,
		ts.mrID,
		CAST(ts.mrTIMESTAMP AS SMALLDATETIME) [Timestamp],
		CAST((DATEDIFF(MINUTE,CAST(ts.mrTIMESTAMP AS SMALLDATETIME),GETDATE()) / 60) AS VARCHAR) + ':' + RIGHT('00' + RTRIM(CAST((DATEDIFF(MINUTE,CAST(ts.mrTIMESTAMP AS SMALLDATETIME),GETDATE()) % 60) AS VARCHAR)),2) Age,
		i.StatusDisplayName [Status],
		DATEDIFF(MINUTE,CAST(ts.mrTIMESTAMP AS SMALLDATETIME),GETDATE()) AgeMinutes
	FROM 
	(
		SELECT 
			u.real_name,
			u.user_id
		FROM 
			users u
		WHERE 
			u.user_type 
		IN 
			('4','2')
		AND 
			u.default_project = 4
		AND 
			user_id NOT IN ('administrator','cshort')
		-- Exclude specific users from displaying in this widget 
		AND (
			(@i_ExcludeTier2 = 1 AND user_id NOT IN ('jperryman','nmathes','tscrape','pzenko'))
			OR
			(@i_ExcludeTier2 = 0)
		)
		--
		GROUP BY
			u.user_id,
			u.real_name
	) a
	CROSS APPLY
	(
		SELECT 
			TOP 1 *
		FROM
			MASTER4_FIELDHISTORY
		WHERE
			mrUSERID = a.user_id
		AND
			mrFIELDNAME = 'mrSTATUS'
		ORDER BY 
			mrTIMESTAMP DESC
	) ts
	INNER JOIN
		MASTER4_ISSUESTATUS i
	ON
		i.IssueStatusName = ts.mrNEWFIELDVALUE
	ORDER BY
		ts.mrTIMESTAMP, a.real_name

	SET NOCOUNT OFF

END
