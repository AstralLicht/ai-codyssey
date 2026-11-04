# 나의 첫 개발 작업실 - 올인원 입학 연수

## 1. 프로젝트 개요와 현재 상태

터미널 조작, Linux 권한, Docker 컨테이너 운영, 웹 서버 이미지 제작, 포트 매핑, 바인드 마운트와 볼륨 영속성을 직접 검증한 프로젝트다. Windows 호스트에서 Docker Desktop의 Linux 컨테이너를 사용한다.

2026-11-04 실제 실행 결과를 기록했다. 아래 출력 발췌는 실제 로그이며, 예상 출력으로 대체하지 않았다. Git 작성자 및 원격 저장소 설정을 마쳤다. **브라우저 주소창 포함 캡처와 VS Code 로그인·연동 화면 증거는 아직 추가해야 한다.**

## 2. 실행 환경

| 항목 | 확인 결과 |
|---|---|
| 호스트 | Windows / PowerShell 5.1 |
| 명령 실행 터미널 | Codex CLI 명령 실행 환경 |
| Docker CLI / 서버 | 29.9.2 / 29.9.2 |
| 컨테이너 환경 | Docker Desktop Linux 엔진, Ubuntu 24.04 |
| Git | 2.56.0.windows.2 |
| 웹 베이스 이미지 | nginx:alpine |
| 웹 포트 | 127.0.0.1:18080 → 컨테이너 80 |

Docker 실행 파일은 `C:\Program Files\Docker\Docker\resources\bin\docker.exe`에 있었다. PATH에 없어 절대 경로로 찾은 뒤 스크립트 프로세스의 PATH에 해당 디렉터리를 추가했다. Docker 엔진 접근에는 실행 환경의 추가 권한이 필요했다.

## 3. 수행 체크리스트

- [x] 터미널 기본 조작 및 숨김 파일 확인
- [x] 파일과 디렉터리 각각 권한 변경 및 전후 비교
- [x] 기존 Docker 설치 상태와 엔진 동작 점검
- [x] hello-world 및 Ubuntu 실행
- [x] 이미지 다운로드·조회, 컨테이너 실행·중지·삭제·조회
- [x] 컨테이너 로그와 리소스 확인
- [x] Dockerfile 직접 작성 및 커스텀 이미지 빌드
- [x] 포트 매핑 HTTP 200 검증
- [x] 바인드 마운트 변경 전후 응답 비교
- [x] 볼륨 생성 및 컨테이너 삭제 후 데이터 유지 검증
- [ ] 주소창과 응답 화면이 함께 보이는 브라우저 캡처
- [x] 실제 작성자 정보와 기본 브랜치 설정 및 설정 로그
- [ ] GitHub 저장소 업로드 및 VS Code 로그인·연동 증거

## 4. 파일과 증거 안내

- [웹 페이지 소스](app/index.html)
- [Dockerfile](Dockerfile)
- [전체 자동 검증 스크립트](scripts/verify.ps1)
- [명령과 출력을 포함한 전체 실제 수행 로그](evidence/docker-verification.txt)
- [Docker 인증 도우미 PATH 오류 원본](evidence/initial-docker-error.txt)
- [PowerShell 인자 전달 오류 원본](evidence/quoting-error.txt)
- [실제 Git 로컬 설정](evidence/git-config.txt)
- [선택 과제용 단일 서비스 Compose 설정](compose.yaml) - 설정 작성 완료, Compose 실행은 미검증

전체 로그에는 Windows 호스트 경로가 포함된다. 다른 PC에서는 스크립트가 저장소 위치를 기준으로 경로를 계산하므로 같은 사용자명이나 절대 경로가 필요하지 않다. 로그의 시각 중 컨테이너 로그는 UTC, 호스트 실행 시각은 한국 시간이다.

## 5. 수행 과정

### 5.1 Docker 설치 상태 점검

이미 설치된 Docker를 사용했으며 신규 설치를 수행한 것으로 기록하지 않는다.

```text
$ docker --version
Docker version 29.9.2, build a82e528
$ docker info --format 'Server={{.ServerVersion}} OS={{.OperatingSystem}}'
Server=29.9.2 OS=Docker Desktop
$ docker run --rm hello-world
Hello from Docker!
```

`docker pull hello-world`와 `docker pull ubuntu:24.04`도 실행했다. 이미지 다운로드와 digest 결과는 전체 로그에 있다.

### 5.2 터미널 파일 조작

