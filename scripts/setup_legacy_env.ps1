Param(
    [string]$PythonTag = '3.8',
    [string]$VenvName = '.venv38',
    [string]$ReqFile = 'environment/frontend_server/requirements.txt'
)

Write-Host "[legacy-env] Checking for Python $PythonTag..." -ForegroundColor Cyan
$pyCommand = "py -$PythonTag"
$pythonAvailable = $false
try {
    & py -$PythonTag --version | Out-Null
    $pythonAvailable = $true
} catch {
    $pythonAvailable = $false
}

if (-not $pythonAvailable) {
    Write-Host "Python $PythonTag not found. Please install it via winget:" -ForegroundColor Yellow
    Write-Host " winget install --id Python.Python.$($PythonTag.Replace('.','')) -e" -ForegroundColor Yellow
    Write-Host "Or download: https://www.python.org/ftp/python/$PythonTag.10/python-$PythonTag.10-amd64.exe" -ForegroundColor Yellow
    Write-Host "After install rerun: powershell -ExecutionPolicy Bypass -File .\\scripts\\setup_legacy_env.ps1" -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $VenvName)) {
    Write-Host "[legacy-env] Creating virtual environment $VenvName" -ForegroundColor Cyan
    & py -$PythonTag -m venv $VenvName
    if (-not (Test-Path $VenvName)) { Write-Error "Failed to create venv"; exit 1 }
} else {
    Write-Host "[legacy-env] Virtual environment already exists" -ForegroundColor Green
}

$venvPython = Join-Path $VenvName 'Scripts/python.exe'
if (-not (Test-Path $venvPython)) { Write-Error "python.exe not found in venv"; exit 1 }

Write-Host "[legacy-env] Upgrading build tooling (pip, setuptools, wheel)" -ForegroundColor Cyan
& $venvPython -m pip install --upgrade pip setuptools wheel
if ($LASTEXITCODE -ne 0) { Write-Error "Failed upgrading build tooling"; exit 1 }

if (-not (Test-Path $ReqFile)) { Write-Error "Requirements file '$ReqFile' not found"; exit 1 }
Write-Host "[legacy-env] Installing dependencies from $ReqFile" -ForegroundColor Cyan
& $venvPython -m pip install -r $ReqFile
if ($LASTEXITCODE -ne 0) { Write-Error "Dependency installation failed"; exit 1 }

Write-Host "[legacy-env] Running Django system check" -ForegroundColor Cyan
$manage = 'environment/frontend_server/manage.py'
if (Test-Path $manage) {
    & $venvPython $manage check
} else {
    Write-Host "manage.py not found at $manage; skipping check" -ForegroundColor Yellow
}

Write-Host "[legacy-env] Summary:" -ForegroundColor Magenta
Write-Host "  Venv: $VenvName" -ForegroundColor Magenta
Write-Host "  Python: $PythonTag" -ForegroundColor Magenta
Write-Host "Activate with:  .\\$VenvName\\Scripts\\Activate.ps1" -ForegroundColor Magenta

Write-Host "[legacy-env] Done." -ForegroundColor Green
