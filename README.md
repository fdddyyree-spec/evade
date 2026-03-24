# 🎮 Evade Ultimate Script

Полнофункциональный скрипт для Roblox Evade с AFK Farm Mode и всеми функциями.

---

## 🚀 Быстрый старт

### Запуск скрипта

```lua
loadstring(game:HttpGet("ваш_url/evade_ultimate.lua"))()
```

Или скопируйте код из `evade_ultimate.lua` в ваш executor и нажмите Execute.

---

## 🤖 AFK Farm Mode (Главная фича!)

### Что делает автоматически:

✅ Воскрешает вас при смерти  
✅ Воскрешает других игроков  
✅ Собирает монеты  
✅ Убегает от ботов в безопасную зону  
✅ Лечит вас при низком HP  
✅ Защищает от ботов  

### Как использовать:

```lua
-- 1. Встаньте в безопасное место
-- 2. Установите безопасную зону
SetCurrentPositionAsSafeZone()

-- 3. Запустите AFK режим
StartAFKFarm()

-- 4. Отойдите от компьютера! ☕
```

### Остановить AFK режим:

```lua
StopAFKFarm()
```

---

## 📋 Все функции

### 🏃 Движение

```lua
EnableSpeed(25)          -- Включить скорость (16-150)
DisableSpeed()           -- Выключить скорость

EnableJump(60)           -- Включить прыжок (50-300)
DisableJump()            -- Выключить прыжок

Settings.Bhop = true     -- Автопрыжок
Settings.Noclip = true   -- Прохождение сквозь стены
```

### 👁️ Визуальные

```lua
EnableESP()                  -- Подсветка игроков
DisableESP()                 -- Выключить ESP

Settings.Fullbright = true   -- Полная яркость
Settings.NoFog = true        -- Убрать туман
```

### 🔄 Автоматизация

```lua
Settings.AutoSelfRevive = true      -- Автовоскрешение себя
Settings.AutoReviveOthers = true    -- Автовоскрешение других
Settings.AutoCollectCoins = true    -- Автосбор монет
```

### 🤖 Защита от ботов

```lua
EnableGhostMode()            -- Боты игнорируют
DisableGhostMode()           -- Выключить Ghost Mode

Settings.BotIgnore = true    -- Боты отталкиваются
Settings.NoBots = true       -- Удаление всех ботов
```

### 🎮 Дополнительные функции

```lua
TeleportToSafeZone()     -- Телепорт в безопасную зону
CollectAllCoins()        -- Собрать все монеты
ReviveAllPlayers()       -- Воскресить всех игроков
RemoveBots()             -- Удалить всех ботов
BreakDoors()             -- Сломать все двери
UseInteractables()       -- Использовать все объекты

Settings.PrankStick = true   -- Палка для сбивания (ЛКМ по игроку)
```

---

## ⚙️ Настройки

### Основные настройки

```lua
Settings.Speed = true
Settings.SpeedValue = 25        -- Скорость (16-150)
Settings.Jump = true
Settings.JumpValue = 60         -- Прыжок (50-300)
Settings.Bhop = true
Settings.ESP = true
Settings.Fullbright = true
Settings.NoFog = true
Settings.AutoSelfRevive = true
Settings.AutoReviveOthers = true
Settings.AutoCollectCoins = true
Settings.Noclip = true
Settings.BotIgnore = true
Settings.GhostMode = true
Settings.PrankStick = true
Settings.NoBots = true
```

### AFK настройки

```lua
AFKSettings.ReviveRadius = 100          -- Радиус поиска игроков
AFKSettings.CoinRadius = 150            -- Радиус сбора монет
AFKSettings.BotDangerDistance = 25      -- Убегать если бот ближе
AFKSettings.AutoHealThreshold = 50      -- Лечиться если HP ниже
AFKSettings.SafeZone = Vector3.new(0, 100, 0)  -- Безопасная зона
```

---

## 💡 Примеры использования

### Пример 1: Базовый AFK фарм

```lua
SetCurrentPositionAsSafeZone()
StartAFKFarm()
```

### Пример 2: Агрессивный фарм

```lua
AFKSettings.ReviveRadius = 200
AFKSettings.CoinRadius = 300
Settings.SpeedValue = 45

SetCurrentPositionAsSafeZone()
StartAFKFarm()
```

### Пример 3: Безопасный фарм

```lua
AFKSettings.BotDangerDistance = 50
AFKSettings.AutoHealThreshold = 80
Settings.SpeedValue = 25

SetCurrentPositionAsSafeZone()
StartAFKFarm()
```

### Пример 4: Ручное управление

```lua
EnableSpeed(30)
EnableJump(70)
EnableESP()
EnableGhostMode()
Settings.AutoSelfRevive = true
Settings.AutoCollectCoins = true
```

---

## 🎯 Рекомендации

### Выбор безопасной зоны

**Хорошие места:**
- 🏔️ Высоко над картой (Y = 100+)
- 🏠 Внутри закрытых помещений
- 🚪 За закрытыми дверями

**Плохие места:**
- ❌ На земле рядом с ботами
- ❌ В открытых пространствах

### Оптимальные настройки

```lua
-- Для максимальной безопасности
AFKSettings.BotDangerDistance = 40
AFKSettings.AutoHealThreshold = 70
Settings.SpeedValue = 25

-- Для максимального фарма
AFKSettings.ReviveRadius = 200
AFKSettings.CoinRadius = 300
Settings.SpeedValue = 40
```

---

## ⚠️ Важно

### Требования к Executor

- `fireproximityprompt` - для воскрешения
- `firetouchinterest` - для сбора монет

### Безопасность

1. Не оставляйте скрипт на долго (максимум 1-2 часа)
2. Используйте умеренные настройки
3. Проверяйте периодически

### Ограничения

- Некоторые сервера могут кикать за AFK
- Админы могут заметить необычное поведение
- После обновления игры скрипт может перестать работать

---

## 🐛 Решение проблем

### Скрипт не работает

1. Проверьте консоль (F9) на ошибки
2. Убедитесь что executor поддерживает нужные функции
3. Попробуйте перезапустить скрипт

### AFK режим не воскрешает

```lua
AFKSettings.Enabled = true
AFKSettings.ReviveRadius = 200
```

### Вас кикает с сервера

```lua
Settings.SpeedValue = 20
AFKSettings.ReviveRadius = 80
AFKSettings.CoinRadius = 100
```

---

## 📞 Поддержка

Если возникли проблемы:
1. Проверьте консоль (F9)
2. Убедитесь что безопасная зона установлена
3. Проверьте что AFKSettings.Enabled = true

---

## ⚖️ Дисклеймер

Этот скрипт создан в образовательных целях. Использование может нарушать правила Roblox и привести к бану. Автор не несет ответственности за последствия.

---

**Приятного фарма! 🎮**
