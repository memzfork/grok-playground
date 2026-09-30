# Orbital Observatory / Gravity Slingshot

Контекст для Claude Code. Цель волны `feature/wave-1a-physics` — аккуратно вынести физику N-body, не ломая игру и обсерваторию.

## Первый шаг сессии

Если корневой `index.html` меньше ~50 КБ и в нём нет `function stepPhysics` / `const Game` — это **загрузчик**, не игра.

1. Положи в корень монолит (~1.12 MB, title `Orbital Observatory — N-Body & Relativity`).
2. Путь только относительный: `./index.html`.
3. Закоммить в эту же ветку. Не рефакторить физику, пока монолит не в git.
4. `p9.py` и отдельного каталога тестов в поставке **нет**.
5. Если появился каталог `parts/index.part*`, собери относительно: `./assemble.sh`.

## Что это

Один файл `index.html` (~1.1 MB):

- встроенный Three.js r128 (IIFE, `THREE` на `window`);
- постпроцессинг / bloom / линзирование;
- N-body (Velocity Verlet, опционально 1PN / Hamiltonian);
- научная «обсерватория» (пресеты, телеметрия, слоты, JSON import/export);
- игра «Гравитационная рогатка» (уровни, Mini-Bro, Yandex Games SDK-хуки).

Сборщика **нет**. Нет npm, webpack, vite, TypeScript. Проект открывается как статика.

Верификация встроена в HTML (`window.runVerificationTests`, `?autorun_tests`).

## Как запускать

Пути только относительные:

```bash
python3 -m http.server 8080
# http://127.0.0.1:8080/index.html
```

| URL | Режим |
|---|---|
| `index.html` | игра Gravity Slingshot (`Game.boot()`) |
| `index.html?sandbox` | обсерватория, пресет interstellar |
| `index.html?autorun_tests` | встроенные verification-тесты |
| `index.html?level=3` | уровень (1-based) |
| `index.html?adsmock` | заглушка рекламы |

`file://` допустим, но Web Audio / YaGames / localStorage могут отказать. Предпочитать HTTP.

## Карта монолита

Один `<script>` после CSS и встроенного Three.js:

1. `SIM`, `phys` (SoA), `bodies`, `MAX_BODIES`
2. Velocity Verlet + `subSteps`, смягчение Пламмера
3. Коллизии / CCD (`ccdSphereTime`)
4. 1PN: `SIM.grEnabled`, `SIM.lightSpeed`
5. Инварианты: `computeSystemEnergy`, `computePotentialEnergy`
6. Сцена, камера, lil-gui, `Presets` / `loadPreset`
7. `initObservatory`, `window.observatory`
8. `AudioEngine`
9. `LEVELS`, `LEVEL_HINTS`, `GSave`, `YSDK`, `MiniBro`, `GH`, `Game`
10. Boot: `DOMContentLoaded` → `initScene` → `initObservatory` → `Game.boot()` или `loadPreset('interstellar')` при `?sandbox`

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
Game.afterStep()          // из stepPhysics
Game.solve() / Game.solveAll()
```

## Правила сборки

1. **Канон — `./index.html`.** Без compile/bundle, пока не описана другая команда здесь.
2. **Только относительные пути** для ассетов репо: `./js/...`, `./vendor/...`. Нельзя `file://`, диски, ведущий `/` внутри репо. Исключение: платформенный `/sdk.js` Яндекс Игр (хост площадки, не файл репо).
3. **Не выкидывать встроенный Three.js r128**, пока нет рабочего `./vendor/three.min.js` и проверки sandbox + game.
4. Ghost (`GH` / `ghostRun`) ≡ боевой Verlet (те же `G`, `timeStep`, `subSteps`, softening, CCD).
5. Игра: уровень `(x, y)` y вверх; мир `X=x`, `Y=0`, `Z=-y`.
6. `resetRNG(7, 7)` на старте уровня. Не сеять интегратор `Math.random`.
7. Ключ сохранения `orbital_slingshot_v1` не переименовывать без миграции.
8. Реклама только между уровнями, не из `stepPhysics`.
9. После правок физики: `index.html?autorun_tests`.

## Волна 1a

Можно: вынести расчёт (ускорения, Verlet, 1PN, энергия, коллизии/Roche, ghost), сохранить API `stepPhysics` / `computeAccelerations`.

Нельзя без запроса: рендер/шейдеры/GUI, баланс `LEVELS`, npm «для красоты», смена интегратора.

Сплит — только относительные пути от корня:

```
./index.html
./js/physics/soa.js
./js/physics/integrate.js
./js/physics/gravity.js
./js/physics/relativistic.js
./js/physics/collisions.js
./js/physics/invariants.js
./js/physics/ghost.js
./CLAUDE.md
```

Пустые заготовки, которые ломают загрузку, не создавать.

## Инварианты уровней

`G=1`, `softening=0.06`, `timeStep=0.008`, `subSteps=4`. Зонд `mass=1e-5`. После `startLevel`: `computeAccelerations()` + `resetBaseEnergy()`.

## Проверка

```bash
python3 -m http.server 8080
```

Меню уровня 1, sandbox, `?autorun_tests`, нет `#boot-error`.

## Сессии

Коммиты только в `feature/wave-1a-physics`. После смены структуры обновлять этот файл. Не трогать `HELLO.md` / `NOTEPAD.md` без нужды.
