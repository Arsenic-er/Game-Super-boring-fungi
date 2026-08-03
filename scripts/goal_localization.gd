extends RefCounted

const LOCALES: Array[String] = ["zh_CN", "zh_TW", "en", "ja", "es", "de", "ru"]
const GOAL_IDS: Array[String] = [
	"first_hypha", "mineral_trace", "second_core", "network_1mm", "primary_diet",
	"bacterial_bloom", "first_bacterium", "bacteria_control", "first_structure",
	"bacteria_specialist", "culture_survey", "expedition_supply", "expedition_control",
	"barracks_directive", "ecology_response", "suppression_field", "disperser_burst",
	"rival_colony", "rival_guard", "hypha_severing", "antifungal_lockdown", "sporefall_guard"
]

# Each entry is [titles, descriptions]; both arrays follow LOCALES.
const GOALS := {
	"first_hypha": [["初次萌发", "初次萌發", "First Germination", "最初の発芽", "Primera germinación", "Erste Keimung", "Первое прорастание"], ["形成第一段主菌丝", "形成第一段主菌絲", "Form the first primary hypha", "最初の主菌糸を形成する", "Forma la primera hifa principal", "Bilde die erste Haupthyphe", "Сформируйте первую главную гифу"]],
	"mineral_trace": [["矿物脉络", "礦物脈絡", "Mineral Pathway", "ミネラルの脈", "Rastro mineral", "Mineralspur", "Минеральный след"], ["累计吸收 1.000 矿物离子", "累計吸收 1.000 礦物離子", "Absorb 1.000 mineral ions in total", "ミネラルイオンを累計1.000吸収する", "Absorbe 1.000 iones minerales", "Absorbiere 1.000 Mineralionen", "Поглотите 1.000 минеральных ионов"]],
	"second_core": [["双核心网络", "雙核心網路", "Dual-Core Network", "二核ネットワーク", "Red de dos núcleos", "Zweikernnetz", "Двухъядерная сеть"], ["形成第二个孢子核心", "形成第二個孢子核心", "Form a second spore core", "2つ目の胞子核を形成する", "Forma un segundo núcleo de espora", "Bilde einen zweiten Sporenkern", "Сформируйте второе споровое ядро"]],
	"network_1mm": [["一毫米网络", "一毫米網路", "One-Millimeter Network", "1ミリのネットワーク", "Red de un milímetro", "Ein-Millimeter-Netz", "Миллиметровая сеть"], ["主菌丝总长度达到 1000 μm", "主菌絲總長度達到 1000 μm", "Reach 1000 μm of primary hyphae", "主菌糸を1000 μmにする", "Alcanza 1000 μm de hifas", "Erreiche 1000 μm Haupthyphen", "Достигните 1000 μm главных гиф"]],
	"primary_diet": [["确立主食性", "確立主食性", "Primary Diet", "主食性の確立", "Dieta principal", "Hauptnahrung", "Основной рацион"], ["解锁第一条生物食性", "解鎖第一條生物食性", "Unlock the first biological diet", "最初の生物食性を解除する", "Desbloquea la primera dieta biológica", "Schalte die erste biologische Nahrung frei", "Откройте первый биологический рацион"]],
	"bacterial_bloom": [["培养皿中的新生命", "培養皿中的新生命", "Life in the Dish", "培養皿の新たな生命", "Vida en la placa", "Leben in der Schale", "Жизнь в чашке"], ["观察累计25次细菌分裂", "觀察累計25次細菌分裂", "Observe 25 bacterial divisions", "細菌分裂を25回観察する", "Observa 25 divisiones bacterianas", "Beobachte 25 Bakterienteilungen", "Наблюдайте 25 делений бактерий"]],
	"first_bacterium": [["首次微型捕食", "首次微型捕食", "First Micropredation", "最初の微小捕食", "Primera micropredación", "Erste Mikroprädation", "Первая микроохота"], ["完整消化第一个细菌", "完整消化第一個細菌", "Fully digest the first bacterium", "最初の細菌を完全に消化する", "Digiere la primera bacteria", "Verdaue das erste Bakterium", "Переварите первую бактерию"]],
	"bacteria_control": [["菌落控制", "菌落控制", "Colony Control", "コロニー制御", "Control de colonia", "Koloniekontrolle", "Контроль колонии"], ["累计完整消化25个细菌", "累計完整消化25個細菌", "Fully digest 25 bacteria", "細菌を25体完全に消化する", "Digiere 25 bacterias", "Verdaue 25 Bakterien", "Переварите 25 бактерий"]],
	"first_structure": [["结构突变", "結構突變", "Structural Mutation", "構造変異", "Mutación estructural", "Strukturmutation", "Структурная мутация"], ["购买第一级通用结构进化", "購買第一級通用結構進化", "Buy the first general structure evolution", "汎用構造進化を1段階購入する", "Compra la primera evolución estructural", "Kaufe die erste Strukturevolution", "Купите первый уровень общей структуры"]],
	"bacteria_specialist": [["细菌专家", "細菌專家", "Bacteria Specialist", "細菌スペシャリスト", "Especialista bacteriano", "Bakterienspezialist", "Специалист по бактериям"], ["将任一细菌专属组件升至3级", "將任一細菌專屬組件升至3級", "Raise any bacteria component to level 3", "細菌部位をレベル3にする", "Mejora un componente al nivel 3", "Bringe eine Komponente auf Stufe 3", "Улучшите компонент бактерий до 3-го уровня"]],
	"culture_survey": [["培养环境勘探", "培養環境勘探", "Culture Survey", "培養環境調査", "Estudio del cultivo", "Kulturkartierung", "Исследование среды"], ["永久记录3处异常资源区", "永久記錄3處異常資源區", "Record 3 resource hotspots", "異常資源域を3か所記録する", "Registra 3 zonas de recursos", "Erfasse 3 Ressourcengebiete", "Отметьте 3 ресурсные зоны"]],
	"expedition_supply": [["远征补给线", "遠征補給線", "Expedition Supply Line", "遠征補給線", "Línea de suministro", "Expeditionsnachschub", "Линия снабжения"], ["体外部队累计带回10.000有机与0.500矿物", "體外部隊帶回10.000有機與0.500礦物", "Return 10.000 organic and 0.500 mineral", "有機10.000とミネラル0.500を持ち帰る", "Trae 10.000 orgánico y 0.500 mineral", "Bringe 10.000 Organik und 0.500 Mineral zurück", "Доставьте 10.000 органики и 0.500 минералов"]],
	"expedition_control": [["主动菌落压制", "主動菌落壓制", "Active Colony Suppression", "能動的コロニー制圧", "Supresión activa", "Aktive Eindämmung", "Активное подавление"], ["体外部队累计消灭10个细菌", "體外部隊累計消滅10個細菌", "Destroy 10 bacteria with units", "体外部隊で細菌を10体倒す", "Elimina 10 bacterias con unidades", "Vernichte 10 Bakterien mit Einheiten", "Уничтожьте отрядами 10 бактерий"]],
	"barracks_directive": [["自动菌落编制", "自動菌落編制", "Automated Colony Roster", "自動コロニー編成", "Plantilla automática", "Automatische Planung", "Автоматический гарнизон"], ["为任一兵营保存一次持续防区、采区或猎区", "為任一兵營儲存持續任務區", "Save a persistent zone at any barracks", "兵営に持続任務区を保存する", "Guarda una zona persistente en un cuartel", "Speichere eine Dauerzone an einer Kaserne", "Сохраните постоянную зону для казармы"]],
	"ecology_response": [["生态应答", "生態應答", "Ecological Response", "生態応答", "Respuesta ecológica", "Ökologische Reaktion", "Экологический ответ"], ["成功应对1次细菌生态事件", "成功應對1次細菌生態事件", "Resolve 1 bacterial ecology event", "細菌生態イベントに1回対処する", "Resuelve 1 evento bacteriano", "Bewältige 1 bakterielles Ereignis", "Завершите 1 бактериальное экособытие"]],
	"suppression_field": [["静菌封锁", "靜菌封鎖", "Bacteriostatic Lockdown", "静菌封鎖", "Bloqueo bacteriostático", "Bakteriostatische Sperre", "Бактериостатическая блокада"], ["用抑菌囊体控制1次细菌暴发", "用抑菌囊體控制1次細菌暴發", "Contain 1 bloom with a suppressor capsule", "抑菌嚢体でブルームを1回抑える", "Contén 1 brote con una cápsula", "Dämme 1 Blüte mit einer Hemmkapsel ein", "Сдержите 1 вспышку подавляющей капсулой"]],
	"disperser_burst": [["群落裂解", "群落裂解", "Colony Lysis", "群集溶解", "Lisis de colonia", "Kolonielyse", "Лизис колонии"], ["单次范围裂解命中8个细菌", "單次範圍裂解命中8個細菌", "Hit 8 bacteria with one area lysis", "1回の範囲溶解で細菌8体に命中する", "Alcanza 8 bacterias con una lisis", "Triff 8 Bakterien mit einer Flächenlyse", "Поразите 8 бактерий одним массовым лизисом"]],
	"rival_colony": [["竞争者清除", "競爭者清除", "Rival Removal", "競争者の排除", "Eliminación rival", "Rivalenbeseitigung", "Устранение соперника"], ["使1座竞争性真菌核心失活", "使1座競爭性真菌核心失活", "Deactivate 1 rival fungal core", "競争真菌核を1つ失活させる", "Desactiva 1 núcleo fúngico rival", "Deaktiviere 1 rivalisierenden Pilzkern", "Выведите из строя 1 ядро конкурента"]],
	"rival_guard": [["前线拦截", "前線攔截", "Frontline Interception", "前線迎撃", "Intercepción frontal", "Frontabfang", "Перехват на передовой"], ["累计击败5个竞争菌守卫孢子", "累計擊敗5個競爭菌守衛孢子", "Defeat 5 rival guard spores", "護衛胞子を5体倒す", "Derrota 5 esporas guardianas", "Besiege 5 Wächtersproren", "Победите 5 спор-стражей"]],
	"hypha_severing": [["断丝战术", "斷絲戰術", "Hypha-Severing Tactics", "菌糸切断戦術", "Táctica de corte", "Hyphentrennung", "Тактика рассечения"], ["累计切断3段敌方菌丝", "累計切斷3段敵方菌絲", "Sever 3 enemy hypha segments", "敵の菌糸を3本切断する", "Corta 3 segmentos de hifa", "Durchtrenne 3 Hyphensegmente", "Разорвите 3 сегмента вражеских гиф"]],
	"antifungal_lockdown": [["真菌封锁", "真菌封鎖", "Antifungal Lockdown", "抗真菌封鎖", "Bloqueo antifúngico", "Antimykotische Sperre", "Противогрибковая блокада"], ["在抗真菌区内使1座竞争核心失活", "在抗真菌區內使1座競爭核心失活", "Deactivate 1 rival core in an antifungal zone", "抗真菌区内で競争核を1つ失活させる", "Desactiva 1 núcleo en una zona antifúngica", "Deaktiviere 1 Rivalenkern in einer Antipilzzone", "Выведите из строя 1 ядро в противогрибковой зоне"]],
	"sporefall_guard": [["孢子雨守卫", "孢子雨守衛", "Sporefall Guardian", "胞子雨の守護者", "Guardián de la lluvia", "Sporenfallwache", "Страж споропада"], ["击退3轮竞争孢子雨", "擊退3輪競爭孢子雨", "Repel 3 rival sporefall waves", "競争胞子雨を3波撃退する", "Repele 3 oleadas de esporas", "Wehre 3 Sporenfallwellen ab", "Отразите 3 волны спор соперника"]]
}

