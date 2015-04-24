#Get Environment Specific Values
$dashboardURL = [Environment]::GetEnvironmentVariable("DASHBOARD_URL","Machine")
$authToken = [Environment]::GetEnvironmentVariable("DASHBOARD_AUTH_TOKEN","Machine")
$SqlInstance = [Environment]::GetEnvironmentVariable("DASHBOARD_SQL_INSTANCE","Machine")
$DatabaseName = [Environment]::GetEnvironmentVariable("DASHBOARD_DATABASE_NAME","Machine")
$SqlUserName = [Environment]::GetEnvironmentVariable("DASHBOARD_DATABASE_USERNAME","Machine")
$SqlPassword = [Environment]::GetEnvironmentVariable("DASHBOARD_DATABASE_PASSWORD","Machine")

#Build the SQL Server Connection String
$connStr = "Server=$($SqlInstance);Initial Catalog=$($DatabaseName);User Id=$($SqlUserName);Password=$($SqlPassword);"

#Query cusip_SupportMetrics
$Date = Get-Date -Format d
$conn = New-Object System.Data.SqlClient.SqlConnection $connStr
$conn.Open()
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "exec [cusip_SupportMetrics] @i_Today = '$Date', @i_Period='DAY'"
$SqlCmd.Connection = $conn
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)
$conn.Close()

#Assign results
$AllTickets = $DataSet.Tables[0].Select("GroupName='ALL'")
$UMSTickets = $DataSet.Tables[0].Select("GroupName='UMS'")
$CBSWTickets = $DataSet.Tables[0].Select("GroupName='CBSW'")

#
#SLA Under 30 widget
#
$sla30c = $CBSWTickets.SLA30
$sla30u = $UMSTickets.SLA30
$sla30 = "[
  {
    ""label"" : ""CBSW"",
    ""value"" : $sla30c
  },
  {
    ""label"" : ""UMS"",
    ""value"" : $sla30u
  }
]"
$url = "$($dashboardURL)/widgets/sla30"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""value"" : $sla30
}"

(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

#
#SLA Under 60 widget
#
$sla60c = $CBSWTickets.SLA60
$sla60u = $UMSTickets.SLA60
$sla60 = "[
  {
    ""label"" : ""CBSW"",
    ""value"" : $sla60c
  },
  {
    ""label"" : ""UMS"",
    ""value"" : $sla60u
  }
]"
$url = "$($dashboardURL)/widgets/sla60"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""value"" : $sla60
}"

(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

#
#SLA Over 60 widget
#
$sla61c = $CBSWTickets.SLA61
$sla61u = $UMSTickets.SLA61
$sla61 = "[
  {
    ""label"" : ""CBSW"",
    ""value"" : $sla61c
  },
  {
    ""label"" : ""UMS"",
    ""value"" : $sla61u
  }
]"
$url = "$($dashboardURL)/widgets/sla90"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""value"" : $sla61
}"

(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

#
#UMS tickets widget
#
$url = "$($dashboardURL)/widgets/umsopentickets"
$ums = "[
  {
    ""label"" : ""< 30"",
    ""value"" : $sla30u
  },
  {
    ""label"" : ""< 60"",
    ""value"" : $sla60u
  },
  {
    ""label"" : ""60+"",
    ""value"" : $sla61u
  }
]"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""value"" : $ums
}"
(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

#
#CBSW tickets widget
#
$url = "$($dashboardURL)/widgets/cbswopentickets"
$cbsw = "[
  {
    ""label"" : ""< 30"",
    ""value"" : $sla30c
  },
  {
    ""label"" : ""< 60"",
    ""value"" : $sla60c
  },
  {
    ""label"" : ""60+"",
    ""value"" : $sla61c
  }
]"

$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""value"" : $cbsw
}"
(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

#
#Inbound tickets widget
#
$inb = $AllTickets.InboundTickets
$closed = $AllTickets.ClosedTickets
$noninb = $closed - $inb
$url = "$($dashboardURL)/widgets/inbound"
$points = "[
    {
        ""label"" : ""Inbound"",
        ""value"" : $inb
    },
    {
        ""label"" : ""Non"",
        ""value"" : $noninb
    }
]"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""value"" : $points
}"
(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

#
#Response time widget
#
$art = $AllTickets.AverageResponseTime
$url = "$($dashboardURL)/widgets/averageresponsetime"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""value"" : $art
}"

