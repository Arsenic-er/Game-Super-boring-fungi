extends RefCounted


const LOCALES: Array[String] = ["zh_CN", "zh_TW", "en", "ja", "es", "de", "ru"]
const DIRECTIVE_IDS: Array[String] = ["defense", "harvest", "purge"]
const UNIT_IDS: Array[String] = ["forager", "carrier", "chelator", "scout", "lytic", "suppressor", "disperser", "piercer", "coil", "antifungal"]

# Array-backed tables keep this focused catalog compact while retaining an
# identical, testable key set for every locale.
const KEYS: Array[String] = [
	"common_enabled", "common_disabled", "common_on_short", "common_off_short",
	"unit_forager_short", "unit_carrier_short", "unit_chelator_short", "unit_scout_short", "unit_lytic_short",
	"unit_suppressor_short", "unit_disperser_short", "unit_piercer_short", "unit_coil_short", "unit_antifungal_short",
	"directive_defense", "directive_harvest", "directive_purge",
	"directive_defense_short", "directive_harvest_short", "directive_purge_short", "directive_clear_short",
	"stat_auto_replenish_fmt", "stat_auto_replenish_paused_diet_fmt", "button_auto_replenish_fmt", "button_auto_target_fmt",
	"button_rally_set", "button_rally_clear", "stat_directive_unset", "stat_directive_active_fmt", "stat_directive_paused",
	"toast_rally_set", "toast_rally_cleared", "toast_rally_prompt", "toast_rally_cancelled",
	"toast_auto_replenish_fmt", "toast_auto_target_fmt", "toast_directive_cleared_fmt", "toast_directive_unsupported_fmt",
	"toast_directive_prompt_fmt", "toast_directive_invalid", "toast_directive_saved_fmt", "toast_zone_setup_cancelled_fmt",
	"hover_suppressor_ready_fmt", "hover_suppressor_deploying_fmt", "hover_suppressor_deployed_fmt",
	"hover_disperser_range_fmt", "hover_disperser_damage_fmt",
	"hover_antifungal_ready_fmt", "hover_antifungal_deploying_fmt", "hover_antifungal_deployed_fmt"
]

