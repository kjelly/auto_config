import yaml
import os
import ply.lex as lex
import ply.yacc as yacc
import shutil
import jinja2
import argparse


def read_yaml(path, variable):
    with open(path, 'r') as ftr:
        data = ftr.read()
    data = render(data, variable)
    data = yaml.load(data)
    return data


def file_action(args):
    if args['state'] == 'directory':
        os.system("mkdir -p %s" % args['path'])
    if 'mode' in args:
        os.system("chmod %s %s" % (args['mode'], args['path']))


def template_action(args, meta):
    with open(os.path.join(os.path.join(meta['base_path'], 'templates', args['src'])),'r') as ftr:
        template_str = ftr.read()
    with open(os.path.expanduser(args['dest']), 'w') as ftr:
        ftr.write(render(template_str, meta['variable']))


def render(template_str, variable):
    template = jinja2.Template(template_str, undefined=jinja2.StrictUndefined)
    return template.render(variable)


def copy_action(args, meta):
    src = os.path.join(meta['base_path'], 'files', args['src'])
    dest = os.path.expanduser(args['dest'])
    if os.path.isdir(src):
        dest = os.path.join(dest, os.path.basename(src))
        try:
             shutil.copytree(src, dest)
        except OSError as e:
            if e.errno == 17:
                return
            raise
    else:
        shutil.copy(src, dest)


def parse(s):
    ret = {}

    tokens = (
        'WORD', 'EQUAL', 'QUOTE', 'DQUOTE'
    )

    def t_WORD(t):
        r'(\w|\.|/|~)+'
        return t

    def t_error(t):
        t.lexer.skip(1)

    t_EQUAL = "="
    t_QUOTE = "'"
    t_DQUOTE = "\""
    t_ignore = " \t"

    def p_error(p):
        print("Syntax error at '%s'" % p.value)

    def p_statement(p):
        '''statement :  WORD EQUAL QUOTE WORD QUOTE
                     |  WORD EQUAL WORD
                     |  WORD EQUAL DQUOTE WORD DQUOTE'''
        if len(p) == 4:
            ret[p[1]] = p[3]
        elif len(p) == 6:
            ret[p[1]] = p[4]

    def p_input(p):
        ''' statement : statement statement'''

        pass

    lex.lex()
    yacc.yacc()
    yacc.parse(s)
    return ret


def run_task(lst, meta):
    for i in lst:
        if isinstance(i, dict):
            print('*' * 10)
            if 'name' in i:
                print(i['name'])
            else:
                print(i.keys())
            if 'file' in i:
               file_action(parse(i['file']))
            elif 'template' in i:
                template_action(parse(i['template']), meta)
            elif 'copy' in i:
                copy_action(parse(i['copy']), meta)
            else:
                pass


def init_parser():
    parser = argparse.ArgumentParser(prog='Simple Ansible')
    parser.add_argument('--playbook', '-p', type=str, required=True)
    parser.add_argument('--basepath', '-b', type=str, default='.')
    parser.add_argument('-k', action='append', dest='collection', default=[], required=False)
    return parser


def parse_key_value(collection):
    ret = {}
    for i in collection:
        key, value = i.split('=')
        ret[key] = value
    return ret


def main():
    parser = init_parser()
    args, unknown = parser.parse_known_args()

    variable = {
        "HOME_PATH": os.path.expanduser("~"),
    }

    meta = {
        "variable": variable,
        "base_path": args.basepath,
    }

    variable.update(parse_key_value(args.collection))
    playbook = read_yaml(args.playbook, variable)
    run_task(playbook, meta)


if __name__ == '__main__':
    main()
