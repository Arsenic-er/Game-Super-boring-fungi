extends RefCounted


const LOCALES: Array[String] = ["zh_CN", "zh_TW", "en", "ja", "es", "de", "ru"]
const TASK_IDS: Array[String] = [
	"wake_spore", "first_germination", "absorption_network", "record_dna", "expand_colony",
	"diet_strategy", "organize_expedition", "discover_rival", "clear_rival"
]

const CHROME := {
	"zh_CN": {
		"complete": "第一章完成", "free_culture": "自由培养中 · 下一章节尚未开放",
		"task_heading_fmt": "章节任务 %d/%d · %s", "unlimited": "按自己的节奏完成，不限时", "show_hint": "点击查看操作提示",
		"complete_toast": "第一章目标完成：培养皿已被你的菌落掌控", "new_task_fmt": "新任务：%s"
	},
	"zh_TW": {
		"complete": "第一章完成", "free_culture": "自由培養中 · 下一章節尚未開放",
		"task_heading_fmt": "章節任務 %d/%d · %s", "unlimited": "依自己的節奏完成，沒有時限", "show_hint": "點擊查看操作提示",
		"complete_toast": "第一章目標完成：培養皿已由你的菌落掌控", "new_task_fmt": "新任務：%s"
	},
	"en": {
		"complete": "Chapter 1 complete", "free_culture": "Free culture · Next chapter not yet available",
		"task_heading_fmt": "Chapter task %d/%d · %s", "unlimited": "Complete at your own pace · No time limit", "show_hint": "Click for an action hint",
		"complete_toast": "Chapter 1 complete: your colony controls the dish", "new_task_fmt": "New task: %s"
	},
	"ja": {
		"complete": "第1章クリア", "free_culture": "自由培養中 · 次章は未開放",
		"task_heading_fmt": "章タスク %d/%d · %s", "unlimited": "自分のペースで進行 · 時間制限なし", "show_hint": "クリックで操作ヒント",
		"complete_toast": "第1章クリア：培養皿をコロニーが支配しました", "new_task_fmt": "新しいタスク：%s"
	},
	"es": {
		"complete": "Capítulo 1 completado", "free_culture": "Cultivo libre · Próximo capítulo aún no disponible",
		"task_heading_fmt": "Tarea %d/%d · %s", "unlimited": "Completa a tu ritmo · Sin límite de tiempo", "show_hint": "Haz clic para ver una pista",
		"complete_toast": "Capítulo 1 completado: tu colonia controla la placa", "new_task_fmt": "Nueva tarea: %s"
	},
	"de": {
		"complete": "Kapitel 1 abgeschlossen", "free_culture": "Freie Kultur · Nächstes Kapitel noch nicht verfügbar",
		"task_heading_fmt": "Kapitelziel %d/%d · %s", "unlimited": "Im eigenen Tempo · Kein Zeitlimit", "show_hint": "Klicken für einen Hinweis",
		"complete_toast": "Kapitel 1 abgeschlossen: Deine Kolonie beherrscht die Schale", "new_task_fmt": "Neue Aufgabe: %s"
	},
	"ru": {
		"complete": "Глава 1 завершена", "free_culture": "Свободная культура · Следующая глава пока недоступна",
		"task_heading_fmt": "Задача %d/%d · %s", "unlimited": "Играйте в своём темпе · Без ограничения времени", "show_hint": "Нажмите, чтобы увидеть подсказку",
		"complete_toast": "Глава 1 завершена: колония контролирует чашку", "new_task_fmt": "Новая задача: %s"
	}
}

