
param ($CXX_STANDARD,
       $GPU_ARCHS)

# We need the full path to cl because otherwise cmake will replace CMAKE_CXX_COMPILER with the full path
# and keep CMAKE_CUDA_HOST_COMPILER at "cl" which breaks our cmake script
$script:HOST_COMPILER  = (Get-Command "cl").source -replace '\\','/'
$script:PARALLEL_LEVEL = (Get-WmiObject -class Win32_processor).NumberOfLogicalProcessors

If($null -eq $DEVCONTAINER_NAME) {
    $script:BUILD_DIR="../build/local"
} else {
    $script:BUILD_DIR="../build/$DEVCONTAINER_NAME"
}

If(!(test-path -PathType container "../build")) {
    New-Item -ItemType Directory -Path "../build"
}

# The most recent build will always be symlinked to cccl/build/latest
New-Item -ItemType Directory    -Path "$BUILD_DIR" -Force

$script:COMMON_CMAKE_OPTIONS= @(
    "-S .."
    "-B $BUILD_DIR"
    "-G Ninja"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_CXX_STANDARD=$CXX_STANDARD"
    "-DCMAKE_CUDA_STANDARD=$CXX_STANDARD"
    "-DCMAKE_CXX_COMPILER=$HOST_COMPILER"
    "-DCMAKE_CUDA_HOST_COMPILER=$HOST_COMPILER"
    "-DCMAKE_CUDA_ARCHITECTURES=$GPU_ARCHS"
    "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
)

Write-Host "========================================"
Write-Host "Begin build"
Write-Host "pwd=$pwd"
Write-Host "HOST_COMPILER=$HOST_COMPILER"
Write-Host "CXX_STANDARD=$CXX_STANDARD"
Write-Host "GPU_ARCHS=$GPU_ARCHS"
Write-Host "PARALLEL_LEVEL=$PARALLEL_LEVEL"
Write-Host "BUILD_DIR=$BUILD_DIR"
Write-Host "========================================"

function configure {
    param ($CMAKE_OPTIONS)
    $FULL_CMAKE_OPTIONS = $COMMON_CMAKE_OPTIONS + $CMAKE_OPTIONS
    Start-Process cmake -Wait -NoNewWindow -ArgumentList $FULL_CMAKE_OPTIONS
}

function build {
    param ($BUILD_NAME)
##    source "./sccache_stats.sh" start
    Start-Process cmake -Wait -NoNewWindow -ArgumentList "--build $BUILD_DIR --parallel $PARALLEL_LEVEL"
    echo "${BUILD_NAME} build complete"
##    source "./sccache_stats.sh" end
}

function configure_and_build {
    param ($BUILD_NAME, $CMAKE_OPTIONS)
    configure -CMAKE_OPTIONS $CMAKE_OPTIONS
    build -BUILD_NAME $BUILD_NAME
}

Export-ModuleMember -Function configure, build, configure_and_build
Export-ModuleMember -Variable BUILD_DIR
