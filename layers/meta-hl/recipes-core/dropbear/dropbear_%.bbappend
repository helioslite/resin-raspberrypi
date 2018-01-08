FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://hl-id-rsa-rsm-dropbear \
    file://hl-id-rsa-rsm-pub \
    file://hl-authorized-keys \
    file://hl-known-hosts \
    file://hl-sync-keys \
    file://hl-sync-keys.service \
    "

SYSTEMD_SERVICE_${PN} += "hl-sync-keys.service"

FILES_${PN} += " \
     ${systemd_unitdir} \
     ${bindir} \
     "/home/root/.ssh/" \
     "

RDEPENDS_${PN} += "bash"

do_install_append() {
    install -d ${D}/home/root/.ssh

    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/hl-sync-keys ${D}${bindir}

    mkdir -p ${D}/home/root/.ssh/
    mkdir -p ${D}${localstatedir}/lib/dropbear/ # This will enable the authorized keys to be updated even when the device has read_only root.
    install -m 0600 ${WORKDIR}/hl-authorized-keys ${D}/${localstatedir}/lib/dropbear/authorized_keys
    ln -sf ${localstatedir}/lib/dropbear/authorized_keys ${D}/home/root/.ssh/authorized_keys

    install -m 0600 ${WORKDIR}/hl-id-rsa-rsm-dropbear ${D}/home/root/.ssh/id_rsa_rsm_dropbear
    install -m 0644 ${WORKDIR}/hl-id-rsa-rsm-pub ${D}/home/root/.ssh/id_rsa_rsm.pub
    install -m 0644 ${WORKDIR}/hl-known-hosts ${D}/home/root/.ssh/known_hosts

    if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
        install -d ${D}${systemd_unitdir}/system
        install -c -m 0644 ${WORKDIR}/hl-sync-keys.service ${D}${systemd_unitdir}/system

        sed -i -e 's,@BASE_BINDIR@,${base_bindir},g' \
            -e 's,@SBINDIR@,${sbindir},g' \
            -e 's,@BINDIR@,${bindir},g' \
            ${D}${systemd_unitdir}/system/*.service
    fi
}
