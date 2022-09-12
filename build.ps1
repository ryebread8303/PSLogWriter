$root = $PSScriptRoot
$folders = @{dst=join-path $root "dst";src=join-path $root "src";test=join-path $root "tests";build=join-path $root "build"}
$manifestFile = get-childitem $folders['src'] -Filter *.psd1
$moduleName = split-path $manifestFile -LeafBase
$manifest = import-powershelldatafile $manifestFile
$sourceFiles = get-childitem $folders['src']
$moduleFolder = join-path (join-path $folders['build'] $moduleName) $manifest['ModuleVersion']
new-item -ItemType Directory -path $moduleFolder
copy-item $sourceFiles $moduleFolder
Compress-Archive -path (join-path $folders['build'] $moduleName) -DestinationPath (join-path $folders['dst'] "$moduleName.zip") -Verbose
