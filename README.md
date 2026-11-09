# nvim-zed

Linux x86_64 终端编辑器：Atom One Light、启动页、文件标签、Yazi 浮窗和按需底部终端。配置、Neovim、Yazi、插件及解析器随包提供，运行时不联网安装。

## 启动

```bash
# 从仓库获取；浅克隆可省去历史版本中的大文件。
git clone --depth 1 https://github.com/Lu-Junxiong/nvim-zed.git
./nvim-zed/run /path/to/project

# 或解压离线包。
tar -xzf nvim-zed-linux-x86_64.tar.gz
./nvim-zed/run /path/to/project
```

也可传入文件：`./nvim-zed/run /path/to/project relative/file.py`。只传目录时显示首页；不传目录时使用当前目录。终端按需创建，不自动启动。

要求 Linux x86_64、glibc >= 2.17、Bash、GNU coreutils，PATH 中已有 ty、Ruff、rg、Git。字体、字号在终端设置；完整图标需要 Nerd Font，字符模式用 `NVIM_ZED_ICONS=ascii ./nvim-zed/run /path/to/project`。

统一使用 Neovim 0.12.5 的 [旧系统兼容构建](https://github.com/neovim/neovim-releases)，Yazi 为静态构建。版本见 manifest.txt。glibc 下限根据二进制符号检查，本机实测 glibc 2.39；未在目标旧系统实测。

## 常用操作

`Space` 表示普通模式先按空格，再按后续键；停留 300 毫秒显示快捷键提示。首页用方向键选择、Enter 执行，或输入菜单编号后按 Enter。最近文件只显示当前项目内的可读文件。

| 操作 | 按键 |
| --- | --- |
| 插入／退出插入模式 | `i` / `jk` 或 `Esc` |
| 搜索文件／项目文本 | `Ctrl-p` / `Space /` |
| 已打开文件列表／当前文件内容搜索 | `Space b` / `Space s` |
| 上一个／下一个文件 | `Ctrl-Shift-Tab` / `Ctrl-Tab`，或 `[b` / `]b` |
| 保存／关闭文件 | `Space w` / `Space x` |
| Yazi 文件浏览器 | `Space e` |
| 单个底部终端显示／隐藏 | `Ctrl-\` |
| 切换面板 | `Ctrl-h/j/k/l`；终端中 `Ctrl-k` 返回编辑区 |
| 终端退出输入模式 | 连按两次 `Esc` |
| 大纲 | `Space o` |
| Flash 跳转 | `Space j`，输入目标字符，再按字母标签；Esc 取消 |
| 定义／引用／悬浮说明 | `gd` / `gr` / `K` |
| 重命名／代码修复菜单 | `Space rn` / `Space ca` |
| Ruff 格式化／整理 imports | `Space f` / `Space ci` |
| 光标处诊断／诊断列表 | `Space d` / `Space q` |
| 上一个／下一个诊断 | `[d` / `]d` |
| 上一个／下一个 Git 修改块 | `[c` / `]c` |
| 修改块预览／并排差异／退出差异页 | `Space hp` / `Space hd` / `Space hq` |
| 当前行／选中多行注释 | `gcc` / `gc` |
| 本说明 | `Space ?` |

搜索列表输入文字筛选、Ctrl-n/p 或方向键选择、Enter 打开、Esc 取消；文本匹配默认为模糊匹配，加单引号前缀可按连续子串匹配。文件搜索遵循 rg 忽略规则。

首次保存新文件需指定名称，例如 `:w example.py`。`:wa` 保存全部文件，`:qa` 退出；未保存内容会阻止退出。`:qa!` 放弃修改退出。返回首页：`:lua require('panels').editor(); MiniStarter.open()`。

Ctrl-Tab 仅循环文件，跳过首页、终端等临时窗口，并保留未保存内容。插入模式切换后继续插入；从 shell 或 Yazi 切换会返回编辑区，shell 进程保留。普通 Tab 继续缩进或补全。Windows Terminal 原生支持需要 1.25+，且需取消终端自身同名绑定；SSH/tmux 链路也须支持独立按键编码。

## Yazi 与终端

`Space e` 定位当前文件；首页则从项目目录开始。`j/k` 选择、`h/l` 切换目录、`f` 筛选、`/` 查找、Enter 在编辑器打开、`q` 取消。`a` 新建文件，名称以 `/` 结尾则新建目录。Yazi 自带浅色和字符图标配置；普通浏览、文本预览不需要另装 Yazi 或 file。视频、PDF 等额外预览依赖系统可选工具。

底部 shell 从项目目录启动，继承 Python 环境。隐藏后进程继续运行；`exit` 后下次按 Ctrl-\ 才新建。退出整个编辑器会结束内置 shell。

## Python、补全与大纲

- ty 负责类型检查、补全、跳转和重命名；Ruff 负责规范检查、格式化和整理 imports。修改均手动触发。
- 补全优先当前文件，再补充已加载的同类型文件，并提供路径和 LSP 候选。Tab 确认，Enter 始终换行；Ctrl-n/p 选择、Ctrl-e 关闭、Ctrl-Space 手动触发。
- ty 自动读取项目配置、已激活 virtualenv/Conda、项目 .venv 和 PATH。可用 `NVIM_ZED_PYTHON=/absolute/env/path ./nvim-zed/run /project` 指定环境；`:ZedInfo` 查看工具与 LSP 信息。
- `Space o`：Python 使用 ty；JSON/JSONC、YAML/YML、INI/CFG 直接解析未保存内容，无需语言服务或 Node。
- 结构路径包括嵌套键和从 0 开始的数组下标。YAML 多文档用 doc1、doc2 区分，别名不展开；INI 支持节、`=`/`:` 键及缩进多行值，不提供完整语法校验。
- 诊断列表仅包含语言服务已经报告的结果，不保证扫描全部未打开文件。

Git 差异默认比较暂存区；与最新提交比较用 `:Gitsigns diffthis HEAD`。整个仓库状态可在内置终端运行 `git status`、`git diff`。

## 维护和离线迁移

配置在 config/，版本在 manifest.txt。已有 Neovim 配置与项目本地 Neovim 配置不会加载；Neovim 数据写入 var/。终端、Git、rg、ty 和 Ruff 恢复启动前的环境，继续读取原用户配置。

关闭编辑器后移动整个目录即可。重新生成离线包只需：

```bash
./scripts/package
```

打包当前工作目录中的运行内容，输出 nvim-zed-linux-x86_64.tar.gz。包内不含 Git 历史、var/ 编辑记录、测试和构建源码；未提交的配置修改也会打包。

仓库保留配置回归检查和固定版本解析器源码。`./tests/check` 在临时目录检查；允许命名空间时可用 `unshare -Urn ./tests/check` 断网验证。真实终端按键检查需要创建本地 Unix 套接字。也可用 `./tests/check /path/to/extracted/nvim-zed` 验证离线包。

仅重建解析器时运行 `./scripts/build-parsers`，需要 C 编译器；日常运行不需要编译器。
