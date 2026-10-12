# Windows equivalent of lab.sh. Examples: ./scripts/lab.ps1 step 1
$ErrorActionPreference = 'Stop'
$labRoot = Split-Path $PSScriptRoot -Parent
Push-Location $labRoot
try {
    $labPython = '/home/airflow/lab-venv/bin/python'
    $action = $args[0]
    $rest = @($args | Select-Object -Skip 1)
    switch ($action) {
        { $_ -in 'step','exp','verify' } { docker compose exec -T -w /opt/lab airflow $labPython -m pipeline.cli $action @rest }
        'cli' { docker compose exec -T -w /opt/lab airflow $labPython -m pipeline.cli @rest }
        'test' { docker compose exec -T -w /opt/lab airflow $labPython -m unittest discover -s tests }
        'run' { docker compose exec -T -w /opt/lab airflow bash scripts/run_pipeline.sh @rest }
        'dbt' { docker compose exec -T -w /opt/dbt airflow /home/airflow/lab-venv/bin/dbt @rest --no-use-colors }
        'shell' { docker compose exec airflow bash }
        default { throw 'Usage: ./scripts/lab.ps1 <step|exp|verify|cli|test|run|dbt|shell> [arguments]' }
    }
    $labExitCode = $LASTEXITCODE
} finally {
    Pop-Location
}
exit $labExitCode
