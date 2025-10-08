# validate-nomenclature.ps1
# Valida nomenclatura de documentos e código conforme padrões DDD Workflow v2.0

param(
    [string]$Path = ".",
    [switch]$CheckCode,
    [switch]$Verbose
)

$ErrorCount = 0
$WarningCount = 0

Write-Host "`n📝 DDD Workflow Nomenclature Validator v2.0`n" -ForegroundColor Cyan

# Carregar padrões de nomenclatura
$businessTermsPT = @{
    "Estrategia" = "Strategy"
    "Perna" = "StrategyLeg"
    "Opcao" = "Option"
    "Portfolio" = "Portfolio"
    "Risco" = "Risk"
    "Greeks" = "Greeks"
    "Expiracao" = "Expiration"
    "Strike" = "Strike"
    "Premium" = "Premium"
}

# 1. Validar documentos em 00-doc-ddd
Write-Host "📋 Validating document nomenclature in 00-doc-ddd..." -ForegroundColor Yellow

$validDocPattern = @{
    "02-strategic-design" = '^SDA-\d{2}-.*\.md$'
    "03-ux-design" = '^UXD-\d{2}-.*\.md$'
    "04-tactical-design" = '^DE-\d{2}-.*\.md$'
    "05-database-design" = '^DBA-\d{2}-.*\.md$'
    "06-quality-assurance" = '^QAE-\d{2}-.*\.md$'
    "07-github-management" = '^GM-\d{2}-.*\.md$'
    "00-feedback" = '^FEEDBACK-\d{3}-[A-Z]+-[A-Z]+-.*\.md$'
}

foreach ($folder in $validDocPattern.Keys) {
    $folderPath = "00-doc-ddd/$folder"

    if (Test-Path $folderPath) {
        $docs = Get-ChildItem $folderPath -Filter "*.md" -File

        foreach ($doc in $docs) {
            if ($doc.Name -eq "README.md") { continue }

            $pattern = $validDocPattern[$folder]

            if ($doc.Name -match $pattern) {
                if ($Verbose) {
                    Write-Host "  ✅ $folder/$($doc.Name)" -ForegroundColor Green
                }
            } else {
                Write-Host "  ❌ Invalid name: $folder/$($doc.Name)" -ForegroundColor Red
                Write-Host "     Expected pattern: $pattern" -ForegroundColor Gray
                $ErrorCount++
            }

            # Validar placeholders não substituídos no conteúdo
            $content = Get-Content $doc.FullName -Raw

            if ($content -match '\[PROJECT_NAME\]') {
                Write-Host "  ⚠️  Placeholder [PROJECT_NAME] not replaced in $($doc.Name)" -ForegroundColor Yellow
                $WarningCount++
            }

            if ($content -match '\[YYYY-MM-DD\]') {
                Write-Host "  ⚠️  Placeholder [YYYY-MM-DD] not replaced in $($doc.Name)" -ForegroundColor Yellow
                $WarningCount++
            }

            if ($content -match '\[EpicName\]' -and $folder -eq "04-tactical-design") {
                Write-Host "  ⚠️  Placeholder [EpicName] not replaced in $($doc.Name)" -ForegroundColor Yellow
                $WarningCount++
            }
        }
    }
}

# 2. Validar código backend (se solicitado)
if ($CheckCode) {
    Write-Host "`n💻 Validating backend code nomenclature..." -ForegroundColor Yellow

    if (Test-Path "02-backend") {
        # Validar Aggregates usam inglês
        $domainFiles = Get-ChildItem "02-backend" -Recurse -Filter "*.cs" | Where-Object {
            $_.FullName -match "\\Domain\\" -and $_.Name -notmatch "\.Tests\."
        }

        foreach ($file in $domainFiles) {
            $content = Get-Content $file.FullName -Raw

            # Verificar se há termos em português em classes de domínio
            foreach ($termPT in $businessTermsPT.Keys) {
                if ($content -match "class\s+$termPT\b") {
                    $termEN = $businessTermsPT[$termPT]
                    Write-Host "  ⚠️  Portuguese term in code: '$termPT' in $($file.Name)" -ForegroundColor Yellow
                    Write-Host "     Should use: '$termEN'" -ForegroundColor Gray
                    $WarningCount++
                }
            }

            # Validar Aggregate tem método AddDomainEvent
            if ($content -match "class\s+\w+\s*:\s*Entity\s*<") {
                if ($content -notmatch "AddDomainEvent|RaiseDomainEvent") {
                    Write-Host "  ⚠️  Aggregate without domain event support: $($file.Name)" -ForegroundColor Yellow
                    $WarningCount++
                }
            }
        }

        # Validar Value Objects são immutable
        $valueObjects = $domainFiles | Where-Object {
            (Get-Content $_.FullName -Raw) -match "record\s+\w+|class\s+\w+\s*:\s*ValueObject"
        }

        foreach ($vo in $valueObjects) {
            $content = Get-Content $vo.FullName -Raw

            if ($content -match "\{\s*get;\s*set;\s*\}") {
                Write-Host "  ❌ Value Object with setter: $($vo.Name)" -ForegroundColor Red
                Write-Host "     Value Objects must be immutable" -ForegroundColor Gray
                $ErrorCount++
            }
        }
    }

    # 3. Validar código frontend (se solicitado)
    Write-Host "`n🎨 Validating frontend code nomenclature..." -ForegroundColor Yellow

    if (Test-Path "01-frontend") {
        # Validar componentes seguem PascalCase
        $componentFiles = Get-ChildItem "01-frontend/src/components" -Recurse -Filter "*.tsx" -ErrorAction SilentlyContinue

        foreach ($component in $componentFiles) {
            if ($component.BaseName -cnotmatch '^[A-Z][a-zA-Z0-9]*$') {
                Write-Host "  ⚠️  Component not PascalCase: $($component.Name)" -ForegroundColor Yellow
                $WarningCount++
            }

            $content = Get-Content $component.FullName -Raw

            # Validar export default
            if ($content -notmatch "export\s+default") {
                Write-Host "  ⚠️  Component without default export: $($component.Name)" -ForegroundColor Yellow
                $WarningCount++
            }
        }

        # Validar hooks seguem use* pattern
        $hookFiles = Get-ChildItem "01-frontend/src/hooks" -Recurse -Filter "*.ts" -ErrorAction SilentlyContinue

        foreach ($hook in $hookFiles) {
            if ($hook.BaseName -notmatch '^use[A-Z]') {
                Write-Host "  ❌ Hook not following use* pattern: $($hook.Name)" -ForegroundColor Red
                $ErrorCount++
            }
        }
    }
}

