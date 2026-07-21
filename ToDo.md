## ToDo List

- [ ] add further VACASK testbenches
- [ ] Currently, in `em/scripts` there are four Python scripts that generate layout + ports for EM simulation. In the future, this should be included in `six_port_gen.py` so that every parameter is the same for the final layout and the EM simulation layouts. This will be changed when the EM simulation scripts are present in the IHP-GDSFactory-Addon repo. With that, in the SPARX repo, only the SPARX-specific structures are exported / simulated, and in the IHP-GDSFactory-Addon repo, one can play around with the parameters.: @simi1505 & @davkel99
- [ ] `klayout-drc` / `klayout-drc-regular` is not clean, issue with R + SBD (fix upstream): @simi1505
- [ ] top-level LVS: see [issue](https://github.com/IHP-GmbH/IHP-Open-PDK/issues/1041) for `Rmetal`: @simi1505