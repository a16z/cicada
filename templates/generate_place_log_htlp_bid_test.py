from Crypto.PublicKey import RSA
from jinja2 import Environment, FileSystemLoader
from pprint import pprint
import random
from web3 import Web3

MAX_UINT256 = pow(2, 256) - 1


random.seed(69)


def to_uint_1024(x):
    binaryString = '{0:0{1}b}'.format(x, 2).zfill(1024)
    parts = [binaryString[:256], binaryString[256:512],
             binaryString[512:768], binaryString[768:]]
    return [int(part, 2) for part in parts]


def dict_to_uint_1024(d):
    converted = {}
    for k, v in d.items():
        if k == 'c0' or k == 'c1':
            converted[k] = v
        else:
            converted[k] = to_uint_1024(v)
    return converted


def normalize(x, N):
    return x if x < N / 2 else N - x


def simulator(N, g, h, u, v, r, yInvS=1):
    c = random.randint(0, MAX_UINT256)
    t = random.randint(0, MAX_UINT256) + r * c
    a = normalize((pow(g, t, N) * pow(u, -c, N)) % N, N)
    b = normalize((pow(h, t, N) * pow(v * yInvS, -c, N)) % N, N)
    return (a, b, c, t)


def generate_puzzle(N, g, h, y, yInv, parametersHash, bidderId):
    # Bid
    bidderFlag = (1 << (bidderId - 1))
    r = random.randint(0, MAX_UINT256)
    s = random.randint(0, 1) * bidderFlag  # secret bid bit
    u = normalize(pow(g, r, N), N)
    v = normalize((pow(h, r, N) * pow(y, s, N)) % N, N)

    # Proof of bid validity
    a0 = b0 = c0 = t0 = a1 = b1 = c1 = t1 = None

    if s == 0:
        a1, b1, c1, t1 = simulator(N, g, h, u, v, r, pow(yInv, bidderFlag, N))
        r0 = random.randint(0, MAX_UINT256)
        a0 = normalize(pow(g, r0, N), N)
        b0 = normalize(pow(h, r0, N), N)
        c = int.from_bytes(Web3.solidityKeccak(
            ['uint256[4]'] * 4 + ['bytes32'],
            [to_uint_1024(a0), to_uint_1024(
                b0), to_uint_1024(a1), to_uint_1024(b1), parametersHash]
        ), byteorder='big')
        c0 = (c - c1) % pow(2, 256)
        t0 = r0 + c0 * r
    else:
        a0, b0, c0, t0 = simulator(N, g, h, u, v, r)
        r1 = random.randint(0, MAX_UINT256)
        a1 = normalize(pow(g, r1, N), N)
        b1 = normalize(pow(h, r1, N), N)
        c = int.from_bytes(Web3.solidityKeccak(
            ['uint256[4]'] * 4 + ['bytes32'],
            [to_uint_1024(a0), to_uint_1024(
                b0), to_uint_1024(a1), to_uint_1024(b1), parametersHash]
        ), byteorder='big')
        c1 = (c - c0) % pow(2, 256)
        t1 = r1 + c1 * r

    return {'u': u, 'v': v}, {'a0': a0, 'b0': b0, 't0': t0, 'c0': c0, 'a1': a1, 'b1': b1, 't1': t1, 'c1': c1}


def generate_bid_test(numBidBits, bidderId):
    # Public parameters
    # N = RSA.generate(1024).n
    N = 119811489572127862002400473548445165991417646257390315534749434310249361630773111446686986365667134131769700968038508003183790050995248795868556415935896469708804065561524199281221524011292023692346224158949981067042940731981798525413610618627831152737911921198417981708100865711902031939654050023574809255253
    T = random.randint(1000, 100000)
    g = normalize(random.randint(0, N), N)
    h = normalize(pow(g, 2 ** T, N), N)
    y = normalize(random.randint(0, N), N)
    yInv = normalize(pow(y, -1, N), N)

    parametersHash = Web3.solidityKeccak(
        ['uint256'] + ['uint256[4]'] * 5,
        [T, to_uint_1024(N), to_uint_1024(g), to_uint_1024(h),
         to_uint_1024(y), to_uint_1024(yInv)]
    )

    # Hardcoded msg.sender address for VerifyBidGeneratedTest contract
    parametersHash = Web3.solidityKeccak(
        ['bytes32', 'bytes32'],
        [parametersHash, '0x0000000000000000000000007fa9385be102ac3eac297483dd6233d62b3e1496']
    )

    puzzles = []
    proofs = []
    for _ in range(numBidBits):
        puzzle, proof = generate_puzzle(
            N, g, h, y, yInv, parametersHash, bidderId)
        puzzles.append(puzzle)
        proofs.append(proof)

    environment = Environment(
        loader=FileSystemLoader("templates/"),
        trim_blocks=True,
        lstrip_blocks=True
    )
    template = environment.get_template("PlaceLogHTLPBidTest.sol.jinja")

    [N, g, h, y, yInv] = map(
        lambda x: to_uint_1024(x),
        [N, g, h, y, yInv]
    )
    rendered = template.render(
        numBidBits=numBidBits,
        N=N, T=T, g=g, h=h, y=y, yInv=yInv,
        puzzles=map(dict_to_uint_1024, puzzles),
        proofs=map(dict_to_uint_1024, proofs),
    )
    print(rendered)


generate_bid_test(16, 2)
