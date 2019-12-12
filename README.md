Ceph-deploy
===
 [![](https://img.shields.io/badge/platform-linux--64-lightgrey)](https://img.shields.io/badge/platform-linux--64-lightgrey)
 [![](https://img.shields.io/badge/code%20size-208%20Kb-blue)](https://img.shields.io/badge/code%20size-208%20Kb-blue)
 [![](https://img.shields.io/badge/docs-latest-brightgreen.svg)](https://img.shields.io/badge/docs-latest-brightgreen.svg)
 [![](https://img.shields.io/badge/license-MIT-green)](https://img.shields.io/badge/license-MIT-green)
 
<img src="images/cloudclusters.png" width="100">  

----   

Ansible playbook for `ceph` deployment.
&nbsp;

## Hosts

| hostname |IP Address |NIC |Disk |OS |
| ------ | ------ |--- |------ |------ |
| master1 | 192.168.10.148 / 172.16.0.148 |ens7 |/dev/vda |Ubuntu18.04 |
| master2 | 192.168.10.149 / 172.16.0.149 |ens7 |/dev/vda |Ubuntu18.04 |
| master3 | 192.168.10.151 / 172.16.0.151 |ens7 |/dev/vda |Ubuntu18.04 |
| node1 | 192.168.10.152 / 172.16.0.152 |ens7 | /dev/vdb/, /dev/vdc, /dev/vdd |Ubuntu18.04 |
| node2 | 192.168.10.153 / 172.16.0.153 |ens7 |/dev/vdb/, /dev/vdc, /dev/vdd |Ubuntu18.04 |
| node3 | 192.168.10.155 / 172.16.0.155 |ens7 |/dev/vdb/, /dev/vdc, /dev/vdd |Ubuntu18.04 |
| node4 | 192.168.10.156 / 172.16.0.156 |ens7 |/dev/vdb/, /dev/vdc, /dev/vdd |Ubuntu18.04 |

&nbsp;
## Requirements

- Ansible
- Python 2.7+

&nbsp;

## Installation

1.&nbsp;Log in to master1 and download this playbook.
```shell
export CEPH_INSTALL_DIR="/opt"
cd $CEPH_INSTALL_DIR
git clone https://github.com/cloudclusters/ceph-deploy.git
```
2.&nbsp;Install ansible on "master1" and enable passwordless SSH on other servers.
```shell
apt-get install ansible -y
```

3.&nbsp;Change "inventory_path" and "roles_path" to their current location, in Ansible configuration file.
```shell
cd $CEPH_INSTALL_DIR/ceph-deploy/deploy
sed -i "s#^inventory.*#inventory = $CEPH_INSTALL_DIR/ceph-deploy/deploy/hosts #g" ansible.cfg
sed -i "s#^roles_path.*#roles_path = $CEPH_INSTALL_DIR/ceph-deploy/deploy #g" ansible.cfg
```
4.&nbsp; Modify inventory hosts file.
```yaml
# Management node
[admin]
master1

[master]
# Three ceph components, ceph-mgr, ceph-mon and ceph-mds, are installed on the masters.
# "host_ip" is the public IP address of the host.
192.168.10.148 host_name=master1 host_ip=x.x.x.x dashboard_port=8080
192.168.10.149 host_name=master2 host_ip=x.x.x.x dashboard_port=8080
192.168.10.151 host_name=master3 host_ip=x.x.x.x dashboard_port=8080

[node]
# ceph-osd is installed on the nodes.
192.168.10.152 host_name=node1 
192.168.10.153 host_name=node2
192.168.10.155 host_name=node3

[add_node]
192.168.10.156 host_name=node4

[remove_node]

[all:vars]
master_info="{% for h in groups['master'] %}{{h}}  {{hostvars[h]['host_name']}}\n{% endfor %}"
node_info="{% for h in groups['node'] %}{{h}}  {{hostvars[h]['host_name']}}\n{% endfor %}"
add_node_info="{% for h in groups['add_node'] %}{{h}}  {{hostvars[h]['host_name']}}\n{% endfor %}"

master="{% for h in groups['master'] %}{{hostvars[h]['host_name']}} {% endfor %}"
master_tmp="{% for h in groups['master'] %}\"{{hostvars[h]['host_name']}}\",{% endfor %}"
master_list="[{{master_tmp.rstrip(',')}}]"

# OSD node. ceph-osd is installed on the node
node="{% for h in groups['node'] %}{{hostvars[h]['host_name']}} {% endfor %}"
node_tmp="{% for h in groups['node'] %}\"{{hostvars[h]['host_name']}}\",{% endfor %}"
osd_node_list="[{{node_tmp.rstrip(',')}}]"

add_node="{% for h in groups['add_node'] %}{{hostvars[h]['host_name']}} {% endfor %}"
add_node_tmp="{% for h in groups['add_node'] %}\"{{hostvars[h]['host_name']}}\",{% endfor %}"
add_osd_node_list="[{{add_node_tmp.rstrip(',')}}]"

# All nodes
all_node="{{master}}{{node}}"

# Ceph configuration file directory
workdir="/root/ceph-cluster"

# Ceph cluster multi-network configuration
public_network="192.168.10.0/24"
cluster_network='172.16.0.0/24'

# Number of replicas of an object.
osd_pool_default_size=2

# Ceph dashboard username and password
dashboard_username="<user_name>"
dashboard_password="<password>"

# OSD devices list
osd_partition_list=['/dev/vdb','/dev/vdc','/dev/vdd']

# CEPHFS name
cephfs="cephfs"

# fs_data pool name
fs_data="cephfs_data"
fs_data_pg=256

# fs_metadata pool name
fs_metadata="cephfs_metadata"
fs_metadata_pg=32

# RBD pool name
rbd_pool="rbd"
rbd_pool_pg=256

# Add node devices
add_osd_partition_list=['/dev/vdb','/dev/vdc','/dev/vdd']

# Remove osd by id 
remove_osd_id=11
```

5.&nbsp;Setup the ceph cluster by running the ansible playbook install.yaml.
```shell
ansible-playbook install.yaml
```
If you want to setup a specific component, just run its corresponding playbook.

<details>
<summary>expand</summary>
<pre><code>
ansible-playbook 01-initial-config.yaml
ansible-playbook 02-install-ceph.yaml
ansible-playbook 03-ceph-mon.yaml
ansible-playbook 04-ceph-mgr.yaml
ansible-playbook 05-ceph-dashboard.yaml
ansible-playbook 06-ceph-osd.yaml
ansible-playbook 07-ceph-mds.yaml
ansible-playbook 08-ceph-rbd.yaml
</code></pre>
</details>

&nbsp;


## Edit a CRUSH MAP

1.&nbsp;Get the CRUSH map.
```shell
ceph osd getcrushmap -o crushmap
```
2.&nbsp;Decompile the CRUSH map.
```shell
crushtool -d crushmap -o crushmap.txt
```
3.&nbsp;Modify the CRUSH map file content.
```shell
vim crushmap.txt
```
<details>
<summary>example (crushmap.txt)</summary>
<pre><code>
# begin crush map
tunable choose_local_tries 0
tunable choose_local_fallback_tries 0
tunable choose_total_tries 50
tunable chooseleaf_descend_once 1
tunable chooseleaf_vary_r 1
tunable chooseleaf_stable 1
tunable straw_calc_version 1
tunable allowed_bucket_algs 54
&nbsp;
# devices
device 0 osd.0 class hdd
device 1 osd.1 class hdd
device 2 osd.2 class hdd
device 3 osd.3 class hdd
device 4 osd.4 class hdd
device 5 osd.5 class hdd
device 6 osd.6 class hdd
device 7 osd.7 class hdd
device 8 osd.8 class hdd
&nbsp;
# types
type 0 osd
type 1 host
type 2 chassis
type 3 rack
type 4 row
type 5 pdu
type 6 pod
type 7 room
type 8 datacenter
type 9 region
type 10 root
&nbsp;
# buckets
host node1 {
	id -3		# do not change unnecessarily
	id -4 class hdd		# do not change unnecessarily
	# weight 0.057
	alg straw2
	hash 0	# rjenkins1
	item osd.0 weight 0.019
	item osd.1 weight 0.019
	item osd.2 weight 0.019
}
host node2 {
	id -5		# do not change unnecessarily
	id -6 class hdd		# do not change unnecessarily
	# weight 0.057
	alg straw2
	hash 0	# rjenkins1
	item osd.3 weight 0.019
	item osd.4 weight 0.019
	item osd.5 weight 0.019
}
host node3 {
	id -7		# do not change unnecessarily
	id -8 class hdd		# do not change unnecessarily
	# weight 0.057
	alg straw2
	hash 0	# rjenkins1
	item osd.6 weight 0.019
	item osd.7 weight 0.019
	item osd.8 weight 0.019
}
root default {
	id -1		# do not change unnecessarily
	id -2 class hdd		# do not change unnecessarily
	# weight 0.168
	alg straw2
	hash 0	# rjenkins1
	item node1 weight 0.056
	item node2 weight 0.056
	item node3 weight 0.056
}
host node1-ssd {
	id -9		# do not change unnecessarily
	id -21 class hdd		# do not change unnecessarily
	# weight 0.038
	alg straw2
	hash 0	# rjenkins1
	item osd.0 weight 0.019
	item osd.1 weight 0.019
}
host node2-ssd {
	id -10		# do not change unnecessarily
	id -22 class hdd		# do not change unnecessarily
	# weight 0.038
	alg straw2
	hash 0	# rjenkins1
	item osd.3 weight 0.019
	item osd.4 weight 0.019
}
host node3-ssd {
	id -11		# do not change unnecessarily
	id -23 class hdd		# do not change unnecessarily
	# weight 0.038
	alg straw2
	hash 0	# rjenkins1
	item osd.6 weight 0.019
	item osd.7 weight 0.019
}
root ssd {
	id -12		# do not change unnecessarily
	id -24 class hdd		# do not change unnecessarily
	# weight 0.111
	alg straw2
	hash 0	# rjenkins1
	item node1-ssd weight 0.037
	item node2-ssd weight 0.037
	item node3-ssd weight 0.037
}
host node1-hdd {
	id -13		# do not change unnecessarily
	id -17 class hdd		# do not change unnecessarily
	# weight 0.019
	alg straw2
	hash 0	# rjenkins1
	item osd.2 weight 0.019
}
host node2-hdd {
	id -14		# do not change unnecessarily
	id -18 class hdd		# do not change unnecessarily
	# weight 0.019
	alg straw2
	hash 0	# rjenkins1
	item osd.5 weight 0.019
}
host node3-hdd {
	id -15		# do not change unnecessarily
	id -19 class hdd		# do not change unnecessarily
	# weight 0.019
	alg straw2
	hash 0	# rjenkins1
	item osd.8 weight 0.019
}
root hdd {
	id -16		# do not change unnecessarily
	id -20 class hdd		# do not change unnecessarily
	# weight 0.057
	alg straw2
	hash 0	# rjenkins1
	item node1-hdd weight 0.019
	item node2-hdd weight 0.019
	item node3-hdd weight 0.019
}
&nbsp;
# rules
rule replicated_rule {
	id 0
	type replicated
	min_size 1
	max_size 10
	step take default
	step chooseleaf firstn 0 type host
	step emit
}
rule ssd_rule {
	id 1
	type replicated
	min_size 1
	max_size 10
	step take ssd
	step chooseleaf firstn 0 type host
	step emit
}
rule hdd_rule {
	id 2
	type replicated
	min_size 1
	max_size 10
	step take hdd
	step chooseleaf firstn 0 type host
	step emit
}
&nbsp;
# end crush map
</code></pre>
</details>

4.&nbsp;Recompile the CRUSH map.
```shell
crushtool -c crushmap.txt -o newcrushmap
```
5.&nbsp;Set the CRUSH map.
```shell
ceph osd setcrushmap  -i  newcrushmap
```
&nbsp;

## Add Node 

The following illustrate how to join one additional storage servers, node4, to this ceph cluster.

1.&nbsp;Edit ceph inventory hosts file. 
```shell
cd $CEPH_INSTALL_DIR/ceph-deploy/deploy/
vim hosts
```

2.&nbsp;Under [add_node] section, add a new node4 with its partition list.
```yaml
[add_node]
192.168.10.156 host_name=node4

add_osd_partition_list=['/dev/vdb','/dev/vdc','/dev/vdd']
```

3.&nbsp;Run playbook add_node.yaml on master1 server.
```shell
ansible-playbook add_node.yaml
```

&nbsp;


## Remove OSD  
	
1.&nbsp;Edit ceph inventory hosts file. 
```shell
cd $CEPH_INSTALL_DIR/ceph-deploy/deploy/
vim hosts
```

2.&nbsp;Specify the OSD you want to remove in following format(it’s good to just remove one OSD each time)
```yaml
remove_osd_id=11
```
3.&nbsp;Execute remove_osd.sh
```shell
bash remove_osd.sh
```
	
