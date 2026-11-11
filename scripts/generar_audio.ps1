$ErrorActionPreference = 'Stop'
$audioDirectory = Join-Path $PSScriptRoot '..\assets\audio'
New-Item -ItemType Directory -Force -Path $audioDirectory | Out-Null
$tracks = @{
    orbit = 'aevalsrc=0.10*sin(2*PI*130.81*t)+0.06*sin(2*PI*196*t)+0.035*sin(2*PI*261.63*t):s=44100:d=30'
    forest = 'anoisesrc=d=30:c=pink:r=44100:a=0.18'
    dawn = 'aevalsrc=0.09*sin(2*PI*174.61*t)+0.06*sin(2*PI*220*t)+0.035*sin(2*PI*349.23*t):s=44100:d=30'
}
foreach ($track in $tracks.GetEnumerator()) {
    $audioFilters = if ($track.Key -eq 'forest') { 'lowpass=f=1600,afade=t=in:d=2,afade=t=out:st=28:d=2' } else { 'afade=t=in:d=2,afade=t=out:st=28:d=2' }
    & ffmpeg -hide_banner -loglevel error -f lavfi -i $track.Value -af $audioFilters -codec:a libmp3lame -b:a 96k -y (Join-Path $audioDirectory ($track.Key + '.mp3'))
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo generar el audio.' }
}
