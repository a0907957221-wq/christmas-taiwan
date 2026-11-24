Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'

$src = Join-Path $PSScriptRoot '1.png'
$dst = Join-Path $PSScriptRoot 'images\christmas.png'
if (-not (Test-Path -LiteralPath $src)) { throw "source image not found: $src" }

$orig = New-Object System.Drawing.Bitmap($src)
$w = $orig.Width
$h = $orig.Height
"Loaded $src  ${w}x${h}"

# ---- read pixels ----
$rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
$data = $orig.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadWrite, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$stride = $data.Stride
$bytes = New-Object byte[] ($stride * $h)
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)
$orig.UnlockBits($data)
"stride=$stride bytes=$($bytes.Length)"

$origBytes = [byte[]]$bytes.Clone()
if ($origBytes.Length -ne $bytes.Length) { throw "clone length mismatch" }

# ---- cool winter grade deltas, stronger in shadows ----
$dR = New-Object int[] 256
$dG = New-Object int[] 256
$dB = New-Object int[] 256
for ($i = 0; $i -lt 256; $i++) {
    $wgt = $i / 255.0
    $dR[$i] = [int][Math]::Round(-22 * $wgt)
    $dG[$i] = [int][Math]::Round(5 * $wgt)
    $dB[$i] = [int][Math]::Round(34 * $wgt)
}

$qrX1 = 8;  $qrX2 = 132
$qrY1 = 6;  $qrY2 = 134

for ($y = 0; $y -lt $h; $y++) {
    $rowOff = $y * $stride
    $aboveOff = ($y - 7) * $stride
    $inQrBand = ($y -ge $qrY1 -and $y -le $qrY2)
    $canSnow = ($y -ge 7 -and $y -lt 520)
    for ($x = 0; $x -lt $w; $x++) {
        $i = $rowOff + ($x * 4)
        $or = $origBytes[$i]; $og = $origBytes[$i + 1]; $ob = $origBytes[$i + 2]

        # --- cool grade ---
        $lum = ($or + $og + $ob) * 0.3333333
        if ($lum -ge 170) { $idx = 0 } else { $idx = [int]((170.0 - $lum) * 1.5) }
        $v = $or + $dR[$idx]; if ($v -lt 0) { $v = 0 } elseif ($v -gt 255) { $v = 255 }
        $bytes[$i] = [byte]$v
        $v = $og + $dG[$idx]; if ($v -lt 0) { $v = 0 } elseif ($v -gt 255) { $v = 255 }
        $bytes[$i + 1] = [byte]$v
        $v = $ob + $dB[$idx]; if ($v -lt 0) { $v = 0 } elseif ($v -gt 255) { $v = 255 }
        $bytes[$i + 2] = [byte]$v

        # --- snow resting on top edges of dark branches ---
        if ($canSnow) {
            if ($inQrBand -and $x -ge $qrX1 -and $x -le $qrX2) { continue }
            if ($or -lt 95 -and $og -lt 95 -and $ob -lt 95 -and $aboveOff -ge 0) {
                $aj = $aboveOff + ($x * 4)
                $al = ($origBytes[$aj] + $origBytes[$aj + 1] + $origBytes[$aj + 2]) * 0.3333333
                if ($al -gt 118) {
                    $hash = (($x * 7 + $y * 13) -band 255)
                    if ($hash -lt 150) {
                        $amt = 0.26 + (($hash -band 31) * 0.0071)
                        $v = [int]($bytes[$i] + (255 - $bytes[$i]) * $amt); if ($v -gt 255) { $v = 255 }
                        $bytes[$i] = [byte]$v
                        $v = [int]($bytes[$i + 1] + (255 - $bytes[$i + 1]) * $amt); if ($v -gt 255) { $v = 255 }
                        $bytes[$i + 1] = [byte]$v
                        $v = [int]($bytes[$i + 2] + (255 - $bytes[$i + 2]) * $amt); if ($v -gt 255) { $v = 255 }
                        $bytes[$i + 2] = [byte]$v
                    }
                }
            }
        }
    }
}
"pixel pass done"

# ---- write back ----
$data2 = $orig.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::WriteOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
[System.Runtime.InteropServices.Marshal]::Copy($bytes, 0, $data2.Scan0, $bytes.Length)
$orig.UnlockBits($data2)

# ---- drawing passes ----
$g = [System.Drawing.Graphics]::FromImage($orig)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