(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

#
#New tickets today widget
#
$newtickets = $AllTickets.NewTickets
$url = "$($dashboardURL)/widgets/newtickets"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""current"" : $newtickets
}"
(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

#
#Wait time widget
#
$conn.Open()
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "exec [cusip_SupportResponseTime]"
$SqlCmd.Connection = $conn
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet) | Out-Null
$conn.Close()

$waittime = $DataSet.Tables[0].Rows[0][0]
$url = "$($dashboardURL)/widgets/waittime"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""value"" : ""$waittime""
}"
(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

#
#Active tickets today widget
#
$conn.Open()
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "exec [cusip_ActiveTickets]"
$SqlCmd.Connection = $conn
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)
$conn.Close()

$active = $DataSet.Tables[0].Rows[0][0]
$url = "$($dashboardURL)/widgets/active"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""value"" : ""$active""
}"
(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

#
#Open tickets widget
#
$conn.Open()
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "exec [cusip_UnhandledTickets]"
$SqlCmd.Connection = $conn
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)
$conn.Close()

$unhandled = $DataSet.Tables[0].Rows[0][0]
$url = "$($dashboardURL)/widgets/unhandled"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""value"" : ""$unhandled""
}"
(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json


#
# AGENT DASHBOARD
#

#Query 
$conn = New-Object System.Data.SqlClient.SqlConnection $connStr
$conn.Open()
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "exec [cusip_SupportAgentMetrics] @i_Today = '$Date'"
$SqlCmd.Connection = $conn
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)
$conn.Close()

#Assign results
$rows = $DataSet.Tables[0].Rows


#
# CONTRACTED
#
$i = 0 
$pb2h2 = "
[ 
    {""cols"" : 
        [ 
            {""class"" : ""contractedtabletablehdr1"", ""value"" : ""Agent""}, 
            {""class"" : ""contractedtabletablehdr2"", ""value"" : ""Count""}
        ] 
    }
]
"
$pb2r2 = "["
foreach ($row in $rows)
{
    $i += 1
    if ($row[11] -ne 0)
        {
        $pb2r2 += "
            { ""cols"" : 
                [
                    {""class"" : ""contractedtabletablecol1"", ""value"" : ""$($row[0])""}, 
                    {""class"" : ""contractedtabletablecol2"", ""value"" : ""$($row[11])""}
                ]
            }
        "
        if ($i -lt $rows.Count)
        {
            $pb2r2 += ","
        }
    }
}
$pb2r2  = $pb2r2.TrimEnd(',')
$pb2r2 += "]"
$url2 = "$($dashboardURL)/widgets/contractedtable"
$json2 = "{
    ""auth_token"" : ""$($authToken)"",
    ""hrows"" : $pb2h2,
    ""rows"" : $pb2r2
}"

(Invoke-WebRequest -Uri $url2 -Method Post -Body $json2).content | ConvertFrom-Json




#
# PENDING
#
$i = 0
$pb2 = "["
foreach ($row in $rows)
{
    $i += 1
    $pb2 += "
        { 
            ""label"" : ""$($row[0])"",
            ""value"" :  $($row[8])
        }
    "
    if ($i -lt $rows.Count)
    {
        $pb2 += ","
    }
}
$pb2 += "]"
$url2 = "$($dashboardURL)/widgets/pending"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""data"" : $pb2
}"

(Invoke-WebRequest -Uri $url2 -Method Post -Body $json).content | ConvertFrom-Json


#
# RESOLVED
#
$i = 0
$pb3 = "["
foreach ($row in $rows)
{
    $i += 1
    $pb3 += "
        { 
            ""label"" : ""$($row[0])"",
            ""value"" :  $($row[2])
        }
    "
    if ($i -lt $rows.Count)
    {
        $pb3 += ","
    }
}
$pb3 += "]"
$url3 = "$($dashboardURL)/widgets/resolved"
$json3 = "{
    ""auth_token"" : ""$($authToken)"",
    ""data"" : $pb3
}"

(Invoke-WebRequest -Uri $url3 -Method Post -Body $json3).content | ConvertFrom-Json

