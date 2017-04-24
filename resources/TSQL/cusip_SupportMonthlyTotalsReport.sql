USE [Footprints]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[cusip_SupportMonthlyTotalsReport]

AS

BEGIN

CREATE TABLE #tmpMonthlyNewTickets
(
    MonthNumber INT,
    MonthAbbv NVARCHAR(20),
    YearNumber INT,
    TicketCount INT,
    UMSCount INT,
    CBSWCount INT,
    ResponseTime INT,
    SLA60 INT,
    InboundTickets INT DEFAULT 0,
    ChatTickets INT DEFAULT 0,
    EmailTickets INT DEFAULT 0
)

INSERT INTO #tmpMonthlyNewTickets
(
    MonthNumber,
    MonthAbbv,
    YearNumber,
    TicketCount,
    UMSCount,
    CBSWCount
)
SELECT
    DATEPART(MONTH,m.mrSUBMITDATE) tMonthNo,
    CONVERT(CHAR(3),m.mrSUBMITDATE,0) tMonth,
    DATEPART(YEAR,m.mrSUBMITDATE) tYear,
    COUNT(m.mrID) tCount,
    SUM(
        CASE
            WHEN a.Application = 'UMS' THEN 1
            ELSE 0
        END
    ),
    SUM(
        CASE
            WHEN a.Application = 'CBSW' THEN 1
            ELSE 0
        END
    )
FROM
    master4 m
INNER JOIN
    MASTER4_ABDATA a
ON
    a.mrID=m.mrID
WHERE
    m.mrSTATUS NOT IN (
        '_DELETED_',
        '_PENDING_SOLUTION_',
        '_SOLVED_',
        'Draft__bSolution'
    )
AND
    (mrASSIGNEES LIKE 'Support%' OR mrASSIGNEES LIKE '% Support%')
GROUP BY
    DATEPART(YEAR,m.mrSUBMITDATE),DATEPART(MONTH,m.mrSUBMITDATE),CONVERT(CHAR(3),m.mrSUBMITDATE,0)
ORDER BY
    tYear, tMonth

UPDATE
    #tmpMonthlyNewTickets
SET
    InboundTickets = ISNULL(A.InboundTickets, 0)
FROM
(
    SELECT
        COUNT(mrID) InboundTickets,
        DATEPART(MONTH,mrTIMESTAMP) tMonth,
        DATEPART(YEAR,mrTIMESTAMP) tYear
    FROM
    (
        SELECT 
            fh.mrID,
            MIN(fh.mrTIMESTAMP) mrTIMESTAMP
        FROM 
            MASTER4_FIELDHISTORY fh
        INNER JOIN 
            MASTER4 m
        ON 
            m.mrID = fh.mrID
        INNER JOIN
            MASTER4_ABDATA ma
        ON
            m.mrID = ma.mrID
        WHERE 
            fh.mrFIELDNAME = 'mrStatus'
        AND
            fh.mrNEWFIELDVALUE = 'Closed'
        AND
            m.First__bContact__bResolution = 'on'
        AND
            m.mrSTATUS <> '_DELETED_'
        AND
            (m.mrASSIGNEES LIKE 'Support%' OR m.mrASSIGNEES LIKE '% Support%')
        GROUP BY
            fh.mrID
    ) B
    GROUP BY
        DATEPART(MONTH,mrTIMESTAMP),
        DATEPART(YEAR,mrTIMESTAMP)
) A
WHERE
    A.tMonth = #tmpMonthlyNewTickets.MonthNumber
AND
    A.tYear = #tmpMonthlyNewTickets.YearNumber

UPDATE
    #tmpMonthlyNewTickets
SET
    ChatTickets = ISNULL(A.ChatTickets, 0)
FROM
(
    SELECT
        COUNT(mrID) ChatTickets,
        DATEPART(MONTH,mrTIMESTAMP) tMonth,
        DATEPART(YEAR,mrTIMESTAMP) tYear
    FROM
    (
        SELECT 
            fh.mrID,
            MIN(fh.mrTIMESTAMP) mrTIMESTAMP
        FROM 
            MASTER4_FIELDHISTORY fh
        INNER JOIN 
            MASTER4 m
        ON 
            m.mrID = fh.mrID
        INNER JOIN
            MASTER4_ABDATA ma
        ON
            m.mrID = ma.mrID
        WHERE 
            fh.mrFIELDNAME = 'mrStatus'
        AND
            fh.mrNEWFIELDVALUE = 'Closed'
        AND
            m.Chat__bResolution = 'on'
        AND
            m.mrSTATUS <> '_DELETED_'
        AND
            (m.mrASSIGNEES LIKE 'Support%' OR m.mrASSIGNEES LIKE '% Support%')
        GROUP BY
            fh.mrID
    ) B
    GROUP BY
        DATEPART(MONTH,mrTIMESTAMP),
        DATEPART(YEAR,mrTIMESTAMP)
) A
WHERE
    A.tMonth = #tmpMonthlyNewTickets.MonthNumber
AND
    A.tYear = #tmpMonthlyNewTickets.YearNumber

UPDATE
    #tmpMonthlyNewTickets
SET
    EmailTickets = ISNULL(A.EmailTickets, 0)
FROM
(
    SELECT
        COUNT(mrID) EmailTickets,
        DATEPART(MONTH,mrTIMESTAMP) tMonth,
        DATEPART(YEAR,mrTIMESTAMP) tYear
    FROM
    (
        SELECT 
            fh.mrID,
            MIN(fh.mrTIMESTAMP) mrTIMESTAMP
        FROM 
            MASTER4_FIELDHISTORY fh
        INNER JOIN 
            MASTER4 m
        ON 
            m.mrID = fh.mrID
        INNER JOIN
            MASTER4_ABDATA ma
        ON
            m.mrID = ma.mrID
        WHERE 
            fh.mrFIELDNAME = 'mrStatus'
        AND
            fh.mrNEWFIELDVALUE = '_REQUEST_'
        AND
            fh.mrOLDFIELDVALUE IS NULL
        AND
            m.mrSTATUS <> '_DELETED_'
        AND
            (m.mrASSIGNEES LIKE 'Support%' OR m.mrASSIGNEES LIKE '% Support%')
        GROUP BY
            fh.mrID
    ) B
    GROUP BY
        DATEPART(MONTH,mrTIMESTAMP),
        DATEPART(YEAR,mrTIMESTAMP)
) A
WHERE
    A.tMonth = #tmpMonthlyNewTickets.MonthNumber
AND
    A.tYear = #tmpMonthlyNewTickets.YearNumber

SELECT
    MonthAbbv,
    YearNumber,
    TicketCount,
    UMSCount,
    CBSWCount,
    InboundTickets,
    ChatTickets,
    EmailTickets
FROM
    #tmpMonthlyNewTickets
ORDER BY
    YearNumber, MonthNumber

DROP TABLE #tmpMonthlyNewTickets

END
