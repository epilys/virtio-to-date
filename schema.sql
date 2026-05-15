create table IF NOT EXISTS virtio_standard_version(
  name TEXT NOT NULL PRIMARY KEY UNIQUE,
  url TEXT NOT NULL UNIQUE,
  created TEXT NOT NULL UNIQUE
) STRICT;

CREATE TABLE IF NOT EXISTS virtio_device(
  id INTEGER NOT NULL PRIMARY KEY UNIQUE,
  name TEXT NOT NULL UNIQUE,
  short_name TEXT,
  id_reserved_in TEXT NOT NULL REFERENCES "virtio_standard_version" ("name") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  introduced_in TEXT REFERENCES "virtio_standard_version" ("name") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
) STRICT;

CREATE TABLE IF NOT EXISTS virtio_transport(
  name TEXT NOT NULL PRIMARY KEY UNIQUE,
  short_name TEXT NOT NULL UNIQUE,
  introduced_in TEXT NOT NULL REFERENCES "virtio_standard_version" ("name") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
) STRICT;

--CREATE TABLE IF NOT EXISTS virtio_device_feature(
--  id INTEGER NOT NULL PRIMARY KEY UNIQUE,
--  bit INTEGER NOT NULL,
--  name TEXT NOT NULL UNIQUE,
--  introduced_in TEXT NOT NULL REFERENCES "virtio_standard_version" ("name") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
--  device_id INTEGER REFERENCES "virtio_device" ("id") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
--  CONSTRAINT unique_feature UNIQUE(bit, device_id)
--) STRICT;

CREATE TABLE IF NOT EXISTS operating_system(
  short_name TEXT NOT NULL PRIMARY KEY UNIQUE,
  name TEXT NOT NULL UNIQUE,
  notes TEXT,
  url TEXT
) STRICT;

CREATE TABLE IF NOT EXISTS virtualization_stack(
  short_name TEXT NOT NULL PRIMARY KEY UNIQUE,
  name TEXT NOT NULL UNIQUE,
  notes TEXT,
  url TEXT
) STRICT;

CREATE TABLE IF NOT EXISTS virtio_device_driver(
  id INTEGER NOT NULL PRIMARY KEY UNIQUE,
  device_id INTEGER NOT NULL REFERENCES "virtio_device" ("id") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  software TEXT NOT NULL REFERENCES "operating_system" ("short_name") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  additional_requirements TEXT,
  notes TEXT,
  introduced_in_version TEXT,
  created TEXT,
  CONSTRAINT unique_impl UNIQUE(software, device_id, additional_requirements)
) STRICT;

CREATE TABLE IF NOT EXISTS virtio_transport_driver(
  id INTEGER NOT NULL PRIMARY KEY UNIQUE,
  transport TEXT NOT NULL REFERENCES "virtio_transport" ("short_name") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  software TEXT NOT NULL REFERENCES "operating_system" ("short_name") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  additional_requirements TEXT,
  notes TEXT,
  introduced_in_version TEXT,
  created TEXT,
  CONSTRAINT unique_impl UNIQUE(software, transport, additional_requirements)
) STRICT;

CREATE TABLE IF NOT EXISTS virtio_device_backend(
  id INTEGER NOT NULL PRIMARY KEY UNIQUE,
  device_id INTEGER NOT NULL REFERENCES "virtio_device" ("id") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  software TEXT NOT NULL REFERENCES "virtualization_stack" ("short_name") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  url TEXT,
  additional_requirements TEXT,
  notes TEXT,
  introduced_in_version TEXT,
  created TEXT,
  CONSTRAINT unique_impl UNIQUE(software, device_id, additional_requirements)
) STRICT;

CREATE TABLE IF NOT EXISTS virtio_transport_backend(
  id INTEGER NOT NULL PRIMARY KEY UNIQUE,
  transport TEXT NOT NULL REFERENCES "virtio_transport" ("short_name") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  software TEXT NOT NULL REFERENCES "virtualization_stack" ("short_name") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  additional_requirements TEXT,
  notes TEXT,
  introduced_in_version TEXT,
  created TEXT,
  CONSTRAINT unique_impl UNIQUE(software, transport, additional_requirements)
) STRICT;
--CREATE TABLE IF NOT EXISTS virtio_device_feature_requirement(
--  id INTEGER NOT NULL PRIMARY KEY UNIQUE,
--  bit INTEGER NOT NULL,
--  name TEXT NOT NULL UNIQUE,
--  introduced_in TEXT NOT NULL REFERENCES "virtio_standard_version" ("name") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
--  device_id INTEGER REFERENCES "virtio_device" ("id") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
--  CONSTRAINT unique_feature UNIQUE(bit, device_id)
--) STRICT;


