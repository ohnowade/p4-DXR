import sys
sys.path.insert(1, '../p4-utils')

from p4utils.mininetlib.network_API import NetworkAPI

net = NetworkAPI()
net.setLogLevel('info')

net.addP4Switch('s1')
net.addHost('h1')
net.addHost('h2')
net.addHost('h3')
net.addHost('h4')
net.addHost('h5')
net.addHost('h6')
net.addHost('h7')
net.addHost('h8')


net.setP4Source('s1','dxr.p4')
net.setP4CliInput('s1', 'cmd.txt')

net.addLink('s1', 'h1')
net.addLink('s1', 'h2')
net.addLink('s1', 'h3')
net.addLink('s1', 'h4')
net.addLink('s1', 'h5')
net.addLink('s1', 'h6')
net.addLink('s1', 'h7')
net.addLink('s1', 'h8')

net.setIntfPort('s1', 'h1', 1)  # Set the number of the port on s1 facing h1
net.setIntfPort('h1', 's1', 0)  # Set the number of the port on h1 facing s1
net.setIntfPort('s1', 'h2', 2)  # Set the number of the port on s1 facing h2
net.setIntfPort('h2', 's1', 0)  # Set the number of the port on h2 facing s1
net.setIntfPort('s1', 'h3', 3)  # Set the number of the port on s1 facing h3
net.setIntfPort('h3', 's1', 0)  # Set the number of the port on h3 facing s1
net.setIntfPort('s1', 'h4', 4)  # Set the number of the port on s1 facing h4
net.setIntfPort('h4', 's1', 0)  # Set the number of the port on h4 facing s1
net.setIntfPort('s1', 'h5', 5)  
net.setIntfPort('h5', 's1', 0)
net.setIntfPort('s1', 'h6', 6)  
net.setIntfPort('h6', 's1', 0)
net.setIntfPort('s1', 'h7', 7)  
net.setIntfPort('h7', 's1', 0)
net.setIntfPort('s1', 'h8', 8)  
net.setIntfPort('h8', 's1', 0)

net.setIntfIp('h1','s1','3.6.22.33/32')
net.setIntfIp('h2','s1','30.11.13.23/32')
net.setIntfIp('h3','s1','23.33.1.8/32')
net.setIntfIp('h4','s1','12.36.123.92/24')
net.setIntfIp('h5','s1','12.36.123.217/24')
net.setIntfIp('h6','s1','12.36.123.125/24')
net.setIntfIp('h7','s1','12.36.123.169/24')
net.setIntfIp('h8','s1','12.36.123.40/24')

index = [0, 0, 0, 0, 0]
index[2] = index[2] + 1


# 40 92 125 169 217
#       125(0)              125(1)
#    40(0)     169(1)     38(2)   180(3)
#       92      217
#
#1.1.123.125


# net.setIntfIp('s1','h1','3.6.0.1/32')
# net.setIntfIp('s1','h2','30.11.0.1/32')
# net.setIntfIp('s1','h3','23.33.0.1/32')
# net.setIntfIp('s1','h4','12.36.0.1/32')

net.setDefaultRoute('h1', '3.6.22.33')
net.setDefaultRoute('h2', '30.11.13.23')
net.setDefaultRoute('h3', '23.33.1.8')
net.setDefaultRoute('h4', '12.36.123.92')
net.setDefaultRoute('h5', '12.36.123.217')
net.setDefaultRoute('h6', '12.36.123.125')
net.setDefaultRoute('h7', '12.36.123.169')
net.setDefaultRoute('h8', '12.36.123.40')

net.enablePcapDumpAll()
net.enableLogAll()

net.enableCli()
net.startNetwork()
