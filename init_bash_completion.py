import os
import os.path

if os.path.exists('/etc/skel/.bashrc'):
    os.system("cat /etc/skel/.bashrc >> ~/.bashrc")
    print 'Success'
else:
    print 'Please install bash-completion.'
