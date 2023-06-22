from Crypto.PublicKey import RSA
from jinja2 import Environment, FileSystemLoader
import random
from sympy import isprime
from web3 import Web3

MAX_UINT256 = pow(2, 256) - 1
HIGH_BIT = pow(2, 255)


def to_uint_1024(x):
    binaryString = '{0:0{1}b}'.format(x, 2).zfill(1024)
    parts = [binaryString[:256], binaryString[256:512],
             binaryString[512:768], binaryString[768:]]
    return [int(part, 2) for part in parts]


def normalize(x, N):
    return x if x < N / 2 else N - x


def simulator(N, g, h, u, v, r, yInv=1):
    c = random.randint(0, MAX_UINT256)
    t = random.randint(0, MAX_UINT256) + r * c
    a = normalize((pow(g, t, N) * pow(u, -c, N)) % N, N)
    b = normalize((pow(h, t, N) * pow(v * yInv, -c, N)) % N, N)
    return (a, b, c, t)


def generate_end_to_end_test(numBallots):
    # Public parameters
    N = RSA.generate(1024).n
    T = random.randint(1000, 100000)
    g = normalize(random.randint(0, N), N)
    h = normalize(pow(g, 2 ** T, N), N)
    y = normalize(random.randint(0, N), N)
    yInv = normalize(pow(y, -1, N), N)

    parametersHash = Web3.solidityKeccak(
        ['uint256[4]', 'uint256', 'uint256[4]',
            'uint256[4]', 'uint256[4]', 'uint256[4]'],
        [to_uint_1024(N), T, to_uint_1024(g), to_uint_1024(h),
         to_uint_1024(y), to_uint_1024(yInv)]
    )

    ballots = []
    count = 0
    U = g
    V = h

    for _ in range(numBallots):
        _parametersHash = Web3.solidityKeccak(
            ['bytes32', 'bytes32'],
            [parametersHash, '0x0000000000000000000000007FA9385bE102ac3EAc297483Dd6233D62b3e1496']
        )

        # Ballot
        r = random.randint(0, MAX_UINT256)
        s = random.randint(0, 1)  # secret 0/1 vote
        u = normalize(pow(g, r, N), N)
        v = normalize((pow(h, r, N) * pow(y, s, N)) % N, N)

        # Running tally puzzle/count
        U = normalize(U * u % N, N)
        V = normalize(V * v % N, N)
        count += s

        # Proof of ballot validity
        a0 = b0 = c0 = t0 = a1 = b1 = c1 = t1 = None

        if s == 0:
            a1, b1, c1, t1 = simulator(N, g, h, u, v, r, yInv)
            r0 = random.randint(0, MAX_UINT256)
            a0 = normalize(pow(g, r0, N), N)
            b0 = normalize(pow(h, r0, N), N)
            c = int.from_bytes(Web3.solidityKeccak(
                ['uint256[4]'] * 4 + ['bytes32'],
                [to_uint_1024(a0), to_uint_1024(
                    b0), to_uint_1024(a1), to_uint_1024(b1), _parametersHash]
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
                    b0), to_uint_1024(a1), to_uint_1024(b1), _parametersHash]
            ), byteorder='big')
            c1 = (c - c0) % pow(2, 256)
            t1 = r1 + c1 * r

        environment = Environment(
            loader=FileSystemLoader("templates/"),
            trim_blocks=True,
            lstrip_blocks=True
        )
        template = environment.get_template("EndToEndTest.sol.jinja")

        [u, v, a0, b0, t0, a1, b1, t1] = map(
            lambda x: to_uint_1024(x),
            [u, v, a0, b0, t0, a1, b1, t1]
        )
        ballots.append({
            'u': u, 'v': v,
            'a0': a0, 'b0': b0, 'c0': c0, 't0': t0,
            'a1': a1, 'b1': b1, 'c1': c1, 't1': t1
        })

    # Solve final puzzle
    w = normalize(pow(U, 2 ** T, N), N)
    j = 0
    l = None
    while True:
        hash = int.from_bytes(Web3.solidityKeccak(
            ['uint256[4]', 'uint256[4]', 'bytes32', 'uint256'],
            [to_uint_1024(U), to_uint_1024(w), parametersHash, j]
        ), byteorder='big')
        candidate = hash | HIGH_BIT
        if isprime(candidate):
            l = candidate
            break
        j += 1

    q = (2 ** T) // l
    pi = normalize(pow(U, q, N), N)

    [N, g, h, y, yInv, w, pi] = map(
        lambda x: to_uint_1024(x),
        [N, g, h, y, yInv, w, pi]
    )
    finalize = {
        'count': count,
        'w': w,
        'pi': pi,
        'j': j,
        'l': l,
    }
    pp = {
        'N': N,
        'T': T,
        'g': g,
        'h': h,
        'y': y,
        'yInv': yInv
    }
    rendered = template.render(ballots=ballots, finalize=finalize, pp=pp)
    print(rendered)


generate_end_to_end_test(5)
