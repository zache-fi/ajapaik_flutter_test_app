<?php
$dir = "."; // current directory
$files = scandir($dir);

echo "<ul>";
foreach($files as $file) {
    if ($file != "." && $file != ".." && is_file($file)) {
        echo "<li>$file</li>";
    }
}
echo "</ul>";
?>
