# 小组协作详细分工要求

本项目最终交付为 Jekyll 静态网站版简历生成与优化工作台。小组 4 人按 A/B/C/D 分工，每人只在自己的分支和负责文件内修改，避免多人同时改同一文件造成冲突。

## 一、统一工作流程

所有组员第一次拉取项目：

```powershell
git clone https://github.com/xuanxuanwuhh/ai-resume-generator.github.io.git
Set-Location -LiteralPath ".\ai-resume-generator.github.io"
```

每次开始工作前：

```powershell
git checkout main
git pull origin main
```

每位组员创建自己的分支：

```powershell
git checkout -b member-a-docs
git checkout -b member-b-style
git checkout -b member-c-interaction
git checkout -b member-d-runtime
```

提交前必须检查：

```powershell
.\check-jekyll.ps1
git status
```

提交并推送自己的分支：

```powershell
git add .
git commit -m "docs: update project documentation"
git push origin member-a-docs
```

## 二、总协作规则

- 不直接向 `main` 分支提交代码，所有改动都通过个人分支和 Pull Request 合并。
- 每个 Pull Request 只包含自己负责范围内的文件。
- `_site/`、`.jekyll-cache/`、`.sass-cache/` 是生成产物，不能提交。
- 如果确实需要修改别人负责的文件，必须先在群里说明原因，并得到该文件负责人同意。
- 合并顺序建议为 D -> A -> B -> C，最后全员统一验收。
- 提交信息使用固定格式：`docs:`、`style:`、`feat:`、`fix:`、`chore:`。

## 三、组员 A：文档与报告负责人

分支名：`member-a-docs`

主要目标：保证项目说明清楚、复现步骤准确、报告材料完整，方便老师或同学不看代码也能运行和理解项目。

可修改文件：

- `README.md`
- `复现命令.txt`
- `TEAM_WORK_PLAN.md`
- `build_exp5_report.py`
- `report-assets/`

禁止修改：

- `assets/css/style.css`
- `assets/js/app.js`
- `docker-compose.yml`
- `.github/workflows/pages.yml`

具体任务：

- 检查 `README.md` 中本地启动、状态检查、GitHub Pages 预览地址是否准确。
- 整理 `复现命令.txt`，保证命令顺序适合课堂或答辩现场复现。
- 完善报告说明，突出项目功能、技术路线、隐私说明和可复现运行方式。
- 检查截图素材是否对应当前页面，不使用过期界面截图。
- 校对中文文案，避免错别字、乱码和表达不统一。

交付标准：

- 任何组员按照 `README.md` 能独立启动项目。
- 文档中的命令能直接复制执行。
- 报告内容与当前 Jekyll 静态网站版本一致。
- Pull Request 中不包含样式、交互或部署脚本改动。

推荐提交信息：

```text
docs: improve setup and report instructions
docs: update team collaboration plan
```

## 四、组员 B：视觉样式负责人

分支名：`member-b-style`

主要目标：优化页面视觉、响应式布局和打印效果，让入口界面、工作台和简历预览在不同屏幕下都清晰美观。

可修改文件：

- `assets/css/style.css`

原则上不修改，确需新增 class 时先和 C 沟通：

- `index.html`

禁止修改：

- `assets/js/app.js`
- `README.md`
- `docker-compose.yml`
- `.github/workflows/pages.yml`

具体任务：

- 优化入口界面视觉层次，保证“材料场景、模板、主题、语言、进入工作台”一眼可见。
- 检查工作台左右布局，确保表单、预览、评分区不重叠。
- 优化移动端显示，重点检查 375px、768px、桌面宽屏三种宽度。
- 检查 9 个模板和 4 个主题的颜色搭配，保证文字对比度足够。
- 优化打印样式，导出 PDF 时简历主体优先展示，不出现无关控制面板。

交付标准：

- 主页入口界面视觉完整，不被工作台内容遮挡。
- 桌面端和移动端没有文字溢出、按钮重叠、面板错位。
- 主题切换后主要按钮、标签、评分区颜色统一。
- Pull Request 中原则上只包含 `assets/css/style.css`。

推荐提交信息：

```text
style: improve responsive layout
style: polish print and theme styles
```

## 五、组员 C：前端交互负责人

分支名：`member-c-interaction`

主要目标：维护浏览器端交互逻辑，保证入口选择、模板切换、语言切换、本地评分和目标匹配功能稳定。

