# Week 13 — actual deployment and submission evidence

**DO NOT mark as completed until tested on the AWS account.** Region: ap-northeast-2.

## Already verified (GitHub)
- Source: https://github.com/kkokkiyo/cloudDataBase_subject
- 13-week frontend build and offline Lambda test/cfn-lint passed in https://github.com/kkokkiyo/cloudDataBase_subject/actions/runs/45922297661
- 12-week S3/CloudFront screenshot in the earlier report is not week-13 DynamoDB/AppSync evidence

## Work mode checklist after AWS login
1. Open AWS CloudFormation console (Seoul) and deploy `infra/week13.yaml` as `portfolio-week13` with `CAPABILITY_IAM`.
2. Inspect stack creation output. If it fails, resolve the real CloudFormation error rather than claiming success.
3. Run `python3 backend/seed.py --stack portfolio-week13` in an authenticated AWS environment; confirm Projects=3, Skills=8, Steps=8 in tables.
4. Download Actions artifact `portfolio-dist`; run `infra/deploy-week13.sh` with a valid `DIST_DIR` to upload it to the previous private S3 and invalidate CloudFront.
5. Set `PUBLISH_GUESTBOOK_KEY=yes` ONLY for supervised temporary public guestbook demonstration; this exposes an API key in browser and DOES NOT authenticate users. Rotate/remove key after evaluation.
6. Run `bash infra/verify-week13.sh`; verify GraphQL mutation AND query, DynamoDB table key, HTTP API and website route status.
7. Capture the following genuine screenshots at readable resolution.

| Evidence label | Required image |
| --- | --- |
| 13-01-DDB-Key | Guestbook DynamoDB table with PK (S), SK (S) |
| 13-02-DDB-Items | A real test entry in Guestbook after successful mutation |
| 13-03-AppSync-API | AppSync GraphQL API, API endpoint and API key existence (mask key value) |
| 13-04-IAM-Role | AppSync data source service role with minimum dynamodb:PutItem / Query permissions |
| 13-05-GraphQL-Mutation | Successful addGuestbookEntry response with entryId |
| 13-06-GraphQL-Query | Successful listGuestbookEntries response with identical entryId |
| 13-07-Web-MVP | CloudFront /guestbook/ visible new message, form and list |
| 13-08-Atlas | Dynamic project graph filter and AWS API data in use |
| 13-09-Replay | Four-step Replay changing between stages |
| 13-10-Debug | Real error message and fix result (if any). GitHub CI NoRegionError can be used as developer debugging, but must not be misrepresented as AWS AppSync debugging |

## Report completion conditions
Add actual timestamps/URLs, briefly describe exact test inputs and results, and cite screenshot file names. Do not use a mocked/stock UI or last week's screenshots as new AWS console evidence. The written report currently contains quizzes, code review and CI error; it does not yet contain actual AppSync/DynamoDB runtime evidence.