$i = 0
$pb3c = "["
foreach ($row in $rows)
{
    $i += 1
    $pb3c += "
        { 
            ""label"" : ""$($row[0])"",
            ""value"" :  $($row[4])
        }
    "
    if ($i -lt $rows.Count)
    {
        $pb3c += ","
    }
}
$pb3c += "]"
$url3c = "$($dashboardURL)/widgets/resolvedc"
$json3c = "{
    ""auth_token"" : ""$($authToken)"",
    ""data"" : $pb3c
}"

(Invoke-WebRequest -Uri $url3c -Method Post -Body $json3c).content | ConvertFrom-Json

$i = 0
$pb3u = "["
foreach ($row in $rows)
{
    $i += 1
    $pb3u += "
        { 
            ""label"" : ""$($row[0])"",
            ""value"" :  $($row[3])
        }
    "
    if ($i -lt $rows.Count)
    {
        $pb3u += ","
    }
}
$pb3u += "]"
$url3u = "$($dashboardURL)/widgets/resolvedu"
$json3u = "{
    ""auth_token"" : ""$($authToken)"",
    ""data"" : $pb3u
}"

(Invoke-WebRequest -Uri $url3u -Method Post -Body $json3u).content | ConvertFrom-Json

#
# ASSIGNED
#
$i = 0
$pb4 = "["
foreach ($row in $rows)
{
    $i += 1
    $pb4 += "
        { 
            ""label"" : ""$($row[0])"",
            ""value"" :  $($row[5])
        }
    "
    if ($i -lt $rows.Count)
    {
        $pb4 += ","
    }
}
$pb4 += "]"

$url = "$($dashboardURL)/widgets/assigned"
$json = "{
    ""auth_token"" : ""$($authToken)"",
    ""data"" : $pb4
}"

(Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

#
# LASTSTATUS
#
#Query 
$conn = New-Object System.Data.SqlClient.SqlConnection $connStr
$conn.Open()
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "exec [cusip_SupportAgentLastStatus] @i_ExcludeTier2=1"
$SqlCmd.Connection = $conn
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)
$conn.Close()

#Assign results
$rows = $DataSet.Tables[0].Rows

$i = 0 
$pb1h1 = "
[ 
    {""cols"" : 
        [ 
            {""class"" : ""statustabletablehdr1"", ""value"" : ""Agent""}, 
            {""class"" : ""statustabletablehdr2"", ""value"" : ""Age (h:m)""},
            {""class"" : ""statustabletablehdr3"", ""value"" : ""Ticket""},
            {""class"" : ""statustabletablehdr4"", ""value"" : ""Status""} 
        ] 
    }
]
"
$pb1r1 = "["
foreach ($row in $rows)
{
    $i += 1
    $pb1r1 += "
        { ""cols"" : 
            [
                {""class"" : ""statustabletablecol1"", ""value"" : ""$($row[0])""}, 
                {""class"" : ""statustabletablecol2"", ""value"" : ""$($row[3])""},
                {""class"" : ""statustabletablecol3"", ""value"" : ""$($row[1])""}, 
                {""class"" : ""statustabletablecol4"", ""value"" : ""$($row[4])""}
            ]
        }
    "
    if ($i -lt $rows.Count)
    {
        $pb1r1 += ","
    }
}
$pb1r1 += "]"
$url1 = "$($dashboardURL)/widgets/laststatustable"
$json1 = "{
    ""auth_token"" : ""$($authToken)"",
    ""hrows"" : $pb1h1,
    ""rows"" : $pb1r1
}"

(Invoke-WebRequest -Uri $url1 -Method Post -Body $json1).content | ConvertFrom-Json

#
# Escalations
#
$conn = New-Object System.Data.SqlClient.SqlConnection $connStr
$conn.Open()
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "exec [cusip_SupportAgentEscalations]"
$SqlCmd.Connection = $conn
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)
$conn.Close()

#Assign results
$rows = $DataSet.Tables[0].Rows


$i = 0 
$pb3h3 = "
[ 
    {""cols"" : 
        [ 
            {""class"" : ""escalatedtabletablehdr1"", ""value"" : ""Ticket""}, 
            {""class"" : ""escalatedtabletablehdr2"", ""value"" : ""Age (h:m)""},
            {""class"" : ""escalatedtabletablehdr3"", ""value"" : ""Status""} 
        ] 
    }
]
"
$pb3r3 = "["
foreach ($row in $rows)
{
    $i += 1
    $pb3r3 += "
        { ""cols"" : 
            [
                {""class"" : ""escalatedtabletablecol1"", ""value"" : ""$($row[0])""}, 
                {""class"" : ""escalatedtabletablecol2"", ""value"" : ""$($row[2])""},
                {""class"" : ""escalatedtabletablecol3"", ""value"" : ""$($row[3])""}
            ]
        }
    "
    if ($i -lt $rows.Count)
    {
        $pb3r3 += ","
    }
}
$pb3r3 += "]"
$url3 = "$($dashboardURL)/widgets/escalatedtable"
$json3 = "{
    ""auth_token"" : ""$($authToken)"",
    ""hrows"" : $pb3h3,
    ""rows"" : $pb3r3
}"

