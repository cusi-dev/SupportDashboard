CREATE PROCEDURE [dbo].[cusip_ActiveTicketsSummary]
(
    @i_Dashboard BIT = 1
)
AS
BEGIN

    DECLARE @m_ActiveTickets TABLE
    (
        mrID INT
    )

    INSERT @m_ActiveTickets
    SELECT
        m.mrID
    FROM 
        MASTER4 m
    WHERE 
        m.mrSTATUS NOT IN (
            'Closed',
            'Resolved',
            '_DELETED_',
            'Client__bAcceptance',
            'Contracted__bWork',
            'Development',
            'Pending',
            'Escalated__b__u__bDevelopment',
            'Escalated__b__u__bCBSW__bDevelopment',
            'Escalated__b__u__bMgmt',
            'Escalated__b__u__bPayment__bServices',
            'Escalated__b__u__bTier__b2'
        )
    AND
        (mrASSIGNEES LIKE 'Support%' OR mrASSIGNEES LIKE '% Support%')
    AND
        NOT m.Scheduled__bCall >= DATEADD(d,1,CAST(GETDATE() AS DATE))

    IF @i_Dashboard = 1
    BEGIN
        SELECT * FROM @m_ActiveTickets ORDER BY 1
    END
    ELSE
    BEGIN
        SELECT
            COUNT(t.mrID) StatusCount,
            REPLACE(REPLACE(m.mrSTATUS,'__b',' '),'__u','-') ConvertedStatus
        FROM
            @m_ActiveTickets t
        INNER JOIN
            MASTER4 m
        ON
            m.mrID = t.mrID
        GROUP BY
            m.mrSTATUS
        ORDER BY
            COUNT(t.mrID) DESC
    END

END
