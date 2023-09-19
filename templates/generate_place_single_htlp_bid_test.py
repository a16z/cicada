from Crypto.PublicKey import RSA
from jinja2 import Environment, FileSystemLoader
from pprint import pprint
import random
from web3 import Web3
import itertools

random.seed(420)

MAX_UINT256 = pow(2, 256) - 1
SQUARES = [i * i for i in range(20)]


def to_uint_1024(x):
    binaryString = '{0:0{1}b}'.format(x, 2).zfill(1024)
    parts = [binaryString[:256], binaryString[256:512],
             binaryString[512:768], binaryString[768:]]
    return [int(part, 2) for part in parts]


def normalize(x, N):
    x = x % N
    return x if x < N / 2 else N - x


def gen_htlp(N, g, h, y, s, rSplit=1):
    r = random.randint(0, int(MAX_UINT256 // rSplit))
    u = normalize(pow(g, r, N), N)
    v = normalize(pow(h, r, N) * pow(y, s, N), N)
    return (u, v, r)


def dict_to_uint_1024(d):
    converted = {}
    for k, v in d.items():
        converted[k] = to_uint_1024(v)
    return converted


def square_decompose_legendre(x):
    target = 4 * x + 1
    for (s1, s2, s3) in list(itertools.product(range(20), range(20), range(20))):
        if s1 ** 2 + s2 ** 2 + s3 ** 2 == target:
            return (s1, s2, s3)
    raise Exception("Square decomposition not found")


def proof_of_square_htlp(Z1, Z2, s, N, h, y, parametersHash):
    (_, v1, r1) = Z1
    (_, _, r2) = Z2

    [alpha1, alpha2, beta] = [
        random.randint(0, MAX_UINT256) for _ in range(3)]

    A1 = normalize(pow(h, alpha1, N) * pow(y, beta, N), N)
    A2 = normalize(pow(h, alpha2, N) * pow(v1, beta, N), N)

    e = int.from_bytes(Web3.solidityKeccak(
        ['uint256[4]'] * 2 + ['bytes32'],
        [to_uint_1024(A1), to_uint_1024(
            A2), parametersHash]
    ), byteorder='big')

    w1 = r1 * e + alpha1
    w2 = (r2 - r1 * s) * e + alpha2
    x = s * e + beta

    return {
        'A1': A1,
        'A2': A2,
        'x': x,
        'w1': w1,
        'w2': w2,
        'squareRoot': v1
    }


def proof_of_equal_htlp(Z1, Z2, s, N, h, y, parametersHash):
    (_, v1, r1) = Z1
    (_, v2, r2) = Z2

    # print(normalize(pow(h, r1, N) * pow(y, s, N), N))
    # print(v1)
    # print(normalize(pow(h, r2, N) * pow(y, s, N), N))
    # print(v2)

    [alpha1, alpha2, beta] = [
        random.randint(0, MAX_UINT256) for _ in range(3)]

    A1 = normalize(pow(h, alpha1, N) * pow(y, beta, N), N)
    A2 = normalize(pow(h, alpha2, N) * pow(y, beta, N), N)

    e = int.from_bytes(Web3.solidityKeccak(
        ['uint256[4]'] * 2 + ['bytes32'],
        [to_uint_1024(A1), to_uint_1024(
            A2), parametersHash]
    ), byteorder='big')

    w1 = alpha1 + e * r1
    w2 = alpha2 + e * r2
    x = beta + e * s

    # lhs = normalize(pow(v1, e, N) * A1, N)
    # rhs = normalize(pow(h, w1, N) * pow(y, x, N), N)
    # print(lhs, rhs)

    # lhs = normalize(pow(v2, e, N) * A2, N)
    # rhs = normalize(pow(h, w2, N) * pow(y, x, N), N)
    # print(lhs, rhs)

    PoKSEq = {
        'A1': A1,
        'A2': A2,
        'x': x,
        'w1': w1,
        'w2': w2,
    }

    # pprint(PoKSEq)

    return PoKSEq


def proof_of_valid_htlp(Z, s, N, g, h, y, parametersHash):
    (_, _, r) = Z
    t = random.randint(0, MAX_UINT256)
    x = random.randint(0, MAX_UINT256)

    a = normalize(pow(g, x, N), N)
    b = normalize(pow(h, x, N) * pow(y, t, N), N)

    e = int.from_bytes(Web3.solidityKeccak(
        ['uint256[4]'] * 2 + ['bytes32'],
        [to_uint_1024(a), to_uint_1024(b), parametersHash]
    ), byteorder='big')

    alpha = r * e + x
    beta = s * e + t

    PoPV = {
        'a': a,
        'b': b,
        'alpha': alpha,
        'beta': beta,
    }

    return PoPV


def generate_bid_test():
    # Public parameters
    # N = RSA.generate(1024).n
    N = 119811489572127862002400473548445165991417646257390315534749434310249361630773111446686986365667134131769700968038508003183790050995248795868556415935896469708804065561524199281221524011292023692346224158949981067042940731981798525413610618627831152737911921198417981708100865711902031939654050023574809255253
    T = random.randint(1000, 100000)
    g = normalize(random.randint(0, N), N)
    h = normalize(pow(g, 2 ** T, N), N)
    hInv = pow(h, -1, N)
    y = normalize(random.randint(0, N), N)
    yInv = pow(y, -1, N)
    maxBid = 100
    yM = normalize(pow(y, maxBid, N), N)

    parametersHash = Web3.solidityKeccak(
        ['uint256'] + ['uint256[4]'] * 7,
        [T, to_uint_1024(N), to_uint_1024(g), to_uint_1024(h), to_uint_1024(hInv),
         to_uint_1024(y), to_uint_1024(yInv), to_uint_1024(yM)]
    )

    # Hardcoded msg.sender address
    parametersHash = Web3.solidityKeccak(
        ['bytes32', 'bytes32'],
        [parametersHash, '0x00000000000000000000000000000000000000000000000000000c0ffee2c0de']
    )

    bid = random.randint(0, maxBid)

    (u, v, r) = Z = gen_htlp(N, g, h, y, bid)
    vInv = pow(v, -1, N)
    puzzle = ({'u': u, 'v': v})
    PoPV = proof_of_valid_htlp(Z, bid, N, g, h, y, parametersHash)

    (s_1, s_2, s_3) = square_decompose_legendre(bid)
    squareDecomposition = []
    proofsOfSquare = []

    decompositionV = 1
    decompositionR = 0

    for s_j in [s_1, s_2, s_3]:
        Z_j = gen_htlp(N, g, h, y, s_j)
        (_, v_j, r_j) = Zprime_j = gen_htlp(N, g, h, y, s_j ** 2)
        decompositionV = (decompositionV * v_j) % N
        decompositionR += r_j
        squareDecomposition.append(v_j)
        proofsOfSquare.append(proof_of_square_htlp(
            Z_j, Zprime_j, s_j, N, h, y, parametersHash)
        )

    decompositionV = normalize(decompositionV, N)

    legendre = normalize(pow(v, 4, N) * y, N)
    proofOfEquality = proof_of_equal_htlp(
        (None, decompositionV, decompositionR),
        (None, legendre, 4 * r),
        4 * bid + 1, N, h, y, parametersHash
    )

    proofOfPositivity = {
        'squareDecomposition': squareDecomposition,
        'PoKSqS': proofsOfSquare,
        'PoKSEq': proofOfEquality
    }

    (s_1, s_2, s_3) = square_decompose_legendre(maxBid - bid)
    squareDecomposition = []
    proofsOfSquare = []

    decompositionV = 1
    decompositionR = 0

    for s_j in [s_1, s_2, s_3]:
        Z_j = gen_htlp(N, g, hInv, y, s_j)
        (_, v_j, r_j) = Zprime_j = gen_htlp(N, g, hInv, y, s_j ** 2)
        decompositionV = (decompositionV * v_j) % N
        decompositionR += r_j
        squareDecomposition.append(v_j)
        proofsOfSquare.append(proof_of_square_htlp(
            Z_j, Zprime_j, s_j, N, hInv, y, parametersHash)
        )

    decompositionV = normalize(decompositionV, N)

    legendre = normalize(pow(yM * vInv % N, 4, N) * y, N)
    proofOfEquality = proof_of_equal_htlp(
        (None, decompositionV, decompositionR),
        (None, legendre, 4 * r),
        4 * (maxBid - bid) + 1, N, hInv, y, parametersHash
    )

    proofOfUpperBound = {
        'squareDecomposition': squareDecomposition,
        'PoKSqS': proofsOfSquare,
        'PoKSEq': proofOfEquality
    }

    render_template(T, N, g, h, hInv, y, yInv, vInv, yM,
                    puzzle, PoPV, proofOfPositivity, proofOfUpperBound, maxBid)


def render_template(
        T, N, g, h, hInv, y, yInv, vInv, yM,
        bid, PoPV, proofOfPositivity, proofOfUpperBound, maxBid):

    [N, g, h, hInv, y, yInv, vInv, yM] = map(
        lambda x: to_uint_1024(x),
        [N, g, h, hInv, y, yInv, vInv, yM]
    )
    
    PoKSqS = []
    for p in proofOfPositivity['PoKSqS']:
        converted = dict_to_uint_1024(p)
        if p['w2'] < 0:
            converted['w2'] = to_uint_1024(-p['w2'])
            converted['w2IsNegative'] = "true"
        else:
            converted['w2IsNegative'] = "false"
        PoKSqS.append(converted)

    proofOfPositivity = {
        'squareDecomposition': [to_uint_1024(v) for v in proofOfPositivity['squareDecomposition']],
        'PoKSqS': PoKSqS,
        'PoKSEq': dict_to_uint_1024(proofOfPositivity['PoKSEq']),
    }

    PoKSqS = []
    for p in proofOfUpperBound['PoKSqS']:
        converted = dict_to_uint_1024(p)
        if p['w2'] < 0:
            converted['w2'] = to_uint_1024(-p['w2'])
            converted['w2IsNegative'] = "true"
        else:
            converted['w2IsNegative'] = "false"
        PoKSqS.append(converted)

    proofOfUpperBound = {
        'squareDecomposition': [to_uint_1024(v) for v in proofOfUpperBound['squareDecomposition']],
        'PoKSqS': PoKSqS,
        'PoKSEq': dict_to_uint_1024(proofOfUpperBound['PoKSEq']),
    }

    # pprint(puzzles)
    # pprint(proofs)

    environment = Environment(
        loader=FileSystemLoader("templates/"),
        trim_blocks=True,
        lstrip_blocks=True
    )
    template = environment.get_template("PlaceSingleHTLPBidTest.sol.jinja")

    rendered = template.render(
        N=N, T=T, g=g, h=h, hInv=hInv, y=y, yInv=yInv, vInv=vInv, yM=yM,
        bid=dict_to_uint_1024(bid),
        PoPV=dict_to_uint_1024(PoPV),
        proofOfPositivity=proofOfPositivity,
        proofOfUpperBound=proofOfUpperBound,
        maxBid=maxBid
    )
    print(rendered)


generate_bid_test()
