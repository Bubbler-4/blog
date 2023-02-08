---
title: "Rust로 새싹문제를 정복해보자 - 2"
date: 2023-01-11T17:07:58+09:00
draft: false
tags: ["Rust", "PS", "Tutorial"]
description: "지난 포스트에서는 기초적인 입출력과 사칙연산을 배워 보았습니다. 이 포스트에서는 함수를 작성하는 법을 다룹니다."
---

[지난 포스트](../tutorial-1)에서는 기초적인 입출력과 사칙연산을 배워 보았습니다. 이 포스트에서는 함수를 작성하는 법을 다룹니다.
원래는 조건문과 반복문까지 진행하려고 했는데, 조건문 문제 목록을 보니 내용이 꽤 방대해질 것 같아서 별도의 포스트를 쓰기로 했습니다.

## 함수

Rust에서 함수를 선언하는 문법은 다음과 같습니다.

```rust
fn function_name(param1: type1, param2: type2, ...) -> return_type {
    ...
}
```

딱히 함수가 리턴할 값이 없을 경우 `-> return_type` 부분은 생략 가능하며, `main` 함수가 그 예시입니다.

C/C++와 달리 Rust의 함수들은 그 함수를 사용하는 곳과 관계없이 배치할 수 있습니다.
(C/C++에서 나중에 정의된 함수를 앞에서 사용하려면 전방 선언을 해야 합니다.)

### 15964. 이상한 기호

[문제 링크](https://boj.kr/15964)

함수 구현의 간단한 예시로서 이 문제에서 요구하는 함수 `A@B = (A+B) * (A-B)`를 만들어 봅시다.

문제 조건에서 `A`와 `B`가 10만 이하이면 `A@B`의 값을 저장하는 데에 64비트 변수가 필요하고, 결과값이 음수일 수 있으므로,
파라미터인 `A`와 `B`, 그리고 리턴 타입을 모두 `i64`로 지정합니다. 함수의 내용도 어렵지 않으니 주어진 대로 구현해 주면 다음과 같습니다.

```rust
fn a_at_b(a: i64, b: i64) -> i64 {
    return (a + b) * (a - b);
}
```

C/C++/Python에서처럼 `return`을 사용하면 위와 같은 코드가 됩니다. 하지만 Rust에서는 `return`을 쓰지 않는 다음의 문법을 선호합니다.

```rust
fn a_at_b(a: i64, b: i64) -> i64 {
    (a + b) * (a - b)
}
```

마지막에 세미콜론(`;`)이 없다는 점을 유의하세요. 함수의 마지막에 세미콜론이 없이 수식이 오면 그 식의 결과가 함수의 리턴값이 됩니다.

이제 이 함수를 이용해서 문제를 푸는 코드를 완성해보면 다음과 같습니다.

```rust
use std::io::{stdin, Read};

fn main() {
    let mut buffer = String::new();
    let mut stdin = stdin();
    stdin.read_to_string(&mut buffer).unwrap();
    let mut words = buffer.split_ascii_whitespace();
    let a = words.next().unwrap().parse::<i64>().unwrap();
    let b = words.next().unwrap().parse::<i64>().unwrap();
    let ans = a_at_b(a, b);
    print!("{}", ans);
}

fn a_at_b(a: i64, b: i64) -> i64 {
    (a + b) * (a - b)
}
```

이제 다른 문제를 풀기 전에, 입력에서 수 하나를 파싱하는 함수를 만들어 볼까요? 라고 하고 싶었으나...

{{< collapse summary="어질어질한 코드 주의" >}}

```rust
fn get1<'a, Words, T>(words: &mut Words) -> T
where
    Words: Iterator<Item = &'a str>,
    T: std::str::FromStr,
{
    words.next().unwrap().parse().ok().unwrap()
}

fn get2<T: std::str::FromStr>(words: &mut dyn Iterator<Item = &str>) -> T {
    words.next().unwrap().parse().ok().unwrap()
}

fn get3<'a, T: std::str::FromStr>(words: &mut impl Iterator<Item = &'a str>) -> T {
    words.next().unwrap().parse().ok().unwrap()
}

fn get4<T: std::str::FromStr>(words: &mut std::str::SplitAsciiWhitespace) -> T {
    words.next().unwrap().parse().ok().unwrap()
}
```

위 코드들에 대해 더 공부하고 싶으시다면 Rust book에서
[borrowing의 개념](https://doc.rust-lang.org/book/ch04-02-references-and-borrowing.html)과
[제네릭 함수](https://doc.rust-lang.org/book/ch10-01-syntax.html),
[trait](https://doc.rust-lang.org/book/ch10-02-traits.html),
[lifetime](https://doc.rust-lang.org/book/ch10-03-lifetime-syntax.html)의 표기와 활용법에 대한 이해를 하고 돌아와서 다시 한 번 읽어보시면
도움이 될지도... 모르겠네요. 더 자세한 설명은 입출력 템플릿 관련 포스트에서 하게 될 것 같습니다.

{{< /collapse >}}

### 연습문제

다른 "함수" 문제인 [2475. 검증수](https://boj.kr/2475)에서, 5개의 정수를 파라미터로 받아서 그 5자리 수의 검증수를 리턴하는 함수를 만들고,
이 함수를 이용해 문제를 풀어 보세요.

다음 포스트에서는 조건문(`if`와 `match`)을 다뤄 보겠습니다.
