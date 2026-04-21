package host

import (
	"github.com/vishvananda/netlink"
)

// NetlinkOps is a wrapper interface over vishvananda/netlink devlink operations.
// This allows for easy mocking in unit tests.
//
//go:generate mockgen -destination mock/mock_netlink_ops.go -source netlink_ops.go
type NetlinkOps interface {
	DevLinkGetDeviceByName(bus, device string) (*netlink.DevlinkDevice, error)
}

type defaultNetlinkOps struct{}

func (defaultNetlinkOps) DevLinkGetDeviceByName(bus, device string) (*netlink.DevlinkDevice, error) {
	return netlink.DevLinkGetDeviceByName(bus, device)
}

func newNetlinkOps() NetlinkOps {
	return &defaultNetlinkOps{}
}
