#
# Author:: AJ Christensen (<aj@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/provider/group/groupadd'
require 'chef/mixin/shell_out'

class Chef
  class Provider
    class Group
      class Suse < Chef::Provider::Group::Groupadd

        include Chef::Mixin::ShellOut

        def load_current_resource
          super
        end

        def define_resource_requirements
          super
          requirements.assert(:all_actions) do |a| 
            a.assertion { ::File.exists?("/usr/sbin/groupmod") } 
            a.failure_message Chef::Exceptions::Group, "Could not find binary /usr/sbin/groupmod for #{@new_resource.name}"
            # No whyrun alternative: this component should be available in the base install of any given system that uses it
          end
        end

        def modify_group_members
          unless @new_resource.members.empty?
            #add users that are missing in any case
            to_add = @new_resource.members.dup
            to_add.reject! { |user| @current_resource.members.include?(user) }
            Chef::Log.debug("#{@new_resource} adding members #{to_add.join(', ')} to group #{@new_resource.group_name}") unless to_add.empty?
            to_add.each do |member|
              shell_out!("groupmod -A #{member} #{@new_resource.group_name}")
            end
            #delete users if not in "append" mode
            unless(@new_resource.append)
              to_delete = @current_resource.members.dup
              to_delete.reject! { |user| @new_resource.members.include?(user) }
              Chef::Log.debug("#{@new_resource} removing members #{to_delete.join(', ')}") unless to_delete.empty?
              to_delete.each do |member|
                shell_out!("groupmod -R #{member} #{@new_resource.group_name}")
              end
            end
          else
            Chef::Log.debug("#{@new_resource} not changing group members, the group has no members")
          end
        end
      end
    end
  end
end
