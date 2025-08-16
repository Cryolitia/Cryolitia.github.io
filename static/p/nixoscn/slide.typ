#import "@preview/touying:0.6.1": *
#import themes.metropolis: *
#import "@preview/codly:1.0.0": *
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
    title: [CJK语言支持困境],
    subtitle: [ #h(2em) ——以Steam为例],
    author: [Cryolitia],
    date: datetime(
      year: 2025,
      month: 08,
      day: 09,
    ),
    institution: [NixOS 社区],
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

#focus-slide[
  警告：非线性时间线
]


= 起

什么？2024年了NixOS上的Steam还不能用？

---

== 豆腐块

- #link("https://github.com/NixOS/nixpkgs/issues/178121")
- #link("https://github.com/Jovian-Experiments/Jovian-NixOS/issues/355")

#grid(
  columns: (1fr, 1fr),
  [#align(center, image("0001.png", width: 80%))],
  [#align(center, image("0002.png", width: 80%))],
)

== 字体

=== 文泉驿？

梦回初中

#link("https://wiki.archlinux.org/index.php?title=Steam&oldid=809160")

#align(center, image("0003.png", width: 70%))

#pagebreak()

=== Variable font？

#link("https://github.com/flathub/com.valvesoftware.Steam/issues/1070")

#align(center, image("0004.png", width: 60%))#align(center, image("0005.png", width: 60%))

= 承

上面提到的修复方法怎么都没用？

== 跑起来了……吗？

至少我们知道了如何向Steam提供正确的字体文件

#[

#show raw: text.with(size: 0.8em)

```nix
# pkgs/by-name/st/steam/package.nix
{
  extraPkgs ? pkgs: [ ], # extra packages to add to targetPkgs
}:
buildRuntimeEnv {
  pname = "steam";
  inherit (steam-unwrapped) version meta;

  extraPkgs = pkgs: [ steam-unwrapped ] ++ extraPkgs pkgs;
```

```nix
programs.steam.extraPkgs = p: (cfg.extraPackages ++ lib.optionals (prev ? extraPkgs) (prev.extraPkgs p));
```
]

但是？


== 如何证明他实际不能用

=== 找不同

#image("0006.png", width: 100%)

#[
#show raw: text.with(size: 0.5em)
```nix
    fontconfig = {
      defaultFonts = {
        emoji = [
          "Source Han Serif SC"
          "JetBrainsMono Nerd Font"
          "Noto Color Emoji"
        ];
        monospace = [
          "Source Han Serif SC"
          "Sarasa Mono SC"
          "JetBrainsMono Nerd Font Mono"
        ];
        sansSerif = [ "Source Han Serif SC" ];
        serif = [ "Source Han Serif SC" ];
      };
      cache32Bit = true;
    };
```
]

=== 俺寻思没问题

#image("0007.png", width: 100%)
#image("0008.png", width: 100%)

=== 再看看？

#align(center, image("0009.png", width: 50%))

== 我文件呢？

#[
#show raw: text.with(size: 0.5em)
```nix
fonts.fontconfig.localConf = ''
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <description>Load local customization file</description>
	<!-- Load local system customization file -->
	<match>
	    <test name="prgname" compare="contains" ignore-blanks="true">
		    <string>steam</string>
    	</test>
		<test name="family" compare="eq">
			<string>Arial</string>
		</test>
		<edit binding="same" mode="prepend" name="family">
			<string>sans-serif</string>
		</edit>
 	</match>
</fontconfig>
``
```
]

`$ strace -f steam:`

`[pid 11930] access("/etc/fonts/local.conf", R_OK) = -1 ENOENT (No such file or directory)`

---

这不是在这吗！

#align(center, image("0010.png", width: 80%))

= 转

盗梦空间

== 解铃还需系铃人

#link("https://github.com/ValveSoftware/steam-for-linux/issues/10422#issuecomment-1944396010")

#align(center, image("0011.png", width: 80%))

== 柳暗花明疑无路

#link("https://github.com/ValveSoftware/steam-for-linux/issues/10915")

#align(center, image("0012.png", width: 90%))

== 层层套娃

- NixOS
  - buildFHSEnv
    - Steam Linux Runtime

#line(length: 80%)

`/etc/fonts/local.conf` or `.config/fontconfig/fonts.conf`, that is the question.

= 合
愉快的游玩CJK游戏吧！
---

== 合并！

#link("https://github.com/NixOS/nixpkgs/pull/312268")

#[
#show raw: text.with(size: 0.8em)
```nix
fontPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = config.fonts.packages;
      defaultText = lib.literalExpression "fonts.packages";
      example = lib.literalExpression "with pkgs; [ source-han-sans ]";
      description = ''
        Font packages to use in Steam.
        Defaults to system fonts, but could be overridden to use other fonts — useful for users who would like to customize CJK fonts used in Steam. According to the [upstream issue](https://github.com/ValveSoftware/steam-for-linux/issues/10422#issuecomment-1944396010), Steam only follows the per-user fontconfig configuration.
      '';
    };
```
]

== 问题看起来完美的解决了！

但是……以后呢……

#align(center, image("0013.png", width: 90%))

`nixpkgs-cjk-maintainer team` 可能性微存

#focus-slide[
  完结&提问 \
  #line(length: 80%)
  #set text(size: 0.8em)
  特别感谢 `@CoelacanthusHex` (aka 浅见沙织)的帮助
]
