# Neovim Zed 风格便携版

Linux x86_64。Atom One Light 配色、顶部文件标签、右侧文件树、底部终端。

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
启动时显示文件树，焦点保留在编辑区；底部终端按需打开。

## 系统要求

- Linux x86_64，glibc >= 2.34，以及系统 libgcc_s.so.1；不适用于 Alpine/musl。
- Bash、GNU coreutils；PATH 中已有 `ty`、`ruff`、`rg`、`git`。
- 支持真彩色的终端；字体和字号在终端里设置，不需要 Nerd Font。
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
| 当前文件大纲（函数、类、方法等） | `Space o` |
| 上一个／下一个文件 | `[b` / `]b` |
| 关闭当前文件 | `Space bd` |
| 保存 | `Space w` 或 `:w` |
| 文件树显示／隐藏 | `Space e` |
| 文件树展开或打开／收起 | `l` / `h` |
| 底部终端显示／隐藏 | `Ctrl-\` |
| 面板左／下／上／右切换 | `Ctrl-h/j/k/l` |
| 终端退出输入模式，可选择、复制输出 | 连按两次 `Esc` |
| 定义／引用／悬浮说明 | `gd` / `gr` / `K` |
| 重命名 | `Space rn` |
| Ruff 格式化 | `Space f` |
| 整理 imports／代码修复菜单 | `Space oi` / `Space ca` |
| 查看诊断 | `Space d` |
| 上一个／下一个诊断 | `[d` / `]d` |
| 上一个／下一个 Git 修改块 | `[c` / `]c` |
| 预览修改块 | `Space hp` |
| 当前文件与 Git 暂存区并排比较 | `Space hd` |
| 关闭差异页，返回编辑布局 | `Space hq` |
| 本说明 | `Space ?` |

搜索窗口：直接输入、`Ctrl-n/p` 或方向键选项、`Enter` 打开、`Esc` 取消。
搜索遵循 rg 的忽略规则，默认不扫描隐藏文件及被忽略目录。
终端隐藏后进程继续运行。面板切换键和 `Ctrl-\` 被编辑器接管；`jk` 不影响 shell。
退出整个 Neovim 会结束内置终端，不会自动保存文件；用 `:wa` 保存所有修改，`:qa` 退出。
Git 差异页默认比较暂存区；也可用 `:Gitsigns diffthis HEAD` 查看与 HEAD 的差异。

## 补全和 Python

- buffer 单词优先，同时提供路径和 ty 语义候选；候选右侧标明 `[buf]`、`[path]`、`[ty]`。
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
运行数据全部写入包内 `var/`；不修改现有 Neovim 配置，也不自动执行项目本地 Neovim 配置。

退出 Neovim 后移动整个目录即可。迁移不需要联网。
发布压缩包不带编辑历史；自己重新打包时，可以在退出后删除 `var/`，清除日志、撤销记录和历史路径。

## 已验证

- 嵌入式终端 UI 实测：布局、面板切换、终端进程保留、jk、补全按键、文件／全文／buffer 搜索。
- 实际 ty + Ruff：双服务诊断、补全、悬浮说明、跨文件跳转／引用／重命名、格式化。
- Python 环境：项目 .venv 自动发现，以及显式指定不同 Conda 环境后的第三方库跳转。
- 临时 Git 仓库：修改标记、修改块导航／预览、并排差异及退出。
- 全新解压到含空格路径，在无网络命名空间中启动并复测交互；旧配置和启动环境隔离。

## 从仓库制作离线包

在仓库目录执行，打包当前已提交版本，不包含运行缓存或 Git 历史：

```bash
git archive --format=tar.gz --prefix=nvim-zed/ -o nvim-zed-linux-x86_64.tar.gz HEAD
```
