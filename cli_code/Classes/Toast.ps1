class Toast {
    [char]$InfoIcon = [char]9989
    [char]$ErrorIcon = [char]0x274C

    [void] Show([string]$Type, [string]$Title, [string]$Message) {
        $icon = ""
        switch ($Type.ToLower()) {
            'info'  { $icon = $this.InfoIcon }
            'error' { $icon = $this.ErrorIcon }
        }
        $ToastText02 = [Windows.UI.Notifications.ToastTemplateType, Windows.UI.Notifications, ContentType = WindowsRuntime]::ToastText02
        $TemplateContent = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]::GetTemplateContent($ToastText02)
        $TemplateContent.SelectSingleNode("//text[@id='1']").InnerText = "BGH-CLI | $icon $Title"
        $TemplateContent.SelectSingleNode("//text[@id='2']").InnerText = $Message
        $AppId = "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppId).Show($TemplateContent)
    }
}
