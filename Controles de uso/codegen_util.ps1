# codegen_util.ps1 - helper routines for gerador_codigos.bat
#
# Modes:
#   fold   -> read raw code bytes from %TMPIN% (console codepage),
#             fold accents + uppercase, write ASCII to %TMPOUT%
#   view      -> list all codes in %CODESFILE% (active / expired / used count)
#   delete    -> remove CodeRedeemData["%COD%"] block from %CODESFILE%
#                (also removes the usage counter for that code)
#   overwrite -> remove the block but KEEP the usage counter, so a regenerated
#                code keeps its "used X/Y" history (maxUses is a real lifetime cap)
#
# All paths come from environment variables set by the .bat.

param([string]$Mode = "fold", [int]$cp = 0)

# Path of the usage counter file (same folder as codes_data.lua)
function Get-UsedFile {
    return [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($env:CODESFILE), 'codes_used.lua')
}

# ---------------------------------------------------------------
# fold: PROMOCAO / PROMOCAO / promoAo all become PROMOCAO
# The input bytes were captured by cmd's set /p in the console
# codepage, so decode TMPIN using that same codepage.
# ---------------------------------------------------------------
function Fold-Code {
    if ($cp -le 0) {
        try { $cp = [System.Console]::InputEncoding.CodePage } catch { $cp = 850 }
        if ($cp -le 0) { $cp = 850 }
    }
    $enc = [System.Text.Encoding]::GetEncoding($cp)
    $s = [System.IO.File]::ReadAllText($env:TMPIN, $enc)
    $s = $s.Trim()
    $s = $s.Normalize([System.Text.NormalizationForm]::FormD)
    $s = $s -replace '\p{M}', ''
    $s = $s.ToUpperInvariant()
    $s = $s -replace '[^A-Z0-9~]', ''
    # UTF-8 sem BOM (ASCII e subconjunto; seguro se o arquivo tiver acentos)
    [System.IO.File]::WriteAllText($env:TMPOUT, $s, (New-Object System.Text.UTF8Encoding($false)))
}

# ---------------------------------------------------------------
# view: print a readable list of codes (marks expired ones and the
# used count for codes that have a usage limit)
# ---------------------------------------------------------------
function Show-Codes {
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $path = $env:CODESFILE
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Output 'Nenhum codigo cadastrado ainda.'
        return
    }
    # used counters: CodeRedeemUsed = { ["CODE"] = 3 }
    $used = @{}
    $usedFile = Get-UsedFile
    if (Test-Path -LiteralPath $usedFile) {
        foreach ($ul in [System.IO.File]::ReadAllLines($usedFile)) {
            $ux = $ul.Trim()
            if ($ux -match '\["([^"]+)"\]\s*=\s*(\d+)') {
                $used[$matches[1]] = [int64]$matches[2]
            }
        }
    }
    $lines = [System.IO.File]::ReadAllLines($path)
    $in = $false
    foreach ($t in $lines) {
        $x = $t.Trim()
        if ($x -match 'CodeRedeemData\["([^"]+)"\]\s*=\s*\{') {
            $code = $matches[1]
            Write-Output ('==== ' + $code)
            $in = $true
        } elseif ($in) {
            if ($x -eq '}') {
                $in = $false
            } elseif ($x -match 'expire = (\d+)') {
                $e = [int64]$matches[1]
                if ($e -gt 0) {
                    if ($e -lt $now) {
                        Write-Output '    >> EXPIRADO'
                    } else {
                        Write-Output ('    expira em ' + [DateTimeOffset]::FromUnixTimeSeconds($e).ToString('dd/MM/yyyy HH:mm'))
                    }
                }
            } elseif ($x -match 'maxUses = (\d+)') {
                $m = [int64]$matches[1]
                $u = 0
                if ($used.ContainsKey($code)) { $u = $used[$code] }
                if ($m -gt 0) {
                    if ($u -ge $m) {
                        Write-Output ('    usos: ' + $u + '/' + $m + '  >> ESGOTADO')
                    } else {
                        Write-Output ('    usos: ' + $u + '/' + $m)
                    }
                }
            } elseif ($x -ne '') {
                Write-Output ('    ' + $x)
            }
        }
    }
}

# ---------------------------------------------------------------
# delete: remove the whole CodeRedeemData["COD"] = { ... } block
# ---------------------------------------------------------------
function Remove-Code {
    param([switch]$KeepUsed)
    $code = $env:COD
    $path = $env:CODESFILE
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Output 'NOTFOUND'
        return
    }
    $lines = @([System.IO.File]::ReadAllLines($path))
    $out = New-Object System.Collections.Generic.List[string]
    $skip = $false
    $found = $false
    $pat = 'CodeRedeemData\["' + [regex]::Escape($code) + '"\]\s*=\s*\{'
    foreach ($l in $lines) {
        $t = $l.Trim()
        if (-not $skip -and $t -match $pat) {
            $skip = $true
            $found = $true
            continue
        }
        if ($skip) {
            if ($t -eq '}') { $skip = $false }
            continue
        }
        [void]$out.Add($l)
    }
    if ($found) {
        [System.IO.File]::WriteAllLines($path, $out, (New-Object System.Text.UTF8Encoding($false)))
        # remove the usage counter for this code too (unless KeepUsed, used
        # by the overwrite flow so a regenerated code keeps its used count)
        if (-not $KeepUsed) {
            $usedFile = Get-UsedFile
            if (Test-Path -LiteralPath $usedFile) {
                $ulines = @([System.IO.File]::ReadAllLines($usedFile))
                $uout = New-Object System.Collections.Generic.List[string]
                $skipUsed = $false
                foreach ($ul in $ulines) {
                    $ux = $ul.Trim()
                    if (-not $skipUsed -and $ux -match '\["' + [regex]::Escape($code) + '"\]\s*=\s*\d+') {
                        $skipUsed = $true
                        continue
                    }
                    [void]$uout.Add($ul)
                }
                if ($skipUsed) {
                    [System.IO.File]::WriteAllLines($usedFile, $uout, (New-Object System.Text.UTF8Encoding($false)))
                }
            }
        }
        Write-Output 'DELETED'
    } else {
        Write-Output 'NOTFOUND'
    }
}

# ---------------------------------------------------------------
# getstorage: write the existing storage of a code to %TMPSTORAGE%
# (used on overwrite so players who redeemed keep their flag)
# ---------------------------------------------------------------
function Get-Storage {
    $code = $env:COD
    $path = $env:CODESFILE
    if (-not (Test-Path -LiteralPath $path)) { return }
    $lines = [System.IO.File]::ReadAllLines($path)
    $in = $false
    foreach ($t in $lines) {
        $x = $t.Trim()
        if (-not $in -and $x -match 'CodeRedeemData\["' + [regex]::Escape($code) + '"\]\s*=\s*\{') {
            $in = $true
            continue
        }
        if ($in) {
            if ($x -match '^storage\s*=\s*(\d+)') {
                [System.IO.File]::WriteAllText($env:TMPSTORAGE, $matches[1], (New-Object System.Text.UTF8Encoding($false)))
                return
            }
            if ($x -eq '}') { return }
        }
    }
}

switch ($Mode) {
    'fold'       { Fold-Code }
    'view'       { Show-Codes }
    'delete'     { Remove-Code }
    'overwrite'  { Remove-Code -KeepUsed }
    'getstorage' { Get-Storage }
    default      { Write-Output 'UNKNOWN MODE' }
}
