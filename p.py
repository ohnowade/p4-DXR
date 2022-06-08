import preprocess


class Tree:
    def __init__(self, level, index, value, hop, left, right):  # value = last 16 biy
        self.left = left
        self.right = right
        self.value = value
        self.level = level
        self.hop = hop
        self.index = index


def add_broadcast_group(num):
    f = open('cmd1.txt', 'a')
    f.write('mc_mgrp_create 1\n')
    for i in range(1, num + 1):
        f.write('mc_node_create {} {}\n'.format(i - 1, i))
        f.write('mc_node_associate 1 {}\n'.format(i - 1))
    f.close()


def buildBtree(treelist, levelindex):
    return treeHelper(treelist, 1, len(treelist)-1, 0, levelindex)


def treeHelper(treelist, level, high, low, levelindex):
    if high < low:
        # print('stop')
        return None

    if levelindex.get(level) == None:
        levelindex.update({level: 0})

    currlevelindex = levelindex[level] + 1
    levelindex[level] = currlevelindex
    mid = int(low + (high-low)/2)  # find middle one add to node
    # print(mid)
    tuple = treelist[mid]
    last_s16 = tuple[0]
    nexthop = tuple[1]
    #tmp = mid-1
    #print("left high low: ",tmp,low )
    left = treeHelper(treelist, level+1, mid-1, low, levelindex)

    #tmp = mid + 1
    #print("right high low: " ,high, tmp )
    right = treeHelper(treelist, level+1, high, mid+1, levelindex)
    # build a level list
    Current = Tree(level, currlevelindex, last_s16, nexthop, left, right)
    return Current


def convet(treelist, f):
    for tree in treelist:
        conTree(tree, f)


def conTree(tree, f):
    table_name = "range_table_level_" + str(tree.level)
    f.write("table_add " + table_name + " get_next_node " +
            str(tree.index) + ' => ' + str(tree.value) + " " + str(tree.hop) + " ")
    if(tree.left == None):
        f.write('0 ')
    else:
        f.write(str(tree.left.index))
        f.write(" ")
    if(tree.right == None):
        f.write('0')
    else:
        f.write(str(tree.right.index))
    f.write('\n')

    if tree.left != None:
        conTree(tree.left, f)
    if tree.right != None:
        conTree(tree.right, f)


def main():
    #list, dict
    lookupTable, prefixesDict = preprocess.createTables()
    # print(lookupTable)
    print(prefixesDict.get(14665))
    # create next hop dic
    dict_nh = {None: 0, 'default': 1}

    file_name = 'cmd1.txt'
    f = open(file_name, 'w+')  # open file in append mode
    i = 0
    index_nh = 0
    totalli = {}
    treelist = []
    for element in lookupTable:
        # give nexthop index
        if element in dict_nh:
            index_nh = dict_nh.get(element)
        else:
            index_nh = len(dict_nh)
            dict_nh.update({element: index_nh})

        # Now we have the next hop index
        # build loop up table, and build tree
        # later access tree and build range table

        if element == None:  # range table
            # build tree
            listOfTuple = prefixesDict.get(i)
            if(listOfTuple == None):
                f.write('table_add lookup_table get_range_table ' +
                        str(i) + ' => 0 1\n')
                i += 1
                continue
            # print(listOfTuple)
            # update tuple hop
            listOfUpdateTuple = []
            for entry in listOfTuple:
                if entry[2] in dict_nh:
                    nh = dict_nh.get(entry[2])
                else:
                    nh = len(dict_nh)
                    dict_nh.update({entry[2]: nh})
                listOfUpdateTuple.append((entry[0], nh))
            Node = buildBtree(listOfUpdateTuple, totalli)
            treelist.append(Node)
            f.write('table_add lookup_table get_range_table ' +
                    str(i) + ' => ' + str(totalli[1]) + ' 0\n')
        else:  # loopup table
            # find next hop index
            f.write('table_add lookup_table get_range_table ' +
                    str(i) + ' => 0 ' + str(index_nh)+'\n')
        i += 1
    # print(totalli)
    convet(treelist, f)
    # the rest of list has value none, -> index is key is
    # call
    print(dict_nh)
    print(totalli)
    f.close()
    add_broadcast_group(3)


main()