可修改文件：

- `assets/js/app.js`

原则上不修改，确需改结构时先和 B 沟通：

- `index.html`

禁止修改：

- `assets/css/style.css`
- `README.md`
- `docker-compose.yml`
- `.github/workflows/pages.yml`

具体任务：

- 检查入口界面选择场景、模板、主题和语言后，进入工作台能同步对应状态。
- 检查 URL 参数示例页，例如 `?case=recommendation&template=blue&theme=ember`，能直接进入对应工作台状态。
- 检查中文/英文切换，确保按钮、标题、字段标签、建议区文案能同步切换。
- 检查 9 个模板切换是否都能渲染，不出现空白或 class 残留错误。
- 优化本地规则评分和目标匹配逻辑，保证结果可解释，不伪装成真实大模型。

交付标准：

- 点击“进入工作台”前显示入口界面，点击后进入编辑工作台。
- 场景、模板、主题、语言切换后预览区即时更新。
- 本地匹配和优化建议按钮能正常输出结果。
- Pull Request 中原则上只包含 `assets/js/app.js`。

推荐提交信息：

```text
feat: improve local matching interaction
fix: sync entry selections with workspace
```

## 六、组员 D：运行部署负责人

分支名：`member-d-runtime`

主要目标：保证项目本地能用 Docker 一键跑通，远端能通过 GitHub Pages 自动部署和在线预览。

可修改文件：

- `docker-compose.yml`
- `_config.yml`
- `.github/workflows/pages.yml`
- `start-jekyll.ps1`
- `check-jekyll.ps1`
- `Gemfile`
- `Gemfile.lock`
- `.gitignore`

禁止修改：

- `assets/css/style.css`
- `assets/js/app.js`
- 页面文案和报告内容

具体任务：

- 检查 `.\start-jekyll.ps1` 能清理旧容器、检查端口并启动 Jekyll。
- 检查 `.\check-jekyll.ps1` 能验证主页和 3 个示例 URL 返回 `200`。
- 确认 `_config.yml` 排除了非站点文件，避免 Dockerfile、脚本、报告进入 `_site`。
- 确认 GitHub Pages 工作流能构建并部署。
- 确认线上地址 `https://xuanxuanwuhh.github.io/ai-resume-generator.github.io/` 可访问。

交付标准：

- 本地执行 `.\start-jekyll.ps1` 后能访问 `http://127.0.0.1:4000/`。
- 本地执行 `.\check-jekyll.ps1` 全部通过。
- GitHub Actions 中 Pages 部署为绿色成功状态。
- Pull Request 中不包含页面样式或交互业务逻辑改动。

推荐提交信息：

```text
chore: improve jekyll runtime scripts
fix: update pages deployment workflow
```

## 七、合并与验收安排

合并前每位组员需要在 Pull Request 中写明：

- 本次修改了哪些文件。
- 完成了哪些任务。
- 是否运行了 `.\check-jekyll.ps1`。
- 是否存在需要其他组员注意的地方。

最终验收由全员一起完成：

```powershell
git checkout main
git pull origin main
.\start-jekyll.ps1
.\check-jekyll.ps1
```

最终检查清单：

- 本地主页能打开入口界面。
- 点击“进入工作台”后进入简历编辑界面。
- 4 个材料场景可切换。
- 9 个模板可切换。
- 4 个主题可切换。
- 中文和英文可切换。
- 本地评分、目标匹配、优化建议可用。
- GitHub Pages 在线地址可访问。

## 八、冲突处理办法

- 如果 `git pull` 出现冲突，不要盲目覆盖文件。
- 先用 `git status` 查看冲突文件。
- 只处理自己负责文件内的冲突。
- 如果冲突文件属于别人负责范围，先暂停并联系对应负责人。
- 冲突解决后重新运行 `.\check-jekyll.ps1`，再提交。

## 九、建议时间安排

第一阶段：运行稳定

- D 完成本地启动、检查脚本、Pages 部署确认。

第二阶段：内容完善

- A 完成文档、复现命令和报告说明。

第三阶段：体验优化

- B 完成视觉和响应式样式。
- C 完成交互逻辑检查和小优化。

第四阶段：最终验收

- 四人合并到 `main` 后统一运行本地检查，并确认线上 Pages 地址正常。
