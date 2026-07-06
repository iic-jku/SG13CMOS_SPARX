## ToDo List

- [ ] add GitHub action for checking license headers
    - https://github.com/aesc-silicon/ElemRV/blob/main/.github/workflows/license-check.yaml
    - https://github.com/aesc-silicon/ElemRV/blob/main/REUSE.toml
- [ ] update `sparx_powdet_sbd.sch` with new KLayout LVS (no `ntap` / `ptap` extraction)
- [ ] add regression test to IIC-OSIC-TOOLS repo
- [ ] fix top-level Ngspice testbench: @simi1505
- [ ] implement top-level VACASK testbench: @simi1505
- [ ] top-level LVS (labels on `*_top.gds` missing): @simi1505 & @davkel99
- [ ] KLayout LVS --> CMIM issues with PWell.block layer: see [IHP Open-PDK issue](https://github.com/IHP-GmbH/IHP-Open-PDK/issues/958) --> fixed with [IHP Open-PDK PR](https://github.com/IHP-GmbH/IHP-Open-PDK/pull/1030)
- [ ] more testing: @simi1505
- [ ] Change DBU from 5 nm to 1 nm in code: @davkel99
- [ ] Update GDSFactory IHP PDK `main` branch from `IHP-TO` branch: @davkel99
- [ ] Clean up private repo and add SPARX as module: @davkel99