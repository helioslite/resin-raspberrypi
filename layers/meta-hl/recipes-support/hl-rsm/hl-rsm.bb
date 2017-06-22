DESCRIPTION = "RSM (Reverse SSH Manager) client"
SECTION = "console/utils"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${RESIN_COREBASE}/COPYING.Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRC_URI = " \
    file://hl-rsm \
    file://hl-rsm.service \
    file://hl-rsm.timer \
    "

inherit allarch systemd

SYSTEMD_SERVICE_${PN} = " \
    hl-rsm.service \
    hl-rsm.timer \
    "
SYSTEMD_AUTO_ENABLE = "enable"

RDEPENDS_${PN} = " \
    bash \
    jq \
    "

FILES_${PN} += " \
     ${systemd_unitdir} \
     ${bindir} \
     "

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/hl-rsm ${D}${bindir}/hl-rsm

    if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
        install -d ${D}${systemd_unitdir}/system
        install -c -m 0644 ${WORKDIR}/hl-rsm.service ${D}${systemd_unitdir}/system
        install -c -m 0644 ${WORKDIR}/hl-rsm.timer ${D}${systemd_unitdir}/system
        sed -i -e 's,@BASE_BINDIR@,${base_bindir},g' \
            -e 's,@SBINDIR@,${sbindir},g' \
            -e 's,@BINDIR@,${bindir},g' \
            ${D}${systemd_unitdir}/system/*.service
    fi
}