INSERT INTO virtio_standard_version(name, url, created) VALUES
('VIRTIO-v1.0', 'https://docs.oasis-open.org/virtio/virtio/v1.0/virtio-v1.0.html', '03 March 2016'),
('VIRTIO-v1.1', 'https://docs.oasis-open.org/virtio/virtio/v1.1/virtio-v1.1.html', '11 April 2019'),
('VIRTIO-v1.2', 'https://docs.oasis-open.org/virtio/virtio/v1.2/virtio-v1.2.html', '01 July 2022'),
('VIRTIO-v1.3', 'https://docs.oasis-open.org/virtio/virtio/v1.3/virtio-v1.3.html', '06 October 2023'),
('VIRTIO-v1.4', 'https://docs.oasis-open.org/virtio/virtio/v1.4/virtio-v1.4.html', 'unreleased')
;

INSERT INTO virtio_device
(id, name,          short_name,    id_reserved_in, introduced_in) VALUES
(1,	'network card', 'virtio-net', 'VIRTIO-v1.0', 'VIRTIO-v1.0'),
(2,	'block device', 'virtio-blk', 'VIRTIO-v1.0', 'VIRTIO-v1.0'),
(3,	'console', 'virtio-console', 'VIRTIO-v1.0', 'VIRTIO-v1.0'),
(4,	'entropy source', 'virtio-rng', 'VIRTIO-v1.0', 'VIRTIO-v1.0'),
(5,	'memory ballooning (traditional)', 'virtio-balloon', 'VIRTIO-v1.0', 'VIRTIO-v1.0'),
(6,	'ioMemory', 'virtio-iomem', 'VIRTIO-v1.0', NULL),
(7,	'rpmsg', NULL, 'VIRTIO-v1.0', NULL),
(8,	'SCSI host', 'virtio-scsi', 'VIRTIO-v1.0', 'VIRTIO-v1.0'),
(9,	'9P transport', 'virtio-9p', 'VIRTIO-v1.0', NULL),
(10,	'mac80211 wlan', NULL, 'VIRTIO-v1.0', NULL),
(11,	'rproc serial', NULL, 'VIRTIO-v1.0', NULL),
(12,	'virtio CAIF', NULL, 'VIRTIO-v1.0', NULL),
(13,	'memory balloon', NULL, 'VIRTIO-v1.0', NULL),
(16,	'GPU device', 'virtio-gpu', 'VIRTIO-v1.0', 'VIRTIO-v1.1'),
(17,	'Timer/Clock device', 'virtio-rtc', 'VIRTIO-v1.0', 'VIRTIO-v1.4'),
(18,	'Input device', 'virtio-input', 'VIRTIO-v1.0', 'VIRTIO-v1.1'),
(19,	'Socket device', 'virtio-vsock', 'VIRTIO-v1.1', 'VIRTIO-v1.1'),
(20,	'Crypto device', 'virtio-crypto', 'VIRTIO-v1.1', 'VIRTIO-v1.1'),
(21,	'Signal Distribution Module', NULL, 'VIRTIO-v1.1', NULL),
(22,	'pstore device', NULL, 'VIRTIO-v1.1', NULL),
(23,	'IOMMU device', 'virtio-iommu', 'VIRTIO-v1.1', 'VIRTIO-v1.2'),
(24,	'Memory device', 'virtio-mem', 'VIRTIO-v1.2', 'VIRTIO-v1.2'),
(25,	'Sound device', 'virtio-snd', 'VIRTIO-v1.2', 'VIRTIO-v1.2'),
(26,	'file system device', 'virtio-fs', 'VIRTIO-v1.2', 'VIRTIO-v1.2'),
(27,	'PMEM device', 'virtio-pmem', 'VIRTIO-v1.2', 'VIRTIO-v1.2'),
(28,	'RPMB device', 'virtio-rpmb', 'VIRTIO-v1.2', 'VIRTIO-v1.2'),
(29,	'mac80211 hwsim wireless simulation device', NULL, 'VIRTIO-v1.2', NULL),
(30,	'Video encoder device', NULL, 'VIRTIO-v1.2', NULL),
(31,	'Video decoder device', NULL, 'VIRTIO-v1.2', NULL),
(32,	'SCMI device', 'virtio-scmi', 'VIRTIO-v1.2', 'VIRTIO-v1.2'),
(33,	'NitroSecureModule', NULL, 'VIRTIO-v1.2', NULL),
(34,	'I2C adapter', 'virtio-i2c', 'VIRTIO-v1.2', 'VIRTIO-v1.2'),
(35,	'Watchdog', NULL, 'VIRTIO-v1.2', NULL),
(36,	'CAN device', 'virtio-can', 'VIRTIO-v1.2', 'VIRTIO-v1.4'),
(38,	'Parameter Server', NULL, 'VIRTIO-v1.2', NULL),
(39,	'Audio policy device', NULL, 'VIRTIO-v1.2', NULL),
(40,	'Bluetooth device', NULL, 'VIRTIO-v1.2', NULL),
(41,	'GPIO device', 'virtio-gpio', 'VIRTIO-v1.2', 'VIRTIO-v1.2'),
(42,	'RDMA device', NULL, 'VIRTIO-v1.2', NULL),
(43,	'Camera device', 'virtio-camera', 'VIRTIO-v1.3', NULL),
(44,	'ISM device', NULL, 'VIRTIO-v1.3', NULL),
(45,	'SPI controller', 'virtio-spi', 'VIRTIO-v1.3', 'VIRTIO-v1.4'),
(46,	'TEE device', NULL, 'VIRTIO-v1.4', NULL),
(47,	'CPU balloon device', NULL, 'VIRTIO-v1.4', NULL),
(48,	'Media device', 'virtio-media', 'VIRTIO-v1.4', 'VIRTIO-v1.4'),
(49,	'USB controller', 'virtio-usb', 'VIRTIO-v1.4', NULL)
;

