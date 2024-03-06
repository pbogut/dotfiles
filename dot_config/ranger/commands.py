from __future__ import (absolute_import, division, print_function)

import os
import os.path
import datetime

from ranger.api.commands import Command


class cd_year_month(Command):  # pylint: disable=invalid-name
    """:cd_year_month path/
    Appends Year/Month to given path and changing dir
    (creates folder if not already exists)
    """

    def execute(self):
        currentDateTime = datetime.datetime.now()
        date = currentDateTime.date()
        year_month = date.strftime("/%Y/%m")

        path = self.arg(1) + year_month
        if path[0] == '~':
            path = path.replace('~', os.getenv('HOME', '~'), 1)


        if not os.path.isdir(path):
            self.fm.mkdir(path)

        self.fm.cd(path)
