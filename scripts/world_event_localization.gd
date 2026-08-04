extends RefCounted


const LOCALES: Array[String] = ["zh_CN", "zh_TW", "en", "ja", "es", "de", "ru"]
const KEYS: Array[String] = [
	"ecology_name_bloom", "ecology_name_toxin", "event_phase_warning", "event_phase_active",
	"event_locate_time_fmt", "ecology_hud_title_fmt", "ecology_bloom_control_fmt",
	"ecology_warning_title_fmt", "ecology_warning_detail", "ecology_delayed_title", "ecology_delayed_detail_fmt",
	"ecology_bloom_active_title", "ecology_bloom_active_detail_fmt", "ecology_toxin_active_title", "ecology_toxin_active_detail_fmt",
	"ecology_contained_title", "ecology_contained_detail_fmt", "ecology_expired_title", "ecology_expired_detail", "ecology_located_toast",
	"sporefall_warning_toast_fmt", "sporefall_active_toast_fmt", "sporefall_defeated_fmt", "sporefall_defeated_dna_fmt",
	"sporefall_cooldown_title", "sporefall_warning_title_fmt", "sporefall_active_title_fmt", "sporefall_next_signal_fmt",
	"sporefall_paused_detail", "sporefall_locate_core", "sporefall_located_toast",
	"threat_notice", "threat_imminent", "threat_contact", "threat_locate", "threat_located",
	"duration_hours_fmt", "duration_minutes_fmt", "duration_seconds_fmt"
]

