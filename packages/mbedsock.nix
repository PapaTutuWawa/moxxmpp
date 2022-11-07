{
  stdenv, cmake, pkg-config
, mbedtls
}:

stdenv.mkDerivation {
  pname = "mbedsock";
  version = "0.1.1";

  src = ./mbedsock;

  cmakeFlags = [ "-DMBEDTLS_ROOT_DIR=${mbedtls}" ];
  
  buildInputs = [ cmake mbedtls pkg-config ];
}
