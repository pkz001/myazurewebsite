#login to azure account
Login-AzureRmAccount

#get subscriptions
Get-AzureRmSubscription

#select subscriptions

Select-AzureRmSubscription -SubscriptionName "Free Trial"

#create a resource group
$resourceGroup = New-AzureRmResourceGroup -Name PowershellRG -Location 'East US' 

#create subnet configurations  subitem config needs to be set first before creating parent item.
#point to note if any item that has a subitem like a virtual network has a subitem subnet. 
#so the subitem configurations needs to be set first then only we can create a vnet

$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name subnet1 -AddressPrefix 10.0.0.0/24

#now subitem is configured we will create a virtual network
$virtualNetwork = New-AzureRmVirtualNetwork -Name Vnet1 -ResourceGroupName $resourceGroup.ResourceGroupName -Location 'East US' -AddressPrefix 10.0.0.0/24 -Subnet $subnetConfig


#create a public IP Address
$publicIPAddress = New-AzureRmPublicIpAddress -Name PublicIP01 -ResourceGroupName $resourceGroup.ResourceGroupName -Location 'East US' -AllocationMethod Dynamic -Sku Basic

#now create a network interface (NSG can also be added here or later)

$networkInterface = New-AzureRmNetworkInterface -Name NIC01 -ResourceGroupName $resourceGroup.ResourceGroupName -Location $resourceGroup.Location -PublicIpAddress $publicIPAddress -Subnet $virtualNetwork.Subnets[0]

$networkInterface = Get-AzureRmNetworkInterface -Name NIC01 -ResourceGroupName PowershellRG


#create NSG . point to note to create NSG we need NSG rules which we will create first

$NsgRules = New-AzureRmNetworkSecurityRuleConfig -Name NSG_RDP_Rule -Protocol Tcp -Description "allows rdp access" -SourcePortRange * -DestinationPortRange 3389 -Direction Inbound -SourceAddressPrefix * -DestinationAddressPrefix * -Priority 1000 -Access Allow


#now create NSG with above NSG rule

$networkSecurityGroup = New-AzureRmNetworkSecurityGroup -Name NSG01 -ResourceGroupName $resourceGroup.ResourceGroupName -Location $resourceGroup.Location -SecurityRules $NsgRules


#associate the NSG with the subnet

Set-AzureRmVirtualNetworkSubnetConfig -NetworkSecurityGroup $networkSecurityGroup -Name $virtualNetwork.Subnets[0].Name -AddressPrefix 10.0.0.0/24 -VirtualNetwork $virtualNetwork


# now we need to update virtual network with the configuration which we did to subnet remember the subitem configuration changes needs to be updated to parent item

Set-AzureRmVirtualNetwork -VirtualNetwork $virtualNetwork


#set credential for Virtual Machine Admin

$cred = Get-Credential


# now we will create an initial VM configuration file to add different things to it

$vmConfig =  New-AzureRmVMConfig -VMName PSVM01 -VMSize Standard_B1ls


# add os and credential details to it

$vmConfig = Set-AzureRmVMOperatingSystem -VM $vmConfig -Windows -ComputerName PsServer01 -Credential $cred -ProvisionVMAgent -EnableAutoUpdate


# add image information to the config file

$vmConfig = Set-AzureRmVMSourceImage -VM $vmConfig -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter -Version Latest

#add os disk details to the config file

$vmConfig = Set-AzureRmVMOSDisk -VM $vmConfig -Name OSDisk -CreateOption FromImage -Windows -Caching ReadWrite 


#add network adapter to the config file

$vmConfig = Add-AzureRmVMNetworkInterface -VM $vmConfig -NetworkInterface $networkInterface

#finally create a VM

$vmConfig = New-AzureRmVM -ResourceGroupName PowershellRG -Location 'East US' -VM $vmConfig


