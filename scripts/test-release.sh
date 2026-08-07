#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

run_component_tests() {
  local component=$1 dir="$REPO_ROOT/apps/$1"
  require_dir "$dir"
  info "Testing $component"
  if [[ -x "$dir/test.sh" ]]; then
    (cd "$dir" && ./test.sh)
  elif [[ -f "$dir/pom.xml" ]]; then
    require_command mvn
    (cd "$dir" && mvn --batch-mode test)
  elif [[ -x "$dir/gradlew" ]]; then
    (cd "$dir" && ./gradlew test)
  elif [[ -f "$dir/CMakeLists.txt" ]]; then
    require_command cmake
    cmake -S "$dir" -B "$dir/build" -DBUILD_TESTING=ON
    cmake --build "$dir/build"
    ctest --test-dir "$dir/build" --output-on-failure
  elif [[ -f "$dir/Makefile" ]]; then
    require_command make
    make -C "$dir" test
  elif [[ -f "$dir/package.json" ]]; then
    require_command npm
    (cd "$dir" && npm test -- --runInBand)
  else
    fail "No supported test entry point for $component (test.sh, Maven, Gradle, CMake, Make, or npm)"
  fi
  pass "$component tests"
}

run_component_tests gateway-java
run_component_tests parser-cpp
run_component_tests ops-console