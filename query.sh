#!/usr/bin/env bash

# shellcheck disable=SC2154

set -e

if [ "$DEBUG" ]; then
  set -x
fi

if [ ! -f "$(which jq)" ]; then
  echo "please install jq ('brew install jq')" && exit 1
fi

node_url="https://fx-json.functionx.io:26657"
if [ "$NODE_URL" ]; then
  node_url="$NODE_URL"
fi

function validator_earnings() {

  validators=$(fxcored query staking validators --node "$node_url" | jq '.validators')
  index=1
  while read valAddress moniker; do
    accAddress=$(fxcored debug addr "$valAddress" | jq -r '.AccAddress')
    printf "%-2d %-20s commission: %s" "$index" "$moniker" "$(fxcored query distribution commission "$valAddress" --node "$node_url" -o json | jq -c -r '.commission[0].amount')"
    printf " rewards: %s\n" "$(fxcored query distribution rewards "$accAddress" "$valAddress" --node "$node_url" -o json | jq -c -r '.rewards[0].amount')"
    index=$((index + 1))
  done < <(echo "$validators" | jq -r '.[]|"\(.operator_address) \(.description.moniker)"')
}

function validator_status() {
  validators=$(fxcored query staking validators --node "$node_url" | jq '.validators')
  index=1
  while read valAddress moniker status jailed unbonding_time tokens; do
    printf "%-2s %-15s %s %s %s %s\n" "$index" "$moniker" "$status" "$jailed" "$unbonding_time" "$tokens"
    index=$((index + 1))
  done < <(echo "$validators" | jq -r '.[]|"\(.operator_address) \(.description.moniker)"')
}

if [ "$0" == "./query.sh" ]; then
  "$@" || echo "exec $0 invalid params:" "$@" && exit 1
fi
