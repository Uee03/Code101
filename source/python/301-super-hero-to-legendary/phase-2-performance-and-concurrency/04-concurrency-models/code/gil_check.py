import sys
import sysconfig

free_threaded_build = bool(sysconfig.get_config_var("Py_GIL_DISABLED"))
gil_enabled = sys._is_gil_enabled() if hasattr(sys, "_is_gil_enabled") else True

print("python:", sys.version.split()[0])
print("free-threaded build:", free_threaded_build)
print("GIL enabled now:", gil_enabled)
