Param(
	[Parameter(Mandatory = $true)]
	[string] $repositoryName,
	[Parameter(Mandatory = $true)]
	[string] $settingsFilename,
	[Parameter(Mandatory = $false)]
	[string] $settingsVersion,
	[Parameter(Mandatory = $true)]
	[int] $buildNumber
)

$baseFolder = $ENV:GITHUB_WORKSPACE
$buildArtifactFolder = Join-Path $baseFolder "output"
New-Item $buildArtifactFolder -ItemType Directory | Out-Null

. (Join-Path $PSScriptRoot "Read-Settings.ps1") -pipelineName $repositoryName -fileName $settingsFilename -version $settingsVersion
. (Join-Path $PSScriptRoot "Install-BcContainerHelper.ps1") -bcContainerHelperVersion $bcContainerHelperVersion -genericImageName $genericImageName

$params = @{}
$insiderSasToken = "$ENV:insiderSasToken"
$licenseFile = "$ENV:LicenseFile"
$codeSignCertPfxFile = "$ENV:CertPfxUrl"
$AzureArtifactsBlobSasToken = "$ENV:AzureArtifactsBlobSasToken"

if (!$doNotSignApps -and $codeSignCertPfxFile) {
	if ("$ENV:CertPfxPass" -ne "") {
		$codeSignCertPfxPassword = ConvertTo-SecureString -String "$ENV:CertPfxPass" -AsPlainText -Force
		$params = @{
			"codeSignCertPfxFile"     = $codeSignCertPfxFile
			"codeSignCertPfxPassword" = $codeSignCertPfxPassword
		}
	}
	else {
		$codeSignCertPfxPassword = $null
	}
}

$allTestResults = "testresults*.xml"
$testResultsFile = Join-Path $baseFolder "TestResults.xml"
$testResultsFiles = Join-Path $baseFolder $allTestResults
if (Test-Path $testResultsFiles) {
	Remove-Item $testResultsFiles -Force
}

$mainAppFolder = Join-Path $baseFolder $appFolders.Split(',')[0].Trim()
$appJsonFile = Join-Path $mainAppFolder "app.json"
$appJson = Get-Content $appJsonFile | ConvertFrom-Json
$appJsonVersion = [System.Version]$appJson.Version
$appVersion = "$($appJsonVersion.Major).$($appJsonVersion.Minor)"
$appBuild = $appJsonVersion.Build

Run-AlPipeline @params `
	-pipelineName $repositoryName `
	-containerName $containerName `
	-imageName $imageName `
	-artifact $artifact.replace('{INSIDERSASTOKEN}', $insiderSasToken) `
	-memoryLimit $memoryLimit `
	-baseFolder $baseFolder `
	-licenseFile $licenseFile `
	-installApps $installApps.replace('{AzureArtifactsBlobSasToken}', $AzureArtifactsBlobSasToken) `
	-previousApps $previousApps `
	-appFolders $appFolders `
	-testFolders $testFolders `
	-doNotRunTests:$doNotRunTests `
	-testResultsFile $testResultsFile `
	-testResultsFormat 'JUnit' `
	-installTestFramework:$installTestFramework `
	-installTestLibraries:$installTestLibraries `
	-installPerformanceToolkit:$installPerformanceToolkit `
	-enableCodeCop:$enableCodeCop `
	-enableAppSourceCop:$enableAppSourceCop `
	-enablePerTenantExtensionCop:$enablePerTenantExtensionCop `
	-enableUICop:$enableUICop `
	-azureDevOps:$false `
	-gitLab:$false `
	-gitHubActions:$true `
	-AppSourceCopMandatoryAffixes $appSourceCopMandatoryAffixes `
	-AppSourceCopSupportedCountries $appSourceCopSupportedCountries `
	-additionalCountries $additionalCountries `
	-buildArtifactFolder $buildArtifactFolder `
	-CreateRuntimePackages:$CreateRuntimePackages `
	-appVersion $appVersion `
	-appBuild $appBuild `
	-appRevision $buildNumber `
	-applicationInsightsKey $applicationInsightsKey
