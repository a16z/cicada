import argparse
from eth_abi import encode


def bigAdd(args):
    expectNumInputs(args, 2)
    a = int(args.inputs[0], 0)
    b = int(args.inputs[1], 0)
    encodeBigNumber(a + b)

def bigSub(args):
    expectNumInputs(args, 2)
    a = int(args.inputs[0], 0)
    b = int(args.inputs[1], 0)
    encodeBigNumber(a - b)

def bigGte(args):
    expectNumInputs(args, 2)
    a = int(args.inputs[0], 0)
    b = int(args.inputs[1], 0)
    encoded = encode(['bool'], [a >= b])
    print('0x' + encoded.hex())

def bigLte(args):
    expectNumInputs(args, 2)
    a = int(args.inputs[0], 0)
    b = int(args.inputs[1], 0)
    encoded = encode(['bool'], [a <= b])
    print('0x' + encoded.hex())

def bigAddMod(args):
    expectNumInputs(args, 3)
    a = int(args.inputs[0], 0)
    b = int(args.inputs[1], 0)
    m = int(args.inputs[2], 0)
    encodeBigNumber((a + b) % m)

def bigSubMod(args):
    expectNumInputs(args, 3)
    a = int(args.inputs[0], 0)
    b = int(args.inputs[1], 0)
    m = int(args.inputs[2], 0)
    encodeBigNumber((a - b) % m)

def expectNumInputs(args, n):
    if len(args.inputs) != n:
        raise Exception('Expected {} inputs, received {}'.format(n, len(args.inputs)))

def encodeBigNumber(x):
    words = [(x >> (i * 256)) % (2 ** 256) for i in range(8)]
    words.reverse()
    encoded = encode(['uint256[8]'], [words])
    print('0x' + encoded.hex())

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-o', '--operation')
    parser.add_argument('-i', '--inputs', nargs='+')
    args = parser.parse_args()

    if args.operation == 'add':
        bigAdd(args)
    if args.operation == 'sub':
        bigSub(args)
    if args.operation == 'gte':
        bigGte(args)
    if args.operation == 'lte':
        bigLte(args)
    if args.operation == 'addMod':
        bigAddMod(args)
    if args.operation == 'subMod':
        bigSubMod(args)
