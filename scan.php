<?php
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // Get the target from the form
    $target = escapeshellarg($_POST['target']);

    // Path to your bash script
    $bashScript = 'scan.sh';

    // Full command to run the bash script with the target parameter
    $command = "bash $bashScript $target 2>&1";  // Capture both stdout and stderr

    // Run the command and capture the output
    $output = shell_exec($command);

    // Send the output back to the front-end
    echo "<pre>$output</pre>";
} else {
    echo "Invalid request.";
}
?>