function New-SoftSprite([int]$size, [System.Drawing.Color]$center, [System.Drawing.Color]$edge) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $gg = [System.Drawing.Graphics]::FromImage($bmp)
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p.AddEllipse(0, 0, $size, $size)
    $b = New-Object System.Drawing.Drawing2D.PathGradientBrush($p)
    $b.CenterColor = $center
    $b.SurroundColors = @($edge)
    $gg.FillPath($b, $p)
    $gg.Dispose()
    return $bmp
}

$soft = New-SoftSprite 64 ([System.Drawing.Color]::FromArgb(115, 255, 255, 255)) ([System.Drawing.Color]::FromArgb(0, 255, 255, 255))
$glow = New-SoftSprite 64 ([System.Drawing.Color]::FromArgb(165, 255, 214, 110)) ([System.Drawing.Color]::FromArgb(0, 255, 190, 70))

$rand = New-Object System.Random(20261225)
$white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$gold  = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)

# --- small crisp snowflakes ---
for ($n = 0; $n -lt 620; $n++) {
    $x = $rand.Next(0, $w)
    $y = $rand.Next(0, $h)
    $r = 1.0 + [Math]::Pow($rand.NextDouble(), 2) * 3.4
    $a = 80 + [int]($rand.NextDouble() * 165)
    $white.Color = [System.Drawing.Color]::FromArgb($a, 255, 255, 255)
    $g.FillEllipse($white, ($x - $r), ($y - $r), ($r * 2), ($r * 2))
}

# --- large soft out-of-focus snow ---
for ($n = 0; $n -lt 42; $n++) {
    $s = 16 + $rand.Next(0, 30)
    $x = $rand.Next(0, $w - $s)
    $y = $rand.Next(0, $h - $s)
    $g.DrawImage($soft, $x, $y, $s, $s)
}

# --- warm christmas lights on dark branches ---
$placed = 0
$tries = 0
while ($placed -lt 46 -and $tries -lt 4000) {
    $tries++
    $x = $rand.Next(50, $w - 40)
    $y = $rand.Next(30, [int]($h * 0.72))
    $i = $y * $stride + $x * 4
    if ($origBytes[$i] -lt 105 -and $origBytes[$i + 1] -lt 105 -and $origBytes[$i + 2] -lt 105) {
        $s = 26 + $rand.Next(0, 14)
        $g.DrawImage($glow, ($x - [int]($s / 2)), ($y - [int]($s / 2)), $s, $s)
        $gold.Color = [System.Drawing.Color]::FromArgb(245, 255, 245, 205)
        $g.FillEllipse($gold, ($x - 2.6), ($y - 2.6), 5.2, 5.2)
        $placed++
    }
}
"lights placed=$placed (tries=$tries)"

# --- keep QR code pixel-perfect: paste original region back on top ---
$clean = New-Object System.Drawing.Bitmap($src)
$minX = $w; $minY = $h; $maxX = -1; $maxY = -1
for ($y = 0; $y -lt 200; $y++) {
    for ($x = 0; $x -lt 250; $x++) {
        $i = $y * $stride + $x * 4
        if ($origBytes[$i] -gt 238 -and $origBytes[$i + 1] -gt 238 -and $origBytes[$i + 2] -gt 238) {
            if ($x -lt $minX) { $minX = $x }
            if ($x -gt $maxX) { $maxX = $x }
            if ($y -lt $minY) { $minY = $y }
            if ($y -gt $maxY) { $maxY = $y }
        }
    }
}
if ($maxX -gt $minX -and $maxY -gt $minY) {
    $pad = 3
    $sx = [Math]::Max(0, $minX - $pad); $sy = [Math]::Max(0, $minY - $pad)
    $sw = [Math]::Min($w - $sx, ($maxX - $minX + 1) + $pad * 2)
    $sh = [Math]::Min($h - $sy, ($maxY - $minY + 1) + $pad * 2)
    $srcRect = New-Object System.Drawing.Rectangle($sx, $sy, $sw, $sh)
    $dstRect = New-Object System.Drawing.Rectangle($sx, $sy, $sw, $sh)
    $g.DrawImage($clean, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
    "QR box x=$minX..$maxX y=$minY..$maxY pasted back"
} else {
    "QR box not found - skipping paste-back"
}

$g.Dispose()
$soft.Dispose()
$glow.Dispose()
$white.Dispose()
$gold.Dispose()
$clean.Dispose()

$orig.Save($dst, [System.Drawing.Imaging.ImageFormat]::Png)
$orig.Dispose()
"Saved: $dst  ($([Math]::Round((Get-Item -LiteralPath $dst).Length/1KB)) KB)"
