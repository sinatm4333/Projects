param(
    [int]$Port = 8791,
    [string]$FilePath = "E:\Projects\SVC\SVC\src\crm_geo_sales_dashboard_bot.lua"
)
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.Start()
Write-Host "Serving $FilePath on http://127.0.0.1:$Port/"
try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $response = $context.Response
        try {
            $response.Headers.Add("Access-Control-Allow-Origin", "*")
            $response.Headers.Add("Access-Control-Allow-Methods", "GET, OPTIONS")
            $response.Headers.Add("Access-Control-Allow-Headers", "*")
            $response.Headers.Add("Access-Control-Allow-Private-Network", "true")
            if ($context.Request.HttpMethod -eq "OPTIONS") {
                $response.StatusCode = 204
                $response.OutputStream.Close()
                continue
            }
            $bytes = [System.IO.File]::ReadAllBytes($FilePath)
            $response.ContentType = "text/plain; charset=utf-8"
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } finally {
            $response.OutputStream.Close()
        }
    }
} finally {
    $listener.Stop()
}
