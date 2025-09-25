function Connect-BenQNetwork {
    $availableNets = netsh wlan show networks | Select-String "SSID"
    $benqNet = $availableNets | Where-Object { $_ -match "BenQ" }

    if ($benqNet) {
        $ssidLine = $benqNet -replace "^\s*SSID\s+\d+\s*:\s*", ""
        $ssid = $ssidLine.Trim()
        netsh wlan connect name=$ssid | Out-Null
    } else {
        throw "Kein BenQ-Netzwerk gefunden. Beamer vermutlich ausgeschaltet oder nicht verfügbar."
    }
}