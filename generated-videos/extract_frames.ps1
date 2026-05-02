Param(
  [int]$Frames = 4,
  [string]$InputDir = $PSScriptRoot,
  [string]$OutputRoot = (Join-Path $PSScriptRoot 'frames')
)

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
  Write-Error "ffmpeg not found in PATH. Install ffmpeg and try again."
  exit 1
}
if (-not (Get-Command ffprobe -ErrorAction SilentlyContinue)) {
  Write-Error "ffprobe not found in PATH. Install ffmpeg (ffprobe) and try again."
  exit 1
}

$extensions = @('*.mp4','*.mov','*.mkv','*.avi','*.webm','*.mpg','*.mpeg')
foreach ($pattern in $extensions) {
  Get-ChildItem -Path $InputDir -Filter $pattern -File -ErrorAction SilentlyContinue | ForEach-Object {
    $file = $_
    $base = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $outdir = Join-Path $OutputRoot $base
    if (-not (Test-Path $outdir)) { New-Item -ItemType Directory -Path $outdir -Force | Out-Null }
    Write-Host "Processing $($file.Name) -> $outdir (extracting $Frames frames)"
    $durationRaw = & ffprobe -v error -show_entries format=duration -of csv=p=0 -i $file.FullName 2>$null
    if (-not $durationRaw) { Write-Warning "Could not determine duration for $($file.Name), skipping"; return }
    $duration = [double]$durationRaw
    for ($i=1; $i -le $Frames; $i++) {
      $fraction = $i/($Frames + 1)
      $timestamp = "{0:N3}" -f ($duration * $fraction)
      $outName = "{0}_{1}.jpg" -f $base, $i.ToString("00")
      $outPath = Join-Path $outdir $outName
      & ffmpeg -hide_banner -loglevel error -ss $timestamp -i $file.FullName -frames:v 1 -q:v 2 $outPath
    }
  }
}

Write-Host "Done. Frames are in $OutputRoot"
