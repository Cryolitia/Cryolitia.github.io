#import "@preview/touying:0.6.1": *
#import themes.metropolis: *
#import "@preview/codly:1.0.0": *
#import "@preview/codly-languages:0.1.8": *

#import "@preview/numbly:0.1.0": numbly

#set page(background: image("Picture1.png"))
#set text(font: "Sarasa UI SC")
#set par(first-line-indent: 2em)
#set list(indent: 2em)
#let fake_par = {
      v(-1em)
      box()
    }

#show: codly-init.with()
#codly(zebra-fill: none)
#codly(fill: black.transparentize(50%))
#show raw: text.with(font: "JetBrainsMono NF")

#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  footer: self => self.info.institution,
  config-info(
    title: [deepin 桌面环境在发行版移植中的问题],
    author: [Cryolitia, 项泽龙],
    date: datetime(
      year: 2025,
      month: 7,
      day: 25,
    ),
    institution: [deepin社区],
  ),
  config-common(preamble: {
    codly(languages: codly-languages)
  }),
)

#show: touying-set-config.with(config-colors(
  primary: rgb("#ff3535"),
  primary-light: rgb("#ffc000"),
  secondary: black.transparentize(100%),
  neutral-lightest: white,
  neutral-dark: white,
  neutral-darkest: white,
))

#set heading(numbering: numbly("{1}.", default: "1.1"))

#title-slide()

= 目录 <touying:hidden>

#outline(title: none, indent: 1em, depth: 1)

= 上游依赖项补丁有关的耦合问题

deepin系统仓库中的第三方库ABI/API与上游不兼容，导致DDE在其他发行版上崩溃

---

=== 来源

- DDE项目的研发过程中直接在deepin系统仓库中对第三方库进行了破坏ABI/API兼容性的修改
- 出于某些需要，DDE项目依赖了仅在deepin环境下需要的闭源模块

=== 解决方案

#fake_par

要求DDE项目必须兼容原始上游项目

=== RFC（发起中）

#fake_par

#link("https://github.com/deepin-community/rfcs/pull/17","rfc: patch maintenance convention")

= 大量DTK项目CMake文件中的版本号存在人为性错误

CMake版本号与实际版本号不一致，版本号需在编译时传入

---

== 现状

=== CMake

#[

#set text(size: 0.8em)

```cmake
set (DTK_VERSION "5.6.12" CACHE STRING "define project version")
project (DtkCore
  VERSION ${DTK_VERSION}
  DESCRIPTION "DTK Core module"
  LANGUAGES CXX C
)

if("${PROJECT_VERSION_MAJOR}" STREQUAL "5")
    set(QT_VERSION_MAJOR "5")
elseif("${PROJECT_VERSION_MAJOR}" STREQUAL "6")
    set(QT_VERSION_MAJOR "6")
    set(DTK_VERSION_MAJOR "6")
else()
    message(SEND_ERROR "not support Prject Version ${PROJECT_VERSION}.")
endif()
```
]

=== Arch Linux PKGBUILD

#codly(highlights: (
  (line: 8, fill: blue.transparentize(50%)),
))

```bash
build() {
  cd dtk6core
  cmake . -GNinja \
      -DBUILD_DOCS=ON \
      -DBUILD_TESTING=ON \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DCMAKE_INSTALL_LIBEXECDIR=lib \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DDTK_VERSION=$pkgver
  ninja
}
```
==

=== 原因

- 平行项目形如 `dtkcore` 和 `dtk6core`
- 研发认为版本发布时仅修改一处 `debian/changelog` 中的版本号即可，更多修改是不必要的
- `dtkcore` 和 `dtk6core`之间的变更被魔法同步，两个仓库中的cmake文件均同时包含Qt5和Qt6的版本
- CMake在编译时根据传入的版本号确定Qt版本
- 由于某大型软件仓库已经在主线接受了在编译时传入版本号的魔法操作，导致这个行为被错误认为是非常合理的

=== 解决方案

- 设计自动化发版流程，用更懒的操作防止研发使用先前偷懒的错误方式
- 所有项目对 `debian` 目录的更改必须经过deepin系统组审核

= DDE与deepin配置文件混杂

`deepin-desktop-base` \
`deepin-desktop-schemas` \
`deepin-osconfig` \
`default-settings`

---

=== 现状

- #link("https://github.com/orgs/linuxdeepin/discussions/11769","deepin/dde 配置梳理 · linuxdeepin · Discussion #11769")
- `deepin-desktop-base` 看起来像DDE相关，但打包安装后`os-release`神奇的变成了deepin
- `deepin-osconfig` 看起来像deepin系统相关，但不打包安装会导致DDE无法正常使用。

=== 解决方案

- `dde-settings-default`
- `deepin-settings-default`

= Qt私有头文件的使用

---

=== 现状

- DDE项目出于实际需要，使用了Qt的私有头文件，而许多发行版没有提供这些头文件
- Qt私有库部分的ABI不稳定，可能导致运行时找不到符号而崩溃

=== 解决方案

- 直接向其他发行版推动Qt私有头文件的打包
  - Debian中已经包含大量形如 `qt*-private-dev` 的包
  - 先进的构建系统Nix可以直接通过 `${qt6Packages.qtbase.src}` 引用
- 暂时在其他发行版上注释或回退使用不稳定符号的相关代码

= 其他问题

---

- 部分项目安装过程中假设了特定的 `libexecdir` 目录，已经更改为允许在构建过程中通过参数传入
- 部分项目安装过程中文件的权限位设置不正确，例如，可执行文件未设置 `x` 权限位
- 大量DDE项目缺乏供发行版参考的清晰有意义的自然语言描述
- 部分已经废弃不再使用的项目仍作为依赖被其他软件引用，仓库也没有被标记废弃或存档


#v(1em)

#fake_par

AOSC构建系统中严格的品质保证（QA）检查帮助我们发现了大量未曾察觉的上述错误，在此特向AOSC表示感谢。

#focus-slide[
  感谢！
]
