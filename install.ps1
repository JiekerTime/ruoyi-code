# Ruoyi Code installer for Windows
# Usage: .\install.ps1 [-Release] [-NoVerify]

param(
    [switch]$Release,
    [switch]$NoVerify,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

function Write-Step($step, $total, $msg) {
    Write-Host "`n[$step/$total] $msg" -ForegroundColor Blue
}

function Write-Ok($msg) {
    Write-Host "  ok $msg" -ForegroundColor Green
}

function Write-Warn($msg) {
    Write-Host "  warn $msg" -ForegroundColor Yellow
}

function Write-Err($msg) {
    Write-Host "  error $msg" -ForegroundColor Red
}

function Write-Info($msg) {
    Write-Host "  -> $msg" -ForegroundColor Cyan
}

# Banner
Write-Host @"

    / \__
   (    @\___    RUOYI
   /         O
  /   (_____/
 /_____/   U

"@ -ForegroundColor Yellow
Write-Host "Ruoyi Code installer - 让每个人都能用上 AI 编码" -ForegroundColor DarkGray

if ($Help) {
    Write-Host @"

Usage: .\install.ps1 [options]

Options:
  -Release    Build optimized release profile
  -NoVerify   Skip post-install verification
  -Help       Show this help
"@
    exit 0
}

$BuildProfile = if ($Release) { "release" } else { "debug" }
$TotalSteps = 6

# Step 1: Environment
Write-Step 1 $TotalSteps "Detecting host environment"
Write-Info "OS: Windows $([System.Environment]::OSVersion.Version)"
Write-Info "Arch: $env:PROCESSOR_ARCHITECTURE"
Write-Ok "Windows detected"

# Step 2: Locate workspace
Write-Step 2 $TotalSteps "Locating the Rust workspace"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RustDir = Join-Path $ScriptDir "rust"

if (-not (Test-Path (Join-Path $RustDir "Cargo.toml"))) {
    Write-Err "Cannot find rust/Cargo.toml"
    exit 1
}
Write-Ok "workspace at $RustDir"

# Step 3: Prerequisites
Write-Step 3 $TotalSteps "Checking prerequisites"

$hasRust = (Get-Command rustc -ErrorAction SilentlyContinue) -and (Get-Command cargo -ErrorAction SilentlyContinue)

if ($hasRust) {
    Write-Ok "rustc found: $(rustc --version)"
    Write-Ok "cargo found: $(cargo --version)"
} else {
    Write-Info "Rust toolchain not found, installing via rustup..."

    $rustupUrl = "https://win.rustup.rs/x86_64"
    $rustupExe = Join-Path $env:TEMP "rustup-init.exe"

    try {
        Invoke-WebRequest -Uri $rustupUrl -OutFile $rustupExe -UseBasicParsing
        & $rustupExe -y --default-toolchain stable
        $env:PATH = "$env:USERPROFILE\.cargo\bin;$env:PATH"

        if ((Get-Command rustc -ErrorAction SilentlyContinue) -and (Get-Command cargo -ErrorAction SilentlyContinue)) {
            Write-Ok "Rust installed: $(rustc --version)"
        } else {
            Write-Err "Rust installation failed. Please install manually: https://rustup.rs"
            exit 1
        }
    } catch {
        Write-Err "Failed to download rustup: $_"
        Write-Err "Please install Rust manually: https://rustup.rs"
        exit 1
    } finally {
        Remove-Item $rustupExe -ErrorAction SilentlyContinue
    }
}

if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Ok "git found: $(git --version)"
} else {
    Write-Warn "git not found - some features may not work"
}

# Step 4: Build
Write-Step 4 $TotalSteps "Building the ruoyi-cli workspace ($BuildProfile)"

$cargoArgs = @("build", "--workspace")
if ($Release) { $cargoArgs += "--release" }

Write-Info "running: cargo $($cargoArgs -join ' ')"
Write-Info "this may take a few minutes on the first build"

Push-Location $RustDir
try {
    & cargo @cargoArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Err "cargo build failed"
        exit 1
    }
} finally {
    Pop-Location
}

$RuoyiBin = Join-Path $RustDir "target\$BuildProfile\ruoyi-cli.exe"
if (-not (Test-Path $RuoyiBin)) {
    Write-Err "Binary not found at $RuoyiBin"
    exit 1
}
Write-Ok "built $RuoyiBin"

# Step 5: Verify
Write-Step 5 $TotalSteps "Verifying the installed binary"

if ($NoVerify) {
    Write-Warn "verification skipped (-NoVerify)"
} else {
    try {
        $version = & $RuoyiBin --version 2>&1
        Write-Ok "ruoyi-cli --version -> $version"
    } catch {
        Write-Err "ruoyi-cli --version failed"
        exit 1
    }

    try {
        & $RuoyiBin --help | Out-Null
        Write-Ok "ruoyi-cli --help responded"
    } catch {
        Write-Err "ruoyi-cli --help failed"
        exit 1
    }
}

# Step 6: Install to PATH
Write-Step 6 $TotalSteps "Installing ruoyi-cli to PATH"

$InstallDir = Join-Path $env:USERPROFILE ".local\bin"
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

$DestBin = Join-Path $InstallDir "ruoyi-cli.exe"
Copy-Item $RuoyiBin $DestBin -Force
Write-Ok "copied to $DestBin"

# Add to user PATH if not already present
$UserPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($UserPath -notlike "*$InstallDir*") {
    [Environment]::SetEnvironmentVariable("PATH", "$InstallDir;$UserPath", "User")
    $env:PATH = "$InstallDir;$env:PATH"
    Write-Ok "added $InstallDir to user PATH"
    Write-Warn "open a new terminal for PATH changes to take effect"
} else {
    Write-Ok "$InstallDir already in PATH"
}

if (Get-Command ruoyi-cli -ErrorAction SilentlyContinue) {
    Write-Ok "ruoyi-cli is now available globally"
}

Write-Host @"

Ruoyi Code is installed and ready!

  Quick start:

  # 1. configure API key (create .env file in your project):
  'DEEPSEEK_API_KEY=sk-...' | Out-File .env -Encoding utf8

  # 2. start interactive REPL:
  ruoyi-cli

  # 3. or one-shot prompt:
  ruoyi-cli prompt "summarize this repository"

  # other providers:
  # ANTHROPIC_API_KEY=sk-ant-...
  # OPENAI_API_KEY=sk-...

  For deeper docs, see USAGE.md
"@
