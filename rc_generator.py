import jinja2
import argparse


def init_parser():
    parser = argparse.ArgumentParser(prog='RC generator')
    subparsers = parser.add_subparsers(help='sub command')

    vim_parser = subparsers.add_parser('vim', help='vim help')
    vim_parser.add_argument('--programming', type=bool, default=True)
    vim_parser.add_argument('--nvim', type=bool, default=True)
    vim_parser.set_defaults(func=generate_vimrc)

    return parser


def render(obj, template):
    template = jinja2.Template(template)
    return template.render(**obj)


def read_file(path):
    with open(path, 'r') as ftr:
        return ftr.read()


def generate_vimrc(args):
    vimrc_j2 = read_file('roles/vim/templates/vimrc')
    obj = {
        'programming': args.programming,
        'nvim': args.nvim
    }
    print(render(obj, vimrc_j2))


def main():
    parser = init_parser()
    args, unknown = parser.parse_known_args()
    args.func(args)


if __name__ == '__main__':
    main()
