# Cloud Database — AWS Self-Introduction Web App

한양대학교 ERICA 클라우드데이터베이스 12~14주차 실습 프로젝트입니다.

## 목표
기존 [Astro 포트폴리오](https://github.com/kkokkiyo/kkokkiyo.github.io)를 유지하면서 AWS 기반 **Research Atlas**(기술–프로젝트 그래프)와 **Interactive Pipeline Replay**(사전 제작한 프로젝트 프로세스 도식)를 추가합니다.

**12주차:** GitHub 소스 관리 → 정적 사이트 빌드 → S3 비공개 버킷 → CloudFront OAC → CloudFront 200 / S3 직접 접근 403 검증.

**13주차:** DynamoDB · API Gateway · Lambda · 기능 연동.

**14주차:** CloudWatch · 비용 확인 · 최종 보고.

## 개발 구성
- `patch/`: 기존 Astro 사이트에 병합할 새 페이지·데이터
- `infra/week12.yaml`: S3 비공개, PublicAccessBlock, CloudFront OAC, 버킷 정책 및 URL rewrite
- `backend/`: 13주차 읽기 전용 API와 DynamoDB 데이터 예제
- `.github/workflows/build.yml`: 기존 사이트를 복제해 패치를 적용하고 Astro 빌드 및 artifact 생성

## 배포시 주의
- AWS 실계정 배포 전 예상 비용, CloudFormation 변경사항을 확인합니다.
- IAM 키·비밀번호·토큰을 GitHub에 커밋하지 않습니다.
- 실제 CloudFront URL과 HTTP 200/403은 실계정 배포 이후에만 제출합니다.
- 개념도는 실제 연구 실험 스크린샷이 아닙니다.

## 실제 AWS 리소스 배포
CloudFront/OAC 설정 템플릿은 `infra/week12.yaml`을 참조하십시오. CloudFormation 스택 생성 후 빌드 아티팩트 `dist/`를 S3에 업로드합니다. Windows: `aws cloudformation deploy --template-file infra/week12.yaml --stack-name portfolio-week12 --parameter-overrides SiteBucketName=YOUR_UNIQUE_BUCKET --region ap-northeast-2` 후 `aws s3 sync dist s3://YOUR_UNIQUE_BUCKET/ --region ap-northeast-2`.

버킷 퍼블릭 접근 차단을 해제하지 마세요.
