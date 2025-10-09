# validate-structure.ps1
# Valida estrutura do repositório DDD Workflow v2.0

param(
    [switch]$Verbose
)

$ErrorCount = 0
$WarningCount = 0
$config = Get-Content "workflow-config.json" | ConvertFrom-Json

Write-Host "`n🔍 DDD Workflow Structure Validator v2.0`n" -ForegroundColor Cyan

# 1. Validar pastas obrigatórias
Write-Host "📁 Validating folder structure..." -ForegroundColor Yellow

$requiredFolders = @(
    "00-doc-ddd/00-feedback",
    "00-doc-ddd/01-inputs-raw",
    "00-doc-ddd/02-strategic-design",
    "00-doc-ddd/03-ux-design",
    "00-doc-ddd/04-tactical-design",
    "00-doc-ddd/05-database-design",
    "00-doc-ddd/06-quality-assurance",
    "00-doc-ddd/07-github-management",
    ".agents/templates/01-strategic-design",
    ".agents/templates/02-ux-design",
    ".agents/templates/03-tactical-design",
    ".agents/templates/04-database-design",
    ".agents/templates/05-quality-assurance",
    ".agents/templates/06-github-management",
    ".agents/templates/07-feedback"
)

foreach ($folder in $requiredFolders) {
    if (Test-Path $folder) {
        if ($Verbose) { Write-Host "  ✅ $folder" -ForegroundColor Green }
    } else {
        Write-Host "  ❌ Missing: $folder" -ForegroundColor Red
        $ErrorCount++
    }
}

# 2. Validar arquivos de configuração
Write-Host "`n📄 Validating configuration files..." -ForegroundColor Yellow

$requiredFiles = @(
    ".ddd-workflow-config.json",
    ".agents/docs/00-Workflow-Guide.md",
    ".agents/docs/01-Agents-Overview.md",
    ".agents/docs/02-Nomenclature-Standards.md"
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        if ($Verbose) { Write-Host "  ✅ $file" -ForegroundColor Green }
    } else {
        Write-Host "  ❌ Missing: $file" -ForegroundColor Red
        $ErrorCount++
    }
}

# 3. Validar agents XML
Write-Host "`n🤖 Validating agent definitions..." -ForegroundColor Yellow

$requiredAgents = @(
    "10-SDA - Strategic Domain Analyst.xml",
    "20-UXD - User Experience Designer.xml",
    "30-DE - Domain Engineer.xml",
    "40-DBA - Database Administrator.xml",
    "50-FE - Frontend Engineer.xml",
    "60-QAE - Quality Assurance Engineer.xml",
    "70-GM - GitHub Manager.xml"
)

foreach ($agent in $requiredAgents) {
    $agentPath = ".agents/$agent"
    if (Test-Path $agentPath) {
        # Validar XML estrutura
        try {
            [xml]$xml = Get-Content $agentPath
            $deliverables = $xml.agent.deliverables.deliverable

            if ($Verbose) {
                Write-Host "  ✅ $agent ($($deliverables.Count) deliverables)" -ForegroundColor Green
            }

            # Validar templates referenciados existem
            foreach ($deliverable in $deliverables) {
                $templatePath = $deliverable.template
                if ($templatePath -and -not (Test-Path $templatePath)) {
                    Write-Host "    ⚠️  Template missing: $templatePath" -ForegroundColor Yellow
                    $WarningCount++
                }
            }
        } catch {
            Write-Host "  ❌ Invalid XML: $agent" -ForegroundColor Red
            $ErrorCount++
        }
    } else {
        Write-Host "  ❌ Missing: $agent" -ForegroundColor Red
        $ErrorCount++
    }
}

# 4. Validar templates
Write-Host "`n📝 Validating templates..." -ForegroundColor Yellow

