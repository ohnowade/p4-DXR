/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

struct metadata {
    bit<8> currentNode;
    bool matched;
}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        /* TODO: add parser logic */
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4 : parse_ipv4;
            default : accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }
}


/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

action forward(inout standard_metadata_t standard_metadata, 
               inout ipv4_t ipv4_hdr, 
               in egressSpec_t port) {
    standard_metadata.egress_spec = port;
    ipv4_hdr.ttl = ipv4_hdr.ttl - 1;
}

action get_next_node(inout standard_metadata_t standard_metadata, 
                     inout ipv4_t ipv4_hdr,
                     inout metadata meta, 
                     ip4Addr_t addr_val, 
                     bit<9> port, 
                     bit<8> left, 
                     bit<8> right) {
    if (ipv4_hdr.dstAddr == addr_val) {
        meta.matched = true;
        forward(standard_metadata, ipv4_hdr, port);
    }
    else if (ipv4_hdr.dstAddr < addr_val) {
        meta.currentNode = left;
    } else {
        meta.currentNode = right;
    }
}

// Binary tree stages
control Stage1(inout standard_metadata_t standard_metadata, 
               inout metadata meta, 
               inout ipv4_t ipv4_hdr) {
    table root {
        key = {
            meta.currentNode: exact;
        }
        actions = {
            get_next_node(standard_metadata, ipv4_hdr, meta);
            NoAction;
        }
        size = 1;
        default_action = NoAction();
    }

    apply {
        root.apply();
    }
}

control Stage2(inout standard_metadata_t standard_metadata, 
               inout metadata meta, 
               inout ipv4_t ipv4_hdr) {
    table nodes {
        key = {
            meta.currentNode: exact;
        }
        actions = {
            get_next_node(standard_metadata, ipv4_hdr, meta);
            NoAction;
        }
        size = 2;
        default_action = NoAction();
    }

    apply {
        nodes.apply();
    }
}

control Stage3(inout standard_metadata_t standard_metadata, 
               inout metadata meta, 
               inout ipv4_t ipv4_hdr) {
    table leaves {
        key = {
            meta.currentNode: exact;
        }
        actions = {
            get_next_node(standard_metadata, ipv4_hdr, meta);
            NoAction;
        }
        size = 4;
        default_action = NoAction();
    }

    apply {
        leaves.apply();
    }
}


control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    Stage1() stage1;
    Stage2() stage2;
    Stage3() stage3;

    apply {
        meta.currentNode = 1;
        meta.matched = false;
        stage1.apply(standard_metadata, meta, hdr.ipv4);
        if (!meta.matched) stage2.apply(standard_metadata, meta, hdr.ipv4);
        if (!meta.matched) stage3.apply(standard_metadata, meta, hdr.ipv4);
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {  }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
     apply {
        update_checksum(
            hdr.ipv4.isValid(),
            { hdr.ipv4.version,
              hdr.ipv4.ihl,
              hdr.ipv4.diffserv,
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
    }
}


/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        /* TODO: add deparser logic */
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;