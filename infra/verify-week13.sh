#!/usr/bin/env bash
# Evidence collector for Week 13. Run only AFTER authorized AWS login/deployment.
# Does not print or save the AppSync API key.
set -euo pipefail
AWS_REGION="${AWS_REGION:-ap-northeast-2}"
STACK="${STACK:-portfolio-week13}"
CF_URL="${CF_URL:-https://d6oennms0h6ql.cloudfront.net}"
AWS_DEFAULT_REGION="$AWS_REGION"
export AWS_DEFAULT_REGION

command -v aws >/dev/null || { echo "AWS CLI is required"; exit 1; }
command -v curl >/dev/null || { echo "curl is required"; exit 1; }
echo "===== Identity (account ID only; avoid copying sensitive values) ====="
aws sts get-caller-identity --query '{Account:Account,Arn:Arn}' --output json
echo "===== Stack state ====="
aws cloudformation describe-stacks --stack-name "$STACK" --region "$AWS_REGION" \
  --query 'Stacks[0].{Status:StackStatus,Name:StackName}' --output json

field() {
  aws cloudformation describe-stacks --stack-name "$STACK" --region "$AWS_REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue | [0]" --output text
}
API_URL=$(field ApiUrl)
APP_URL=$(field AppSyncApiUrl)
APP_ID=$(field AppSyncApiId)
GUESTBOOK=$(field GuestbookTable)

echo "===== DynamoDB Guestbook key schema ====="
aws dynamodb describe-table --table-name "$GUESTBOOK" --region "$AWS_REGION" \
  --query 'Table.{TableName:TableName,Status:TableStatus,KeySchema:KeySchema,ItemCount:ItemCount}' --output json

echo "===== Project read-only API ====="
for endpoint in /projects /graph /projects/dot-pacman /projects/dot-pacman/pipeline; do
  code=$(curl -sS -o /tmp/week13-api.json -w '%{http_code}' "${API_URL%/}$endpoint") || code="NETWORK_ERROR"
  echo "$endpoint HTTP $code"
  if [[ "$code" != 200 ]]; then cat /tmp/week13-api.json 2>/dev/null || true; fi
done

echo "===== AppSync query/mutation (test only; key is NOT shown) ====="
KEY=$(aws appsync list-api-keys --api-id "$APP_ID" --region "$AWS_REGION" \
  --query 'apiKeys[0].id' --output text)
if [[ "$KEY" == "None" || -z "$KEY" ]]; then
  echo "No AppSync API key; cannot run GraphQL test" >&2
  exit 1
fi
json_request() {
  curl --fail-with-body -sS -X POST "$APP_URL" \
    -H 'Content-Type: application/json' -H "x-api-key: $KEY" \
    --data "$1"
}
MUTATION='{"query":"mutation AddTest($name:String!,$message:String!){addGuestbookEntry(name:$name,message:$message){entryId name message createdAt}}","variables":{"name":"13주차 테스트","message":"AppSync GraphQL DynamoDB 저장 확인"}}'
echo "Mutation result (NO key shown):"
json_request "$MUTATION" | python3 -m json.tool
QUERY='{"query":"query Recent{listGuestbookEntries(limit:5){entryId name message createdAt}}"}'
echo "Query result (NO key shown):"
json_request "$QUERY" | python3 -m json.tool

echo "===== CloudFront page checks ====="
for path in / /atlas/ /pipeline/ /guestbook/; do
  code=$(curl -sS -o /dev/null -w '%{http_code}' "${CF_URL%/}$path") || code="NETWORK_ERROR"
  echo "$path HTTP $code"
done
echo "Tests above are REAL only if executed successfully in your AWS account."
echo "Capture AWS console (DynamoDB/AppSync/IAM) plus terminal responses for assignment."
