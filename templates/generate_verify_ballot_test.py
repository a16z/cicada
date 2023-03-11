from Crypto.PublicKey import RSA
from jinja2 import Environment, FileSystemLoader
from pprint import pprint
import random
from web3 import Web3

MAX_UINT256 = pow(2, 256) - 1


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


def generate_ballot_test(i):
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

    # Ballot
    r = random.randint(0, MAX_UINT256)
    s = random.randint(0, 1)  # secret 0/1 vote
    u = normalize(pow(g, r, N), N)
    v = normalize((pow(h, r, N) * pow(y, s, N)) % N, N)

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

    environment = Environment(
        loader=FileSystemLoader("templates/"),
        trim_blocks=True,
        lstrip_blocks=True
    )
    template = environment.get_template("VerifyBallotTest.sol.jinja")
    # pprint({
    #     'N': N,
    #     'T': T,
    #     'g': g,
    #     'h': h,
    #     'y': y,
    #     'yInv': yInv,
    #     'r': r,
    #     's': s,
    #     'u': u,
    #     'v': v,
    #     'a0': a0,
    #     'b0': b0,
    #     'c0': c0,
    #     't0': t0,
    #     'a1': a1,
    #     'b1': b1,
    #     'c1': c1,
    #     't1': t1,
    # })

    [N, g, h, y, yInv, u, v, a0, b0, t0, a1, b1, t1] = map(
        lambda x: to_uint_1024(x),
        [N, g, h, y, yInv, u, v, a0, b0, t0, a1, b1, t1]
    )
    rendered = template.render(
        i=i,
        N=N, T=T, g=g, h=h, y=y, yInv=yInv,
        u=u, v=v,
        a0=a0, b0=b0, c0=c0, t0=t0,
        a1=a1, b1=b1, c1=c1, t1=t1)
    print(rendered)


for i in range(256):
    generate_ballot_test(i+1)
