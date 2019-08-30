#https://github.com/logicappsio/LogicAppConnectionAuth/blob/master/LogicAppConnectionAuth.ps1
#Updated for new Az commands

[CmdletBinding()]
param(
    [string] $ResourceGroupName = 'YourRG',
    [string] $ConnectionName    = 'YourConnectionName'
)
function Show-OAuthWindow {
    param (
        [string] $url
    )
    Add-Type -AssemblyName System.Windows.Forms
 
    $form = New-Object -TypeName System.Windows.Forms.Form -Property @{Width=600;Height=800}
    $web  = New-Object -TypeName System.Windows.Forms.WebBrowser -Property @{Width=580;Height=780;Url=($url -f ($Scope -join "%20")) }
    $DocComp  = {
            $Global:uri = $web.Url.AbsoluteUri
            if ($Global:Uri -match "error=[^&]*|code=[^&]*") {$form.Close() }
    }
    $web.ScriptErrorsSuppressed = $true
    $web.Add_DocumentCompleted($DocComp)
    $form.Controls.Add($web)
    $form.Add_Shown({$form.Activate()})
    $form.ShowDialog() | Out-Null
}

try { 
    Get-AzResource | Select-Object -First 1 | Out-Null
}
catch { 
    Write-Verbose -Message ("[{0}] - Logging into Azure" -f $(Get-Date))
    Login-AzAccount
}

$connection = Get-AzResource -ResourceType "Microsoft.Web/connections" -ResourceGroupName $ResourceGroupName -ResourceName $ConnectionName
Write-Verbose -Message ("Connection status: {0}" -f ($connection.Properties.statuses | Select-Object -First 1 -ExpandProperty Status))

$parameters = @{
	"parameters" = ,@{
	    "parameterName"= "token";
	    "redirectUrl"= "https://ema1.exp.azure.com/ema/default/authredirect"
	}
}

$consentResponse = Invoke-AzResourceAction -Action "listConsentLinks" -ResourceId $connection.ResourceId -Parameters $parameters -Force
Show-OAuthWindow -URL $consentResponse.Value.Link

$regex = '(code=)(.*)$'
$code  = ($uri | Select-string -pattern $regex).Matches[0].Groups[2].Value

Write-Verbose -Message ("Received an accessCode: {0}" -f $code)

if (-Not [string]::IsNullOrEmpty($code)) {
	$parameters = @{ }
	$parameters.Add("code", $code)
	Invoke-AzResourceAction -Action "confirmConsentCode" -ResourceId $connection.ResourceId -Parameters $parameters -Force -ErrorAction Ignore
} 

$connection = Get-AzResource -ResourceType "Microsoft.Web/connections" -ResourceGroupName $ResourceGroupName -ResourceName $ConnectionName
Write-Output -InputObject ("Connection status - {0}" -f  ($connection.Properties.statuses | Select-Object -First 1 -ExpandProperty Status))
