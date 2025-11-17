# AWS Bedrock + OIDC Setup Guide для Claude Code GitHub Actions

## 📋 Обзор

Эта инструкция поможет настроить безопасную интеграцию Claude Code GitHub Actions с AWS Bedrock используя OIDC (OpenID Connect) для региона **eu-north-1** (Stockholm).

### Почему OIDC?

- ✅ **Безопасность**: Временные токены вместо долгоживущих ключей
- ✅ **Автоматизация**: Автоматическая ротация credentials
- ✅ **Гран control**: Ограничение доступа по репозиторию и ветке
- ✅ **Соответствие best practices**: Рекомендуется AWS и GitHub

## 🎯 Что будет настроено

1. OIDC Identity Provider в AWS IAM
2. IAM Role с правами доступа к Bedrock
3. Trust Policy для вашего GitHub репозитория
4. GitHub Workflow с OIDC authentication
5. Минимальные необходимые права (Principle of Least Privilege)

## 📝 Предварительные требования

- [ ] AWS аккаунт с правами администратора IAM
- [ ] Доступ к Amazon Bedrock включен
- [ ] Доступ к Claude моделям в регионе `eu-north-1` запрошен
- [ ] GitHub репозиторий с admin правами
- [ ] GitHub App установлено (или используется GITHUB_TOKEN)

## 🔧 Шаг 1: Включение Amazon Bedrock

### 1.1 Проверка доступа к Bedrock

1. Откройте AWS Console
2. Перейдите в **Amazon Bedrock**
3. Убедитесь, что сервис доступен в регионе **EU (Stockholm) eu-north-1**

### 1.2 Запрос доступа к моделям Claude

1. В Bedrock Console выберите **Model access** в боковом меню
2. Нажмите **Manage model access**
3. Найдите и отметьте модели Anthropic Claude:
   - Claude 3.5 Sonnet
   - Claude 3 Opus (опционально)
   - Claude 3 Haiku (опционально)
4. Нажмите **Request model access**
5. Заполните форму и отправьте запрос
6. Ожидайте подтверждения (обычно мгновенно или в течение нескольких минут)

### Доступные модели в eu-north-1

```text
eu.anthropic.claude-3-5-sonnet-20241022-v2:0
eu.anthropic.claude-3-5-haiku-20241022-v1:0
eu.anthropic.claude-3-opus-20240229-v1:0
```

> **Примечание**: Модель ID включает префикс региона `eu.` для европейских регионов.

## 🔐 Шаг 2: Настройка OIDC Identity Provider

### 2.1 Создание OIDC Provider в AWS

1. Откройте **IAM Console**: https://console.aws.amazon.com/iam/
2. В левом меню выберите **Identity providers**
3. Нажмите **Add provider**

### 2.2 Конфигурация провайдера

Заполните форму:

**Provider type**: `OpenID Connect`

**Provider URL**:
```text
https://token.actions.githubusercontent.com
```

**Audience**:
```text
sts.amazonaws.com
```

4. Нажмите **Get thumbprint** (загрузится автоматически)
5. Нажмите **Add provider**

### 2.3 Подтверждение создания

После создания вы увидите:
```text
ARN: arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com
```

Сохраните этот ARN - он понадобится позже.

## 👤 Шаг 3: Создание IAM Role

### 3.1 Начало создания роли

1. В IAM Console выберите **Roles** в левом меню
2. Нажмите **Create role**

### 3.2 Выбор типа доверенной сущности

**Trusted entity type**: `Web identity`

**Identity provider**: Выберите созданный OIDC provider
```text
token.actions.githubusercontent.com
```

**Audience**:
```text
sts.amazonaws.com
```

### 3.3 Настройка условий доступа (ВАЖНО!)

Нажмите **Add condition** для ограничения доступа:

**Condition 1 - Ограничение по организации/пользователю:**
- Condition key: `token.actions.githubusercontent.com:sub`
- Operator: `StringLike`
- Value: `repo:evgenygurin/*:*`
  (это разрешит все ваши репозитории)

**ИЛИ для конкретного репозитория:**
- Value: `repo:evgenygurin/claude-code-github-action-docs:ref:refs/heads/main`
  (только этот репозиторий и ветка main)

**Condition 2 - Ограничение по audience:**
- Condition key: `token.actions.githubusercontent.com:aud`
- Operator: `StringEquals`
- Value: `sts.amazonaws.com`

Нажмите **Next**

### 3.4 Присвоение прав (Permissions)

**Вариант A: Использовать готовую политику (проще)**

1. В поиске найдите: `AmazonBedrockFullAccess`
2. Отметьте эту политику
3. Нажмите **Next**

**Вариант B: Создать минимальную custom policy (безопаснее)**