const VALUES := {
	"zh_CN": [
		"局部细菌暴发", "代谢毒素区", "预警", "活跃", "点击定位 · %02d:%02d", "%s · %s", "未控 %d/%d · 维持 %d/%d 秒",
		"生态预警：%s", "点击右侧事件卡定位；准备裂菌孢子、抗生素或修复储备。", "暴发延后", "培养皿细菌数量接近上限，事件将在 %d 秒后重新评估。",
		"局部细菌暴发", "%d 个高活性细菌出现；消灭至 %d 个以下，或用抑菌区封锁 %d 秒。", "代谢毒素区形成", "抗生素分泌与解毒代谢会降低伤害，坚持 %d 秒即可消散。",
		"生态事件已应对", "%s 已平息；长期目标进度已更新。", "暴发期结束", "高活性阶段已经结束，但残余细菌仍留在培养皿中。", "镜头已定位到生态事件区域",
		"检测到竞争孢子雨：落点已标记，%d 秒后形成菌落", "第 %d 轮竞争菌落已形成", "击退第 %d 轮孢子雨：有机 +%.3f · 矿物 +%.3f", "击退第 %d 轮孢子雨：有机 +%.3f · 矿物 +%.3f · DNA +%d",
		"竞争孢子雨 · 冷却", "第 %d 轮孢子雨 · 落点预警", "第 %d 轮竞争菌落 · 活跃", "下一次信号 · %s", "生态事件或兵营缺失，计时已延后", "点击定位竞争核心", "镜头已定位竞争孢子雨",
		"竞争菌丝已进入警戒范围", "竞争菌丝正在逼近核心", "竞争菌丝已接触菌落！", "点击定位已发现的威胁", "镜头已定位竞争菌丝前缘", "%.1f 小时", "%d 分钟", "%d 秒"
	],
	"zh_TW": [
		"局部細菌暴發", "代謝毒素區", "預警", "活躍", "點擊定位 · %02d:%02d", "%s · %s", "未控 %d/%d · 維持 %d/%d 秒",
		"生態預警：%s", "點擊右側事件卡定位；準備裂菌孢子、抗生素或修復儲備。", "暴發延後", "培養皿細菌數量接近上限，事件將在 %d 秒後重新評估。",
		"局部細菌暴發", "%d 個高活性細菌出現；消滅至 %d 個以下，或用抑菌區封鎖 %d 秒。", "代謝毒素區形成", "抗生素分泌與解毒代謝會降低傷害，堅持 %d 秒即可消散。",
		"生態事件已處理", "%s 已平息；長期目標進度已更新。", "暴發期結束", "高活性階段已結束，但殘餘細菌仍留在培養皿中。", "鏡頭已定位至生態事件區域",
		"偵測到競爭孢子雨：落點已標記，%d 秒後形成菌落", "第 %d 輪競爭菌落已形成", "擊退第 %d 輪孢子雨：有機 +%.3f · 礦物 +%.3f", "擊退第 %d 輪孢子雨：有機 +%.3f · 礦物 +%.3f · DNA +%d",
		"競爭孢子雨 · 冷卻", "第 %d 輪孢子雨 · 落點預警", "第 %d 輪競爭菌落 · 活躍", "下一次訊號 · %s", "生態事件或兵營缺失，計時已延後", "點擊定位競爭核心", "鏡頭已定位競爭孢子雨",
		"競爭菌絲已進入警戒範圍", "競爭菌絲正逼近核心", "競爭菌絲已接觸菌落！", "點擊定位已發現的威脅", "鏡頭已定位競爭菌絲前緣", "%.1f 小時", "%d 分鐘", "%d 秒"
	],
	"en": [
		"Local bacterial bloom", "Metabolic toxin zone", "Warning", "Active", "Click to locate · %02d:%02d", "%s · %s", "Uncontrolled %d/%d · Hold %d/%d s",
		"Ecology warning: %s", "Click the event card to locate it; prepare lytic spores, antibiotics, or repair reserves.", "Bloom delayed", "Bacteria are near the dish limit; the event will be checked again in %d seconds.",
		"Local bacterial bloom", "%d hyperactive bacteria appeared; reduce them below %d or suppress the zone for %d seconds.", "Metabolic toxin zone formed", "Antibiotic secretion and detox metabolism reduce damage. Endure for %d seconds.",
		"Ecology event contained", "%s has subsided; long-term goal progress was updated.", "Bloom period ended", "The hyperactive phase ended, but surviving bacteria remain in the dish.", "Camera centered on the ecology event",
		"Rival Sporefall detected: landing marked; a colony forms in %d seconds", "Rival colony wave %d has formed", "Sporefall wave %d repelled: organic +%.3f · mineral +%.3f", "Sporefall wave %d repelled: organic +%.3f · mineral +%.3f · DNA +%d",
		"Rival Sporefall · Cooldown", "Sporefall wave %d · Landing warning", "Rival colony wave %d · Active", "Next signal · %s", "Timer delayed by an ecology event or missing barracks", "Click to locate the rival core", "Camera centered on Rival Sporefall",
		"Rival hyphae entered warning range", "Rival hyphae are approaching a core", "Rival hyphae reached the colony!", "Click to locate the revealed threat", "Camera centered on the rival hyphal front", "%.1f h", "%d min", "%d s"
	],
	"ja": [
		"局所細菌ブルーム", "代謝毒素域", "警告", "活動中", "クリックで移動 · %02d:%02d", "%s · %s", "未制御 %d/%d · 維持 %d/%d 秒",
		"生態警告：%s", "右のイベントカードで位置を確認。溶菌胞子、抗生物質、修復備蓄を準備しましょう。", "ブルーム延期", "細菌数が培養皿の上限に近いため、%d 秒後に再判定します。",
		"局所細菌ブルーム", "高活性細菌が %d 体出現。%d 体未満まで減らすか、抑制域を %d 秒維持してください。", "代謝毒素域が形成", "抗生物質分泌と解毒代謝で損傷を軽減できます。%d 秒耐えると消散します。",
		"生態イベントを制御", "%s は沈静化し、長期目標の進行が更新されました。", "ブルーム期終了", "高活性期は終わりましたが、生き残った細菌は培養皿に残ります。", "生態イベントの位置へ移動しました",
		"競争胞子雨を検出：落下地点を表示。%d 秒後にコロニー形成", "第 %d 波の競争コロニーが形成されました", "胞子雨第 %d 波を撃退：有機 +%.3f · 鉱物 +%.3f", "胞子雨第 %d 波を撃退：有機 +%.3f · 鉱物 +%.3f · DNA +%d",
		"競争胞子雨 · 待機中", "胞子雨第 %d 波 · 落下警告", "競争コロニー第 %d 波 · 活動中", "次の信号 · %s", "生態イベント中、または兵舎がなくタイマー停止", "クリックで競争コアへ移動", "競争胞子雨の位置へ移動しました",
		"競争菌糸が警戒範囲に侵入", "競争菌糸がコアへ接近中", "競争菌糸がコロニーに接触！", "クリックで発見済みの脅威へ移動", "競争菌糸の前線へ移動しました", "%.1f 時間", "%d 分", "%d 秒"
	],
	"es": [
		"Floración bacteriana local", "Zona de toxinas metabólicas", "Alerta", "Activo", "Clic para localizar · %02d:%02d", "%s · %s", "Sin controlar %d/%d · Mantén %d/%d s",
		"Alerta ecológica: %s", "Pulsa la tarjeta para localizarla; prepara esporas líticas, antibióticos o reservas de reparación.", "Floración aplazada", "Las bacterias rozan el límite de la placa; se revisará de nuevo en %d segundos.",
		"Floración bacteriana local", "Aparecieron %d bacterias hiperactivas; reduce a menos de %d o suprime la zona durante %d segundos.", "Zona de toxinas formada", "Los antibióticos y la desintoxicación reducen el daño. Resiste %d segundos.",
		"Evento ecológico controlado", "%s se ha calmado; se actualizó el objetivo a largo plazo.", "Fin de la floración", "La fase hiperactiva terminó, pero quedan bacterias en la placa.", "Cámara centrada en el evento ecológico",
		"Lluvia de esporas rival detectada: impacto marcado; colonia en %d segundos", "Se formó la colonia rival de la oleada %d", "Oleada %d repelida: orgánico +%.3f · mineral +%.3f", "Oleada %d repelida: orgánico +%.3f · mineral +%.3f · ADN +%d",
		"Lluvia rival · Recarga", "Oleada %d · Alerta de impacto", "Colonia rival %d · Activa", "Próxima señal · %s", "Temporizador aplazado por evento ecológico o falta de cuartel", "Clic para localizar el núcleo rival", "Cámara centrada en la lluvia rival",
		"Las hifas rivales entraron en alerta", "Las hifas rivales se acercan al núcleo", "¡Las hifas rivales tocaron la colonia!", "Clic para localizar la amenaza", "Cámara centrada en el frente rival", "%.1f h", "%d min", "%d s"
	],
	"de": [
		"Lokale Bakterienblüte", "Stoffwechsel-Toxinzone", "Warnung", "Aktiv", "Klicken zum Orten · %02d:%02d", "%s · %s", "Unkontrolliert %d/%d · Halten %d/%d s",
		"Ökologie-Warnung: %s", "Ereigniskarte anklicken; Lyse-Sporen, Antibiotika oder Reparaturreserven vorbereiten.", "Blüte verzögert", "Die Bakterienzahl liegt nahe am Schalenlimit; erneute Prüfung in %d Sekunden.",
		"Lokale Bakterienblüte", "%d hochaktive Bakterien erschienen; auf unter %d senken oder das Gebiet %d Sekunden hemmen.", "Stoffwechsel-Toxinzone gebildet", "Antibiotika und Entgiftung senken den Schaden. %d Sekunden durchhalten.",
		"Ökologieereignis eingedämmt", "%s ist abgeklungen; der Fortschritt der Langzeitziele wurde aktualisiert.", "Blütezeit beendet", "Die hochaktive Phase ist vorbei, aber restliche Bakterien bleiben in der Schale.", "Kamera auf das Ökologieereignis zentriert",
		"Rivalen-Sporenfall erkannt: Landung markiert; Kolonie entsteht in %d Sekunden", "Rivalenkolonie der Welle %d ist entstanden", "Sporenfall %d abgewehrt: Organik +%.3f · Mineral +%.3f", "Sporenfall %d abgewehrt: Organik +%.3f · Mineral +%.3f · DNA +%d",
		"Rivalen-Sporenfall · Abklingzeit", "Sporenfall %d · Landewarnung", "Rivalenkolonie %d · Aktiv", "Nächstes Signal · %s", "Timer wegen Ökologieereignis oder fehlender Kaserne verzögert", "Klicken, um den Rivalenkern zu orten", "Kamera auf den Rivalen-Sporenfall zentriert",
		"Rivalenhyphe im Warnbereich", "Rivalenhyphen nähern sich einem Kern", "Rivalenhyphen berühren die Kolonie!", "Klicken, um die Bedrohung zu orten", "Kamera auf die Rivalenfront zentriert", "%.1f Std.", "%d Min.", "%d Sek."
	],
	"ru": [
		"Локальная вспышка бактерий", "Зона метаболических токсинов", "Тревога", "Активно", "Нажмите для перехода · %02d:%02d", "%s · %s", "Без контроля %d/%d · Удержание %d/%d с",
		"Экологическая тревога: %s", "Нажмите на карточку; подготовьте литические споры, антибиотики или запас ремонта.", "Вспышка отложена", "Число бактерий близко к пределу чашки; повторная проверка через %d секунд.",
		"Локальная вспышка бактерий", "Появилось активных бактерий: %d. Оставьте меньше %d или подавляйте зону %d секунд.", "Сформирована зона токсинов", "Антибиотики и детоксикация снижают урон. Продержитесь %d секунд.",
		"Экологическое событие подавлено", "%s утихло; прогресс долгосрочной цели обновлён.", "Вспышка завершена", "Активная фаза закончилась, но выжившие бактерии остались в чашке.", "Камера наведена на экологическое событие",
		"Обнаружен дождь спор соперника: место отмечено; колония появится через %d секунд", "Сформирована колония соперника, волна %d", "Волна спор %d отражена: органика +%.3f · минералы +%.3f", "Волна спор %d отражена: органика +%.3f · минералы +%.3f · ДНК +%d",
		"Дождь спор · Перезарядка", "Волна спор %d · Место падения", "Колония соперника %d · Активна", "Следующий сигнал · %s", "Таймер отложен из-за экособытия или отсутствия казармы", "Нажмите, чтобы найти вражеское ядро", "Камера наведена на дождь спор",
		"Гифы соперника вошли в зону тревоги", "Гифы соперника приближаются к ядру", "Гифы соперника коснулись колонии!", "Нажмите, чтобы найти угрозу", "Камера наведена на передний край гиф", "%.1f ч", "%d мин", "%d с"
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
	var key_index := KEYS.find(key)
	if key_index < 0:
		return key
	var values: Array = VALUES.get(normalize_locale(locale_id), VALUES["en"])
	if key_index >= values.size():
		values = VALUES["en"]
	return String(values[key_index])
