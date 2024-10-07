# Parameters
param(
    [string]$SqlServerInstance = "localhost", # Replace with your SQL Server instance
    [string]$Database = "YourDatabase", # Replace with your database name
    [string]$SqlQuery = "SELECT 1", # Replace with your test query
    [int]$NumberOfThreads = 10, # Number of parallel threads
    [int]$TestDurationInSeconds = 60 # Duration of the test in seconds
)

# Load the SQL Server module
Import-Module SqlServer

# Function to execute SQL query
function Execute-SqlQuery {
    param (
        [string]$Instance,
        [string]$DbName,
        [string]$Query
    )

    try {
        # Open a connection to the SQL Server
        $connectionString = "Server=$Instance;Database=$DbName;Integrated Security=True;"
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionString
        $command = New-Object System.Data.SqlClient.SqlCommand $Query, $connection

        # Open the connection and execute the query
        $connection.Open()
        $command.ExecuteNonQuery()
        $connection.Close()
    }
    catch {
        Write-Host "Error executing query: $($_.Exception.Message)"
    }
}

# Create an array of background jobs for parallel execution
$jobs = @()
$startTime = Get-Date

while ((Get-Date) - $startTime).TotalSeconds -lt $TestDurationInSeconds {
    for ($i = 0; $i -lt $NumberOfThreads; $i++) {
        $jobs += Start-Job -ScriptBlock {
            param($server, $database, $query)
            Execute-SqlQuery -Instance $server -DbName $database -Query $query
        } -ArgumentList $SqlServerInstance, $Database, $SqlQuery
    }
    Start-Sleep -Seconds 1
}

# Wait for all jobs to finish
$jobs | ForEach-Object { 
    $_ | Wait-Job 
}

# Clean up completed jobs
$jobs | ForEach-Object { 
    Remove-Job $_ 
}

Write-Host "SQL Stress Test completed."


<#
For test:
.\SqlStressTest.ps1 -SqlServerInstance "YourServer" -Database "YourDatabase" -SqlQuery "SELECT * FROM YourTable" -NumberOfThreads 20 -TestDurationInSeconds 120
#>
