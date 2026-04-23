package host

import (
	"fmt"

	"github.com/vishvananda/netlink"
	"github.com/vishvananda/netlink/nl"
)

// NetlinkProvider wraps netlink library calls to allow mocking in unit tests.
type NetlinkProvider interface {
	// GetDevLinkDeviceEswitchMode returns the eswitch mode ("legacy" or
	// "switchdev") for the given PF PCI address via devlink.
	GetDevLinkDeviceEswitchMode(pciAddr string) (string, error)

	// GetDevLinkPhysicalPortNetdev returns the netdev name of the physical
	// flavour devlink port for the given bus/device (e.g. "pci"/"0000:0c:00.0").
	// This is equivalent to:
	//   devlink port show | grep "pci/<pciAddr>" | grep "flavour physical"
	// and works in both legacy and switchdev eswitch modes.
	GetDevLinkPhysicalPortNetdev(bus, pciAddr string) (string, error)
}

type defaultNetlinkProvider struct{}

var _ NetlinkProvider = &defaultNetlinkProvider{}

func (defaultNetlinkProvider) GetDevLinkDeviceEswitchMode(pciAddr string) (string, error) {
	dev, err := netlink.DevLinkGetDeviceByName("pci", pciAddr)
	if err != nil {
		return "", err
	}
	return dev.Attrs.Eswitch.Mode, nil
}

func (defaultNetlinkProvider) GetDevLinkPhysicalPortNetdev(bus, pciAddr string) (string, error) {
	ports, err := netlink.DevLinkGetAllPortList()
	if err != nil {
		return "", fmt.Errorf("failed to list devlink ports: %w", err)
	}
	for _, port := range ports {
		if port.BusName == bus && port.DeviceName == pciAddr &&
			port.PortFlavour == nl.DEVLINK_PORT_FLAVOUR_PHYSICAL {
			return port.NetdeviceName, nil
		}
	}
	return "", fmt.Errorf("no physical flavour port found for %s/%s", bus, pciAddr)
}
