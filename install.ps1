# Amateur Radio Stack - script d'installation (Windows 10/11)
# Depot : https://github.com/f4izc/amateur-radio-stack
#
# Lancement :
#   irm https://f4izc.github.io/amateur-radio-stack/install.ps1 | iex
#
# Ce script :
#   1. telecharge le catalogue (software.json) et les dernieres versions (versions.json)
#   2. affiche un menu par categorie (fenetre, ou liste numerotee en console)
#   3. pour chaque logiciel choisi : telecharge et lance l'installeur de la derniere release GitHub,
#      ou ouvre la page de telechargement officielle quand il n'y a pas de release GitHub
# Les webtools (PHP, Docker) ne sont jamais installes par ce script.
#
# Note : ce fichier est volontairement en ASCII (sans accents) pour s'executer
# correctement quel que soit l'encodage utilise par PowerShell au telechargement.

param([switch]$DryRun)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { }

$Base = 'https://f4izc.github.io/amateur-radio-stack'

function Get-Json([string]$Name) {
    $r = Invoke-WebRequest -Uri "$Base/$Name" -UseBasicParsing
    $text = [Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()).TrimStart([char]0xFEFF)
    return ($text | ConvertFrom-Json)
}

function Write-Title([string]$Text) {
    Write-Host ''
    Write-Host $Text -ForegroundColor Cyan
}

Write-Title 'Amateur Radio Stack - installation des logiciels radio'

try {
    $catalog  = @(Get-Json 'software.json')
    $versions = Get-Json 'versions.json'
} catch {
    Write-Host "Impossible de recuperer le catalogue : $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Verifie ta connexion, puis relance le script."
    return
}

# Webtools et entrees sans methode d'installation : exclus du menu
$items = @($catalog |
    Where-Object { $_.type -ne 'webtool' -and $_.install } |
    Sort-Object category, name)

if ($items.Count -eq 0) {
    Write-Host 'Aucun logiciel installable dans le catalogue.' -ForegroundColor Yellow
    return
}

$rows = @($items | ForEach-Object {
    $mode = if ($_.install.method -eq 'github') { 'Installation automatique' } else { 'Ouvre la page officielle' }
    [pscustomobject]@{
        Categorie   = $_.category
        Logiciel    = $_.name
        Mode        = $mode
        Description = $_.description
        Id          = $_.id
    }
})

# --- Menu -------------------------------------------------------------------
$selection = @()
$hasGrid = $PSVersionTable.PSVersion.Major -lt 6 -and (Get-Command Out-GridView -ErrorAction SilentlyContinue)

if ($hasGrid) {
    Write-Host 'Une fenetre de selection s''ouvre : Ctrl+clic pour choisir plusieurs logiciels, puis OK.'
    $selection = @($rows | Out-GridView -Title 'Amateur Radio Stack : choisis les logiciels a installer' -PassThru)
} else {
    $i = 0
    $currentCat = ''
    foreach ($r in $rows) {
        if ($r.Categorie -ne $currentCat) {
            $currentCat = $r.Categorie
            Write-Host ''
            Write-Host "== $currentCat ==" -ForegroundColor Yellow
        }
        $i++
        Write-Host ('{0,3}. {1}  ({2})' -f $i, $r.Logiciel, $r.Mode)
    }
    Write-Host ''
    $answer = Read-Host "Numeros a installer (ex: 1,3,5), 'tout' pour tout, vide pour quitter"
    if ($answer -match '^\s*tout\s*$') {
        $selection = $rows
    } elseif ($answer.Trim()) {
        foreach ($part in ($answer -split '[,; ]+')) {
            $n = 0
            if ([int]::TryParse($part, [ref]$n) -and $n -ge 1 -and $n -le $rows.Count) {
                $selection += $rows[$n - 1]
            }
        }
    }
}

if ($selection.Count -eq 0) {
    Write-Host 'Rien de selectionne, fin du script.'
    return
}

# --- Installation -----------------------------------------------------------
function Install-App($app) {
    Write-Title "==> $($app.name)"

    switch ($app.install.method) {
        'github' {
            $v = $versions.($app.github)
            if (-not $v -or -not $v.assets) {
                Write-Warning "Aucune release connue pour $($app.name). Ouverture de la page officielle."
                if (-not $DryRun) { Start-Process $app.homepage }
                return 'page ouverte (release introuvable)'
            }

            $candidates = @($v.assets | Where-Object { $_.name -match $app.asset_regex })
            if ($candidates.Count -eq 0) {
                Write-Warning "Aucun installeur ne correspond dans la release $($v.tag). Ouverture de la page officielle."
                if (-not $DryRun) { Start-Process $app.homepage }
                return 'page ouverte (installeur introuvable)'
            }

            # On prefere un fichier nomme setup/install, sinon le premier par ordre alphabetique
            $asset = $candidates |
                Sort-Object @{ Expression = { if ($_.name -match 'setup|install') { 0 } else { 1 } } }, name |
                Select-Object -First 1

            $dest = Join-Path $env:TEMP $asset.name
            Write-Host "Version $($v.tag) : $($asset.name)"
            if ($DryRun) { return 'simulation (rien telecharge)' }

            Write-Host 'Telechargement...'
            Invoke-WebRequest -Uri $asset.url -OutFile $dest -UseBasicParsing

            $silent = $app.install.silent_args
            Write-Host 'Lancement de l''installeur (suis les etapes a l''ecran)...'
            if ($asset.name -match '\.msi$') {
                $msiArgs = "/i `"$dest`" $silent"
                Start-Process msiexec.exe -ArgumentList $msiArgs -Wait
            } elseif ($silent) {
                Start-Process $dest -ArgumentList $silent -Wait
            } else {
                Start-Process $dest -Wait
            }
            return 'installeur lance'
        }
        'page' {
            $url = if ($app.install.url) { $app.install.url } else { $app.homepage }
            Write-Host "Ouverture de la page officielle : $url"
            if (-not $DryRun) { Start-Process $url }
            return 'page ouverte'
        }
        default {
            Write-Warning "Methode d'installation inconnue pour $($app.name)."
            return 'ignore'
        }
    }
}

$report = @()
foreach ($sel in $selection) {
    $app = $items | Where-Object { $_.id -eq $sel.Id } | Select-Object -First 1
    if (-not $app) { continue }
    try {
        $result = Install-App $app
    } catch {
        Write-Host "Echec pour $($app.name) : $($_.Exception.Message)" -ForegroundColor Red
        $result = 'echec'
    }
    $report += [pscustomobject]@{ Logiciel = $app.name; Resultat = $result }
}

Write-Title 'Recapitulatif'
$report | Format-Table -AutoSize
Write-Host 'Termine. Les licences des logiciels (VARA par exemple) restent a ta charge.'
if ($Host.Name -eq 'ConsoleHost') { [void](Read-Host 'Appuie sur Entree pour fermer') }
