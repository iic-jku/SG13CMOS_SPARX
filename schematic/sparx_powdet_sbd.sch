v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
B 4 1020 -880 1660 -500 {dash = 8
fill = false}
B 4 260 -880 820 -500 {dash = 8
fill = false}
B 4 1680 -880 2220 -500 {dash = 8
fill = false}
B 4 2240 -880 2460 -500 {dash = 8
fill = false}
T {Schottky Barrier Diode Based Power Detector} 620 -1720 0 0 1 1 {}
T {Circuit Operation:
- R1 provides a 50 Ω input termination.
- C1 ac-couples the RF + LO signal to the demodulating SBD D1 and is implemented as a MIM capacitor.
- M3–M4 and R2 form a transimpedance amplifier (TIA) that delivers a buffered voltage output.
- M1–M2, D2, and R3–R5 implement a replica bias. With this replica circuit, it is now possible to measure the demodulated output signal differentially.
- C2-C4 are MIM capacitor arrays which provide proper supply-rail decoupling.

Layout Considerations:
- Minimize RF input parasitics (R, L, C):
    - Route TopMetal2 directly down to the top plate (TopMetal1) of C1with a VIA.
    - Use a VIA-stack from the bottom plate (Metal5) of C1 directly down to the SBD.
- Apply Metal5 no-fill regions to reduce parasitic capacitance.
- Match components of the main and replica paths.
- C2–C4 values may be adapted to layout requirements, provided they remain large enough for sufficient supply-rail decoupling.} 80 -1600 0 0 0.6 0.6 {}
T {4mA} 680 -470 0 0 0.3 0.3 {}
T {400uA} 1170 -470 0 1 0.3 0.3 {}
T {nom. 1.5V} 100 -990 0 0 0.3 0.3 {}
T {1.128V} 350 -720 0 0 0.2 0.2 {}
T {0.737V} 1125 -720 0 1 0.2 0.2 {}
T {0.730V} 750 -720 0 1 0.2 0.2 {}
T {0.756V} 470 -720 0 0 0.2 0.2 {}
T {Replica Circuit} 1502.5 -530 0 0 0.4 0.4 {}
T {Power Detector Circuit} 267.5 -530 0 0 0.4 0.4 {}
T {Decoupling
Capacitors} 1962.5 -555 0 0 0.4 0.4 {}
T {Dummy
Transistors} 2262.5 -725 0 0 0.4 0.4 {}
T {1.129V} 350 -910 0 0 0.2 0.2 {}
T {0.761V} 1275 -720 0 1 0.2 0.2 {}
T {SPDX-FileCopyrightText: 2025-2026 The SPARX Team
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
} 1920 -230 0 0 0.4 0.4 {}
N 320 -770 320 -700 {lab=rfin_int}
N 320 -700 400 -700 {lab=rfin_int}
N 140 -960 700 -960 {lab=vdd}
N 2260 -840 2300 -840 {lab=vdd}
N 700 -840 760 -840 {lab=vdd}
N 700 -560 760 -560 {lab=vss}
N 560 -700 560 -560 {lab=bb_int}
N 660 -700 700 -700 {lab=vout}
N 700 -700 700 -590 {lab=vout}
N 700 -810 700 -700 {lab=vout}
N 700 -530 700 -480 {lab=vss}
N 560 -700 600 -700 {lab=bb_int}
N 560 -840 560 -700 {lab=bb_int}
N 560 -840 660 -840 {lab=bb_int}
N 560 -560 660 -560 {lab=bb_int}
N 700 -700 840 -700 {lab=vout}
N 460 -700 560 -700 {lab=bb_int}
N 700 -960 700 -870 {lab=vdd}
N 1140 -700 1140 -590 {lab=vref}
N 1080 -840 1140 -840 {lab=vdd}
N 1080 -560 1140 -560 {lab=vss}
N 1140 -810 1140 -700 {lab=vref}
N 1140 -700 1180 -700 {lab=vref}
N 1240 -700 1280 -700 {lab=bias2}
N 1180 -840 1280 -840 {lab=bias2}
N 1280 -840 1280 -700 {lab=bias2}
N 1280 -700 1280 -560 {lab=bias2}
N 1180 -560 1280 -560 {lab=bias2}
N 1140 -530 1140 -480 {lab=vss}
N 1140 -960 1140 -870 {lab=vdd}
N 1280 -700 1380 -700 {lab=bias2}
N 1440 -700 1520 -700 {lab=#net1}
N 1520 -770 1520 -700 {lab=#net1}
N 1000 -700 1140 -700 {lab=vref}
N 1760 -640 1760 -480 {lab=vss}
N 1760 -480 1940 -480 {lab=vss}
N 1940 -640 1940 -480 {lab=vss}
N 2120 -640 2120 -480 {lab=vss}
N 2260 -960 2340 -960 {lab=vdd}
N 1940 -960 1940 -700 {lab=vdd}
N 2120 -960 2120 -700 {lab=vdd}
N 140 -960 140 -920 {lab=vdd}
N 1760 -920 1760 -700 {lab=bias1}
N 1520 -920 1520 -830 {lab=bias1}
N 320 -920 1520 -920 {lab=bias1}
N 320 -920 320 -830 {lab=bias1}
N 260 -920 320 -920 {lab=bias1}
N 140 -920 200 -920 {lab=vdd}
N 1080 -960 1140 -960 {lab=vdd}
N 1080 -480 1140 -480 {lab=vss}
N 1420 -690 1420 -480 {lab=vss}
N 420 -690 420 -480 {lab=vss}
N 1140 -960 1940 -960 {lab=vdd}
N 1520 -920 1760 -920 {lab=bias1}
N 1940 -960 2120 -960 {lab=vdd}
N 1940 -480 2120 -480 {lab=vss}
N 2340 -560 2400 -560 {lab=vss}
N 2340 -840 2400 -840 {lab=vdd}
N 2260 -560 2300 -560 {lab=vss}
N 2260 -480 2340 -480 {lab=vss}
N 2340 -960 2340 -870 {lab=vdd}
N 2340 -810 2340 -780 {lab=vdd}
N 2260 -780 2340 -780 {lab=vdd}
N 2260 -840 2260 -780 {lab=vdd}
N 2340 -620 2340 -590 {lab=vss}
N 2260 -620 2340 -620 {lab=vss}
N 2260 -620 2260 -560 {lab=vss}
N 2260 -560 2260 -480 {lab=vss}
N 2340 -530 2340 -480 {lab=vss}
N 2120 -480 2260 -480 {lab=vss}
N 2260 -960 2260 -840 {lab=vdd}
N 2120 -960 2260 -960 {lab=vdd}
N 100 -700 160 -700 {lab=rfin}
N 100 -960 140 -960 {lab=vdd}
N 220 -700 320 -700 {lab=rfin_int}
N 420 -480 700 -480 {lab=vss}
N 1420 -480 1760 -480 {lab=vss}
N 2340 -960 2400 -960 {lab=vdd}
N 2400 -960 2400 -840 {lab=vdd}
N 2340 -480 2400 -480 {lab=vss}
N 2400 -560 2400 -480 {lab=vss}
N 1080 -960 1080 -840 {lab=vdd}
N 760 -960 1080 -960 {lab=vdd}
N 760 -960 760 -840 {lab=vdd}
N 700 -960 760 -960 {lab=vdd}
N 1080 -560 1080 -480 {lab=vss}
N 760 -480 1080 -480 {lab=vss}
N 760 -560 760 -480 {lab=vss}
N 700 -480 760 -480 {lab=vss}
N 1140 -480 1420 -480 {lab=vss}
N 100 -480 420 -480 {lab=vss}
C {ipin.sym} 100 -700 0 0 {name=p2 lab=rfin}
C {opin.sym} 840 -700 0 0 {name=p3 lab=vout}
C {iopin.sym} 100 -480 0 1 {name=p4 lab=vss}
C {rsil.sym} 320 -800 0 0 {name=R1
w=0.5e-6
l=2.5e-6
model=rsil
body=vss
spiceprefix=X
b=0
m=1
}
C {schottky_nbl1.sym} 430 -700 1 0 {name=D1
model=schottky_nbl1
Nx=1
Ny=1
spiceprefix=X
}
C {lab_wire.sym} 320 -700 0 0 {name=p5 sig_type=std_logic lab=rfin_int}
C {iopin.sym} 100 -960 2 0 {name=p6 lab=vdd}
C {cap_cmim.sym} 1760 -670 0 0 {name=C2
model=cap_cmim
w=10e-6
l=10e-6
m=30
spiceprefix=X}
C {annotate_fet_params.sym} 1030 -420 0 0 {name=annot1 ref=M1}
C {annotate_fet_params.sym} 1190 -420 0 0 {name=annot2 ref=M2}
C {opin.sym} 1000 -700 0 1 {name=p12 lab=vref}
C {sg13_lv_pmos.sym} 680 -840 0 0 {name=M4
l=0.13u
w=100u
ng=20
m=1
model=sg13_lv_pmos
spiceprefix=X
}
C {sg13_lv_nmos.sym} 680 -560 0 0 {name=M3
l=0.13u
w=50u
ng=20
m=1
model=sg13_lv_nmos
spiceprefix=X
}
C {rppd.sym} 630 -700 1 0 {name=R2
w=0.5e-6
l=1.5e-6
model=rppd
body=vss
spiceprefix=X
b=0
m=1
}
C {sg13_lv_pmos.sym} 1160 -840 0 1 {name=M2
l=0.13u
w=10u
ng=2
m=1
model=sg13_lv_pmos
spiceprefix=X
}
C {sg13_lv_nmos.sym} 1160 -560 0 1 {name=M1
l=0.13u
w=5u
ng=2
m=1
model=sg13_lv_nmos
spiceprefix=X
}
C {cap_cmim.sym} 1940 -670 0 0 {name=C3
model=cap_cmim
w=10e-6
l=10e-6
m=28
spiceprefix=X}
C {lab_wire.sym} 560 -700 0 0 {name=p7 sig_type=std_logic lab=bb_int}
C {annotate_fet_params.sym} 590 -420 0 0 {name=annot3 ref=M3}
C {annotate_fet_params.sym} 740 -420 0 0 {name=annot4 ref=M4}
C {schottky_nbl1.sym} 1410 -700 3 1 {name=D2
model=schottky_nbl1
Nx=1
Ny=1
spiceprefix=X
}
C {rhigh.sym} 230 -920 1 0 {name=R3
w=0.5e-6
l=2e-6
model=rhigh
body=vss
spiceprefix=X
b=0
m=1
}
C {lab_wire.sym} 320 -920 0 1 {name=p9 sig_type=std_logic lab=bias1}
C {rppd.sym} 1210 -700 3 1 {name=R4
w=0.5e-6
l=1.5e-6
model=rppd
body=vss
spiceprefix=X
b=0
m=1
}
C {rsil.sym} 1520 -800 0 0 {name=R5
w=0.5e-6
l=2.5e-6
model=rsil
body=vss
spiceprefix=X
b=0
m=1
}
C {lab_wire.sym} 1280 -700 0 1 {name=p11 sig_type=std_logic lab=bias2}
C {sg13_lv_nmos.sym} 2320 -560 0 0 {name=Mdummy1
l=0.13u
w=5u
ng=2
m=1
model=sg13_lv_nmos
spiceprefix=X
}
C {sg13_lv_pmos.sym} 2320 -840 0 0 {name=Mdummy2
l=0.13u
w=10u
ng=2
m=1
model=sg13_lv_pmos
spiceprefix=X
}
C {cap_cmim.sym} 190 -700 3 1 {name=C1
model=cap_cmim
w=10e-6
l=10e-6
m=1
spiceprefix=X}
C {cap_cmim.sym} 2120 -670 0 0 {name=C4
model=cap_cmim
w=6.8e-6
l=9e-6
m=2
spiceprefix=X}
C {title-3.sym} 0 0 0 0 {name=l4 author="(c) 2026 H. Pretl, ICD@JKU" rev=1.0 lock=true}
