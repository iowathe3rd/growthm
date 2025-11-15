# CODE INSTRUCTION

1. Общие требования
	•	Код писать на TypeScript (и только TypeScript в Edge Functions и совместимых частях).
	•	Типизация должна быть строгой: избегать any. Использовать интерфейсы/типы, желательно в отдельных файлах.
	•	Соблюдать модульность: логика должна быть разбита на небольшие модули, каждый модуль отвечает за свою зону ответственности.
	•	Соблюдать чистую архитектуру: слой сервисов, слой данных, слой бизнес-логики отделены.
	•	Все секреты, ключи, URL-адреса находятся в переменных окружения, не захардкожены в коде.
	•	Обязательно использовать RLS (Row Level Security) в базе данных и NEVER использовать service_role ключ на фронтенде.  ￼
	•	Logs и обработка ошибок должны быть однородными по всему проекту: ошибка — выбра­сывается/логируется, возвращается корректный HTTP статус.
	•	Комментарии и документация: функции, классы и интерфейсы должны иметь комментарии (/** … */) с описанием назначения.

⸻

2. Архитектура проекта (Backend-(Supabase) часть)

Папки и структура

supabase/                         // корень проекта Supabase
  functions/                     // Edge Functions
    _shared/                     // общие модули
      supabaseAdmin.ts
      supabaseClient.ts
      types.ts                   // общие типы интерфейсов
      llmClient.ts               // обёртка вызова LLM
      errorHandler.ts            // обработки ошибок
    create-growth-map/           // функция создания карты
      index.ts
    regenerate-sprint/           // функция адаптации спринта
      index.ts
    growth-report/               // функция отчёта
      index.ts
  migrations/                    // SQL-скрипты миграций
  config.toml                    // конфигурация функций

Модули
	•	_shared/supabaseAdmin.ts — клиент Supabase с SERVICE_ROLE ключом, только для серверной логики.
	•	_shared/supabaseClient.ts — клиент Supabase с ANON/авторизированным ключом (если нужно).
	•	_shared/types.ts — все интерфейсы: Goal, SkillTree, Sprint, SprintTask, UserProfile, и др.
	•	_shared/llmClient.ts — обёртка для вызова LLM (например OpenAI), с типами входа/выхода.
	•	_shared/errorHandler.ts — функции-утилиты форматирования ошибок, возвращение Response с корректным JSON: { error: string }.

Edge Function — шаблон

import { serve } from "https://deno.land/std/http/server.ts";
import { supabaseAdmin } from "../_shared/supabaseAdmin.ts";
import type { YourInputType, YourOutputType } from "../_shared/types.ts";

serve(async (req) => {
  try {
    const body: YourInputType = await req.json();
    // авторизация: проверить JWT из заголовка
    // бизнес-логика…
    const result: YourOutputType = await someService(body);
    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { "Content-Type": "application/json" }
    });
  } catch (err) {
    return errorHandler(err);
  }
});

	•	Не использовать // @ts-ignore, не подавлять ошибки типизации.
	•	Использовать await/async корректно.
	•	Каждая функция должна быть единичным HTTP endpoint. Имя функции — с дефисом (create-growth-map), как рекомендует Supabase.  ￼
	•	Проверка авторизации (JWT) перед бизнес-логикой.

⸻

3. База данных (Supabase/Postgres) и типы

Типы в TypeScript (_shared/types.ts)

export interface UserProfile {
  id: string;
  name: string;
  created_at: string; // ISO timestamp
}

export interface Goal {
  id: string;
  user_id: string;
  title: string;
  description: string;
  horizon_months: number;
  daily_minutes: number;
  created_at: string;
}

export interface SkillTree {
  id: string;
  goal_id: string;
  tree_json: SkillNode[];
  created_at: string;
}

export type SkillNode = {
  id: string;
  label: string;
  children?: SkillNode[];
};

export interface Sprint {
  id: string;
  goal_id: string;
  sprint_number: number;
  from_date: string;
  to_date: string;
  summary?: string;
  created_at: string;
}

export interface SprintTask {
  id: string;
  sprint_id: string;
  skill_node_id: string;
  title: string;
  description: string;
  difficulty: "low" | "medium" | "high";
  status: "pending" | "done" | "skipped";
  created_at: string;
}

export interface ProgressLog {
  id: string;
  user_id: string;
  goal_id: string;
  sprint_id?: string;
  payload: Record<string, unknown>;
  created_at: string;
}

	•	Все поля обязательны, кроме где явно ?.
	•	Использовать enum или union типы для строгих значений (difficulty, status).
	•	Не использовать any.

База данных
	•	Использовать UUID-поля как id, user_id и др.
	•	Включать created_at timestamptz default now() во всех таблицах.
	•	Настроить RLS-политику на каждой таблице: пользователи могут читать/изменять только свои строки.  ￼
	•	Использовать индексы на частые ключи (user_id, goal_id).

⸻

4. Лучшие практики кода + правила “чистоты”

