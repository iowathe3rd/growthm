1. Файловая структура проекта (iOS / SwiftUI)

/MyGrowthMapApp/
  ├── MyGrowthMapAppApp.swift           // @main приложение
  ├── Resources/
  │     ├── Assets.xcassets             // цвета, изображения, SF Symbols
  │     ├── Fonts/                      // кастомные шрифты (если есть)
  │     └── Localization/               // локализация, если нужно
  ├── Models/
  │     ├── UserProfile.swift
  │     ├── Goal.swift
  │     ├── SkillTree.swift
  │     ├── Sprint.swift
  │     └── SprintTask.swift
  ├── Services/
  │     ├── SupabaseService.swift       // взаимодействие с Supabase
  │     ├── GrowthMapAPI.swift          // вызовы Edge Functions
  │     └── AnalyticsService.swift      // (опционально) логирование, треки
  ├── ViewModels/
  │     ├── OnboardingViewModel.swift
  │     ├── GoalsListViewModel.swift
  │     ├── GoalDetailViewModel.swift
  │     ├── SprintViewModel.swift
  │     └── GrowthReportViewModel.swift
  ├── Views/
  │     ├── OnboardingView.swift
  │     ├── GoalsListView.swift
  │     ├── GoalDetailView.swift
  │     ├── SkillTreeView.swift         // визуализация дерева
  │     ├── SprintTasksView.swift
  │     ├── GrowthReportView.swift
  │     └── Shared/
  │         ├── Components/             // кнопки, карточки, чекбоксы
  │         ├── Views/                  // общие представления
  │         └── Extensions.swift        // расширения для SwiftUI
  ├── Style/
  │     ├── Colors.swift                // палитра приложения
  │     ├── Typography.swift            // шрифты, размеры
  │     ├── LayoutConstants.swift       // отступы, размеры
  │     └── DesignSystem.swift          // общие компоненты UI (карточка, кнопка)
  ├── Utils/
  │     ├── DateExtensions.swift
  │     ├── JSONDecoding.swift
  │     └── Logger.swift
  └── Tests/
        ├── ServicesTests/
        ├── ViewModelsTests/
        └── ViewsTests/

Комментарии по структуре
	•	Models – простые struct модели, отражающие типы из бэкенда (Goal, SkillTree и др.).
	•	Services – слой взаимодействия с внешними системами (Supabase, API).
	•	ViewModels – слой логики UI (MVVM), получает данные через Services, держит @Published параметры.
	•	Views – непосредственно SwiftUI интерфейсы, минимальная логика (напрямую вью не выполняет бизнес-логику).
	•	Style – единое место, где хранится дизайн-система: цвета, типографика, размеры, компоненты.
	•	Utils – вспомогательные функции и расширения.
	•	Tests – тесты.
	•	Shared компоненты (кнопки, карточки) живут под Views/Shared/Components.

⸻

2. Правила кодирования и архитектуры (SwiftUI часть)
	•	Код на Swift 5 (или выше). Использовать strict type safety, избегать Any, force-unwrap (!) почти всегда избегать.
	•	Использовать MVVM:
	•	ViewModels имеют ObservableObject и @Published свойства.
	•	Views подписываются на ViewModel через @StateObject или @ObservedObject.
	•	ViewModels не имеют доступа к UI-фреймворкам (например, не вызывают .sheet напрямую) — только через @Published состояния.
	•	Services (в Services/) не содержат UI-логику, только сетевые/данные.
	•	Взаимодействие с Supabase: использовать офиц. SDK для Swift/SwiftUI, следовать принципам.
	•	Все данные асинхронны — использовать async/await. Обработка ошибок: через do { try await … } catch { … }.
	•	UI Views максимально “легкие”: не содержат бизнес-логику, всё что можно вынести — в ViewModel или Service.
	•	Использовать Dependency Injection там, где нужно (например, ViewModel принимает Service в конструкторе) для тестируемости.
	•	Все константы (цвета, размеры, шрифты) — из Style/LayoutConstants.swift и Typography.swift, не хардкодить в Views.
	•	Линтинг/форматирование: использовать SwiftLint + SwiftFormat, правила: no force unwrap, prefer guard over if let, avoid 잡ные конструкции.
	•	Accessibility: каждый интерактивный элемент должен иметь .accessibilityLabel(), .accessibilityHint(), поддерживать Dynamic Type.  ￼
	•	Версионирование UI-компонентов: если дизайн меняется, добавлять новую версию компонента, не ломая старые.

⸻

3. Дизайн-система и UI-принципы

Опора на Apple HIG
	•	Три ключевых принципа: Clarity, Deference, Depth.  ￼
	•	Использовать системные цвета (.primary, .secondary, .background) и только при необходимости расширять палитру с кастомными адаптированными цветами.  ￼
	•	Минимальный размер сенсорных элементов: 44pt × 44pt.  ￼
	•	Храни макеты в светлом и тёмном режимах, поддерживай адаптивность.
	•	Сделай UI-элементы “легкими”, с прозрачностью/эффектом glass (если ты хочешь Liquid Glass стиль) но не мешающими читаемости и навигации.

