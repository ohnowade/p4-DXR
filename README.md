# p4-DXR
To craete a topology in Mininet and run our P4 program as a switch, we make use of the tool P4-Utils. It not only provides a script that automatically install all dependencies, it also provides a Python module, which defines and runs the Mininet topology with P4 programs integrated, and a CLI command that takes in a JSON file as its input to realize the same functionality. The detail of P4-Utils can be found at https://github.com/nsg-ethz/p4-utils#requirements.

Our logic of preprocessing is located in ``` preprocess.py ```. ``` p.py ``` includes codes to start preprocessing and generate control plane commands for our P4 program. Our P4 implementation of the DXR algorithm is in ``` dxr.p4 ```. To test our implementation, we define and run the Mininet topology in ``` rundxr.py ```.

Here are the steps to run our code:
1. Put bgptable.txt under the same directory as all other source files.
2. Run ``` python3 p.py ``` to preprocess the input prefixes and generate control plane commands for our p4 program; all commands will be written to file ``` cmd1.txt ``` (Note that we have already generated all commands in ``` cmd1.txt ``` and pushed the file to the repository, so it is ok to skip step 2).
3. Run ``` sudo python3 rundxr.py ``` to start the defined topology in Mininet. After the running, it enters the command line of Mininet.
4. Run Mininet commands to test the connections among hosts (for example ``` pingall ```).
5. The log of the switch implemented by our P4 program is located in ``` ./log/p4s.s1.log ```. The pcap directory is ```./pcap ```, and the files can be checked with ``` tcpdump ``` command.
