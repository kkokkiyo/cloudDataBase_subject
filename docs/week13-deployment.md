# 13주차 실제 배포 순서

이 저장소는 기존 `kkokkiyo.github.io` Astro 소스를 빌드하여 AWS S3·CloudFront에 배포합니다.

## 빌드
GitHub Actions의 **Build AWS course portfolio**가 성공하면 `portfolio-dist` 아티팩트를 다운로드하고 `dist/` 폴더에 압축을 풉니다. `patch/src/pages/guestbook.astro` 및 `atlas.astro`, `pipeline.astro`가 빌드에 포함됩니다.

## AWS 서울 리전 배포
AWS CLI 로그인 후 아래 명령을 실행합니다.

```bash
aws sts get-caller-identity
python3 -m pip install boto3
export DIST_DIR=dist
bash infra/deploy-week13.sh
```

스크립트는 `infra/week13.yaml`을 이용해 DynamoDB 5개 테이블(Projects, Skills, ProjectSkills, PipelineSteps, Guestbook), Lambda, HTTP API, AppSync API, DynamoDB IAM Role/리졸버를 생성합니다. 초기 데이터 3개 프로젝트·8개 기술·8개 단계가 등록됩니다. 클라우드 리소스 생성은 과금될 수 있습니다.

**방명록 실습:** AppSync Query/Mutation을 콘솔에서 우선 테스트합니다. 공개 웹페이지에서 직접 등록하려면 `PUBLISH_GUESTBOOK_KEY=yes`로 스크립트를 다시 실행할 수 있지만, 웹에 노출되는 API 키는 **인증 수단이 아니며 누구나 사용할 수 있습니다.** 과제 실습 완료 후 API 키를 삭제하고 쓰기 기능을 중단하세요. 공개 방명록을 계속 운영하려면 Cognito 인증, WAF·Rate Limit 및 스팸 방지가 필요합니다.

## 검증
- DynamoDB 테이블 키: Guestbook `PK`(S), `SK`(S)
- GraphQL API `listGuestbookEntries(limit:20)` 및 `addGuestbookEntry(name,message)` 실행 확인
- `/atlas/` 기술 선택 및 동적 데이터 상태 표시
- `/pipeline/` 4단계 이전·다음 클릭 및 AWS 단계 조회
- `/guestbook/` 저장·조회 결과(웹 키 설정한 경우)
- CloudWatch에서 Lambda 오류 확인
- 디버깅 보고서에는 실제로 관찰한 오류만 작성

배포 후 로그인 계정과 AWS 콘솔 화면에서 캡처를 수집하며, 실제 수행하지 않은 실습을 완료라고 표현하지 않습니다.
