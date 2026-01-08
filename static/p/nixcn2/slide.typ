#import "@preview/touying:0.6.1": *
#import themes.metropolis: *
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.8": *

#import "@preview/numbly:0.1.0": numbly

#set page(background: image("nix-wallpaper-nineish.src.svg"))
#set text(font: "Sarasa UI SC")
#set par(first-line-indent: 2em)
#set list(indent: 2em)
#let fake_par = {
      v(-1em)
      box()
    }

#show: codly-init.with()
#codly(zebra-fill: none)
#codly(fill: white.transparentize(50%))
#show raw: text.with(font: "JetBrainsMono NF")

#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  footer: self => self.info.institution,
  config-info(
    title: [NixOS on SBC],
    subtitle: [ #h(2em) (Single Board Computer)],
    author: [Cryolitia PukNgae],
    date: datetime(
      year: 2025,
      month: 12,
      day: 28,
    ),
    institution: [NixOS CN],
  ),
  config-common(preamble: {
    codly(languages: codly-languages)
  }),
)

#show: touying-set-config.with(config-colors(
  primary: rgb("#4D6FB7"),
  primary-light: rgb("#5FB8F2"),
  secondary: black.transparentize(100%),
  neutral-lightest: black,
  neutral-dark: black,
  neutral-darkest: black,
))

#set heading(numbering: numbly("{1}.", default: "1.1"))

#title-slide()

== Cryolitia PukNgae

- GitHub: #link("https://github.com/cryolitia", "@Cryolitia")
- Telegram: \@Cryolitia
- Email: cryolitia.pukngae\@linux.dev

\

前PLCT实习生，灵车设备(叶公好龙)爱好者，deepin-ports SIG 成员。

#place(
  top + right,
  image("./1.webp", width: 30%)
)

= 单板计算机

---

#align(center)[
  #table(
  columns: 4,
  inset: 30pt,
  align: center,
  stroke: 0.6pt,

  [], [*体积纯粹*], [*体积中立*], [*体积自由*],

  [*计算纯粹*],
  [Raspberry Pi],
  [Radxa O6],
  [SG2044],

  [*计算中立*],
  [ESP32],
  [Ti Nspire CX],
  [RTX 5090],

  [*计算自由*],
  [74283],
  [AMD Kintex-7],
  [人列计算机],
)
]

---

#image("2.jpg", width: 100%)

---

= 设备树/ACPI

---

- ACPI：*EDK2* -> 通用内核 + 驱动

- 设备树：编译内核 -> Bootloader加载 -> 内核（*版本匹配*） + 驱动

\

#link("https://github.com/radxa/kernel/blob/linux-6.17.1/arch/arm64/boot/dts/qcom/qcs6490-radxa-dragon-q6a.dts")

= Linux 内核

---

=== 内核配置

\

- #link("https://github.com/radxa/kernel/blob/linux-6.17.1/arch/arm64/configs/qcom_module_defconfig", "qcom_module_defconfig")

- `ignoreConfigErrors = true;`

---

=== 厂商内核

\

- #link("https://github.com/deepin-community/deepin-ports-kernel/tree/new/kernel/profiles")

- #link("https://search.nixos.org/packages?channel=unstable&query=linuxKernel.kernels.")

---

#align(center)[#image("3.jpg", height: 60%)]

```log
nvme nvme0: controller is down; will reset;
nvme nvme0: Does your device have a faulty power saving mode enabled?
nvme 0001:00:00.0: Unable to change power state from D3cold to D0, device inaccessible
```

= 分区

4096 sector

---

=== 错误

- #link("https://github.com/nix-community/disko/blob/master/lib/types/gpt.nix#L315")
- #link("https://github.com/NixOS/nixpkgs/blob/master/nixos/lib/make-disk-image.nix#L284")

=== 正确

- `fdisk --sector-size 4096`
- `losetup --sector-size 4096`
- ghostfish（但是并没有看懂）

= 技术之外的问题

---

=== 抽象厂商

- #link("https://github.com/radxa-pkg/aic8800/issues/54")
- #link("https://lore.kernel.org/all/20251020092144.25259-1-he.zhenang@bedmex.com/")

=== 非一级架构

- RISC-V
- LoongArch
- MIPS(?)

=== 树莓派沙文主义

- #link("https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/sd-card/sd-image-aarch64.nix")

#focus-slide[
  完结&提问 \
  #line(length: 80%)
  #set text(size: 0.8em)
  感谢deepin和瑞莎计算机在相关工作中的支持
]
