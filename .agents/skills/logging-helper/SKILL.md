---
name: logging-helper
description: "Стратегия логирования, форматы, уровни, отладка через логи, поиск edge cases и багов. Триггеры: добавь логи, логирование, trace, отслеживай баг, edge case, найди причину, почему упало, что тут произошло, логирование в продакшене."
---


# Logging Helper — логирование как инструмент отладки

## Контекст

Логи — первый инструмент отладки, не костыль. Логгируй везде: вход/выход функций, ключевые состояния, ошибки, тайминги, неочевидные ветки. Помогают находить баги и edge cases до того, как пользователь заметит.

## Стратегия

### Что логировать
- Входные параметры функций (валидация)
- Возвращаемые значения (особенно при неочевидных результатах)
- Исключения и стектрейсы
- Переходы между состояниями
- Edge cases (пустые массивы, null, boundary values)
- Тайминги критичных операций (DB queries, API calls, heavy computations)
- Retry-попытки и fallback-ветки

### Уровни логирования
| Уровень | Когда | Пример |
|---------|-------|--------|
| `error` | Критичные сбои, требующие вмешательства | DB connection lost, API timeout |
| `warn` | Подозрительное, но система работает | Deprecated API, cache miss > 50% |
| `info` | Ключевые события бизнес-логики | User logged in, order created |
| `debug` | Детальная трассировка для отладки | Function entry/exit, intermediate values |

### Формат
```
[TIMESTAMP] [LEVEL] [MODULE] message — context: {key: value}
```
- Машина-читаемо (парсится локи)
- Человек-читаемо (понятно без декодера)
- ISO 8601 для timestamp
- JSON для context — удобно для grep/jq

## Алгоритм отладки через логи

1. **Добавь логи** в подозрительные места
2. **Воспроизведи** проблему
3. **Проанализируй** вывод — найди аномалию
4. **Убери лишнее**, оставь ключевые точки контроля
5. Зафиксируй edge case в тесте

## Логирование в продакшене

Логи → Мониторинг → Алерты

- Не надейся на «проверю руками»
- Критичные error-логи → алерт (email, Slack, Telegram)
- Паттерны ошибок → дашборд
- Ротация логой — не забивай диск

## Триггеры

«добавь логи», «логирование», «trace», «отслеживай баг», «edge case», «найди причину», «почему упало», «что тут произошло», «логирование в продакшене»

## Примеры

✅ **Правильно:**
```typescript
async function processOrder(order: Order) {
  log.debug('[ORDER] processing start', { orderId: order.id, items: order.items.length });
  
  try {
    const result = await validateOrder(order);
    if (!result.valid) {
      log.warn('[ORDER] validation failed', { orderId: order.id, reasons: result.errors });
      return { status: 'rejected', errors: result.errors };
    }
    
    log.info('[ORDER] processed successfully', { orderId: order.id });
    return { status: 'ok' };
  } catch (err) {
    log.error('[ORDER] unexpected error', { orderId: order.id, error: err.message, stack: err.stack });
    throw err;
  }
}
```

❌ **Неправильно:**
```typescript
async function processOrder(order: Order) {
  // а что тут случилось? никто не знает
  const result = await validateOrder(order);
  return result; // вернул — и ладно
}
```

❌ **Секреты в логах (НИКОГДА):**
```typescript
log.info('auth', { token: user.token, password: user.password }); // СЕКРЕТЫ!
```

✅ **Маскирование:**
```typescript
log.info('auth attempt', { email: user.email, apiKey: mask(user.apiKey) });
// apiKey: 'sk-****abcd'
```

## Ссылки
- AGENTS.md правило #19
