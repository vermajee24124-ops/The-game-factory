# Turbo Rush Specification Traceability

PRD -> GameConfig.gd, DifficultyService.gd, LevelGenerator.gd, RewardService.gd, progression services
TRD -> project.godot, autoload services, main.gd, smoke tests
App Flow -> main.gd screen navigation and race states
UI/UX Brief -> main.gd design tokens, landscape layout and touch controls
Backend/Local Save Schema -> SaveSystem.gd, EconomyService.gd, ProgressionService.gd, AdsManager.gd, IAPManager.gd
Implementation Plan -> service order, procedural generation, race loop and 10,000-level smoke tests

Release must separately verify native ads, native billing, receipt validation, consent, licenses, permissions, privacy/data behavior, performance and store compliance.