const TASK_TEXT := {
	"zh_CN": [
		["唤醒孢子", "点击中央孢子核心", "左键点击发光的孢子核心，打开它的操作菜单。"],
		["初次萌发", "延伸第一段主菌丝", "在核心菜单选择“延伸菌丝”，再点击附近空地。"],
		["建立吸收网络", "累计吸收 1.000 有机营养", "让主菌丝靠近橙色营养点，细吸收丝会自动长出。"],
		["记录遗传变化", "由核心完成 1 次 DNA 记录", "点击孢子核心并选择“产生 DNA”；生产会持续一段时间。"],
		["扩建菌落", "拥有 2 个存活核心", "延伸足够长的菌丝后，在末端长出新的孢子核心。"],
		["形成营养策略", "在升级界面解锁 1 条主食性", "打开左上角“升级 [E]”，在食性页选择你的第一条路线。"],
		["组织远征", "建造兵营并生产 1 个体外孢子", "从菌丝末端建立兵营核心，然后在核心菜单排队生产游猎孢子。"],
		["发现竞争菌落", "探索并发现竞争性真菌", "派侦察孢子向黑幕外移动；竞争菌只有进入视野后才会显示。"],
		["清除竞争菌落", "使竞争性真菌核心失活", "框选部队后右键敌菌核心。穿壁孢子效率最高，游猎孢子也能缓慢啃噬。"]
	],
	"zh_TW": [
		["喚醒孢子", "點擊中央孢子核心", "左鍵點擊發光的孢子核心，開啟它的操作選單。"],
		["初次萌發", "延伸第一段主菌絲", "在核心選單選擇「延伸菌絲」，再點擊附近空地。"],
		["建立吸收網路", "累計吸收 1.000 有機營養", "讓主菌絲靠近橙色營養點，細吸收絲會自動長出。"],
		["記錄遺傳變化", "由核心完成 1 次 DNA 記錄", "點擊孢子核心並選擇「產生 DNA」；生產會持續一段時間。"],
		["擴建菌落", "擁有 2 個存活核心", "延伸足夠長的菌絲後，在末端長出新的孢子核心。"],
		["形成營養策略", "在升級介面解鎖 1 條主食性", "開啟左上角「升級 [E]」，在食性頁選擇第一條路線。"],
		["組織遠征", "建造兵營並生產 1 個體外孢子", "從菌絲末端建立兵營核心，再於核心選單排隊生產遊獵孢子。"],
		["發現競爭菌落", "探索並發現競爭性真菌", "派偵察孢子朝黑幕外移動；競爭菌進入視野後才會顯示。"],
		["清除競爭菌落", "使競爭性真菌核心失活", "框選部隊後右鍵敵菌核心。穿壁孢子效率最高，遊獵孢子也能緩慢啃噬。"]
	],
	"en": [
		["Wake the spore", "Click the central spore core", "Left-click the glowing spore core to open its action menu."],
		["First germination", "Extend the first main hypha", "Choose Extend Hypha in the core menu, then click nearby open ground."],
		["Build a feeder network", "Absorb 1.000 organic nutrient", "Grow a main hypha near orange nutrient points; fine feeders emerge automatically."],
		["Record genetic change", "Complete 1 DNA record at a core", "Click a spore core and choose Produce DNA. Recording takes some time."],
		["Expand the colony", "Maintain 2 living cores", "Extend a long enough hypha, then form a new spore core at its tip."],
		["Adopt a feeding strategy", "Unlock 1 primary diet", "Open Upgrade [E] at the upper left and choose your first diet route."],
		["Organize an expedition", "Build a barracks and produce 1 mobile spore", "Form a barracks core at a hypha tip, then queue a forager spore there."],
		["Discover a rival colony", "Explore and reveal a rival fungus", "Send a scout beyond the fog. Rivals appear only after entering vision."],
		["Eliminate the rival", "Deactivate a rival fungal core", "Select units and right-click the rival core. Piercers excel; foragers can slowly damage it."]
	],
	"ja": [
		["胞子を目覚めさせる", "中央の胞子核をクリック", "光る胞子核を左クリックして、操作メニューを開きます。"],
		["最初の発芽", "最初の主菌糸を伸ばす", "コアメニューで「菌糸を伸ばす」を選び、近くの空地をクリックします。"],
		["吸収網を作る", "有機栄養を 1.000 吸収", "主菌糸を橙色の栄養点へ近づけると、細い吸収菌糸が自動で伸びます。"],
		["遺伝変化を記録", "コアで DNA を1回記録", "胞子核をクリックして「DNA 生成」を選びます。記録には時間がかかります。"],
		["コロニーを拡張", "生存コアを2個維持", "菌糸を十分に伸ばし、先端に新しい胞子核を作ります。"],
		["栄養戦略を決める", "主食性を1つ解放", "左上の「進化 [E]」を開き、食性ページで最初の経路を選びます。"],
		["遠征隊を編成", "兵舎を建て体外胞子を1体生産", "菌糸先端に兵舎コアを作り、採集胞子を生産キューへ入れます。"],
		["競争コロニーを発見", "探索して競争菌を発見", "偵察胞子を暗闇の外へ送りましょう。競争菌は視界に入るまで見えません。"],
		["競争コロニーを排除", "競争菌のコアを失活", "部隊を選び、敵コアを右クリックします。穿壁胞子が最適ですが採集胞子も攻撃できます。"]
	],
	"es": [
		["Despierta la espora", "Haz clic en el núcleo central", "Haz clic izquierdo en el núcleo brillante para abrir su menú de acciones."],
		["Primera germinación", "Extiende la primera hifa principal", "Elige Extender hifa en el menú del núcleo y pulsa sobre terreno libre cercano."],
		["Crea una red de absorción", "Absorbe 1.000 de nutriente orgánico", "Acerca una hifa a los puntos naranjas; las hifas finas crecerán solas."],
		["Registra el cambio genético", "Completa 1 registro de ADN", "Haz clic en un núcleo y elige Producir ADN. El registro tarda un tiempo."],
		["Expande la colonia", "Mantén 2 núcleos vivos", "Extiende una hifa lo suficiente y forma un núcleo nuevo en su extremo."],
		["Adopta una dieta", "Desbloquea 1 dieta principal", "Abre Mejoras [E] arriba a la izquierda y elige tu primera dieta."],
		["Organiza una expedición", "Construye un cuartel y produce 1 espora", "Crea un núcleo de cuartel en una punta y pon una espora recolectora en cola."],
		["Descubre una colonia rival", "Explora y revela un hongo rival", "Envía una espora exploradora más allá de la niebla. El rival aparece al verlo."],
		["Elimina al rival", "Desactiva un núcleo fúngico rival", "Selecciona unidades y haz clic derecho en el núcleo rival. Las perforadoras son las mejores."]
	],
	"de": [
		["Spore wecken", "Zentralen Sporenkern anklicken", "Linksklick auf den leuchtenden Sporenkern öffnet sein Aktionsmenü."],
		["Erste Keimung", "Erste Haupthyphe verlängern", "Im Kernmenü Hyphe verlängern wählen und auf freien Boden in der Nähe klicken."],
		["Nährnetz aufbauen", "1.000 organische Nährstoffe aufnehmen", "Haupthyphen an orange Nährpunkte führen; feine Nährhyphen wachsen automatisch."],
		["Genveränderung erfassen", "1 DNA-Aufzeichnung abschließen", "Sporenkern anklicken und DNA erzeugen wählen. Die Aufzeichnung benötigt Zeit."],
		["Kolonie erweitern", "2 lebende Kerne erhalten", "Eine Hyphe weit genug verlängern und an ihrer Spitze einen neuen Sporenkern bilden."],
		["Ernährung festlegen", "1 primäre Ernährung freischalten", "Oben links Upgrades [E] öffnen und die erste Ernährungsroute wählen."],
		["Expedition organisieren", "Kaserne bauen und 1 Außenspore erzeugen", "An einer Hyphenspitze einen Kasernenkern bilden und eine Sammlerspore einreihen."],
		["Rivalen entdecken", "Einen konkurrierenden Pilz aufdecken", "Eine Spähspore in den Nebel senden. Rivalen erscheinen erst in Sichtweite."],
		["Rivalen beseitigen", "Einen gegnerischen Pilzkern deaktivieren", "Einheiten wählen und den gegnerischen Kern rechtsklicken. Bohrsporen sind am wirksamsten."]
	],
	"ru": [
		["Пробудите спору", "Нажмите на центральное ядро", "Щёлкните ЛКМ по светящемуся ядру споры, чтобы открыть меню действий."],
		["Первое прорастание", "Вырастите первую главную гифу", "Выберите «Удлинить гифу» в меню ядра и нажмите на свободное место рядом."],
		["Создайте сеть питания", "Поглотите 1.000 органики", "Подведите главную гифу к оранжевым точкам; тонкие гифы вырастут сами."],
		["Запишите генетическое изменение", "Завершите 1 запись ДНК", "Нажмите на ядро и выберите производство ДНК. Запись требует времени."],
		["Расширьте колонию", "Поддерживайте 2 живых ядра", "Удлините гифу и сформируйте новое споровое ядро на её конце."],
		["Выберите питание", "Откройте 1 основной тип питания", "Откройте «Улучшения [E]» слева вверху и выберите первый тип питания."],
		["Организуйте экспедицию", "Постройте казарму и создайте 1 спору", "Создайте казарменное ядро на конце гифы и закажите спору-сборщика."],
		["Найдите колонию соперника", "Исследуйте и обнаружьте чужой гриб", "Отправьте разведчика за туман. Соперник появится только в поле зрения."],
		["Уничтожьте соперника", "Деактивируйте вражеское ядро", "Выберите бойцов и нажмите ПКМ на ядро врага. Лучше всего подходят пробивающие споры."]
	]
}


static func normalize_locale(locale_id: String) -> String:
	var value := locale_id.strip_edges().replace("-", "_").to_lower()
	if value.begins_with("zh_hant") or value.begins_with("zh_tw") or value.begins_with("zh_hk") or value.begins_with("zh_mo"):
		return "zh_TW"
	if value.begins_with("zh"):
		return "zh_CN"
	for candidate in ["en", "ja", "es", "de", "ru"]:
		if value == candidate or value.begins_with(candidate + "_"):
			return candidate
	return "en"


static func text(key: String, locale_id: String) -> String:
	var table: Dictionary = CHROME.get(normalize_locale(locale_id), CHROME["en"])
	return String(table.get(key, (CHROME["en"] as Dictionary).get(key, key)))


static func tasks(locale_id: String) -> Array:
	var locale := normalize_locale(locale_id)
	var copy: Array = TASK_TEXT.get(locale, TASK_TEXT["en"])
	var result: Array = []
	for index in range(TASK_IDS.size()):
		var row: Array = copy[index]
		result.append({"id": TASK_IDS[index], "title": String(row[0]), "detail": String(row[1]), "hint": String(row[2])})
	return result
