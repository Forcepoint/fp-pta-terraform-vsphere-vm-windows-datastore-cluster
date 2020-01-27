data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

data "vsphere_datastore_cluster" "datastore_cluster" {
  name          = var.vsphere_datastore_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "compute_cluster" {
  name          = var.vsphere_compute_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "vlan_main" {
  name          = var.vlan_main
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.vm_clone_from
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "vm" {
  name                 = var.name
  folder               = var.folder
  resource_pool_id     = data.vsphere_compute_cluster.compute_cluster.resource_pool_id
  datastore_cluster_id = data.vsphere_datastore_cluster.datastore_cluster.id

  num_cpus          = var.num_cpus
  memory            = var.memory
  guest_id          = data.vsphere_virtual_machine.template.guest_id
  nested_hv_enabled = var.nested_hv_enabled
  scsi_type         = data.vsphere_virtual_machine.template.scsi_type

  wait_for_guest_net_timeout = var.wait_for_guest_net_timeout
  shutdown_wait_timeout      = var.shutdown_wait_timeout

  network_interface {
    network_id   = data.vsphere_network.vlan_main.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk1"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    timeout       = var.clone_timeout

    customize {
      windows_options {
        computer_name         = var.name
        workgroup             = var.workgroup
        join_domain           = var.join_domain
        domain_admin_user     = var.domain_admin_user
        domain_admin_password = var.domain_admin_password
        product_key           = var.product_key
        time_zone             = var.time_zone
        full_name             = var.full_name
        admin_password        = var.admin_password
        auto_logon            = var.auto_logon
        run_once_command_list = var.run_once_command_list
      }

      network_interface {
        ipv4_address    = var.ipv4_address
        ipv4_netmask    = var.ipv4_netmask
        ipv6_address    = var.ipv6_address
        ipv6_netmask    = var.ipv6_netmask
        dns_domain      = var.dns_domain
        dns_server_list = var.dns_server_list
      }

      ipv4_gateway    = var.ipv4_gateway
      ipv6_gateway    = var.ipv6_gateway

      timeout         = var.customize_timeout
    }
  }
}