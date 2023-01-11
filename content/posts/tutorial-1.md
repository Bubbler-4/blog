---
title: "Rust로 새싹문제를 정복해보자 - 1"
date: 2022-09-08T22:54:21+09:00
draft: false
tags: ["Rust", "PS", "Tutorial"]
---

[solved.ac](https://solved.ac)에서는 프로그래밍 언어 입문에 좋은 [새싹 문제 리스트](https://solved.ac/problems/sprout)를 제공합니다.
이 시리즈에서는 Rust를 가지고 이 문제들을 하나씩 풀어 보겠습니다.

참고: 이 시리즈를 포함한 모든 Rust 관련 포스트는 2021 edition을 기준으로 합니다. BOJ 제출 언어는 `Rust 2021`입니다.

## 시작하기 전에

진심으로 Rust PS에 도전할 예정이라면 [The Rust Book 1장](https://doc.rust-lang.org/book/ch01-00-getting-started.html)을 따라가면서
Rust를 설치하고 PS용 project를 하나 생성해서 사용하는 것이 좋습니다.
링크된 The Rust Book은 Rust의 공식 입문서이니, 이 시리즈를 진행하면서 같이 참고하시면 도움이 될 수 있습니다.
([비공식 한글 번역](https://rinthel.github.io/rust-lang-book-ko/ch01-00-getting-started.html)도 있는데, 업데이트가 되지 않은 부분이 일부 있을 수 있습니다.)

에디터는 개인적으로 VS Code + rust-analyzer 플러그인 조합을 추천합니다.

일단 Rust의 맛을 조금 보고 결정하려면 [Attempt This Online](https://ato.pxeger.com/run?1=m72kqLS4ZEe0kq5uakpmSWZ-nq2RgZGhko6Ckq6_UuyCpaUlaboWa9PyFHITM_M0NBWquWohYlCpBVAaAA)에서 표준 입력과 함께 프로그램을 실행해 볼 수 있습니다.

## 출력하기

### 2557. Hello World!

[문제 링크](https://boj.kr/2557)

클래식한 입문 문제부터 시작해 봅시다.

먼저, 실행을 위한 코드에는 `main` 함수가 있어야 합니다. `main` 함수를 정의하는 문법은 다음과 같습니다.

```rust
fn main() {
    // 본문
}
```

출력에는 `print!()` 또는 `println!()` 매크로를 사용합니다.
"매크로"라는 단어만 보고 나가떨어지는 분들이 있을 수 있는데, 겁먹을 필요는 전혀 없습니다.
C의 `printf` 내지 Python의 `str.format`과 비슷한 것이라고 생각해 주시면 됩니다.
Rust 함수는 가변 길이의 인자를 받을 수 없기 때문에 함수 대신 매크로를 제공하고 있는 것 뿐입니다.

`Hello World!`를 출력하려면 다음과 같이 사용합니다.

```rust
fn main() {
    println!("Hello World!");
}
```

`println`은 출력 끝에 줄바꿈이 추가되고, `print`는 추가되지 않습니다.
BOJ는 출력 끝의 빈 칸이나 줄바꿈은 무시하고 채점하므로, `print`와 `println` 둘 중 어느 것을 써도 정답 처리됩니다.

### 25083. 새싹

[문제 링크](https://boj.kr/25083)

조금(?) 더 복잡한 문자열을 출력하는 문제입니다.

```
         ,r'"7
r`-_   ,'  ,/
 \. ". L_r'
   `~\/
      |
      |
```

다른 언어를 써 보셨다면 아시겠지만, 보통 문자열 내에 일부 기호를 넣으려면 escape sequence를 써야 합니다.
줄바꿈은 `\n`, `"`은 `\"`, `\`은 `\\` 처럼 말이죠. 러스트도 마찬가지입니다. (다만 `'`은 escape할 필요가 없습니다.)

하지만 러스트는 그 외에도 강력한 raw string 문법을 제공합니다.
Python의 그것과 비슷하게 `r"..."`처럼 문자열 앞에 `r`을 붙이면 raw string이 되어 `"` 글자를 제외한 모든 글자를 그대로 문자열 내에 쓸 수 있습니다.
`"`를 써야 한다면 `r#"..."#`처럼 따옴표 앞뒤에 `#`를 하나씩 추가해주면 정확히 `"#` 문자열이 나올 때까지의 모든 글자를 문자열로 인식합니다.
그걸로도 부족하면 `r##"..."##`처럼 `#`를 필요한 만큼 추가하면 됩니다.

이를 이용해서 새싹 문제를 해결하는 코드는 다음과 같습니다. 이 문제는 `r"..."`로는 모자라고 `r#"..."#`를 써야 합니다.

```rust
fn main() {
    print!(r#"         ,r'"7
r`-_   ,'  ,/
 \. ". L_r'
   `~\/
      |
      |"#);
}
```

문자열의 첫 줄이 뒤틀리는 것은 어쩔 수 없지만, 어쨌든 문제에서 주어진 문자열을 고치지 않고 그대로 복붙해서 풀 수 있습니다.

### 연습문제

나머지 "출력" 문제들을 풀어 보세요.

* [10699. 오늘 날짜](https://boj.kr/10699)
* [7287. 등록](https://boj.kr/7287)
* [10171. 고양이](https://boj.kr/10171)
* [10172. 개](https://boj.kr/10172)

## 입력 받기

사실상 Rust PS의 입문 장벽이 시작되는 지점입니다.
C의 `scanf`, C++의 `cin`, Python의 `input`에 해당하는 기능이 러스트에는 없다보니, 뭐라도 입력을 받으려면 조금 빙 돌아가야 합니다.

필요한 기초 기능과 관련 문법에 대한 설명은 Rust Book의 2장([한글](https://rinthel.github.io/rust-lang-book-ko/ch02-00-guessing-game-tutorial.html), [영어](https://doc.rust-lang.org/book/ch02-00-guessing-game-tutorial.html))의 앞부분을 참고하면 도움이 될 것 같습니다.

### 11718. 그대로 출력하기

[문제 링크](https://boj.kr/11718)

문제 순서를 바꿔서, 입력을 받아서 아무것도 하지 않아도 되는 문제를 먼저 가져와 봤습니다.

```rust
use std::io::{stdin, Read};
fn main() {
    let mut buffer = String::new();
    let mut stdin = stdin();
    stdin.read_to_string(&mut buffer).unwrap();
    print!("{}", buffer);
}
```

Rust Book의 예시 코드와 조금 다르게 생겼는데, 달라진 부분만 한 줄씩 설명해 보겠습니다.

```rust
use std::io::{stdin, Read};
```

`std::io` 모듈의 `stdin`과 `Read`를 사용하겠다는 선언입니다.
[`stdin()`](https://doc.rust-lang.org/std/io/fn.stdin.html) 함수는 [`Stdin`](https://doc.rust-lang.org/std/io/struct.Stdin.html) 오브젝트를 반환하며,
이 오브젝트는 [`Read`](https://doc.rust-lang.org/std/io/trait.Read.html) trait을 구현합니다.
아래에서 쓰게 될 `read_to_string`이 `Read`의 메소드 중 하나이기 때문에 `Read`를 use하지 않으면 컴파일 에러가 납니다.
(Rust Book에서 사용한 `read_line`은 `Stdin`의 자체 메소드입니다.)

```rust
    let mut stdin = stdin();
```

`stdin()`이 주는 `Stdin` 오브젝트를 `stdin`이라는 변수에 저장했습니다.
이렇게 선언하면 우변의 `stdin`은 라이브러리 함수이고, 이 줄의 아래부터 `stdin`은 지금 선언한 변수를 가리키게 됩니다.

지금 코드의 경우는 Rust Book에서처럼 `stdin()`의 결과에 바로 `read_to_string` 메소드를 호출해도 되지만,
나중에 빠른 입출력을 구현할 때 `stdin`에 추가적인 처리를 할 예정입니다.

```rust
    stdin.read_to_string(&mut buffer).unwrap();
```

`read_line`이 stdin에서 한 줄을 읽는 함수라면, `read_to_string`은 stdin의 내용을 끝까지 읽어 `buffer`에 저장합니다.
`read_line`과 비슷하게 IO 오류가 발생할 수 있기 때문에 `Result`가 리턴되는데,
실제로는 오류가 나지 않을 것이라는 것을 컴파일러에게 알려주기 위해 `.unwrap()`을 추가했습니다.
이 부분이 없으면 `unused_must_use`라는 경고가 발생합니다.

이 줄이 지나면 `buffer`에는 입력된 문자열 전체가 들어 있습니다.

```rust
    print!("{}", buffer);
```

이를 그대로 출력합니다. `print`나 `println`의 첫 번째 인자는 포맷 문자열로, 항상 문자열 **상수**여야 합니다.
따라서 `print!(buffer)`와 같은 코드는 컴파일이 되지 않고, `buffer`가 들어갈 자리를 나타내는 포맷 문자열 `"{}"`을 쓰고 나서
포맷 인자로 `buffer`를 넘겨줘야 합니다.

### Rust 1.65+ 에서의 입력 방법

기존에는 `String` 버퍼를 먼저 만들고 그 버퍼를 채워야 해서 두 줄의 코드가 필요했는데,
Rust 버전 1.65부터는 조금 더 간편하게 입력을 받을 수 있습니다.
`Read` trait의 메소드 `read_to_string()`과 다르게, `std::io::read_to_string` 함수는 `Read`인 오브젝트를 받아서
`String` 오브젝트를 새로 만들어 반환해 줍니다.

```rust
use std::io::{stdin, read_to_string};
fn main() {
    let input = read_to_string(stdin()).unwrap();
    print!("{}", input);
}
```

2023년 1월 기준 BOJ와 Codeforces에서 사용 가능합니다.

## 입력 파싱하기, 정수 타입, 사칙연산

이제 입력을 가지고 뭔가 계산하려면 문자열을 수로 변환하는 과정을 거쳐야 합니다.
Python으로 치면 `n, m = map(int, input().split())`에서 `input()`을 제외한 부분에 해당합니다.

### 정수 타입과 연산자

러스트도 C나 C++처럼 다양한 크기의 정수 타입을 기본 타입으로 제공합니다. 사용 가능한 모든 정수 타입의 목록은 다음과 같습니다.

| 부호가 있는가? | 8비트 | 16비트 | 32비트 | 64비트 | 128비트 | register 크기 |
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| Yes | `i8` | `i16` | `i32` | `i64` | `i128` | `isize` |
| No  | `u8` | `u16` | `u32` | `u64` | `u128` | `usize` |

정수가 아닌 기본 타입은 실수 타입 `f32`, `f64` (각각 `float`, `double`에 대응), 글자 타입 `char`, 참거짓을 나타내는 `bool`이 있습니다.

C나 C++의 경우 `int`나 `long` 같은 타입의 크기는 환경에 영향을 받는데, 러스트의 정수 타입은 타입 이름에 크기가 모두 쓰여 있어 더 명확합니다.
`isize`와 `usize`는 요즘 대부분의 컴퓨터가 64비트 프로세서를 쓰기 때문에 64비트라고 가정해도 무방합니다.

정수형 상수는 `1234`처럼 그냥 쓰면 컴파일러가 타입 추론을 시도하고, 아무 정수형이나 올 수 있는 상황이면 `i32`를 사용합니다.
상수에 타입을 주려면 `1234u32`처럼 뒤에 타입을 붙이면 됩니다.
2진수나 16진수는 `0b0011`, `0xabcdu32`처럼 앞에 `0b`나 `0x`를 붙여서 쓸 수 있고,
`1_000_000` 또는 `0b_0001_0111_u32`처럼 긴 상수를 읽기 쉽게 `_`를 구분자로 쓸 수 있습니다.
([Rust By Example](https://doc.rust-lang.org/rust-by-example/primitives/literals.html) 참조)

러스트의 연산자에는 사칙연산 `+ - * / %`, 비교 `< = > <= >= !=`, 비트 연산 `& | ^ << >>`, 논리 연산 `&& || !`, 연산 후 대입 `+=` 등이 있으며,
이들은 모두 C나 C++과 동일하게 동작합니다. 그러나 `++`, `--`는 존재하지 않고, 비트 반전은 `~`가 아닌 `!`를 사용합니다.

러스트는 안전성을 추구하는 언어이기 때문에, 서로 다른 두 타입의 정수를 가지고 연산하는 것이 금지되어 있습니다.
예를 들어 `a: i32`와 `b: i64`를 서로 더하려면 `a as i64 + b`처럼 명시적 형변환을 해 주어야 합니다.
(예외적으로 bitshift 연산은 오른쪽에 아무 정수 타입이 오는 것이 허용됩니다.)

### 1000. A+B

[문제 링크](https://boj.kr/1000)

이제 본격적으로 파싱 후 연산을 해 봅시다.

```rust
use std::io::{stdin, Read};
fn main() {
    let mut buffer = String::new();
    let mut stdin = stdin();
    stdin.read_to_string(&mut buffer).unwrap();
    let mut words = buffer.split_ascii_whitespace();
    let a = words.next().unwrap().parse::<usize>().unwrap();
    let b = words.next().unwrap().parse::<usize>().unwrap();
    print!("{}", a + b);
}
```

`main`의 앞 3줄까지는 이전 코드와 똑같습니다. 입력을 받았으니 이제 빈 칸을 기준으로 문자열을 나누어야 합니다.

```rust
    let mut words = buffer.split_ascii_whitespace();
```

이를 실행해 주는 메소드로는 `.split_ascii_whitespace()`가 있는데, 정확히는 문자열 조각을 하나씩 내어주는 반복자([`Iterator`](https://doc.rust-lang.org/std/iter/trait.Iterator.html))를 만들어 줍니다. 일단 여기서는 "`.next()`를 호출해서 물건을 하나씩 여러 번 꺼낼 수 있는 오브젝트"라고만 생각해도 됩니다.
`words.next()`를 한 번 호출할 때마다 `words`의 내부 상태가 바뀌기 때문에 `words`를 `mut`로 선언합니다.

```rust
    let a = words.next().unwrap().parse::<usize>().unwrap();
    let b = words.next().unwrap().parse::<usize>().unwrap();
```

여기서 문자열 조각을 하나 꺼내기 위해 `words.next()`를 호출합니다.
반복자에서 물건 하나를 꺼내는 연산을 했을 때 꺼낼 것이 있을 수도 있고 없을 수도 있어서 `Option`이 반환되는데, 여기서 문자열을 꺼내기 위해 `.unwrap()`을 사용합니다.
그 다음, 이 문자열을 정수로 변환하기 위해 `.parse()`를 사용하는데, 이 함수는 다양한 결과 타입을 줄 수 있기 때문에 어떤 타입을 원하는지 명시적으로 표현해야 합니다. 이 표현을 위한 문법이 `::<usize>`입니다. 이 변환 역시 실패할 수 있기 때문에 `Result`가 반환되고, 그 안에 있는 `usize`를 꺼내기 위해 `.unwrap()`을 다시 한 번 사용합니다.

같은 과정을 두 번 사용하여 입력으로 주어지는 두 수 `a`와 `b`를 각각 `usize` 타입으로 얻었습니다.

```rust
    print!("{}", a + b);
```

마지막으로, 두 수에 대해서 원하는 연산을 수행하여 결과를 출력합니다.

입력값 하나마다 저렇게 긴 줄을 쳐야 하는 것은 좋지 않기 때문에, 다음 포스트에서 함수 구현을 다루면서 이 부분도 같이 해결할 예정입니다.

### 연습문제

나머지 "입력과 계산" 문제들을 풀어 보세요.

* [1001. A-B](https://boj.kr/1001)
* [10998. A×B](https://boj.kr/10998)
* [10869. 사칙연산](https://boj.kr/10869)
* [1008. A/B](https://boj.kr/1008)
* [11382. 꼬마 정민](https://boj.kr/11382)

다음 포스트에서는 함수, 조건문, 반복문을 다뤄보도록 하겠습니다.