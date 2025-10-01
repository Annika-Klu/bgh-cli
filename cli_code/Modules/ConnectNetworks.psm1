function Connect-BenQNetwork {
    $availableNets = netsh wlan show networks | Select-String "SSID"
    $benqNet = $availableNets | Where-Object { $_ -match "^BenQ.*2$" }

    if ($benqNet) {
        $ssidLine = $benqNet -replace "^\s*SSID\s+\d+\s*:\s*", ""
        $ssid = $ssidLine.Trim()
        netsh wlan connect name=$ssid | Out-Null
    } else {
        throw "Nicht gefunden. Beamer vermutlich nicht verfügbar (ausgeschaltet?)."
    }
}