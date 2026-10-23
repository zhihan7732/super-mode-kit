# 超级模式技能集合 1.0.0

这是将本地“超级模式”整理后的可移植 Codex 工作流集合。适用于需要明确规格、实现计划、排错证据和交付验证的软件开发，尤其是设备上位机项目。

## 三分钟安装

1. 将整个压缩包解压到任意目录，保留目录结构。
2. 在该目录打开 PowerShell，执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1
```

3. 重新打开 Codex 或新建聊天，输入：

```text
使用 $max-mode-cn，按超级模式处理当前项目：断线恢复后偶尔重复执行上料步骤。先查证流程和日志，再完成修复及验证。
```

也可以说“超级模式：帮我实现……”。如自然语言没有触发，请使用明确的 `$max-mode-cn`。单纯咨询或诊断只会完成相应分析；明确要求修改时才进入实现。

## 环境与配置

需要可正常使用本地技能和文件工具的 Codex，以及 Windows PowerShell 5.1+ 或跨平台 PowerShell 7+。无需额外 API Key、数据库、MCP、Python 或下载第三方源码。模型、账号和工具权限沿用接收者自己的 Codex 配置。本包不会修改这些设置。

默认安装到 `CODEX_HOME/skills`；未设置 `CODEX_HOME` 时使用当前用户的 `.codex/skills`。这是本包的默认安装约定。若接收端从其他目录发现技能，请显式指定：

```powershell
.\Install.ps1 -SkillsRoot 'D:\Tools\Codex\skills' -ArtifactRoot 'D:\工程计划'
```

macOS/Linux 安装 PowerShell 7 后运行 `pwsh -NoProfile -File ./Install.ps1`。没有 PowerShell 时，可将 `skills/` 下的六个文件夹手动复制到接收端的技能目录，再按 `config.example.json` 配置入口中的 `settings.json`。手动安装应自行备份冲突文件夹。

规格默认写入当前用户的 `Documents/CodexPlans/<项目名>/specs/<任务名>/`。安装时可用 `-ArtifactRoot` 改变根目录；安装后也可编辑 `max-mode-cn/settings.json` 中的 `artifact_root`。路径必须为绝对路径。用户针对任务指定的路径优先。

## 包含内容

| 技能 | 职责 |
| --- | --- |
| max-mode-cn | 中文入口、统一配置、依赖检查 |
| pc-control-max-mode | 核心流程与设备场景检查 |
| speckit | 规格、设计、计划、任务与验收模板 |
| speckit-superpowers-bridge | 规格与实现交接，控制范围漂移 |
| superpowers | 小步实现、系统排错、基于证据验证 |
| gstack | 按需 review、QA、交付准备和复盘 |

这些是基于本地技能整理的自包含工作流说明，并非同名上游项目的官方发行版，也未打包其 CLI、完整源码或插件。不依赖原作者电脑上的源码目录。设备场景已内置；其他“普通模式”“快速模式”和个人学习库不属于本包。

CT-1131A 数据库、客户资料、日志、个人历史记录和账号信息均未打包。需要项目知识库时，由接收者另行配置并显式要求使用；没有知识库也能完成通用流程。数据库写入必须符合该任务授权，不能因启用超级模式而自动写入。

## 检查、更新与恢复

```powershell
.\Test-Package.ps1
.\Install.ps1 -CheckOnly
.\Test-Package.ps1 -InstalledRoot "$env:USERPROFILE\.codex\skills"
```

第一条校验发行文件 SHA-256、技能结构和引用；第二条预览安装位置及冲突，不写文件；第三条核对已安装的六个技能及其配置。设置了 `CODEX_HOME` 或自定义目录时，请传入实际路径。校验清单用于检测意外损坏，不是发行者身份签名。

再次执行安装即更新。所有冲突会在写入前备份到技能根目录旁的 `super-mode-backups/<唯一批次>/`，并保留原有入口配置，除非明确传入 `-ArtifactRoot`。失败时安装器会尝试回滚并报告结果；备份始终保留。恢复旧版时，先关闭使用这些技能的聊天，再将备份内的对应目录复制回原安装位置。安装器只触及本包列出的六个技能，不更改其他技能。

卸载时仅移走这六个已安装文件夹；若原来存在同名技能，请用备份恢复。规格产物和备份不会自动删除。

若技能未出现：确认六个目录分别直接包含 `SKILL.md`，确认实际发现目录，重开聊天并显式调用。若没有设备或测试环境，最终报告必须写出未验证项目，不能把模拟验证描述为现场通过。

## 来源与再分发

来源为分享者现有的本地方法说明，经可移植化改写。外部项目名称仅表示工作流来源方向，不表示官方背书；不包含第三方代码或数据，也不替第三方授予许可证。转发时请保留本说明、完整文件和校验清单；涉及组织内部使用规范时由分享者确认分享权限。

官方技能文档入口：https://developers.openai.com/codex/skills/ 。制作时该站点访问返回 403，故本包不声称已核实所有 Codex 版本的目录发现行为；安装器允许显式指定接收端目录。
