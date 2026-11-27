#!/usr/bin/env bash
# Week13 deploy; requires AWS CLI v2 and authorized local AWS login.
set -euo pipefail
REGION=ap-northeast-2
STACK="${STACK:-portfolio-week13}"
SITE_STACK="${SITE_STACK:-portfolio-week12}"
CF_URL="${CF_URL:-https://d6oennms0h6ql.cloudfront.net}"
DIST_DIR="${DIST_DIR:-dist}"
if [[ ! -d "$DIST_DIR" ]]; then
  echo "Missing build output directory: $DIST_DIR" >&2
  exit 1
fi
aws sts get-caller-identity >/dev/null
echo "Deploying stack $STACK to $REGION. Review AWS pricing before proceeding."
aws cloudformation deploy --region "$REGION" --stack-name "$STACK" \
  --template-file infra/week13.yaml \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides CloudFrontOrigin="$CF_URL" \
  --no-fail-on-empty-changeset
echo "Seeding project / relation / replay records."
python3 backend/seed.py --stack "$STACK" --region "$REGION"
OUT=$(aws cloudformation describe-stacks --region "$REGION" --stack-name "$STACK" --output json)
export OUT
python3 - <<'PY'
import json,os,pathlib
out=json.loads(os.environ["OUT"])["Stacks"][0]["Outputs"]
values={x["OutputKey"]:x["OutputValue"] for x in out}
pathlib.Path(os.environ.get("DIST_DIR","dist"),"data").mkdir(parents=True,exist_ok=True)
config={"projectApiUrl":values["ApiUrl"],"appSyncApiUrl":values["AppSyncApiUrl"]}
if os.environ.get("PUBLISH_GUESTBOOK_KEY")=="yes":
    import subprocess
    res=subprocess.check_output(["aws","appsync","list-api-keys","--api-id",values["AppSyncApiId"],"--region","ap-northeast-2","--output","json"])
    keys=json.loads(res)["apiKeys"]
    if not keys:raise RuntimeError("No AppSync key")
    config["appSyncApiKey"]=keys[0]["id"]
    print("WARNING: publishing the API key makes anonymous guestbook writes possible. Disable after grading.")
else:
    print("Guestbook writing disabled (set PUBLISH_GUESTBOOK_KEY=yes to enable for course demo).")
p=pathlib.Path(os.environ.get("DIST_DIR","dist"))/"data"/"runtime-config.json"
p.write_text(json.dumps(config,ensure_ascii=False),encoding="utf-8")
print("Generated runtime config: "+str(p))
PY
BUCKET=$(aws cloudformation describe-stacks --region "$REGION" --stack-name "$SITE_STACK" \
  --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue | [0]" --output text)
DISTRIBUTION=$(aws cloudformation describe-stacks --region "$REGION" --stack-name "$SITE_STACK" \
  --query "Stacks[0].Outputs[?OutputKey=='DistributionId'].OutputValue | [0]" --output text)
aws s3 sync "$DIST_DIR/" "s3://$BUCKET/" --region "$REGION"
aws cloudfront create-invalidation --distribution-id "$DISTRIBUTION" --paths '/*' >/dev/null
echo "Deployed to $CF_URL ; confirm /atlas/ /pipeline/ /guestbook/ and AppSync query + mutation."
echo "NOTE: API Key mode is for temporary coursework and is not secure authentication."
