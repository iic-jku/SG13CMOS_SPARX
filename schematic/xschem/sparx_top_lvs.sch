v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
T {SPARX Top (for Top-Level LVS)} 870 -1720 0 0 1 1 {}
T {SPDX-FileCopyrightText: 2025-2026 The SPARX Team
SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
} 1920 -220 0 0 0.4 0.4 {}
N 1040 -1260 1200 -1260 {lab=#net1}
N 1200 -1260 1200 -940 {lab=#net1}
N 1040 -1300 1040 -1260 {lab=#net1}
N 1280 -1260 1440 -1260 {lab=vrf}
N 1280 -1260 1280 -940 {lab=vrf}
N 1440 -1300 1440 -1260 {lab=vrf}
N 1020 -1500 1020 -1460 {lab=vref1}
N 1060 -1500 1060 -1460 {lab=vout1}
N 1240 -1380 1380 -1380 {lab=vdd}
N 1420 -1500 1420 -1460 {lab=vout2}
N 1460 -1500 1460 -1460 {lab=vref2}
N 940 -1380 980 -1380 {lab=vss}
N 940 -1500 940 -1380 {lab=vss}
N 1500 -1380 1540 -1380 {lab=vss}
N 1540 -1500 1540 -1380 {lab=vss}
N 1240 -1500 1240 -1380 {lab=vdd}
N 1100 -1380 1240 -1380 {lab=vdd}
N 1280 -940 1720 -940 {lab=vrf}
N 1280 -860 1640 -860 {lab=#net2}
N 1280 -860 1280 -540 {lab=#net2}
N 1200 -860 1200 -540 {lab=#net1}
N 560 -900 720 -900 {lab=vlo}
N 1040 -540 1200 -540 {lab=#net1}
N 1040 -540 1040 -500 {lab=#net1}
N 1280 -540 1440 -540 {lab=#net2}
N 1440 -540 1440 -500 {lab=#net2}
N 1020 -340 1020 -300 {lab=vref3}
N 1060 -340 1060 -300 {lab=vout3}
N 1240 -420 1380 -420 {lab=vdd}
N 1420 -340 1420 -300 {lab=vout4}
N 1460 -340 1460 -300 {lab=vref4}
N 940 -420 980 -420 {lab=vss}
N 940 -420 940 -300 {lab=vss}
N 1500 -420 1540 -420 {lab=vss}
N 1540 -420 1540 -300 {lab=vss}
N 1240 -420 1240 -300 {lab=vdd}
N 1100 -420 1240 -420 {lab=vdd}
N 1640 -760 1640 -720 {lab=vss}
N 1640 -860 1640 -820 {lab=#net2}
N 1040 -940 1200 -940 {lab=#net1}
N 1000 -900 1040 -940 {lab=#net1}
N 1040 -860 1200 -860 {lab=#net1}
N 1000 -900 1040 -860 {lab=#net1}
N 760 -900 1000 -900 {lab=#net1}
N 560 -980 600 -980 {lab=vss}
N 560 -820 600 -820 {lab=vss}
N 1680 -1020 1720 -1020 {lab=vss}
N 1680 -860 1720 -860 {lab=vss}
C {ipin.sym} 1720 -940 2 0 {name=p2 lab=vrf}
C {opin.sym} 1060 -1500 3 0 {name=p3 lab=vout1}
C {iopin.sym} 1240 -1500 3 0 {name=p6 lab=vdd}
C {opin.sym} 1020 -1500 1 1 {name=p12 lab=vref1}
C {title-3.sym} 0 0 0 0 {name=l4 author="Simon Dorrer" rev=1.0 lock=true}
C {opin.sym} 1460 -1500 1 1 {name=p1 lab=vref2}
C {opin.sym} 1420 -1500 3 0 {name=p8 lab=vout2}
C {ipin.sym} 560 -900 0 0 {name=p11 lab=vlo}
C {iopin.sym} 940 -1500 3 0 {name=p15 lab=vss}
C {iopin.sym} 1540 -1500 3 0 {name=p16 lab=vss}
C {sparx_powdet_sbd.sym} 1040 -1380 1 1 {name=x1}
C {sparx_powdet_sbd.sym} 1440 -1380 3 0 {name=x2}
C {opin.sym} 1060 -300 3 1 {name=p21 lab=vout3}
C {iopin.sym} 1240 -300 3 1 {name=p22 lab=vdd}
C {opin.sym} 1020 -300 1 0 {name=p23 lab=vref3}
C {opin.sym} 1460 -300 1 0 {name=p24 lab=vref4}
C {opin.sym} 1420 -300 3 1 {name=p25 lab=vout4}
C {iopin.sym} 940 -300 3 1 {name=p26 lab=vss}
C {iopin.sym} 1540 -300 3 1 {name=p27 lab=vss}
C {sparx_powdet_sbd.sym} 1040 -420 1 0 {name=x3}
C {sparx_powdet_sbd.sym} 1440 -420 3 1 {name=x9}
C {sg13g2_pr/rsil.sym} 1640 -790 0 0 {name=R1
w=0.5e-6
l=2.5e-6
model=rsil
body=sub!
spiceprefix=X
 m=1
  mm_ok=1
value="expr_eng(  ( 9.0e-6 / @w + 7.0 * ( @l ) / ( @w + 1.0e-8 ) ) / @m  )"
}
C {lab_pin.sym} 1640 -720 3 0 {name=p19 sig_type=std_logic lab=vss
}
C {iopin.sym} 560 -980 2 0 {name=p5 lab=vss}
C {iopin.sym} 560 -820 2 0 {name=p7 lab=vss}
C {iopin.sym} 1720 -1020 2 1 {name=p4 lab=vss}
C {iopin.sym} 1720 -860 2 1 {name=p9 lab=vss}
