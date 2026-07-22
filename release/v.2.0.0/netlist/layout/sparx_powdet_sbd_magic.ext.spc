* NGSPICE file created from sparx_powdet_sbd.ext - technology: ihp-sg13g2

.subckt sparx_powdet_sbd vref vout vss vdd rfin
X0 vdd vss cap_cmim l=10u w=10u
X1 vss dw_8122_3287# vout vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X2 vout dw_8122_3287# vdd vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X3 vss dw_8122_3287# vout vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X4 vdd vss cap_cmim l=10u w=10u
X5 a_8474_1965# vss cap_cmim l=10u w=10u
X6 vout dw_8122_3287# vdd vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X7 vdd dw_9390_3287# vref vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X8 vss dw_8122_3287# vout vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X9 a_9398_2535# dw_9390_3287# vss schottky_nbl1 l=1.2u w=2.655u
X10 vout dw_8122_3287# vdd vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X11 a_8474_1965# vss cap_cmim l=10u w=10u
X12 vdd vss cap_cmim l=10u w=10u
X13 vdd vss cap_cmim l=10u w=10u
X14 vdd vss cap_cmim l=10u w=10u
X15 a_8474_1965# vss cap_cmim l=10u w=10u
X16 vout dw_8122_3287# vss vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X17 a_8474_1965# vss cap_cmim l=10u w=10u
X18 vout dw_8122_3287# vdd vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X19 vdd vss cap_cmim l=10u w=10u
X20 vdd vss cap_cmim l=10u w=10u
X21 a_8474_1965# vss cap_cmim l=10u w=10u
X22 vout dw_8122_3287# vss vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X23 vdd vss cap_cmim l=9u w=6.8u
X24 vdd vss cap_cmim l=10u w=10u
X25 vdd vss cap_cmim l=10u w=10u
X26 vss dw_8122_3287# vout vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X27 a_8474_1965# vss cap_cmim l=10u w=10u
X28 a_8474_1965# vss cap_cmim l=10u w=10u
X29 a_8474_1965# vss cap_cmim l=10u w=10u
X30 vout dw_8122_3287# vdd vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X31 a_8474_1965# vss cap_cmim l=10u w=10u
X32 vss vss vss vss sg13_lv_nmos ad=0.475p pd=2.88u as=46.1791p ps=0.2399m w=2.5u l=0.13u
X33 vdd vss cap_cmim l=9u w=6.8u
X34 vdd vss cap_cmim l=10u w=10u
X35 vdd vss cap_cmim l=10u w=10u
X36 vdd dw_8122_3287# vout vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X37 vdd vss cap_cmim l=10u w=10u
X38 a_8474_1965# vss cap_cmim l=10u w=10u
X39 vss dw_8122_3287# vout vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X40 a_8474_1965# vdd vss rhigh l=2u w=0.5u
X41 vdd dw_8122_3287# vout vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X42 vout dw_8122_3287# vss vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X43 a_8474_1965# vss cap_cmim l=10u w=10u
X44 vdd vss cap_cmim l=10u w=10u
X45 vdd vss cap_cmim l=10u w=10u
X46 vss dw_8122_3287# vout vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X47 a_8474_1965# vss cap_cmim l=10u w=10u
X48 vdd vss cap_cmim l=10u w=10u
X49 a_8474_1965# vss cap_cmim l=10u w=10u
X50 vref dw_9390_3287# vss vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X51 a_8474_1965# vss cap_cmim l=10u w=10u
X52 vdd vss cap_cmim l=10u w=10u
X53 vout dw_8122_3287# vss vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X54 rfin a_8232_3371# cap_cmim l=10u w=10u
X55 dw_9390_3287# vref vss rppd l=1.5u w=0.5u
X56 vdd vss cap_cmim l=10u w=10u
X57 vdd dw_8122_3287# vout vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X58 a_9398_2535# a_8474_1965# vss rsil l=2.5u w=0.5u
X59 vss dw_8122_3287# vout vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X60 a_8474_1965# vss cap_cmim l=10u w=10u
X61 vdd vss cap_cmim l=10u w=10u
X62 vdd dw_8122_3287# vout vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X63 vout dw_8122_3287# vdd vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X64 vss vss vss vss sg13_lv_nmos ad=0.85p pd=5.68u as=0 ps=0 w=2.5u l=0.13u
X65 vdd vss cap_cmim l=10u w=10u
X66 vdd vss cap_cmim l=10u w=10u
X67 a_8232_3371# dw_8122_3287# vss schottky_nbl1 l=1.2u w=2.655u
X68 vout dw_8122_3287# vss rppd l=1.5u w=0.5u
X69 vout dw_8122_3287# vdd vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X70 vss dw_8122_3287# vout vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X71 a_8474_1965# vss cap_cmim l=10u w=10u
X72 vdd dw_8122_3287# vout vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X73 a_8474_1965# vss cap_cmim l=10u w=10u
X74 vss dw_8122_3287# vout vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X75 vout dw_8122_3287# vss vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X76 a_8474_1965# vss cap_cmim l=10u w=10u
X77 a_8474_1965# vss cap_cmim l=10u w=10u
X78 vdd vss cap_cmim l=10u w=10u
X79 a_8474_1965# vss cap_cmim l=10u w=10u
X80 a_8474_1965# vss cap_cmim l=10u w=10u
X81 vout dw_8122_3287# vss vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X82 vdd dw_8122_3287# vout vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X83 vdd vss cap_cmim l=10u w=10u
X84 vout dw_8122_3287# vdd vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X85 vout dw_8122_3287# vss vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X86 vdd dw_8122_3287# vout vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X87 a_8474_1965# vss cap_cmim l=10u w=10u
X88 a_8474_1965# vss cap_cmim l=10u w=10u
X89 vref dw_9390_3287# vdd vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X90 vout dw_8122_3287# vss vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X91 vdd vdd vdd vdd sg13_lv_pmos ad=0.95p pd=5.38u as=43.4451p ps=0.26832m w=5u l=0.13u
X92 vss dw_9390_3287# vref vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X93 vdd vss cap_cmim l=10u w=10u
X94 vdd dw_8122_3287# vout vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X95 a_8474_1965# vss cap_cmim l=10u w=10u
X96 a_8474_1965# vss cap_cmim l=10u w=10u
X97 vdd vss cap_cmim l=10u w=10u
X98 a_8474_1965# vss cap_cmim l=10u w=10u
X99 a_8474_1965# vss cap_cmim l=10u w=10u
X100 a_8474_1965# vss cap_cmim l=10u w=10u
X101 vdd vss cap_cmim l=10u w=10u
X102 vdd vdd vdd vdd sg13_lv_pmos ad=1.7p pd=10.68u as=0 ps=0 w=5u l=0.13u
X103 vout dw_8122_3287# vdd vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X104 vout dw_8122_3287# vss vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X105 vdd dw_8122_3287# vout vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X106 vdd vss cap_cmim l=10u w=10u
X107 a_8474_1965# vss cap_cmim l=10u w=10u
X108 a_8232_3371# a_8474_1965# vss rsil l=2.5u w=0.5u
X109 vdd vss cap_cmim l=10u w=10u
X110 vdd dw_8122_3287# vout vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X111 vout dw_8122_3287# vdd vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X112 vout dw_8122_3287# vss vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X113 a_8474_1965# vss cap_cmim l=10u w=10u
X114 vdd vss cap_cmim l=10u w=10u
X115 vss dw_8122_3287# vout vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
.ends

