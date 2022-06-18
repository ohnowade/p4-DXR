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
    ip_addr = ['180.236.36.133/24', '57.73.33.2/32', '1.0.248.1/24', '203.10.62.127/24', '203.133.249.0/24', '220.247.158.169/24']
    createStartTopo(6, ip_addr)

