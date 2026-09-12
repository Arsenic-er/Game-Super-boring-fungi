extends RefCounted


const LOCALES: Array[String] = ["zh_CN", "zh_TW", "en", "ja", "es", "de", "ru"]
const TASK_IDS: Array[String] = [
	"wake_spore", "first_germination", "absorption_network", "record_dna", "expand_colony",
	"diet_strategy", "organize_expedition", "secure_supply", "expand_network", "discover_rival", "clear_rival"
]

const CHROME := {
	"zh_CN": {
		"complete": "第一章完成", "free_culture": "自由培养中 · 下一章节尚未开放",
		"task_heading_fmt": "章节任务 %d/%d · %s", "unlimited": "按自己的节奏完成，不限时", "show_hint": "点击查看操作提示",
		"complete_toast": "第一章完成：补给与扩张达标，首个竞争菌落已清除", "new_task_fmt": "新任务：%s",
		"supply_progress_fmt": "有机 %.0f/%.0f · 矿 %.0f/%.0f · 运 %.1f/%.1f",
		"expansion_progress_fmt": "核心 %d/%d · 菌丝 %.0f/%.0f μm",
		"review_report": "点击重看报告 · 培养仍可继续",
		"report_legacy_subtitle": "此档已按旧版目标通关；成果保留，新增经营条件不追溯。"
	},
	"zh_TW": {
		"complete": "第一章完成", "free_culture": "自由培養中 · 下一章節尚未開放",
		"task_heading_fmt": "章節任務 %d/%d · %s", "unlimited": "依自己的節奏完成，沒有時限", "show_hint": "點擊查看操作提示",
		"complete_toast": "第一章完成：補給與擴張達標，首個競爭菌落已清除", "new_task_fmt": "新任務：%s",
		"supply_progress_fmt": "有機 %.0f/%.0f · 礦 %.0f/%.0f · 運 %.1f/%.1f",
		"expansion_progress_fmt": "核心 %d/%d · 菌絲 %.0f/%.0f μm",
		"review_report": "點擊重看報告 · 培養仍可繼續",
		"report_legacy_subtitle": "此檔已依舊版目標通關；成果保留，新增經營條件不追溯。"
	},
	"en": {
		"complete": "Chapter 1 complete", "free_culture": "Free culture · Next chapter not yet available",
		"task_heading_fmt": "Chapter task %d/%d · %s", "unlimited": "Complete at your own pace · No time limit", "show_hint": "Click for an action hint",
		"complete_toast": "Chapter 1 complete: supply and expansion goals met, first rival cleared", "new_task_fmt": "New task: %s",
		"supply_progress_fmt": "Org %.0f/%.0f · Min %.0f/%.0f · Cargo %.1f/%.1f",
		"expansion_progress_fmt": "Cores %d/%d · Hyphae %.0f/%.0f μm",
		"review_report": "Click to review report · Keep cultivating",
		"report_legacy_subtitle": "Completed under earlier rules. Completion is retained; new economy goals do not apply retroactively."
	},
	"ja": {
		"complete": "第1章クリア", "free_culture": "自由培養中 · 次章は未開放",
		"task_heading_fmt": "章タスク %d/%d · %s", "unlimited": "自分のペースで進行 · 時間制限なし", "show_hint": "クリックで操作ヒント",
		"complete_toast": "第1章クリア：補給と拡張の目標を達成し、最初の競争菌を排除しました", "new_task_fmt": "新しいタスク：%s",
		"supply_progress_fmt": "有機 %.0f/%.0f · 鉱 %.0f/%.0f · 搬入 %.1f/%.1f",
		"expansion_progress_fmt": "コア %d/%d · 菌糸 %.0f/%.0f μm",
		"review_report": "クリックで結果を再表示 · 培養を続行可能",
		"report_legacy_subtitle": "旧版の目標でクリア済みです。成果は保持され、新しい経営条件は遡って適用されません。"
	},
	"es": {
		"complete": "Capítulo 1 completado", "free_culture": "Cultivo libre · Próximo capítulo aún no disponible",
		"task_heading_fmt": "Tarea %d/%d · %s", "unlimited": "Completa a tu ritmo · Sin límite de tiempo", "show_hint": "Haz clic para ver una pista",
		"complete_toast": "Capítulo 1 completado: suministro y expansión logrados, primer rival eliminado", "new_task_fmt": "Nueva tarea: %s",
		"supply_progress_fmt": "Org %.0f/%.0f · Min %.0f/%.0f · Carga %.1f/%.1f",
		"expansion_progress_fmt": "Núcleos %d/%d · Hifas %.0f/%.0f μm",
		"review_report": "Clic para revisar el informe · Sigue cultivando",
		"report_legacy_subtitle": "Completado con reglas anteriores. Se conserva el logro; las nuevas metas económicas no son retroactivas."
	},
	"de": {
		"complete": "Kapitel 1 abgeschlossen", "free_culture": "Freie Kultur · Nächstes Kapitel noch nicht verfügbar",
		"task_heading_fmt": "Kapitelziel %d/%d · %s", "unlimited": "Im eigenen Tempo · Kein Zeitlimit", "show_hint": "Klicken für einen Hinweis",
		"complete_toast": "Kapitel 1 abgeschlossen: Versorgung und Ausbau erreicht, erster Rivale beseitigt", "new_task_fmt": "Neue Aufgabe: %s",
		"supply_progress_fmt": "Org %.0f/%.0f · Min %.0f/%.0f · Fracht %.1f/%.1f",
		"expansion_progress_fmt": "Kerne %d/%d · Hyphen %.0f/%.0f μm",
		"review_report": "Bericht per Klick öffnen · Weiter kultivieren",
		"report_legacy_subtitle": "Nach früheren Regeln abgeschlossen. Der Erfolg bleibt; neue Wirtschaftsziele gelten nicht rückwirkend."
	},
	"ru": {
		"complete": "Глава 1 завершена", "free_culture": "Свободная культура · Следующая глава пока недоступна",
		"task_heading_fmt": "Задача %d/%d · %s", "unlimited": "Играйте в своём темпе · Без ограничения времени", "show_hint": "Нажмите, чтобы увидеть подсказку",
		"complete_toast": "Глава 1 завершена: цели снабжения и расширения достигнуты, первый соперник побеждён", "new_task_fmt": "Новая задача: %s",
		"supply_progress_fmt": "Орг %.0f/%.0f · Мин %.0f/%.0f · Груз %.1f/%.1f",
		"expansion_progress_fmt": "Ядра %d/%d · Гифы %.0f/%.0f μm",
		"review_report": "Нажмите для просмотра отчёта · Культура продолжается",
		"report_legacy_subtitle": "Завершено по прежним правилам. Успех сохранён; новые хозяйственные цели не применяются задним числом."
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
		["建立补给循环", "菌丝吸收与孢子返巢补给达标", "菌丝吸收有机营养和矿物，采集孢子把有机营养运回母体；当前值与目标值见任务面板。"],
		["扩张菌丝网络", "存活核心与成熟相连菌丝达标", "增加存活核心（兵营也计入），延长并保护菌丝；只计成熟且未断联的长度，目标值见任务面板。"],
		["发现竞争菌落", "探索并发现竞争性真菌", "派侦察孢子向黑幕外移动；竞争菌只有进入视野后才会显示。"],
		["清除竞争菌落", "补给、扩张达标并击败首个竞争菌落", "框选部队后右键敌菌核心；穿壁孢子更高效。结算时还需保持补给与网络目标达标。"]
	],
	"zh_TW": [
		["喚醒孢子", "點擊中央孢子核心", "左鍵點擊發光的孢子核心，開啟它的操作選單。"],
		["初次萌發", "延伸第一段主菌絲", "在核心選單選擇「延伸菌絲」，再點擊附近空地。"],
		["建立吸收網路", "累計吸收 1.000 有機營養", "讓主菌絲靠近橙色營養點，細吸收絲會自動長出。"],
		["記錄遺傳變化", "由核心完成 1 次 DNA 記錄", "點擊孢子核心並選擇「產生 DNA」；生產會持續一段時間。"],
		["擴建菌落", "擁有 2 個存活核心", "延伸足夠長的菌絲後，在末端長出新的孢子核心。"],
		["形成營養策略", "在升級介面解鎖 1 條主食性", "開啟左上角「升級 [E]」，在食性頁選擇第一條路線。"],
		["組織遠征", "建造兵營並生產 1 個體外孢子", "從菌絲末端建立兵營核心，再於核心選單排隊生產遊獵孢子。"],
		["建立補給循環", "菌絲吸收與孢子返巢補給達標", "菌絲吸收有機營養與礦物，採集孢子把有機營養運回母體；目前值與目標值見任務面板。"],
		["擴張菌絲網路", "存活核心與成熟相連菌絲達標", "增加存活核心（兵營也計入），延長並保護菌絲；只計成熟且未斷聯的長度，目標值見任務面板。"],
		["發現競爭菌落", "探索並發現競爭性真菌", "派偵察孢子朝黑幕外移動；競爭菌進入視野後才會顯示。"],
		["清除競爭菌落", "補給、擴張達標並擊敗首個競爭菌落", "框選部隊後右鍵敵菌核心；穿壁孢子更有效率。結算時仍須保持補給與網路目標達標。"]
	],
	"en": [
		["Wake the spore", "Click the central spore core", "Left-click the glowing spore core to open its action menu."],
		["First germination", "Extend the first main hypha", "Choose Extend Hypha in the core menu, then click nearby open ground."],
		["Build a feeder network", "Absorb 1.000 organic nutrient", "Grow a main hypha near orange nutrient points; fine feeders emerge automatically."],
		["Record genetic change", "Complete 1 DNA record at a core", "Click a spore core and choose Produce DNA. Recording takes some time."],
		["Expand the colony", "Maintain 2 living cores", "Extend a long enough hypha, then form a new spore core at its tip."],
		["Adopt a feeding strategy", "Unlock 1 primary diet", "Open Upgrade [E] at the upper left and choose your first diet route."],
		["Organize an expedition", "Build a barracks and produce 1 mobile spore", "Form a barracks core at a hypha tip, then queue a forager spore there."],
		["Establish supply", "Meet absorption and returned-cargo goals", "Absorb organics and minerals through hyphae; gatherers must carry organics home. See the task panel for current and target amounts."],
		["Expand the network", "Meet living-core and connected-hypha goals", "Add living cores, including barracks, and protect growing hyphae. Only mature, connected length counts; targets are shown in the task panel."],
		["Discover a rival colony", "Explore and reveal a rival fungus", "Send a scout beyond the fog. Rivals appear only after entering vision."],
		["Eliminate the rival", "Meet supply and expansion goals; defeat the first rival", "Select units and right-click the rival core; piercers excel. Supply and network goals must still be met when the chapter completes."]
	],
	"ja": [
		["胞子を目覚めさせる", "中央の胞子核をクリック", "光る胞子核を左クリックして、操作メニューを開きます。"],
		["最初の発芽", "最初の主菌糸を伸ばす", "コアメニューで「菌糸を伸ばす」を選び、近くの空地をクリックします。"],
		["吸収網を作る", "有機栄養を 1.000 吸収", "主菌糸を橙色の栄養点へ近づけると、細い吸収菌糸が自動で伸びます。"],
		["遺伝変化を記録", "コアで DNA を1回記録", "胞子核をクリックして「DNA 生成」を選びます。記録には時間がかかります。"],
		["コロニーを拡張", "生存コアを2個維持", "菌糸を十分に伸ばし、先端に新しい胞子核を作ります。"],
		["栄養戦略を決める", "主食性を1つ解放", "左上の「進化 [E]」を開き、食性ページで最初の経路を選びます。"],
		["遠征隊を編成", "兵舎を建て体外胞子を1体生産", "菌糸先端に兵舎コアを作り、採集胞子を生産キューへ入れます。"],
		["補給体制を築く", "吸収量と持ち帰った栄養の目標を達成", "菌糸で有機栄養とミネラルを吸収し、採集胞子で有機栄養を持ち帰ります。現在値と目標値はタスク欄に表示されます。"],
		["菌糸網を広げる", "生存コア数と成熟した接続菌糸の目標を達成", "兵舎を含む生存コアを増やし、菌糸を伸ばして守りましょう。成熟し接続が保たれた長さのみ計上。目標値はタスク欄で確認できます。"],
		["競争コロニーを発見", "探索して競争菌を発見", "偵察胞子を暗闇の外へ送りましょう。競争菌は視界に入るまで見えません。"],
		["競争コロニーを排除", "補給・拡張を達成し最初の競争菌を倒す", "部隊を選び敵コアを右クリック。穿壁胞子が得意です。章の完了時にも補給と菌糸網の目標達成が必要です。"]
	],
	"es": [
		["Despierta la espora", "Haz clic en el núcleo central", "Haz clic izquierdo en el núcleo brillante para abrir su menú de acciones."],
		["Primera germinación", "Extiende la primera hifa principal", "Elige Extender hifa en el menú del núcleo y pulsa sobre terreno libre cercano."],
		["Crea una red de absorción", "Absorbe 1.000 de nutriente orgánico", "Acerca una hifa a los puntos naranjas; las hifas finas crecerán solas."],
		["Registra el cambio genético", "Completa 1 registro de ADN", "Haz clic en un núcleo y elige Producir ADN. El registro tarda un tiempo."],
		["Expande la colonia", "Mantén 2 núcleos vivos", "Extiende una hifa lo suficiente y forma un núcleo nuevo en su extremo."],
		["Adopta una dieta", "Desbloquea 1 dieta principal", "Abre Mejoras [E] arriba a la izquierda y elige tu primera dieta."],
		["Organiza una expedición", "Construye un cuartel y produce 1 espora", "Crea un núcleo de cuartel en una punta y pon una espora recolectora en cola."],
		["Asegura el suministro", "Cumple las metas de absorción y entrega", "Absorbe materia orgánica y minerales con hifas y lleva materia orgánica a casa con recolectoras. El panel indica los valores actuales y las metas."],
		["Amplía la red", "Alcanza las metas de núcleos e hifas conectadas", "Añade núcleos vivos, incluidos cuarteles, y protege las hifas. Solo cuenta la longitud madura y conectada; consulta las metas en el panel."],
		["Descubre una colonia rival", "Explora y revela un hongo rival", "Envía una espora exploradora más allá de la niebla. El rival aparece al verlo."],
		["Elimina al rival", "Cumple suministro y expansión; derrota al primer rival", "Selecciona unidades y haz clic derecho en el núcleo rival; las perforadoras destacan. Las metas de suministro y red deben seguir cumplidas al terminar."]
	],
	"de": [
		["Spore wecken", "Zentralen Sporenkern anklicken", "Linksklick auf den leuchtenden Sporenkern öffnet sein Aktionsmenü."],
		["Erste Keimung", "Erste Haupthyphe verlängern", "Im Kernmenü Hyphe verlängern wählen und auf freien Boden in der Nähe klicken."],
		["Nährnetz aufbauen", "1.000 organische Nährstoffe aufnehmen", "Haupthyphen an orange Nährpunkte führen; feine Nährhyphen wachsen automatisch."],
		["Genveränderung erfassen", "1 DNA-Aufzeichnung abschließen", "Sporenkern anklicken und DNA erzeugen wählen. Die Aufzeichnung benötigt Zeit."],
		["Kolonie erweitern", "2 lebende Kerne erhalten", "Eine Hyphe weit genug verlängern und an ihrer Spitze einen neuen Sporenkern bilden."],
		["Ernährung festlegen", "1 primäre Ernährung freischalten", "Oben links Upgrades [E] öffnen und die erste Ernährungsroute wählen."],
		["Expedition organisieren", "Kaserne bauen und 1 Außenspore erzeugen", "An einer Hyphenspitze einen Kasernenkern bilden und eine Sammlerspore einreihen."],
		["Versorgung aufbauen", "Aufnahme- und Frachtziele erreichen", "Nimm Organik und Mineralien durch Hyphen auf und lasse Sammler Organik heimbringen. Aktuelle Werte und Zielmengen stehen im Aufgabenfeld."],
		["Netz ausbauen", "Ziele für lebende Kerne und verbundene Hyphen erreichen", "Baue lebende Kerne einschließlich Kasernen und schütze die Hyphen. Nur ausgereifte, verbundene Länge zählt; Zielwerte stehen im Aufgabenfeld."],
		["Rivalen entdecken", "Einen konkurrierenden Pilz aufdecken", "Eine Spähspore in den Nebel senden. Rivalen erscheinen erst in Sichtweite."],
		["Rivalen beseitigen", "Versorgung und Ausbau schaffen; ersten Rivalen besiegen", "Einheiten wählen und den Feindkern rechtsklicken; Bohrsporen sind besonders wirksam. Versorgung und Netz müssen beim Abschluss weiterhin die Ziele erfüllen."]
	],
	"ru": [
		["Пробудите спору", "Нажмите на центральное ядро", "Щёлкните ЛКМ по светящемуся ядру споры, чтобы открыть меню действий."],
		["Первое прорастание", "Вырастите первую главную гифу", "Выберите «Удлинить гифу» в меню ядра и нажмите на свободное место рядом."],
		["Создайте сеть питания", "Поглотите 1.000 органики", "Подведите главную гифу к оранжевым точкам; тонкие гифы вырастут сами."],
		["Запишите генетическое изменение", "Завершите 1 запись ДНК", "Нажмите на ядро и выберите производство ДНК. Запись требует времени."],
		["Расширьте колонию", "Поддерживайте 2 живых ядра", "Удлините гифу и сформируйте новое споровое ядро на её конце."],
		["Выберите питание", "Откройте 1 основной тип питания", "Откройте «Улучшения [E]» слева вверху и выберите первый тип питания."],
		["Организуйте экспедицию", "Постройте казарму и создайте 1 спору", "Создайте казарменное ядро на конце гифы и закажите спору-сборщика."],
		["Наладьте снабжение", "Достигните целей поглощения и доставки", "Поглощайте органику и минералы гифами; сборщики должны доставлять органику домой. Текущие и целевые значения указаны на панели задачи."],
		["Расширьте сеть", "Достигните целей по ядрам и связанным гифам", "Добавляйте живые ядра, включая казармы, и защищайте гифы. Учитывается только зрелая связанная длина; цели указаны на панели задачи."],
		["Найдите колонию соперника", "Исследуйте и обнаружьте чужой гриб", "Отправьте разведчика за туман. Соперник появится только в поле зрения."],
		["Уничтожьте соперника", "Выполните снабжение и расширение; победите первого врага", "Выберите бойцов и нажмите ПКМ на ядро врага; пробивающие споры особенно эффективны. При завершении цели снабжения и сети должны оставаться выполненными."]
	]
}