const VALUES := {
	"zh_CN": [
		"开启", "关闭", "开", "关", "游", "载", "矿", "侦", "裂", "抑", "散", "穿", "缠", "封",
		"防区", "采区", "猎区", "防区", "采区", "猎区", "清任务",
		"自动补员：%s · %s %d / %d", "自动补员暂停：%s 食性失效", "补员：%s", "目标 %d", "设置集结", "清除集结",
		"持续任务：未设置", "持续任务：%s · %s · 编制 %d · 补员接班", "持续任务暂停：兵种、食性或区域失效",
		"集结点已设置；新单位会先前往该位置", "集结点已清除", "左键点击地图设置集结点；右键或 Esc 取消", "已取消设置集结点",
		"自动补员：%s", "自动补员目标：%d", "兵营持续任务已清除；%d 个现役单位解除编制", "%s 当前不能执行%s持续任务",
		"为%s按住右键拖出正方形%s；Esc 取消", "持续任务不兼容，或区域超出菌落行动范围", "兵营持续%s已保存：现役 %d，新补员将自动接班", "已取消设置%s",
		"右键定位并展开 · 半径 %.0f μm · 细菌代谢 %.0f%%", "展开 %.1f / %.1f 秒 · 半径 %.0f μm", "抑菌半径 %.0f μm · 吸收与分裂速度 %.0f%%",
		"射程 %.0f μm · 裂解半径 %.0f μm · 下次释放 %.1f 秒", "单次伤害 %.3f × 食性效率 · 上次命中 %d",
		"右键定位并展开 · 半径 %.0f μm · 敌菌吸收与扩张 %.0f%%", "展开 %.1f / %.1f 秒 · 半径 %.0f μm", "封锁半径 %.0f μm · 断联菌丝衰败速度 %.0f%%"
	],
	"zh_TW": [
		"開啟", "關閉", "開", "關", "獵", "載", "礦", "偵", "裂", "抑", "散", "穿", "纏", "封",
		"防區", "採區", "獵區", "防區", "採區", "獵區", "清任務",
		"自動補員：%s · %s %d / %d", "自動補員暫停：%s 食性失效", "補員：%s", "目標 %d", "設定集結", "清除集結",
		"持續任務：未設定", "持續任務：%s · %s · 編制 %d · 補員接班", "持續任務暫停：兵種、食性或區域失效",
		"集結點已設定；新單位會先前往該位置", "集結點已清除", "左鍵點擊地圖設定集結點；右鍵或 Esc 取消", "已取消設定集結點",
		"自動補員：%s", "自動補員目標：%d", "兵營持續任務已清除；%d 個現役單位解除編制", "%s 目前不能執行%s持續任務",
		"為%s按住右鍵拖出正方形%s；Esc 取消", "持續任務不相容，或區域超出菌落行動範圍", "兵營持續%s已儲存：現役 %d，新補員將自動接班", "已取消設定%s",
		"右鍵定位並展開 · 半徑 %.0f μm · 細菌代謝 %.0f%%", "展開 %.1f / %.1f 秒 · 半徑 %.0f μm", "抑菌半徑 %.0f μm · 吸收與分裂速度 %.0f%%",
		"射程 %.0f μm · 裂解半徑 %.0f μm · 下次釋放 %.1f 秒", "單次傷害 %.3f × 食性效率 · 上次命中 %d",
		"右鍵定位並展開 · 半徑 %.0f μm · 敵菌吸收與擴張 %.0f%%", "展開 %.1f / %.1f 秒 · 半徑 %.0f μm", "封鎖半徑 %.0f μm · 斷聯菌絲衰敗速度 %.0f%%"
	],
	"en": [
		"Enabled", "Disabled", "On", "Off", "F", "C", "M", "S", "L", "U", "D", "P", "H", "AF",
		"defense zone", "harvest zone", "purge zone", "Guard", "Gather", "Purge", "Clear",
		"Auto replenish: %s · %s %d / %d", "Auto paused: %s diet inactive", "Auto: %s", "Target %d", "Set rally", "Clear rally",
		"Directive: not set", "Directive: %s · %s · %d active · auto handoff", "Directive paused: unit, diet, or zone invalid",
		"Rally point set; new units will go there first", "Rally point cleared", "Left-click the map to set a rally point; right-click or Esc to cancel", "Rally point setup cancelled",
		"Auto replenish: %s", "Auto replenish target: %d", "Barracks directive cleared; %d active units released", "%s cannot run a persistent %s",
		"For %s, hold right-click and drag a square %s; Esc cancels", "Directive incompatible or zone outside colony operating range", "Persistent %s saved: %d active; replacements take over automatically", "%s setup cancelled",
		"Right-click to deploy · radius %.0f μm · bacterial metabolism %.0f%%", "Deploying %.1f / %.1f s · radius %.0f μm", "Suppression radius %.0f μm · absorption and division %.0f%% speed",
		"Range %.0f μm · lysis radius %.0f μm · next burst %.1f s", "Damage %.3f × diet efficiency · last hit %d",
		"Right-click to deploy · radius %.0f μm · rival absorption and growth %.0f%%", "Deploying %.1f / %.1f s · radius %.0f μm", "Lockdown radius %.0f μm · severed-hypha decay %.0f%% speed"
	],
	"ja": [
		"有効", "無効", "入", "切", "採", "運", "鉱", "偵", "溶", "抑", "散", "穿", "狩", "封",
		"防衛区域", "採集区域", "掃討区域", "防衛", "採集", "掃討", "解除",
		"自動補充：%s · %s %d / %d", "自動補充停止：%s の食性が無効", "補充：%s", "目標 %d", "集結設定", "集結解除",
		"継続任務：未設定", "継続任務：%s · %s · 配備 %d · 自動交代", "継続任務停止：兵種・食性・区域が無効",
		"集結地点を設定しました。新規ユニットは先に向かいます", "集結地点を解除しました", "マップを左クリックして集結地点を設定。右クリックまたは Esc で取消", "集結地点の設定を取り消しました",
		"自動補充：%s", "自動補充目標：%d", "兵営の継続任務を解除。現役 %d 体を解任しました", "%s は%sの継続任務を実行できません",
		"%s用の正方形%sを右ドラッグ。Esc で取消", "任務が非対応、または区域がコロニーの行動範囲外です", "継続%sを保存：現役 %d 体。補充個体が自動交代します", "%sの設定を取り消しました",
		"右クリックで展開 · 半径 %.0f μm · 細菌代謝 %.0f%%", "展開 %.1f / %.1f 秒 · 半径 %.0f μm", "抑制半径 %.0f μm · 吸収・分裂速度 %.0f%%",
		"射程 %.0f μm · 溶菌半径 %.0f μm · 次回 %.1f 秒", "威力 %.3f × 食性効率 · 前回命中 %d",
		"右クリックで展開 · 半径 %.0f μm · 敵菌吸収・成長 %.0f%%", "展開 %.1f / %.1f 秒 · 半径 %.0f μm", "封鎖半径 %.0f μm · 切断菌糸の衰弱速度 %.0f%%"
	],
	"es": [
		"Activo", "Inactivo", "Sí", "No", "R", "T", "Q", "E", "L", "Su", "D", "P", "H", "AF",
		"zona defensiva", "zona de recolección", "zona de purga", "Def.", "Reco.", "Purga", "Borrar",
		"Reposición: %s · %s %d / %d", "Reposición pausada: dieta de %s inactiva", "Repos.: %s", "Meta %d", "Fijar reunión", "Quitar reunión",
		"Tarea continua: sin asignar", "Tarea: %s · %s · %d activos · relevo auto.", "Tarea pausada: unidad, dieta o zona no válida",
		"Punto de reunión fijado; las unidades nuevas irán allí primero", "Punto de reunión eliminado", "Clic izquierdo en el mapa para fijar la reunión; clic derecho o Esc cancela", "Se canceló la colocación del punto de reunión",
		"Reposición automática: %s", "Objetivo de reposición: %d", "Tarea continua eliminada; %d unidades activas liberadas", "%s no puede realizar una %s continua",
		"Para %s, arrastra con el botón derecho una %s cuadrada; Esc cancela", "Tarea incompatible o zona fuera del alcance de la colonia", "%s continua guardada: %d activos; los reemplazos tomarán el relevo", "Se canceló la configuración de %s",
		"Clic derecho para desplegar · radio %.0f μm · metabolismo bacteriano %.0f%%", "Despliegue %.1f / %.1f s · radio %.0f μm", "Radio supresor %.0f μm · absorción y división al %.0f%%",
		"Alcance %.0f μm · radio de lisis %.0f μm · próxima descarga %.1f s", "Daño %.3f × eficiencia trófica · último impacto %d",
		"Clic derecho para desplegar · radio %.0f μm · absorción y expansión rival %.0f%%", "Despliegue %.1f / %.1f s · radio %.0f μm", "Radio de bloqueo %.0f μm · deterioro de hifas cortadas %.0f%%"
	],
	"de": [
		"Aktiv", "Inaktiv", "An", "Aus", "J", "T", "C", "S", "L", "H", "V", "B", "F", "A",
		"Schutzgebiet", "Sammelgebiet", "Jagdgebiet", "Schutz", "Sammeln", "Jagd", "Löschen",
		"Auto-Nachschub: %s · %s %d / %d", "Nachschub pausiert: Nahrung für %s inaktiv", "Auto: %s", "Ziel %d", "Sammelpunkt", "Punkt löschen",
		"Dauerauftrag: nicht gesetzt", "Auftrag: %s · %s · %d aktiv · Auto-Ablösung", "Auftrag pausiert: Einheit, Nahrung oder Gebiet ungültig",
		"Sammelpunkt gesetzt; neue Einheiten gehen zuerst dorthin", "Sammelpunkt gelöscht", "Linksklick auf die Karte setzt den Sammelpunkt; Rechtsklick oder Esc bricht ab", "Setzen des Sammelpunkts abgebrochen",
		"Automatischer Nachschub: %s", "Nachschubziel: %d", "Dauerauftrag gelöscht; %d aktive Einheiten freigestellt", "%s kann keinen dauerhaften Auftrag „%s“ ausführen",
		"Für %s mit Rechtsziehen ein quadratisches %s markieren; Esc bricht ab", "Auftrag unvereinbar oder Gebiet außerhalb des Kolonieradius", "Dauerhaftes %s gespeichert: %d aktiv; Ersatz übernimmt automatisch", "Einrichtung von %s abgebrochen",
		"Rechtsklick zum Entfalten · Radius %.0f μm · Bakterienstoffwechsel %.0f%%", "Entfalten %.1f / %.1f s · Radius %.0f μm", "Hemmfeld %.0f μm · Aufnahme und Teilung mit %.0f%% Tempo",
		"Reichweite %.0f μm · Lyseradius %.0f μm · nächste Abgabe %.1f s", "Schaden %.3f × Nahrungseffizienz · letzter Treffer %d",
		"Rechtsklick zum Entfalten · Radius %.0f μm · Pilzaufnahme und Wachstum %.0f%%", "Entfalten %.1f / %.1f s · Radius %.0f μm", "Sperrradius %.0f μm · Zerfall getrennter Hyphen %.0f%% Tempo"
	],
	"ru": [
		"Включено", "Выключено", "Вкл", "Выкл", "Ф", "Н", "Х", "Р", "Л", "П", "К", "Б", "О", "А",
		"зона защиты", "зона сбора", "зона зачистки", "Защита", "Сбор", "Зачист.", "Сброс",
		"Автопополнение: %s · %s %d / %d", "Пополнение приостановлено: питание %s неактивно", "Авто: %s", "Цель %d", "Точка сбора", "Убрать точку",
		"Постоянная задача: не задана", "Задача: %s · %s · в строю %d · автосмена", "Задача приостановлена: неверны боец, питание или зона",
		"Точка сбора задана; новые бойцы сначала пойдут туда", "Точка сбора удалена", "ЛКМ по карте задаёт точку сбора; ПКМ или Esc отменяет", "Установка точки сбора отменена",
		"Автопополнение: %s", "Цель автопополнения: %d", "Постоянная задача снята; освобождено бойцов: %d", "%s не может выполнять постоянную задачу «%s»",
		"Для %s протяните ПКМ квадратную %s; Esc отменяет", "Задача несовместима или зона вне радиуса колонии", "Постоянная %s сохранена: в строю %d; пополнение сменит бойцов", "Настройка %s отменена",
		"ПКМ для развёртывания · радиус %.0f μm · метаболизм бактерий %.0f%%", "Развёртывание %.1f / %.1f с · радиус %.0f μm", "Радиус подавления %.0f μm · поглощение и деление %.0f%%",
		"Дальность %.0f μm · радиус лизиса %.0f μm · следующий выброс %.1f с", "Урон %.3f × эффективность питания · прошлое попадание %d",
		"ПКМ для развёртывания · радиус %.0f μm · поглощение и рост врага %.0f%%", "Развёртывание %.1f / %.1f с · радиус %.0f μm", "Радиус блокады %.0f μm · распад отрезанных гиф %.0f%%"
	]
}


static func normalize_locale(locale: String) -> String:
	var normalized := locale.strip_edges().replace("-", "_")
	if LOCALES.has(normalized):
		return normalized
	var lowered := normalized.to_lower()
	if lowered.begins_with("zh_tw") or lowered.begins_with("zh_hk") or lowered.begins_with("zh_mo") or lowered.begins_with("zh_hant"):
		return "zh_TW"
	if lowered.begins_with("zh"):
		return "zh_CN"
	for locale_id in ["en", "ja", "es", "de", "ru"]:
		if lowered.begins_with(locale_id):
			return locale_id
	return "en"


static func text(key: String, locale: String) -> String:
	var key_index := KEYS.find(key)
	if key_index < 0:
		return key
	var values: Array = VALUES.get(normalize_locale(locale), VALUES["en"])
	if key_index >= values.size():
		values = VALUES["en"]
	return String(values[key_index])
