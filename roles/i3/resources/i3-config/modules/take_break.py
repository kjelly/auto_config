from time import time
from subprocess import check_output
from datetime import datetime, timedelta


def get_user_idle_time():
    try:
        output = check_output("xprintidle", shell=True)
    except:
        output = '0'
    return int(output, 10)


def get_human_time(secs):
    sec = timedelta(seconds=secs)
    d = datetime(1, 1, 1) + sec
    return "%02d:%02d:%02d" % (d.hour, d.minute, d.second)


class Py3status:
    """
    Simply output the currently logged in user in i3bar.

    Inspired by i3 FAQ:
        https://faq.i3wm.org/question/1618/add-user-name-to-status-bar/
    """
    busyCount = 0
    breakCount = 0
    INTERVAL = 3

    def on_click(self, i3status_output_json, i3status_config, event):
        self.busyCount = 0

    def busy(self, i3status_output_json, i3status_config):
        """
        We use the getpass module to get the current user.
        """

        if get_user_idle_time() > 30 * 1000:
            self.busyCount = 0
            text = get_human_time(get_user_idle_time() / 1000)
            color = "#00FF00"
        else:
            self.busyCount += self.INTERVAL
            text = get_human_time(self.busyCount)

            if self.busyCount > 60 * 3:
                color = "#FF0000"
            else:
                color = "#FFFFFF"

        # set, cache and return the output
        response = {'full_text': text, 'name': 'busy', 'color': color}
        response['cached_until'] = time() + self.INTERVAL
        return (0, response)
