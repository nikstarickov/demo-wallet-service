# start-db.ps1
Write-Host "Очистка старых контейнеров..." -ForegroundColor Yellow
docker stop wallet-postgres-dev 2>$null
docker rm wallet-postgres-dev 2>$null
docker volume rm postgres_dev_data 2>$null

Write-Host "Запуск PostgreSQL..." -ForegroundColor Green
docker run -d `
  --name wallet-postgres-dev `
  -e POSTGRES_DB=wallet_dev `
  -e POSTGRES_USER=dev_user `
  -e POSTGRES_PASSWORD=dev_password `
  -p 5432:5432 `
  -v postgres_dev_data:/var/lib/postgresql/data `
  postgres:15-alpine

Write-Host "Ожидание инициализации базы..." -ForegroundColor Cyan
Start-Sleep -Seconds 5

# Проверка
$maxAttempts = 10
$attempt = 0
while ($attempt -lt $maxAttempts) {
    $attempt++
    Write-Host "Попытка $attempt/$maxAttempts..." -ForegroundColor Gray
    $result = docker exec wallet-postgres-dev psql -U dev_user -d wallet_dev -c "SELECT 1;" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ База данных готова!" -ForegroundColor Green
        Write-Host "PostgreSQL: localhost:5432" -ForegroundColor Cyan
        Write-Host "База: wallet_dev" -ForegroundColor Cyan
        Write-Host "Пользователь: dev_user" -ForegroundColor Cyan
        Write-Host "Пароль: dev_password" -ForegroundColor Cyan
        break
    }
    Start-Sleep -Seconds 2
}

if ($attempt -eq $maxAttempts) {
    Write-Host "❌ Не удалось подключиться к базе" -ForegroundColor Red
    docker logs wallet-postgres-dev
}