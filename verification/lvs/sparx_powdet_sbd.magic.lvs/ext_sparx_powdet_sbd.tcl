crashbackups stop
drc off
gds read /foss/designs/SG13CMOS_SPARX/layout/sparx_powdet_sbd.gds
if {[lsearch [cellname list topcells] {sparx_powdet_sbd}] < 0} {
    set _fp [open {/foss/designs/SG13CMOS_SPARX/verification/lvs/sparx_powdet_sbd.magic.lvs/ext_sparx_powdet_sbd.cellmismatch} w]
    puts $_fp [cellname list topcells]
    close $_fp
    quit -noprompt
}
load sparx_powdet_sbd
select top cell
flatten sparx_powdet_sbd_flat
load sparx_powdet_sbd_flat
cellname delete sparx_powdet_sbd
cellname rename sparx_powdet_sbd_flat sparx_powdet_sbd
select top cell
extract path /foss/designs/SG13CMOS_SPARX/verification/lvs/sparx_powdet_sbd.magic.lvs
extract no capacitance
extract no coupling
extract no resistance
extract no length
extract all
ext2spice lvs
ext2spice -p /foss/designs/SG13CMOS_SPARX/verification/lvs/sparx_powdet_sbd.magic.lvs -o /foss/designs/SG13CMOS_SPARX/verification/lvs/sparx_powdet_sbd.magic.lvs/sparx_powdet_sbd.ext.spc
quit -noprompt