$requiredTemplates = @(
    ".agents/templates/01-strategic-design/SDA-01-Event-Storming.template.md",
    ".agents/templates/01-strategic-design/SDA-02-Context-Map.template.md",
    ".agents/templates/01-strategic-design/SDA-03-Epic-Backlog.template.md",
    ".agents/templates/02-ux-design/UXD-01-User-Flows.template.md",
    ".agents/templates/02-ux-design/UXD-02-Wireframes.template.md",
    ".agents/templates/02-ux-design/UXD-03-Component-Library.template.md",
    ".agents/templates/03-tactical-design/DE-01-[EpicName]-Tactical-Model.template.md",
    ".agents/templates/04-database-design/DBA-01-[EpicName]-Schema-Review.template.md",
    ".agents/templates/05-quality-assurance/QAE-01-Test-Strategy.template.md",
    ".agents/templates/06-github-management/GM-01-GitHub-Setup.template.md",
    ".agents/templates/07-feedback/FEEDBACK.template.md"
)

foreach ($template in $requiredTemplates) {
    if (Test-Path $template) {
        if ($Verbose) { Write-Host "  ✅ $template" -ForegroundColor Green }
    } else {
        Write-Host "  ❌ Missing: $template" -ForegroundColor Red
        $ErrorCount++
    }
}

# 5. Validar nomenclatura de documentos existentes
Write-Host "`n📋 Validating existing documents nomenclature..." -ForegroundColor Yellow

$docFolders = Get-ChildItem "00-doc-ddd" -Directory | Where-Object { $_.Name -match '^\d{2}-' }

foreach ($folder in $docFolders) {
    $docs = Get-ChildItem $folder.FullName -Filter "*.md"

    foreach ($doc in $docs) {
        $validPattern = '^(SDA|UXD|DE|DBA|FE|QAE|GM)-\d{2}-.*\.md$'

        if ($doc.Name -notmatch $validPattern -and $doc.Name -ne "README.md") {
            Write-Host "  ⚠️  Non-standard name: $($folder.Name)/$($doc.Name)" -ForegroundColor Yellow
            $WarningCount++
        }
    }
}

# 6. Validar feedback files
Write-Host "`n💬 Validating feedback files..." -ForegroundColor Yellow

if (Test-Path "00-doc-ddd/00-feedback") {
    $feedbacks = Get-ChildItem "00-doc-ddd/00-feedback" -Filter "FEEDBACK-*.md"

    foreach ($feedback in $feedbacks) {
        $validPattern = '^FEEDBACK-\d{3}-[A-Z]+-[A-Z]+-.*\.md$'

        if ($feedback.Name -match $validPattern) {
            if ($Verbose) { Write-Host "  ✅ $($feedback.Name)" -ForegroundColor Green }
        } else {
            Write-Host "  ⚠️  Non-standard feedback name: $($feedback.Name)" -ForegroundColor Yellow
            $WarningCount++
        }
    }

    if ($feedbacks.Count -eq 0 -and $Verbose) {
        Write-Host "  [INFO] No feedback files found (OK for new projects)" -ForegroundColor Cyan
    }
}

# 7. Validar duplicatas (pastas antigas)
Write-Host "`n🔍 Checking for duplicates/old folders..." -ForegroundColor Yellow

$oldFolders = @(
    "00-doc-ddd/05-security",
    "00-doc-ddd/10-github-management"
)

$foundOld = $false
foreach ($oldFolder in $oldFolders) {
    if (Test-Path $oldFolder) {
        Write-Host "  ⚠️  Old folder still present: $oldFolder" -ForegroundColor Yellow
        $WarningCount++
        $foundOld = $true
    }
}

if (-not $foundOld -and $Verbose) {
    Write-Host "  ✅ No old folders found" -ForegroundColor Green
}

# Summary
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "📊 VALIDATION SUMMARY" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

if ($ErrorCount -eq 0 -and $WarningCount -eq 0) {
    Write-Host "`n✅ All checks passed! Structure is valid." -ForegroundColor Green
    exit 0
} elseif ($ErrorCount -eq 0) {
    Write-Host "`n⚠️  Warnings: $WarningCount" -ForegroundColor Yellow
    Write-Host "Structure is valid but some improvements recommended." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "`nErrors: $ErrorCount" -ForegroundColor Red
    Write-Host "Warnings: $WarningCount" -ForegroundColor Yellow
    Write-Host "Please fix errors before proceeding." -ForegroundColor Red
    exit 1
}
