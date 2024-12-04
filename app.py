# ----------------------------------------------------------------------------------------------------
# PYTHON SCRIPT WHICH INVOKES THE SCHEDULER AND PASSES IN THE YAML DEFINING THE TEST SUITE ORDERING.
# ----------------------------------------------------------------------------------------------------

from scheduler import app

try:
    if __name__ == '__main__':
        # Check if at least one argument (the YAML filename) is provided
        yaml_filename = "test.yaml"
        app.run(yaml_filename)
except Exception as ex:
    print(f"Failure occurred during scheduler run - {ex}")
    raise ex
