import os
import apt
import sys
import shutil
from autotest.client import test, utils
from autotest.client.shared import utils_memory


class phase_one(test.test):
    """
    Execute basic sanity tests
    """
    version = 1
    
    def install_required_pkgs(self):
        pkgs = [
             'tftp-hpa',  'nfs-common',  'stress-ng'
        ]

        cache = apt.cache.Cache()
        cache.update()

        for package_name in pkgs:
            pkg = cache[package_name]

            if pkg.is_installed:
                self.results = "{pkg_name} already installed".format(pkg_name=package_name)
            else:
                self.results = pkg.mark_install()

            try:
                self.results = cache.commit()
            except Exception, arg:
                self.results = "Sorry, package installation failed [{err}]".format(err=str(arg))

    def initialize(self):
        self.install_required_pkgs()

    def setup(self, tarball='phase_one.tar.bz2'):
        shutil.copyfile(os.path.join(self.bindir, 'phase_one_test.sh'),
                        os.path.join(self.srcdir, 'phase_one_test.sh'))
        #os.chmod(os.path.join(self.srcdir, 'phase_one_test.sh'), 0o755)
        os.chdir(self.srcdir)
        os.chmod('phase_one_test.sh' , 0755)      

    def run_once(self, args='', testcase='all'):
        args = testcase
        cmd = os.path.join(self.srcdir, 'phase_one_test.sh') + ' ' + args
        self.results = utils.system(cmd)
