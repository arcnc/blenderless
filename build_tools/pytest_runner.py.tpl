"""The pytest entry point."""
import os
import signal
import sys

import pytest


def quit_pytest(signum: int, _) -> None:
    sys.exit(signum)

if __name__ == '__main__':
    signal.signal(signal.SIGTERM, quit_pytest)

    sys.argv = sys.argv + [{args}]  # pylint: disable=line-too-long

    exit_code = pytest.console_main()
    sys.stdout.flush()
    sys.stderr.flush()
    # bpy's static C++ destructors can segfault at process exit, after all tests ran; skip them.
    os._exit(exit_code)
