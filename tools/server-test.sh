#!/usr/bin/env bash

# One-command, source-only verification for the fungi development server.
# The complete test run happens in /tmp so Godot import metadata never dirties
# the source checkout and no Windows export is produced.

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-/home/ubuntu/fungi/tools/godot/4.7/godot}"
LOG_ROOT="${FUNGI_TEST_LOG_DIR:-/home/ubuntu/fungi/test-logs}"
IMPORT_TIMEOUT="${FUNGI_IMPORT_TIMEOUT:-180}"
TEST_TIMEOUT="${FUNGI_TEST_TIMEOUT:-120}"
STARTUP_TIMEOUT="${FUNGI_STARTUP_TIMEOUT:-45}"
KEEP_WORKDIR=0

usage() {
	cat <<'EOF'
Usage: ./tools/server-test.sh [--keep-workdir] [--godot PATH]

Runs resource import, every GDScript smoke test, and a headless main-scene
startup check. It never exports an EXE. Logs are stored outside the repository.

Environment overrides:
  GODOT_BIN                 Godot executable
  FUNGI_TEST_LOG_DIR        Persistent log directory
  FUNGI_IMPORT_TIMEOUT      Import timeout in seconds (default: 180)
  FUNGI_TEST_TIMEOUT        Per-test timeout in seconds (default: 120)
  FUNGI_STARTUP_TIMEOUT     Startup timeout in seconds (default: 45)
EOF
}

