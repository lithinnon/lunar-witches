// SPDX-License-Identifier: GPL-2.0
/*
 * ASUS TUF A14 FA401EA firmware sets the RTS525A subsystem IDs to 1043:202f on
 * boot but does not restore them after S0i3, so they read back as 10ec:525a.
 * pciehp_device_replaced() then treats the soldered reader as swapped and
 * removes it, and the removal blocks syncing a filesystem on the lost SD card,
 * which stalls resume. Cache the IDs the device reports after S0i3 instead.
 */
#include <linux/module.h>
#include <linux/pci.h>

#define RTS525A_DEVICE 0x525a
#define ASUS_SUBSYSTEM_VENDOR 0x1043
#define ASUS_SUBSYSTEM_DEVICE 0x202f

static int __init rtsx_subsystem_ids_init(void)
{
	struct pci_dev *pdev = NULL;

	while ((pdev = pci_get_device(PCI_VENDOR_ID_REALTEK, RTS525A_DEVICE, pdev))) {
		if (pdev->subsystem_vendor != ASUS_SUBSYSTEM_VENDOR ||
		    pdev->subsystem_device != ASUS_SUBSYSTEM_DEVICE)
			continue;

		pdev->subsystem_vendor = pdev->vendor;
		pdev->subsystem_device = pdev->device;
		pci_info(pdev, "cached subsystem IDs set to %04x:%04x\n",
			 pdev->subsystem_vendor, pdev->subsystem_device);
	}

	return 0;
}
module_init(rtsx_subsystem_ids_init);

static void __exit rtsx_subsystem_ids_exit(void)
{
}
module_exit(rtsx_subsystem_ids_exit);

MODULE_DESCRIPTION("Stop pciehp removing the FA401EA RTS525A reader on resume");
MODULE_LICENSE("GPL");
