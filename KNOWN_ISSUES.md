# SPARX Known Issues

## KLayout Regular DRC

`klayout-drc-regular` is not clean due to antenna check violations. IHP has waived these DRC errors during the March 2026 tapeout. `make klayout-drc` (`macro` level) is clean. The 33 violations on `sparx160_top` are:

| Rule(s) | Count | Root cause |
| --- | :---: | --- |
| `Ant.e_Metal5`, `Ant.e_TopMetal1`, `Ant.e_TopMetal2` | 24 | Large RF/supply metal (incl. the M5 ground plane on `vss`) connects to the power-detector MOS gates (`MM1`–`MM4` and the `MMdummy*` devices, whose gates tie directly to `vdd`/`vss`), so the cumulative-metal-to-gate-area ratio exceeds 20000. |
| `Ant.f_TopVia2` | 8 | Same nets as above. Cumulative TopVia2-to-gate-area ratio exceeds 500. |
| `Ant.h` | 1 | The `schottky` PCell contains a built-in antenna diode placed in NWell, which the rule forbids (`dantenna in NWell not allowed`). Device-cell quirk, not a SPARX layout defect. |

## gdscheck DRC

`make gdscheck-drc` (`macro` level, suite `core`) is not clean with gdscheck 0.2.0, while `make klayout-drc` is. It reports 8 `nSDB.e` on `sparx160_top` and 2 on `sparx_powdet_sbd`, all on the contact of the `schottky` PCell, which draws `nSD.block` over `Cont` as part of the device. gdscheck checks `nSD.block` against every contact, while the KLayout deck leaves this device out of the rule, so the report is false and has to be fixed in gdscheck ([gdscheck issue 53](https://github.com/aesc-silicon/gdscheck/issues/53)). Until then it stops `make all`.

`make gdscheck-drc-regular` (suite `main`) adds 8 `Ant.e`, 8 `Ant.f` and 8 `Ant.h` on `sparx160_top`, the rules of the table above.

## Magic DRC

`make magic-drc` is not clean. It reports 976 `MIM.e` and 38 `MIM.i` on `sparx160_top`, and 244 `MIM.e` and 9 `MIM.i` on `sparx_powdet_sbd`. KLayout reports no `MIM.e`, also at `regular` level, so the Magic rule is the suspect. `MIM.i` is in no KLayout deck, so it has no second opinion. The flows leave the Magic DRC out until these are settled, its lines are commented out in `magic-verify` and `make all`.
