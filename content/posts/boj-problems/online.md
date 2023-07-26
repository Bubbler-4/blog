---
title: "개발 환경 설치 없이 BOJ 문제 풀기"
date: 2023-07-26T16:34:14+09:00
draft: false
tags: ["PS", "BOJ", "개발"]
---

BOJ 등 문제 풀이 사이트에서 문제를 풀려고 하는데 로컬에 개발 환경(컴파일러, IDE 등)을 설치하기 어려운 경우가 있다.
이 포스트에서는 이러한 경우에 자신이 짠 코드를 돌려 볼 수 있는 방법을 몇 가지 소개한다.

<!--more-->

## 온라인 코드 실행 사이트

### Try It Online (TIO)

* 링크: [Try It Online!](https://tio.run/)
* 지원되는 언어: 600개 이상(!), 거의 모든 메이저 언어와 BF, Befunge, Whitespace 등의 esolang, **Mathematica, GolfScript** 포함
* 실행 시간 제한: 60초 (컴파일 시간 포함)

원래는 [Code Golf StackExchange](https://codegolf.stackexchange.com/)에서 사용하기 위해 만들어진 사이트이며,
그래서 코드가 몇 바이트인지를 표시하는 기능이 포함되어 있다.

컴파일러 플래그를 직접 넣을 수 있다. BOJ 제출용 코드는 [BOJ Help: 언어 정보](https://help.acmicpc.net/language/info)를 참고하여 플래그를 넣고 실행해 보면 된다.
컴파일러 버전은 보통 플래그에 `-V` 또는 `--version`을 넣어보면 알 수 있다.

코드 공유 기능이 있다. 위쪽의 링크 버튼을 눌러서 나오는 여러 버튼 중에서 Plain URL을 복사하면 된다.

Mathematica와 GolfScript 코드를 돌려볼 수 있는 사실상 유일한 사이트이다.

아쉽게도 TIO의 운영자가 개인적인 이유로 언어 버전 업데이트를 중단한 상태다. 최신 버전이 필요한 경우 다른 사이트를 사용하는 것이 좋다.
또한, 아희(Aheui)가 있지만 BOJ에서 사용하는 인터프리터와는 동작이 다르다.

### Attempt This Online (ATO)

* 링크: [Attempt This Online!](https://ato.pxeger.com/)
* 지원되는 언어: 거의 모든 메이저 언어의 **최신 버전**과 **아희** 포함
* 실행 시간 제한: 60초 (컴파일 시간 포함)

위의 TIO의 대체재로 등장한 사이트 중에서 가장 잘 개발, 유지보수되고 있는 사이트이다.
최신 버전 컴파일러가 필요한 경우 보통 이 사이트를 쓰면 된다.

ATO에도 코드 공유 기능이 있는데, 그냥 아무것도 하지 않고 현재 주소를 복사하면 된다.
단, 이 기능 때문에 매우 긴 소스 코드를 편집하려고 하면 페이지가 느려지는 문제가 있다.

### Godbolt

* 링크: [Godbolt](https://godbolt.org/)
* 지원되는 언어: 거의 모든 메이저 언어 포함, **언어 버전 선택 가능**
* 실행 시간 제한: 약 5초 추정

원래는 어떤 코드의 컴파일된 어셈블리를 확인하는 용도로 많이 쓰지만, 코드 실행용으로 쓸 수도 있다.
코드 창의 + 버튼을 누르고 Execution Only를 선택하면 되며, Executor 창의 오른쪽에서 두 번째 버튼을 선택하여 stdin을 입력할 수 있다.

다양한 컴파일러 버전을 지원하기 때문에, 정확히 특정 버전의 컴파일러가 필요한 경우에도 사용할 수 있다.

## 클라우드 IDE 서비스

단순히 BOJ 제출용 코드만 작성할 것이 아니라 좀 더 제대로 된 개발 환경을 구성하고 싶다면 클라우드 IDE 서비스를 사용하면 좋다.
이러한 서비스로는 Gitpod와 Github Codespaces 등이 있고, 둘 다 웹용 VSCode에서 리눅스 가상 머신에 접속하는 형태이다.
그냥 VSCode를 사용하는 것처럼 터미널도 제공되므로 필요한 컴파일러와 기능을 깔고 사용하면 된다.
다만 Github 계정이 있어야 하고 (Gitpod의 경우 Gitlab/Bitbucket도 가능), Github 레포를 만들어서 기초 설정을 해야 한다.

### Gitpod

* 링크: [Gitpod](https://gitpod.io/)
* 월 제공 시간: 50시간 (standard), 25시간 (large)

아무 설정을 하지 않고 workspace를 생성하면 C/C++, Java, Node.js, Python, Rust 등이 기본으로 깔려 있는 `gitpod/workspace-full` 도커 이미지를 사용한다.
VNC 설정이 되어 있는 `gitpod/workspace-full-vnc`를 쓰면 GUI 프로그램도 사용 가능하다. (가끔 회사에서 컴퓨터로 디스코드 접속할 때 쓴다(...))
설정 방법은 [여기](https://www.gitpod.io/docs/configure/workspaces/workspace-image)를 참고.

Workspace를 생성한 후 Pin을 하지 않고 방치하면 14일 뒤에 삭제된다.

### Github Codespaces

* 링크: [Github Codespaces](https://github.com/codespaces)
* 월 제공 시간: 60시간 (2-core), 30시간 (4-core)

기본 이미지에는 아무것도 깔려있지 않지만, [여기](https://docs.github.com/ko/codespaces/setting-up-your-project-for-codespaces/adding-a-dev-container-configuration/introduction-to-dev-containers#using-a-predefined-dev-container-configuration)에 있는 대로 하면 원하는 언어의 개발 환경이 제공되는 듯 하다.

Codespace를 생성한 후 Keep codespace를 선택하지 않고 방치하면 한 달 뒤에 삭제된다.
또한 시간 제한과 별도로 저장 공간 제한이 있는데 (이미지 크기 x 이미지를 유지한 기간으로 계산), 경험상 2개 정도의 codespace를 무기한 유지할 수 있다.

## 개인 서버에 원격 개발 환경 만들기

개인 서버가 있거나 GCP, AWS 등의 무료 인스턴스가 있는 경우에는 그 서버에 개발 환경을 만드는 것도 고려해볼 수 있다.

### code-server

* 링크: [code-server](https://github.com/coder/code-server)

리눅스 서버에 code-server를 설치하고 `code-server`를 실행한 다음 서버에 접속하면 그 서버 컴퓨터에서 VSCode를 켠 것처럼 사용할 수 있다.
직접 HTTPS 설정하는 것은 귀찮으니, Cloudflare에서 적당한 도메인을 하나 사서 Cloudflare DNS 설정을 하는 것이 가장 간편하다.
(어차피 도메인이 없으면 인증서가 발급이 안 됨)