Ubuntu 컨테이너에서 다음 명령을 실행했다. `set -eux`로 각 명령을 출력하고 오류 시 중단했다. 전체 명령과 출력은 [수행 로그](evidence/docker-verification.txt)의 첫 Ubuntu 실행 부분에 있다.

```bash
pwd
mkdir -p /tmp/practice
cd /tmp/practice
touch empty.txt .hidden
echo terminal-ok > original.txt
cp original.txt copy.txt
mv copy.txt renamed.txt
ls -la
cat renamed.txt
rm renamed.txt
```

실제 출력 발췌:

```text
/
-rw-r--r-- 1 root root    0 Nov  4 09:16 .hidden
-rw-r--r-- 1 root root    0 Nov  4 09:16 empty.txt
-rw-r--r-- 1 root root   12 Nov  4 09:16 original.txt
-rw-r--r-- 1 root root   12 Nov  4 09:16 renamed.txt
terminal-ok
```

`/tmp/practice`는 루트부터 지정하는 절대 경로다. `original.txt`는 현재 디렉터리를 기준으로 해석하는 상대 경로이며 이 실습에서는 `/tmp/practice/original.txt`를 가리킨다. 실습용 컨테이너는 종료 시 삭제되므로 호스트 파일을 지우지 않는다.

### 5.3 파일·디렉터리 권한 변경

```bash
mkdir permissions
touch permissions/file
chmod 600 permissions/file
chmod 700 permissions
stat -c %a:%n permissions permissions/file
chmod 644 permissions/file
chmod 755 permissions
stat -c %a:%n permissions permissions/file
```

```text
700:permissions
600:permissions/file
755:permissions
644:permissions/file
```

소유자/그룹/기타 사용자 순으로 각 숫자를 해석한다. 읽기 r=4, 쓰기 w=2, 실행 x=1을 더한다. 644는 소유자 읽기·쓰기, 나머지 읽기다. 755는 소유자 전체 권한, 나머지 읽기·실행이다. 디렉터리의 x는 내부 항목에 접근·탐색할 권한이다. 이 결과는 Linux 컨테이너 내부 권한이며 Windows NTFS ACL 변경 결과가 아니다.

### 5.4 컨테이너 실행과 세션 수명

```text
$ docker run -d --name codyssey-20261104181613-first ubuntu:24.04 sleep infinity
$ docker exec codyssey-20261104181613-first bash -lc 'ls /; echo exec-session-finished'
exec-session-finished
$ docker inspect --format '{{.State.Running}}' codyssey-20261104181613-first
true
$ docker stop codyssey-20261104181613-first
$ docker ps -a --filter name=codyssey-20261104181613
... Exited (137) ... codyssey-20261104181613-first
$ docker rm codyssey-20261104181613-first
```

`exec`는 실행 중인 컨테이너에 별도 프로세스를 생성한다. 해당 bash가 끝나도 주 프로세스인 `sleep infinity`가 살아 있으면 컨테이너는 유지된다. `attach`는 기존 주 프로세스의 입출력에 연결하므로 주 프로세스를 종료하면 컨테이너도 종료된다. 실제 관찰은 exec 종료 후 `true` 및 stop 후 `Exited`이며, 대화형 attach 분리 키 조작은 수행하지 않았다.

### 5.5 Dockerfile과 커스텀 웹 서버

기존 NGINX 이미지에 직접 작성한 HTML을 복사했다. 목적별 변경은 다음과 같다.

| 변경 | 목적 |
|---|---|
| `COPY app/` | 기본 NGINX 화면을 과제용 웹 페이지로 교체 |
| `LABEL` | 이미지 식별 |
| `APP_ENV=training` | 실습 환경 메타데이터 지정. 정적 HTML 내용이나 포트는 바꾸지 않음 |
| `HEALTHCHECK` | 내부 HTTP 응답을 통한 상태 점검 |
| `EXPOSE 80` | 내부 서비스 포트 문서화. 호스트 공개는 별도 `-p`로 설정 |

```powershell
docker build -t codyssey-workspace:1.0 .
docker images codyssey-workspace
docker run -d --name codyssey-20261104181613-web -p 127.0.0.1:18080:80 codyssey-workspace:1.0
Invoke-WebRequest http://127.0.0.1:18080/ -UseBasicParsing
docker port codyssey-20261104181613-web
docker logs codyssey-20261104181613-web
docker stats --no-stream codyssey-20261104181613-web
```

```text
HTTP 200
... workspace-v1 ...
80/tcp -> 127.0.0.1:18080
```