Правила
	•	Именование: использовать camelCase для переменных/функций, PascalCase для типов/интерфейсов. Имя функции должно отражать действие: createGrowthMap, regenerateSprint.
	•	Одно действие — одна функция: функция не должна делать “10 разных вещей”. Если логика растёт — разделить на сервисы/утилиты.  ￼
	•	Чёткие границы слоёв:
	•	Сервисный слой: бизнес-логика (вызов LLM, вычисления).
	•	Дата-слой: запросы к Supabase/Postgres.
	•	API слой (Edge Function): HTTP-контроллер, валидация входа, вызов сервисов, возвращение ответа.
	•	Типы ввода/вывода: вся функция должна принимать строго типизированный интерфейс, возвращать строго типизированный интерфейс.
	•	Валидация входа: использовать библиотеку вроде Zod или ручную проверку, чтобы не полагаться на “текст → JSON → вставка”.
	•	Обработка ошибок: не оставлять необработанные ошибки. Использовать try/catch, логировать, возвращать понятный формат ошибок. Например:

return new Response(JSON.stringify({ error: "Invalid input" }), { status: 400 });


	•	Не блокировать фронтенд ключами: никогда не передавать SERVICE_ROLE_KEY в клиент.  ￼
	•	Миграции: использовать Supabase CLI или другой инструмент, фиксировать изменения схемы.
	•	Документация/комментарии: модули, функции и публичные методы должны иметь комментарии, обозначающие назначение.
	•	Линтинг и форматирование: использовать ESLint + Prettier, настроить правила: no-any, strict-null-checks, consistent-return.
	•	Unit тесты: по возможности покрывать ключевые функции (например сервисы генерации спринта) небольшими тестами.

Практики работы с Supabase
	•	Всегда использовать await supabase.from(...).select().eq(...).single() или .insert().returning() с контролем ошибок.
	•	Не делать insert/update в фронтенде без проверки RLS или business-логики — операции с данными через Edge Functions.
	•	Использовать supabase.functions.invoke() для вызова Edge Functions с контролем ошибок.
	•	Для сложных трансформаций/валидаций данных — использовать либо Database Function (SQL) либо Edge Function, не “тянуть” всё в фронтенд.  ￼
	•	Логика, близкая к данным (например, подсчёт процентов выполнения задач), должна быть ближе к базе или в функции сервиса, а не дублироваться на фронтенде.
	•	Хранить секреты, ключи, URL в .env / настройках проекта (не в коде).

⸻

5. Установка и конфигурация (Backend)
	1.	Установить Supabase CLI:

npm install -g supabase


	2.	Инициализировать проект:

supabase init


	3.	Настроить файлы:
	•	supabase/config.toml — указать functions папку, verify_jwt = true и др.  ￼
	4.	Создать нужные таблицы и миграции (migrations/xxxx_create_tables.sql).
	5.	Установить TypeScript и Deno зависимости в функции:

npm init -y
npm install @supabase/supabase-js
npm install --save-dev typescript


	6.	Создать функции через CLI:

supabase functions new create-growth-map
supabase functions new regenerate-sprint
supabase functions new growth-report


	7.	Локальный запуск:

supabase start
supabase functions serve --no-verify-jwt   # для разработки


	8.	Деплой функций в прод:

supabase functions deploy


	9.	Настроить переменные окружения: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, OPENAI_API_KEY, и др.
	10.	Настроить linting:

npm install --save-dev eslint prettier @typescript-eslint/parser

и конфиг .eslintrc.js с правилами no-any, strict: true, @typescript-eslint/no-explicit-any, и т.д.

⸻

6. Правила кодинга и проверка качества
	•	Каждый pull-request (или коммит) должен содержать: описание задачи, изменения, тесты (если есть).
	•	Код review: проверить, что нет any, что функции не выполняют “много работы” (Single Responsibility), что типы описаны.
	•	CI: настроить pipeline, который запускает npm run lint, npm run typecheck, npm run test.
	•	Наименование файлов: функции — kebab-case, модули вспомогательные — camelCase.ts.
	•	Комментарии: публичные методы / API handlers — обязательны.
	•	Логи: в Edge Functions — минимальные, не выводить секреты или чувствительные данные.
	•	Производительность: избегать тяжёлых зависимостей в Edge Functions (по рекомендации Supabase).  ￼
	•	Обработка ошибок: не подавлять, не логировать неконтролируемый stack на клиент. Сервер должен корректно возвращать статус 500 и сообщение “Internal Server Error”.

⸻

7. Контроль качества и мониторинг
	•	Включить логирование и мониторинг функций через Supabase Dashboard.  ￼
	•	Использовать метрики: количество вызовов, ошибки, latency.
	•	Обновление зависимостей: регулярно проверять версии @supabase/supabase-js, Deno, TypeScript.
	•	Установка правил безопасности: проверка RLS, проверка, что никакой “unrestricted” доступ не открыт.
	•	База данных: периодический аудит схемы, индексов, проверка, что нет “чёрных дыр” доступа.