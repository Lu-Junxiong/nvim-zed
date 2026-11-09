# Neovim Zed 风格便携版

Linux x86_64。Atom One Light 配色、顶部文件标签、Yazi 浮窗文件浏览器、底部终端。

可以克隆仓库后直接启动（插件和 Neovim 已随仓库提供）：

```bash
git clone https://github.com/Lu-Junxiong/nvim-zed.git
./nvim-zed/run /path/to/project
```

已有离线压缩包时：

```bash
tar -xzf nvim-zed-linux-x86_64.tar.gz
./nvim-zed/run /path/to/project
```

也可以 `./nvim-zed/run /path/to/project relative/file.py`。不传目录则使用当前目录。
只传项目目录时显示全宽启动页，焦点在启动页；指定文件时直接打开文件。终端按 `Ctrl-\` 首次创建，不自动启动，打开后占底部高度约 25%。

## 系统要求

- Linux x86_64，glibc >= 2.34，以及系统 libgcc_s.so.1；不适用于 Alpine/musl。
- Bash、GNU coreutils；PATH 中已有 `ty`、`ruff`、`rg`、`git`。
- 支持真彩色的终端；字体和字号在终端里设置，完整文件图标需要终端选择 Nerd Font；也可使用下述 ASCII 图标模式。
- 解压目录可写。配置与插件已内置，运行时不安装、不更新、不联网下载。

包含 Neovim 0.12.6。已验证 ty 0.0.99、Ruff 0.16.10；插件版本见 manifest.txt。
系统实测为 glibc 2.39；2.34 下限来自二进制所需符号检查，未在旧系统实测。

## 快捷键

`Space` 表示普通模式先按空格，再按后面的键。`Ctrl-p` 在普通模式搜索文件；插入模式用于选择补全。

| 操作 | 按键 |
| --- | --- |
| 退出插入模式 | `jk` 或 `Esc` |
| 文件搜索 | `Ctrl-p` |
| 项目全文搜索 | `Space /` |
| 搜索、切换已打开文件 | `Space b` |
| 搜索当前文件内容 | `Space s` 或原生 `/` |
| 当前文件大纲（Python、JSON、YAML、INI） | `Space o` |
| 屏幕内快速跳转（Flash） | `Space j` |
| 上一个／下一个文件 | `[b` / `]b` |
| 上一个／下一个文件（终端支持时） | `Ctrl-Shift-Tab` / `Ctrl-Tab` |
| 关闭当前文件 | `Space x` |
| 保存 | `Space w` 或 `:w` |
| Yazi 文件浏览器打开／关闭 | `Space e`（普通模式） |
| Yazi 上下选择／父目录／进入 | `j`、`k` / `h` / `l` |
| 底部终端显示／隐藏 | `Ctrl-\` |
| 面板左／下／上／右切换 | `Ctrl-h/j/k/l` |
| 终端退出输入模式，可选择、复制输出 | 连按两次 `Esc` |
| 定义／引用／悬浮说明 | `gd` / `gr` / `K` |
| 重命名 | `Space rn` |
| Ruff 格式化 | `Space f` |
| 整理 imports／代码修复菜单 | `Space ci` / `Space ca` |
| 查看诊断 | `Space d` |
| 诊断列表（按严重程度排序） | `Space q` |
| 上一个／下一个诊断 | `[d` / `]d` |
| 上一个／下一个 Git 修改块 | `[c` / `]c` |
| 预览修改块 | `Space hp` |
| 当前文件与 Git 暂存区并排比较 | `Space hd` |
| 关闭差异页，返回编辑布局 | `Space hq` |
| 本说明 | `Space ?` |

搜索窗口：直接输入、`Ctrl-n/p` 或方向键选项、`Enter` 打开、`Esc` 取消。

Flash：普通模式按 `Space j`，输入目标字符，再按目标旁的字母标签跳转；`Esc` 取消。支持可见编辑窗口间跳转，排除 Yazi、终端和补全窗口。原生 `f/F/t/T`、`;`、`,` 保持不变。
搜索遵循 rg 的忽略规则，默认不扫描隐藏文件及被忽略目录。
首次按 `Ctrl-\` 时，终端从项目目录启动，继承已激活的 Python 环境；隐藏后进程继续运行。执行 `exit` 后不会自动重启，下次按 `Ctrl-\` 创建新终端。面板切换键和 `Ctrl-\` 被编辑器接管；`jk` 不影响 shell。
退出整个 Neovim 会结束内置终端，不会自动保存文件；用 `:wa` 保存所有修改，`:qa` 退出。
Git 差异页默认比较暂存区；也可用 `:Gitsigns diffthis HEAD` 查看与 HEAD 的差异。

## 补全和 Python

- 当前 buffer 的单词优先，其他已加载的同类型文件提供补充；同时提供路径和 ty 语义候选；候选右侧标明 `[buf]`、`[path]`、`[ty]`。
- `Tab` 接受已选项，未选择时接受首项；没有候选时正常缩进。
- `Enter` 始终换行。`Ctrl-n/p` 选项，`Ctrl-e` 关闭菜单，`Ctrl-Space` 手动触发。
- ty 负责类型检查、补全、跳转和重命名；Ruff 负责规范检查、格式化和整理 imports。
- 格式化和整理 imports 都是手动操作，不会在保存时自动修改代码。
- 诊断显示在行号旁，按 `Space d` 查看详情，不在代码后堆叠文字。

项目根目录由最近的 pyproject.toml、ty.toml、Ruff 配置或 .git 确定。
环境选择交给 ty，读取项目配置、已激活的 virtualenv/Conda、项目 .venv 和 PATH。
建议先激活项目环境再启动；项目依赖仍由你自己维护。
需要强制指定环境时，传入环境目录或 Python 解释器的绝对路径：

```bash
NVIM_ZED_PYTHON=/path/to/env ./nvim-zed/run /path/to/project
```

`:ZedInfo` 查看工具路径、版本、环境来源和当前文件连接的 LSP。

## 配置与搬迁

配置在 `config/init.lua` 和 `config/lua/`。主题在 `config/lua/theme.lua`，使用随包的 onedarkpro.nvim（onelight）。已有的 ~/.config/nvim 等配置不会加载。
Neovim 的运行数据全部写入包内 `var/`；不修改现有 Neovim 配置，也不自动执行项目本地 Neovim 配置。
终端、`:!`、Git、rg、ty 和 Ruff 通过 `bin/` 中的统一入口恢复启动前的环境，继续读取你原有的用户配置；项目配置照常生效。

`[b`、`]b`、`Space x` 和 `Space w` 会先返回编辑区，不会把底部终端替换成文件。

退出 Neovim 后移动整个目录即可。迁移不需要联网。
发布压缩包不带编辑历史；自己重新打包时，可以在退出后删除 `var/`，清除日志、撤销记录和历史路径。

## 已验证

- 嵌入式终端 UI 实测：布局、面板切换、终端进程保留、jk、补全按键、文件／全文／buffer 搜索。
- 实际 ty + Ruff：双服务诊断、补全、悬浮说明、跨文件跳转／引用／重命名、格式化。
- Python 环境：项目 .venv 自动发现，以及显式指定不同 Conda 环境后的第三方库跳转。
- 临时 Git 仓库：修改标记、修改块导航／预览、并排差异及退出。
- 全新解压到含空格路径，在无网络命名空间中启动并复测交互；旧配置和启动环境隔离。

## 从仓库制作离线包

在仓库目录执行，打包当前已提交版本。`.gitattributes` 自动排除插件测试、示例和开发脚本；保留运行代码、帮助文档与依赖许可证，不包含运行缓存或 Git 历史：

```bash
git archive --format=tar.gz --prefix=nvim-zed/ -o nvim-zed-linux-x86_64.tar.gz HEAD
```

## 检查配置

仓库中运行 `./tests/check`，会在临时目录复制配置并检查启动布局、环境隔离、Git 用户配置、面板保护、搜索、大纲、Python 诊断与格式化、Flash 和补全按键，不改动项目文件。

Linux 允许非特权用户创建命名空间时，可断网验证：

```bash
unshare -Urn ./tests/check
```

也可以用 `./tests/check /path/to/extracted/nvim-zed` 验证解压后的精简包。检查脚本本身不会包含在离线包中。

## 图标、快捷键提示和诊断列表

顶部标签、搜索列表和 Yazi显示文件类型图标。完整字形需要在本地终端选择 Nerd Font；SSH 连接时也在本地终端设置。若出现方框或乱码，可以先使用字符图标：

```bash
NVIM_ZED_ICONS=ascii ./nvim-zed/run /path/to/project
```

普通模式按空格，停留 300 毫秒会显示可用快捷键；继续按键执行，Esc 取消。快速连续输入快捷键会直接执行。

`Space q` 汇总语言服务已经报告的诊断，错误优先；输入文字筛选、Ctrl-n/p 或方向键选择、Enter 跳转、Esc 关闭。列表范围取决于语言服务已检查的文件，不保证扫描所有未打开文件。`Space d` 继续查看光标处的诊断详情。

## 启动页

不指定文件时显示项目路径、常用操作和最近 5 个项目文件；不存在的文件和项目外的历史记录不会显示。方向键选择、Enter 执行，也可输入菜单项前的字母编号后按 Enter，例如 `n` + Enter 新建、`r1` + Enter 打开第一项最近文件。

`Ctrl-p` 查找文件、`Space /` 搜索项目、`Ctrl-\` 按需打开终端。取消搜索或隐藏终端会回到启动页。已有文件参数、标准输入内容和未保存内容优先于启动页。

## 配置文件大纲

`Space o` 支持 Python、JSON/JSONC、YAML/YML 和 INI/CFG。Python 使用 ty；其余格式直接解析当前 buffer，无需安装语言服务或 Node，也无需先保存文件。

- JSON、YAML 显示嵌套键和数组元素，例如 `model.parameters.rate`、`items[0].name`；数组编号从 0 开始。
- YAML 多文档用 `doc1`、`doc2` 区分。锚点处的结构可展开；别名、合并键不展开为复制的结构。
- INI/CFG 显示 `[section]` 和 `[section].key`，支持 `=`、`:` 分隔符，忽略注释和缩进的多行值。这里不提供 INI 完整语法校验。
- JSON、YAML 出现未完成语法时会提示，并展示已识别部分；空结构会提示没有可显示内容。

直接输入筛选、Ctrl-n/p 或方向键选择、Enter 跳转、Esc 关闭。重名键会显示完整父路径；字段名有特殊字符时使用括号表示。解析器随包提供，兼容旧 glibc 版本，不需要目标机器编译。

仓库保留了固定版本的语法源码。仅在需要重新编译解析器时运行 `./scripts/build-parsers`，需要 C 编译器；离线包不包含这些构建源码。

## Yazi 和文件切换

`Space e` 打开 Yazi 浮窗，定位当前文件；启动页或无文件名时从项目目录开始。`j/k` 上下选择、`h/l` 切换目录、`f` 筛选、`/` 查找、Enter 在 Neovim 打开选中文件、`q` 取消。选中的多个文件都会加入标签，首个文件显示在编辑区。浮窗关闭后保留原编辑布局，底部 shell 独立运行。

包内包含固定版本的静态 Yazi、ya、浅色配置和按扩展名识别文件的插件，普通浏览和文本预览无需目标机器安装 Yazi 或 file；视频、PDF 等额外预览依赖对应的可选工具。`s` 使用已有 rg 搜索。Yazi 配置在 `config/yazi/`；`NVIM_ZED_ICONS=ascii` 同时适用于编辑器和 Yazi。

Ctrl-Tab / Ctrl-Shift-Tab 按标签顺序循环切换文件，跳过首页、终端和其他临时窗口，并保留未保存内容。插入模式切换后继续插入；从 shell 切换会回到编辑区并保留 shell；在 Yazi 中切换会取消浮窗再切换文件。

终端必须将这两个组合键传给 Neovim，可能需要删除终端自身的同名快捷键。普通 Tab 仍用于缩进或补全；没有配置 F13/F14 转发。Neovim 可识别 CSI-u 编码的 Ctrl-Tab / Ctrl-Shift-Tab（`ESC[9;5u` / `ESC[9;6u`），已通过真实 PTY 输入验证；具体终端是否发送独立编码需要本地确认。`[b` / `]b` 始终保留为普通模式的替代操作。

检查脚本中的真实终端测试会创建临时本地 Unix 套接字，需要系统允许此操作。所有检查仍可在 `unshare -Urn` 下离线运行。
