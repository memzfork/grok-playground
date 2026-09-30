# Orbital Observatory / Gravity Slingshot

Контекст для Claude Code. Репозиторий стартует с **одного самодостаточного HTML-файла**.
Цель волны `feature/wave-1a-physics` — аккуратно вынести физику N-body, не ломая игру и обсерваторию.

## Что это

Один файл `index.html` (~1.1 MB):

- встроенный Three.js r128 (IIFE, `THREE` на `window`);
- постпроцессинг / bloom / линзирование;
- N-body (Velocity Verlet, опционально 1PN / Hamiltonian);
- научная «обсерватория» (пресеты, телеметрия, слоты, JSON import/export);
- игра «Гравитационная рогатка» (уровни, Mini-Bro, Yandex Games SDK-хуки).

Сборщика **нет**. Нет npm, webpack, vite, TypeScript. Проект открывается как статика.

Вспомогательных скриптов `p9.py` и отдельного каталога тестов **нет** — верификация встроена в HTML (`window.runVerificationTests`, `?autorun_tests`).

## Как запускать

Любой из вариантов, пути только относительные:

```bash
# из корня репозитория
python3 -m http.server 8080
# затем http://127.0.0.1:8080/index.html
```

Режимы через query string (относительный URL, без абсолютных путей):

| URL | Режим |
|---|---|
| `index.html` | игра, уровни Gravity Slingshot (`Game.boot()`) |
| `index.html?sandbox` | научная обсерватория, пресет Gargantua / interstellar |
| `index.html?autorun_tests` | прогон встроенных verification-тестов |
| `index.html?level=3` | старт конкретного уровня (1-based) |
| `index.html?adsmock` | заглушка рекламы даже вне localhost |

Открывать `index.html` с `file://` можно, но Web Audio / YaGames / localStorage могут быть ограничены. Предпочитать локальный HTTP.

## Карта монолита (ориентиры, не трогать вслепую)

Порядок в одном `<script>` после CSS и встроенного Three.js:

1. Ядро симуляции: `SIM`, `phys` (SoA: `pos/vel/acc/mass/id/...`), `bodies`, `MAX_BODIES`.
2. Интегратор: Velocity Verlet + `subSteps`, смягчение Пламмера (`softening`, `soft2`).
3. Коллизии: `collisionMode` (`merge` и др.), CCD (`ccdSphereTime`).
4. Релятивистика: `SIM.grEnabled`, `SIM.lightSpeed`, 1PN; флаг `grReady`.
5. Инварианты: энергия, момент, drift HUD; `computeSystemEnergy`, `computePotentialEnergy`.
6. Сцена / камера / GUI (`lil-gui`), пресеты `Presets` / `loadPreset`.
7. Обсерватория: `initObservatory`, `window.observatory`.
8. Аудио: `AudioEngine` (процедурный Web Audio).
9. Игра: `LEVELS`, `LEVEL_HINTS`, `GSave`, `YSDK`, `MiniBro`, `GH` (ghost Verlet), `Game`.
10. Boot: `DOMContentLoaded` → `initScene` → `initObservatory` → `Game.boot()` или `loadPreset('interstellar')` при `?sandbox`.

Публичные точки, которые должны остаться живыми после рефакторинга:

```js
window.observatory = {
  game: Game,
  loadPreset,
  step: stepPhysics,
  save: createStateSnapshot,
  restore: restoreStateSnapshot,
  tests: window.runVerificationTests,
  state: { count, time, preset, gr, paused, energy, renderer }
};
window.runVerificationTests
Game.afterStep()          // вызывается из stepPhysics
Game.solve() / Game.solveAll()
```

## Правила сборки — не ломать

1. **Канонический артефакт — `index.html` в корне.** Пока нет пайплайна сборки, страница должна открываться без шагов compile/bundle. Если начнёте сплитить JS — либо инлайнить обратно в `index.html`, либо добавить крошечный сборщик и явно описать команду в этом файле. Не оставляйте «полуразобранный» HTML с битыми `<script src>`.
2. **Только относительные пути.** Запрещены `file://`, абсолютные диски и ведущий `/` для ассетов репозитория. Допустимы:
   - `./index.html`, `./js/physics.js`, `./assets/...`;
   - внешние https-ссылки в справке (arxiv, threejs.org);
   - платформенный `/sdk.js` Яндекс Игр — это путь хоста площадки, не файл репо. Не заменять на локальный абсолютный путь.
