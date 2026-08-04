extends RefCounted


const LOCALES: Array[String] = ["zh_CN", "zh_TW", "en", "ja", "es", "de", "ru"]
const REASON_IDS: Array[String] = [
	"enemy_guard", "rival_core_counter", "rival_hypha_counter", "rival_infection",
	"ecology_toxin", "bacteria_toxin", "lytic_burst_counter", "low_biomass",
	"repair_transfer", "manual_return", "no_core", "environment_pressure", "unknown"
]

const KEYS: Array[String] = [
	"hud_help", "filter_all", "selection_fmt", "selection_stats_fmt",
	"action_defense", "action_harvest", "action_purge", "action_clear",
	"guard_name", "guard_state_patrol", "guard_state_chasing", "guard_state_attacking",
	"guard_state_returning", "guard_state_orphaned", "guard_state_unknown", "guard_hint",
	"origin_initial", "origin_sporefall_fmt", "core_header_fmt", "core_state_dormant",
	"core_state_foraging", "core_state_assault", "core_state_starved", "core_state_dead",
	"core_state_unknown", "core_status_fmt", "core_hint", "hypha_integrity_fmt",
	"hypha_connected", "hypha_disconnected", "hypha_status_origin_fmt", "hypha_hint",
	"hover_reason_fmt", "hover_damage_fmt", "reason_enemy_guard", "reason_rival_core_counter",
	"reason_rival_hypha_counter", "reason_rival_infection", "reason_ecology_toxin",
	"reason_bacteria_toxin", "reason_lytic_burst_counter", "reason_low_biomass",
	"reason_repair_transfer", "reason_manual_return", "reason_no_core",
	"reason_environment_pressure", "reason_unknown", "toast_guard_defeated",
	"toast_core_defeated", "toast_hypha_severed", "toast_unit_lost_fmt",
	"toast_player_core_lost_fmt", "toast_command_receipt_fmt", "toast_command_unavailable",
	"toast_returning_fmt", "rival_discovery_title", "rival_discovery_detail",
	"rival_discovery_toast", "toast_selected_fmt", "toast_filter_fmt",
	"toast_harvest_select", "toast_harvest_unavailable", "toast_harvest_prompt",
	"toast_clear_orders_fmt", "toast_clear_none", "toast_harvest_assigned_fmt", "toast_harvest_failed",
	"toast_purge_select", "toast_purge_prompt", "toast_purge_assigned_fmt", "toast_purge_failed",
	"toast_defense_select", "toast_defense_unavailable", "toast_defense_prompt",
	"toast_defense_assigned_fmt", "toast_defense_failed"
]

