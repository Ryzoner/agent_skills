# Ryzoner/agent_skills - installer (Windows PowerShell 5.1+)
# Skachivayet arkhiv repozitoriya i ustanavlivayet vse skilly v $HOME/.agents/skills/
# Idempotentnyy: perezapisyvaet sushchestvuyushchie papki skilov.

$ErrorActionPreference = "Stop"

# Nadjozhnoe opredelenie SCRIPT_DIR
if ($null -ne $MyInvocation.MyCommand.Path -and (Test-Path $MyInvocation.MyCommand.Path)) {
    $SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
} elseif ($null -ne $PSScriptRoot -and $PSScriptRoot -ne '') {
    $SCRIPT_DIR = $PSScriptRoot
} else {
    $SCRIPT_DIR = (Get-Location).Path
}

$REPO_URL = "https://github.com/Ryzoner/agent_skills"
$REPO_TAR = "$REPO_URL/archive/refs/heads/main.tar.gz"

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  Ryzoner/agent_skills installer" -ForegroundColor Cyan
Write-Host "  Vse skilly + ExampleSubagents" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

$HOME_DIR = $env:USERPROFILE
$SKILLS_DEST = Join-Path $HOME_DIR ".agents\skills"
$EXAMPLES_DEST = Join-Path $HOME_DIR ".agents\ExampleSubagents"

Write-Host "[~] Domashnyaya direktoriya: $HOME_DIR" -ForegroundColor Yellow
Write-Host "[~] Kuda: $SKILLS_DEST" -ForegroundColor Yellow
Write-Host ""

# 1. Sozdayom direktorii
Write-Host "[1] Sozdayu direktorii..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $SKILLS_DEST -Force | Out-Null
New-Item -ItemType Directory -Path $EXAMPLES_DEST -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $HOME_DIR ".myskills\skills") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $HOME_DIR ".notes\INBOX") -Force | Out-Null
Write-Host "    [OK] ~/.agents/skills/" -ForegroundColor Green
Write-Host "    [OK] ~/.agents/ExampleSubagents/" -ForegroundColor Green
Write-Host "    [OK] ~/.myskills/skills/" -ForegroundColor Green
Write-Host "    [OK] ~/.notes/INBOX/" -ForegroundColor Green
Write-Host ""

# 2. Skachivayu arkhiv
$TMPDIR = Join-Path $env:TEMP ("agent_skills_" + [guid]::NewGuid().ToString("N").Substring(0, 8))
New-Item -ItemType Directory -Path $TMPDIR -Force | Out-Null
$TAR_FILE = Join-Path $TMPDIR "repo.tar.gz"

