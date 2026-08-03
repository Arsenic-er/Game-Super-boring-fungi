extends RefCounted


const LOCALES: Array[String] = ["zh_CN", "zh_TW", "en", "ja", "es", "de", "ru"]
const PAGE_IDS: Array[String] = ["germination", "resources_dna", "evolution", "barracks_command", "exploration_goals", "survival_failure"]

const TEXTS := {
	"zh_CN": {
		"menu_guide": "玩法指引", "guide_title": "菌落培养手册", "guide_prev": "上一页", "guide_next": "下一页", "guide_back": "返回", "guide_page_fmt": "%d / %d", "guide_keys_hint": "← → 翻页 · Home / End 跳转 · Esc 返回暂停菜单",
		"guide_germination_title": "从孢子到菌丝",
		"guide_germination_body": "点击孢子核心，选择“延伸”。\n再点击附近空地，主菌丝会慢慢长过去。\n靠近营养点后，细吸收丝会自动伸出。",
		"guide_germination_hint": "先向橙色有机营养生长。",
		"guide_resources_dna_title": "营养与 DNA",
		"guide_resources_dna_body": "实验室里的水分无限；生长主要消耗有机营养，特殊结构还需要矿物离子。\n孢子核心会缓慢消耗营养并记录 DNA。\n按住 Shift 或 Ctrl，可一次排队 5 或 10 份 DNA。",
		"guide_resources_dna_hint": "DNA 用来购买进化。",
		"guide_evolution_title": "选择进化方向",
		"guide_evolution_body": "按 E 打开升级界面。\n用 DNA 解锁食性、能力和专属兵种；节点强化则消耗有机营养。\n新增食性会越来越贵，所以先发展一种主食。",
		"guide_evolution_hint": "先选主食性，再升级专属能力。",
		"guide_barracks_command_title": "兵营与部队指挥",
		"guide_barracks_command_body": "在成熟菌丝末端建造兵营核心，生产体外孢子。\n按住左键拖出方框选择部队，右键点击地点或敌人下达命令。\n绿色路线表示命令方向，采集单位会自动带资源回家。",
		"guide_barracks_command_hint": "先用采集兵补给，再派战斗兵。",
		"guide_exploration_goals_title": "探索与长期目标",
		"guide_exploration_goals_body": "黑幕下的区域要由部队探索后才会显示。\n小地图会记录发现的资源区与威胁。\n按 G 打开长期目标，追踪进度并领取不同奖励。",
		"guide_exploration_goals_hint": "沿小地图的未知边缘探索。",
		"guide_survival_failure_title": "保护你的菌落",
		"guide_survival_failure_body": "鼠标移到核心上，可查看生物量百分比。\n毒素和攻击会降低生物量；核心死亡后，未被其他核心接回的菌丝会衰退。\n所有核心死亡时，本局失败。",
		"guide_survival_failure_hint": "保留营养修复，让核心互相接应。"
	},
	"zh_TW": {
		"menu_guide": "玩法指引", "guide_title": "菌落培養手冊", "guide_prev": "上一頁", "guide_next": "下一頁", "guide_back": "返回", "guide_page_fmt": "%d / %d", "guide_keys_hint": "← → 翻頁 · Home / End 跳轉 · Esc 返回暫停選單",
		"guide_germination_title": "從孢子到菌絲",
		"guide_germination_body": "點擊孢子核心，選擇「延伸」。\n再點擊附近空地，主菌絲會慢慢長過去。\n靠近營養點後，細吸收絲會自動伸出。",
		"guide_germination_hint": "先向橙色有機營養生長。",
		"guide_resources_dna_title": "營養與 DNA",
		"guide_resources_dna_body": "實驗室裡的水分無限；生長主要消耗有機營養，特殊結構還需要礦物離子。\n孢子核心會緩慢消耗營養並記錄 DNA。\n按住 Shift 或 Ctrl，可一次排隊 5 或 10 份 DNA。",
		"guide_resources_dna_hint": "DNA 用來購買進化。",
		"guide_evolution_title": "選擇進化方向",
		"guide_evolution_body": "按 E 開啟升級介面。\n用 DNA 解鎖食性、能力和專屬兵種；節點強化則消耗有機營養。\n新增食性會越來越貴，所以先發展一種主食。",
		"guide_evolution_hint": "先選主食性，再升級專屬能力。",
		"guide_barracks_command_title": "兵營與部隊指揮",
		"guide_barracks_command_body": "在成熟菌絲末端建造兵營核心，生產體外孢子。\n按住左鍵拖出方框選擇部隊，右鍵點擊地點或敵人下達命令。\n綠色路線表示命令方向，採集單位會自動帶資源回家。",
		"guide_barracks_command_hint": "先用採集兵補給，再派戰鬥兵。",
		"guide_exploration_goals_title": "探索與長期目標",
		"guide_exploration_goals_body": "黑幕下的區域要由部隊探索後才會顯示。\n小地圖會記錄發現的資源區與威脅。\n按 G 開啟長期目標，追蹤進度並領取不同獎勵。",
		"guide_exploration_goals_hint": "沿小地圖的未知邊緣探索。",
		"guide_survival_failure_title": "保護你的菌落",
		"guide_survival_failure_body": "滑鼠移到核心上，可查看生物量百分比。\n毒素和攻擊會降低生物量；核心死亡後，未被其他核心接回的菌絲會衰退。\n所有核心死亡時，本局失敗。",
		"guide_survival_failure_hint": "保留營養修復，讓核心互相接應。"
	},
	"en": {
		"menu_guide": "Gameplay guide", "guide_title": "Colony Culture Guide", "guide_prev": "Previous", "guide_next": "Next", "guide_back": "Back", "guide_page_fmt": "%d / %d", "guide_keys_hint": "← → turn pages · Home / End jump · Esc returns to pause",
		"guide_germination_title": "From Spore to Hypha",
		"guide_germination_body": "Click the spore core and choose Extend.\nThen click nearby ground; the primary hypha will slowly grow there.\nNear resource specks, fine feeder hyphae extend automatically.",
		"guide_germination_hint": "Grow toward orange organic nutrients first.",
		"guide_resources_dna_title": "Nutrients and DNA",
		"guide_resources_dna_body": "Water is unlimited in the lab; growth mostly uses organic nutrients, while special structures also need mineral ions.\nThe spore core slowly spends nutrients to record DNA.\nHold Shift or Ctrl to queue 5 or 10 DNA at once.",
		"guide_resources_dna_hint": "Spend DNA on evolution.",
		"guide_evolution_title": "Choose an Evolution Path",
		"guide_evolution_body": "Press E to open Upgrades.\nSpend DNA on diets, abilities, and specialist units; node upgrades use organic nutrients.\nExtra diets become much more expensive, so develop one main diet first.",
		"guide_evolution_hint": "Pick a main diet, then improve its abilities.",
		"guide_barracks_command_title": "Barracks and Commands",
		"guide_barracks_command_body": "Build a barracks core at a mature hypha tip to produce expedition spores.\nHold left mouse and drag a square to select units; right-click a place or enemy to command them.\nThe green route shows the order, and gatherers carry resources home automatically.",
		"guide_barracks_command_hint": "Supply first, then send combat units.",
		"guide_exploration_goals_title": "Exploration and Goals",
		"guide_exploration_goals_body": "Areas under the dark fog appear only after your units explore them.\nThe minimap records discovered resource zones and threats.\nPress G for long-term goals, track progress, and claim different rewards.",
		"guide_exploration_goals_hint": "Explore along the minimap’s unknown edge.",
		"guide_survival_failure_title": "Protect Your Colony",
		"guide_survival_failure_body": "Hover over a core to see its biomass percentage.\nToxins and attacks reduce biomass; after a core dies, hyphae not reconnected by another core decay.\nThe run ends when every core is dead.",
		"guide_survival_failure_hint": "Save nutrients for repairs and link your cores."
	},
	"ja": {
		"menu_guide": "遊び方ガイド", "guide_title": "コロニー培養ガイド", "guide_prev": "前へ", "guide_next": "次へ", "guide_back": "戻る", "guide_page_fmt": "%d / %d", "guide_keys_hint": "← → ページ移動 · Home / End ジャンプ · Esc 一時停止へ",
		"guide_germination_title": "胞子から菌糸へ",
		"guide_germination_body": "胞子核をクリックし、「伸長」を選びます。\n近くの空き地をクリックすると、主菌糸がゆっくり伸びます。\n資源点に近づくと、細い吸収糸が自動で伸びます。",
		"guide_germination_hint": "まず橙色の有機栄養へ伸びましょう。",
		"guide_resources_dna_title": "栄養と DNA",
		"guide_resources_dna_body": "実験室では水分は無限です。成長には主に有機栄養を使い、特殊構造にはミネラルも必要です。\n胞子核は栄養をゆっくり消費して DNA を記録します。\nShift または Ctrl を押すと、DNA を5個または10個まとめて予約できます。",
		"guide_resources_dna_hint": "DNA は進化の購入に使います。",
		"guide_evolution_title": "進化の方向を選ぶ",
		"guide_evolution_body": "E でアップグレードを開きます。\nDNA で食性・能力・専用兵種を解除し、ノード強化には有機栄養を使います。\n食性を増やすほど高価になるため、まず主食を1つ育てましょう。",
		"guide_evolution_hint": "主食性を選び、専用能力を伸ばしましょう。",
		"guide_barracks_command_title": "兵営と部隊指揮",
		"guide_barracks_command_body": "成熟した菌糸の先端に兵営核を作り、体外胞子を生産します。\n左ボタンで四角くドラッグして部隊を選び、場所や敵を右クリックして命令します。\n緑の線が命令方向を示し、採取部隊は自動で資源を持ち帰ります。",
		"guide_barracks_command_hint": "まず採取で補給し、次に戦闘部隊を送りましょう。",
		"guide_exploration_goals_title": "探索と長期目標",
		"guide_exploration_goals_body": "暗い霧の下は、部隊が探索すると表示されます。\nミニマップには発見した資源域と脅威が記録されます。\nG で長期目標を開き、進捗を追跡して報酬を受け取ります。",
		"guide_exploration_goals_hint": "ミニマップの未知の縁を探索しましょう。",
		"guide_survival_failure_title": "コロニーを守る",
		"guide_survival_failure_body": "核にカーソルを合わせると、生物量の割合を確認できます。\n毒素や攻撃で生物量が減り、核が死ぬと他の核につながらない菌糸は衰退します。\nすべての核が死ぬと失敗です。",
		"guide_survival_failure_hint": "修復用の栄養を残し、核同士をつなぎましょう。"
	},
	"es": {
		"menu_guide": "Guía de juego", "guide_title": "Guía de cultivo", "guide_prev": "Anterior", "guide_next": "Siguiente", "guide_back": "Volver", "guide_page_fmt": "%d / %d", "guide_keys_hint": "← → cambia de página · Home / End salta · Esc vuelve a pausa",
		"guide_germination_title": "De espora a hifa",
		"guide_germination_body": "Haz clic en el núcleo de espora y elige Extender.\nLuego haz clic cerca: la hifa principal crecerá lentamente hasta allí.\nAl acercarse a recursos, las hifas absorbentes salen solas.",
		"guide_germination_hint": "Crece primero hacia los nutrientes orgánicos naranjas.",
		"guide_resources_dna_title": "Nutrientes y ADN",
		"guide_resources_dna_body": "El agua es ilimitada en el laboratorio; crecer usa sobre todo nutrientes orgánicos, y las estructuras especiales también necesitan minerales.\nEl núcleo gasta nutrientes lentamente para registrar ADN.\nMantén Shift o Ctrl para poner 5 o 10 ADN en cola.",
		"guide_resources_dna_hint": "Usa el ADN para comprar evoluciones.",
		"guide_evolution_title": "Elige una evolución",
		"guide_evolution_body": "Pulsa E para abrir Mejoras.\nGasta ADN en dietas, habilidades y unidades especiales; mejorar nodos usa nutrientes orgánicos.\nCada dieta extra cuesta mucho más, así que desarrolla primero una principal.",
		"guide_evolution_hint": "Elige una dieta principal y mejora sus habilidades.",
		"guide_barracks_command_title": "Cuartel y órdenes",
		"guide_barracks_command_body": "Crea un núcleo de cuartel en la punta de una hifa madura para producir esporas de expedición.\nArrastra un cuadro con el botón izquierdo para seleccionar; haz clic derecho en un lugar o enemigo para dar una orden.\nLa ruta verde muestra la orden y los recolectores llevan recursos a casa solos.",
		"guide_barracks_command_hint": "Consigue suministros antes de enviar combatientes.",
		"guide_exploration_goals_title": "Exploración y objetivos",
		"guide_exploration_goals_body": "Las zonas bajo la niebla oscura aparecen cuando tus unidades las exploran.\nEl minimapa guarda las zonas de recursos y amenazas descubiertas.\nPulsa G para ver objetivos a largo plazo, seguirlos y cobrar recompensas.",
		"guide_exploration_goals_hint": "Explora el borde desconocido del minimapa.",
		"guide_survival_failure_title": "Protege tu colonia",
		"guide_survival_failure_body": "Pon el cursor sobre un núcleo para ver su porcentaje de biomasa.\nLas toxinas y ataques reducen la biomasa; si un núcleo muere, las hifas sin otra conexión decaen.\nLa partida termina si mueren todos los núcleos.",
		"guide_survival_failure_hint": "Guarda nutrientes para reparar y conecta tus núcleos."
	},
	"de": {
		"menu_guide": "Spielanleitung", "guide_title": "Leitfaden zur Pilzkultur", "guide_prev": "Zurück", "guide_next": "Weiter", "guide_back": "Pausemenü", "guide_page_fmt": "%d / %d", "guide_keys_hint": "← → blättern · Home / End springen · Esc zurück zur Pause",
		"guide_germination_title": "Von der Spore zur Hyphe",
		"guide_germination_body": "Klicke den Sporenkern an und wähle Verlängern.\nKlicke dann in die Nähe; die Haupthyphe wächst langsam dorthin.\nNahe Ressourcen wachsen feine Aufnahmehyphen automatisch.",
		"guide_germination_hint": "Wachse zuerst zu orangefarbener Organik.",
		"guide_resources_dna_title": "Nährstoffe und DNA",
		"guide_resources_dna_body": "Wasser ist im Labor unbegrenzt; Wachstum braucht vor allem organische Nährstoffe, besondere Strukturen auch Mineralionen.\nDer Sporenkern verbraucht langsam Nährstoffe, um DNA aufzuzeichnen.\nHalte Shift oder Strg, um 5 oder 10 DNA einzureihen.",
		"guide_resources_dna_hint": "Kaufe mit DNA neue Evolutionen.",
		"guide_evolution_title": "Wähle einen Evolutionsweg",
		"guide_evolution_body": "Drücke E, um Upgrades zu öffnen.\nDNA schaltet Nahrung, Fähigkeiten und Spezialeinheiten frei; Kern-Upgrades kosten Organik.\nWeitere Nahrungsarten werden viel teurer, also entwickle zuerst eine Hauptnahrung.",
		"guide_evolution_hint": "Wähle eine Hauptnahrung und verbessere ihre Fähigkeiten.",
		"guide_barracks_command_title": "Kaserne und Befehle",
		"guide_barracks_command_body": "Baue am Ende einer reifen Hyphe einen Kasernenkern, der Expeditionssporen erzeugt.\nZiehe mit links ein Quadrat zur Auswahl und rechtsklicke auf einen Ort oder Feind.\nDie grüne Route zeigt den Befehl; Sammler bringen Ressourcen selbst zurück.",
		"guide_barracks_command_hint": "Sammle erst Vorräte, dann sende Kämpfer.",
		"guide_exploration_goals_title": "Erkundung und Ziele",
		"guide_exploration_goals_body": "Gebiete im dunklen Nebel werden erst nach der Erkundung sichtbar.\nDie Minikarte merkt sich entdeckte Ressourcen und Gefahren.\nDrücke G für Langzeitziele, verfolge den Fortschritt und hole Belohnungen ab.",
		"guide_exploration_goals_hint": "Erkunde den unbekannten Rand der Minikarte.",
		"guide_survival_failure_title": "Schütze deine Kolonie",
		"guide_survival_failure_body": "Fahre über einen Kern, um seinen Biomasseanteil zu sehen.\nGifte und Angriffe senken ihn; stirbt ein Kern, zerfallen nicht neu verbundene Hyphen.\nWenn alle Kerne tot sind, ist der Durchlauf verloren.",
		"guide_survival_failure_hint": "Spare Nährstoffe für Reparaturen und verbinde Kerne."
	},
	"ru": {
		"menu_guide": "Как играть", "guide_title": "Справочник по колонии", "guide_prev": "Назад", "guide_next": "Вперёд", "guide_back": "Меню паузы", "guide_page_fmt": "%d / %d", "guide_keys_hint": "← → листать · Home / End перейти · Esc назад к паузе",
		"guide_germination_title": "От споры к гифе",
		"guide_germination_body": "Нажмите на споровое ядро и выберите «Удлинить».\nЗатем нажмите рядом — главная гифа медленно вырастет туда.\nВозле ресурсов тонкие всасывающие гифы растут сами.",
		"guide_germination_hint": "Сначала растите к оранжевой органике.",
		"guide_resources_dna_title": "Питание и ДНК",
		"guide_resources_dna_body": "В лаборатории вода бесконечна; рост тратит в основном органику, а особым структурам нужны и минералы.\nСпоровое ядро медленно тратит питание и записывает ДНК.\nУдерживайте Shift или Ctrl, чтобы поставить в очередь 5 или 10 ДНК.",
		"guide_resources_dna_hint": "Тратьте ДНК на эволюцию.",
		"guide_evolution_title": "Выберите путь эволюции",
		"guide_evolution_body": "Нажмите E, чтобы открыть улучшения.\nЗа ДНК открываются рационы, способности и особые бойцы; усиление узлов тратит органику.\nНовые рационы быстро дорожают, поэтому сначала развивайте один основной.",
		"guide_evolution_hint": "Выберите основной рацион и развивайте его способности.",
		"guide_barracks_command_title": "Казарма и команды",
		"guide_barracks_command_body": "Постройте ядро казармы на конце зрелой гифы, чтобы создавать походные споры.\nЗажмите левую кнопку и растяните квадрат выбора; правой кнопкой укажите место или врага.\nЗелёная линия показывает приказ, а сборщики сами несут ресурсы домой.",
		"guide_barracks_command_hint": "Сначала соберите припасы, затем отправляйте бойцов.",
		"guide_exploration_goals_title": "Разведка и цели",
		"guide_exploration_goals_body": "Области под тёмным туманом появляются после разведки вашими отрядами.\nМини-карта запоминает найденные ресурсы и угрозы.\nНажмите G, чтобы открыть долгосрочные цели, следить за ними и получать награды.",
		"guide_exploration_goals_hint": "Исследуйте неизвестный край мини-карты.",
		"guide_survival_failure_title": "Защитите колонию",
		"guide_survival_failure_body": "Наведите курсор на ядро, чтобы увидеть процент биомассы.\nЯды и атаки снижают её; после гибели ядра гифы без новой связи распадаются.\nЕсли погибнут все ядра, партия проиграна.",
		"guide_survival_failure_hint": "Берегите питание для ремонта и связывайте ядра."
	}
}


static func normalize_locale(locale: String) -> String:
	var normalized := locale.strip_edges().replace("-", "_")
	if LOCALES.has(normalized):
		return normalized
	var lowered := normalized.to_lower()
	if lowered.begins_with("zh_tw") or lowered.begins_with("zh_hk") or lowered.begins_with("zh_hant"):
		return "zh_TW"
	if lowered.begins_with("zh"):
		return "zh_CN"
	for locale_id in ["en", "ja", "es", "de", "ru"]:
		if lowered.begins_with(locale_id):
			return locale_id
	return "zh_CN"


static func text(key: String, locale: String) -> String:
	var normalized := normalize_locale(locale)
	var localized: Dictionary = TEXTS.get(normalized, {})
	if localized.has(key):
		return String(localized[key])
	var fallback: Dictionary = TEXTS["en"]
	return String(fallback.get(key, key))


static func page(page_id: String, locale: String) -> Dictionary:
	var stable_id := page_id if PAGE_IDS.has(page_id) else PAGE_IDS[0]
	return {
		"id": stable_id,
		"title": text("guide_%s_title" % stable_id, locale),
		"body": text("guide_%s_body" % stable_id, locale),
		"hint": text("guide_%s_hint" % stable_id, locale)
	}
