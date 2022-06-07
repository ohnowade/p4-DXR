import sys
sys.path.insert(1, '../p4-utils')

from p4utils.mininetlib.network_API import NetworkAPI

def createStartTopo(num_host, ip_addr):
    if len(ip_addr) != num_host:
        print('Number of IP addresses given is not equal to number of hosts!')
        return
    
    net = NetworkAPI()
    net.setLogLevel('info')

    net.addP4Switch('s1')
    net.setP4Source('s1','dxr.p4')
    net.setP4CliInput('s1', 'cmd1.txt')

    for i in range(1, num_host + 1):
        host_name = 'h{}'.format(i)
        net.addHost(host_name)
        net.addLink('s1', host_name)
        net.setIntfPort('s1', host_name, i)  
        net.setIntfPort(host_name, 's1', 0)
        net.setIntfIp(host_name, 's1', ip_addr[i - 1])
        print("set {} with ip address {}\n".format(host_name, ip_addr[i-1]))
        cur_ip = ip_addr[i - 1].split('/')[0]
        net.setDefaultRoute(host_name, cur_ip)

    net.enablePcapDumpAll()
    net.enableLogAll()
    net.enableCli()
    net.startNetwork()

if __name__ == '__main__':
    # ip_addr = ['3.6.22.33/32','30.11.13.23/32','23.33.1.8/32','12.36.123.58/24','12.36.123.240/24','12.36.123.105/24','12.36.123.180/24','12.36.123.137/24']
    ip_addr = ['97.150.36.133/24', '57.73.33.2/32', '115.166.114.216/24']
    createStartTopo(3, ip_addr)

