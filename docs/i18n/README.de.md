[English](README.en.md) | [简体中文](README.zh-Hans.md) | [繁體中文](README.zh-Hant.md) | [日本語](README.ja.md) | [Español](README.es.md) | [**Deutsch**](README.de.md) | [Русский](README.ru.md)

# Game: Super boring fungi

Ein Idle-Spiel über Evolution und Ausbreitung: Es beginnt mit einer mikroskopisch kleinen Spore und wächst über Ökosysteme, menschliche Gesellschaften und Staaten bis hin zum gesamten Planeten.

Das Projekt ist derzeit ein früher Windows-Prototyp in Version `0.40.0`. Im Mittelpunkt steht Kapitel 1, eine mikroskopische Laborkultur aus der Vogelperspektive. Der Spieler kontrolliert ausschließlich den Pilz, erweitert sein Hyphennetz, nimmt Nährstoffe auf, entwickelt neue Fähigkeiten und befehligt mobile Expeditionssporen. Version 0.40 führt rollensichere Befehle ein, damit Einheiten keine Sammel- oder Angriffsaufgaben ausführen, die nicht zu ihrer Spezialisierung passen.

## Download und Start

Öffne das [neueste Release](https://github.com/Arsenic-er/Game-Super-boring-fungi/releases/latest), lade die Windows-ZIP-Datei herunter, entpacke sie und starte `FungiMicroculture.exe`.

- Plattform: Windows 10/11, 64 Bit
- Installation: nicht erforderlich; alle Spieldaten sind in die EXE eingebettet
- Spielstände: werden separat im Anwendungsdatenverzeichnis des aktuellen Windows-Benutzers gespeichert
- Windows kann eine SmartScreen-Warnung anzeigen, da dieser Hobby-Build nicht digital signiert ist

## Zentrale Spielinhalte

- Erkunde eine weitläufige, frei zoombare Laborkultur mit gebündelten organischen Nährstoffen, Mineralionen, Bakterienkolonien, konkurrierenden Pilzen und dauerhaftem Nebel des Krieges.
- Keime aus einem einzelnen Sporenkern, verlängere Haupthyphen und bilde feine Absorptionshyphen, die Ressourcen langsam und mit Dezimalgenauigkeit aufnehmen.
- Verbrauche Nährstoffe zur DNA-Produktion, kaufe umkehrbare Evolutionen und Verbesserungen für Struktur, Überleben, Anpassung und Ernährungsweisen und erfülle langfristige Ziele mit unterschiedlichen Belohnungen.
- Verwalte die Biomasse von Kernen und Expeditionseinheiten auf drei Dezimalstellen sowie Toxinschäden, langsame Heilung, Rückzug zur Reparatur und das Absterben oder Wiederverbinden isolierter Hyphen.
- Baue Kasernenkerne und produziere spezialisierte Sporen für Sammlung, Transport, Mineralgewinnung, Erkundung, Bakterienbekämpfung, Pilzbekämpfung und den Einsatz räumlicher Wirkfelder.
- Weise geeigneten Einheiten dauerhafte quadratische Verteidigungs-, Sammel- oder Bakterien-Säuberungszonen zu. Nach Abladen, Reparatur, Ersatz oder begrenztem Offline-Fortschritt nehmen sie ihre Aufgabe wieder auf.
- Die rollensicheren Befehle von v0.40 lassen nur geeignete Einheitentypen sammeln oder angreifen. Ungeeignete Einheiten einer gemischten Gruppe bewegen sich zum Zielgebiet und halten dort ihre Position; die Befehlsmeldung nennt ausgeführte, auf Wache gesetzte und nicht verfügbare Einheiten.
- Erlebe Bakterienblüten, Toxinzonen, wiederkehrenden Sporenfall konkurrierender Pilze, Ressourcenanomalien, Erkundung im Nebel, langfristigen Idle-Fortschritt und eine originale Pixel-Labor-Klangkulisse mit getrennten Lautstärkekanälen.

## Steuerung in Kürze

- Kern-DNA: normal klicken für 1, Umschalttaste + Klick für 5, Strg + Klick für 10
- Linksklick: Kern untersuchen, Aktion wählen oder Expeditionssporen auswählen
- Ziehen mit der linken Maustaste: Einheiten rechteckig auswählen
- Rechtsklick: Bewegung, Sammlung, Angriff, Hyphentrennung oder Einsatz befehlen
- `Z`: quadratische Verteidigungszone festlegen
- `X`: quadratische Sammelzone festlegen
- `V`: quadratische Bakterien-Säuberungszone festlegen
- `C`: manuelle oder dauerhafte Befehle der Auswahl löschen und gesunde Einheiten in ihr rollengerechtes Automatikverhalten zurückversetzen
- `R`: ausgewählte Expeditionssporen zur Kaserne zurückschicken
- Rechts- oder Mittelklick ziehen: Kamera verschieben
- Mausrad: zoomen
- `E`: Evolutionsladen öffnen
- `G`: langfristige Ziele öffnen
- `F5`: sofort speichern
- `Esc`: Fenster schließen, Aktion abbrechen oder pausieren/fortsetzen

## Geplante Größenordnungen

Die Mikrokultur ist nur der Anfang. Künftige eigenständige Kapitel sollen über Mikroorganismen und Zellen, kleine Lebewesen und Gegenstände, Ökosysteme, menschliche Gesellschaft, Städte und Länder bis zur modernen Erde führen. Physiologische Merkmale aus frühen Größenordnungen sollen spätere Ausbreitungs- und Eroberungsstrategien beeinflussen.

## Entwicklung

Das Projekt verwendet Godot `4.7` und GDScript. Öffne `project.godot` in Godot, um den Quellstand auszuführen. Automatisierte Smoke-Tests liegen unter `tests/`; beim Windows-Export werden die Spieldaten in eine einzelne EXE eingebettet.

## Rechte

Copyright © 2026 koko. Alle Rechte vorbehalten.

Quellcode, Grafiken, Audio, Spieldesign, Texte und alle weiteren Inhalte dieses Repositorys sind ausschließlich zur Ansicht und Bewertung öffentlich zugänglich. **Eine Genehmigung zum Kopieren, Wiederverwenden, Ändern, Weiterverbreiten, Erstellen abgeleiteter Werke oder zur kommerziellen Nutzung wird nicht erteilt.** Der offizielle Build darf nur zum persönlichen Spielen und zur Bewertung heruntergeladen und ausgeführt werden. Siehe [LICENSE](../../LICENSE).
