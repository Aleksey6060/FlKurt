# План проекта: Магазин спорт инвентаря (Sport Gear)
> Цель: максимальный балл (30/30)

---

## Итоговые баллы по критериям

| Критерий | Баллов |
|---|---|
| Firebase Auth + сброс пароля через почту | 4 |
| Firebase Firestore | 3 |
| Тема реализована полностью | 5 |
| Уведомления | 4 |
| Clean Architecture | 4 |
| Анимации | 2 |
| Bloc/Cubit | 4 |
| Интерфейс | 4 |
| **Итого** | **30** |
| Штраф за вылеты | -6 (не допустить!) |

---

## Технологический стек

- **Flutter** (target: Android / iOS)
- **Firebase Auth** — регистрация, вход, сброс пароля, подтверждение email
- **Firebase Firestore** — каталог товаров, корзина, заказы, профиль
- **Firebase Cloud Messaging (FCM)** — push-уведомления
- **flutter_bloc** — управление состоянием везде
- **Clean Architecture** — разделение на data / domain / presentation
- **flutter_local_notifications** — локальные уведомления (дополнительно к FCM)
- **go_router** — навигация
- **cached_network_image** — кэш изображений
- **shimmer** — анимация загрузки (skeleton)

---

## Архитектура: Clean Architecture

```
lib/
├── core/
│   ├── constants/          # цвета, строки, размеры
│   ├── errors/             # Failure классы
│   ├── usecases/           # базовый UseCase
│   ├── utils/              # validators, formatters
│   └── widgets/            # общие виджеты (LoadingWidget, ErrorWidget)
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/   # firebase_auth_datasource.dart
│   │   │   ├── models/        # user_model.dart
│   │   │   └── repositories/  # auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/      # user.dart
│   │   │   ├── repositories/  # auth_repository.dart (абстракция)
│   │   │   └── usecases/      # login, register, logout, reset_password, verify_email
│   │   └── presentation/
│   │       ├── bloc/          # auth_bloc.dart / auth_state.dart / auth_event.dart
│   │       └── pages/         # login_page, register_page, forgot_password_page
│   │
│   ├── catalog/
│   │   ├── data/ ...
│   │   ├── domain/ ...
│   │   └── presentation/
│   │       ├── bloc/          # catalog_bloc, filter_cubit
│   │       └── pages/         # home_page, catalog_page, game_detail_page
│   │
│   ├── cart/
│   │   ├── data/ ...
│   │   ├── domain/ ...
│   │   └── presentation/
│   │       ├── bloc/          # cart_bloc
│   │       └── pages/         # cart_page, checkout_page
│   │
│   ├── profile/
│   │   ├── data/ ...
│   │   ├── domain/ ...
│   │   └── presentation/
│   │       ├── bloc/          # profile_cubit
│   │       └── pages/         # profile_page, orders_page
│   │
│   └── notifications/
│       ├── data/ ...
│       └── services/          # notification_service.dart
│
└── main.dart
```

---

## Экраны приложения

### 1. Splash Screen
- Логотип магазина с анимацией (fade-in + scale)
- Проверка состояния авторизации → редирект

### 2. Авторизация / Регистрация
- **Login Page**: email + пароль, кнопка "Войти", ссылка "Забыли пароль?", ссылка "Зарегистрироваться"
- **Register Page**: имя, email, пароль, подтверждение пароля — валидация всех полей
- **Forgot Password Page**: поле email → отправка письма Firebase → снэкбар "Письмо отправлено"
- **Email Verification Page**: экран с просьбой подтвердить email, кнопка "Отправить повторно", polling проверки

### 3. Home Page (главная)
- AppBar с поиском и иконкой корзины (бейдж с кол-вом)
- Баннер-карусель (рекомендуемые товары) с PageView + анимацией
- Горизонтальный список категорий (Кардио, Силовые, Йога, Бокс, и т.д.)
- Секция "Популярные товары" — GridView с карточками
- Секция "Новинки"
- Shimmer-загрузка пока данные грузятся

### 4. Каталог / Поиск
- Список/сетка товаров с фильтрацией (по категории, цене, рейтингу)
- Сортировка (по цене, рейтингу, новизне)
- Переключение между List и Grid view
- Пустое состояние с иллюстрацией

### 5. Страница товара (Product Detail)
- Hero-анимация из каталога
- Скриншоты (PageView с индикатором)
- Описание, категория, производитель, рейтинг
- Кнопки "В корзину" / "Уже в корзине"
- Кнопка "В избранное" (wishlist)

### 6. Корзина (Cart)
- Список добавленных товаров
- Изменение количества / удаление
- Итоговая сумма
- Кнопка "Оформить заказ" → диалог подтверждения → снэкбар успеха + уведомление

### 7. Профиль
- Аватар (initials), имя, email
- Верифицирован ли email (иконка)
- История заказов
- Кнопка "Выйти"
- Кнопка "Изменить пароль" (сброс через почту)

### 8. История заказов
- Список заказов с датой, суммой, составом
- Карточка каждого заказа

---

## Firebase Firestore: структура данных

```
products/
  {productId}/
    title: string
    description: string
    price: number
    genre: string
    rating: number
    imageUrl: string
    screenshots: string[]
    publisher: string
    releaseDate: timestamp
    isNew: bool
    isFeatured: bool

users/
  {userId}/
    name: string
    email: string
    createdAt: timestamp

    cart/
      {productId}/
        quantity: number
        addedAt: timestamp

    orders/
      {orderId}/
        products: [{productId, title, price}]
        total: number
        createdAt: timestamp
        status: string

    wishlist/
      {productId}/
        addedAt: timestamp
```

