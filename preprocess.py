from collections import defaultdict
from contextlib import nullcontext
from mailbox import _PartialFile
from os import popen
import re
from sys import prefix
from tkinter.messagebox import YES

from numpy import bitwise_and, maximum, minimum
from tqdm import tqdm


def ipv4ToString(ipv4):
    # 1.0.4.0
    ipv4 = ipv4.split('.')

    res = 0b00000000000000000000000000000000
    for i in ipv4:
        binInt = int(i)
        res <<= 8
        res = res | binInt
    res = f'{res:032b}'
    return res


def getRange(ipv4, filter=32):

    ipv4String = ipv4ToString(ipv4)
    minimum = ipv4String[:filter] + '0' * (32-filter)
    maximum = ipv4String[:filter] + '1' * (32-filter)

    return (minimum, maximum)


def createTables():
    lookupTable = [None] * (2**16)
    prefixesDict = defaultdict(list)
    with open('bgptable.txt') as f:
        for line in tqdm(f):
            results = re.match(
                r'\*.*(\d+\.\d+\.\d+\.\d+/?\d*).*(\d+\.\d+\.\d+\.\d+)', line)
            if results == None:
                continue
            # tranform to string

            results = results.group(0)
            results = results.split(' ')
            results = list(
                filter(lambda val: val != '' and val != '*' and val != '*>', results))

            ipv4 = results[0].split('/')
            filterIndex = 32
            nextHop = results[1]
            if len(ipv4) > 1:
                filterIndex = int(ipv4[1])
                curRange = getRange(ipv4[0], filterIndex)
            else:
                curRange = getRange(ipv4[0])

            if filterIndex > 16:
                keyPrefix = int(curRange[0], 2) >> 16
                minRange = int(curRange[0][16:], 2)
                maxRange = int(curRange[1][16:], 2)

                '''
                Look Range
                None None
                None YES
                Yes None -> None Yes
                '''
                # never have exact match
                if(lookupTable[keyPrefix] == None):
                    if keyPrefix not in prefixesDict:
                        # range table is empty
                        # insert first range
                        prefixesDict[keyPrefix] = [
                            (minRange, maxRange, nextHop)]
                    else:
                        # range table not empty
                        # check whether there is an overlap range
                        for j in range(len(prefixesDict[keyPrefix])):
                            existingMin = prefixesDict[keyPrefix][j][0]
                            existingMax = prefixesDict[keyPrefix][j][1]
                            existNextHop = prefixesDict[keyPrefix][j][2]
                            if existingMax > minRange:
                                # Overlap detect
                                # pop this overlap range first
                                prefixesDict[keyPrefix].pop(j)
                                if (existingMax == maxRange):
                                    if minRange - existingMin > 0:
                                        prefixesDict[keyPrefix].append(
                                            (existingMin, minRange - 1, existNextHop))
                                    prefixesDict[keyPrefix].append(
                                        (minRange, maxRange, nextHop))

                                elif (existingMin == minRange):
                                    prefixesDict[keyPrefix].append(
                                        (minRange, maxRange, nextHop))
                                    if existingMax - maxRange > 0:
                                        prefixesDict[keyPrefix].append(
                                            (maxRange + 1, existingMax, existNextHop))

                                else:
                                    if minRange - existingMin > 0:
                                        prefixesDict[keyPrefix].append(
                                            (existingMin, minRange - 1, existNextHop))
                                    prefixesDict[keyPrefix].append(
                                        (minRange, maxRange, nextHop))
                                    if existingMax - maxRange > 0:
                                        prefixesDict[keyPrefix].append(
                                            (maxRange + 1,  existingMax, existNextHop))

                                break
                        else:

                            prefixesDict[keyPrefix].append(
                                (minRange, maxRange, nextHop))

                        prefixesDict[keyPrefix] = sorted(
                            prefixesDict[keyPrefix], key=lambda x: x[0])

                else:

                    if minRange == 0 and maxRange == 2 ** 16 - 1:
                        prefixesDict[keyPrefix].append((
                            minRange, maxRange, nextHop))
                    elif minRange == 0:
                        prefixesDict[keyPrefix].append((0, maxRange, nextHop))
                        prefixesDict[keyPrefix].append((
                            maxRange + 1, 2**16-1, lookupTable[keyPrefix]))
                    elif maxRange == 2**16 - 1:
                        prefixesDict[keyPrefix].append((
                            0, minRange-1, lookupTable[keyPrefix]))
                        prefixesDict[keyPrefix].append((
                            minRange, maxRange, nextHop))
                    else:
                        prefixesDict[keyPrefix].append((
                            0, minRange - 1, lookupTable[keyPrefix]))
                        prefixesDict[keyPrefix].append((
                            minRange, maxRange, nextHop))
                        prefixesDict[keyPrefix].append((
                            maxRange+1, 2**16-1, lookupTable[keyPrefix]))

                    lookupTable[keyPrefix] = None

            else:
                minPrefix = int(curRange[0], 2) >> 16
                maxPrefix = int(curRange[1], 2) >> 16
                for i in range(minPrefix, maxPrefix+1):
                    lookupTable[i] = nextHop

    # insertDefault for rangeTable
    for key in prefixesDict.keys():
        curIndex = 0
        curRangeTable = prefixesDict[key][:]
        for i in range(len(curRangeTable)):
            if curIndex < curRangeTable[i][0]:
                prefixesDict[key].append(
                    (curIndex, curRangeTable[i][0] - 1, 'default'))

            curIndex = curRangeTable[i][1] + 1

        if curIndex <= (2**16 - 1):
            prefixesDict[key].append(
                (curIndex, 2**16 - 1, 'default'))

        prefixesDict[key] = sorted(
            prefixesDict[key], key=lambda x: x[0])

    # merge range with same nextHop
    for key in prefixesDict.keys():
        newRangeTable = []

        for i in range(len(prefixesDict[key])):

            if (len(newRangeTable) > 0 and newRangeTable[-1][2] == prefixesDict[key][i][2] and newRangeTable[-1][1] + 1 == prefixesDict[key][i][0]):
                popRange = newRangeTable.pop()
                newRangeTable.append(
                    (popRange[0], prefixesDict[key][i][1], popRange[2]))
            else:
                newRangeTable.append(prefixesDict[key][i])

        prefixesDict[key] = newRangeTable[:]

    return lookupTable, prefixesDict
