extends RefCounted

# Review-only copy. Mission titles/objectives keep the existing seven-language APIs.
const TEXTS := {
"zh_CN": {
"title":"独立关卡审查", "badge":"F8 审查 / 暂停 · %s×", "new":"新开 / 重置本关", "continue":"继续本关存档", "play":"返回试玩", "save":"保存本关", "report":"导出审查报告", "quit":"退出",
"confirm":"这会覆盖本关的审查进度；正式存档不受影响。再次点击确认重置。", "yes":"确认重置", "cancel":"取消",
"intro":"这是隔离的游戏切片，不是正常战役通关记录。跳过的前置只用于进入本关；资源消耗、升级和胜负规则保持正式玩法。不会改写正式或开发者存档。",
"fixture":"出发家园基础配置：有机营养 220.000、矿物 24.000、DNA 0；一枚已展开普通主核；无预制菌丝、兵营或军队；研究和建设分支均为 0，只允许基础游猎孢子。主巢挑战使用固定低配家园，并保留所需主巢等级的正式被动加成，不代表后期玩家家园。失联网络另有任务预设遗迹、孤立菌丝与中继核心；实际关内初态实体数记录在报告中。",
"controls":"操作：左键核心建造；左键框选孢子，右键下令；滚轮缩放，WASD 移动镜头；J 查看目标 / 开始任务波次；Esc 游戏菜单；F8 返回本审查面板。加速只改变模拟速度，不免除成本。",
"paused":"当前暂停。选择新开，或读取本关的隔离存档。", "running":"当前试玩进度", "finished":"本次审查已结算", "error":"入口错误：必须提供有效的 --review-mission=<关卡 ID>。不会读取或写入任何正式存档。",
"saved":"已保存本关。", "save_failed":"保存或读取失败，原有可恢复存档保留。", "report_saved":"审查报告已写入：", "locked":"审查切片禁用开发者免成本模式。", "empty":"尚未开始本关。", "result":"结果", "unsettled":"未结算", "no_timing":"加速和脚本耗时不证明普通玩家通关时长。离线期间本切片不产生收益。",
"build":"构建", "scene":"场景 / 种子", "initial":"初始快照 SHA-256", "progress":"目标", "resources":"当前资源", "location":"隔离存档", "time":"模拟秒 / 活跃墙钟秒 / 用过的倍率", "tier":"主巢等级（前置跳过仅为审查）", "status_objectives_met":"目标已达成；可在 J 面板结算或继续检查。", "status_failure":"本局失败；可查看状态、导出报告或重开。", "status_victory":"胜利", "status_retreat":"撤退", "status_unsettled":"未结算"
},
"zh_TW": {
"title":"獨立關卡審查", "badge":"F8 審查 / 暫停 · %s×", "new":"新開 / 重置本關", "continue":"繼續本關存檔", "play":"返回試玩", "save":"儲存本關", "report":"匯出審查報告", "quit":"離開",
"confirm":"這會覆蓋本關審查進度；正式存檔不受影響。再次點擊確認重置。", "yes":"確認重置", "cancel":"取消",
"intro":"這是隔離的遊戲切片，不是正常戰役通關紀錄。跳過前置只用於進入本關；成本、升級和勝負規則保持正式玩法。不會改寫正式或開發者存檔。",
"fixture":"出發家園基礎配置：有機 220.000、礦物 24.000、DNA 0；一枚已展開普通主核；無預製菌絲、兵營或軍隊；研究和建設分支皆為 0，只有基礎遊獵孢子許可。主巢挑戰使用固定低配家園，保留所需主巢等級的正式被動加成，不代表後期玩家家園。失聯網路另有任務預設遺跡、孤立菌絲和中繼；實際初始實體數見報告。",
"controls":"左鍵核心建造；左鍵框選、右鍵下令；滾輪縮放、WASD 移鏡；J 目標 / 開波；Esc 遊戲選單；F8 審查面板。加速不免除成本。",
"paused":"目前暫停。選擇新開，或讀取本關隔離存檔。", "running":"目前試玩進度", "finished":"本次審查已結算", "error":"入口錯誤：需要有效的 --review-mission=<關卡 ID>。不會讀寫正式存檔。",
"saved":"已儲存本關。", "save_failed":"存讀檔失敗；可恢復存檔保留。", "report_saved":"報告已寫入：", "locked":"審查切片停用開發者免成本模式。", "empty":"尚未開始。", "result":"結果", "unsettled":"未結算", "no_timing":"加速與腳本耗時不代表玩家通關時間。離線不產生收益。",
"build":"構建", "scene":"場景 / 種子", "initial":"初始快照 SHA-256", "progress":"目標", "resources":"目前資源", "location":"隔離存檔", "time":"模擬秒 / 活躍實際秒 / 用過的倍率", "tier":"主巢等級（前置僅為審查跳過）", "status_objectives_met":"目標達成；可於 J 結算或繼續檢查。", "status_failure":"本局失敗；可匯出報告或重開。", "status_victory":"勝利", "status_retreat":"撤退", "status_unsettled":"未結算"
},
"en": {
"title":"Independent mission review", "badge":"F8 Review / pause · %s×", "new":"New / reset this slice", "continue":"Resume this slice", "play":"Return to play", "save":"Save this slice", "report":"Export review report", "quit":"Quit",
"confirm":"This replaces this slice's progress only. Campaign saves are untouched. Click again to confirm.", "yes":"Confirm reset", "cancel":"Cancel",
"intro":"An isolated playable slice, not proof of campaign completion. Prerequisites are bypassed only for access; ordinary costs, research and victory rules apply. Normal and developer saves are never edited.",
"fixture":"Departure-home baseline: 220.000 organic, 24.000 minerals, 0 DNA; one settled ordinary core; no prepared hyphae, barracks or army; zero research and nest branches, basic forager license only. Challenges use a fixed minimal home with the required nest tier's normal passive bonuses, not a representative late-game home. Lost Network additionally contains authored ruins, orphan hyphae and a relay; the report lists actual initial entity counts.",
"controls":"Left-click cores to build; drag-select units, right-click orders; wheel zoom, WASD camera; J objectives / start waves; Esc game menu; F8 this panel. Speed-up never waives costs.",
"paused":"Paused. Start a fresh slice or resume its separate save.", "running":"Current review run", "finished":"This review run is settled", "error":"Invalid entry: provide --review-mission=<valid mission ID>. No normal save will be read or written.",
"saved":"Slice saved.", "save_failed":"Save/load failed; recoverable saves were kept.", "report_saved":"Report written to:", "locked":"Cost-free developer mode is disabled in review slices.", "empty":"This slice has not started.", "result":"Outcome", "unsettled":"Unsettled", "no_timing":"Accelerated/scripted time does not certify player completion time. No offline gains are awarded.",
"build":"Build", "scene":"Scene / seed", "initial":"Initial snapshot SHA-256", "progress":"Objectives", "resources":"Current resources", "location":"Isolated save", "time":"Simulation seconds / active wall seconds / speeds used", "tier":"Nest tier (prerequisites bypassed for review only)", "status_objectives_met":"Objectives met; settle in J or keep inspecting.", "status_failure":"Run failed; inspect, export a report, or reset.", "status_victory":"Victory", "status_retreat":"Retreat", "status_unsettled":"Unsettled"
},
"ja": {
"title":"独立ミッション確認", "badge":"F8 確認 / 一時停止 · %s×", "new":"このミッションを新規開始", "continue":"専用セーブを再開", "play":"プレイに戻る", "save":"専用セーブ", "report":"確認レポート出力", "quit":"終了",
"confirm":"この確認用進行だけを上書きします。通常セーブは変更しません。再度押して確定。", "yes":"リセット確定", "cancel":"取消",
"intro":"通常キャンペーンのクリア記録ではなく、独立した確認用ミッションです。前提条件だけを省略し、費用・研究・勝敗条件は通常通りです。通常・開発者セーブには触れません。",
"fixture":"出発拠点の基本構成：有機 220.000、鉱物 24.000、DNA 0。展開済み通常コア1個。菌糸・兵舎・軍隊の事前配置なし。研究と巣分岐は0、基本採集胞子だけ解放。巣の挑戦は最低構成の固定拠点と必要な巣レベルの通常パッシブを使用し、後期拠点を代表しません。Lost Networkには任務用の遺跡・孤立菌糸・中継核もあります。実際の初期個体数はレポートに記録します。",
"controls":"左クリックで建設、ドラッグで選択、右クリックで命令。ホイールでズーム、WASDで移動。Jで目標・ウェーブ開始、Escメニュー、F8確認。加速しても費用は必要です。",
"paused":"一時停止中。新規開始または専用セーブ再開を選択。", "running":"現在の確認進行", "finished":"確認結果を確定済み", "error":"有効な --review-mission=<ID> が必要です。通常セーブは読み書きしません。",
"saved":"保存しました。", "save_failed":"保存・読込失敗。復旧可能なセーブは保持。", "report_saved":"レポート保存先：", "locked":"確認中は開発者の費用免除を無効にします。", "empty":"未開始です。", "result":"結果", "unsettled":"未確定", "no_timing":"加速・スクリプト時間はプレイヤー所要時間の証明ではありません。オフライン収益なし。",
"build":"ビルド", "scene":"シーン / シード", "initial":"初期状態 SHA-256", "progress":"目標", "resources":"現在の資源", "location":"専用セーブ", "time":"シミュレーション秒 / 実操作秒 / 使用倍率", "tier":"巣レベル（確認用の前提省略）", "status_objectives_met":"目標達成。Jで結果確定、または確認を継続。", "status_failure":"失敗。確認・レポート出力・再開始が可能。", "status_victory":"勝利", "status_retreat":"撤退", "status_unsettled":"未確定"
},
"es": {
"title":"Revisión de misión independiente", "badge":"F8 Revisar / pausa · %s×", "new":"Nueva partida / reiniciar", "continue":"Continuar esta misión", "play":"Volver al juego", "save":"Guardar esta misión", "report":"Exportar informe", "quit":"Salir",
"confirm":"Solo reemplaza el progreso de esta prueba. Las partidas normales no cambian. Pulsa otra vez para confirmar.", "yes":"Confirmar reinicio", "cancel":"Cancelar",
"intro":"Prueba aislada, no prueba de haber completado la campaña. Solo se omiten requisitos de acceso; costes, investigación y victoria siguen las reglas normales. No modifica partidas normales ni de desarrollador.",
"fixture":"Base de partida: 220.000 orgánico, 24.000 minerales, 0 ADN; un núcleo normal desplegado; sin hifas, cuartel ni ejército preparados; investigaciones y ramas a 0, solo recolector básico. Los desafíos usan una base mínima fija y las bonificaciones normales del nivel de nido exigido; no representan una base avanzada. Lost Network también incluye ruinas, hifas aisladas y un núcleo de relevo propios de la misión; el informe recoge las entidades iniciales reales.",
"controls":"Clic izquierdo para construir; arrastrar para seleccionar; clic derecho para órdenes. Rueda: zoom; WASD: cámara; J: objetivos / oleadas; Esc: menú; F8: revisión. Acelerar no elimina costes.",
"paused":"En pausa. Inicia o continúa el guardado separado.", "running":"Prueba actual", "finished":"Prueba finalizada", "error":"Se requiere --review-mission=<ID válido>. No se leerá ni escribirá una partida normal.",
"saved":"Misión guardada.", "save_failed":"Error al guardar/cargar; se conservan los archivos recuperables.", "report_saved":"Informe escrito en:", "locked":"El modo sin costes está desactivado.", "empty":"Misión sin iniciar.", "result":"Resultado", "unsettled":"Sin finalizar", "no_timing":"El tiempo acelerado o automatizado no certifica la duración para jugadores. Sin ingresos sin conexión.",
"build":"Versión", "scene":"Escena / semilla", "initial":"SHA-256 inicial", "progress":"Objetivos", "resources":"Recursos actuales", "location":"Guardado aislado", "time":"Segundos simulados / reales activos / velocidades usadas", "tier":"Nivel del nido (acceso de prueba)", "status_objectives_met":"Objetivos cumplidos; finaliza en J o sigue revisando.", "status_failure":"Derrota; revisa, exporta o reinicia.", "status_victory":"Victoria", "status_retreat":"Retirada", "status_unsettled":"Sin finalizar"
},
"de": {
"title":"Einzelmission prüfen", "badge":"F8 Prüfung / Pause · %s×", "new":"Neu / Mission zurücksetzen", "continue":"Prüfstand fortsetzen", "play":"Zurück zum Spiel", "save":"Prüfstand speichern", "report":"Prüfbericht exportieren", "quit":"Beenden",
"confirm":"Nur dieser Prüfstand wird ersetzt. Normale Spielstände bleiben unverändert. Erneut zur Bestätigung klicken.", "yes":"Zurücksetzen bestätigen", "cancel":"Abbrechen",
"intro":"Isolierte Spielprobe, kein Nachweis eines Kampagnenabschlusses. Nur Zugangsvoraussetzungen werden übersprungen; Kosten, Forschung und Siegbedingungen bleiben normal. Normale und Entwickler-Spielstände bleiben unberührt.",
"fixture":"Ausgangsbasis: 220.000 organisch, 24.000 Mineralien, 0 DNA; ein entfalteter normaler Kern; keine vorbereiteten Hyphen, Kaserne oder Armee; Forschung und Nestzweige auf 0, nur einfacher Sammler. Nestprüfungen nutzen eine feste Minimalbasis mit normalen passiven Boni der erforderlichen Neststufe, keine repräsentative Spätspielbasis. Lost Network enthält zusätzlich vorgegebene Ruinen, verwaiste Hyphen und einen Relaiskern; der Bericht enthält die tatsächlichen anfänglichen Entitätszahlen.",
"controls":"Linksklick: bauen; Ziehen: Einheiten wählen; Rechtsklick: Befehl. Mausrad: Zoom; WASD: Kamera; J: Ziele / Wellenstart; Esc: Menü; F8: Prüfung. Beschleunigung erlässt keine Kosten.",
"paused":"Pausiert. Neu beginnen oder separaten Prüfstand laden.", "running":"Aktuelle Spielprobe", "finished":"Prüfung abgeschlossen", "error":"Gültiges --review-mission=<ID> erforderlich. Normale Spielstände werden nicht gelesen oder geschrieben.",
"saved":"Prüfstand gespeichert.", "save_failed":"Speichern/Laden fehlgeschlagen; wiederherstellbare Dateien bleiben erhalten.", "report_saved":"Bericht gespeichert unter:", "locked":"Kostenfreier Entwicklermodus ist gesperrt.", "empty":"Noch nicht gestartet.", "result":"Ergebnis", "unsettled":"Offen", "no_timing":"Beschleunigte oder skriptgesteuerte Zeit belegt keine Spielerdauer. Keine Offline-Erträge.",
"build":"Build", "scene":"Szene / Startwert", "initial":"Anfangszustand SHA-256", "progress":"Ziele", "resources":"Aktuelle Ressourcen", "location":"Isolierter Spielstand", "time":"Simulationssekunden / aktive reale Sekunden / Geschwindigkeiten", "tier":"Neststufe (Prüfzugang)", "status_objectives_met":"Ziele erfüllt; mit J abschließen oder weiter prüfen.", "status_failure":"Niederlage; prüfen, Bericht exportieren oder neu starten.", "status_victory":"Sieg", "status_retreat":"Rückzug", "status_unsettled":"Offen"
},
"ru": {
"title":"Проверка отдельной миссии", "badge":"F8 Проверка / пауза · %s×", "new":"Начать / сбросить миссию", "continue":"Продолжить эту миссию", "play":"Вернуться в игру", "save":"Сохранить миссию", "report":"Экспорт отчёта", "quit":"Выход",
"confirm":"Будет заменён только прогресс этой проверки. Обычные сохранения не изменятся. Нажмите ещё раз для подтверждения.", "yes":"Подтвердить сброс", "cancel":"Отмена",
"intro":"Изолированная игровая проверка, не подтверждение прохождения кампании. Пропущены лишь условия доступа; затраты, исследования и победа работают обычно. Обычные сохранения и режим разработчика не изменяются.",
"fixture":"Исходная база: органика 220.000, минералы 24.000, ДНК 0; одно развёрнутое обычное ядро; без готовых гиф, казармы или армии; исследования и ветви гнезда — 0, открыт лишь базовый собиратель. Испытания используют фиксированную минимальную базу с обычными бонусами нужного уровня гнезда, не типичную позднюю базу. Lost Network также содержит руины, осиротевшие гифы и ретранслятор задания; фактическое число объектов в начале указано в отчёте.",
"controls":"ЛКМ: строительство; рамка: выбор; ПКМ: приказ. Колесо: масштаб; WASD: камера; J: цели / начало волн; Esc: меню; F8: проверка. Ускорение не отменяет затраты.",
"paused":"Пауза. Начните заново или загрузите отдельное сохранение.", "running":"Текущая проверка", "finished":"Проверка завершена", "error":"Нужен верный --review-mission=<ID>. Обычные сохранения не будут прочитаны или изменены.",
"saved":"Миссия сохранена.", "save_failed":"Ошибка сохранения/загрузки; восстанавливаемые файлы сохранены.", "report_saved":"Отчёт записан:", "locked":"Бесплатный режим разработчика отключён.", "empty":"Миссия ещё не начата.", "result":"Результат", "unsettled":"Не завершено", "no_timing":"Ускоренное и скриптовое время не доказывает длительность прохождения игроком. Офлайн-доход отключён.",
"build":"Сборка", "scene":"Сцена / зерно", "initial":"SHA-256 начального состояния", "progress":"Цели", "resources":"Текущие ресурсы", "location":"Отдельное сохранение", "time":"Секунды симуляции / активного времени / скорости", "tier":"Уровень гнезда (доступ для проверки)", "status_objectives_met":"Цели выполнены; завершите через J или продолжайте проверку.", "status_failure":"Поражение; проверьте, экспортируйте отчёт или начните заново.", "status_victory":"Победа", "status_retreat":"Отступление", "status_unsettled":"Не завершено"
}
}

static func text(locale: String, key: String) -> String:
	var chosen: Dictionary = TEXTS.get(locale, TEXTS["en"])
	return String(chosen.get(key, TEXTS["en"].get(key, key)))
