---
title: "Cargo-OJ: What it takes to be a PSer and a dev at once"
date: 2023-03-03T09:26:04+09:00
draft: false
tags: ["PS", "Dev", "Rust", "Cargo-OJ"]
---

*A journey to pursue best practices while doing PS*

<!--more-->

I like solving programming problems (often called *problem solving*, or PS). I also classify myself as a semi-professional developer, so I like to organize my code. And I *love* Rust the programming language. The result is [a collection of handwritten algorithms and data structures](https://github.com/Bubbler-4/rust-problem-solving/tree/b2d784cc06a48187afce2f22e0989377fd3b2966/competitive/src/competelib), structured as many modules in a lib crate.

So far, I was using them by copy-pasting into my main solution file as needed, since all online judge sites (OJs) only accept single file submissions. One day I wondered: Can I use these algorithms simply by importing them, and get my entire crate compiled into a single, readable Rust source?

I tried DDGing several search terms but found nothing even close to what I imagined. [basm-rs](https://github.com/kiwiyou/basm-rs) exists, but it didn't quite suit my taste because:

* it emits an encoding of raw machine code (I want my submitted solutions to be readable), and
* it allows using a nightly compiler and drawing in 3rd party crates (I consider it cheating, as OJs normally use a stable compiler without 3rd party crates).

So I decided to write one myself.

## Requirements

Write a cargo command so that:

* I organize various PS-related functions under Rust module structure,
* I write my solution to a PS problem in `lib.rs`,
* and the command packs it into a single self-contained source code (likely `main.rs`),
* *reasonably formatted*, and
* *all unnecessary code removed*.

The last line is a must for me, since the entire library is like 100,000 bytes in scale, and spamming all of them in every single submission of mine is a no-go.

I decided to attack this in two steps:

* collect the module tree into single file, and then
* remove all items that give `dead_code` warnings on compile (assume the original codebase compiles).

## Step 1: Collecting module tree into a single file

I figured I'd need to properly parse a Rust source. Even if I "cheated" here with string substitution, I'd need it anyway when removing items later.

### How to parse Rust source code

Rust's grammar is pretty complicated, and I don't even know all the syntactic elements supported by Rust. Fortunately there's a crate that does the job: [`syn`](https://docs.rs/syn/latest/syn/index.html).

If you have dependencies in your Rust crate, you'll most likely see `syn` as a transitive dependency. It is mainly used to write "proc macros", combined with crates like `quote` and `proc-macro2`. But `syn` itself is more general than that, as it lets you also construct the Rust AST from Rust source and manipulate it in various ways.

The starting point is [`syn::parse_file`](https://docs.rs/syn/latest/syn/fn.parse_file.html), which takes a string and returns a [`syn::File`](https://docs.rs/syn/latest/syn/struct.File.html) if successful. A `File` contains a `Vec` of [`syn::Item`](https://docs.rs/syn/latest/syn/enum.Item.html)s, and an `Item` is an enum representing any "item" in Rust. An item could be a function, a struct/enum/trait definition, an `impl` block, an inner `mod`, etc. A `mod` is represented with [`syn::ItemMod`](https://docs.rs/syn/latest/syn/struct.ItemMod.html):

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

The `ident` field contains the name of the inner module, and I need to fill in the `content` field if it is `None`, by reading the corresponding file.

### Rust's module structure

Now we can identify `mod m;` declarations in the root file `src/lib.rs`. Then where is the corresponding file? Good news: [Rust reference](https://doc.rust-lang.org/reference/items/modules.html#module-source-filenames) has an answer. Bad news: it actually has multiple answers.

The most common (and recommended) structure looks like this:

```rust
// lib.rs
mod m1;

// m1.rs
mod m2;

// m1/m2.rs
struct MyStruct();
```

But there also exists `mod.rs` way:

```rust
// lib.rs
mod m1;

// m1/mod.rs <--
mod m2;

// m1/m2.rs
struct MyStruct();
```

and even a way using custom path attribute:

```rust
// lib.rs
mod m1;

// m1.rs
#[path = "m2.rs"]
mod m2;

// m2.rs <--
struct MyStruct();
```

For now, I decided to only accept the first one for simplicity.

Implementation: [`fn load_recursive`](https://github.com/Bubbler-4/rust-problem-solving/blob/90bb4bf3a7b4cd33cd426bf51a743e549233fb3d/cargo-oj/src/main.rs#L316-L367) (It also removes `#![allow(dead_code)]` from the crate root if it exists. Without it, the IDE complains about all the unused library functions I don't use.)

## Step 2: Removing dead code

### Getting `dead_code` warnings

Now we have one AST representing the entire module tree. How do we check for dead code on it?

Writing it by myself would require writing almost half a compiler (roughly what `rust-analyzer` did already), which is a no-go. I couldn't figure out how to use `rust-analyzer` as a library either. The only choice left to me was to explicitly run `cargo check` (or equivalent `rustc` command).

To do that, I had to convert the AST back to source code in plain text. Again, there's a crate for that: [`prettyplease`](https://github.com/dtolnay/prettyplease). It has an additional benefit of being fast, and being a basic formatter. So I don't have to format the resulting source code again when all the job is done.

In order to use `cargo check`, the source code must be part of the current crate. I decided to write the source to `/src/bin/tmp.rs` and run `cargo check --bin tmp --message-format json`. The `--message-format json` part is documented [here](https://doc.rust-lang.org/cargo/reference/external-tools.html#json-messages), and in the case of compiler messages, the inner structure is documented [here](https://doc.rust-lang.org/rustc/json.html). If you run `cargo check` with this option, you get a bunch of JSON objects, each on one line, and each representing one warning (in case of warnings). One such output would look like this (formatted and some less relevant fields simplified):

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

So, in order to filter `dead_code` warnings, it's enough to check the following in order:

* `obj.reason == "compiler-message"`
* `obj.message.code` exists
* `obj.message.code.code == "dead_code"`

But how to parse JSON? With [`serde_json`](https://docs.rs/serde_json/latest/serde_json/). `string.parse::<serde_json::Value>()` parses the given string into a nested representation of the JSON object. Then I can use [`value.pointer(path)`](https://docs.rs/serde_json/latest/serde_json/enum.Value.html#method.pointer) to fetch a deeply located field at once. How convenient.

Since a `dead_code` warning only gives the span of the identifier, not the entire item, I had to traverse over the items in the AST and check if each identifier matches the given span.

(Technical detail: to get a matching span (line start, line end, etc.), I had to parse the prettified source again and traverse on *that*.)

Implementation: [`fn cargo_check_deadcode`](https://github.com/Bubbler-4/rust-problem-solving/blob/97becc831f2e9cf032f2dbe466ff9fb140cabf35/cargo-oj/src/main.rs#L728-L762)

### But when is `dead_code` triggered, exactly?

The [rustc book](https://doc.rust-lang.org/rustc/lints/listing/warn-by-default.html#dead-code) just says "The `dead_code` lint detects unused, unexported items". Unexported means when an item is not `pub`. (`pub(crate)` does not make an item exported.) But exactly which kind of items are *unused*?

* Unused functions, types (`type T = U`), and constants (`const C: usize = 0`) are detected.
* Structs and enums are also detected, but `impl` blocks are not. Deleting these structs and enums without deleting associated impls would break the code.
* Individual items (associated functions and constants) within `impl` blocks *are* detected.
* Traits and `impl Trait`s are *not* detected. Also, if a struct or enum implements a trait, they're also "shielded" and not detected as dead code, even if they're unused otherwise.

[A demonstration.](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=d1be518711c50b878532b2106015191b)

*Note*: While I was writing this, I found out that I missed some item kinds and a potential improvement in the filtering process. More on that in the *Future works* section.

The last point is a bad news for me, since I have a bunch of `impl Trait`s in my library. This led me to the next revision in my overall strategy:

### Overall strategy, version 2

* Collect the module tree into single file, and then
* remove all items that give `dead_code` warnings on compile (assume the original codebase compiles). *Avoid deleting structs and enums at this step.*
* *Try removing remaining items one by one, and remove it if it still compiles.*

The last step sounds a bit "brute-forcey" (and it turned out to be the bottleneck indeed), but I couldn't find any alternative that would achieve the same thing. (I considered using a trait resolver such as [chalk](https://github.com/rust-lang/chalk), but couldn't quite figure out how to use it for my code, nor reliably remove all unused *structs, enums, trait declarations, and impl blocks* using it.)

### Traversing the AST, and the visitor pattern

Now to the problem of actually traversing the AST. The Rust AST has so many different kinds of nodes, and I need to recursively visit the nodes. That sounds super cumbersome.

Fortunately, `syn` comes with [`Visit`](https://docs.rs/syn/latest/syn/visit/trait.Visit.html) and [`VisitMut`](https://docs.rs/syn/latest/syn/visit_mut/trait.VisitMut.html) traits, which simplifies writing a *visitor*. [Visitor pattern](https://rust-unofficial.github.io/patterns/patterns/behavioural/visitor.html) is a design pattern that abstracts over visiting a heterogeneous collection of objects, or in this case, traversing the tree structure.

Since all the methods in `VisitMut` simply visit its children recursively by default, it suffices to override the methods on certain nodes:

* `File` to remove items in the root module,
* `ItemMod` to remove items in submodules, and
* `ItemImpl` to remove associated items inside an impl block.

The outline of the code looks roughly like this:

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

Implementation: [`struct DeadCodeRemover` and its impls](https://github.com/Bubbler-4/rust-problem-solving/blob/97becc831f2e9cf032f2dbe466ff9fb140cabf35/cargo-oj/src/main.rs#L614-L684)

## Step 3: Removing items one by one

I had to think a lot about the strategy on this one. Trying to choose one item out of the entire tree and remove it on the fly sounded too complicated, so I went the two-pass approach:

* First identify all items to try removal and collect their *canonical positions*, and then
* repeatedly try removing one by one.

The idea of canonical position works like this:

* The root item (i.e. the `File`) has the canonical position of `[]`.
* Its child items are assigned `[0]`, `[1]`, etc.
* In general, the children of an item at position `X` are assigned `[X, 0]`, `[X, 1]`, etc.

Except that there was one flaw with this: A list of items is stored as a `Vec`, and removing one item from there changes the positions of the items on the right.

After more thought, I decided to collect *spans* (byte offset range of each item) instead of canonical positions, and overwrite the region with spaces when deleting it. While it sounds less smart, it certainly meets the requirements.

Another weird technical detail: I could get [`Span`](https://docs.rs/proc-macro2/latest/proc_macro2/struct.Span.html)s from each AST node, but this object does not have APIs to extract the byte ranges. While I was debugging something else, I found that its *debug format* contains it. So I wrote a small function [`span_to_bytes`](https://github.com/Bubbler-4/rust-problem-solving/blob/97becc831f2e9cf032f2dbe466ff9fb140cabf35/cargo-oj/src/main.rs#L395-L400) that parses the information from the debug format string. Also, another function [`offset`](https://github.com/Bubbler-4/rust-problem-solving/blob/97becc831f2e9cf032f2dbe466ff9fb140cabf35/cargo-oj/src/main.rs#L402-L404) to fix the spans from `syn` nodes, as multiple `parse_file` calls seem to add up to the byte offsets.

Implementation: [`fn item_positions2`](https://github.com/Bubbler-4/rust-problem-solving/blob/97becc831f2e9cf032f2dbe466ff9fb140cabf35/cargo-oj/src/main.rs#L406-L448)

This function runs a DFS to collect spans so that the later items come first and parents come before children. The rationale for this ordering is that removing an entire module when possible will save calls to its children, and items in a module are usually written so that later items depend on earlier ones. It also filters out the top-level `main` function.

Running `cargo check` on the result is easy. It uses the same code as before, and it's simpler because it suffices to check the exit code.

Now to the overall problem. I decided to try the positions in a circular fashion, removing redundant items (i.e. children of an already deleted module) from the queue, until there's nothing to be deleted.

Implementation: [`fn try_remove_one_item2`](https://github.com/Bubbler-4/rust-problem-solving/blob/97becc831f2e9cf032f2dbe466ff9fb140cabf35/cargo-oj/src/main.rs#L142-L165) (at this point, I had `cargo_check_success` instead of `rustc_check_success`.)

### Switch from cargo to rustc

With the [main function](https://github.com/Bubbler-4/rust-problem-solving/blob/97becc831f2e9cf032f2dbe466ff9fb140cabf35/cargo-oj/src/main.rs#L47-L71) ready, I thought it should work.

As shown [in the cargo docs](https://doc.rust-lang.org/cargo/reference/external-tools.html#custom-subcommands) and [an SO post](https://stackoverflow.com/a/70293462/4595904), I ran the following, hoping it to give `main.rs` correctly.

```bash
# at workspace/cargo-oj/
cargo install --path .
cd ../ps
cargo oj
```

Well, it didn't.

With the current logic, the result couldn't have compilation error. Yet the resulting `main.rs` was giving various errors. In one run, a necessary method on `struct I` was missing; in another, `struct I` itself was missing; yet in another, the `solve` function was missing!

The only possible cause I could imagine was interference with the IDE regarding the `tmp.rs` file. Okay, I shouldn't be overwriting a file within the IDE workspace in such a quick succession. Then it should be done outside. But there's no cargo project outside, so I guess I'd need to invoke `rustc` directly. And if so, I'd pass the source code via stdin as well. (I knew passing source via stdin was a thing, from [how code.golf runs rustc](https://github.com/code-golf/code-golf/blob/master/langs/rust/rust). They do it because they don't want "reading from the source file" be a valid solution for Quine.)

Now I had to figure out how to imitate the behavior of `cargo check` with `rustc`. Digging into the [rust-lang/cargo](https://github.com/rust-lang/cargo) repo didn't help. Running `cargo` with `--build-plan` didn't help either. I DDG'd again and found [this SO Q&A](https://stackoverflow.com/q/51485765/4595904), listing a couple of options that work with stable Rust:

* `rustc --emit=mir -o /dev/null`
* `rustc -C extra-filename=-tmp -C linker=true`
* `rustc --out-dir=/tmp/tmpdir`

In the first option, `-o /dev/null` part didn't work for me. Running it without `-o` part gave a `<filename>.mir` file at the working directory. After a lot of experiments, a combination of first and third seemed to work for me, so the command became

```bash
# cargo check, checking success/failure only
rustc --emit=mir --edition=2021 --out-dir=/tmp/ramdisk -
# cargo check --message-format=json
rustc --emit=mir --edition=2021 --out-dir=/tmp/ramdisk --error-format=json -
```

(I did set up a ramdisk at `/tmp/ramdisk`; it's surprisingly easy in Linux, and there are tons of tutorials out there teaching you how to set it up. Nonetheless, I doubt it significantly helped with the total running time.)

The entire program finally worked, giving a correct, minimal, formatted `main.rs`. But it took over 5s, which felt too slow.

## Step 4: Optimization

I couldn't imagine doing the same job without the help of `rustc`, so the only options left were parallelizing `rustc` invocations and reducing the number of invocations itself.

### Parallizing `rustc` runs

For the former, I tried [`rayon`](https://docs.rs/rayon/latest/rayon/index.html) first, as I had some prior experience with it and its `par_iter` seemed so easy. But I had to change the logic to use it ([source](https://github.com/Bubbler-4/rust-problem-solving/blob/97becc831f2e9cf032f2dbe466ff9fb140cabf35/cargo-oj/src/main.rs#L190-L208)), and it made the total running time actually worse. Turns out [there's a warning](https://docs.rs/rayon/latest/rayon/fn.join.html#warning-about-blocking-io):

> If you do perform I/O, and that I/O should block (e.g., waiting for a network request), the overall performance may be poor.

Okay, so I guess I need [`tokio`](https://docs.rs/tokio/latest/tokio/index.html) instead. It provides a multithreaded async runtime, which should help with parallelizing child processes. It has [an async interface for child processes](https://docs.rs/tokio/latest/tokio/process/index.html) too.

With this, I wanted to handle `rustc` runs in the order of completion. The first thing I tried was a horrible mess involving [an mpsc channel](https://doc.rust-lang.org/std/sync/mpsc/index.html)... and it didn't quite work out. Was it an infinite loop, or a deadlock? I don't know.

I DDG'd again and found [the exact SO post I needed](https://stackoverflow.com/a/72652221/4595904). Turns out there are various async task management utilities in [`futures`](https://docs.rs/futures/latest/futures/index.html), one of which is [`FuturesUnordered`](https://docs.rs/futures/latest/futures/stream/futures_unordered/struct.FuturesUnordered.html). With it, my new [`try_remove_one_item`](https://github.com/Bubbler-4/rust-problem-solving/blob/97becc831f2e9cf032f2dbe466ff9fb140cabf35/cargo-oj/src/main.rs#L210-L252) got a lot longer, but it did become faster, running at around 2s.

Except that it didn't remove some of the unnecessary items. I [added a `while` loop](https://github.com/Bubbler-4/rust-problem-solving/blob/97becc831f2e9cf032f2dbe466ff9fb140cabf35/cargo-oj/src/main.rs#L279-L317) to ensure that all unnecessary items were correctly filtered, and it went up again to 3s.

At this point, I figured that the maximum parallelization would be achieved if I actually ran the tests sequentially with a small queue for the `Future`s. The logic essentially returned to the initial one. [Final version.](https://github.com/Bubbler-4/rust-problem-solving/blob/97becc831f2e9cf032f2dbe466ff9fb140cabf35/cargo-oj/src/main.rs#L319-L355)

### Reducing `rustc` calls

Then I had another idea: do less work with these `rustc` calls and run another `dead_code` pass as postprocessing. I decided to remove enclosing `mod`s and items inside `impl` blocks from the list of positions returned by `item_positions`. This brought the running time down to 1.5s.

The complete code so far, cleaned-up and commented, can be found [here](https://github.com/Bubbler-4/rust-problem-solving/blob/90bb4bf3a7b4cd33cd426bf51a743e549233fb3d/cargo-oj/src/main.rs).

## Future work

* Loading files
    * Allow `mod.rs`-style modules.
    * Copy file-level attributes on submodules to parent `mod` node as well.
    * Check if doc-comments do survive the round trip.
* Dead code elimination
    * What to do with macro decls/invocations?
    * Filter `unused_imports` too.
    * Filter associated constants, and delete empty impl blocks (which will make deleting structs/enums safe).
* Bruteforcing
    * Check if a [current-thread scheduler](https://docs.rs/tokio/latest/tokio/runtime/index.html#current-thread-scheduler) works better.
* Publishing the crate
    * Allow the `tmp` directory to be configured. Use [`directories`](https://crates.io/crates/directories) to store such configuration.

If you have any questions or suggestions about the code, please leave a comment below.