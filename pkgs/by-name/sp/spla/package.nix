{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  mpi,
  blas,
  gfortran,
  llvmPackages,
  cudaPackages,
  rocmPackages,
  config,
  gpuBackend ? (
    if config.cudaSupport then
      "cuda"
    else if config.rocmSupport then
      "rocm"
    else
      "none"
  ),
}:

assert builtins.elem gpuBackend [
  "none"
  "cuda"
  "rocm"
];

stdenv.mkDerivation rec {
  pname = "spla";
  version = "1.6.1";

  src = fetchFromGitHub {
    owner = "eth-cscs";
    repo = "spla";
    rev = "v${version}";
    hash = "sha256-fNH1IOKV1Re8G7GH9Xfn3itR80eonTbEGKQRRD16/2k=";
  };

  outputs = [
    "out"
    "dev"
  ];

  postPatch = ''
    substituteInPlace src/gpu_util/gpu_blas_api.hpp \
      --replace '#include <rocblas.h>' '#include <rocblas/rocblas.h>'
  '';

  nativeBuildInputs = [
    cmake
    gfortran
  ];

  buildInputs = [
    blas
    mpi
  ]
  ++ lib.optional (gpuBackend == "cuda") cudaPackages.cudatoolkit
  ++ lib.optionals (gpuBackend == "rocm") [
    rocmPackages.clr
    rocmPackages.rocblas
  ]
  ++ lib.optional stdenv.hostPlatform.isDarwin llvmPackages.openmp;

  cmakeFlags = [
    "-DSPLA_OMP=ON"
    "-DSPLA_FORTRAN=ON"
    "-DSPLA_INSTALL=ON"
    # Required due to broken CMake files
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
  ]
  ++ lib.optional (gpuBackend == "cuda") "-DSPLA_GPU_BACKEND=CUDA"
  ++ lib.optional (gpuBackend == "rocm") [ "-DSPLA_GPU_BACKEND=ROCM" ];

  preFixup = ''
    substituteInPlace $out/lib/cmake/SPLA/SPLASharedTargets-release.cmake \
      --replace-fail "\''${_IMPORT_PREFIX}" "$out"
  '';

  meta = with lib; {
    description = "Specialized Parallel Linear Algebra, providing distributed GEMM functionality for specific matrix distributions with optional GPU acceleration";
    homepage = "https://github.com/eth-cscs/spla";
    license = licenses.bsd3;
    maintainers = [ maintainers.sheepforce ];
  };
}
