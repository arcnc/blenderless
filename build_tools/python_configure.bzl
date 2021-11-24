"""Implements a repository rule for setting up a local Python repo."""

def _get_python_bin(repository_ctx):
    """Gets the python bin path."""
    interpreter = repository_ctx.attr.python_interpreter
    python_bin_path = repository_ctx.which(interpreter)
    if python_bin_path != None:
        return str(python_bin_path)
    fail("Failed to find path for Python interpreter {}!".format(interpreter))

def _execute(repository_ctx, cmdline):
    result = repository_ctx.execute(cmdline)
    if result.return_code != 0:
        fail("Failed to execute `{}`, reason:\n{}"
            .format(" ".join(cmdline), result.stderr))
    return result.stdout.strip("\n")

def _python_configure_impl(repository_ctx):
    python_binary = _get_python_bin(repository_ctx)

    print_include_dir = "import sysconfig; print(sysconfig.get_config_var('INCLUDEPY'))"
    python_include_dir = _execute(
        repository_ctx,
        [python_binary, "-c", print_include_dir],
    )

    print_python_extension_suffix = "import sysconfig; print(sysconfig.get_config_var('EXT_SUFFIX'));"
    python_extension_suffix = _execute(
        repository_ctx,
        [python_binary, "-c", print_python_extension_suffix],
    )

    repository_ctx.symlink(python_include_dir, "python_include")

    # Python extensions should depend on `py3_headers` target. See
    # python_extension.bzl.
    repository_ctx.file(
        "BUILD",
        """
package(default_visibility = ["//visibility:public"])

load("@bazel_tools//tools/python:toolchain.bzl", "py_runtime_pair")

py_runtime(
    name = "py3_runtime",
    interpreter_path = "{python_binary}",
    python_version = "PY3",
)

py_runtime_pair(
    name = "py3_runtime_pair",
    py3_runtime = ":py3_runtime",
)

toolchain(
    name = "py3_toolchain",
    toolchain = ":py3_runtime_pair",
    toolchain_type = "@bazel_tools//tools/python:toolchain_type",
)

cc_library(
    name = "py3_headers",
    hdrs = glob(["python_include/**/*.h"]),
    includes = ["python_include"],
)
""".format(python_binary = python_binary),
    )

    # We store separately the extension suffix, used in python_extension.bzl.
    repository_ctx.file(
        "defs.bzl",
        """
EXT_SUFFIX = "{python_extension_suffix}"
""".format(python_extension_suffix = python_extension_suffix),
    )

python_configure = repository_rule(
    implementation = _python_configure_impl,
    doc = """Sets up a local Python repository.""",
    attrs = {
        "python_interpreter": attr.string(
            mandatory = True,
            doc = "The Python interpreter",
        ),
    },
)
