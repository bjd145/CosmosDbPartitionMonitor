$result = ConvertFrom-Json $ENV:deploymentOutput
$logicAppUri = $result.logicAppUri.value
Write-Host "##vso[task.setvariable variable=logicAppUri]$logicAppUri"