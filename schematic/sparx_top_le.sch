v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
T {SPARX Top} 1110 -1720 0 0 1 1 {}
T {SPDX-FileCopyrightText: 2025-2026 The SPARX Team
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1} 1920 -220 0 0 0.4 0.4 {}
N 1040 -1160 1200 -1160 {lab=#net1}
N 1040 -1200 1040 -1160 {lab=#net1}
N 1440 -1200 1440 -1160 {lab=#net2}
N 1020 -1400 1020 -1360 {lab=vref1}
N 1060 -1400 1060 -1360 {lab=vout1}
N 1420 -1400 1420 -1360 {lab=vout2}
N 1460 -1400 1460 -1360 {lab=vref2}
N 940 -1280 980 -1280 {lab=vss}
N 940 -1400 940 -1280 {lab=vss}
N 1500 -1280 1540 -1280 {lab=vss}
N 1540 -1400 1540 -1280 {lab=vss}
N 1040 -640 1200 -640 {lab=#net3}
N 1040 -640 1040 -600 {lab=#net3}
N 1280 -640 1440 -640 {lab=#net4}
N 1440 -640 1440 -600 {lab=#net4}
N 1020 -440 1020 -400 {lab=vref3}
N 1060 -440 1060 -400 {lab=vout3}
N 1420 -440 1420 -400 {lab=vout4}
N 1460 -440 1460 -400 {lab=vref4}
N 940 -520 980 -520 {lab=vss}
N 940 -520 940 -400 {lab=vss}
N 1500 -520 1540 -520 {lab=vss}
N 1540 -520 1540 -400 {lab=vss}
N 1460 -760 1460 -720 {lab=vss}
N 1460 -860 1460 -820 {lab=#net5}
N 1240 -520 1380 -520 {lab=vdd}
N 1240 -520 1240 -400 {lab=vdd}
N 1100 -520 1240 -520 {lab=vdd}
N 1240 -1280 1380 -1280 {lab=vdd}
N 1240 -1400 1240 -1280 {lab=vdd}
N 1100 -1280 1240 -1280 {lab=vdd}
N 940 -980 980 -980 {lab=vss}
N 940 -820 980 -820 {lab=vss}
N 1500 -860 1540 -860 {lab=vss}
N 1500 -1020 1540 -1020 {lab=vss}
N 1360 -940 1540 -940 {lab=vrf}
N 1360 -860 1460 -860 {lab=#net5}
N 940 -900 1120 -900 {lab=vlo}
N 1280 -800 1280 -640 {lab=#net4}
N 1200 -800 1200 -640 {lab=#net3}
N 1280 -1160 1440 -1160 {lab=#net2}
N 1200 -1160 1200 -1000 {lab=#net1}
N 1280 -1160 1280 -1000 {lab=#net2}
C {ipin.sym} 1540 -940 2 0 {name=p2 lab=vrf}
C {opin.sym} 1060 -1400 3 0 {name=p3 lab=vout1}
C {iopin.sym} 1240 -1400 3 0 {name=p6 lab=vdd}
C {opin.sym} 1020 -1400 1 1 {name=p12 lab=vref1}
C {title-3.sym} 0 0 0 0 {name=l4 author="Simon Dorrer" rev=1.0 lock=true}
C {opin.sym} 1460 -1400 1 1 {name=p1 lab=vref2}
C {opin.sym} 1420 -1400 3 0 {name=p8 lab=vout2}
C {ipin.sym} 940 -900 0 0 {name=p11 lab=vlo}
C {iopin.sym} 940 -1400 3 0 {name=p15 lab=vss}
C {iopin.sym} 1540 -1400 3 0 {name=p16 lab=vss}
C {sparx_powdet_sbd.sym} 1040 -1280 1 1 {name=x1}
C {sparx_powdet_sbd.sym} 1440 -1280 3 0 {name=x2}
C {opin.sym} 1060 -400 3 1 {name=p21 lab=vout3}
C {iopin.sym} 1240 -400 3 1 {name=p22 lab=vdd}
C {opin.sym} 1020 -400 1 0 {name=p23 lab=vref3}
C {opin.sym} 1460 -400 1 0 {name=p24 lab=vref4}
C {opin.sym} 1420 -400 3 1 {name=p25 lab=vout4}
C {iopin.sym} 940 -400 3 1 {name=p26 lab=vss}
C {iopin.sym} 1540 -400 3 1 {name=p27 lab=vss}
C {sparx_powdet_sbd.sym} 1040 -520 1 0 {name=x3}
C {sparx_powdet_sbd.sym} 1440 -520 3 1 {name=x9}
C {sg13g2_pr/rsil.sym} 1460 -790 0 0 {name=R1
w=0.5e-6
l=2.5e-6
model=rsil
body=VSS
spiceprefix=X
 m=1
  mm_ok=1
value="expr_eng(  ( 9.0e-6 / @w + 7.0 * ( @l ) / ( @w + 1.0e-8 ) ) / @m  )"
}
C {lab_pin.sym} 1460 -720 3 0 {name=p19 sig_type=std_logic lab=vss
}
C {iopin.sym} 940 -980 2 0 {name=p4 lab=vss}
C {iopin.sym} 940 -820 2 0 {name=p5 lab=vss}
C {iopin.sym} 1540 -860 0 0 {name=p9 lab=vss}
C {iopin.sym} 1540 -1020 0 0 {name=p10 lab=vss}
C {sparx_core_le.sym} 1240 -900 0 0 {name=x4}
