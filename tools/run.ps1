param(
    [string]$Godot = 'godot',
    [string]$Output = '',
    [ValidateSet('lab', 'render-tests', 'logic-tests')][string]$Mode = 'lab'
)
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
if (-not $Output) { $Output = Join-Path ([System.IO.Path]::GetTempPath()) 'godot-ui-check' }
New-Item -ItemType Directory -Path $Output -Force | Out-Null
$runArgs = @('--path', $projectPath, '--log-file', (Join-Path $Output ($Mode + '.log')))
if ($Mode -eq 'lab') {
    $runArgs += @('--rendering-method', 'gl_compatibility', '--rendering-driver', 'opengl3')
} elseif ($Mode -eq 'render-tests') {
    $runArgs += @('--rendering-method', 'gl_compatibility', '--rendering-driver', 'opengl3', '--script', 'res://tests/run_tests.gd', '--', '--output', $Output)
} else {
    $runArgs += @('--headless', '--script', 'res://tests/run_tests.gd', '--', '--logic-only', '--output', $Output)
}
& $Godot @runArgs
exit $LASTEXITCODE
