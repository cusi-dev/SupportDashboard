CREATE TABLE [dbo].[tblCusiMetricsActiveTickets](
  [id] [bigint] IDENTITY(1,1) NOT NULL,
  [ActiveTickets] [smallint] NOT NULL,
  [DateCaptured] [datetime2](7) NOT NULL,
  PRIMARY KEY CLUSTERED
  (
    [id] ASC
  )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
