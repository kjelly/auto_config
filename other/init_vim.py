import os.path
import os
import tempfile
import shutil


home_dir = os.path.expanduser('~')
base_path = os.path.abspath(os.path.dirname(__file__))
vim_template_path = os.path.join(base_path, 'vimrc')
vimrc_path = os.path.join(home_dir, '.vimrc')


def cd_to_tmp_dir():
    tmp_dir = tempfile.gettempdir()
    if not tmp_dir:
        print 'No temp dir'
        return False
    os.chdir(tmp_dir)
    return True


def init_vim_dir():
    os.chdir(home_dir)
    os.system("mkdir -p .vim/bundle")


def init_vimrc():
    shutil.copyfile(vim_template_path, vimrc_path)


def install_bundle():
    git_path = "https://github.com/gmarik/vundle.git"
    bundle_dir = os.path.join(home_dir, '.vim', 'bundle')
    if not os.path.exists(bundle_dir):
        os.system("mkdir -p {dir}".format(dir=bundle_dir))
    os.chdir(bundle_dir)
    os.system('git clone ' + git_path)


def install():
    init_vim_dir()
    install_bundle()
    init_vimrc()


if __name__ == '__main__':
    install()
