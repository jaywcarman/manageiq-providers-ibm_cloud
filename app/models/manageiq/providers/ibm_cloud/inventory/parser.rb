class ManageIQ::Providers::IbmCloud::Inventory::Parser < ManageIQ::Providers::Inventory::Parser
  require_nested :PowerVirtualServers
  require_nested :VPC
end