---

## Уведомления (4 балла)

1. **Firebase Cloud Messaging (FCM)** — push при новых акциях/новинках (background)
2. **flutter_local_notifications** — локальное уведомление после успешного заказа
3. Уведомление при добавлении в корзину (local, scheduled dismiss)
4. Инициализация в `notification_service.dart`, запрос разрешений при старте

---

## Анимации (2 балла)

| Место | Анимация |
|---|---|
| Splash | FadeTransition + ScaleTransition логотипа |
| Все страницы при загрузке | Shimmer (shimmer package) |
| Переход в Game Detail | Hero анимация обложки |
| Добавление в корзину | ScaleTransition иконки + SnackBar |
| Карусель баннеров | PageView с плавным скроллом |
| Появление карточек в списке | AnimatedList / staggered анимация |
| Bottom NavBar | AnimatedContainer для активного таба |

---

## Bloc/Cubit: список (4 балла)

| BLoC / Cubit | Назначение |
|---|---|
| `AuthBloc` | состояние авторизации, login, register, logout |
| `CatalogBloc` | загрузка игр, поиск |
| `FilterCubit` | фильтры и сортировка |
| `CartBloc` | корзина — добавить, удалить, изменить кол-во |
| `WishlistCubit` | избранное |
| `ProfileCubit` | данные профиля, история заказов |
| `NotificationCubit` | состояние уведомлений |

---

## Интерфейс (4 балла)

### Дизайн и стиль (1 балл)
- Тёмная тема (gaming-стиль): фон `#0D0D0D`, акцент `#6C63FF` (фиолетовый)
- Шрифт: Google Fonts — Rajdhani (заголовки) + Roboto (текст)
- Иконки: Material Icons + кастомные SVG
- Единый ThemeData в `core/constants/app_theme.dart`

### Навигация (1 балл)
- `BottomNavigationBar` с вкладками: Главная / Каталог / Корзина / Профиль
- `go_router` для вложенной навигации
- Кнопка Back на всех вложенных экранах
- Hero-переходы между экранами

### Формы ввода (1 балл)
- Валидация: email формат, пароль минимум 6 символов, совпадение паролей
- Подсветка ошибочных полей красным
- `TextFormField` с labelText и hintText
- Показ/скрытие пароля

### Отображение данных (1 балл)
- GridView + ListView для игр
- Фильтры и сортировка в каталоге
- SnackBar при добавлении в корзину / успешном заказе (исчезает через 3 сек)
- Toast при ошибках
- Skeleton loading (shimmer) во время загрузки

---

## Обработка ошибок (критично: -6 баллов за вылеты)

- `try/catch` везде где работа с Firebase
- `Either<Failure, T>` в domain layer (dartz package)
- Глобальный `FlutterError.onError` и `PlatformDispatcher.instance.onError` в `main.dart`
- Пустые состояния (empty state widgets) при отсутствии данных
- Offline-режим: показ сообщения об отсутствии сети
- Loading индикаторы чтобы нельзя было нажать кнопку дважды
- `BlocListener` для отображения ошибок из BLoC

---

## Зависимости (pubspec.yaml)

```yaml
dependencies:
  flutter_bloc: ^8.1.6
  firebase_core: ^3.x
  firebase_auth: ^5.x
  cloud_firestore: ^5.x
  firebase_messaging: ^15.x
  flutter_local_notifications: ^18.x
  go_router: ^14.x
  cached_network_image: ^3.x
  shimmer: ^3.x
  google_fonts: ^6.x
  dartz: ^0.10.1
  get_it: ^8.x          # DI / Service Locator
  equatable: ^2.x
  intl: ^0.19.x
```

---

## Порядок реализации

1. **Настройка проекта** — Firebase, pubspec.yaml, структура папок, DI (get_it)
2. **Core** — темы, константы, базовые классы, обработка ошибок
3. **Auth feature** — регистрация, вход, сброс пароля, подтверждение email
4. **Firestore** — заполнение базы тестовыми играми (скрипт/вручную)
5. **Catalog feature** — загрузка игр, каталог, фильтры, детальная страница
6. **Cart feature** — корзина, оформление заказа
7. **Profile feature** — профиль, история заказов, wishlist
8. **Notifications** — FCM + local notifications
9. **Анимации** — добавить shimmer, hero, splash анимацию
10. **Полировка UI** — тема, адаптивность, проверка на устройствах
11. **Тестирование** — проверить все edge cases, обработку ошибок

---

## Чеклист перед сдачей

- [ ] Регистрация работает
- [ ] Вход работает
- [ ] Сброс пароля через email работает
- [ ] Подтверждение email работает
- [ ] Данные берутся из Firestore
- [ ] Корзина и заказы сохраняются в Firestore
- [ ] Push уведомление приходит
- [ ] Локальное уведомление показывается после заказа
- [ ] Все состояния через Bloc/Cubit
- [ ] Shimmer на всех экранах загрузки
- [ ] Hero анимация работает
- [ ] Splash анимация работает
- [ ] Валидация форм работает
- [ ] Фильтрация и сортировка работает
- [ ] BottomNavigationBar на всех основных экранах
- [ ] Нет необработанных исключений
- [ ] Нет вылетов при пустых данных
- [ ] SnackBar при успешных действиях
- [ ] Обработка отсутствия сети