(Invoke-WebRequest -Uri $url3 -Method Post -Body $json3).content | ConvertFrom-Json


#
# AGENT2
#

#Query 
$Date = Get-Date -Format d
$conn = New-Object System.Data.SqlClient.SqlConnection $connStr
$conn.Open()
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
#$SqlCmd.CommandText = "exec [cusip_SupportAgentMetrics] @i_Today = '2015-04-01'"#'$Date'"
$SqlCmd.CommandText = "exec [cusip_SupportAgentMetrics] @i_Today = '$Date'"
$SqlCmd.Connection = $conn
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)
$conn.Close()

#Assign results
$rows = $DataSet.Tables[0].Rows

$i = 0
#
# AGENT LOOP
#
foreach ($row in $rows)
{
    $i += 1

    $agentname = $row[0]
    $url = "$($dashboardURL)/widgets/agent$($i)name"
    $json = "{
        ""auth_token"" : ""$($authToken)"",
        ""text"" : ""$agentname""
    }"
    (Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

    $inprogress = $row[24]
    $url = "$($dashboardURL)/widgets/agent$($i)inprogress"
    $json = "{
        ""auth_token"" : ""$($authToken)"",
        ""value"" : ""$inprogress""
    }"
    (Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

    $assigned = $row[5] - $row[24]
    $url = "$($dashboardURL)/widgets/agent$($i)assigned"
    $json = "{
        ""auth_token"" : ""$($authToken)"",
        ""value"" : ""$assigned""
    }"
    (Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

    $pending = $row[8] - $row[14]
    $url = "$($dashboardURL)/widgets/agent$($i)pending"
    $json = "{
        ""auth_token"" : ""$($authToken)"",
        ""value"" : ""$pending""
    }"
    (Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

    $escalated = $row[14]
    $url = "$($dashboardURL)/widgets/agent$($i)escalated"
    $json = "{
        ""auth_token"" : ""$($authToken)"",
        ""value"" : ""$escalated""
    }"
    (Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

    $contracted = $row[11]
    $url = "$($dashboardURL)/widgets/agent$($i)contracted"
    $json = "{
        ""auth_token"" : ""$($authToken)"",
        ""value"" : ""$contracted""
    }"
    (Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json

    $resolved = $row[2]
    $url = "$($dashboardURL)/widgets/agent$($i)resolved"
    $json = "{
        ""auth_token"" : ""$($authToken)"",
        ""value"" : ""$resolved""
    }"
    (Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json
    $resolvedu = $row[3]
    $url = "$($dashboardURL)/widgets/agent$($i)resolvedu"
    $json = "{
        ""auth_token"" : ""$($authToken)"",
        ""current"" : ""$resolvedu""
    }"
    (Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json
    $resolvedc = $row[4]
    $url = "$($dashboardURL)/widgets/agent$($i)resolvedc"
    $json = "{
        ""auth_token"" : ""$($authToken)"",
        ""current"" : ""$resolvedc""
    }"
    (Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json
}

# LAST UPDATE
$conn = New-Object System.Data.SqlClient.SqlConnection $connStr
$conn.Open()
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "exec [cusip_SupportAgentLastStatus] @i_ExcludeTier2=0"
$SqlCmd.Connection = $conn
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)
$conn.Close()

#Assign results
$rows = $DataSet.Tables[0].Rows
$rows = $rows | Sort-Object real_name
$i = 0
foreach ($row in $rows)
{
    $i += 1

    $updateage = $row[5]
    $url = "$($dashboardURL)/widgets/agent$($i)updateage"
    $json = "{
        ""auth_token"" : ""$($authToken)"",
        ""text"" : ""$updateage""
    }"
    (Invoke-WebRequest -Uri $url -Method Post -Body $json).content | ConvertFrom-Json
}