3. **Не выкидывать встроенный Three.js**, пока не подключён тот же r128 с рабочего относительного `vendor/three.min.js` и страница не проверена в sandbox + game.
4. **Не менять численный контракт физики без тестов.** Ghost-симулятор (`GH` / `ghostRun`) обязан совпадать с боевым Verlet: те же `G`, `timeStep`, `subSteps`, softening, массы, CCD. Иначе сломаются прицел, подсказки и `LEVEL_HINTS`.
5. **Координаты игры:** уровень задан в 2D `(x, y)` экрана (y вверх). Мир Three.js: `X = x`, `Y = 0`, `Z = −y`. Не «выпрямить» оси без правки `Game.W`, `goalAt`, камеры и хинтов.
6. **Сиды и детерминизм.** Уровни стартуют через `resetRNG(7, 7)` и `resetBodyIdCounter()`. Не вводить `Math.random` в интегратор.
7. **Сохранения.** Ключи `orbital_slingshot_v1` и слоты обсерватории — не переименовывать без миграции.
8. **Язык UI** — ru/en через `L10N` / `setLang`. Комментарии в коде можно оставлять на русском, как в исходнике.
9. **Реклама / YSDK.** Полноэкранная реклама только между уровнями (`MONET.interstitialEvery`, `minIntervalMs`). Не вызывать ads из `stepPhysics`.
10. **Тесты обязательны после правок физики.** Открыть `index.html?autorun_tests` или вызвать `window.runVerificationTests()` в консоли. Если выносите тесты в отдельные файлы — запускать их той же командой, что описана ниже, и не удалять in-page runner, пока волна не закончена.

## Волна 1a — физика (ожидаемый скоуп)

Разрешено и желательно:

- вынести в отдельные модули **только** расчёт: ускорения, Verlet, 1PN, энергия/момент, коллизии/Roche, ghost-integrator;
- держать SoA `phys` и API `stepPhysics` / `computeAccelerations` стабильными;
- добавить узкие юнит-проверки на инварианты (энергия двух тел, figure-8 не разваливается на коротком отрезке, ghost ≡ live).

Не делать в этой ветке, если нет явного запроса:

- переписывать рендер, шейдеры, bloom, GUI;
- менять тексты уровней / баланс `LEVELS` / пересчитывать `LEVEL_HINTS` без нужды;
- подключать npm «для красоты»;
- переходить на другой интегратор (RK4, Barnes-Hut) без флага совместимости.

Если сплитите файлы, предлагаемая раскладка (все пути относительные от корня):

```
index.html                 # оболочка: CSS + boot + <script type="module" src="./js/main.js">
js/vendor/three.min.js     # только если вынесли Three, иначе оставить inline
js/physics/soa.js
js/physics/integrate.js
js/physics/gravity.js
js/physics/relativistic.js
js/physics/collisions.js
js/physics/invariants.js
js/physics/ghost.js
js/game/...                # не в скоупе 1a, пока не понадобится
CLAUDE.md                  # этот файл, обновлять после смены сборки
```

Пока файлов модуля нет — **не создавать пустые заготовки**, которые ломают загрузку. Сначала работающий split, потом удаление дублирующего куска из монолита.

## Инварианты, которые нельзя молча сломать

- `SIM.G`, `SIM.softening`, `SIM.timeStep`, `SIM.subSteps` для уровней: `G=1`, `softening=0.06`, `timeStep=0.008`, `subSteps=4`.
- Зонд: крошечная масса `1e-5`, не должен сдвигать звезду.
- После `startLevel` нужен `computeAccelerations()` + `resetBaseEnergy()` до первого кадра.
- `needsAccelerationRecalc` — не выкидывать.
- Предел Роша и merge-коллизии используются и игрой, и пресетами (`rocheLab`, `protocloud`).

## Проверка перед коммитом

```bash
python3 -m http.server 8080
# 1) http://127.0.0.1:8080/index.html           — меню уровней, первый полёт
# 2) http://127.0.0.1:8080/index.html?sandbox   — сцена + lil-gui справа
# 3) http://127.0.0.1:8080/index.html?autorun_tests
```

Минимум руками: запуск зонда на уровне 1, пауза/шаг в sandbox, отсутствие ошибок в консоли (`boot-error` скрыт).

## Соглашения для облачных сессий

- Коммитить в текущую ветку `feature/wave-1a-physics`, не в `main`.
- Не переписывать `HELLO.md` / `NOTEPAD.md` / смысл `README.md` без нужды.
- После смены структуры сразу править этот `CLAUDE.md` — следующая сессия читает только его.
- Не класть секреты, токены, `node_modules`, бинарные дампы слотов.
- Крупный монолит уже в git; не дублировать его копиями `index.copy.html`.
