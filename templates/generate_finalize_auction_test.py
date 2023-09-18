from Crypto.PublicKey import RSA
from jinja2 import Environment, FileSystemLoader
from pprint import pprint
import random
from sympy import isprime
from web3 import Web3

MAX_UINT256 = pow(2, 256) - 1
HIGH_BIT = pow(2, 255)

random.seed(420)


def to_uint_1024(x):
    binaryString = '{0:0{1}b}'.format(x, 2).zfill(1024)
    parts = [binaryString[:256], binaryString[256:512],
             binaryString[512:768], binaryString[768:]]
    return [int(part, 2) for part in parts]


def dict_to_uint_1024(d):
    converted = {}
    for k, v in d.items():
        converted[k] = to_uint_1024(v)
    return converted


def normalize(x, N):
    return x if x < N / 2 else N - x


def generate_puzzle_and_proof(T, N, g, y, parametersHash, s):
    r = random.randint(0, MAX_UINT256)

    u = normalize(pow(g, r, N), N)
    w = normalize(pow(u, 2 ** T, N), N)
    v = normalize((w * pow(y, s, N)) % N, N)

    j = 0
    l = None
    while True:
        hash = int.from_bytes(Web3.solidityKeccak(
            ['uint256[4]', 'uint256[4]', 'bytes32', 'uint256'],
            [to_uint_1024(u), to_uint_1024(w), parametersHash, j]
        ), byteorder='big')
        candidate = hash | HIGH_BIT
        if isprime(candidate):
            l = candidate
            break
        j += 1

    q = (2 ** T) // l
    pi = normalize(pow(u, q, N), N)

    return {'u': u, 'v': v}, {'pi': pi, 'l': l, 'j': j}, w


def generate_finalize_auction_test(numBidBits):
    # Public parameters
    N = RSA.generate(1024).n
    T = random.randint(1000, 100000)
    g = normalize(random.randint(0, N), N)
    h = normalize(pow(g, 2 ** T, N), N)
    y = normalize(random.randint(0, N), N)
    yInv = pow(y, -1, N)

    parametersHash = Web3.solidityKeccak(
        ['uint256'] + ['uint256[4]'] * 5,
        [T, to_uint_1024(N), to_uint_1024(g), to_uint_1024(h),
         to_uint_1024(y), to_uint_1024(yInv)]
    )

    w = []
    talliesPlaintext = []
    tallies = []
    proofs = []
    for _ in range(numBidBits):
        s = random.randint(0, 1) * 7 # All three bidders tie
        tally, proof, w_i = generate_puzzle_and_proof(
            T, N, g, y, parametersHash, s)
        tallies.append(tally)
        proofs.append(proof)
        talliesPlaintext.append(s)
        w.append(to_uint_1024(w_i))

    environment = Environment(
        loader=FileSystemLoader("templates/"),
        trim_blocks=True,
        lstrip_blocks=True
    )
    template = environment.get_template("FinalizeAuctionTest.sol.jinja")

    [N, g, h, y, yInv] = map(
        lambda x: to_uint_1024(x),
        [N, g, h, y, yInv]
    )

    for proof in proofs:
        proof['pi'] = to_uint_1024(proof['pi'])

    rendered = template.render(
        N=N, T=T, g=g, h=h, y=y, yInv=yInv,
        tallies=map(dict_to_uint_1024, tallies),
        talliesPlaintext=talliesPlaintext,
        proofs=proofs, w=w, numBidBits=numBidBits
    )
    print(rendered)


generate_finalize_auction_test(16)