컨테이너는 독립된 네트워크 환경을 사용하므로 내부 80 포트를 호스트 18080에 연결했다. `127.0.0.1`로 바인딩하여 이 PC에서만 접속한다. `logs`에서는 GET 요청 200 응답, `stats`에서는 CPU 0.00%, 메모리 14.48MiB / 7.594GiB가 관찰됐다. 수치는 실행 시점마다 달라진다.

빌드에 사용된 베이스 digest는 `sha256:785835ea65db4bba6f021acc0f3be91b0fef76a53fe41f8588c6698d2aed0606`이다. `nginx:alpine` 태그는 이후 변경될 수 있으며 엄밀히 동일한 베이스가 필요하면 Dockerfile의 FROM에 이 digest를 지정한다.

### 5.6 바인드 마운트 변경 반영

스크립트는 저장소 아래 `evidence/bind-site`를 생성하고 실제 절대 경로를 계산해 연결했다.

```powershell
Set-Content evidence/bind-site/index.html bind-before
docker run -d --name <실습용이름> -p 127.0.0.1:18081:80 --mount "type=bind,source=<계산된경로>,target=/usr/share/nginx/html,readonly" codyssey-workspace:1.0
Invoke-WebRequest http://127.0.0.1:18081/ -UseBasicParsing
Set-Content evidence/bind-site/index.html bind-after
Invoke-WebRequest http://127.0.0.1:18081/ -UseBasicParsing
```

위 설명용 인자는 [실제 로그](evidence/docker-verification.txt)에 구체적 값으로 남아 있다. 실제 응답은 변경 전 `HTTP 200 / bind-before`, 변경 후 `HTTP 200 / bind-after`였다. 재빌드나 재시작 없이 호스트 변경이 반영됐다. Windows PowerShell의 UTF-8 BOM으로 응답 문자열 앞에 `ï»¿`가 표시됐으나 검증 문자열과 상태 코드는 정상 확인했다. 읽기 전용 마운트는 컨테이너의 쓰기를 막으며 호스트에서의 수정은 허용한다.

### 5.7 Docker 볼륨 영속성

```powershell
docker volume create codyssey-20261104181613-data
docker run -d --name codyssey-20261104181613-first --mount type=volume,source=codyssey-20261104181613-data,target=/data ubuntu:24.04 sleep infinity
docker exec codyssey-20261104181613-first bash -lc 'echo persistent-workspace > /data/proof.txt; cat /data/proof.txt'
docker rm -f codyssey-20261104181613-first
docker run -d --name codyssey-20261104181613-second --mount type=volume,source=codyssey-20261104181613-data,target=/data ubuntu:24.04 sleep infinity
docker exec codyssey-20261104181613-second cat /data/proof.txt
```

```text
# 삭제 전
persistent-workspace
# 기존 컨테이너 삭제 후, 새 컨테이너에서
persistent-workspace
```

서로 다른 컨테이너 ID와 삭제 명령은 전체 로그에 있다. 데이터는 컨테이너 쓰기 계층이 아닌 Docker 관리 볼륨에 저장되어 컨테이너 삭제 후에도 유지됐다. 볼륨 자체를 삭제하면 데이터도 삭제된다.

## 6. 트러블슈팅

### 6.1 docker 및 인증 도우미를 찾지 못함

- 문제: PATH에서 docker를 찾지 못했고 절대 경로 실행 시 이미지 pull에서 `docker-credential-desktop`을 찾지 못했다.
- 원인 가설: 실행 환경 PATH에 Docker 설치 디렉터리가 빠졌다.
- 확인: 표준 설치 경로의 docker.exe 존재와 버전은 확인됐으나 pull은 인증 도우미 실행 오류로 실패했다. [첫 오류 로그](evidence/initial-docker-error.txt).
- 해결: 스크립트 프로세스 PATH에 Docker bin 디렉터리를 추가했다. 이후 pull, hello-world와 빌드가 성공했다. 시스템 전체 PATH는 변경하지 않았다.

### 6.2 PowerShell에서 Linux 명령의 따옴표 전달 오류

- 문제: `stat -c "%a %n"`이 Docker를 거치며 `stat -c %a`로 해석돼 `missing operand`로 실패했다.
- 원인 가설: Windows PowerShell 5.1의 외부 실행 파일 인자 전달 과정에서 내부 따옴표와 공백이 보존되지 않았다.
- 확인: [오류 로그](evidence/quoting-error.txt)의 bash 추적 출력에서 잘린 인자를 확인했다.
- 해결: 공백 없는 `stat -c %a:%n`으로 변경했다. 재실행에서 파일 600→644, 디렉터리 700→755가 모두 출력됐고 전체 검증 PASS를 확인했다.

