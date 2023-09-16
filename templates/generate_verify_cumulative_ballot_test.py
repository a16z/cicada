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
    (_, v2, r2) = Z2

    [alpha1, alpha2, beta1, beta2, gamma] = [
        random.randint(0, MAX_UINT256) for _ in range(5)]

    A1 = normalize(pow(h, alpha1, N) * pow(y, beta1, N), N)
    A2 = normalize(pow(h, alpha2, N) * pow(v1, beta2, N), N)
    A = normalize(pow(h, gamma, N), N)

    e = int.from_bytes(Web3.solidityKeccak(
        ['uint256[4]'] * 3 + ['bytes32'],
        [to_uint_1024(A1), to_uint_1024(
            A2), to_uint_1024(A), parametersHash]
    ), byteorder='big')

    w1 = alpha1 + e * r1
    x1 = beta1 + e * s
    w2 = alpha2 + e * (r2 - r1 * s)
    x2 = beta2 + e * s
    w = gamma + e * (r1 - r2)

    quotient = normalize(v1 * pow(v2, -1, N), N)

    return {
        'A1': A1,
        'A2': A2,
        'A': A,
        'x1': x1,
        'x2': x2,
        'w1': w1,
        'w2': w2,
        'w': w,
        'quotient': quotient,
        'squareRoot': v1
    }


def proof_of_equal_htlp(Z1, Z2, s, N, h, y, parametersHash):
    (_, v1, r1) = Z1
    (_, v2, r2) = Z2

    [alpha1, alpha2, beta1, beta2, gamma] = [
        random.randint(0, MAX_UINT256) for _ in range(5)]

    A1 = normalize(pow(h, alpha1, N) * pow(y, beta1, N), N)
    A2 = normalize(pow(h, alpha2, N) * pow(y, beta2, N), N)
    A = normalize(pow(h, gamma, N), N)

    e = int.from_bytes(Web3.solidityKeccak(
        ['uint256[4]'] * 3 + ['bytes32'],
        [to_uint_1024(A1), to_uint_1024(
            A2), to_uint_1024(A), parametersHash]
    ), byteorder='big')

    w1 = alpha1 + e * r1
    x1 = beta1 + e * s
    w2 = alpha2 + e * r2
    x2 = beta2 + e * s
    w = gamma + e * (r1 - r2)

    quotient = normalize(v1 * pow(v2, -1, N), N)

    PoKSEq = {
        'A1': A1,
        'A2': A2,
        'A': A,
        'x1': x1,
        'x2': x2,
        'w1': w1,
        'w2': w2,
        'w': w,
        'quotient': quotient
    }

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


def generate_ballot_test(numChoices):
    # Public parameters
    # N = RSA.generate(1024).n
    N = 119811489572127862002400473548445165991417646257390315534749434310249361630773111446686986365667134131769700968038508003183790050995248795868556415935896469708804065561524199281221524011292023692346224158949981067042940731981798525413610618627831152737911921198417981708100865711902031939654050023574809255253
    T = random.randint(1000, 100000)
    g = normalize(random.randint(0, N), N)
    h = normalize(pow(g, 2 ** T, N), N)
    hInv = normalize(pow(h, -1, N), N)
    y = normalize(random.randint(0, N), N)
    yInv = normalize(pow(y, -1, N), N)

    parametersHash = Web3.solidityKeccak(
        ['uint256'] + ['uint256[4]'] * 6,
        [T, to_uint_1024(N), to_uint_1024(g), to_uint_1024(h), to_uint_1024(hInv),
         to_uint_1024(y), to_uint_1024(yInv)]
    )

    # Ballot
    pointsPerVoter = random.randint(2, 100)
    points = [0 for _ in range(numChoices)]
    for _ in range(pointsPerVoter):
        points[random.randrange(len(points))] += 1
    assert (sum(points) == pointsPerVoter)

    puzzles = []
    proofsOfPos = []
    proofsOfValidity = []
    R = 0
    for s in points:
        (u, v, r) = Z = gen_htlp(N, g, h, y, s, numChoices)
        puzzles.append({'u': u, 'v': v})
        (s_1, s_2, s_3) = square_decompose_legendre(s)

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
            4 * s + 1, N, h, y, parametersHash
        )

        # print(to_uint_1024(decompositionV))
        # print(to_uint_1024(legendre))

        proofsOfPos.append({
            'squareDecomposition': squareDecomposition,
            'PoKSqS': proofsOfSquare,
            'PoKSEq': proofOfEquality
        })
        proofsOfValidity.append(proof_of_valid_htlp(
            Z, s, N, g, h, y, parametersHash))
        R += r

    render_template(T, N, g, h, hInv, y, yInv, numChoices,
                    pointsPerVoter, puzzles, proofsOfPos, proofsOfValidity, R)


def render_template(
        T, N, g, h, hInv, y, yInv,
        numChoices, pointsPerVoter,
        puzzles, proofsOfPos, proofsOfValidity, R):

    [N, g, h, hInv, y, yInv] = map(
        lambda x: to_uint_1024(x),
        [N, g, h, hInv, y, yInv]
    )
    ballot = [
        dict_to_uint_1024(Z) for Z in puzzles]

    proofs = []
    for proof in proofsOfPos:
        PoKSqS = []
        for p in proof['PoKSqS']:
            converted = dict_to_uint_1024(p)
            if p['w'] < 0:
                converted['w'] = to_uint_1024(-p['w'])
                converted['wIsNegative'] = "true"
            else:
                converted['wIsNegative'] = "false"
            if p['w2'] < 0:
                converted['w2'] = to_uint_1024(-p['w2'])
                converted['w2IsNegative'] = "true"
            else:
                converted['w2IsNegative'] = "false"
            PoKSqS.append(converted)

        PoKSEq = dict_to_uint_1024(proof['PoKSEq'])
        if proof['PoKSEq']['w'] < 0:
            PoKSEq['w'] = to_uint_1024(-proof['PoKSEq']['w'])
            PoKSEq['wIsNegative'] = "true"
        else:
            PoKSEq['wIsNegative'] = "false"

        proofs.append({
            'squareDecomposition': [to_uint_1024(v) for v in proof['squareDecomposition']],
            'PoKSqS': PoKSqS,
            'PoKSEq': PoKSEq,
        })

    # pprint(puzzles)
    # pprint(proofs)

    environment = Environment(
        loader=FileSystemLoader("templates/"),
        trim_blocks=True,
        lstrip_blocks=True
    )
    template = environment.get_template("VerifyCumulativeBallotTest.sol.jinja")

    rendered = template.render(
        N=N, T=T, g=g, h=h, hInv=hInv, y=y, yInv=yInv,
        ballot=ballot,
        proofs=proofs,
        proofsOfValidity=map(dict_to_uint_1024, proofsOfValidity),
        R=R,
        pointsPerVoter=pointsPerVoter,
        numChoices=numChoices
    )
    print(rendered)


generate_ballot_test(6)
