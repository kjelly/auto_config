import os, errno
import os.path


def get_home_dir():
    return os.path.expanduser("~")


def mkdir_p(path):
    os.makedirs(path)



def get_project_dir():
    file_path = os.path.dirname(__file__)
    parent_path = os.path.join(file_path, '..')
    return os.path.abspath(parent_path)


def make_link(source, target):
    source = os.path.join(get_project_dir(), source)
    if not os.path.exists(source):
        return 'source path not found'

    target_dir_name = os.path.dirname(target)

    if not os.path.exists(target_dir_name):
        mkdir_p(target_dir_name)

    print target
    os.unlink(target)
    os.symlink(source, target)
    return 'success'
