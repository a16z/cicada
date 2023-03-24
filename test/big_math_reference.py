import argparse
import math
from eth_abi import encode


def bigAdd(args):
    [a, b] = parseInputs(args, 2)
    encodeBigNumber(a + b)


def bigSub(args):
    [a, b] = parseInputs(args, 2)
    encodeBigNumber(a - b)


def bigGte(args):
    [a, b] = parseInputs(args, 2)
    encoded = encode(['bool'], [a >= b])
    print('0x' + encoded.hex())


def bigLte(args):
    [a, b] = parseInputs(args, 2)
    encoded = encode(['bool'], [a <= b])
    print('0x' + encoded.hex())


def bigAddMod(args):
    [a, b, m] = parseInputs(args, 3)
    encodeBigNumber((a + b) % m)


def bigSubMod(args):
    [a, b, m] = parseInputs(args, 3)
    encodeBigNumber((a - b) % m)


def bigExpMod(args):
    [a, e, m] = parseInputs(args, 3)
    if e == 0:
        encodeBigNumber(1)
        return

    p = a % m
    result = p if (e & 1) else 1
    for i in range(2, int(math.log2(e)) + 2):
        p = (p ** 2) % m
        if e & (1 << (i - 1)):
            result = (result * p) % m
    encodeBigNumber(result)


def bigMulMod(args):
    [a, b, m] = parseInputs(args, 3)
    encodeBigNumber((a * b) % m)


def parseInputs(args, n):
    if len(args.inputs) != n:
        raise Exception(
            'Expected {} inputs, received {}'.format(n, len(args.inputs)))
    return [int(x, 0) for x in args.inputs]


def encodeBigNumber(x):
    words = [(x >> (i * 256)) % (2 ** 256) for i in range(4)]
    words.reverse()
    encoded = encode(['uint256[4]'], [words])
    print('0x' + encoded.hex())


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-o', '--operation')
    parser.add_argument('-i', '--inputs', nargs='+')
    args = parser.parse_args()

    if args.operation == 'add':
        bigAdd(args)
    elif args.operation == 'sub':
        bigSub(args)
    elif args.operation == 'gte':
        bigGte(args)
    elif args.operation == 'lte':
        bigLte(args)
    elif args.operation == 'addMod':
        bigAddMod(args)
    elif args.operation == 'subMod':
        bigSubMod(args)
    elif args.operation == 'expMod':
        bigExpMod(args)
    elif args.operation == 'mulMod':
        bigMulMod(args)
    else:
        raise Exception('Unrecognized operation: {}'.format(args.operation))
