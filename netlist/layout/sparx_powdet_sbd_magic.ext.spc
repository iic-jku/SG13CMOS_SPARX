* NGSPICE file created from sparx_powdet_sbd.ext - technology: ihp-sg13g2

.subckt sparx_powdet_sbd vref vout vss vdd rfin
X0 vout dw_8122_4047# vdd vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X1 a_8474_2725# vss cap_cmim l=10u w=10u
X2 vout dw_8122_4047# vss vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X3 vdd vss cap_cmim l=10u w=10u
X4 vdd vss cap_cmim l=10u w=10u
X5 vss dw_8122_4047# vout vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X6 a_8474_2725# vss cap_cmim l=10u w=10u
X7 vdd vdd vdd vdd sg13_lv_pmos ad=0.95p pd=5.38u as=43.4451p ps=0.26832m w=5u l=0.13u
X8 a_8474_2725# vss cap_cmim l=10u w=10u
X9 a_8474_2725# vss cap_cmim l=10u w=10u
X10 vss dw_8122_4047# vout vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X11 vout dw_8122_4047# vdd vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X12 vdd vss cap_cmim l=10u w=10u
X13 vdd vss cap_cmim l=10u w=10u
X14 a_8474_2725# vss cap_cmim l=10u w=10u
X15 a_8474_2725# vss cap_cmim l=10u w=10u
X16 vout dw_8122_4047# vss vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X17 vout dw_8122_4047# vdd vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X18 vdd dw_9390_4047# vref vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X19 vout dw_8122_4047# vdd vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X20 vss dw_8122_4047# vout vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X21 vout dw_8122_4047# vss vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X22 vdd vss cap_cmim l=9u w=6.8u
X23 vdd vss cap_cmim l=10u w=10u
X24 vdd vss cap_cmim l=10u w=10u
X25 a_8474_2725# vss cap_cmim l=10u w=10u
X26 vout dw_8122_4047# vdd vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X27 a_8474_2725# vss cap_cmim l=10u w=10u
X28 vss dw_8122_4047# vout vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X29 vout dw_8122_4047# vss vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X30 a_8474_2725# vss cap_cmim l=10u w=10u
X31 vdd vss cap_cmim l=10u w=10u
X32 a_8474_2725# vss cap_cmim l=10u w=10u
X33 a_8474_2725# vss cap_cmim l=10u w=10u
X34 vss dw_8122_4047# vout vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X35 vdd vss cap_cmim l=10u w=10u
X36 a_8474_2725# vss cap_cmim l=10u w=10u
X37 a_8474_2725# vss cap_cmim l=10u w=10u
X38 rfin a_8232_4131# cap_cmim l=10u w=10u
X39 a_8474_2725# vss cap_cmim l=10u w=10u
X40 vdd vss cap_cmim l=10u w=10u
X41 a_8474_2725# vdd vss rhigh l=2u w=0.5u
X42 vout dw_8122_4047# vdd vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X43 a_8232_4131# dw_8122_4047# vss schottky_nbl1 l=1.2u w=2.655u
X44 vdd dw_8122_4047# vout vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X45 vss dw_8122_4047# vout vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X46 vdd vss cap_cmim l=10u w=10u
X47 vdd dw_8122_4047# vout vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X48 a_8474_2725# vss cap_cmim l=10u w=10u
X49 vout dw_8122_4047# vss vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X50 vss dw_8122_4047# vout vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X51 vout dw_8122_4047# vdd vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X52 a_9398_3295# a_8474_2725# vss rsil l=2.5u w=0.5u
X53 vref dw_9390_4047# vss vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X54 vdd vss cap_cmim l=10u w=10u
X55 vss dw_8122_4047# vout vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X56 dw_9390_4047# vref vss rppd l=1.5u w=0.5u
X57 vdd vss cap_cmim l=10u w=10u
X58 vdd dw_8122_4047# vout vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X59 vdd vss cap_cmim l=10u w=10u
X60 vout dw_8122_4047# vdd vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X61 vss vss vss vss sg13_lv_nmos ad=0.85p pd=5.68u as=46.1791p ps=0.2399m w=2.5u l=0.13u
X62 a_8474_2725# vss cap_cmim l=10u w=10u
X63 vdd dw_8122_4047# vout vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X64 vout dw_8122_4047# vdd vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X65 vss dw_8122_4047# vout vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X66 vdd vss cap_cmim l=10u w=10u
X67 vout dw_8122_4047# vss rppd l=1.5u w=0.5u
X68 vdd vss cap_cmim l=10u w=10u
X69 a_8474_2725# vss cap_cmim l=10u w=10u
X70 vdd vss cap_cmim l=10u w=10u
X71 a_8474_2725# vss cap_cmim l=10u w=10u
X72 vdd dw_8122_4047# vout vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X73 a_8474_2725# vss cap_cmim l=10u w=10u
X74 vss dw_8122_4047# vout vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X75 a_8474_2725# vss cap_cmim l=10u w=10u
X76 vdd vss cap_cmim l=10u w=10u
X77 a_8474_2725# vss cap_cmim l=10u w=10u
X78 vout dw_8122_4047# vss vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X79 a_8474_2725# vss cap_cmim l=10u w=10u
X80 vdd vss cap_cmim l=10u w=10u
X81 vdd dw_8122_4047# vout vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X82 vdd vss cap_cmim l=10u w=10u
X83 vss vss vss vss sg13_lv_nmos ad=0.475p pd=2.88u as=0 ps=0 w=2.5u l=0.13u
X84 a_8474_2725# vss cap_cmim l=10u w=10u
X85 vdd vss cap_cmim l=9u w=6.8u
X86 vout dw_8122_4047# vdd vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X87 vdd vss cap_cmim l=10u w=10u
X88 vdd dw_8122_4047# vout vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X89 vout dw_8122_4047# vss vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X90 a_8474_2725# vss cap_cmim l=10u w=10u
X91 vref dw_9390_4047# vdd vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X92 vout dw_8122_4047# vss vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X93 vdd dw_8122_4047# vout vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X94 vdd vss cap_cmim l=10u w=10u
X95 vdd vss cap_cmim l=10u w=10u
X96 vdd vss cap_cmim l=10u w=10u
X97 vdd vss cap_cmim l=10u w=10u
X98 vss dw_9390_4047# vref vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X99 a_8474_2725# vss cap_cmim l=10u w=10u
X100 a_8474_2725# vss cap_cmim l=10u w=10u
X101 vout dw_8122_4047# vss vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X102 a_8474_2725# vss cap_cmim l=10u w=10u
X103 a_8474_2725# vss cap_cmim l=10u w=10u
X104 vdd vss cap_cmim l=10u w=10u
X105 vdd vdd vdd vdd sg13_lv_pmos ad=1.7p pd=10.68u as=0 ps=0 w=5u l=0.13u
X106 a_8474_2725# vss cap_cmim l=10u w=10u
X107 vdd vss cap_cmim l=10u w=10u
X108 vdd vss cap_cmim l=10u w=10u
X109 vout dw_8122_4047# vss vss sg13_lv_nmos ad=0.475p pd=2.88u as=0.475p ps=2.88u w=2.5u l=0.13u
X110 vdd dw_8122_4047# vout vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
X111 a_8232_4131# a_8474_2725# vss rsil l=2.5u w=0.5u
X112 a_9398_3295# dw_9390_4047# vss schottky_nbl1 l=1.2u w=2.655u
X113 a_8474_2725# vss cap_cmim l=10u w=10u
X114 vdd vss cap_cmim l=10u w=10u
X115 vdd dw_8122_4047# vout vdd sg13_lv_pmos ad=0.95p pd=5.38u as=0.95p ps=5.38u w=5u l=0.13u
.ends

