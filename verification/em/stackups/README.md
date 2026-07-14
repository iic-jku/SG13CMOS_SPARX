# Overview of the XML files

Origin repository: <https://github.com/VolkerMuehlhaus/gds2palace_ihp_sg13g2>

## Short answer

All eight `.xml` files in the origin repository's `workflow/` folder (seven of them are copied into this folder, `pcb_ro4003.xml` is not) are the **same kind of file: technology stackup definitions**.
They are not different formats or different roles. They are variants of one schema
(`<Stackup schemaVersion="2.0">`), each describing a different substrate/BEOL configuration.
A model script picks exactly one of them:

```python
XML_filename = "SG13G2_200um.xml"   # stackup
```

They fall into **three families**:

| Family | Files | What it is |
|---|---|---|
| **SG13G2** | `SG13G2_200um`, `SG13G2_100um`, `SG13G2_nosub` | IHP 130 nm SiGe:C BiCMOS (`ihp-sg13g2`). Full BEOL: Metal1–5, TopMetal1/2, MIM. |
| **SG13CMOS5L** | `SG13CMOS5L_200um`, `SG13CMOS5L_300um`, `SG13CMOS5L_200um_backsideGND`, `SG13CMOS5L_nosub` | A **different IHP PDK** (`ihp-sg13cmos5l`): 130 nm plain CMOS with an M1–M4–TM1 metal stack. Also shipped in IIC-OSIC-TOOLS. |
| **PCB** | `pcb_ro4003` | Not an IC at all, but a 2-layer Rogers RO4003 board. |

Within a family, the files differ **only in what is below the BEOL** (and how much air is above).

## What the XML actually contains

Parsed by `gds2palace/util_stackup_reader.py::read_substrate()`. Three sections:

| Section | Purpose |
|---|---|
| `<Materials>` | Named materials with `Type` (Conductor / Dielectric / Semiconductor), `Permittivity`, `DielectricLossTangent`, `Conductivity`, display `Color`. E.g. `TopMetal2` σ = 30.3 MS/m, `SiO2` εr = 4.1, `Substrate` εr = 11.9 / σ = 2 S/m. |
| `<Dielectrics>` | The vertical dielectric stack, **ordered top to bottom**, each with a `Thickness` in µm. This builds the simulation box. |
| `<Layers>` | The GDS layer to physical layer mapping: `Layer=` is the GDSII layer number, `Type=` is `conductor` / `via` / `dielectric`, plus `Zmin` / `Zmax` and the `Material`. Preceded by `<Substrate Offset="..."/>`, which shifts all metal z-coordinates so that z = 0 in the layer table (wafer surface) lands at the correct absolute height inside the dielectric stack. |

So in one sentence: **materials + z-geometry + GDS layer map.**
Same idea as the openEMS IHP XML files. The origin repository notes they are similar but
differ in details to enable Palace-specific "tricks".

### Example excerpt

```xml
<Stackup schemaVersion="2.0">
  <Materials>
    <Material Name="TopMetal2" Type="Conductor" Permittivity="1"
              DielectricLossTangent="0" Conductivity="30300000.0" Color="ff8000"/>
    <Material Name="Substrate" Type="Semiconductor" Permittivity="11.9"
              DielectricLossTangent="0" Conductivity="2.0" Color="01e0ff"/>
  </Materials>
  <ELayers LengthUnit="um">
    <Dielectrics>
      <Dielectric Name="AIR"       Material="AIR"       Thickness="200.0000"/>
      <Dielectric Name="Passive"   Material="Passive"   Thickness="0.4000"/>
      <Dielectric Name="SiO2"      Material="SiO2"      Thickness="15.7303"/>
      <Dielectric Name="EPI"       Material="EPI"       Thickness="3.7500"/>
      <Dielectric Name="Substrate" Material="Substrate" Thickness="180.0000"/>
    </Dielectrics>
    <Layers>
      <Substrate Offset="183.75"/>
      <Layer Name="TopMetal2" Type="conductor" Zmin="11.2303" Zmax="14.2303"
             Material="TopMetal2" Layer="134"/>
      <Layer Name="TopVia2"   Type="via"       Zmin="8.4303"  Zmax="11.2303"
             Material="TopVia2"  Layer="133"/>
      ...
    </Layers>
  </ELayers>
</Stackup>
```

### Special "magic" GDS layers

Layers you can draw in your layout and that the stackup maps to non-PDK objects:

| Name | GDS layer | Meaning |
|---|---|---|
| `SUBGND` | 250 (SG13G2) / 210 (CMOS5L) | Ideal ground plate directly under the EPI, material `LOWLOSS` (σ = 1e10). |
| `BACKSIDEGND` | 251 | Ideal ground plane on the wafer backside. |
| `LBE` | 157 | Filled with `AIR` (local backside etch). Drawing it carves the silicon away. |

## The eight files

