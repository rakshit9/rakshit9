#!/usr/bin/env bash
# auto_commit.sh — random daily commits for rakshit9 profile repo
# Cron: 0 9 * * * /Users/rakshit/Desktop/rakshit9/auto_commit.sh >> /Users/rakshit/Desktop/rakshit9/auto_commit.log 2>&1

REPO="/Users/rakshit/Desktop/rakshit9"
LOG="$REPO/auto_commit.log"
BRANCH="main"
cd "$REPO"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S'): $*" >> "$LOG"; }
log "=== start ==="

# ── Random commit count: 0=30%  2=20%  3=20%  4=15%  5=15% ─────────────────
R=$((RANDOM % 100))
if   [ $R -lt 30 ]; then COUNT=0
elif [ $R -lt 50 ]; then COUNT=2
elif [ $R -lt 70 ]; then COUNT=3
elif [ $R -lt 85 ]; then COUNT=4
else COUNT=5; fi

log "count=$COUNT"

if [ $COUNT -eq 0 ]; then
    log "skip day"
    exit 0
fi

TODAY=$(date '+%Y-%m-%d')

# ── Generate COUNT sorted random times between 9:00–22:00 ───────────────────
mapfile -t TIMES < <(python3 -c "
import random
n = $COUNT
ts = sorted(random.randint(540, 1319) for _ in range(n))
for t in ts:
    print(f'{t//60:02d}:{t%60:02d}')
")

# ── Commit message pools ─────────────────────────────────────────────────────
MSGS_A=("chore: daily log update" "notes: dev log $TODAY" "docs: update activity log" "chore: daily sync" "log: add session notes")
MSGS_B=("refactor: clean up notes" "docs: minor README tweak" "chore: tidy up logs" "notes: add quick thoughts" "update: daily tracker")
MSGS_C=("docs: refresh profile" "chore: update last-updated" "notes: end of day log" "docs: update README" "chore: profile maintenance")
MSGS_D=("chore: housekeeping" "notes: add learnings" "docs: minor formatting" "update: profile stats" "chore: cleanup")
MSGS_E=("chore: final sync" "notes: wrap up" "docs: polish" "update: activity" "chore: eod update")

pick() { local arr=("$@"); echo "${arr[$((RANDOM % ${#arr[@]}))]}"; }

# ── Dev log entry pool ───────────────────────────────────────────────────────
ENTRIES=(
    "Reviewed pull requests and left feedback on open PRs."
    "Refactored auth middleware to reduce response time."
    "Fixed a race condition in the async job queue."
    "Read about consistent hashing — useful for distributed caches."
    "Worked on improving test coverage for the API layer."
    "Explored Kafka consumers for an event-driven pipeline."
    "Debugged a slow query; added composite index, 10x speedup."
    "Drafted a design doc for the new notification service."
    "Learned about RAFT consensus — fascinating stuff."
    "Set up local k8s cluster with minikube for testing."
    "Wrote a small CLI tool to automate log parsing."
    "Explored vector embeddings for semantic search."
    "Reviewed system design: URL shortener with consistent hashing."
    "Deployed a FastAPI service to AWS Lambda + API Gateway."
    "Worked through LeetCode — sliding window problems."
    "Read about Apache Iceberg for data lake management."
    "Profiled a Python service — found GIL contention in threads."
    "Set up pre-commit hooks for linting and type checking."
    "Explored pgvector for storing embeddings in Postgres."
    "Fixed flaky tests in the CI pipeline — timing issues."
    "Reviewed OAuth 2.0 flows for upcoming SSO integration."
    "Worked on data pipeline with Spark + Delta Lake."
    "Read through the React 19 release notes."
    "Implemented retry logic with exponential backoff."
    "Explored OpenTelemetry for distributed tracing."
    "Spent time on DSA practice — trees and graphs."
    "Looked into WebSockets vs SSE for real-time features."
    "Reviewed microservices patterns — saga vs two-phase commit."
    "Wrote unit tests for the payment processing module."
    "Explored Terraform for infra-as-code setup."
)

pick_entry() { echo "${ENTRIES[$((RANDOM % ${#ENTRIES[@]}))]}"; }

# ── Create daily log file ────────────────────────────────────────────────────
LOGFILE="logs/${TODAY}.md"
[ ! -f "$LOGFILE" ] && printf "# Dev Log — %s\n" "$TODAY" > "$LOGFILE"

# ── Commit helper ────────────────────────────────────────────────────────────
TIDX=0
commit_at() {
    local msg="$1"
    local dt="${TODAY}T${TIMES[$TIDX]}:00"
    GIT_AUTHOR_DATE="$dt" GIT_COMMITTER_DATE="$dt" git commit -m "$msg" >> "$LOG" 2>&1 || true
    log "commit[$TIDX]: '$msg' @ ${TIMES[$TIDX]}"
    TIDX=$((TIDX + 1))
}

# ── Build commits ────────────────────────────────────────────────────────────
printf "\n## Session 1\n%s\n" "$(pick_entry)" >> "$LOGFILE"
git add logs/
commit_at "$(pick "${MSGS_A[@]}")"

printf "\n## Session 2\n%s\n" "$(pick_entry)" >> "$LOGFILE"
python3 -c "
import re, datetime
with open('README.md') as f: c = f.read()
today = datetime.date.today().isoformat()
new = re.sub(r'<!-- last-updated: [\d-]+ -->', f'<!-- last-updated: {today} -->', c)
with open('README.md', 'w') as f: f.write(new)
"
git add logs/ README.md
commit_at "$(pick "${MSGS_B[@]}")"

if [ $COUNT -ge 3 ]; then
    printf "\n## Session 3\n%s\n" "$(pick_entry)" >> "$LOGFILE"
    git add logs/
    commit_at "$(pick "${MSGS_C[@]}")"
fi

if [ $COUNT -ge 4 ]; then
    printf "\n## Notes\n%s\n" "$(pick_entry)" >> "$LOGFILE"
    git add logs/
    commit_at "$(pick "${MSGS_D[@]}")"
fi

if [ $COUNT -ge 5 ]; then
    printf "\n## EOD\n%s\n" "$(pick_entry)" >> "$LOGFILE"
    git add logs/
    commit_at "$(pick "${MSGS_E[@]}")"
fi

# ── Push ─────────────────────────────────────────────────────────────────────
git push origin "$BRANCH" >> "$LOG" 2>&1 && log "pushed ok" || log "push failed"
log "=== done ==="
