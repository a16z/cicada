from jinja2 import Environment, FileSystemLoader
import sys

environment = Environment(
    loader=FileSystemLoader("templates/"),
    trim_blocks=True,
    lstrip_blocks=True
)
template = environment.get_template("LibUint.sol.jinja")

num_words = int(sys.argv[1], 0)
content = template.render(num_words=num_words)

filename = 'src/LibUint{}.jinja.sol'.format(num_words * 256)
with open(filename, mode='w') as f:
    f.write(content)
