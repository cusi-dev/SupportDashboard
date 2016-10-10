USE [Footprints]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[cusip_SupportAgentMetrics] 
(
	@i_Today SMALLDATETIME
)
AS 
BEGIN
	SET NOCOUNT ON

	DECLARE @Day SMALLDATETIME = @i_Today
	DECLARE @NextDay SMALLDATETIME = DATEADD(day,1,@i_Today)

	DECLARE @mrid INT

	CREATE TABLE #tmpAgentStats
	(
		AgentName VARCHAR(250),
		AgentID VARCHAR(80),
		Resolved INT,
		ResolvedUMS INT,
		ResolvedCBSW INT,
		Assigned INT,
		AssignedUMS INT,
		AssignedCBSW INT,
		Pending INT,
		PendingUMS INT,
		PendingCBSW INT,
		Contracted INT,
		ContractedUMS INT,
		ContractedCBSW INT,
		Escalated INT,
		EscalatedUMS INT,
		EscalatedCBSW INT,
		Reopened INT,
		ReopenedUMS INT,
		ReopenedCBSW INT,
		Inbound INT,
		InboundUMS INT,
		InboundCBSW INT,
		KBArticles INT,
		InProgress INT,
		InProgressUMS INT,
		InProgressCBSW INT
	)
	CREATE TABLE #tmpTicketAssignees
	(
		mrid INT,
		mrASSIGNEES VARCHAR(2000)
	)
	CREATE TABLE #tmpUserTickets
	(
		mrid INT,
		AgentID VARCHAR(80)
	)

	-- Pre-populate with Support reps
	INSERT INTO #tmpAgentStats
	(
		AgentName,
		AgentID
	)
	SELECT 
		u.real_name,
		u.user_id
	FROM 
		users u
    INNER JOIN
        users_support s
    ON
        s.support_user_id = u.user_id
	GROUP BY
		u.user_id,
		u.real_name
	ORDER BY u.real_name


	--
	-- Resolved tickets
	--
	INSERT #tmpTicketAssignees
	SELECT 
		fh.mrid,
		m.mrASSIGNEES
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
		fh.mrNEWFIELDVALUE IN ('Resolved')--,'Closed')
	AND
		fh.mrTIMESTAMP >= @Day
	AND
		fh.mrTIMESTAMP < @NextDay
	AND
		(mrASSIGNEES LIKE 'Support%' OR mrASSIGNEES LIKE '% Support%')
	GROUP BY 
		fh.mrID,
		m.mrASSIGNEES

	DECLARE cResolved CURSOR FOR
	SELECT 
		mrid
	FROM
		#tmpTicketAssignees
	OPEN cResolved

	FETCH NEXT FROM cResolved INTO @mrid
	WHILE @@FETCH_STATUS = 0
	BEGIN
		INSERT INTO 
			#tmpUserTickets
		SELECT
			@mrid,
			user_id 
		FROM 
			users 
		WHERE 
			user_id 
		IN (
			SELECT 
				data 
			FROM 
				dbo.Split(
					(
						SELECT 
							mrASSIGNEES 
						FROM 
							master4 
						WHERE 
							mrid = @mrid
					)
					,' '
				)
		)
		FETCH NEXT FROM cResolved INTO @mrid
	END

	CLOSE cResolved
	DEALLOCATE cResolved

	UPDATE 
		#tmpAgentStats
	SET 
		Resolved = ISNULL(tResolved.aCount,0),
		ResolvedUMS = ISNULL(tResolved.uCount,0),
		ResolvedCBSW = ISNULL(tResolved.cCount,0)
	FROM
		#tmpAgentStats s
	LEFT JOIN
	(
		SELECT 
			t.AgentID,
			COUNT(t.mrid) aCount,
			SUM(
				CASE
					WHEN ab.[Application] = 'UMS' THEN 1 ELSE 0
				END
			) uCount,
			SUM(
				CASE
					WHEN ab.[Application] = 'CBSW' THEN 1 ELSE 0
				END
			) cCount
		FROM 
			#tmpUserTickets t
		INNER JOIN
			MASTER4_ABDATA ab
		ON
			ab.mrID = t.mrid
		GROUP BY
			t.AgentID
	) tResolved
	ON
		tResolved.AgentID = s.AgentID

	--
	-- Clear tables
	--
	DELETE FROM #tmpTicketAssignees
	DELETE FROM #tmpUserTickets

	--
	-- END: Resolved tickets
	--

	--
	-- Assigned tickets
	--
	INSERT #tmpTicketAssignees
	SELECT 
		m.mrid,
		m.mrASSIGNEES
	FROM 
		MASTER4 m
	INNER JOIN
		MASTER4_ABDATA ma
	ON
		m.mrID=ma.mrID
	WHERE 
		m.mrSTATUS IN ('Assigned','Contact__bAttempted','Customer__bReponse','In__bProgress','Open','Open__b__u__bTime__bSensitive','Rollover','Scheduled__bCall')
	AND
		(mrASSIGNEES LIKE 'Support%' OR mrASSIGNEES LIKE '% Support%')
	AND
		m.Contracted__bWork = 'off'
	GROUP BY 
		m.mrID,
		m.mrASSIGNEES

	DECLARE cAssigned CURSOR FOR
	SELECT 
		mrid
	FROM
		#tmpTicketAssignees
	OPEN cAssigned

	FETCH NEXT FROM cAssigned INTO @mrid
	WHILE @@FETCH_STATUS = 0
	BEGIN
		INSERT INTO 
			#tmpUserTickets
		SELECT
			@mrid,
			user_id 
		FROM 
			users 
		WHERE 
			user_id 
		IN (
			SELECT 
				data 
			FROM 
				dbo.Split(
					(
						SELECT 
							mrASSIGNEES 
						FROM 
							master4 
						WHERE 
							mrid = @mrid
					)
					,' '
				)
		)
		FETCH NEXT FROM cAssigned INTO @mrid
	END

	CLOSE cAssigned
	DEALLOCATE cAssigned

	UPDATE 
		#tmpAgentStats
	SET 
		Assigned = ISNULL(tAssigned.aCount,0),
		AssignedUMS = ISNULL(tAssigned.uCount,0),
		AssignedCBSW = ISNULL(tAssigned.cCount,0)
	FROM
		#tmpAgentStats s
	LEFT JOIN
	(
		SELECT 
			t.AgentID,
			COUNT(t.mrid) aCount,
			SUM(
				CASE
					WHEN ab.[Application] = 'UMS' THEN 1 ELSE 0
				END
			) uCount,
			SUM(
				CASE
					WHEN ab.[Application] = 'CBSW' THEN 1 ELSE 0
				END
			) cCount
		FROM 
			#tmpUserTickets t
		INNER JOIN
			MASTER4_ABDATA ab
		ON
			ab.mrID = t.mrid
		GROUP BY
			t.AgentID
	) tAssigned
	ON
		tAssigned.AgentID = s.AgentID
	--
	-- Clear tables
	--
	DELETE FROM #tmpTicketAssignees
	DELETE FROM #tmpUserTickets

	--
	-- END: Assigned tickets
	--

	--
	-- Pending tickets
	--
	INSERT #tmpTicketAssignees
	SELECT 
		m.mrid,
		m.mrASSIGNEES
	FROM 
		MASTER4 m
	INNER JOIN
		MASTER4_ABDATA ma
	ON
		m.mrID=ma.mrID
	WHERE
		(
				m.mrSTATUS IN ('Client__bAcceptance','Deployment','Development')
			AND
				(mrASSIGNEES LIKE 'Support%' OR mrASSIGNEES LIKE '% Support%')
			AND
				m.Contracted__bWork = 'off'
		)
		OR
		(
				m.mrSTATUS = 'Pending'
			AND
				m.Pending__bSub__ustatus NOT IN ('Backlog','Development')
			AND
				(mrASSIGNEES LIKE 'Support%' OR mrASSIGNEES LIKE '% Support%')
			AND
				m.Contracted__bWork = 'off'
		)
	GROUP BY 
		m.mrID,
		m.mrASSIGNEES

	DECLARE cPending CURSOR FOR
	SELECT 
		mrid
	FROM
		#tmpTicketAssignees
	OPEN cPending

	FETCH NEXT FROM cPending INTO @mrid
	WHILE @@FETCH_STATUS = 0
	BEGIN
		INSERT INTO 
			#tmpUserTickets
		SELECT
			@mrid,
			user_id 
		FROM 
			users 
		WHERE 
			user_id 
		IN (
			SELECT 
				data 
			FROM 
				dbo.Split(
					(
						SELECT 
							mrASSIGNEES 
						FROM 
							master4 
						WHERE 
							mrid = @mrid
					)
					,' '
				)
		)
		FETCH NEXT FROM cPending INTO @mrid
	END

	CLOSE cPending
	DEALLOCATE cPending

	UPDATE 
		#tmpAgentStats
	SET 
		Pending = ISNULL(tPending.aCount,0),
		PendingUMS = ISNULL(tPending.uCount,0),
		PendingCBSW = ISNULL(tPending.cCount,0)
	FROM
		#tmpAgentStats s
	LEFT JOIN
	(
		SELECT 
			t.AgentID,
			COUNT(t.mrid) aCount,
			SUM(
				CASE
					WHEN ab.[Application] = 'UMS' THEN 1 ELSE 0
				END
			) uCount,
			SUM(
				CASE
					WHEN ab.[Application] = 'CBSW' THEN 1 ELSE 0
				END
			) cCount
		FROM 
			#tmpUserTickets t
		INNER JOIN
			MASTER4_ABDATA ab
		ON
			ab.mrID = t.mrid
		GROUP BY
			t.AgentID
	) tPending
	ON
		tPending.AgentID = s.AgentID
	--
	-- Clear tables
	--
	DELETE FROM #tmpTicketAssignees
	DELETE FROM #tmpUserTickets

	--
	-- END: Pending tickets
	--

	--
	-- Contracted tickets
	--
	INSERT #tmpTicketAssignees
	SELECT 
		m.mrid,
		m.mrASSIGNEES
	FROM 
		MASTER4 m
	INNER JOIN
		MASTER4_ABDATA ma
	ON
		m.mrID=ma.mrID
	WHERE 
		Contracted__bWork = 'on'
	AND
		m.mrSTATUS NOT IN ('Resolved','Closed','_DELETED_')
	AND
		(mrASSIGNEES LIKE 'Support%' OR mrASSIGNEES LIKE '% Support%')
	GROUP BY 
		m.mrID,
		m.mrASSIGNEES

	DECLARE cContracted CURSOR FOR
	SELECT 
		mrid
	FROM
		#tmpTicketAssignees
	OPEN cContracted

	FETCH NEXT FROM cContracted INTO @mrid
	WHILE @@FETCH_STATUS = 0
	BEGIN
		INSERT INTO 
			#tmpUserTickets
		SELECT
			@mrid,
			user_id 
		FROM 
			users 
		WHERE 
			user_id 
		IN (
			SELECT 
				data 
			FROM 
				dbo.Split(
					(
						SELECT 
							mrASSIGNEES 
						FROM 
							master4 
						WHERE 
							mrid = @mrid
					)
					,' '
				)
		)
		FETCH NEXT FROM cContracted INTO @mrid
	END

	CLOSE cContracted
	DEALLOCATE cContracted

	UPDATE 
		#tmpAgentStats
	SET 
		Contracted = ISNULL(tContracted.aCount,0),
		ContractedUMS = ISNULL(tContracted.uCount,0),
		ContractedCBSW = ISNULL(tContracted.cCount,0)
	FROM
		#tmpAgentStats s
	LEFT JOIN
	(
		SELECT 
			t.AgentID,
			COUNT(t.mrid) aCount,
			SUM(
				CASE
					WHEN ab.[Application] = 'UMS' THEN 1 ELSE 0
				END
			) uCount,
			SUM(
				CASE
					WHEN ab.[Application] = 'CBSW' THEN 1 ELSE 0
				END
			) cCount
		FROM 
			#tmpUserTickets t
		INNER JOIN
			MASTER4_ABDATA ab
		ON
			ab.mrID = t.mrid
		GROUP BY
			t.AgentID
	) tContracted
	ON
		tContracted.AgentID = s.AgentID
	--
	-- Clear tables
	--
	DELETE FROM #tmpTicketAssignees
	DELETE FROM #tmpUserTickets

	--
	-- END: Contracted tickets
	--

	--
	-- Escalated tickets
	--
	INSERT #tmpTicketAssignees
	SELECT 
		m.mrid,
		m.mrASSIGNEES
	FROM 
		MASTER4 m
	INNER JOIN
		MASTER4_ABDATA ma
	ON
		m.mrID=ma.mrID
	WHERE 
		m.mrSTATUS LIKE ('Escalated%')
	AND
		(mrASSIGNEES LIKE 'Support%' OR mrASSIGNEES LIKE '% Support%')
	GROUP BY 
		m.mrID,
		m.mrASSIGNEES

	DECLARE cEscalated CURSOR FOR
	SELECT 
		mrid
	FROM
		#tmpTicketAssignees
	OPEN cEscalated

	FETCH NEXT FROM cEscalated INTO @mrid
	WHILE @@FETCH_STATUS = 0
	BEGIN
		INSERT INTO 
			#tmpUserTickets
		SELECT
			@mrid,
			user_id 
		FROM 
			users 
		WHERE 
			user_id 
		IN (
			SELECT 
				data 
			FROM 
				dbo.Split(
					(
						SELECT 
							mrASSIGNEES 
						FROM 
							master4 
						WHERE 
							mrid = @mrid
					)
					,' '
				)
		)
		FETCH NEXT FROM cEscalated INTO @mrid
	END

	CLOSE cEscalated
	DEALLOCATE cEscalated

	UPDATE 
		#tmpAgentStats
	SET 
		Escalated = ISNULL(tEscalated.aCount,0),
		EscalatedUMS = ISNULL(tEscalated.uCount,0),
		EscalatedCBSW = ISNULL(tEscalated.cCount,0)
	FROM
		#tmpAgentStats s
	LEFT JOIN
	(
		SELECT 
			t.AgentID,
			COUNT(t.mrid) aCount,
			SUM(
				CASE
					WHEN ab.[Application] = 'UMS' THEN 1 ELSE 0
				END
			) uCount,
			SUM(
				CASE
					WHEN ab.[Application] = 'CBSW' THEN 1 ELSE 0
				END
			) cCount
		FROM 
			#tmpUserTickets t
		INNER JOIN
			MASTER4_ABDATA ab
		ON
			ab.mrID = t.mrid
		GROUP BY
			t.AgentID
	) tEscalated
	ON
		tEscalated.AgentID = s.AgentID
	--
	-- Clear tables
	--
	DELETE FROM #tmpTicketAssignees
	DELETE FROM #tmpUserTickets

	--
	-- END: Escalated tickets
	--

	--
	-- Reopened tickets
	--
	INSERT #tmpTicketAssignees
	SELECT 
		fh.mrid,
		m.mrASSIGNEES
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
		fh.mrNEWFIELDVALUE IN ('Reopened')
	AND
		fh.mrTIMESTAMP >= @Day
	AND
		fh.mrTIMESTAMP < @NextDay
	AND
		(mrASSIGNEES LIKE 'Support%' OR mrASSIGNEES LIKE '% Support%')
	GROUP BY 
		fh.mrID,
		m.mrASSIGNEES

	DECLARE cReopened CURSOR FOR
	SELECT 
		mrid
	FROM
		#tmpTicketAssignees
	OPEN cReopened

	FETCH NEXT FROM cReopened INTO @mrid
	WHILE @@FETCH_STATUS = 0
	BEGIN
		INSERT INTO 
			#tmpUserTickets
		SELECT
			@mrid,
			user_id 
		FROM 
			users 
		WHERE 
			user_id 
		IN (
			SELECT 
				data 
			FROM 
				dbo.Split(
					(
						SELECT 
							mrASSIGNEES 
						FROM 
							master4 
						WHERE 
							mrid = @mrid
					)
					,' '
				)
		)
		FETCH NEXT FROM cReopened INTO @mrid
	END

	CLOSE cReopened
	DEALLOCATE cReopened

	UPDATE 
		#tmpAgentStats
	SET 
		Reopened = ISNULL(tReopened.aCount,0),
		ReopenedUMS = ISNULL(tReopened.uCount,0),
		ReopenedCBSW = ISNULL(tReopened.cCount,0)
	FROM
		#tmpAgentStats s
	LEFT JOIN
	(
		SELECT 
			t.AgentID,
			COUNT(t.mrid) aCount,
			SUM(
				CASE
					WHEN ab.[Application] = 'UMS' THEN 1 ELSE 0
				END
			) uCount,
			SUM(
				CASE
					WHEN ab.[Application] = 'CBSW' THEN 1 ELSE 0
				END
			) cCount
		FROM 
			#tmpUserTickets t
		INNER JOIN
			MASTER4_ABDATA ab
		ON
			ab.mrID = t.mrid
		GROUP BY
			t.AgentID
	) tReopened
	ON
		tReopened.AgentID = s.AgentID
	--
	-- Clear tables
	--
	DELETE FROM #tmpTicketAssignees
	DELETE FROM #tmpUserTickets

	--
	-- END: Reopened tickets
	--

	--
	-- Inbound tickets
	--
	INSERT #tmpTicketAssignees
	SELECT 
		fh.mrid,
		m.mrASSIGNEES
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
		fh.mrNEWFIELDVALUE IN ('Resolved')--,'Closed')
	AND
		fh.mrTIMESTAMP >= @Day
	AND
		fh.mrTIMESTAMP < @NextDay
	AND
		(mrASSIGNEES LIKE 'Support%' OR mrASSIGNEES LIKE '% Support%')
	AND
		m.First__bContact__bResolution = 'on'
	GROUP BY 
		fh.mrID,
		m.mrASSIGNEES

	DECLARE cInbound CURSOR FOR
	SELECT 
		mrid
	FROM
		#tmpTicketAssignees
	OPEN cInbound

	FETCH NEXT FROM cInbound INTO @mrid
	WHILE @@FETCH_STATUS = 0
	BEGIN
		INSERT INTO 
			#tmpUserTickets
		SELECT
			@mrid,
			user_id 
		FROM 
			users 
		WHERE 
			user_id 
		IN (
			SELECT 
				data 
			FROM 
				dbo.Split(
					(
						SELECT 
							mrASSIGNEES 
						FROM 
							master4 
						WHERE 
							mrid = @mrid
					)
					,' '
				)
		)
		FETCH NEXT FROM cInbound INTO @mrid
	END

	CLOSE cInbound
	DEALLOCATE cInbound

	UPDATE 
		#tmpAgentStats
	SET 
		Inbound = ISNULL(tInbound.aCount,0),
		InboundUMS = ISNULL(tInbound.uCount,0),
		InboundCBSW = ISNULL(tInbound.cCount,0)
	FROM
		#tmpAgentStats s
	LEFT JOIN
	(
		SELECT 
			t.AgentID,
			COUNT(t.mrid) aCount,
			SUM(
				CASE
					WHEN ab.[Application] = 'UMS' THEN 1 ELSE 0
				END
			) uCount,
			SUM(
				CASE
					WHEN ab.[Application] = 'CBSW' THEN 1 ELSE 0
				END
			) cCount
		FROM 
			#tmpUserTickets t
		INNER JOIN
			MASTER4_ABDATA ab
		ON
			ab.mrID = t.mrid
		GROUP BY
			t.AgentID
	) tInbound
	ON
		tInbound.AgentID = s.AgentID
	--
	-- Clear tables
	--
	DELETE FROM #tmpTicketAssignees
	DELETE FROM #tmpUserTickets

	--
	-- END: Inbound tickets
	--

	--
	-- KB Articles tickets - non-standard query group
	--
	INSERT #tmpTicketAssignees
	SELECT 
		m.mrid,
		m.mrASSIGNEES
	FROM 
		MASTER4 m
	INNER JOIN
		MASTER4_ABDATA ma
	ON
		m.mrID=ma.mrID
	WHERE 
		mrSTATUS IN ('_PENDING_SOLUTION_','_SOLVED_','Draft__bSolution')
	AND 
		datepart(week,mrSUBMITDATE) = datepart(week,getdate())
	AND 
		datepart(year,mrSUBMITDATE) = datepart(year,getdate())	
	GROUP BY 
		m.mrID,
		m.mrASSIGNEES

	DECLARE cKBArticles CURSOR FOR
	SELECT 
		mrid
	FROM
		#tmpTicketAssignees
	OPEN cKBArticles

	FETCH NEXT FROM cKBArticles INTO @mrid
	WHILE @@FETCH_STATUS = 0
	BEGIN
		INSERT INTO 
			#tmpUserTickets
		SELECT
			@mrid,
			user_id 
		FROM 
			users 
		WHERE 
			user_id 
		IN (
			SELECT 
				data 
			FROM 
				dbo.Split(
					(
						SELECT 
							mrSUBMITTER 
						FROM 
							master4 
						WHERE 
							mrid = @mrid
					)
					,' '
				)
		)
		FETCH NEXT FROM cKBArticles INTO @mrid
	END

	CLOSE cKBArticles
	DEALLOCATE cKBArticles

	UPDATE 
		#tmpAgentStats
	SET 
		KBArticles = ISNULL(tKBArticles.aCount,0)
	FROM
		#tmpAgentStats s
	LEFT JOIN
	(
		SELECT 
			t.AgentID,
			COUNT(t.mrid) aCount
		FROM 
			#tmpUserTickets t
		GROUP BY
			t.AgentID
	) tKBArticles
	ON
		tKBArticles.AgentID = s.AgentID
	--
	-- Clear tables
	--
	DELETE FROM #tmpTicketAssignees
	DELETE FROM #tmpUserTickets

	--
	-- END: KB Articles tickets - non-standard
	--

	--
	-- In Progress tickets
	--
	INSERT #tmpTicketAssignees
	SELECT 
		m.mrid,
		m.mrASSIGNEES
	FROM 
		MASTER4 m
	INNER JOIN
		MASTER4_ABDATA ma
	ON
		m.mrID=ma.mrID
	WHERE 
		m.mrSTATUS IN ('In__bProgress')
	AND
		(mrASSIGNEES LIKE 'Support%' OR mrASSIGNEES LIKE '% Support%')
	AND
		m.Contracted__bWork = 'off'
	GROUP BY 
		m.mrID,
		m.mrASSIGNEES

	DECLARE cInProgress CURSOR FOR
	SELECT 
		mrid
	FROM
		#tmpTicketAssignees
	OPEN cInProgress

	FETCH NEXT FROM cInProgress INTO @mrid
	WHILE @@FETCH_STATUS = 0
	BEGIN
		INSERT INTO 
			#tmpUserTickets
		SELECT
			@mrid,
			user_id 
		FROM 
			users 
		WHERE 
			user_id 
		IN (
			SELECT 
				data 
			FROM 
				dbo.Split(
					(
						SELECT 
							mrASSIGNEES 
						FROM 
							master4 
						WHERE 
							mrid = @mrid
					)
					,' '
				)
		)
		FETCH NEXT FROM cInProgress INTO @mrid
	END

	CLOSE cInProgress
	DEALLOCATE cInProgress

	UPDATE 
		#tmpAgentStats
	SET 
		InProgress = ISNULL(tInProgress.aCount,0),
		InProgressUMS = ISNULL(tInProgress.uCount,0),
		InProgressCBSW = ISNULL(tInProgress.cCount,0)
	FROM
		#tmpAgentStats s
	LEFT JOIN
	(
		SELECT 
			t.AgentID,
			COUNT(t.mrid) aCount,
			SUM(
				CASE
					WHEN ab.[Application] = 'UMS' THEN 1 ELSE 0
				END
			) uCount,
			SUM(
				CASE
					WHEN ab.[Application] = 'CBSW' THEN 1 ELSE 0
				END
			) cCount
		FROM 
			#tmpUserTickets t
		INNER JOIN
			MASTER4_ABDATA ab
		ON
			ab.mrID = t.mrid
		GROUP BY
			t.AgentID
	) tInProgress
	ON
		tInProgress.AgentID = s.AgentID
	--
	-- Clear tables
	--
	DELETE FROM #tmpTicketAssignees
	DELETE FROM #tmpUserTickets

	--
	-- END: In Progress tickets
	--

	SELECT * FROM #tmpAgentStats

	DROP TABLE #tmpTicketAssignees
	DROP TABLE #tmpUserTickets
	DROP TABLE #tmpAgentStats

	SET NOCOUNT OFF
END