while (( $# > 0 )); do
	case "$1" in
		--keep-workdir)
			KEEP_WORKDIR=1
			shift
			;;
		--godot)
			if (( $# < 2 )); then
				echo "ERROR: --godot requires a path." >&2
				exit 2
			fi
			GODOT_BIN="$2"
			shift 2
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			echo "ERROR: unknown option: $1" >&2
			usage >&2
			exit 2
			;;
	esac
done

if [[ ! -x "$GODOT_BIN" ]]; then
	echo "ERROR: Godot executable not found or not executable: $GODOT_BIN" >&2
	exit 2
fi

mkdir -p "$LOG_ROOT"
exec 9>"$LOG_ROOT/.server-test.lock"
if ! flock -n 9; then
	echo "ERROR: another fungi server test is already running." >&2
	exit 2
fi

RUN_ID="$(date -u +'%Y%m%dT%H%M%SZ')-$$"
RUN_DIR="$LOG_ROOT/$RUN_ID"
WORK_ROOT="$(mktemp -d "/tmp/fungi-server-test.${RUN_ID}.XXXXXX")"
mkdir -p "$RUN_DIR/tests"

cleanup() {
	local exit_code=$?
	if (( KEEP_WORKDIR == 0 )); then
		rm -rf -- "$WORK_ROOT"
	else
		echo "Scratch project kept at: $WORK_ROOT"
	fi
	exit "$exit_code"
}
trap cleanup EXIT INT TERM

SOURCE_COMMIT="$(git -C "$SOURCE_ROOT" rev-parse --short=12 HEAD 2>/dev/null || echo unknown)"
DIRTY_COUNT="$(git -C "$SOURCE_ROOT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
START_EPOCH="$(date +%s)"

echo "Fungi server verification"
echo "Source : $SOURCE_ROOT"
echo "Commit : $SOURCE_COMMIT (dirty entries: $DIRTY_COUNT)"
echo "Godot  : $("$GODOT_BIN" --version | head -n 1)"
echo "Logs   : $RUN_DIR"
echo

echo "[setup] Creating isolated source snapshot..."
if ! rsync -a \
	--exclude='.git/' \
	--exclude='.godot/' \
	--exclude='build/' \
	--exclude='release/' \
	--exclude='*.log' \
	"$SOURCE_ROOT/" "$WORK_ROOT/" >"$RUN_DIR/rsync.log" 2>&1; then
	echo "FAIL: source snapshot could not be created."
	tail -n 30 "$RUN_DIR/rsync.log"
	exit 1
fi

# Keep all user:// writes, caches, and settings inside the disposable snapshot.
export HOME="$WORK_ROOT/.home"
export XDG_DATA_HOME="$WORK_ROOT/.xdg/data"
export XDG_CONFIG_HOME="$WORK_ROOT/.xdg/config"
export XDG_CACHE_HOME="$WORK_ROOT/.xdg/cache"
mkdir -p "$HOME" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"

fatal_log_pattern='SCRIPT ERROR:|Parse Error:|Failed to load script|Cannot open file|Segmentation fault|CRASH'
overall_failed=0
import_status="PASS"
startup_status="PASS"

echo "[1/3] Importing resources..."
timeout --signal=TERM "$IMPORT_TIMEOUT" \
	"$GODOT_BIN" --headless --editor --path "$WORK_ROOT" --import --quit \
	>"$RUN_DIR/import.log" 2>&1
import_rc=$?
if (( import_rc != 0 )) || grep -Eiq "$fatal_log_pattern" "$RUN_DIR/import.log"; then
	import_status="FAIL"
	overall_failed=1
	echo "      FAIL (exit $import_rc)"
	tail -n 30 "$RUN_DIR/import.log"
else
	echo "      PASS"
fi

mapfile -t TEST_FILES < <(
	find "$WORK_ROOT/tests" -maxdepth 1 -type f \
		\( -name '*_smoke.gd' -o -name 'smoke_test.gd' \) -print | sort
)
test_total=${#TEST_FILES[@]}
test_passed=0
test_failed=0
: >"$RUN_DIR/failed-tests.txt"

echo "[2/3] Running $test_total smoke tests..."
if [[ "$import_status" == "FAIL" ]]; then
	echo "      SKIP (resource import failed)"
	test_failed=$test_total
	printf '%s\n' "all tests skipped because resource import failed" >"$RUN_DIR/failed-tests.txt"
else
	for test_file in "${TEST_FILES[@]}"; do
		test_name="$(basename "$test_file" .gd)"
		test_log="$RUN_DIR/tests/$test_name.log"
		timeout --signal=TERM "$TEST_TIMEOUT" \
			"$GODOT_BIN" --headless --path "$WORK_ROOT" \
			--script "res://tests/$test_name.gd" \
			>"$test_log" 2>&1
		test_rc=$?
		if (( test_rc == 0 )) && ! grep -Eiq "$fatal_log_pattern|SMOKE_FAIL:" "$test_log"; then
			test_passed=$((test_passed + 1))
			printf '.'
		else
			test_failed=$((test_failed + 1))
			overall_failed=1
			printf 'F'
			printf '%s (exit %s)\n' "$test_name" "$test_rc" >>"$RUN_DIR/failed-tests.txt"
		fi
	done
	echo
	if (( test_failed == 0 )); then
		echo "      PASS ($test_passed/$test_total)"
	else
		echo "      FAIL ($test_passed passed, $test_failed failed)"
		while IFS= read -r failed_line; do
			failed_name="${failed_line%% *}"
			echo "      - $failed_line"
			tail -n 20 "$RUN_DIR/tests/$failed_name.log"
		done <"$RUN_DIR/failed-tests.txt"
	fi
fi

echo "[3/3] Starting the main scene headlessly..."
if [[ "$import_status" == "FAIL" ]]; then
	startup_status="SKIP"
	echo "      SKIP (resource import failed)"
else
	timeout --signal=TERM "$STARTUP_TIMEOUT" \
		"$GODOT_BIN" --headless --path "$WORK_ROOT" --quit-after 30 \
		>"$RUN_DIR/startup.log" 2>&1
	startup_rc=$?
	if (( startup_rc != 0 )) || grep -Eiq "$fatal_log_pattern" "$RUN_DIR/startup.log"; then
		startup_status="FAIL"
		overall_failed=1
		echo "      FAIL (exit $startup_rc)"
		tail -n 30 "$RUN_DIR/startup.log"
	else
		echo "      PASS"
	fi
fi

END_EPOCH="$(date +%s)"
ELAPSED=$((END_EPOCH - START_EPOCH))
if (( overall_failed == 0 )); then
	final_status="PASS"
else
	final_status="FAIL"
fi

{
	echo "result=$final_status"
	echo "commit=$SOURCE_COMMIT"
	echo "dirty_entries=$DIRTY_COUNT"
	echo "godot=$("$GODOT_BIN" --version | head -n 1)"
	echo "resource_import=$import_status"
	echo "smoke_tests_passed=$test_passed"
	echo "smoke_tests_failed=$test_failed"
	echo "smoke_tests_total=$test_total"
	echo "main_scene_startup=$startup_status"
	echo "elapsed_seconds=$ELAPSED"
	echo "run_directory=$RUN_DIR"
} >"$RUN_DIR/summary.txt"
ln -sfn "$RUN_ID" "$LOG_ROOT/latest"

echo
echo "RESULT : $final_status"
echo "TESTS  : $test_passed/$test_total passed"
echo "TIME   : ${ELAPSED}s"
echo "SUMMARY: $RUN_DIR/summary.txt"

if (( overall_failed != 0 )); then
	exit 1
fi
