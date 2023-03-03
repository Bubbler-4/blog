---
title: "Cargo-OJ: PS와 개발 둘 다에 진심인 자의 업보"
date: 2023-03-03T09:25:59+09:00
draft: false
tags: ["PS", "Dev", "Rust", "Cargo-OJ"]
---

*PS에서 best practice를 추구하면 안 되는 걸까?*

<!--more-->

Rust 언어로 PS를 하면서 여러 가지 문제를 풀다 보니 [각종 수제 자료구조와 알고리즘](https://github.com/Bubbler-4/rust-problem-solving/tree/b2d784cc06a48187afce2f22e0989377fd3b2966/competitive/src/competelib)을 만들게 되었다. 나름 코드 구조화를 중요하게 생각하는 편이라, 각각의 알고리즘은 lib crate 내의 여러 모듈에 나누어서 들어 있다.

이걸 가지고 문제를 풀 때, 지금까지는 필요한 라이브러리 코드를 솔루션 파일에 직접 복붙하는 방법을 써 왔다. 온라인 저지(OJ)에서는 단일 파일 제출만 허용하기 때문이다. 그러다 어느 날 이런 생각이 들었다. 그냥 필요한 알고리즘을 import해서 문제를 풀고, 그걸 자동으로 소스파일 하나로 만들어서 제출하면 안 될까?

기존에 비슷한 물건이 있는지 요리조리 검색해 봤지만 딱히 뭐가 나오진 않았다. kiwiyou님이 만든 [basm-rs](https://github.com/kiwiyou/basm-rs)라는 게 있지만, 다음과 같은 이유로 나는 사용하지 않는다.

* 결과물이 머신 코드의 인코딩이다. 나는 OJ에 제출하는 코드는 사람이 읽을 수 있는 게 낫다고 생각하는 편이다.
* nightly 버전 컴파일러와 외부 crate 사용이 된다. 이건 OJ의 기본적인 제한 사항을 우회하는 것이라 다소 불공정하지 않나 생각한다.

그래서 **직접 그런 물건을 만들어 보기로 했다.**

## 요구 사항

* 라이브러리를 러스트 모듈 형태로 저장하고,
* 그 라이브러리에서 필요한 기능을 use해서 `lib.rs`에 풀이를 작성해 놓고 커맨드를 치면,
* 전체 모듈을 하나의 `main.rs`로 만든다.
* `main.rs`는 포매팅 되어 있어야 하고,
* *모든 불필요한 코드는 제거되어야 한다.*

마지막 줄이 중요하다. 전체 라이브러리를 합치면 대충 10만 바이트는 나오는데 이를 모든 제출 파일에 박는 건 말이 안 된다.

이를 위해서 다음의 2단계로 나누어 공략하기로 했다.

* 먼저 모듈 트리를 하나의 파일로 만든다.
* 그 다음, 컴파일 할 때 `dead_code` warning이 뜨는 item을 모두 지운다. 이 때, 주어진 코드는 컴파일이 된다고 가정한다.

## 1단계: 모듈 트리를 하나의 파일로 만들기

일단 소스를 파싱해야겠다고 생각했다. 문자열 치환으로 때우고 넘기더라도 2단계에서 item을 지울 때 어차피 필요할 것이다.

### Rust 소스 파싱하기

Rust의 문법은 꽤나 복잡하고, 모든 문법을 다 알지도 못하니 처음부터 짜는 건 좋은 방법이 아니다. 다행히 [`syn`](https://docs.rs/syn/latest/syn/index.html) crate를 쓰면 이 부분은 간단하게 해결이 된다.

디펜던시가 있는 프로젝트를 빌드해 봤다면, 지나가는 crate 이름 중에 거의 반드시 `syn`이라는 것을 봤을 것이다. 이는 주로 "proc macro"라는 매크로를 짤 때 쓰이며, `quote`와 `proc-macro2` 등의 crate와 거의 항상 같이 다닌다. 하지만 여기서는 `syn`으로 완전한 Rust 코드를 파싱해서 AST로 만들고 그 AST를 수정하는 용도로 쓸 것이다.

[`syn::parse_file`](https://docs.rs/syn/latest/syn/fn.parse_file.html)은 문자열을 받아 [`syn::File`](https://docs.rs/syn/latest/syn/struct.File.html)을 리턴한다. `File`은 [`syn::Item`](https://docs.rs/syn/latest/syn/enum.Item.html)의 벡터를 갖고 있고, `Item`은 Rust의 모든 "item"을 나타낼 수 있는 enum이다. 여기서 item은 모듈 레벨에 등장할 수 있는 모든 정의나 선언문을 통틀어 말하는 것으로, 함수 정의, struct/enum/trait 정의, `impl` 블록이나 `mod` 선언일 수도 있다. 그런 item들 중에서 `mod` 선언은 [`syn::ItemMod`](https://docs.rs/syn/latest/syn/struct.ItemMod.html)에 저장된다.

```rust
pub struct ItemMod {
    pub attrs: Vec<Attribute>,
    pub vis: Visibility,
    pub mod_token: Mod,
    pub ident: Ident,
    pub content: Option<(Brace, Vec<Item>)>,
    pub semi: Option<Semi>,
}
```

`ident`는 모듈의 이름을 가리키고, `content`가 `None`이면 `ident`가 가리키는 파일을 파싱해서 채워주면 될 것이다.

### Rust의 모듈 트리 구조

지금까지의 정보를 이용하면 `src/lib.rs` 안에 있는 `mod m;` 선언을 찾아낼 수 있다. 그럼 `mod m`에 해당하는 파일은 어디에 있을까? [Rust reference](https://doc.rust-lang.org/reference/items/modules.html#module-source-filenames)에 그 해답이 있다. 문제는, 그 해답이 여러 개다.

가장 흔하게 쓰이는 구조는 다음과 같다.

```rust
// lib.rs
mod m1;

// m1.rs
mod m2;

// m1/m2.rs
struct MyStruct();
```

하지만 다음과 같이 `mod.rs`를 쓸 수도 있고...

```rust
// lib.rs
mod m1;

// m1/mod.rs <--
mod m2;

// m1/m2.rs
struct MyStruct();
```

심지어 path attribute를 써서 위치를 지정하는 방법도 있다.

```rust
// lib.rs
mod m1;

// m1.rs
#[path = "m2.rs"]
mod m2;

// m2.rs <--
struct MyStruct();
```

일단은 첫 번째 방법만 허용하기로 했다. 그러면 같은 방법으로 하위 모듈에서도 더 하위 모듈을 찾아서 끼워넣으면 되니 재귀적으로 구현하면 된다.

추가적으로 root에서 `#![allow(dead_code)]`를 감지해서 지우는 코드도 넣었다. `lib.rs`에서 코드를 짤 때 이게 없으면 IDE에서 warning 폭탄을 맞게 된다.

코드: [`fn load_recursive`](https://github.com/Bubbler-4/rust-problem-solving/blob/90bb4bf3a7b4cd33cd426bf51a743e549233fb3d/cargo-oj/src/main.rs#L316-L367)

## 2단계: dead code 지우기

### `dead_code` warning 추출하기

이제 모듈 트리 전체를 하나의 파일로 나타낸 AST를 만들었다. 여기서 dead code를 어떻게 체크할까?

이걸 손으로 짜려면 대충 [컴파일러의 반](https://fasterthanli.me/articles/proc-macro-support-in-rust-analyzer-for-nightly-rustc-versions#a-tale-of-one-and-a-half-compilers) 정도를 직접 구현해야 한다. 딱 봐도 불가능. `rust-analyzer`가 비슷한 일을 하는 것을 알고 있어서 이걸 라이브러리로 쓰는 방법도 찾아봤지만 찾을 수 없었다. 이제 남은 유일한 방법은 `cargo check` 또는 같은 역할을 하는 `rustc` 명령을 돌리는 것이었다.

`cargo check`이든 뭐든 돌리려면 갖고 있는 AST를 다시 문자열로 바꿔야 한다. 다행히 [`prettyplease`](https://github.com/dtolnay/prettyplease)라는 crate가 정확히 이걸 해 준다. 거기다가 빠르고, 포매팅도 적용해 준다고 하니, 최종 결과물에 포매팅을 따로 돌릴 필요가 없다.

추가적으로, `cargo check`을 돌리려면 소스 코드가 현재 crate 내에 있어야 한다. 일단 `src/bin/tmp.rs`에 쓰고 `cargo check --bin tmp --message-format json`을 돌리기로 했다. `--message-format json` 부분은 [여기](https://doc.rust-lang.org/cargo/reference/external-tools.html#json-messages)에 설명이 있고, 컴파일러 메시지의 내부 구조는 [여기](https://doc.rust-lang.org/rustc/json.html)에서 볼 수 있다. 이 옵션을 줘서 `cargo check`을 돌리면 여러 개의 JSON 오브젝트가 한 줄에 하나씩 출력된다. 워닝이 있으면 워닝 하나 당 하나의 오브젝트가 나오며, 대략 다음과 같이 생겼다. (포매팅 적용, 일부 필드 간략화)

```json
{
    "reason":"compiler-message",
    "package_id":"..",
    "manifest_path":"..",
    "target":{"..":".."},
    "message":{
        "rendered":"..",
        "children":[],
        "code":{
            "code":"dead_code",
            "explanation":null
        },
        "level":"warning",
        "message":"constant `S` is never used",
        "spans":[
            {
                "byte_end":5450,
                "byte_start":5449,
                "column_end":19,
                "column_start":18,
                "expansion":null,
                "file_name":"src/io.rs",
                "is_primary":true,
                "label":null,
                "line_end":177,
                "line_start":177,
                "suggested_replacement":null,
                "suggestion_applicability":null,
                "text":[".."]
            }
        ]
    }
}
```

이제 `dead_code` 워닝만 보려면 다음과 같은 순서로 체크하면 된다.

* `obj.reason == "compiler-message"`
* `obj.message.code`가 존재
* `obj.message.code.code == "dead_code"`

그럼 JSON 파싱은 어떻게 할까? [`serde_json`](https://docs.rs/serde_json/latest/serde_json/)으로 하면 된다. `string.parse::<serde_json::Value>()`을 호출하면 주어진 문자열을 JSON 오브젝트의 트리 형태로 파싱해준다. 그리고 깊은 위치의 필드를 액세스하려면 [`value.pointer(path)`](https://docs.rs/serde_json/latest/serde_json/enum.Value.html#method.pointer)로 한 번에 액세스할 수 있다.

`dead_code` 워닝의 span 정보는 item 전체의 span이 아니라 이름의 span만 주기 때문에(같은 이유로 IDE에서도 이름에만 노란 밑줄이 그어진다), 실제 item을 통째로 지우기 위해서는 AST 전체를 돌면서 ident의 span이 맞는 item을 찾아야 했다.

코드: [`fn cargo_check_deadcode`](https://github.com/Bubbler-4/rust-problem-solving/blob/97becc831f2e9cf032f2dbe466ff9fb140cabf35/cargo-oj/src/main.rs#L728-L762)

### `dead_code`는 정확히 언제 발생하는가?

[Rustc book](https://doc.rust-lang.org/rustc/lints/listing/warn-by-default.html#dead-code)을 보면 그냥 "The `dead_code` lint detects unused, unexported items"라고 되어 있다. Unexported는 어떤 item이 pub이 아닐 때다. 그럼 어떤 item이 unused인가?

이것저것 시험해봐서 알아낸 사실은 다음과 같다.

* 사용되지 않은 함수, 타입 `type T = U`, 상수 `const C: usize = 0`는 unused이다.
* 사용되지 않은 struct와 enum도 unused이지만, `impl` 블록은 해당되지 않는다. struct와 enum을 지울 때 관련된 `impl` 블록을 지우지 않으면 컴파일이 안될 것이다.
* `impl` 블록 내에 있는 사용되지 않은 개별 item(함수와 상수)들은 unused이다. (`impl` 블록 내에 올 수 있는 item의 종류는 제한적이다.)
* trait과 `impl Trait`은 실제로 사용되지 않더라도 unused로 치지 않는다. 심지어, 어떤 struct나 enum이 trait을 구현하면, 해당되는 struct와 enum도 실제로 사용되지 않았더라도 unused로 치지 않는다.

[예시 코드](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=d1be518711c50b878532b2106015191b)

내 라이브러리에는 `impl Trait`이 제법 있기 때문에, trait에 엮인 코드가 지워지지 않으면 꽤 많은 양의 쓸모없는 코드가 남아있을 것이다. 그래서 다음과 같이 한 단계를 더 추가하기로 했다.

### 접근 방법 ver.2

* 먼저 모듈 트리를 하나의 파일로 만든다.
* 그 다음, 컴파일 할 때 `dead_code` warning이 뜨는 item을 모두 지운다. 이 때, 주어진 코드는 컴파일이 된다고 가정한다. struct나 enum은 지우지 않는다.
* 남아있는 item들을 하나씩 지워봐서 컴파일이 되면 지우기를 반복한다.

조금 브루트포스스러운 접근이긴 하지만, 같은 결과를 낼 더 나은 방법을 찾지 못해서 내린 결론이다. [chalk](https://github.com/rust-lang/chalk) 같은 걸 써볼까도 생각했지만, 현재 코드에 적용할 방법도 찾지 못했고, 그걸로 struct, enum, impl block 등등을 모두 깔끔하게 지울 수 있을지 불분명했다.

### AST 순회와 visitor 패턴

다시 `dead_code`를 지우는 문제로 돌아와서, 지울 item들이 주어졌을 때 어떻게 하면 해당되는 item들을 다 지울 수 있을까? 이를 위해서는 일단 AST를 재귀적으로 순회해야 한다. 그런데 Rust AST에는 노드 종류가 적어도 수십개는 된다.

다행히 `syn`은 "visitor"를 간단하게 작성할 수 있게 해 주는 [`Visit`](https://docs.rs/syn/latest/syn/visit/trait.Visit.html)과 [`VisitMut`](https://docs.rs/syn/latest/syn/visit_mut/trait.VisitMut.html) trait을 제공한다. [visitor 패턴](https://rust-unofficial.github.io/patterns/patterns/behavioural/visitor.html)은 재귀적인 트리 구조를 순회하는 동작을 추상화한 디자인 패턴이다. `Visit`과 `VisitMut` trait은 모든 메소드의 기본 동작이 단순히 자식 노드들에 대한 순회 함수를 호출하는 것으로 되어 있으므로, 특정 노드에 대한 동작만 원하는 동작으로 갈아끼우면 된다. 이 경우에는 다음과 같이 구현할 수 있다.

* `File` 노드: 최상위 모듈의 item을 지우기 위함
* `ItemMod` 노드: 하위 모듈의 item을 지우기 위함
* `ItemImpl` 노드: `impl` 블록 내의 item을 지우기 위함

실제 코드는 대략 다음과 같이 생겼다.

```rust
struct DeadCodeRemover {
    // store the collection of idents to be removed with spans
    idents: HashSet<...>,
}

impl VisitMut for DeadCodeRemover {
    fn visit_file_mut(&mut self, i: &mut syn::File) {
        // remove items from `i.items` that match `self.idents`
        visit_mut::visit_file_mut(self, i);
        // remove empty submodules
    }
    fn visit_item_mod_mut(&mut self, i: &mut syn::ItemMod) {
        // if i is a module with body...
        if let Some((_, ref mut items)) = i.content {
            // remove items from `items` that match `self.idents`
        }
        visit_mut::visit_item_mod_mut(self, i);
        if let Some((_, ref mut items)) = i.content {
            // remove empty submodules
        }
    }
    fn visit_item_impl_mut(&mut self, i: &mut syn::ItemImpl) {
        // remove associated functions that match `self.idents`
        visit_mut::visit_item_impl_mut(self, i);
    }
}
```

코드: [`struct DeadCodeRemover`와 관련 impl](https://github.com/Bubbler-4/rust-problem-solving/blob/97becc831f2e9cf032f2dbe466ff9fb140cabf35/cargo-oj/src/main.rs#L614-L684)

## 3단계: item 하나씩 지우기

이 부분을 어떻게 처리해야 할지 한참을 생각해야 했다. 트리 순회 한 번에 하나씩 지운 결과 여러 가지를 만드는 것은 힘들 것 같아서, 두 번에 걸쳐서 순회하는 방법을 생각해 보았다.

* 먼저, 지워 볼 item들의 목록을 일종의 좌표 형태로 만들어 추출한다.
* 각각의 좌표에 대해 그 좌표의 item을 지워 본다.

각 item의 좌표는 다음과 같이 정의한다.

* 트리의 루트(즉, `File`)는 좌표가 `[]`(길이 0의 배열)이다.
* 루트의 자식 노드에 해당하는 item들은 순서대로 `[0]`, `[1]`, ...의 좌표를 갖는다. 여기에는 하위 모듈도 포함된다.
* 좌표가 `X`인 item의 자식 노드인 item들은 순서대로 `[X, 0]`, `[X, 1]`, ...의 좌표를 갖는다.

하지만 이 방법에도 문제가 있었다. 자식 item의 목록은 `Vec`에 저장되어 있기 때문에, 그 item들 중 하나를 지우면 뒷번호의 item들의 좌표가 바뀐다. 그래서, 각각의 item의 좌표 대신 span(몇 번 바이트부터 몇 번 바이트까지)을 저장하고, 소스에서 어떤 item을 지울 때는 그 영역을 빈 칸으로 덮어쓰는 방식을 쓰기로 했다.

여담: 각각의 AST 노드에서 [`Span`](https://docs.rs/proc-macro2/latest/proc_macro2/struct.Span.html)을 얻는 것까지는 간단했는데, 이 `Span`에는 바이트 위치를 추출하는 메소드가 없다. 다른 방법을 시험하던 와중에 이 `Span`을 디버그 출력을 하면 바이트 위치가 출력된다는 것을 우연히 알게 되었고, 이를 이용한 [`span_to_bytes`](https://github.com/Bubbler-4/rust-problem-solving/blob/97becc831f2e9cf032f2dbe466ff9fb140cabf35/cargo-oj/src/main.rs#L395-L400) 함수를 짜서 사용했다. 거기에다, `parse_file`을 여러 번 호출하면 AST 노드의 바이트 오프셋이 누적되는 것처럼 보이는 현상이 있어서, 각각의 span 위치에서 현재 파일의 시작점의 위치를 빼 주어야 했다.

코드: [`fn item_positions2`](https://github.com/Bubbler-4/rust-problem-solving/blob/97becc831f2e9cf032f2dbe466ff9fb140cabf35/cargo-oj/src/main.rs#L406-L448)

이 함수는 특정한 순서로 DFS를 돌면서 나중에 나오는 item 먼저, 자식보다 부모 먼저 순서로 span들을 저장한다. 순서를 이렇게 한 이유는, 가능하면 모듈 전체를 미리 지우면 그 자식들은 볼 필요가 없다는 점, 그리고 보통 라이브러리 코드는 아래쪽 코드가 위쪽 코드에 의존하기 때문에 의존성이 있는 item들도 한번에 최대한 많이 지워질 수 있도록 한 것이다. 또한 루트에 있는 `main` 함수는 무시한다.

이 결과에 `cargo check`을 돌리는 것은 기존 코드를 거의 그대로 쓰면 되어서 어렵지 않았다. 이번에는 출력을 읽지 않고 exit code만 확인한다.

이제, item의 span의 목록이 주어졌을 때 실제로 item을 지워보는 부분을 구현해야 한다. 실질적으로 의존성을 알 수 없기 때문에, 다음과 같은 알고리즘을 구현했다.

```
item의 목록을 Queue Q에 저장
Q2는 빈 Queue
while Q is not empty:
    Q에서 item I를 꺼낸다
    I가 이미 지워진 노드의 자식이면 continue
    I를 지웠을 때 컴파일이 되면
        소스에서 I를 지우고 Q2의 내용물을 Q로 옮긴다
    아니면 I를 Q2에 넣는다
```

코드: [`fn try_remove_one_item2`](https://github.com/Bubbler-4/rust-problem-solving/blob/97becc831f2e9cf032f2dbe466ff9fb140cabf35/cargo-oj/src/main.rs#L142-L165)

### cargo 대신 rustc

[main 함수](https://github.com/Bubbler-4/rust-problem-solving/blob/97becc831f2e9cf032f2dbe466ff9fb140cabf35/cargo-oj/src/main.rs#L47-L71)까지 완성하고 나서, 나는 이 코드가 문제가 없을 것이라고 확신했다. [cargo 문서](https://doc.rust-lang.org/cargo/reference/external-tools.html#custom-subcommands) 와 [SO 포스트](https://stackoverflow.com/a/70293462/4595904)의 내용에 따라서 다음과 같이 실행해 보았다. 이러면 내가 원하는 `main.rs`가 나오겠지?

```bash
# at workspace/cargo-oj/
cargo install --path .
cd ../ps
cargo oj
```

아니었다.

분명 코드대로라면 결과물이 컴파일 에러가 날 수 없었다. 그럼에도 불구하고, 최종 결과로 나온 `main.rs`는 이런저런 에러를 뱉고 있었다. 심지어 여러 번 돌리면 매번 다른 결과가 나왔다. 어떨 때는 `struct I`가 없어졌다가, 어떨 때는 `struct I`의 중요한 메소드가 없어졌다가, 어떨 때는 심지어 `solve` 함수가 없어지기도 했다.

상상의 나래를 펼쳐가면서 가능한 에러의 원인을 생각해 봤지만, `tmp.rs`와 IDE의 상호작용에 뭔가 문제가 있는 게 아닌가 하는 생각밖에 들지 않았다. IDE가 감시하고 있는 폴더의 파일을 그렇게 초고속으로 덮어쓰기를 반복했으니 그럴만 하다 싶었다. 만약 그렇다면 IDE가 보고 있는 폴더 밖에서 같은 작업을 해야 한다. 하지만 cargo 프로젝트가 그 밖에 있을 리 없으니, 대신 rustc를 직접 실행해야 할 것 같았다. 그렇게 하는 김에, 아예 소스를 rustc의 stdin을 통해서 주는 방법을 쓰기로 했다. ([code.golf가 rustc를 호출하는 법](https://github.com/code-golf/code-golf/blob/master/langs/rust/rust)을 본 적이 있어서 이게 가능하다는 것은 이미 알고 있었다. code.golf는 소스 코드를 파일에서 읽어서 Quine 문제를 푸는 것을 방지하기 위해 이런 방식을 쓴다.)

이제 `cargo check`을 `rustc`로 재현해야 한다. [rust-lang/cargo](https://github.com/rust-lang/cargo) 깃허브 레포를 뒤져봤지만 별 소득이 없었다. `cargo`에 `--build-plan`을 줘 봐도 딱히 의미있는 결과는 보이지 않았다. 다시 검색을 켰다. 이번에도 [SO 포스트](https://stackoverflow.com/q/51485765/4595904)에서 답을 찾을 수 있었다. SO 답변이 알려주는 방법은 다음과 같다.

* `rustc --emit=mir -o /dev/null`
* `rustc -C extra-filename=-tmp -C linker=true`
* `rustc --out-dir=/tmp/tmpdir`

첫 번째 커맨드는 `-o /dev/null` 부분이 어째서인지 동작하지 않았다. `-o`를 빼고 돌리면 `<filename>.mir`라는 파일이 현재 폴더에 생겼다. 이것저것 실험해 보다가, 1번과 3번을 섞은 다음의 커맨드를 쓰기로 했다.

```bash
# cargo check, checking success/failure only
rustc --emit=mir --edition=2021 --out-dir=/tmp/ramdisk -
# cargo check --message-format=json
rustc --emit=mir --edition=2021 --out-dir=/tmp/ramdisk --error-format=json -
```

(실제로 `/tmp/ramdisk`에 ramdisk를 mount해서 돌렸다. 리눅스에서 ramdisk를 만드는 것은 의외로 쉽고, 검색하면 튜토리얼이 많이 나오니 아무거나 잡아서 시키는 대로 하면 된다. 하지만 딱히 실행 시간을 줄이는 데에 도움이 되진 않은 것 같다.)

이제 프로그램을 다시 돌리니 의도대로 만들어진 `main.rs`가 나왔다. 하지만 이게 나오는 데 5초가 걸렸다. 좀 느린 것 같아서 최적화를 해 보기로 했다.

## 4단계: 최적화

여전히 이 과정을 `rustc` 호출 없이 구현하는 것은 말이 안 되는 것 같았다. 그렇다면 남은 것은 `rustc` 호출을 병렬화하는 것과 `rustc` 호출 횟수 자체를 줄이는 것밖에 없었다.

### `rustc` 호출 병렬화

먼저 [`rayon`](https://docs.rs/rayon/latest/rayon/index.html)을 시도해 보았다. 사용 경험이 조금이나마 있었고, `par_iter`가 있어서 적용해보기 쉬울 것이라고 생각했다. 하지만 그걸 쓰려면 로직을 조금 수정해야 했고 ([코드](https://github.com/Bubbler-4/rust-problem-solving/blob/97becc831f2e9cf032f2dbe466ff9fb140cabf35/cargo-oj/src/main.rs#L190-L208)), 결과적으로 실행 시간은 오히려 길어졌다. 찾아보니 [경고문](https://docs.rs/rayon/latest/rayon/fn.join.html#warning-about-blocking-io)이 붙어 있다.

> If you do perform I/O, and that I/O should block (e.g., waiting for a network request), the overall performance may be poor.

> 입출력을 수행해야 하고 그 입출력이 blocking이면, 전반적인 성능은 좋지 않을 수 있다.

아무래도 [`tokio`](https://docs.rs/tokio/latest/tokio/index.html)를 써야 할 것 같다. tokio는 멀티스레드 비동기(async) 런타임과 여러 비동기 입출력 함수를 제공하는 라이브러리이다. 이거라면 자식 프로세스를 병렬화하는 데에도 도움이 될 것 같았다. 실제로 [자식 프로세스를 async로 실행하는 기능](https://docs.rs/tokio/latest/tokio/process/index.html)도 제공한다.

왜인지 `rustc` 실행이 끝나는 순서대로 처리하고 싶어졌다. 이를 위해 처음 짠 코드는 [mpsc 채널](https://doc.rust-lang.org/std/sync/mpsc/index.html)을 동반한 괴랄한 코드가 되었고, 실행해봤더니 어디선가 데드락이 걸렸는지 무한루프인지 모르겠지만 어쨌든 돌지 않았다.

다 지우고, 다시 검색창을 켰다. [당장 필요했던 SO 포스트](https://stackoverflow.com/a/72652221/4595904)가 튀어나왔다. [`futures`](https://docs.rs/futures/latest/futures/index.html) crate에 여러 가지 async 작업 관리용 유틸리티가 있다고 한다. 그 중 하나가 [`FuturesUnordered`](https://docs.rs/futures/latest/futures/stream/futures_unordered/struct.FuturesUnordered.html)로, future의 unordered collection 역할을 하며 결과를 하나 await하면 가장 먼저 끝난 결과가 나온다. 이걸 써서 [`try_remove_one_item`](https://github.com/Bubbler-4/rust-problem-solving/blob/97becc831f2e9cf032f2dbe466ff9fb140cabf35/cargo-oj/src/main.rs#L210-L252)를 재작성했다. 코드가 꽤 길어졌지만 실행 시간이 2초 정도로 확실히 빨라졌다.

하지만 불필요한 item 중 일부가 지워지지 않고 남아있었다. 다시 [`while` 루프로 감싸서 지울 것이 없도록 반복해야 했다](https://github.com/Bubbler-4/rust-problem-solving/blob/97becc831f2e9cf032f2dbe466ff9fb140cabf35/cargo-oj/src/main.rs#L279-L317). 실행 시간이 약 3초로 다시 길어졌다.

여기까지 짜놓고 다시 생각해보니, 그냥 원래 알고리즘 순서대로 실행하되 future들을 작은 큐에 넣어서 같이 돌 수 있게 하는 게 오히려 빠르겠다 싶었다. 그래서 [코드를 한 번 더 다시 짰다](https://github.com/Bubbler-4/rust-problem-solving/blob/97becc831f2e9cf032f2dbe466ff9fb140cabf35/cargo-oj/src/main.rs#L319-L355).

### `rustc` 실행 횟수 줄이기

이쯤에서 또다시 새로운 아이디어가 떠올랐다. `rustc` 호출로 하는 일을 줄이고 `dead_code` 제거 코드를 한 번 더 돌리면 된다. 지울 item 후보들을 리턴해주는 `item_positions` 함수에서 `mod`들, 그리고 `impl` 내부의 item들을 제외했다. 그랬더니 실행 시간이 최종적으로 1.5s로 줄었다.

코드를 정리하고 코멘트를 추가한 최종본은 [여기](https://github.com/Bubbler-4/rust-problem-solving/blob/90bb4bf3a7b4cd33cd426bf51a743e549233fb3d/cargo-oj/src/main.rs)에 있다.

## 앞으로 할 일

* 파일 읽기
    * `mod.rs` 형태의 모듈을 허용하기
    * 하위 모듈의 파일에 붙어있는 attribute들도 가져와서 `mod` 노드에 추가하기
    * doc-comment라는 특수한 종류의 코멘트는 AST에 남아있다는 거 같은데 아직 확인해보지 못했다. 실제로 남아있는지, 포매팅은 잘 되는지 확인하기
* dead code 지우기
    * 매크로 선언과 호출은 어떻게 할지 고민해보기
    * `unused_imports` 워닝도 지우기
    * impl 내부의 상수 선언 지우기, 빈 impl block 지우기 (이러면 struct와 enum 지우는 것도 안전하지 않을까?)
* 브루트포스 item 지우기
    * [current-thread scheduler](https://docs.rs/tokio/latest/tokio/runtime/index.html#current-thread-scheduler)로 바꿔보고 성능 확인하기
* crate 배포
    * `tmp` 폴더 위치 설정 가능하게 하기. [`directories`](https://crates.io/crates/directories)를 쓰면 될 것 같다. ramdisk가 딱히 효과가 없으면 [`tempfile`](https://docs.rs/tempfile/3.4.0/tempfile/)의 tempdir를 써도 되지 않을까?