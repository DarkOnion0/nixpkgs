{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pip,
  pytestCheckHook,
  pythonOlder,
  setuptools-scm,
  setuptools,
  tomli,
}:

buildPythonPackage rec {
  pname = "extension-helpers";
  version = "1.2.0";
  pyproject = true;

  disabled = pythonOlder "3.8";

  src = fetchFromGitHub {
    owner = "astropy";
    repo = "extension-helpers";
    tag = "v${version}";
    hash = "sha256-qneulhSYB2gYiCdgoU7Dqg1luLWhVouFVihcKeOA37E=";
  };

  build-system = [
    setuptools
    setuptools-scm
  ];

  dependencies = [ setuptools ] ++ lib.optionals (pythonOlder "3.11") [ tomli ];

  nativeCheckInputs = [
    pytestCheckHook
    pip
  ];

  pythonImportsCheck = [ "extension_helpers" ];

  enabledTestPaths = [ "extension_helpers/tests" ];

  disabledTests = [
    # Test require network access
    "test_only_pyproject"
  ];

  meta = with lib; {
    description = "Helpers to assist with building Python packages with compiled C/Cython extensions";
    homepage = "https://github.com/astropy/extension-helpers";
    changelog = "https://github.com/astropy/extension-helpers/blob/${version}/CHANGES.md";
    license = licenses.bsd3;
    maintainers = with maintainers; [ fab ];
  };
}