1. Нажмите **Create policy**
2. Перейдите на вкладку **JSON**
3. Вставьте следующую политику:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "BedrockInvokeModel",
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": "arn:aws:bedrock:eu-north-1::foundation-model/anthropic.claude-*"
    }
  ]
}
```

4. Нажмите **Next**
5. Policy name: `GitHubActionsBedrockMinimal`
6. Нажмите **Create policy**
7. Вернитесь к созданию роли и выберите эту политику

### 3.5 Имя и описание роли

**Role name**:
```text
GitHubActionsBedrockRole
```

**Description**:
```bash
OIDC role for GitHub Actions to access AWS Bedrock in eu-north-1
```

### 3.6 Проверка Trust Policy

Перед созданием проверьте Trust policy (автоматически сгенерированную):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:evgenygurin/claude-code-github-action-docs:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

### 3.7 Создание роли

Нажмите **Create role**

### 3.8 Сохранение Role ARN

После создания скопируйте Role ARN:
```text
arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsBedrockRole
```

**Этот ARN понадобится для GitHub Secrets!**

## 🔑 Шаг 4: Настройка GitHub Secrets

### 4.1 Добавление секретов

1. Откройте ваш репозиторий на GitHub
2. **Settings** → **Secrets and variables** → **Actions**
3. Нажмите **New repository secret**

### 4.2 Секрет с Role ARN

**Name**:
```text
AWS_ROLE_TO_ASSUME
```

**Secret**:
```text
arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsBedrockRole
```

(вставьте ваш реальный ARN из предыдущего шага)

Нажмите **Add secret**

### 4.3 Секрет с регионом (опционально)

**Name**:
```text
AWS_REGION
```

**Secret**:
```text
eu-north-1
```

Нажмите **Add secret**

### 4.4 GitHub App credentials (если используете)

Если используете собственное GitHub App:

**Name**: `APP_ID`
**Secret**: ID вашего приложения

**Name**: `APP_PRIVATE_KEY`
**Secret**: Содержимое .pem файла

## 📄 Шаг 5: Создание GitHub Workflow

См. готовый workflow в файле: `.github/workflows/claude-bedrock-eu.yml`

Или используйте example: `examples/claude-bedrock-eu-oidc.yml`

## ✅ Шаг 6: Тестирование

### 6.1 Создайте тестовый issue

1. В вашем репозитории создайте новый issue
2. Напишите в описании:
```text
@claude привет! Можешь ли ты помочь мне с настройкой AWS Bedrock?
```

### 6.2 Проверьте workflow

1. Перейдите на вкладку **Actions**
2. Найдите запущенный workflow `Claude Code Action (Bedrock EU)`
3. Откройте workflow run
4. Проверьте логи:
   - OIDC authentication успешен
   - Claude отвечает на issue

### 6.3 Ожидаемый результат

Claude должен:
- Успешно аутентифицироваться через OIDC
- Подключиться к Bedrock в регионе eu-north-1
- Ответить в комментарии к issue

## 🔍 Troubleshooting

### Ошибка: "Not authorized to perform sts:AssumeRoleWithWebIdentity"

**Причина**: Trust policy не соответствует репозиторию/ветке

**Решение**:
1. Проверьте Trust policy роли
2. Убедитесь, что `token.actions.githubusercontent.com:sub` правильный
3. Формат должен быть: `repo:OWNER/REPO:ref:refs/heads/BRANCH`

### Ошибка: "Access Denied" при вызове Bedrock

**Причина**: Недостаточно прав у роли

**Решение**:
1. Проверьте, что политика `AmazonBedrockFullAccess` или custom policy присоединена к роли
2. Убедитесь, что у вас есть доступ к моделям Claude в Bedrock
3. Проверьте регион в workflow (должен быть `eu-north-1`)

### Ошибка: "Model not found"

**Причина**: Неправильный model ID для региона

**Решение**:
- Используйте model ID с префиксом региона: `eu.anthropic.claude-...`
- Не используйте: `us.anthropic.claude-...` или без префикса

### Ошибка: "Workflow doesn't trigger"

**Причина**: Неправильная конфигурация triggers

**Решение**:
1. Проверьте, что workflow файл в `.github/workflows/`
2. Проверьте синтаксис YAML
3. Убедитесь, что используется `@claude` в комментарии
4. Проверьте, что GitHub Actions включены в репозитории

## 📊 Мониторинг и Логи

### CloudTrail

Все вызовы к Bedrock логируются в CloudTrail:

1. AWS Console → CloudTrail → Event history
2. Фильтры:
   - Event source: `bedrock.amazonaws.com`
   - User name: Ваша GitHub роль
   - Region: eu-north-1

### Cost Monitoring

1. AWS Console → Cost Explorer
2. Фильтры:
   - Service: Amazon Bedrock
   - Region: EU (Stockholm)
3. Настройте budget alerts

## 🔒 Безопасность Best Practices

### 1. Минимальные права

✅ Используйте custom policy вместо `AmazonBedrockFullAccess`
✅ Ограничьте доступ только к необходимым моделям
✅ Ограничьте доступ только к необходимым регионам

### 2. Ограничение по репозиторию

✅ В Trust policy указывайте конкретный репозиторий
✅ Используйте ограничение по ветке (например, только main)
❌ Не используйте wildcard `*:*` для всех репозиториев

### 3. Мониторинг

✅ Включите CloudTrail для всех регионов
✅ Настройте алерты на необычную активность
✅ Регулярно проверяйте логи доступа

### 4. Ротация

✅ OIDC токены автоматически ротируются (ничего не нужно делать!)
✅ Регулярно проверяйте и обновляйте политики
✅ Удаляйте неиспользуемые роли

## 📚 Дополнительные ресурсы

- [AWS OIDC for GitHub Actions](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Amazon Bedrock User Guide](https://docs.aws.amazon.com/bedrock/)
- [Claude Models in Bedrock](https://docs.anthropic.com/en/api/claude-on-amazon-bedrock)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

## ✅ Чеклист настройки

Убедитесь, что выполнено:

- [ ] Amazon Bedrock включен в eu-north-1
- [ ] Доступ к моделям Claude запрошен и одобрен
- [ ] OIDC Identity Provider создан
- [ ] IAM Role с правильной Trust Policy создана
- [ ] Минимальные необходимые права присвоены роли
- [ ] Role ARN добавлен в GitHub Secrets
- [ ] GitHub Workflow создан и настроен
- [ ] Тестовый issue создан и Claude ответил успешно
- [ ] CloudTrail логи проверены
- [ ] Cost monitoring настроен

**Поздравляем! Безопасная интеграция AWS Bedrock с OIDC настроена!** 🎉
