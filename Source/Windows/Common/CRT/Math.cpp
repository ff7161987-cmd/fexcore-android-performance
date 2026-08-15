// SPDX-License-Identifier: MIT
#define _SECIMP
#define _CRTIMP
#include <cstdlib>
#include <cstdint>
#include <cmath>

#if defined(_WIN32)
// llvm-mingw's Windows CRT does not export POSIX sincos, but -ffast-math can
// emit that combined symbol from a pair of sin/cos calls. Keep the compatibility
// shim unoptimized so it cannot fold back into a recursive sincos call.
extern "C" __attribute__((noinline, optnone)) void sincos(double X, double* Sin, double* Cos) {
  *Sin = ::sin(X);
  *Cos = ::cos(X);
}
#endif

long double tanl(long double X) {
  return tan(static_cast<double>(X));
}

long double sinl(long double X) {
  return sin(static_cast<double>(X));
}

long double cosl(long double X) {
  return cos(static_cast<double>(X));
}

long double exp2l(long double N) {
  return exp2(static_cast<double>(N));
}

long double log2l(long double N) {
  return log2(static_cast<double>(N));
}

long double atan2l(long double X, long double Y) {
  return atan2(static_cast<double>(X), static_cast<double>(Y));
}
