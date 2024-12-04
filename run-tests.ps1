Param(
    [Parameter(Mandatory = $True)]
    [String] $TEST_FOLDER_PATH,

    [Parameter(Mandatory = $False)]
    [String] $TEST_FILTER
)

$ABSOLUTE_PATH = Resolve-Path $TEST_FOLDER_PATH

$UNIX_PLATFORM = 'Unix'
$os_name = [environment]::OSVersion.Platform

if ($os_name -eq $UNIX_PLATFORM) {
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class SignalHandler {
    // Import the signal function from libc
    [DllImport("libc.so.6", SetLastError = true)]
    public static extern int signal(int signum, SignalHandler.HandlerRoutine handler);

    // Define the delegate for handling signals
    public delegate void HandlerRoutine(int signum);

    // Signal constants (SIGTERM, SIGINT)
    public const int SIGTERM = 15;
    public const int SIGINT = 2;

    // The handler method that will be called when a signal is received
    public static void Handler(int signum) {
        if (signum == SIGTERM || signum == SIGINT) {
            Console.WriteLine("SIGTERM or SIGINT received. Cleaning up...");
            Environment.SetEnvironmentVariable("PS_SCRIPT_EXIT", "1");
        }
    }

    // Register the signal handler
    public static void Register() {
        signal(SIGTERM, new HandlerRoutine(Handler));
        signal(SIGINT, new HandlerRoutine(Handler));
    }
}
"@
} else {
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class SignalHandler {
    [DllImport("Kernel32.dll", SetLastError = true)]
    public static extern bool SetConsoleCtrlHandler(HandlerRoutine handler, bool add);

    public delegate bool HandlerRoutine(int dwCtrlType);

    public static bool Handler(int dwCtrlType) {
        if (dwCtrlType == 2 || dwCtrlType == 0) { // SIGTERM or Ctrl+C
            Console.WriteLine("SIGTERM or Ctrl+C received. Cleaning up...");
            Environment.SetEnvironmentVariable("PS_SCRIPT_EXIT", "1");
            return true;
        }
        return true;
    }

    public static void Register() {
        SetConsoleCtrlHandler(new HandlerRoutine(Handler), true);
    }
}
"@
}

# Register the handler
[SignalHandler]::Register()

if($env:PS_SCRIPT_EXIT -eq "1") {
    Write-Host "Signal received. Exiting script gracefully."
    exit
}

Write-Host "Hello from test script"
Write-Host "Pwsh Process ID: $PID"
# python scripts/test-python.py

$SUITE_NAME = $TEST_FOLDER_PATH.substring($TEST_FOLDER_PATH.lastIndexOf("/") + 1)
$LOGGING_NAME = "test_$SUITE_NAME"

if ($TEST_FILTER -ne '') {
    $LOGGING_NAME = $TEST_FILTER
}

# Write-Host "Running tests for $SUITE_NAME"
# Write-Host "Logging to $LOGGING_NAME"
# Write-Host "Absolute path: $ABSOLUTE_PATH"

push-location $ABSOLUTE_PATH

$TEST_RESULT_DIRECTORY = [io.path]::combine($PSScriptRoot, "test-results")

$RESULT_PATH = [io.path]::combine($TEST_RESULT_DIRECTORY, $SUITE_NAME)

# Write-Host "Result path: $RESULT_PATH"

New-Item -Force $RESULT_PATH/$LOGGING_NAME.txt | Out-Null

if($TEST_FILTER){
    python -m pytest -rpP -v -k $TEST_FILTER `
    --log-file "${RESULT_PATH}/${LOGGING_NAME}.log" `
    --junitxml "${RESULT_PATH}/${LOGGING_NAME}.xml" `
    -o junit_suite_name=${SUITE_NAME} `
    -o junit_family=xunit1 `
    --capture=tee-sys > "${RESULT_PATH}/${LOGGING_NAME}.txt"
}
else{
    python -m pytest -rpP -v `
    --log-file "${RESULT_PATH}/${LOGGING_NAME}.log" `
    --junitxml "${RESULT_PATH}/${LOGGING_NAME}.xml" `
    -o junit_suite_name=${SUITE_NAME} `
    -o junit_family=xunit1 `
    --capture=tee-sys > "${RESULT_PATH}/${LOGGING_NAME}.txt"
}


pop-location

exit $LASTEXITCODE
