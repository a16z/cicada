from Crypto.PublicKey import RSA
from jinja2 import Environment, FileSystemLoader
from pprint import pprint
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


def generate_proof_of_exponentiation_test(i):
    # Public parameters
    N = RSA.generate(1024).n
    T = random.randint(1000, 100000)
    g = random.randint(0, N)
    h = pow(g, 2 ** T, N)
    y = random.randint(0, N)
    yInv = pow(y, -1, N)

    r = random.randint(0, MAX_UINT256)

    u = pow(g, r, N)
    w = pow(u, 2 ** T, N)

    j = 0
    l = None
    while True:
        hash = int.from_bytes(Web3.solidityKeccak(
            ['uint256[4]', 'uint256[4]', 'uint256'],
            [to_uint_1024(u), to_uint_1024(w), j]
        ), byteorder='big')
        candidate = hash | HIGH_BIT
        if isprime(candidate):
            l = candidate
            break
        j += 1

    q = (2 ** T) // l
    pi = pow(u, q, N)

    environment = Environment(
        loader=FileSystemLoader("templates/"),
        trim_blocks=True,
        lstrip_blocks=True
    )
    template = environment.get_template("ProofOfExponentiationTest.sol.jinja")

    # pprint({
    #     'N': N,
    #     'T': T,
    #     'g': g,
    #     'h': h,
    #     'y': y,
    #     'yInv': yInv,
    #     'r': r,
    #     'u': u,
    #     'w': w,
    #     'π': pi,
    #     'j': j,
    #     'l': l
    # })
    [N, g, h, y, yInv, u, w, pi] = map(
        lambda x: to_uint_1024(x),
        [N, g, h, y, yInv, u, w, pi]
    )
    rendered = template.render(
        i=i,
        N=N, T=T, g=g, h=h, y=y, yInv=yInv,
        u=u, w=w,
        pi=pi, j=j, l=l
    )
    print(rendered)

for i in range(256):
    generate_proof_of_exponentiation_test(i+1)