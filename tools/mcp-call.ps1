param(
    [Parameter(Mandatory)][string]$Name,
    [string]$ArgumentsJson = '{}'
)
$ErrorActionPreference = 'Stop'
$body = @{
    jsonrpc = '2.0'
    id = 1
    method = 'tools/call'
    params = @{ name = $Name; arguments = ($ArgumentsJson | ConvertFrom-Json) }
} | ConvertTo-Json -Depth 30
$result = Invoke-RestMethod 'http://127.0.0.1:9080/mcp' -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 30
$result | ConvertTo-Json -Depth 30
if ($result.error -or $result.result.isError) { throw "MCP call failed: $Name" }
