# Configure the Microsoft Azure Provider
provider "azurerm" {
    subscription_id = "88472c8d-1473-42cb-ae3e-7421b5eedbfe"
    client_id       = "99f026f8-9ee5-4e23-8635-a39f1fd0513f"
    client_secret   = "e172fbb1-3c64-4032-a7df-2d9513a99715"
    tenant_id       = "72f988bf-86f1-41af-91ab-2d7cd011db47"
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "terraformTestGroup" {
    name     = "terraform-RG"
    location = "eastus"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "terraformterraformnetwork" {
    name                = "terraformVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.terraformTestGroup.name}"
    tags = {
        environment = "Terraform Demo"
    }
}
# Create subnet
resource "azurerm_subnet" "terraformterraformsubnet" {
    name                 = "terraformSubnet"
    resource_group_name  = "${azurerm_resource_group.terraformTestGroup.name}"
    virtual_network_name = "${azurerm_virtual_network.terraformterraformnetwork.name}"
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "terraformterraformpublicip" {
    name                         = "terraformPublicIP"
    location                     = "eastus"
    resource_group_name          = "${azurerm_resource_group.terraformTestGroup.name}"
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "terraformterraformnsg" {
    name                = "terraformNetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.terraformTestGroup.name}"
    
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "terraformterraformnic" {
    name                      = "terraformNIC"
    location                  = "eastus"
    resource_group_name       = "${azurerm_resource_group.terraformTestGroup.name}"
    network_security_group_id = "${azurerm_network_security_group.terraformterraformnsg.id}"

    ip_configuration {
        name                          = "terraformNicConfiguration"
        subnet_id                     = "${azurerm_subnet.terraformterraformsubnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.terraformterraformpublicip.id}"
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.terraformTestGroup.name}"
    }
    
    byte_length = 8
}


# Create storage account for boot diagnostics
resource "azurerm_storage_account" "terraformstorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "${azurerm_resource_group.terraformTestGroup.name}"
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "terraformterraformvm" {
    name                  = "terraformVM"
    location              = "eastus"
    resource_group_name   = "${azurerm_resource_group.terraformTestGroup.name}"
    network_interface_ids = ["${azurerm_network_interface.terraformterraformnic.id}"]
    vm_size               = "Standard_DS13_v2"

    storage_os_disk {
        name              = "terraformOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "terraformvm"
        admin_username = "azureuser"
        admin_username = "testadmin"
        admin_password = "Password1234!"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.terraformstorageaccount.primary_blob_endpoint}"
    }

    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_managed_disk" "terraformterraformdisk" {
  name                 = "terraformdata-disk1"
  location             = "eastus"
  resource_group_name  = "${azurerm_resource_group.terraformTestGroup.name}"
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 1000
}

resource "azurerm_virtual_machine_data_disk_attachment" "terraformterraformdiskattach" {
  managed_disk_id    = "${azurerm_managed_disk.terraformterraformdisk.id}"
  virtual_machine_id = "${azurerm_virtual_machine.terraformterraformvm.id}"
  lun                = "10"
  caching            = "ReadOnly"
}