INSERT INTO virtio_transport(name, short_name, introduced_in) VALUES
('Virtio Over PCI Bus', 'virtio-pci', 'VIRTIO-v1.0'),
('Virtio Over MMIO', 'virtio-mmio', 'VIRTIO-v1.0'),
('Virtio Over Channel I/O', 'virtio-ccw', 'VIRTIO-v1.0')
;

INSERT INTO operating_system(short_name, name, url, notes) VALUES
('linux', 'Linux', 'https://www.kernel.org/', NULL),
('freebsd', 'FreeBSD', 'https://www.freebsd.org/', NULL),
('netbsd', 'NetBSD', 'https://www.netbsd.org/', NULL),
('redox', 'Redox OS', 'https://www.redox-os.org/', NULL),
('virtio-win', 'Microsoft Windows', 'https://github.com/virtio-win/kvm-guest-drivers-windows', 'With paravirtualized drivers for QEMU/KVM')
;

INSERT INTO virtualization_stack(short_name, name, url) VALUES
('qemu', 'QEMU', 'https://www.qemu.org/'),
('vhost-user', 'vhost-user protocol', 'https://www.qemu.org/'),
('linux-vhost', 'Linux kernel vhost-accelerated', 'https://www.kernel.org/')
;

INSERT INTO virtio_transport_driver(transport, software) VALUES
('virtio-pci', 'linux'),
('virtio-mmio', 'linux'),
('virtio-pci', 'virtio-win'),
('virtio-pci', 'freebsd'),
('virtio-pci', 'netbsd'),
('virtio-pci', 'redox')
;

INSERT INTO virtio_device_driver(device_id, software, notes) VALUES
(1, 'linux', 'virtio_net'),
(2, 'linux', 'virtio_blk'),
(3, 'linux', 'virtio_console'),
(5, 'linux', 'virtio_balloon'),
(4, 'linux', 'virtio-rng'),
(7, 'linux', 'virtio_rpmsg_bus'),
(8, 'linux', 'virtio_scsi'),
(9, 'linux', '9pnet_virtio'),
(12, 'linux', 'caif_virtio'),
(16, 'linux', 'virtio-gpu'),
(17, 'linux', 'virtio_rtc'),
(18, 'linux', 'virtio_input'),
(19, 'linux', 'vsock'),
(20, 'linux', 'virtio_crypto'),
(23, 'linux', 'virtio-iommu'),
(24, 'linux', 'virtio_mem'),
(25, 'linux', 'virtio_snd'),
(26, 'linux', 'virtiofs'),
(27, 'linux', 'virtio_pmem'),
(32, 'linux', 'scmi_transport_virtio'),
(34, 'linux', 'i2c-virtio'),
(40, 'linux', 'virtio_bt'),
(41, 'linux', 'gpio-virtio')
;

