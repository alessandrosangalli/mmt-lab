module Style exposing (css)

{-| The page's stylesheet, injected by `Main.view`.
-}


css : String
css =
    """
:root {
  --ground: #eef2ee;
  --sheet: #f8faf7;
  --ink: #16242a;
  --muted: #5a6a6b;
  --rule: #cfd9d3;
  --blue: #1f5fa6;
  --red: #b3342b;
  --amber: #a8741a;
}
@media (prefers-color-scheme: dark) {
  :root {
    --ground: #0f1719;
    --sheet: #162225;
    --ink: #e2eae5;
    --muted: #95a6a4;
    --rule: #2b3c3f;
    --blue: #74aae6;
    --red: #ef7d70;
    --amber: #e0aa4f;
    color-scheme: dark;
  }
}
body {
  margin: 0;
  background: var(--ground);
  color: var(--ink);
  font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
}
.page {
  max-width: 860px;
  margin: 0 auto;
  padding: 24px 16px 48px;
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 22px;
}
h1 {
  font-family: Georgia, "Times New Roman", serif;
  font-size: 1.9rem;
  margin: 0;
}
.subtitle {
  margin: 6px 0 0;
  color: var(--muted);
  max-width: 62ch;
  line-height: 1.5;
}
.controls.b { border-color: var(--amber); }
.controls.a { border-color: var(--rule); }
.controls {
  background: var(--sheet);
  border: 1px solid var(--rule);
  border-radius: 10px;
  padding: 16px;
  display: grid;
  gap: 14px;
}
.control label {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  font-size: 0.9rem;
  margin-bottom: 4px;
}
.controls h2 { font-size: 1rem; margin: 0; }
.premises {
  display: grid;
  gap: 14px;
  padding-top: 14px;
  border-top: 1px solid var(--rule);
}
.premises h3 { font-size: 0.9rem; margin: 0; }
.premise { display: grid; gap: 4px; }
.premise-note {
  margin: 0;
  font-size: 0.8rem;
  line-height: 1.45;
  color: var(--muted);
  max-width: 65ch;
}
.controls .hint { margin: 0; }
.policy, .changes { display: grid; gap: 14px; }
.changes:empty { display: none; }
.change {
  display: grid;
  gap: 12px;
  padding: 12px;
  border: 1px dashed var(--rule);
  border-radius: 8px;
}
.change-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  font-size: 0.9rem;
  font-weight: 600;
}
.value { font-variant-numeric: tabular-nums; font-weight: 600; }
input[type=range] { width: 100%; accent-color: var(--blue); }
.buttons { display: flex; flex-wrap: wrap; gap: 8px; }
button {
  font: inherit;
  font-weight: 600;
  padding: 9px 14px;
  border-radius: 8px;
  border: 1px solid var(--blue);
  background: var(--blue);
  color: var(--sheet);
  cursor: pointer;
}
button.secondary { background: transparent; color: var(--blue); }
button.small { padding: 4px 10px; font-size: 0.8rem; }
button:disabled { opacity: 0.45; cursor: default; }
button:focus-visible { outline: 2px solid var(--ink); outline-offset: 2px; }
.content { display: grid; grid-template-columns: minmax(0, 1fr); gap: 22px; }
.summary {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
  gap: 1px;
  background: var(--rule);
  border: 1px solid var(--rule);
  border-radius: 10px;
  overflow: hidden;
}
.indicator { background: var(--sheet); padding: 10px 12px; display: grid; gap: 2px; }
.indicator:last-child:nth-child(odd) { grid-column: 1 / -1; }
.indicator .name {
  font-size: 0.72rem;
  color: var(--muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.indicator .number { font-size: 1.3rem; font-weight: 600; font-variant-numeric: tabular-nums; }
.block h2 { font-size: 1rem; margin: 0 0 8px; }
.legend {
  display: flex;
  flex-wrap: wrap;
  gap: 14px;
  font-size: 0.8rem;
  color: var(--muted);
  margin-bottom: 8px;
}
.key::before {
  content: "";
  display: inline-block;
  width: 10px;
  height: 10px;
  margin-right: 6px;
  border-radius: 2px;
  vertical-align: -1px;
}
.key.a::before { background: var(--blue); }
.key.b::before { background: var(--amber); }
.key.private::before { background: var(--blue); }
.key.government::before { background: var(--red); }
.key.foreign::before { background: var(--amber); }
.key.dashed::before { width: 14px; height: 0; border-top: 2px dashed var(--muted); border-radius: 0; vertical-align: 3px; }
.key.cursor::before { width: 0; height: 12px; border-left: 1px solid var(--ink); border-radius: 0; opacity: 0.55; vertical-align: -2px; }
.key.changed::before { width: 0; height: 12px; border-left: 1px dashed var(--red); border-radius: 0; vertical-align: -2px; }
.linechart { padding: 6px 10px 24px 40px; }
.plot {
  position: relative;
  height: 170px;
  border-left: 1px solid var(--rule);
  border-bottom: 1px solid var(--ink);
}
.plot svg {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  overflow: visible;
}
.plot line, .plot polyline { vector-effect: non-scaling-stroke; }
.plot .grid { stroke: var(--rule); stroke-width: 1; }
.plot .marker { stroke: var(--red); stroke-width: 1; stroke-dasharray: 3 3; }
.plot .cursor { stroke: var(--ink); stroke-width: 1; opacity: 0.55; }
.plot .series { fill: none; stroke-width: 2; stroke-linejoin: round; }
.plot .series.a { stroke: var(--blue); }
.plot .series.b { stroke: var(--amber); stroke-dasharray: 6 4; }
.plot .series.private { stroke: var(--blue); }
.plot .series.government { stroke: var(--red); }
.plot .series.foreign { stroke: var(--amber); }
.plot .series.dashed { stroke-dasharray: 6 4; }
.plot .zero { stroke: var(--ink); stroke-width: 1; }
.plot .hit { fill: transparent; cursor: pointer; }
.ytick, .xtick {
  position: absolute;
  font-size: 0.7rem;
  color: var(--muted);
  font-variant-numeric: tabular-nums;
  pointer-events: none;
}
.ytick { left: -40px; width: 34px; text-align: right; transform: translateY(-50%); }
.xtick { top: 100%; margin-top: 5px; transform: translateX(-50%); }
.dot {
  position: absolute;
  width: 9px;
  height: 9px;
  border-radius: 50%;
  border: 2px solid var(--sheet);
  transform: translate(-50%, -50%);
  pointer-events: none;
}
.dot.a { background: var(--blue); }
.dot.b { background: var(--amber); }
.dot.private { background: var(--blue); }
.dot.government { background: var(--red); }
.dot.foreign { background: var(--amber); }
.block h2.spaced { margin-top: 18px; }
.linechart + .control { margin-top: 8px; }
.warning {
  margin: 0;
  padding: 10px 12px;
  border: 1px solid var(--amber);
  border-radius: 8px;
  color: var(--ink);
  font-size: 0.9rem;
  line-height: 1.5;
}
.map-controls {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-end;
  gap: 12px;
  margin-bottom: 12px;
}
.map-axis { display: grid; gap: 4px; min-width: 0; flex: 1 1 220px; }
.map-axis label { font-size: 0.8rem; color: var(--muted); }
.map-axis select {
  font: inherit;
  font-size: 0.9rem;
  padding: 7px 8px;
  border: 1px solid var(--rule);
  border-radius: 8px;
  background: var(--sheet);
  color: var(--ink);
  min-width: 0;
  max-width: 100%;
}
.map-axis-name { margin: 0 0 4px; font-size: 0.8rem; color: var(--muted); }
.map-axis-name.across { margin: 4px 0 10px; text-align: right; max-width: 520px; }
.map-grid {
  display: grid;
  grid-template-columns: 2.4rem repeat(11, minmax(0, 1fr));
  gap: 2px;
  max-width: 520px;
}
.map-tick {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  padding-right: 4px;
  font-size: 0.65rem;
  color: var(--muted);
  font-variant-numeric: tabular-nums;
}
.map-tick.below { justify-content: center; padding: 2px 0 0; font-size: 0.55rem; }
.cell {
  aspect-ratio: 1;
  min-width: 0;
  padding: 0;
  border: 0;
  border-radius: 3px;
  font-size: 0.6rem;
  font-weight: 600;
  line-height: 1;
  color: var(--sheet);
  font-variant-numeric: tabular-nums;
}
button.cell { padding: 0; border: 0; border-radius: 3px; font-size: 0.6rem; }
button.cell:disabled { opacity: 1; }
.cell.settles { background: var(--blue); }
.cell.adjusting { background: var(--amber); }
.cell.failed { background: var(--red); }
.cell.pending { background: var(--rule); }
.cell.here { outline: 2px solid var(--ink); outline-offset: 1px; position: relative; z-index: 1; }
.key.settles::before { background: var(--blue); }
.key.adjusting::before { background: var(--amber); }
.key.failed::before { background: var(--red); }
.key.here::before { background: transparent; box-shadow: inset 0 0 0 2px var(--ink); }
.cell.brazil { box-shadow: inset 0 0 0 3px var(--sheet), inset 0 0 0 5px var(--ink); }
.key.brazil::before { background: var(--muted); box-shadow: inset 0 0 0 2px var(--sheet), 0 0 0 2px var(--ink); }
.premises .buttons { margin-top: 2px; }
.share input {
  width: 100%;
  box-sizing: border-box;
  font: inherit;
  font-family: ui-monospace, "SF Mono", Menlo, Consolas, monospace;
  font-size: 0.8rem;
  padding: 8px 10px;
  border: 1px solid var(--rule);
  border-radius: 8px;
  background: var(--sheet);
  color: var(--ink);
}
.share a { color: var(--blue); font-size: 0.9rem; }
.share p { margin: 8px 0 0; }
.scroll { overflow-x: auto; }
table.godley {
  width: 100%;
  min-width: 420px;
  border-collapse: collapse;
  background: var(--sheet);
  font-size: 0.9rem;
}
.godley th, .godley td {
  padding: 8px 10px;
  text-align: right;
  border-bottom: 1px solid var(--rule);
}
.godley th[scope=row], .godley thead th:first-child { text-align: left; font-weight: 500; }
.godley thead th {
  font-size: 0.72rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--muted);
  border-bottom: 2px solid var(--ink);
}
.godley td.num {
  font-family: ui-monospace, "SF Mono", Menlo, Consolas, monospace;
  font-variant-numeric: tabular-nums;
}
.godley td.negative { color: var(--red); }
.godley td.total { color: var(--muted); }
.godley tfoot th, .godley tfoot td {
  font-weight: 600;
  border-top: 2px solid var(--ink);
  border-bottom: none;
}
.hint {
  margin: 0 0 8px;
  max-width: 65ch;
  font-size: 0.85rem;
  line-height: 1.5;
  color: var(--muted);
}
.check { margin: 8px 0 0; font-size: 0.85rem; font-weight: 600; }
.check.ok { color: var(--blue); }
.check.error { color: var(--red); }
.notes ol { margin: 0 0 10px; padding-left: 20px; line-height: 1.6; }
"""
