#!/bin/bash
# This case needs the spec stage (policy application, flagged concerns): use the full pipeline.
set -e
[ -f .stagekit/config.json ] || exit 0
jq --slurpfile p "$PLUGIN/pipelines/full.json" '.pipeline=$p[0]' .stagekit/config.json > .stagekit/config.tmp
mv .stagekit/config.tmp .stagekit/config.json
