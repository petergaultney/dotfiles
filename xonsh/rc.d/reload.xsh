import sys
import importlib


def reload(args):
    module_names = set(sys.modules) & set(globals())
    for module_name in module_names:
        for arg in args:
            if module_name.startswith(arg):
                print(f"Reloading {module_name}")
                importlib.reload(sys.modules[module_name])


aliases["reload"] = reload
