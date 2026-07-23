# SPARX Known Issues

## KLayout Regular DRC

`klayout-drc-regular` is not clean due to antenna check violations. IHP has waived these DRC errors during the March 2026 tapeout. `make klayout-drc` (`macro` level) is clean. The 33 violations on `sparx160_top` are:

| Rule(s) | Count | Root cause |
| --- | :---: | --- |
| `Ant.e_Metal5`, `Ant.e_TopMetal1`, `Ant.e_TopMetal2` | 24 | Large RF/supply metal (incl. the M5 ground plane on `vss`) connects to the power-detector MOS gates (`MM1`–`MM4` and the `MMdummy*` devices, whose gates tie directly to `vdd`/`vss`), so the cumulative-metal-to-gate-area ratio exceeds 20000. |
| `Ant.f_TopVia2` | 8 | Same nets as above. Cumulative TopVia2-to-gate-area ratio exceeds 500. |
| `Ant.h` | 1 | The `schottky` PCell contains a built-in antenna diode placed in NWell, which the rule forbids (`dantenna in NWell not allowed`). Device-cell quirk, not a SPARX layout defect. |