| File | Technology / BEOL | Substrate below the BEOL | Air above |
|---|---|---|---|
| `SG13G2_200um.xml` | Full SG13G2: Metal1–5, TopMetal1/2, MIM + Vmim (BEOL ≈ 16.1 µm) | EPI 3.75 µm + Si 180 µm (200 µm total) | 200 µm |
| `SG13G2_100um.xml` | same | EPI 3.75 µm + Si 80 µm (≈ 100 µm, thinned wafer) | 200 µm |
| `SG13G2_nosub.xml` | same | **none**, replaced by a 2 µm SiO₂ "Spacing" (no EPI, no Si, no `SUBGND` / `BACKSIDEGND` / `LBE`) | 300 µm |
| `SG13CMOS5L_200um.xml` | 5-metal option: Metal1–4 + TopMetal1 only, **no Metal5, no TopMetal2, no MIM**, thinner oxide (8.9 µm) | EPI 3.75 µm + Si 186.95 µm | 300 µm |
| `SG13CMOS5L_300um.xml` | same | Si 286.95 µm (≈ 300 µm) | 300 µm |
| `SG13CMOS5L_200um_backsideGND.xml` | same | 200 µm Si **plus a 1 µm `LOWLOSS` backside metal dielectric block** (ground plane on the wafer back, no GDS layer needed) | 300 µm |
| `SG13CMOS5L_nosub.xml` | same | **none**, 2 µm SiO₂ spacing only | 300 µm |
| `pcb_ro4003.xml` | Not an IC at all: 2-layer Rogers RO4003 PCB (εr = 3.38, tanδ = 0.0022), 510 µm core, 17 µm copper top and bottom | n/a | n/a |

## SG13G2 substrate variants at a glance

![Substrate variants of the SG13G2 stackup XML files](sg13g2_stackup_variants.svg)

*Cross-sections (not to scale). All three SG13G2 variants share the same BEOL. They differ only in
what sits below it and how much air sits above.*

## SG13CMOS5L variants at a glance

![The four SG13CMOS5L stackup XML variants](sg13cmos5l_stackup_variants.svg)

*Cross-sections (not to scale). Note the BEOL itself is different from SG13G2. This is a separate
PDK, which is why the two families cannot be shown in one figure.*

## Default stackup

The repository **never declares a default**. There is no `default` keyword, no fallback inside
`read_substrate()`, and `workflow/README.md` does not rank the files. Every model script must name
one explicitly:

```python
XML_filename = "SG13G2_200um.xml"   # stackup
```

What does exist is a *de-facto* default, taken from the examples:

| PDK | De-facto default | Reasoning |
|---|---|---|
| **SG13G2** | `SG13G2_200um.xml` | Used by every substrate-aware example (`palace_L2n0`, `palace_ind_frame`, `palace_rfcmim`, `inductor_500pH_2port`). Full BEOL on 200 µm silicon. |
| **SG13CMOS5L** | `SG13CMOS5L_200um.xml` | No example uses any CMOS5L stackup, so this is by analogy: it is the plain on-wafer case, and the other three are derived from it (300 µm = thicker Si, `backsideGND` = + ideal ground plate, `nosub` = Si removed). |

**Caveat:** the 100 / 200 / 300 µm numbers are *modelling truncations* of the silicon, not the
physical wafer thickness. With the default `ABC` boundary at `zmin`, the value decides how much
lossy silicon (σ = 2 S/m) is inside the simulation domain. A thicker value captures more substrate
loss, but leads to a larger mesh and a slower simulation.

## Which examples use which

| Model script | Stackup |
|---|---|
| `palace_line_viaport.py`, `palace_line_noGDS.py`, `palace_balun_mesh5.py`, `palace_butlermatrix.py`, `palace_butlermatrix_dump93.py` | `SG13G2_nosub.xml` |
| `palace_L2n0.py`, `palace_ind_frame.py`, `palace_rfcmim.py`, `inductor_500pH_2port.py` | `SG13G2_200um.xml` |
| `palace_core.py` | `SG13G2_100um.xml` |
| `palace_pcb_lowpass.py` | `pcb_ro4003.xml` |

None of the `SG13CMOS5L_*.xml` files is referenced by any example. They are provided for the
5-metal flavour if you need it.

## How to choose

- **Transmission lines, baluns, Butler matrices**, and anything else with a solid Metal1 ground
  plane underneath: use **`nosub`**. The ground shields the silicon, so removing it costs almost
  nothing in accuracy and saves a lot of mesh. The user's guide explicitly notes the
  with/without-substrate difference was verified negligible for their line models.
- **Inductors, MIM caps**, and anything where substrate loss or coupling matters: use **`200um`**
  (or `100um` for a thinned wafer).
- Add `SUBGND` / `BACKSIDEGND` / `LBE` polygons to your GDS **only** if the chosen stackup declares
  those layers (`nosub` deliberately drops them).

## One inconsistency worth knowing

In the SG13G2 files `LBE` is declared `Type="dielectric"`, while in the older CMOS5L files it is
`Type="via"` with material `AIR`. The reader supports both (`is_dielectric` / `is_via`), but the
SG13G2 form is the cleaner one to copy if you write your own stackup.

---