const TEXTS := {
	"panel_title": ["长期目标", "長期目標", "Long-Term Goals", "長期目標", "Objetivos a largo plazo", "Langzeitziele", "Долгосрочные цели"],
	"panel_subtitle": ["不同目标提供不同奖励", "不同目標提供不同獎勵", "Each goal offers a different reward", "目標ごとに報酬が異なります", "Cada objetivo ofrece una recompensa", "Jedes Ziel bietet eine andere Belohnung", "За разные цели полагаются разные награды"],
	"page_fmt": ["%d / %d 页", "%d / %d 頁", "Page %d / %d", "%d / %d ページ", "Página %d / %d", "Seite %d / %d", "Страница %d / %d"],
	"all_done": ["全部目标已完成", "全部目標已完成", "All goals completed", "すべての目標を達成", "Todos los objetivos completados", "Alle Ziele abgeschlossen", "Все цели выполнены"],
	"not_tracked": ["未追踪目标 · 点击打开", "未追蹤目標 · 點擊開啟", "No tracked goal · Click to open", "追跡中なし · クリックで開く", "Sin objetivo · Haz clic para abrir", "Kein Ziel · Zum Öffnen klicken", "Нет цели · Нажмите, чтобы открыть"],
	"tracker_claimable_fmt": ["可领取｜%s｜%s", "可領取｜%s｜%s", "CLAIM｜%s｜%s", "受取可能｜%s｜%s", "COBRAR｜%s｜%s", "ABHOLEN｜%s｜%s", "ЗАБРАТЬ｜%s｜%s"],
	"tracker_active_fmt": ["追踪｜%s｜%s", "追蹤｜%s｜%s", "TRACK｜%s｜%s", "追跡｜%s｜%s", "SEGUIR｜%s｜%s", "ZIEL｜%s｜%s", "ЦЕЛЬ｜%s｜%s"],
	"tooltip_progress_fmt": ["进度：%s", "進度：%s", "Progress: %s", "進捗：%s", "Progreso: %s", "Fortschritt: %s", "Прогресс: %s"],
	"tooltip_reward_fmt": ["奖励：%s", "獎勵：%s", "Reward: %s", "報酬：%s", "Recompensa: %s", "Belohnung: %s", "Награда: %s"],
	"tooltip_open": ["点击打开目标面板", "點擊開啟目標面板", "Click to open the goals panel", "クリックで目標を開く", "Haz clic para abrir los objetivos", "Klicken, um Ziele zu öffnen", "Нажмите, чтобы открыть цели"],
	"tracking_cancelled": ["已取消目标追踪", "已取消目標追蹤", "Goal tracking cancelled", "目標の追跡を解除しました", "Seguimiento cancelado", "Zielverfolgung beendet", "Отслеживание отменено"],
	"tracking_fmt": ["正在追踪：%s", "正在追蹤：%s", "Tracking: %s", "追跡中：%s", "Siguiendo: %s", "Verfolgt: %s", "Отслеживается: %s"],
	"completed_fmt": ["目标完成：%s，打开目标面板领取奖励", "目標完成：%s，開啟目標面板領取獎勵", "Goal complete: %s. Open goals to claim it.", "目標達成：%s。目標パネルで受取可能です。", "Objetivo completado: %s. Abre el panel.", "Ziel erreicht: %s. Öffne die Ziele.", "Цель выполнена: %s. Откройте панель целей."],
	"reward_claimed_fmt": ["目标奖励已领取：%s", "目標獎勵已領取：%s", "Goal reward claimed: %s", "目標報酬を受取：%s", "Recompensa recibida: %s", "Zielbelohnung erhalten: %s", "Награда получена: %s"],
	"track": ["追踪", "追蹤", "Track", "追跡", "Seguir", "Verfolgen", "Следить"],
	"untrack": ["取消追踪", "取消追蹤", "Untrack", "追跡解除", "Dejar", "Aufheben", "Не следить"],
	"claimed": ["已领取", "已領取", "Claimed", "受取済み", "Recibido", "Erhalten", "Получено"],
	"claim": ["领取", "領取", "Claim", "受取", "Cobrar", "Abholen", "Забрать"],
	"in_progress": ["进行中", "進行中", "In Progress", "進行中", "En curso", "Läuft", "В процессе"],
	"prev_page": ["上一页", "上一頁", "Previous", "前へ", "Anterior", "Zurück", "Назад"],
	"next_page": ["下一页", "下一頁", "Next", "次へ", "Siguiente", "Weiter", "Далее"],
	"progress_count_fmt": ["%d / %d", "%d / %d", "%d / %d", "%d / %d", "%d / %d", "%d / %d", "%d / %d"],
	"progress_decimal_fmt": ["%.3f / %.3f", "%.3f / %.3f", "%.3f / %.3f", "%.3f / %.3f", "%.3f / %.3f", "%.3f / %.3f", "%.3f / %.3f"],
	"progress_length_fmt": ["%.0f / %d μm", "%.0f / %d μm", "%.0f / %d μm", "%.0f / %d μm", "%.0f / %d μm", "%.0f / %d μm", "%.0f / %d μm"],
	"progress_areas_fmt": ["%d / %d 处", "%d / %d 處", "%d / %d areas", "%d / %d か所", "%d / %d zonas", "%d / %d Gebiete", "%d / %d зон"],
	"progress_supply_fmt": ["有机 %.3f/%.3f　矿物 %.3f/%.3f", "有機 %.3f/%.3f　礦物 %.3f/%.3f", "Organic %.3f/%.3f · Mineral %.3f/%.3f", "有機 %.3f/%.3f・ミネラル %.3f/%.3f", "Orgánico %.3f/%.3f · Mineral %.3f/%.3f", "Organik %.3f/%.3f · Mineral %.3f/%.3f", "Органика %.3f/%.3f · Минералы %.3f/%.3f"],
	"reward_dna_fmt": ["DNA +%d", "DNA +%d", "DNA +%d", "DNA +%d", "ADN +%d", "DNA +%d", "ДНК +%d"],
	"reward_organic_fmt": ["有机营养 +%.3f", "有機營養 +%.3f", "Organic +%.3f", "有機栄養 +%.3f", "Orgánico +%.3f", "Organik +%.3f", "Органика +%.3f"],
	"reward_mineral_fmt": ["矿物离子 +%.3f", "礦物離子 +%.3f", "Mineral +%.3f", "ミネラル +%.3f", "Mineral +%.3f", "Mineral +%.3f", "Минералы +%.3f"],
	"reward_dna_organic_fmt": ["DNA +%d　有机 +%.3f", "DNA +%d　有機 +%.3f", "DNA +%d · Organic +%.3f", "DNA +%d・有機 +%.3f", "ADN +%d · Orgánico +%.3f", "DNA +%d · Organik +%.3f", "ДНК +%d · Органика +%.3f"],
	"reward_dna_mineral_fmt": ["DNA +%d　矿物 +%.3f", "DNA +%d　礦物 +%.3f", "DNA +%d · Mineral +%.3f", "DNA +%d・ミネラル +%.3f", "ADN +%d · Mineral +%.3f", "DNA +%d · Mineral +%.3f", "ДНК +%d · Минералы +%.3f"],
	"reward_organic_mineral_fmt": ["有机 +%.3f　矿物 +%.3f", "有機 +%.3f　礦物 +%.3f", "Organic +%.3f · Mineral +%.3f", "有機 +%.3f・ミネラル +%.3f", "Orgánico +%.3f · Mineral +%.3f", "Organik +%.3f · Mineral +%.3f", "Органика +%.3f · Минералы +%.3f"],
	"reward_all_fmt": ["DNA +%d　有机 +%.3f　矿物 +%.3f", "DNA +%d　有機 +%.3f　礦物 +%.3f", "DNA +%d · Organic +%.3f · Mineral +%.3f", "DNA +%d・有機 +%.3f・ミネラル +%.3f", "ADN +%d · Orgánico +%.3f · Mineral +%.3f", "DNA +%d · Organik +%.3f · Mineral +%.3f", "ДНК +%d · Органика +%.3f · Минералы +%.3f"]
}

