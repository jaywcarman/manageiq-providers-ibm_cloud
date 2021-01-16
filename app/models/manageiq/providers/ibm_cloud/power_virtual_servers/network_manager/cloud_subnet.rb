class ManageIQ::Providers::IbmCloud::PowerVirtualServers::NetworkManager::CloudSubnet < ::CloudSubnet
  supports :create

  def self.params_for_create(ems)
    {
      :fields => [
        {
          :component => 'text-field',
          :id        => 'subnet_name',
          :name      => 'subnet_name',
          :label     => _('Subnet Name'),
        },
        {
          :component => 'select',
          :name      => 'type',
          :id        => 'type',
          :label     => _('Type'),
          :options   => [
            {
              :label => 'vlan',
              :value => 'vlan',
            },
            {
              :label => 'pub-vlan',
              :value => 'pub-vlan',
            }
          ]
        },
        {
          :component => 'text-field',
          :id        => 'subnet_cidr',
          :name      => 'subnet_cidr',
          :label     => _('Subnet CIDR'),
          :isRequired => true,
          :validate   => [{:type => 'required'}]
        },
        {
          :component => 'text-area',
          :id        => 'dns_servers',
          :name      => 'dns_servers',
          :label     => _('DNS Servers'),
        },
        # TODO: Validate starting/Ending IP addresses must both be set or both be unset
        #       Use 'IP Address Ranges' subform?
        {
          :component => 'text-field',
          :id        => 'starting_ip_address',
          :name      => 'starting_ip_address',
          :label     => _('Starting IP Address'),
        },
        {
          :component => 'text-field',
          :id        => 'ending_ip_address',
          :name      => 'ending_ip_address',
          :label     => _('Ending IP Address'),
        },
        {
          :component => 'switch',
          :id        => 'jumbo',
          :name      => 'jumbo',
          :label     => _('MTU Jumbo Network'),
          :onText    => 'Enabled',
          :offText   => 'Disabled',
        },
      ],
    }
  end

  supports :delete do
    if number_of(:vms) > 0
      unsupported_reason_add(:delete, _("The Network has active VMIs related to it"))
    end
  end

  def delete_cloud_subnet_queue(userid)
    task_opts = {
      :action => "creating cloud subnet, userid: #{userid}",
      :userid => userid
    }

    queue_opts = {
      :class_name  => self.class.name,
      :method_name => 'raw_delete_cloud_subnet',
      :instance_id => id,
      :priority    => MiqQueue::HIGH_PRIORITY,
      :role        => 'ems_operations',
      :zone        => ext_management_system.my_zone,
      :args        => []
    }

    MiqTask.generic_action_with_callback(task_opts, queue_opts)
  end

  def raw_delete_cloud_subnet
    cloud_instance_id = ext_management_system.parent_manager.uid_ems
    ext_management_system.with_provider_connection(:service => 'PCloudNetworksApi') do |api|
      api.pcloud_networks_delete(cloud_instance_id, ems_ref)
    end
  rescue => e
    _log.error("network=[#{name}], error: #{e}")
  end
end
