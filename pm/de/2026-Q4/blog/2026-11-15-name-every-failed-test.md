<!--
@license
Copyright (c) ggsuite

Use of this source code is governed by terms that can be
found in the LICENSE file in the root of this package.
-->

# Jeden fehlgeschlagenen Test nennen, auch ohne Dateistelle

## Motivation

- `Tests` zeigt einen fehlgeschlagenen Test über die Stelle seines
  Fehlers, als Link, den ein Editor öffnen kann. Diese Stelle fand es im
  Stack-Trace: die erste Zeile, die eine Datei des Pakets nennt.
- Nicht jeder Fehlschlag hat so eine Zeile. Ein Test, der in sein Timeout
  läuft, eine Testdatei, die sich nicht laden lässt, und ein Fehler, der
  im SDK geworfen wird, nennen keine Datei des Pakets.
- So ein Lauf endete mit nichts als »Tests failed«. Der Entwickler musste
  `dart test` von Hand starten, um zu erfahren, welcher Test warum
  fehlschlug.
- Dasselbe geschah, wenn der Test-Runner selbst vorzeitig mit einem
  Fehlercode endete: Nichts sagte, was schiefging.

## Strategie

- Nach fehlgeschlagenem Test berichten, nicht nach Stelle: Jeder Test,
  den der Runner als fehlgeschlagen markiert, bekommt eine Meldung, mit
  Stelle, wenn es eine gibt.
- Die Ausgabe als Ganzes nach dem Lauf lesen statt Zeile für Zeile, damit
  ein Fehlschlag mit seinem eigenen Fehler erscheint und nicht mit Zeilen
  seiner Nachbarn.
- Auch stderr lesen, von Anfang an, damit keine Pipe vollläuft und nichts
  verloren geht, was der Lauf sagt.
- Schlägt der Lauf fehl und keine Meldung erklärt es, zeigen, wie er
  endete.

## Fehlgeschlagene Tests in ErrorInfoReader

- `failedTests` teilt die Ausgabe des Expanded-Reporters in die
  fehlgeschlagenen Tests: die Zeile, die der Runner mit `[E]` markiert,
  und alles, was er bis zur nächsten Fortschrittszeile ausgibt.
- Ein `FailedTest` hat den `name` des Tests, wie der Runner ihn ausgibt —
  `loading test/foo_test.dart` bei einer Datei, die sich nicht laden
  lässt —, seine `lines` und `details`: den Fehler und seinen Stack-Trace
  ohne die Zeile, die den Test nennt, und ohne Leerzeilen.
- `linesOutsideFailedTests` liefert den Rest der Ausgabe, für die
  Meldungen, die zu keinem einzelnen Test gehören.

## Einen Lauf in Tests auswerten

- `_evaluateTestRun` ersetzt das zeilenweise `_processTestOutput`. Es
  liest stdout und stderr, wartet auf den Exit-Code und wertet dann aus.
- `_noteFailedTests` schreibt eine Meldung pro fehlgeschlagenem Test. Mit
  Stelle ist es der Link wie bisher. Ohne Stelle sind es der Name des
  Tests und die ersten sechs Zeilen seines Fehlers; weitere Zeilen
  kündigt ein `…` an.
- `_noteUnexplainedExit` deckt einen Lauf ab, der mit einem Fehlercode
  endet, obwohl kein fehlgeschlagener Test genannt wurde: Es zeigt den
  Exit-Code und die letzten sechs Zeilen von stdout und von stderr.
- Ein Lauf schlägt fehl, wenn der Exit-Code nicht null ist oder ein
  fehlgeschlagener Test gefunden wurde.

## Tests

- Ein Timeout, eine Testdatei, die beim Laden wirft, und ein Fehler ohne
  Stack-Trace-Zeile des Pakets werden jeweils mit dem Namen des Tests
  gemeldet.
- Zwei Fehlschläge in einem Lauf zeigen nur ihre eigenen Fehler.
- Ein Lauf, der mit einem Fehlercode endet und keinen Test nennt, zeigt
  den Exit-Code und das Ende seiner Ausgabe.
- Das README nennt das neue Verhalten, `index.jsonc` und `CLAUDE.md`
  ziehen nach.

## Offene Punkte

- Nur der Expanded-Reporter der Test-Runner von Dart und Flutter wird in
  fehlgeschlagene Tests geteilt. Die Ausgabe eines TypeScript-Laufs wird
  wie bisher gezeigt.
- Sechs Zeilen sind eine feste Grenze. Ein Fehlschlag, dessen Ursache
  weiter unten steht, braucht weiterhin einen Lauf von Hand.