static func normalize_locale(locale_id: String) -> String:
	var lowered := locale_id.strip_edges().replace("-", "_").to_lower()
	if lowered.begins_with("zh_hant") or ["zh_tw", "zh_hk", "zh_mo"].has(lowered): return "zh_TW"
	if lowered.begins_with("zh"): return "zh_CN"
	for locale in ["en", "ja", "es", "de", "ru"]:
		if lowered == locale or lowered.begins_with(locale + "_"): return locale
	return "en"

static func text(key: String, locale_id: String) -> String:
	var index := LOCALES.find(normalize_locale(locale_id))
	if key.begins_with("goal_"):
		var field_index := 0 if key.ends_with("_title") else (1 if key.ends_with("_desc") else -1)
		if field_index >= 0:
			var suffix := "title" if field_index == 0 else "desc"
			var goal_id := key.substr(5, key.length() - 6 - suffix.length())
			var entry: Array = GOALS.get(goal_id, [])
			if entry.size() == 2: return String((entry[field_index] as Array)[index])
	var values: Array = TEXTS.get(key, [])
	return String(values[index]) if values.size() == LOCALES.size() else key

static func reward_text(reward: Dictionary, locale_id: String) -> String:
	var dna := int(reward.get("dna", 0)); var organic := float(reward.get("organic", 0.0)); var mineral := float(reward.get("mineral", 0.0))
	if dna != 0 and organic != 0.0 and mineral != 0.0: return text("reward_all_fmt", locale_id) % [dna, organic, mineral]
	if dna != 0 and organic != 0.0: return text("reward_dna_organic_fmt", locale_id) % [dna, organic]
	if dna != 0 and mineral != 0.0: return text("reward_dna_mineral_fmt", locale_id) % [dna, mineral]
	if organic != 0.0 and mineral != 0.0: return text("reward_organic_mineral_fmt", locale_id) % [organic, mineral]
	if dna != 0: return text("reward_dna_fmt", locale_id) % dna
	if organic != 0.0: return text("reward_organic_fmt", locale_id) % organic
	if mineral != 0.0: return text("reward_mineral_fmt", locale_id) % mineral
	return ""
