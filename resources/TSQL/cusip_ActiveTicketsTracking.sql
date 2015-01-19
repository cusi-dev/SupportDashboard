CREATE PROCEDURE [dbo].[cusip_ActiveTicketsTracking]
AS
BEGIN
  SELECT TOP (20)
    ActiveTickets
  FROM
    [tblCusiMetricsActiveTickets]
  ORDER BY
    [DateCaptured]
  DESC

  SELECT
    COUNT(*) AS CurrentTickets
  FROM
    MASTER4 m
  WHERE
    m.mrSTATUS NOT IN ('Closed','Resolved', '_DELETED_', 'Client__bAcceptance', 'Contracted__bWork', 'Development', 'Pending','Escalated__b__u__bDevelopment','Escalated__b__u__bCBSW__bDevelopment')
    AND m.mrASSIGNEES LIKE 'Support%'
    AND NOT m.Scheduled__bCall > GETDATE()
END