const VALUES := {
	"zh_CN": [
		"左键点击/拖框选兵　右键指令　Z 防区　X 采区　V 猎区　C 清令　R 返巢　滚轮缩放　F5 保存　Esc 暂停",
		"全部", "%s筛选　已选 %d / %d", "平均生物量 %.1f%%　防 %d　采 %d　猎 %d　返 %d　修 %d",
		"设防 Z", "采区 X", "猎区 V", "清令 C",
		"竞争菌守卫孢子", "沿菌丝巡逻", "追击体外孢子", "接触攻击", "返回菌网", "失联衰亡", "巡逻",
		"基础游猎孢子可弱攻；穿壁孢子具有真菌特攻",
		"初始竞争菌落", "第 %d 轮孢子雨", "%s　生物量 %.1f%%", "休眠", "觅食", "侵染扩张", "营养匮乏", "失活", "未知",
		"状态：%s　有机储备 %.3f", "确立真菌食性并生产穿壁孢子可以攻击核心",
		"敌方菌丝　完整度 %.1f%%", "连通供给", "失联衰败", "%s　·　%s", "缠丝猎手可右键指定并切断这段菌丝",
		"行动原因：%s", "最近受伤：%s", "竞争菌守卫孢子", "竞争真菌反击", "菌丝缠绕反击", "敌对真菌侵染",
		"生态毒素", "细菌毒素反噬", "范围裂解反击", "生物量过低", "前往兵营修复", "手动返巢", "失去全部菌落核心", "环境压力", "未知原因",
		"竞争菌守卫孢子已失活", "竞争性真菌核心已失活", "敌方菌丝被切断；远端分支已失去供给",
		"%s因%s失活；自动补员会在资源充足时接替", "%s %d 因%s失活；其菌丝网络开始衰退",
		"指令回执：%d 执行　%d 改为警戒　%d 暂不可用", "重伤、修复中或食性不匹配的单位无法执行", "%d 个体外单位正在返回兵营",
		"发现竞争性真菌菌落", "它会消耗真实营养扩张菌丝；真菌食性可解锁穿壁孢子", "发现敌对菌落　右键可下达攻击指令",
		"已选中 %d 个体外单位", "%s筛选：已选 %d 个单位",
		"请先选择游猎、囊载或螯合孢子", "当前选择中没有可执行资源采集的单位", "按住右键拖出正方形采区；Esc 取消",
		"已清除 %d 个单位的命令；%d 个恢复自动行动", "所选单位没有可清除的手动命令或持久区域", "已为 %d 个单位设置持久采区", "采区超出菌落行动范围，或单位暂时无法执行",
		"请先选择可猎食细菌的游猎、裂菌或溶菌单位", "按住右键拖出正方形细菌清剿区；Esc 取消", "已为 %d 个单位设置持久细菌清剿区", "清剿区超出菌落行动范围，或单位暂时无法执行",
		"请先选择可以出击的体外孢子", "当前选择中没有可执行真菌防御的单位", "按住右键拖出正方形防区；Esc 取消", "已为 %d 个单位设置持久防区", "防区超出菌落行动范围，或单位暂时无法执行"
	],
	"zh_TW": [
		"左鍵點擊/拖框選兵　右鍵指令　Z 防區　X 採區　V 獵區　C 清令　R 返巢　滾輪縮放　F5 儲存　Esc 暫停",
		"全部", "%s篩選　已選 %d / %d", "平均生物量 %.1f%%　防 %d　採 %d　獵 %d　返 %d　修 %d",
		"設防 Z", "採區 X", "獵區 V", "清令 C",
		"競爭菌守衛孢子", "沿菌絲巡邏", "追擊體外孢子", "接觸攻擊", "返回菌網", "失聯衰亡", "巡邏",
		"基礎遊獵孢子可弱攻；穿壁孢子具有真菌特攻",
		"初始競爭菌落", "第 %d 輪孢子雨", "%s　生物量 %.1f%%", "休眠", "覓食", "侵染擴張", "營養匱乏", "失活", "未知",
		"狀態：%s　有機儲備 %.3f", "確立真菌食性並生產穿壁孢子即可攻擊核心",
		"敵方菌絲　完整度 %.1f%%", "連通供給", "失聯衰敗", "%s　·　%s", "纏絲獵手可用右鍵指定並切斷這段菌絲",
		"行動原因：%s", "最近受傷：%s", "競爭菌守衛孢子", "競爭真菌反擊", "菌絲纏繞反擊", "敵對真菌侵染",
		"生態毒素", "細菌毒素反噬", "範圍裂解反擊", "生物量過低", "前往兵營修復", "手動返巢", "失去全部菌落核心", "環境壓力", "未知原因",
		"競爭菌守衛孢子已失活", "競爭性真菌核心已失活", "敵方菌絲已切斷；遠端分支失去供給",
		"%s因%s失活；資源足夠時將自動補員", "%s %d 因%s失活；其菌絲網路開始衰退",
		"指令回報：%d 執行　%d 改為警戒　%d 暫不可用", "重傷、修復中或食性不符的單位無法執行", "%d 個體外單位正在返回兵營",
		"發現競爭性真菌菌落", "它會消耗真實營養擴張菌絲；真菌食性可解鎖穿壁孢子", "發現敵對菌落　按右鍵可下達攻擊指令",
		"已選取 %d 個體外單位", "%s篩選：已選 %d 個單位",
		"請先選擇遊獵、囊載或螯合孢子", "目前選擇中沒有可執行資源採集的單位", "按住右鍵拖出正方形採區；Esc 取消",
		"已清除 %d 個單位的命令；%d 個恢復自動行動", "所選單位沒有可清除的手動命令或持久區域", "已為 %d 個單位設定持久採區", "採區超出菌落行動範圍，或單位暫時無法執行",
		"請先選擇可獵食細菌的遊獵、裂菌或溶菌單位", "按住右鍵拖出正方形細菌清剿區；Esc 取消", "已為 %d 個單位設定持久細菌清剿區", "清剿區超出菌落行動範圍，或單位暫時無法執行",
		"請先選擇可以出擊的體外孢子", "目前選擇中沒有可執行真菌防禦的單位", "按住右鍵拖出正方形防區；Esc 取消", "已為 %d 個單位設定持久防區", "防區超出菌落行動範圍，或單位暫時無法執行"
	],
	"en": [
		"Left-click/drag select · Right-click command · Z defend · X harvest · V purge · C clear · R return · Wheel zoom · F5 save · Esc pause",
		"All", "%s filter · Selected %d / %d", "Avg biomass %.1f%% · Def %d · Harv %d · Purge %d · Return %d · Repair %d",
		"Defend Z", "Harvest X", "Purge V", "Clear C",
		"Rival guard spore", "Patrolling hyphae", "Chasing mobile spores", "Contact attack", "Returning to network", "Orphan decay", "Patrolling",
		"Foragers can fight weakly; piercers specialize against fungi",
		"Initial rival colony", "Sporefall wave %d", "%s · Biomass %.1f%%", "Dormant", "Foraging", "Invasive growth", "Starved", "Inactive", "Unknown",
		"State: %s · Organic reserve %.3f", "Adopt a fungal diet and produce piercers to attack the core",
		"Enemy hypha · Integrity %.1f%%", "Connected supply", "Orphan decay", "%s · %s", "Right-click this hypha with a coil hunter to sever it",
		"Action reason: %s", "Last damage: %s", "Rival guard spore", "Rival fungus counterattack", "Hyphal entanglement", "Rival fungal infection",
		"Ecological toxin", "Bacterial toxin backlash", "Lytic burst backlash", "Low biomass", "Transfer to barracks for repair", "Manual return", "All colony cores lost", "Environmental stress", "Unknown cause",
		"Rival guard spore deactivated", "Rival fungal core deactivated", "Enemy hypha severed; the distal branch lost supply",
		"%s was lost to %s; auto-replenishment will replace it when resources allow", "%s %d was lost to %s; its hyphal network is decaying",
		"Command report: %d executing · %d guarding · %d unavailable", "Wounded, repairing, or diet-incompatible units cannot execute", "%d mobile units are returning to barracks",
		"Rival fungal colony discovered", "It consumes real nutrients to grow; a fungal diet unlocks piercer spores", "Hostile colony discovered · Right-click to issue an attack order",
		"Selected %d mobile units", "%s filter: selected %d units",
		"Select forager, carrier, or chelator spores first", "No selected unit can harvest resources", "Hold right mouse and drag a square harvest zone; Esc cancels",
		"Cleared orders for %d units; %d resumed automatic action", "Selected units have no manual orders or persistent zones to clear", "Assigned a persistent harvest zone to %d units", "The harvest zone is out of colony range, or units cannot act yet",
		"Select bacteria-capable forager, lytic, or disperser units first", "Hold right mouse and drag a square bacterial purge zone; Esc cancels", "Assigned a persistent bacterial purge zone to %d units", "The purge zone is out of colony range, or units cannot act yet",
		"Select mobile spores that can defend against fungi first", "No selected unit can defend against fungi", "Hold right mouse and drag a square defense zone; Esc cancels", "Assigned a persistent defense zone to %d units", "The defense zone is out of colony range, or units cannot act yet"
	],
	"ja": [
		"左クリック/ドラッグで選択　右クリックで指令　Z 防衛　X 採集　V 掃討　C 解除　R 帰還　ホイール拡縮　F5 保存　Esc 一時停止",
		"すべて", "%sフィルター　選択 %d / %d", "平均バイオマス %.1f%%　防 %d　採 %d　掃 %d　帰 %d　修 %d",
		"防衛 Z", "採集 X", "掃討 V", "解除 C",
		"競争菌ガード胞子", "菌糸を巡回", "体外胞子を追跡", "接触攻撃", "菌網へ帰還", "孤立して衰弱", "巡回",
		"採集胞子も弱く攻撃可能。穿壁胞子は真菌に特効",
		"初期競争コロニー", "胞子雨 第%d波", "%s　バイオマス %.1f%%", "休眠", "採餌", "侵食拡張", "栄養不足", "失活", "不明",
		"状態：%s　有機備蓄 %.3f", "真菌食性を選び、穿壁胞子を生産するとコアを攻撃できます",
		"敵菌糸　完全度 %.1f%%", "供給接続", "孤立衰弱", "%s　·　%s", "纏糸ハンターで右クリックするとこの菌糸を切断できます",
		"行動理由：%s", "直近の損傷：%s", "競争菌ガード胞子", "競争菌の反撃", "菌糸の絡みつき", "敵対真菌の侵食",
		"生態毒素", "細菌毒素の反作用", "溶菌バーストの反作用", "バイオマス低下", "兵舎へ修理移送", "手動帰還", "全コロニーコア喪失", "環境ストレス", "原因不明",
		"競争菌ガード胞子が失活しました", "競争菌コアが失活しました", "敵菌糸を切断。遠位枝は供給を失いました",
		"%sは%sで失活。資源が整い次第、自動補充されます", "%s %d は%sで失活。菌糸網が衰退を始めます",
		"指令結果：%d 実行　%d 警戒へ変更　%d 使用不可", "重傷・修理中・食性不適合のユニットは実行できません", "%d 体の体外ユニットが兵舎へ帰還中",
		"競争性真菌コロニーを発見", "実資源を消費して菌糸を拡張します。真菌食性で穿壁胞子を解放できます", "敵対コロニー発見　右クリックで攻撃指令",
		"体外ユニットを %d 体選択", "%sフィルター：%d 体選択",
		"先に採集・運搬・キレート胞子を選択してください", "選択中に資源採集できるユニットがありません", "右ボタンを押しながら正方形の採集区を描画。Esc で取消",
		"%d 体の命令を解除し、%d 体が自動行動へ復帰", "解除できる手動命令または持続区域がありません", "%d 体に持続採集区を設定", "採集区がコロニーの行動範囲外、または現在実行不能です",
		"細菌を捕食できる採集・溶菌・散布ユニットを選択してください", "右ボタンを押しながら正方形の細菌掃討区を描画。Esc で取消", "%d 体に持続細菌掃討区を設定", "掃討区がコロニーの行動範囲外、または現在実行不能です",
		"出撃可能な体外胞子を選択してください", "選択中に真菌防衛できるユニットがありません", "右ボタンを押しながら正方形の防衛区を描画。Esc で取消", "%d 体に持続防衛区を設定", "防衛区がコロニーの行動範囲外、または現在実行不能です"
	],
	"es": [
		"Clic/arrastre izq.: seleccionar · Clic der.: ordenar · Z defender · X recolectar · V purgar · C limpiar · R volver · Rueda zoom · F5 guardar · Esc pausa",
		"Todas", "Filtro %s · Seleccionadas %d / %d", "Biomasa media %.1f%% · Def %d · Rec %d · Pur %d · Reg %d · Rep %d",
		"Defender Z", "Recolectar X", "Purgar V", "Limpiar C",
		"Espora guardiana rival", "Patrulla las hifas", "Persigue esporas móviles", "Ataque por contacto", "Regresa a la red", "Decae aislada", "Patrulla",
		"Las recolectoras atacan débilmente; las perforadoras son especialistas antifúngicas",
		"Colonia rival inicial", "Oleada de esporas %d", "%s · Biomasa %.1f%%", "Latente", "Forrajeo", "Expansión invasiva", "Sin nutrientes", "Inactiva", "Desconocido",
		"Estado: %s · Reserva orgánica %.3f", "Adopta dieta fúngica y produce perforadoras para atacar el núcleo",
		"Hifa enemiga · Integridad %.1f%%", "Suministro conectado", "Deterioro aislado", "%s · %s", "Haz clic derecho con un cazador enrollador para cortar esta hifa",
		"Motivo de acción: %s", "Daño reciente: %s", "Espora guardiana rival", "Contraataque fúngico rival", "Enredo de hifas", "Infección fúngica rival",
		"Toxina ecológica", "Reacción de toxina bacteriana", "Reacción de ráfaga lítica", "Biomasa baja", "Traslado al cuartel para reparar", "Regreso manual", "Todos los núcleos perdidos", "Estrés ambiental", "Causa desconocida",
		"Espora guardiana rival desactivada", "Núcleo fúngico rival desactivado", "Hifa enemiga cortada; la rama distal perdió suministro",
		"%s se perdió por %s; el reemplazo automático actuará cuando haya recursos", "%s %d se perdió por %s; su red de hifas empieza a decaer",
		"Informe: %d ejecutan · %d vigilan · %d no disponibles", "Las unidades heridas, en reparación o con dieta incompatible no pueden actuar", "%d unidades móviles regresan al cuartel",
		"Colonia fúngica rival descubierta", "Consume nutrientes reales para crecer; la dieta fúngica desbloquea esporas perforadoras", "Colonia hostil descubierta · Clic derecho para ordenar un ataque",
		"Seleccionadas %d unidades móviles", "Filtro %s: %d unidades seleccionadas",
		"Selecciona primero esporas recolectoras, portadoras o quelantes", "Ninguna unidad seleccionada puede recolectar recursos", "Mantén el botón derecho y arrastra una zona cuadrada de recolección; Esc cancela",
		"Órdenes borradas para %d unidades; %d retomaron la acción automática", "Las unidades seleccionadas no tienen órdenes manuales ni zonas persistentes que borrar", "Zona persistente de recolección asignada a %d unidades", "La zona de recolección está fuera del alcance o las unidades aún no pueden actuar",
		"Selecciona recolectoras, líticas o dispersoras capaces de cazar bacterias", "Mantén el botón derecho y arrastra una zona cuadrada de purga bacteriana; Esc cancela", "Zona persistente de purga bacteriana asignada a %d unidades", "La zona de purga está fuera del alcance o las unidades aún no pueden actuar",
		"Selecciona primero esporas móviles capaces de defender contra hongos", "Ninguna unidad seleccionada puede defender contra hongos", "Mantén el botón derecho y arrastra una zona cuadrada de defensa; Esc cancela", "Zona persistente de defensa asignada a %d unidades", "La zona de defensa está fuera del alcance o las unidades aún no pueden actuar"
	],
	"de": [
		"Linksklick/Ziehen: wählen · Rechtsklick: Befehl · Z Schutz · X Ernte · V Säubern · C löschen · R zurück · Rad Zoom · F5 speichern · Esc Pause",
		"Alle", "%s-Filter · Gewählt %d / %d", "Ø Biomasse %.1f%% · Sch %d · Ern %d · Jag %d · Zur %d · Rep %d",
		"Schutz Z", "Ernte X", "Säubern V", "Löschen C",
		"Rivalen-Wächterspore", "Patrouilliert an Hyphen", "Verfolgt mobile Sporen", "Kontaktangriff", "Kehrt zum Netz zurück", "Zerfällt isoliert", "Patrouille",
		"Sammlersporen greifen schwach an; Bohrsporen sind gegen Pilze spezialisiert",
		"Ursprüngliche Rivalenkolonie", "Sporenregen-Welle %d", "%s · Biomasse %.1f%%", "Ruhend", "Nahrungssuche", "Invasives Wachstum", "Ausgehungert", "Inaktiv", "Unbekannt",
		"Status: %s · Organikreserve %.3f", "Pilzernährung wählen und Bohrsporen erzeugen, um den Kern anzugreifen",
		"Feindhyphe · Integrität %.1f%%", "Versorgung verbunden", "Isolierter Zerfall", "%s · %s", "Mit einem Wickeljäger rechtsklicken, um diese Hyphe zu trennen",
		"Aktionsgrund: %s", "Letzter Schaden: %s", "Rivalen-Wächterspore", "Gegenangriff des Rivalen", "Hyphenverwicklung", "Rivalisierende Pilzinfektion",
		"Ökologisches Toxin", "Bakterientoxin-Rückschlag", "Lyseimpuls-Rückschlag", "Niedrige Biomasse", "Zur Reparatur in die Kaserne", "Manuelle Rückkehr", "Alle Koloniekerne verloren", "Umweltstress", "Unbekannte Ursache",
		"Rivalen-Wächterspore deaktiviert", "Rivalisierender Pilzkern deaktiviert", "Feindhyphe getrennt; der äußere Ast verlor die Versorgung",
		"%s fiel durch %s aus; automatische Verstärkung folgt bei genügend Ressourcen", "%s %d fiel durch %s aus; sein Hyphennetz zerfällt",
		"Befehlsbericht: %d aktiv · %d bewachen · %d nicht verfügbar", "Verwundete, reparierende oder ernährungsfremde Einheiten können nicht handeln", "%d mobile Einheiten kehren zur Kaserne zurück",
		"Rivalisierende Pilzkolonie entdeckt", "Sie verbraucht echte Nährstoffe; Pilzernährung schaltet Bohrsporen frei", "Feindkolonie entdeckt · Rechtsklick erteilt Angriffsbefehl",
		"%d mobile Einheiten ausgewählt", "%s-Filter: %d Einheiten ausgewählt",
		"Zuerst Sammler-, Träger- oder Chelatorsporen wählen", "Keine gewählte Einheit kann Ressourcen sammeln", "Rechte Maustaste halten und quadratische Erntezone ziehen; Esc bricht ab",
		"Befehle von %d Einheiten gelöscht; %d handeln wieder automatisch", "Die gewählten Einheiten haben keine löschbaren Befehle oder dauerhaften Zonen", "Dauerhafte Erntezone für %d Einheiten gesetzt", "Erntezone außerhalb der Reichweite oder Einheiten derzeit nicht einsatzfähig",
		"Zuerst bakterienfähige Sammler-, Lyse- oder Streueinheiten wählen", "Rechte Maustaste halten und quadratische Bakterien-Säuberungszone ziehen; Esc bricht ab", "Dauerhafte Bakterien-Säuberungszone für %d Einheiten gesetzt", "Säuberungszone außerhalb der Reichweite oder Einheiten derzeit nicht einsatzfähig",
		"Zuerst einsatzfähige mobile Sporen wählen", "Keine gewählte Einheit kann gegen Pilze verteidigen", "Rechte Maustaste halten und quadratische Schutzzone ziehen; Esc bricht ab", "Dauerhafte Schutzzone für %d Einheiten gesetzt", "Schutzzone außerhalb der Reichweite oder Einheiten derzeit nicht einsatzfähig"
	],
	"ru": [
		"ЛКМ/рамка: выбор · ПКМ: приказ · Z оборона · X сбор · V зачистка · C сброс · R возврат · Колесо масштаб · F5 сохранить · Esc пауза",
		"Все", "Фильтр «%s» · Выбрано %d / %d", "Ср. биомасса %.1f%% · Обор %d · Сбор %d · Охот %d · Возв %d · Рем %d",
		"Оборона Z", "Сбор X", "Зачистка V", "Сброс C",
		"Спора-страж соперника", "Патрулирует гифы", "Преследует мобильные споры", "Контактная атака", "Возвращается к сети", "Распадается без связи", "Патруль",
		"Сборщики атакуют слабо; пробивающие споры эффективны против грибов",
		"Исходная колония соперника", "Споропад, волна %d", "%s · Биомасса %.1f%%", "Покой", "Поиск пищи", "Инвазивный рост", "Голодание", "Неактивно", "Неизвестно",
		"Состояние: %s · Запас органики %.3f", "Выберите грибное питание и создайте пробивающие споры для атаки ядра",
		"Вражеская гифа · Целостность %.1f%%", "Связана с питанием", "Распад без связи", "%s · %s", "Щёлкните ПКМ охотником-обвивателем, чтобы перерезать эту гифу",
		"Причина действия: %s", "Последний урон: %s", "Спора-страж соперника", "Контратака гриба-соперника", "Опутывание гифами", "Инфекция вражеского гриба",
		"Экологический токсин", "Ответный бактериальный токсин", "Ответный литический выброс", "Низкая биомасса", "Перевод в казарму на ремонт", "Ручной возврат", "Все ядра колонии потеряны", "Давление среды", "Неизвестная причина",
		"Спора-страж соперника деактивирована", "Ядро гриба-соперника деактивировано", "Вражеская гифа перерезана; дальняя ветвь лишилась питания",
		"%s потеряна из-за %s; автопополнение сработает при наличии ресурсов", "%s %d потеряно из-за %s; сеть гиф начинает распадаться",
		"Отчёт: выполняют %d · охраняют %d · недоступны %d", "Раненые, ремонтируемые или несовместимые по питанию бойцы не могут действовать", "%d мобильных единиц возвращаются в казарму",
		"Обнаружена колония гриба-соперника", "Она расходует реальные питательные вещества; грибное питание открывает пробивающие споры", "Обнаружена вражеская колония · ПКМ отдаёт приказ на атаку",
		"Выбрано мобильных единиц: %d", "Фильтр «%s»: выбрано %d единиц",
		"Сначала выберите споры-сборщики, переносчики или хелаторы", "Среди выбранных нет единиц, способных собирать ресурсы", "Удерживайте ПКМ и растяните квадратную зону сбора; Esc — отмена",
		"Приказы сняты с %d единиц; %d вернулись к автоматическим действиям", "У выбранных единиц нет ручных приказов или постоянных зон для сброса", "Постоянная зона сбора назначена %d единицам", "Зона сбора вне радиуса колонии или единицы пока не могут действовать",
		"Выберите сборщиков, литиков или рассеивателей, способных охотиться на бактерии", "Удерживайте ПКМ и растяните квадратную зону зачистки бактерий; Esc — отмена", "Постоянная зона зачистки бактерий назначена %d единицам", "Зона зачистки вне радиуса колонии или единицы пока не могут действовать",
		"Сначала выберите мобильные споры, готовые к вылазке", "Среди выбранных нет единиц, способных обороняться от грибов", "Удерживайте ПКМ и растяните квадратную зону обороны; Esc — отмена", "Постоянная зона обороны назначена %d единицам", "Зона обороны вне радиуса колонии или единицы пока не могут действовать"
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
	var index := KEYS.find(key)
	if index < 0:
		return key
	var locale := normalize_locale(locale_id)
	var row: Array = VALUES.get(locale, VALUES["en"])
	return String(row[index]) if index < row.size() else String((VALUES["en"] as Array)[index])