# 4. Validar templates
Write-Host "`n📝 Validating template nomenclature..." -ForegroundColor Yellow

$templateFolders = Get-ChildItem ".agents/templates" -Directory

foreach ($folder in $templateFolders) {
    $templates = Get-ChildItem $folder.FullName -Filter "*.template.md"

    foreach ($template in $templates) {
        # Validar template tem .template.md extensão
        if ($template.Name -notmatch '\.template\.md$') {
            Write-Host "  ⚠️  Template without .template.md extension: $($template.Name)" -ForegroundColor Yellow
            $WarningCount++
        }

        # Validar template tem placeholders
        $content = Get-Content $template.FullName -Raw

        $requiredPlaceholders = @('[PROJECT_NAME]', '[YYYY-MM-DD]')
        $missingPlaceholders = $requiredPlaceholders | Where-Object { $content -notmatch [regex]::Escape($_) }

        if ($missingPlaceholders.Count -gt 0) {
            Write-Host "  ⚠️  Template missing placeholders: $($template.Name)" -ForegroundColor Yellow
            Write-Host "     Missing: $($missingPlaceholders -join ', ')" -ForegroundColor Gray
            $WarningCount++
        }

        if ($Verbose -and $missingPlaceholders.Count -eq 0) {
            Write-Host "  ✅ $($folder.Name)/$($template.Name)" -ForegroundColor Green
        }
    }
}

# 5. Validar Feedback files nomenclatura
Write-Host "`n💬 Validating feedback nomenclature..." -ForegroundColor Yellow

if (Test-Path "00-doc-ddd/00-feedback") {
    $feedbacks = Get-ChildItem "00-doc-ddd/00-feedback" -Filter "FEEDBACK-*.md"

    foreach ($feedback in $feedbacks) {
        # Pattern: FEEDBACK-NNN-FROM-TO-title.md
        if ($feedback.Name -match '^FEEDBACK-(\d{3})-([A-Z]+)-([A-Z]+)-(.+)\.md$') {
            $number = $Matches[1]
            $from = $Matches[2]
            $to = $Matches[3]
            $title = $Matches[4]

            # Validar agents existem
            $validAgents = @("SDA", "UXD", "DE", "DBA", "FE", "QAE", "GM")

            if ($from -notin $validAgents) {
                Write-Host "  ❌ Invalid source agent: $from in $($feedback.Name)" -ForegroundColor Red
                $ErrorCount++
            }

            if ($to -notin $validAgents) {
                Write-Host "  ❌ Invalid target agent: $to in $($feedback.Name)" -ForegroundColor Red
                $ErrorCount++
            }

            if ($Verbose -and $from -in $validAgents -and $to -in $validAgents) {
                Write-Host "  ✅ $($feedback.Name)" -ForegroundColor Green
            }
        } else {
            Write-Host "  ❌ Invalid feedback name: $($feedback.Name)" -ForegroundColor Red
            Write-Host "     Expected: FEEDBACK-NNN-FROM-TO-title.md" -ForegroundColor Gray
            $ErrorCount++
        }
    }
}

# Summary
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "📊 NOMENCLATURE VALIDATION SUMMARY" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

if ($ErrorCount -eq 0 -and $WarningCount -eq 0) {
    Write-Host "`n✅ All nomenclature checks passed!" -ForegroundColor Green
    exit 0
} elseif ($ErrorCount -eq 0) {
    Write-Host "`n⚠️  Warnings: $WarningCount" -ForegroundColor Yellow
    Write-Host "Nomenclature is mostly correct but some improvements recommended." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "`n❌ Errors: $ErrorCount" -ForegroundColor Red
    Write-Host "⚠️  Warnings: $WarningCount" -ForegroundColor Yellow
    Write-Host "`nPlease fix errors before proceeding." -ForegroundColor Red
    exit 1
}
