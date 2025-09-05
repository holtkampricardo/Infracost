#!/bin/bash
set -e

# Variables
PROJECT_DIR="./"
PLAN_10GB="tfplan-10gb.binary"
PLAN_40GB="tfplan-40gb.binary"
INFRACOST_10GB="infracost-10gb.json"
INFRACOST_40GB="infracost-40gb.json"
HTML_OUTPUT="infracost-diff.html"

echo "=== Plan 10GB ==="
terraform plan -out $PLAN_10GB
terraform show -json $PLAN_10GB > plan-10gb.json

echo "=== Apply 10GB ==="
terraform apply -auto-approve $PLAN_10GB

echo "=== Infracost breakdown 10GB ==="
infracost breakdown --path plan-10gb.json
infracost breakdown --path plan-10gb.json --format json --out-file $INFRACOST_10GB
infracost output --format html --out-file infracost-1x0gb.html --path $INFRACOST_10GB

echo "=== Modificar disco a 40GB en modules.yaml ==="
# Cambiar disk_size_gb a 40

echo "=== Plan 40GB ==="
terraform plan -out $PLAN_40GB
terraform show -json $PLAN_40GB > plan-40gb.json

echo "=== Infracost breakdown 40GB ==="
infracost breakdown --path plan-40gb.json
infracost breakdown --path plan-40gb.json --format json --out-file $INFRACOST_40GB
infracost output --format html --out-file infracost-40gb.html --path $INFRACOST_40GB

echo "=== Infracost diff 10GB vs 40GB ==="
infracost diff --path $INFRACOST_40GB --compare-to $INFRACOST_10GB --format diff

echo "=== Destroy resources ==="
terraform destroy