INSERT INTO virtio_device_driver(device_id, software) VALUES
(1, 'freebsd'),
(2, 'freebsd'),
(3, 'freebsd'),
(4, 'freebsd'),
(13, 'freebsd'),
(16, 'freebsd'),
(8, 'freebsd')
;

INSERT INTO virtio_device_driver(device_id, software,notes) VALUES
(1, 'netbsd', 'vioif'),
(2, 'netbsd', 'ld'),
(3, 'netbsd', 'viocon'),
(4, 'netbsd', 'viornd'),
(5, 'netbsd', 'viomb'),
(8, 'netbsd', 'vioscsi')
;

INSERT INTO virtio_device_driver(device_id, software,notes) VALUES
(1, 'redox', 'virtio-netd'),
(2, 'redox', 'virtio-blkd'),
(16, 'redox', 'virtio-gpud')
;

INSERT INTO virtio_device_driver(device_id, software, notes) VALUES
(1, 'virtio-win', 'netkvm'),
(2, 'virtio-win', 'viostor'),
(3, 'virtio-win', 'vioser'),
(4, 'virtio-win', 'viorng'),
(5, 'virtio-win', 'balloon'),
(8, 'virtio-win', 'vioscsi'),
(18, 'virtio-win', 'vioinput'),
(16, 'virtio-win', 'viogpudo'),
(24, 'virtio-win', 'viomem'),
(26, 'virtio-win', 'viofs')
;

INSERT INTO virtio_transport_backend(transport, software) VALUES 
('virtio-pci', 'qemu'),
('virtio-ccw', 'qemu'),
('virtio-mmio', 'qemu')
;

INSERT INTO virtio_device_backend(device_id, software) VALUES 
(1, 'qemu'),
(2, 'qemu'),
(3, 'qemu'),
(4, 'qemu'),
(5, 'qemu'),
(4, 'qemu'),
(8, 'qemu'),
(9, 'qemu'),
(16, 'qemu'),
(18, 'qemu'),
(20, 'qemu'),
(23, 'qemu'),
(25, 'qemu'),
(27, 'qemu')
;

INSERT INTO virtio_device_backend(device_id, software, url) VALUES 
(2, 'vhost-user', 'https://www.qemu.org/docs/master/tools/qemu-storage-daemon.html'),
(3, 'vhost-user', 'https://github.com/rust-vmm/vhost-device/tree/main/vhost-device-console'),
(4, 'vhost-user', 'https://github.com/rust-vmm/vhost-device/tree/main/vhost-device-rng'),
(8, 'vhost-user', 'https://github.com/rust-vmm/vhost-device/tree/main/vhost-device-scsi'),
(16, 'vhost-user', 'https://github.com/rust-vmm/vhost-device/tree/main/vhost-device-gpu'),
(17, 'vhost-user', 'https://github.com/rust-vmm/vhost-device/tree/main/vhost-device-rtc'),
(18, 'vhost-user', 'https://github.com/rust-vmm/vhost-device/tree/main/vhost-device-input'),
(19, 'vhost-user', 'https://github.com/rust-vmm/vhost-device/tree/main/vhost-device-vsock'),
(25, 'vhost-user', 'https://github.com/rust-vmm/vhost-device/tree/main/vhost-device-sound'),
(26, 'vhost-user', 'https://virtio-fs.gitlab.io/'),
(32, 'vhost-user', 'https://github.com/rust-vmm/vhost-device/tree/main/vhost-device-scmi'),
(34, 'vhost-user', 'https://github.com/rust-vmm/vhost-device/tree/main/vhost-device-i2c'),
(36, 'vhost-user', 'https://github.com/rust-vmm/vhost-device/tree/main/vhost-device-can'),
(41, 'vhost-user', 'https://github.com/rust-vmm/vhost-device/tree/main/vhost-device-gpio'),
(45, 'vhost-user', 'https://github.com/rust-vmm/vhost-device/tree/main/vhost-device-spi')
;

INSERT INTO virtio_device_backend(device_id, software, notes) VALUES
(1, 'linux-vhost', 'vhost_net: drivers/vhost/net.c'),
(8, 'linux-vhost', 'vhost_scsi: drivers/vhost/scsi.c'),
(19, 'linux-vhost', 'vhost_vsock: drivers/vhost/vsock.c')
;

