/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;
const bit<16> TYPE_ARP = 0x806;

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
    bit<16> next_node_id;
    bool matched;
    bool isARP;
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
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4 : parse_ipv4;
            TYPE_ARP: parse_arp;
            default : accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        meta.matched = false;
        transition accept;
    }

    state parse_arp {
        meta.isARP = true;
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

control QueryLookupTable(inout headers hdr,
                         inout metadata meta,
                         inout standard_metadata_t standard_metadata) {

    action get_range_table(bit<16> top_level_id,
                           bit<3> next_hop) {
        if (top_level_id > 0) {
            meta.matched = false;
            meta.next_node_id = top_level_id;
        } else {
            meta.matched = true;
            standard_metadata.egress_spec = next_hop;
            hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        }
    }
    
    table lookup_table {
        key = {
            hdr.ipv4.dstAddr >> 16: exact @name("first_16_bit");
            //hdr.ipv4.dstAddr : exact;
        }
        actions = {
            get_range_table();
            NoAction;
        }
        size = 65536;
        default_action = NoAction();
    }

    apply {
        lookup_table.apply();
    }
}

action get_next_node(inout headers hdr,
                     inout metadata meta,
                     inout standard_metadata_t standard_metadata,
                     bit<16> val,
                     bit<3> next_hop,
                     bit<16> left_node,
                     bit<16> right_node) {
    bit<16> last_16_bits = (bit<16>)(hdr.ipv4.dstAddr & 0xFFFF);
    if (last_16_bits >= val) {
        standard_metadata.egress_spec = next_hop;
        if (right_node == 0) {
            meta.matched = true;
            hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        } else {
            meta.next_node_id = right_node;
        }
    } else {
        if (left_node == 0) {
            meta.matched = true;
            hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        } else {
            meta.next_node_id = left_node;
        }
    }
}

control RangeTableStage1(inout headers hdr,
                         inout metadata meta,
                         inout standard_metadata_t standard_metadata) {
    table range_table_level_1 {
        key =  {
            meta.next_node_id : exact;
        }
        actions = {
            get_next_node(hdr, meta, standard_metadata);
            NoAction;
        }
        size = 27000;
        default_action = NoAction();
    }

    apply {
        range_table_level_1.apply();
    }  
}

control RangeTableStage2(inout headers hdr,
                         inout metadata meta,
                         inout standard_metadata_t standard_metadata) {
    table range_table_level_2 {
        key =  {
            meta.next_node_id : exact;
        }
        actions = {
            get_next_node(hdr, meta, standard_metadata);
            NoAction;
        }
        size = 27000;
        default_action = NoAction();
    }

    apply {
        range_table_level_2.apply();
    }  
}

control RangeTableStage3(inout headers hdr,
                         inout metadata meta,
                         inout standard_metadata_t standard_metadata) {
    table range_table_level_3 {
        key =  {
            meta.next_node_id : exact;
        }
        actions = {
            get_next_node(hdr, meta, standard_metadata);
            NoAction;
        }
        size = 31000;
        default_action = NoAction();
    }

    apply {
        range_table_level_3.apply();
    }  
}

control RangeTableStage4(inout headers hdr,
                         inout metadata meta,
                         inout standard_metadata_t standard_metadata) {
    table range_table_level_4 {
        key =  {
            meta.next_node_id : exact;
        }
        actions = {
            get_next_node(hdr, meta, standard_metadata);
            NoAction;
        }
        size = 39000;
        default_action = NoAction();
    }

    apply {
        range_table_level_4.apply();
    }  
}

control RangeTableStage5(inout headers hdr,
                         inout metadata meta,
                         inout standard_metadata_t standard_metadata) {
    table range_table_level_5 {
        key =  {
            meta.next_node_id : exact;
        }
        actions = {
            get_next_node(hdr, meta, standard_metadata);
            NoAction;
        }
        size = 45000;
        default_action = NoAction();
    }

    apply {
        range_table_level_5.apply();
    }  
}

control RangeTableStage6(inout headers hdr,
                         inout metadata meta,
                         inout standard_metadata_t standard_metadata) {
    table range_table_level_6 {
        key =  {
            meta.next_node_id : exact;
        }
        actions = {
            get_next_node(hdr, meta, standard_metadata);
            NoAction;
        }
        size = 45200;
        default_action = NoAction();
    }

    apply {
        range_table_level_6.apply();
    }  
}

control RangeTableStage7(inout headers hdr,
                         inout metadata meta,
                         inout standard_metadata_t standard_metadata) {
    table range_table_level_7 {
        key =  {
            meta.next_node_id : exact;
        }
        actions = {
            get_next_node(hdr, meta, standard_metadata);
            NoAction;
        }
        size = 36000;
        default_action = NoAction();
    }

    apply {
        range_table_level_7.apply();
    }  
}

control RangeTableStage8(inout headers hdr,
                         inout metadata meta,
                         inout standard_metadata_t standard_metadata) {
    table range_table_level_8 {
        key =  {
            meta.next_node_id : exact;
        }
        actions = {
            get_next_node(hdr, meta, standard_metadata);
            NoAction;
        }
        size = 12000;
        default_action = NoAction();
    }

    apply {
        range_table_level_8.apply();
    }  
}

control RangeTableStage9(inout headers hdr,
                         inout metadata meta,
                         inout standard_metadata_t standard_metadata) {
    table range_table_level_9 {
        key =  {
            meta.next_node_id : exact;
        }
        actions = {
            get_next_node(hdr, meta, standard_metadata);
            NoAction;
        }
        size = 1500;
        default_action = NoAction();
    }

    apply {
        range_table_level_9.apply();
    }  
}

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    action drop() {
        mark_to_drop(standard_metadata);
    }

    QueryLookupTable() queryLookupTable;
    RangeTableStage1() rangeTableStage1;
    RangeTableStage2() rangeTableStage2;
    RangeTableStage3() rangeTableStage3;
    RangeTableStage4() rangeTableStage4;
    RangeTableStage5() rangeTableStage5;
    RangeTableStage6() rangeTableStage6;
    RangeTableStage7() rangeTableStage7;
    RangeTableStage8() rangeTableStage8;
    RangeTableStage9() rangeTableStage9;

    apply {
        if (meta.isARP) {
            standard_metadata.mcast_grp = 1;
        }
        else {
            queryLookupTable.apply(hdr, meta, standard_metadata);
            if (meta.matched) exit;
            rangeTableStage1.apply(hdr, meta, standard_metadata);
            if (meta.matched) exit;
            rangeTableStage2.apply(hdr, meta, standard_metadata);
            if (meta.matched) exit;
            rangeTableStage3.apply(hdr, meta, standard_metadata);
            if (meta.matched) exit;
            rangeTableStage4.apply(hdr, meta, standard_metadata);
            if (meta.matched) exit;
            rangeTableStage5.apply(hdr, meta, standard_metadata);
            if (meta.matched) exit;
            rangeTableStage6.apply(hdr, meta, standard_metadata);
            if (meta.matched) exit;
            rangeTableStage7.apply(hdr, meta, standard_metadata);
            if (meta.matched) exit;
            rangeTableStage8.apply(hdr, meta, standard_metadata);
            if (meta.matched) exit;
            rangeTableStage9.apply(hdr, meta, standard_metadata);
        }
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