# encoding: utf-8
#
# Cookbook Name:: consul
# Recipe:: default
#
# Copyright (C) 2014, Darron Froese <darron@froese.org>
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

include_recipe 'chef-sugar::default'

package 'unzip'
package 'curl'

remote_file node['jq']['path'] do
  source node['jq']['url']
  owner 'root'
  group 'root'
  mode '00755'
  action :create
end

directory node['consul']['config_path'] do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
  action :create
end

directory node['consul']['config_d_dir'] do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
  action :create
end

directory node['consul']['data_dir'] do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
  action :create
end

template '/etc/default/consul' do
  source 'consul.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template '/etc/init/consul.conf' do
  source 'consul.conf.erb'
  owner 'root'
  group 'root'
  mode '0744'
end

link '/etc/init.d/consul' do
  to '/lib/init/upstart-job'
end

template node['consul']['config_file_path'] do
  source 'config.erb'
  owner 'root'
  group 'root'
  mode '0744'
  notifies :restart, 'service[consul]', :delayed
end

remote_file node['consul']['tmp'] do
  source node['consul']['url']
  checksum node['consul']['checksum']
  owner 'root'
  group 'root'
  mode 00755
end

ark 'consul' do
  url node['consul']['url']
  has_binaries ['consul']
  version '0.5rc1'
  mode 00755
  action :install
end

remote_file node['web_ui']['tmp'] do
  source node['web_ui']['url']
  owner 'root'
  group 'root'
  mode 00755
end

directory node['web_ui']['destination'] do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
  action :create
end

bash 'extract consul web_ui' do
  user 'root'
  cwd node['web_ui']['destination']
  code <<-EOH
    unzip -u node['web_ui']['tmp']
    mv dist/* . && rm -rf dist
  EOH
  not_if { ::File.exist?("#{node['web_ui']['destination']}/index.html") }
end

cookbook_file '/usr/bin/consulkv' do
  source 'consulkv'
  owner 'root'
  group 'root'
  mode '0755'
end

service 'consul' do
  action [:enable, :start]
end