“Liquid Glass” визуальный стиль
	•	Стеклянные/полупрозрачные панели поверх размытого фона (например .background с блуром).
	•	Используй .ultraThinMaterial или .regularMaterial в SwiftUI (iOS 15+).
	•	Контейнеры карточек или модальные окна могут иметь фон .ultraThinMaterial, закруглённые углы (например 12-16pt), мягкую тень.
	•	Цвета акцентов – минимум, чтобы не перегружать: например акцентная зелень/синий/нео-циан.
	•	Типография: заголовки — Font.title, Font.headline; тело — Font.body. Предоставь чёткую иерархию.
	•	Анимации: плавные переходы, например .transition(.opacity.combined(with:.move(edge:.bottom))). Но не отвлекающие — фокус остаётся на контенте.

Компоненты дизайн-системы
	•	PrimaryButton, SecondaryButton — базовые стили кнопок.
	•	CardView — карточка контента с glass-эффектом.
	•	SkillNodeView — узел дерева навыков: круглый элемент с прогресс-кольцом, подписью, состоянием (locked/unlocked).
	•	Цветовая палитра (Colors.swift):

struct Colors {
  static let background = Color("Background")          // defined in Assets
  static let cardBackground = Color("CardBackground")
  static let accent = Color("AccentColor")
  static let textPrimary = Color.primary
  static let textSecondary = Color.secondary
}


	•	Типография (Typography.swift):

struct Typography {
  static let title = Font.title.bold()
  static let heading = Font.headline
  static let body = Font.body
  static let caption = Font.caption
}


	•	Отступы (LayoutConstants.swift):

struct LayoutConstants {
  static let small: CGFloat = 8
  static let medium: CGFloat = 16
  static let large: CGFloat = 24
  static let cornerRadius: CGFloat = 12
}



⸻

4. Навигация и пользовательский поток
	•	Использовать NavigationStack (iOS 16+) или NavigationView с NavigationLink.
	•	Главное меню — список целей (GoalsListView).
	•	При выборе — переход к GoalDetailView, где отображается карта навыков + текущий спринт.
	•	Детали задачи — SprintTasksView.
	•	Отчёт развития — модальный экран GrowthReportView (может быть .sheet).
	•	Онбординг — первый запуск, OnboardingView (если нет целей).
	•	Все навигационные элементы должны быть простыми, понятными и использовать нативные элементы (кнопки «Back», системная навигация).

⸻

5. Инструкции по установке и начальной настройке
	1.	Открыть Xcode, создать новое iOS приложение SwiftUI (+ Swift Package Manager если нужны зависимости).
	2.	Настроить Package.swift или через Xcode добавить:
	•	Supabase Swift SDK (например supabase/swift),
	•	(опционально) библиотека для Result/AsyncHandle,
	•	SwiftLint + SwiftFormat.
	3.	Создать .env-файл (или Configuration.xcconfig) с SUPABASE_URL, SUPABASE_ANON_KEY. Не помещать ключи в репозиторий.
	4.	В Info.plist, добавить Privacy - Microphone Usage Description если понадобится запись аудио (если планируется будущий функционал).
	5.	Подключить дизайн-систему: создать Colors.swift, Typography.swift, LayoutConstants.swift как выше.
	6.	Настроить SwiftLint / SwiftFormat: добавь .swiftlint.yml, .swiftformat. Например запрет force_unwrapping, требование unused_imports, правило на indentation_width: 2.
	7.	Создать базовые ViewModels и Services файлами: SupabaseService.swift, OnboardingViewModel.swift. Написать “заглушки” методов (например authenticateUser, fetchGoals).
	8.	Настроить навигацию: в MyGrowthMapAppApp.swift:

@main
struct MyGrowthMapAppApp: App {
  @StateObject private var onboardingVM = OnboardingViewModel()

  var body: some Scene {
    WindowGroup {
      if onboardingVM.needsOnboarding {
        OnboardingView(viewModel: onboardingVM)
      } else {
        GoalsListView()
      }
    }
  }
}


	9.	Провести базовый UI-тест: отображение списка целей (мока), навигация к деталям.
	10.	Сделать первый commit с “Initialize project” и документировать архитектуру в README.

⸻

6. Правила QA и проверка перед релизом
	•	Проверить UI на разных устройствах / ориентациях / светлый/тёмный режим.
	•	Проверить доступность: Dynamic Type на большом размере шрифта, VoiceOver метки, цветовые контрасты.
	•	Проверить навигацию: Back кнопка работает, модальные экраны закрываются.
	•	Проверить стек ошибок: если сервис возвращает ошибку, UI показывает Alert и предлагает повторить.
	•	Тесты: ViewModel тесты (например, моканный Service, проверка состояния UI), сервис тесты (моковые ответы от Supabase).
	•	Проверить сборку без ошибок/ворнингов, линтинг прошёл (swiftlint).
	•	Перед хакатоном настроить “демо режим”: возможно мок-данные, фокус на ключевых экранах.