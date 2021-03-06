CREATE PROCEDURE [dbo].[cusip_ActiveTickets]
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
    EXEC [dbo].[cusip_ActiveTicketsSummary]

    SELECT
        COUNT(*) AS CurrentTickets
    FROM
        @m_ActiveTickets

    IF @i_Dashboard <> 1
    BEGIN
        SELECT
            m.*
        FROM
            MASTER4 m
        INNER JOIN
            @m_ActiveTickets t
        ON
            t.mrID = m.mrID
    END
END
