
FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

# By default no docker image in the data disk
TARGET_REPOSITORY_armv6 = "helioslite/armv6hf-supervisor"
TARGET_REPOSITORY_armv7a = "helioslite/armv7hf-supervisor"
TARGET_REPOSITORY_armv7ve = "helioslite/armv7hf-supervisor"
TARGET_REPOSITORY_aarch64 = "helioslite/armv7hf-supervisor"
TARGET_REPOSITORY_x86-64 = "helioslite/amd64-supervisor"
TARGET_TAG ?= "v0.2"
LED_FILE ?= "/dev/null"

inherit systemd
SYSTEMD_AUTO_ENABLE = "enable"

SRC_URI += " \
    file://resin-data.mount \
    file://start-resin-supervisor \
    file://supervisor.conf \
    file://resin-supervisor.service \
    file://update-resin-supervisor \
    "

SYSTEMD_SERVICE_${PN} = " \
    resin-supervisor.service \
    "

FILES_${PN} += " \
    /resin-data \
    ${systemd_unitdir} \
    ${sysconfdir} \
    "

RDEPENDS_${PN} = " \
    bash \
    docker \
    coreutils \
    resin-vars \
    systemd \
    curl \
    resin-unique-key \
    "

python () {
    target_repo = d.getVar("TARGET_REPOSITORY", True)
    target_tag = d.getVar("TARGET_TAG", True)
    if target_repo and not target_tag:
        d.setVar('TARGET_TAG', 'latest')
}

do_install () {
    # Generate supervisor conf
    install -d ${D}${sysconfdir}/resin-supervisor/
    install -m 0755 ${WORKDIR}/supervisor.conf ${D}${sysconfdir}/resin-supervisor/
    sed -i -e 's:@TARGET_REPOSITORY@:${TARGET_REPOSITORY}:g' ${D}${sysconfdir}/resin-supervisor/supervisor.conf
    sed -i -e 's:@LED_FILE@:${LED_FILE}:g' ${D}${sysconfdir}/resin-supervisor/supervisor.conf
    sed -i -e 's:@TARGET_TAG@:${TARGET_TAG}:g' ${D}${sysconfdir}/resin-supervisor/supervisor.conf

    install -d ${D}/resin-data

    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/update-resin-supervisor ${D}${bindir}
    install -m 0755 ${WORKDIR}/start-resin-supervisor ${D}${bindir}

    if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
        install -d ${D}${systemd_unitdir}/system

        # Yocto gets confused if we use strange file names - so we rename it here
        # https://bugzilla.yoctoproject.org/show_bug.cgi?id=8161
        install -c -m 0644 ${WORKDIR}/resin-data.mount ${D}${systemd_unitdir}/system/resin\\x2ddata.mount

        install -c -m 0644 ${WORKDIR}/resin-supervisor.service ${D}${systemd_unitdir}/system
        sed -i -e 's,@BASE_BINDIR@,${base_bindir},g' \
            -e 's,@SBINDIR@,${sbindir},g' \
            -e 's,@BINDIR@,${bindir},g' \
            ${D}${systemd_unitdir}/system/*.service
    fi
}
do_install[vardeps] += "DISTRO_FEATURES TARGET_REPOSITORY LED_FILE"

do_deploy_append () {
    echo ${TARGET_TAG} > ${DEPLOYDIR}/VERSION
}
