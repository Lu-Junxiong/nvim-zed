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

## Windows Zed 快捷键

`zed/settings.json` 和 `zed/keymap.json` 保存 Windows Zed 用户配置。Windows 配置应保持为普通文件：指向 WSL 的 Windows 符号链接会导致 Zed 在 WSL 项目中打开设置时出现 I/O 错误，并影响配置监听。

修改仓库配置后，在 Windows PowerShell 中执行以下命令同步到 Windows（不自动同步，无需管理员权限）：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "\\wsl.localhost\Ubuntu\home\lujx\nvim-zed\zed\sync-windows.ps1"
```

在 Zed 中修改配置后，用同一命令加 `-Direction pull` 同步回仓库。同步会用来源覆盖目标，覆盖前保存目标内容为 `.bak-*`；脚本也能将旧符号链接替换为普通文件。两端都有修改时，先比较备份并合并，脚本不会自动合并。

Zed 配置通过 `lsp.ty.settings.diagnosticMode = "off"` 关闭 ty 诊断，保留补全、跳转和悬浮文档；Ruff 检查和格式化仍然启用。上面的路径使用本机 WSL 发行版名 `Ubuntu`，其他机器需替换成自己的发行版名及仓库路径。

Zed 开启 Vim 模式后，以下 `Space` 序列在编辑器普通模式使用：

| 按键 | Windows Zed 操作 |
| --- | --- |
| `jk` | 插入模式退回普通模式 |
| `Ctrl-p` | 搜索文件 |
| `Space e` / `Space o` | 打开并聚焦文件树／大纲；在对应面板再按一次关闭右侧栏并返回编辑器 |
| 文件树中 `yp` / `yP` | 复制选中项的绝对路径／项目相对路径；重命名输入时禁用 |
| `Space /` / `Space s` | 搜索项目／当前文件 |
| `Space b` | 当前分屏的已打开标签列表 |
| `Space w` / `Space x` | 保存／关闭当前标签 |
| `Ctrl-Tab` / `Ctrl-Shift-Tab` | 按标签顺序前后切换，插入模式也可用 |
| `Space rn` / `Space ca` | 重命名／代码操作 |
| `Space f` / `Space ci` | 格式化／整理 imports |
| `Space d` / `Space q` | 悬浮信息（含光标处诊断）／诊断列表 |
| `Space hp` | 展开／收起当前 Git 修改块 |
| `Space j` | 显示可见单词的跳转标签，输入标签跳转；也支持可视模式 |
| `Ctrl-h/j/k/l` | 编辑器普通模式、文件树或大纲中向左／下／上／右切换面板或分屏 |
| `Ctrl-\` | 显示／隐藏终端 |
| 终端中的 `Ctrl-k` | 返回上方编辑区；覆盖 shell 的删除至行尾快捷键 |

文件树里按 `Space o` 切到大纲，大纲里按 `Space e` 切到文件树；文件树重命名输入不拦截这些组合键。大纲默认聚焦符号搜索框，该输入框也支持 `Space o` 关闭、`Space e` 切到文件树、`Ctrl-h` 返回编辑区和 `Ctrl-\` 切换终端。代价是搜索框内连续输入“空格 + o/e”会触发快捷键，单独输入空格可能短暂等待下一键。

文件树和大纲位于右侧，`Ctrl-h` 向左返回编辑区，保留面板显示；重复 `Space e/o` 则关闭右侧栏并返回。若面板仍显示但焦点已经回到编辑器，按对应快捷键会先重新聚焦面板，再按才关闭。`Ctrl-\` 在编辑器、文件树、大纲和终端中均用于切换终端，覆盖编辑器原有的同键分屏绑定。

`gd`、`K`、`[b`/`]b`、`[d`/`]d`、`[c`/`]c`、`gcc`/`gc` 沿用 Zed Vim 默认绑定；`gr` 直接查找引用。保留 Windows 的 `Ctrl-c/v/x/a` 复制、粘贴、剪切和全选习惯，因此这些键覆盖对应的 Vim 操作。

这里按操作意图对齐：Zed 的文件树代替 Yazi，文件内搜索使用搜索栏，修改块预览显示在行内；标签切换可能包含搜索结果等非文件标签。`Space j` 使用 Zed 原生的 Helix 单词标签跳转：直接输入显示的标签，`Esc` 取消；与 Flash 先输入搜索字符的操作不同。Polars 预览、nvitop、Python 环境信息和 Neovim 的 Git 并排差异开关暂未映射。

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
| Python 环境路径与来源 | `Space v` |
| CSV / TSV / Parquet 预览 | `Space p`；Yazi 中 `Ctrl-p` |
| GPU / CPU / 进程监控 | `Space m`；`q` 或 `Esc` 关闭 |
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
- Python 环境按 `NVIM_ZED_PYTHON` → 已激活 virtualenv → 非 base Conda → 项目 `.venv` → Conda base → 启动前 PATH 中的 python3/python 选择。显式路径与已激活 virtualenv 无效时报告错误，不悄悄换环境。
- ty、数据预览和 nvitop 共用这套选择；Python 文件状态栏显示环境名称，`Space v` 查看完整路径与来源，`:ZedInfo` 查看工具与 LSP。选择优先于 ty 配置中的 `environment.python`；其余 ty 项目设置继续生效。
- 指定环境目录或解释器：`NVIM_ZED_PYTHON=/absolute/env/path ./nvim-zed/run /project`。更换环境后重启编辑器；shell 仍继承启动前的环境，不会自动激活上述覆盖路径。
- 各项目首次选定的解释器在本次运行中保持固定，创建或更换 `.venv` 后须重启。无法选择 Python 时 ty 不启动，Ruff 仍可工作。
- `Space o`：Python 使用 ty；JSON/JSONC、YAML/YML、INI/CFG 直接解析未保存内容，无需语言服务或 Node。
- 结构路径包括嵌套键和从 0 开始的数组下标。YAML 多文档用 doc1、doc2 区分，别名不展开；INI 支持节、`=`/`:` 键及缩进多行值，不提供完整语法校验。
- 诊断列表仅包含语言服务已经报告的结果，不保证扫描全部未打开文件。

Git 差异默认比较暂存区；与最新提交比较用 `:Gitsigns diffthis HEAD`。整个仓库状态可在内置终端运行 `git status`、`git diff`。

## 数据、监控与会话

数据预览要求所选 Python 环境已有 Polars（本机验证 1.8.2），不需要 pandas 或 PyArrow。文件中按 `Space p`，或在 Yazi 将光标停在数据文件上按 `Ctrl-p`，可直接打开只读浮窗；目录和其他格式会留在 Yazi 并提示。也可执行 `:ZedPreview /path/to/data.parquet`，避免先加载大文件。`q` / `Esc` 关闭，`Ctrl-Tab` 关闭并切换文件。

预览展示字段、类型、前 50 行和前 20 列；单元格超过 160 字符时截断。CSV 类型按前 50 行推断，默认逗号分隔且有表头；TSV 使用制表符。Parquet 使用文件类型信息和列投影。不统计全表、不修改文件；未保存的编辑不进入预览。采样不等于严格的内存上限，Parquet 行组、CSV 推断和超大单元格仍会产生读取开销；预览超时 15 秒会终止子进程。

`Space m` 打开随包 nvitop，可查看 NVIDIA GPU、显存、CPU、内存和进程；`h` 查看工具帮助，`q` / `Esc` 关闭。需要已有 CPython 3.8+（含 curses）和可用的 NVIDIA 驱动 / NVML。依赖位于 `tools/nvitop/`，仅监控子进程加载，不向研究环境安装包；不包含 Python、CUDA 或驱动。WSL 或旧驱动可能有进程字段显示 N/A；无 GPU / 驱动时浮窗显示工具错误。

退出时自动按启动项目目录保存文件列表、光标和分屏布局，下次仍显示首页。首页选择 `s` 后按 Enter 恢复；命令为 `:ZedSessionRestore`，手动保存为 `:ZedSessionSave`。只访问首页不会覆盖已有会话。存在未保存修改或运行中的内置终端时，先保存并退出终端再恢复。会话不保存未写入磁盘的内容，不重启 shell 或训练进程；状态在 `var/state/nvim-zed/sessions/`，不进入离线包。

## 维护和离线迁移

配置在 config/，版本在 manifest.txt。mini.nvim 仅保留已启用的 8 个模块与对应帮助，nvitop 的 psutil 仅保留 Linux / POSIX 实现。已有 Neovim 配置与项目本地 Neovim 配置不会加载；Neovim 数据写入 var/。终端、Git、rg、ty 和 Ruff 恢复启动前的环境，继续读取原用户配置。

关闭编辑器后移动整个目录即可。重新生成离线包只需：

```bash
./scripts/package
```

打包当前工作目录中的运行内容，输出 nvim-zed-linux-x86_64.tar.gz。包内不含 Git 历史、var/ 编辑记录、测试和构建源码；未提交的配置修改也会打包。

升级离线包时解压到新目录，避免保留已移除的旧插件文件。需要编辑记录时，关闭编辑器后复制旧目录的 `var/`。

仓库保留配置回归检查和固定版本解析器源码。`./tests/check` 在临时目录检查；允许命名空间时可用 `unshare -Urn ./tests/check` 断网验证。真实终端按键检查需要创建本地 Unix 套接字。也可用 `./tests/check /path/to/extracted/nvim-zed` 验证离线包。

带 Polars 的 Python 可用 `ZED_TEST_PYTHON=/absolute/python ./tests/check` 额外检查环境、数据预览、监控浮窗和会话；`python tests/preview.py` 检查真实 CSV / TSV / Parquet 样本与限制。

仅重建解析器时运行 `./scripts/build-parsers`，需要 C 编译器；日常运行不需要编译器。