### 6.3 엔진 접근 권한

- 문제: 제한된 실행 환경에서 Docker named pipe 접근이 거부됐다.
- 원인 가설: 엔진 미설치보다 실행 환경의 접근 권한 제한이다.
- 확인: 같은 docker.exe가 버전은 출력했고, 추가 실행 권한 적용 후 `docker info`에서 서버 29.9.2가 응답했다.
- 해결: 과제 검증 명령을 엔진에 접근 가능한 실행 권한으로 실행했다. Docker 보안 설정을 변경하지 않았다.

## 7. 재현 방법

Docker Desktop의 Linux 엔진이 실행 중이고 18080, 18081 포트가 비어 있어야 한다. 저장소 루트에서 실행한다.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify.ps1
```

완료 시 `PASS: all automated Docker checks completed.`가 출력된다. 스크립트는 이번 실행에서 만든 실험 컨테이너를 정리하고 웹 컨테이너와 데이터 볼륨은 증거 확인용으로 남긴다. 재실행 전 기존 웹 컨테이너를 중지해야 포트가 충돌하지 않는다. 기존 사용자의 컨테이너나 볼륨을 일괄 삭제하지 않는다.

이번 실제 실행의 웹 컨테이너와 볼륨은 다음 명령으로 정리할 수 있다. 데이터 확인을 마친 뒤에만 실행한다.

```powershell
docker rm -f codyssey-20261104181613-web
docker volume rm codyssey-20261104181613-data
```

선택 과제 Compose 사용법은 아래와 같으며 현재 실행 검증 완료 항목에는 포함하지 않았다.

```powershell
docker compose up -d --build
docker compose ps
docker compose logs
docker compose down
```

## 8. Git과 GitHub 및 제출 잔여 작업

Git은 로컬 변경 이력을 관리하는 도구이며 GitHub는 원격 저장소와 협업 기능을 제공한다. 작성자는 `juhyun`, 이메일은 사용자가 제공한 값으로 로컬 설정했다. 원격 저장소는 https://github.com/AstralLicht/ai-codyssey.git 이다. 원격 main의 기존 커밋 이력을 이어받았으며 기존 `attend.py`도 그대로 보존했다. [Git 설정 결과](evidence/git-config.txt)에서 실제 설정을 확인할 수 있다.

아래 명령 중 config, 브랜치 이름 변경, 원격 설정은 수행했다. commit/push 결과는 업로드 후 추가한다. 다른 PC에서 재현할 때 이름·이메일·원격 주소를 본인 값으로 바꾼다.

```powershell
git config --local user.name "실제 작성자 이름"
git config --local user.email "실제 작성자 이메일 또는 GitHub 비공개 이메일"
git config --local init.defaultBranch main
git branch -M main
git config --local --list
git add .
git commit -m "Complete developer workspace mission"
git remote add origin https://github.com/OWNER/REPOSITORY.git
git push -u origin main
```

VS Code에서 GitHub 로그인을 완료하고 이 폴더의 원격 저장소 연결을 확인한 화면을 첨부한다. 인증 화면의 코드나 토큰은 기록하지 않는다. `git config --list` 전체에는 인증 관련 값이 있을 수 있으므로 공개 로그에는 민감 항목을 제거하고 필요한 설정만 남긴다.

최종 제출은 [GitHub 저장소](https://github.com/AstralLicht/ai-codyssey) 링크다. 현재 로컬 실습 검증과 Git 설정을 완료했다. 주소창 포함 브라우저 캡처와 VS Code 계정 연동 증거는 남아 있다.

### 남은 화면 증거 수집

1. 브라우저에서 `http://127.0.0.1:18080/`을 열어 주소창과 웹 페이지가 동시에 보이도록 캡처하고 `evidence/browser-port.png`로 저장한다.
2. VS Code에서 이 저장소를 열어 GitHub 로그인 상태와 원격 저장소 연결을 확인한다. 토큰·인증 코드가 없는 화면만 `evidence/vscode-github.png`로 저장한다.
3. README에 두 이미지를 삽입하고 관련 체크박스를 완료로 바꿔 커밋·푸시한다.

이번 자동화에서는 브라우저 창을 선택할 때 `window id 133272 no longer belongs to Naver_Whale; current owner is Naver_Whale` 오류가 반복돼 캡처를 만들지 못했다. 화면 증거를 임의 생성하지 않았다. curl/HTTP 응답 증거는 5.5 및 전체 로그에서 확인할 수 있다.