Write-Host "[2] Skachivayu $REPO_URL..." -ForegroundColor Yellow
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $REPO_TAR -OutFile $TAR_FILE -UseBasicParsing -ErrorAction Stop
} catch {
    Write-Host "    [X] Oshibka skachivaniya: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "    Prover'te internet i URL." -ForegroundColor Red
    Remove-Item $TMPDIR -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# 3. Raspakovyvaem
Write-Host "[3] Raspakovyvayu..." -ForegroundColor Yellow
$EXTRACT_DIR = Join-Path $TMPDIR "extract"
New-Item -ItemType Directory -Path $EXTRACT_DIR -Force | Out-Null

$tar = Get-Command tar -ErrorAction SilentlyContinue
if ($null -ne $tar) {
    & tar -xzf $TAR_FILE -C $EXTRACT_DIR
} else {
    Write-Host "    [X] tar.exe ne nayden. Trebuetsya Windows 10 1803+." -ForegroundColor Red
    Write-Host "    Skachayte vruchnuyu: $REPO_URL/archive/refs/heads/main.zip" -ForegroundColor Yellow
    Remove-Item $TMPDIR -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

$REPO_DIR = Get-ChildItem -Path $EXTRACT_DIR -Directory | Select-Object -First 1
if ($null -eq $REPO_DIR -or -not (Test-Path (Join-Path $REPO_DIR.FullName ".agents\skills"))) {
    Write-Host "    [X] Ne nashyol .agents/skills/ v arkhive." -ForegroundColor Red
    Remove-Item $TMPDIR -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# 4. Kopiruem skilly
Write-Host "[4] Kopiruyu skilly..." -ForegroundColor Yellow
$copied = 0
$srcSkills = Join-Path $REPO_DIR.FullName ".agents\skills"
Get-ChildItem -Path $srcSkills -Directory | Where-Object { $_.Name -ne ".template" } | ForEach-Object {
    $destDir = Join-Path $SKILLS_DEST $_.Name
    if (Test-Path $destDir) {
        Remove-Item $destDir -Recurse -Force
    }
    Copy-Item $_.FullName $destDir -Recurse -Force
    $script:copied++
}
Write-Host "    [OK] Skopirovano: $copied skilov" -ForegroundColor Green

# 5. Kopiruem primery subagentov
Write-Host "[5] Kopiruyu ExampleSubagents..." -ForegroundColor Yellow
$srcExamples = Join-Path $REPO_DIR.FullName ".agents\ExampleSubagents"
if (Test-Path $srcExamples) {
    Get-ChildItem -Path $srcExamples | Where-Object { $_.Name -ne "README.md" } | ForEach-Object {
        $destPath = Join-Path $EXAMPLES_DEST $_.Name
        if (Test-Path $destPath) {
            Remove-Item $destPath -Recurse -Force
        }
        Copy-Item $_.FullName $destPath -Recurse -Force
    }
    $examplesCount = (Get-ChildItem $EXAMPLES_DEST -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-Host "    [OK] Primerov agentov: $examplesCount" -ForegroundColor Green
}

# 6. npm install dlya skilov s package.json
Write-Host "[6] Proveryayu npm-zavisimosti skilov..." -ForegroundColor Yellow
$npm = Get-Command npm -ErrorAction SilentlyContinue
Get-ChildItem -Path $SKILLS_DEST -Directory | Where-Object { Test-Path (Join-Path $_.FullName "package.json") } | ForEach-Object {
    $skillDir = $_.FullName
    if (-not (Test-Path (Join-Path $skillDir "node_modules"))) {
        if ($null -ne $npm) {
            Write-Host "    -> $($_.Name) (npm install)" -ForegroundColor Yellow
            try {
                Push-Location $skillDir
                & npm install --no-audit --no-fund --silent 2>&1 | Out-Null
                Pop-Location
                Write-Host "       [OK] $($_.Name) gotov" -ForegroundColor Green
            } catch {
                Pop-Location -ErrorAction SilentlyContinue
                Write-Host "       [!] $($_.Name): npm install ne udalsya (propuskayu, skill rabotaet bez zavisimostey)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "    [!] npm ne nayden - $($_.Name) propushchen (rabotaet i bez zavisimostey)" -ForegroundColor Yellow
        }
    }
}

# Ochistka
Remove-Item $TMPDIR -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  [OK] Ustanovka zavershena!" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ustanovleno:" -ForegroundColor Green
Write-Host "  Skilly            -> $SKILLS_DEST"
Write-Host "  ExampleSubagents  -> $EXAMPLES_DEST"
Write-Host "  User Skills       -> $HOME_DIR\.myskills\skills"
Write-Host "  Notes INBOX       -> $HOME_DIR\.notes\INBOX"
Write-Host ""
Write-Host "Sleduyushchie shagi:" -ForegroundColor Yellow
Write-Host "  1. Otkroyte vash AI-agent (Codex, Claude, Qwen, Cursor...)"
Write-Host "  2. Agent podkhvatit skilly iz $SKILLS_DEST"
Write-Host "  3. Ili skazhite agentu: «pokazhi skilly iz ~/.agents/skills/»"
Write-Host ""
Write-Host "[i] Repozitoriy: $REPO_URL" -ForegroundColor Cyan
