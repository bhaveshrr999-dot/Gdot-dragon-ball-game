"""Run a Godot check, treating engine/script errors as failures even with exit 0."""
import subprocess
import sys


def main(argv):
    if not argv:
        print('Usage: run_godot_check.py executable [arguments...]', file=sys.stderr)
        return 2
    failed = False
    with subprocess.Popen(argv, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                          text=True, bufsize=1) as process:
        for line in process.stdout:
            print(line, end='', flush=True)
            failed |= any(marker in line for marker in ('ERROR:', 'FAIL:'))
        code = process.wait()
    return code if code else int(failed)


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
