# Variables
$msiUrl = "https://download.newrelic.com/infrastructure_agent/windows/"
$msiFile = "newrelic-infra.msi"
$msiFullUrl = $msiUrl + $msiFile
$msiPath = "c:\temp\"
$msiFullPath = $msiPath + $msiFile
$envFile = "newrelic.env"

function set_env() {
    if (!(Test-Path -path $envFile)) {
        Write-Host "Copy newrelic.template.env to newrelic.env and configure"
        exit
    }
    Foreach ($line in (Get-Content -path $envFile | Where {$_ -notmatch '^#.*'})) {
        $var = $line.Split('=')
        Write-Host "Setting: $($var)"
        [Environment]::SetEnvironmentVariable($var[0], $var[1], "Process")
    }
    if ([string]::IsNullOrEmpty($env:NEW_RELIC_LICENSE_KEY)) {
        Write-Host "Env var NEW_RELIC_LICENSE_KEY must be set"
        exit
    }
}

function is_admin() {
    $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] �Administrator�)

    if (!$IsAdmin) {
        Write-Host "This script should be run as Administrator"
        exit
    }
}

function download_files(){
    Write-Host "Downloading New Relic Windows Agent"
    $dl = Invoke-WebRequest -uri $msiFullUrl -outfile $msiFullPath
    Write-Host $dl
}

function install() {
    $arguments = @(
        "/qn"
        "/i"
        $msiFullPath
        "GENERATE_CONFIG=true"
        "LICENSE_KEY=" + $env:NEW_RELIC_LICENSE_KEY
    )
    Write-Host "Installing $($msiFile)"
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait -PassThru
    if ($process.ExitCode -ne 0){
        Write-Host "Installation Failed: exit code $($process.ExitCode)"
        exit
    }
    Write-Host "Installation Success"
    Remove-Item -path $msiFullPath
}

# Execute functions
is_admin
set_env
download_files
install