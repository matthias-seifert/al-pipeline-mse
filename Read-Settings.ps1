Param(
	[Parameter(Mandatory = $true)]
	[string] $pipelineName,
	[Parameter(Mandatory = $true)]
	[string] $fileName = "",
	[string] $version = ""
)

$agentName = $ENV:AGENT_NAME

$settings = (Get-Content ($fileName) | ConvertFrom-Json)
if ("$version" -eq "") {
	$version = $settings.versions[0].version
	Write-Host "Version not defined, using $version"
}

$buildversion = $settings.versions | Where-Object { $_.version -eq $version }
if ($buildversion) {
	Write-Host "Set artifact = $($buildVersion.artifact)"
	Set-Variable -Name "artifact" -Value $buildVersion.artifact
}
else {
	throw "Unknown version: $version"
}

if ($agentName) {
	$containerName = "$($agentName -replace '[^a-zA-Z0-9---]', '')-$($pipelineName -replace '[^a-zA-Z0-9---]', '')".ToLowerInvariant()
}
else {
	$containerName = "$($pipelineName.Replace('.','-') -replace '[^a-zA-Z0-9---]', '')".ToLowerInvariant()
}
Write-Host "Set containerName = $containerName"

"installApps", "previousApps", "appSourceCopMandatoryAffixes", "appSourceCopSupportedCountries", "appFolders", "testFolders", "memoryLimit", "additionalCountries", "genericImageName", "vaultNameForLocal", "bcContainerHelperVersion", "applicationInsightsKey" | ForEach-Object {
	$str = ""
	if ($buildversion.PSObject.Properties.Name -eq $_) {
		$str = $buildversion."$_"
	}
	elseif ($settings.PSObject.Properties.Name -eq $_) {
		$str = $settings."$_"
	}
	Write-Host "Set $_ = '$str'"
	Set-Variable -Name $_ -Value "$str"
}

"installTestFramework", "installTestLibraries", "installPerformanceToolkit", "enableCodeCop", "enableAppSourceCop", "enablePerTenantExtensionCop", "enableUICop", "doNotSignApps", "doNotRunTests", "cacheImage", "CreateRuntimePackages" | ForEach-Object {
	$str = "False"
	if ($buildversion.PSObject.Properties.Name -eq $_) {
		$str = $buildversion."$_"
	}
	elseif ($settings.PSObject.Properties.Name -eq $_) {
		$str = $settings."$_"
	}
	Write-Host "Set $_ = $str"
	Set-Variable -Name $_ -Value ($str -eq "True")
}

$imageName = ""
if ($cacheImage -and ("$AgentName" -ne "Hosted Agent" -and "$agentName" -ne "" -and "$AgentName" -notlike "Azure Pipelines*")) {
	$imageName = "bcimage"
}
