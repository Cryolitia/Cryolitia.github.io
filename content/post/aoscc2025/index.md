---
title: deepin 桌面环境在发行版移植中的问题
description: "AOSCC 2025"
date: 2025-07-25
categories: 
  - 演讲
---

<div class="video-wrapper">
    <iframe src="https://player.bilibili.com/player.html?as_wide=1&high_quality=1&page=1&bvid=BV1678tzzERj&p=3&t=1995&autoplay=false"
            scrolling="no"
            frameborder="no"
            framespacing="0"
            allowfullscreen="true"
    >
    </iframe>
</div>

## 与上游依赖项补丁有关的耦合问题

在deepin桌面环境（以下简称DDE）的项目开发过程中，我们用到了很多上游的依赖库，如 `polkit-qt` 。项目组在有些时候需要修改上游依赖库，以增加某些奇怪的功能，这往往也破坏了上游库的ABI兼容性，增加或修改了部分二进制库的函数签名。而这些功能并不是增强DDE用户体验的所必需的，也不必移植到其他的发行版中。

在这种客观需求下，项目组有时会选择直接在deepin系统仓库中增加补丁，在deepin系统构建时直接修补上游依赖库，以便在deepin的操作系统环境中直接包含修补后的软件包。

更有甚者，部分我们第一方项目的鲁棒性不佳。在上游依赖库缺乏此类补丁时会直接闪退崩溃，使得整个项目完全不可用。但是，在向其他发行版移植DDE的时候，其他发行版几乎不可能接受此类对上游依赖库的更改。因此，我们需要一种更合理的方式来控制不可控需求与软件可移植性之间的平衡。

在deepin技术委员会充分讨论后，我们连夜提出了题为《deepin软件包patch维护约定》的RFC草案。我们在草案中要求，所有DDE自研项目必须兼容未经deepin出于扩展功能等非修复性目的自行修补的上游项目。

此外，部分DDE项目也会依赖由于不可控因素而在deepin上必须存在的闭源模块，这同样会由于开发时的鲁棒性不佳而造成兼容性问题。我们也要求项目组在此类场景下提供非的deepin环境的fallback方案。

## 大量DTK项目CMake文件中的版本号存在人为性错误

由于历史遗留问题，deepin第一方项目中存在大量分别依赖Qt5和Qt6的平行项目，如 `dtkcore` 和 `dtk6core`，这些项目虽然命名不同且分别位于独立的GitHub仓库中，但却共享了大量的代码，也包括CMake文件。

此后，DDE项目组将debian的构建系统与DDE项目的版本号以及构建过程绑定。项目组会在发布新的软件包版本时修改仓库 `debian/changelog` 中的版本号，但是由于懒惰等原因不修改CMake文件中的版本号；然后再在 `debian/rules` 中手动控制软件包的构建过程，将debian中的版本号作为参数传递给CMake。

更加雪上加霜的是，DDE项目组使用了一些魔法来同步平行项目间的变更，也包括CMake文件中的变更。这使得CMake文件中同时存在对Qt5和Qt6的支持，每一对平行项目都可以使用Qt5或Qt6构建。具体来说，就是事实上存在 `dtkcore-qt5` `dtk6core-qt5` `dtkcore-qt6` `dtk6core-qt6` 这样的矩阵（尽管我们不对“5-6”“6-5”的组合提供任何可用性保证），而具体在构建过程中选择Qt5还是Qt6是由外部传入的版本的首位是`5`还是`6`来确定的。

因此，发行版在构建这些平行软件包的时候，需要手动在构建过程中向CMake传递由发行版软件包维护者在软件包元数据中定义的版本号，随后构建系统据此选择适当的Qt版本。

此前DDE在Arch Linux和Nixpkgs的打包皆继承了这一方案，在与白特首沟通的时候，我们项目组惊讶地发现这一行为居然是不可接受的。

最终，我设计了一套正常的CI流程来供项目组偷懒的完成此类项目的版本发布工作。该流程可以自动的在发版时更改CMake文件中的版本号，并自动生成新的 `debian/changelog` 文件。该流程目前已经部署上线，deepin第一方项目近期发布的版本中都应包含了正确的版本号。

此外，我们现在原则上要求所有项目组对自身项目中构建系统相关（也就是 `debian` 目录下）内容的更改，都必须经过deepin系统组审核通过，降低了开发组因不熟悉发行版维护要求而降低项目及系统质量的行为发生的可能性。

## DDE与deepin配置文件混杂

由于历史原因，同时并行存在四个与deepin/DDE相关的配置仓库：`deepin-desktop-base` `deepin-desktop-schemas` `deepin-osconfig` `default-settings`。

`deepin-desktop-base` 中提供了大量系统配置，包括 deepin发行版的版本信息和系统图标，系统语言支持列表，`python-apt`集成等。

`default-settings`仓库中皆为deepin系统级别默认配置，定义了系统网络组件行为、首次启动行为、桌面默认图标等，对大量Linux底层文件进行了修改。

`deepin-desktop-schemas`提供的文件中包括了deepin系统应用商店的相关文件和DDE主题配置文件。

`deepin-osconfig`中提供了大量DDE桌面相关的配置。

这就导致了其他发行版可能会发现自己在打包和安装看起来像是DDE项目配置文件的 `deepin-desktop-base` 后发现自己的`os-release`神奇的变成了deepin，却因为没有打包和安装`deepin-osconfig`而导致DDE无法正常使用。

我们找了一个实习生，她整理了所有的配置文件，并将其重新分类为命名和逻辑都比较正确的`dde-settings-default` `deepin-settings-default`两个仓库。推荐移植者在打包时弃用前述四个仓库，而只使用`deepin-settings-default`仓库。

## Qt私有头文件的使用

Qt中存在一些不稳定的私有头文件，它们默认不会被发行版打包和安装。DDE的部分项目出于功能的切实需要，使用这些头文件，这导致其在缺乏这些私有头文件的一般路过发行版上构建失败。

考虑到已经有Debian打包了大量形如 `qt*-private-dev` 的软件包，又或是Nix等可以直接通过 `${qt6Packages.qtbase.src}`引用的强大构建系统，我们决定尝试向其他发行版推动相关私有头文件的打包。

此外，由于Qt私有头文件的不稳定性，DDE项目中使用的私有符号也可能在几个Qt版本中消失不见。目前只能通过注释相关代码或回退对应更改的方式来增强其兼容性。

## 其他问题

- 部分项目安装过程中假设了特定的 `libexecdir` 目录，已经更改为允许在构建过程中通过参数传入
- 部分项目安装过程中文件的权限位设置不正确，例如，可执行文件未设置 `x` 权限位
- 大量DDE项目缺乏供发行版参考的清晰有意义的自然语言描述
- 部分已经废弃不再使用的项目仍作为依赖被其他软件引用，仓库也没有被标记废弃或存档

AOSC构建系统中严格的品质保证（QA）检查帮助我们发现了大量未曾察觉的上述错误，在此特向AOSC表示感谢。

{{< code path = "static/p/aoscc2025/slide.typ" prefix = "typst" title = "幻灯片源码" >}}

{{< vertical_images prefix="output/" count="15" suffix=".svg" >}}