const REPORT_KEYS: Array[String] = [
	"report_title", "report_subtitle", "report_duration_fmt", "report_hypha_length_fmt",
	"report_living_cores_fmt", "report_organic_absorbed_fmt", "report_mineral_absorbed_fmt",
	"report_dna_produced_fmt", "report_units_fmt", "report_bacteria_digested_fmt",
	"report_exploration_fmt", "report_rivals_fmt", "report_unclaimed_notice",
	"report_continuation_notice", "report_next_locked"
]

const REPORT_VALUES := {
	"zh_CN": [
		"第一章完成 · 实验室培养", "你已完成补给与菌落扩张目标，并清除了首个竞争菌落。", "培养时长　%s", "主菌丝长度　%d μm", "存活核心　%d",
		"有机吸收　%.3f", "矿物吸收　%.3f", "DNA 记录　%d", "体外单位　建造 %d　损失 %d", "消化细菌　%d", "探索比例　%.2f%%",
		"竞争守卫 %d　菌落 %d　孢子雨 %d", "长期目标中的未领取奖励仍可继续完成；本结算不会结束当前存档。", "下一章未开放；继续培养时，孢子雨仍可能带来新的竞争菌落。", "下一章节尚未开放"
	],
	"zh_TW": [
		"第一章完成 · 實驗室培養", "你已完成補給與菌落擴張目標，並清除了首個競爭菌落。", "培養時長　%s", "主菌絲長度　%d μm", "存活核心　%d",
		"有機吸收　%.3f", "礦物吸收　%.3f", "DNA 記錄　%d", "體外單位　建造 %d　損失 %d", "消化細菌　%d", "探索比例　%.2f%%",
		"競爭守衛 %d　菌落 %d　孢子雨 %d", "長期目標中的未領取獎勵仍可繼續完成；本結算不會結束目前存檔。", "下一章未開放；繼續培養時，孢子雨仍可能帶來新的競爭菌落。", "下一章節尚未開放"
	],
	"en": [
		"Chapter 1 complete · Laboratory culture", "You met the supply and colony-expansion goals and cleared the first rival colony.", "Culture time  %s", "Main hypha length  %d μm", "Living cores  %d",
		"Organic absorbed  %.3f", "Minerals absorbed  %.3f", "DNA produced  %d", "Mobile units  built %d  lost %d", "Bacteria digested  %d", "Explored  %.2f%%",
		"Rivals: guards %d  colonies %d  sporefalls %d", "Unclaimed long-term rewards remain available; this report does not end the current save.", "Next chapter is locked; continued cultivation can face new rival sporefalls.", "Next chapter not yet available"
	],
	"ja": [
		"第1章クリア · 実験室培養", "補給とコロニー拡張の目標を達成し、最初の競争コロニーを排除しました。", "培養時間　%s", "主菌糸長　%d μm", "生存コア　%d",
		"有機栄養吸収　%.3f", "ミネラル吸収　%.3f", "DNA生産　%d", "体外ユニット　生産 %d　損失 %d", "細菌消化　%d", "探索率　%.2f%%",
		"競争菌：護衛 %d　コロニー %d　胞子雨 %d", "長期目標の未受取報酬は引き続き獲得できます。この結果画面で現在のセーブは終了しません。", "次章は未開放です。培養を続けると、胞子雨で新たな競争菌が現れることがあります。", "次章は未開放"
	],
	"es": [
		"Capítulo 1 completado · Cultivo de laboratorio", "Cumpliste las metas de suministro y expansión y eliminaste la primera colonia rival.", "Tiempo de cultivo  %s", "Longitud de la hifa principal  %d μm", "Núcleos vivos  %d",
		"Materia orgánica absorbida  %.3f", "Minerales absorbidos  %.3f", "ADN producido  %d", "Unidades móviles  creadas %d  perdidas %d", "Bacterias digeridas  %d", "Exploración  %.2f%%",
		"Rivales: guardias %d  colonias %d  lluvias de esporas %d", "Las recompensas pendientes de objetivos a largo plazo siguen disponibles; este informe no cierra la partida.", "El siguiente capítulo está cerrado; al continuar pueden llegar nuevas lluvias de esporas rivales.", "Siguiente capítulo aún no disponible"
	],
	"de": [
		"Kapitel 1 abgeschlossen · Laborkultur", "Du hast Versorgung und Kolonieausbau erreicht und die erste Rivalenkolonie beseitigt.", "Kulturzeit  %s", "Länge der Haupthyphe  %d μm", "Lebende Kerne  %d",
		"Organik aufgenommen  %.3f", "Mineralien aufgenommen  %.3f", "DNA erzeugt  %d", "Mobile Einheiten  gebaut %d  verloren %d", "Bakterien verdaut  %d", "Erkundet  %.2f%%",
		"Rivalen: Wächter %d  Kolonien %d  Sporenregen %d", "Nicht abgeholte Langzeitziel-Belohnungen bleiben verfügbar; dieser Bericht beendet den Spielstand nicht.", "Das nächste Kapitel ist gesperrt; beim Weiterkultivieren drohen neue rivalisierende Sporenregen.", "Nächstes Kapitel noch nicht verfügbar"
	],
	"ru": [
		"Глава 1 завершена · Лабораторная культура", "Вы достигли целей снабжения и расширения и победили первую колонию соперника.", "Время культивации  %s", "Длина главной гифы  %d μm", "Живые ядра  %d",
		"Поглощено органики  %.3f", "Поглощено минералов  %.3f", "Создано ДНК  %d", "Мобильные единицы: создано %d, потеряно %d", "Переварено бактерий  %d", "Исследовано  %.2f%%",
		"Соперники: стражи %d, колонии %d, споропады %d", "Неполученные награды долгосрочных целей остаются доступны; отчёт не завершает текущее сохранение.", "Следующая глава закрыта; при продолжении споропады могут принести новых соперников.", "Следующая глава недоступна"
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
	var locale := normalize_locale(locale_id)
	var report_index := REPORT_KEYS.find(key)
	if report_index >= 0:
		var row: Array = REPORT_VALUES.get(locale, REPORT_VALUES["en"])
		return String(row[report_index]) if report_index < row.size() else String((REPORT_VALUES["en"] as Array)[report_index])
	var table: Dictionary = CHROME.get(locale, CHROME["en"])
	return String(table.get(key, (CHROME["en"] as Dictionary).get(key, key)))


static func tasks(locale_id: String) -> Array:
	var locale := normalize_locale(locale_id)
	var copy: Array = TASK_TEXT.get(locale, TASK_TEXT["en"])
	var result: Array = []
	for index in range(TASK_IDS.size()):
		var row: Array = copy[index]
		result.append({"id": TASK_IDS[index], "title": String(row[0]), "detail": String(row[1]), "hint": String(row[2])})
	return result
