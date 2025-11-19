function Parse-OsqueryResults {
    <#
    .SYNOPSIS
        Parses osquery results log file into structured data.

    .DESCRIPTION
        Reads osquery results log (JSON lines format) and returns a hashtable
        indexed by query name for easy lookup during compliance assessment.

    .PARAMETER Path
        Path to osquery results log file.

    .OUTPUTS
        Hashtable with query results indexed by query name
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_})]
        [string]$Path
    )

    try {
        $results = @{}
        $lineNumber = 0

        Get-Content -Path $Path | ForEach-Object {
            $lineNumber++
            $line = $_.Trim()

            # Skip empty lines
            if ([string]::IsNullOrWhiteSpace($line)) {
                return
            }

            try {
                $json = $_ | ConvertFrom-Json

                # osquery results have a 'name' field for the query name
                if ($json.name) {
                    $queryName = $json.name

                    # Normalize query name: strip pack prefix if present
                    # osquery packs add prefix like: pack_nist_configuration_management_cm_startup_items
                    # We need to extract just: cm_startup_items
                    if ($queryName -match '^pack_nist_[^_]+_(.+)$') {
                        $queryName = $matches[1]
                        Write-Verbose "Normalized query name: $($json.name) -> $queryName"
                    }

                    if (-not $results.ContainsKey($queryName)) {
                        $results[$queryName] = @{
                            QueryName = $queryName
                            OriginalName = $json.name
                            Results = @()
                            LatestTimestamp = $json.unixTime
                            HostIdentifier = $json.hostIdentifier
                        }
                    }

                    # Add this result to the query's results array
                    if ($json.columns) {
                        $results[$queryName].Results += $json.columns
                    }

                    # Update timestamp if this is newer
                    if ($json.unixTime -and $json.unixTime -gt $results[$queryName].LatestTimestamp) {
                        $results[$queryName].LatestTimestamp = $json.unixTime
                    }
                }
            }
            catch {
                Write-Warning "Failed to parse line $lineNumber in osquery results: $_"
            }
        }

        Write-Verbose "Parsed $($results.Count) unique queries from osquery results"
        return $results
    }
    catch {
        Write-Error "Failed to parse osquery results: $_"
        throw
    }
}
