# 简历生成与优化工作台（Jekyll 静态网站版）

本项目由原 Vue/FastAPI 简历生成器改造而来，按《创新实验》期末大作业“静态网站”方向重新实现。项目采用 Jekyll 作为静态站点生成工具，核心交互由原生 HTML、CSS 和 JavaScript 完成。

## 重要说明

- 本版本不在前端直接调用大模型 API。
- 右侧建议区是浏览器本地规则评分和关键词匹配，结果可解释、可离线运行。
- 如果要恢复真实大模型能力，应增加后端代理服务，由后端保存 API Key；不能把密钥写进 Jekyll 静态网页。
- 页面示例使用中性演示数据，不使用真实个人信息。

## 功能模块

- 入口界面：先选择材料场景、模板、主题色和语言，再进入工作台。
- 场景选择：求职、考研、保研、升学。
- 简历编辑：个人信息、教育背景、项目经历、技能奖项。
- 实时预览：编辑内容后即时刷新 A4 简历预览。
- 模板切换：保留 9 个模板选项，对应原项目模板规模。
- 主题切换：极光蓝、森林绿、琥珀橙、学院紫。
- 语言切换：中文 / English。
- 本地规则建议：根据简历完整度、量化表达和目标关键词给出评分与建议。
- 目标匹配：粘贴岗位 JD 或申请要求后进行关键词匹配。
- 导出打印：通过浏览器打印功能导出 PDF。

## 模板数量

原 Vue 项目提供 9 个模板：

```text
modern、blue-gold、sidebar、team-blue-gray、team-classic、
team-modern、team-minimal、team-timeline、team-professional
```

Jekyll 静态版当前提供 9 个模板选项：

```text
现代通用、蓝金正式、侧栏信息、蓝灰团队、经典单栏、
极简投递、时间线项目、专业沉稳、紧凑信息
```

## 技术栈

- 静态网站生成：Jekyll
- 页面结构：HTML / Liquid
- 样式：CSS
- 交互：原生 JavaScript
- 运行验证：Docker + Jekyll

## 运行环境

```powershell
Docker Desktop 29.x 或更高版本
```

本机不需要单独安装 Ruby、Bundler 或 Jekyll，统一通过 Docker 运行。

## 快速启动（推荐）

```powershell
Set-Location -LiteralPath "D:\BiographicalNotes-Jekyll-Final"
.\start-jekyll.ps1
```

脚本会完成以下工作：

- 停止当前项目旧的 Jekyll 容器或临时容器。
- 检查 `4000` 端口是否被其他服务占用。
- 使用 `docker compose up -d` 启动站点。
- 轮询 `http://127.0.0.1:4000/`，确认页面可访问后输出示例地址。

首次启动可能需要下载镜像或安装依赖，等待脚本提示成功即可。

## 状态检查

```powershell
Set-Location -LiteralPath "D:\BiographicalNotes-Jekyll-Final"
.\check-jekyll.ps1
```

检查脚本会确认 Docker 可用、`jekyll` 服务处于运行状态，并验证主页和示例页面全部返回 `200`。

## 小组协作

四人协作分工、分支命名和避免冲突的文件归属见 `TEAM_WORK_PLAN.md`。

## 手动命令

```powershell
Set-Location -LiteralPath "D:\BiographicalNotes-Jekyll-Final"
docker compose up -d
docker compose logs -f jekyll
docker compose down
```

## 访问地址

主页：

```text
http://127.0.0.1:4000/
```

示例页面：

```text
http://127.0.0.1:4000/?case=recommendation&template=blue&theme=ember
http://127.0.0.1:4000/?case=admission&template=sidebar&theme=violet&lang=en
http://127.0.0.1:4000/?case=postgraduate&template=timeline&theme=forest
```

## GitHub Pages 在线预览

仓库已经包含 GitHub Actions 部署配置：`.github/workflows/pages.yml`。

第一次开启 Pages：

1. 打开仓库 `Settings`。
2. 进入 `Pages`。
3. 在 `Build and deployment` 里把 `Source` 选为 `GitHub Actions`。
4. 回到 `Actions`，等待 `Deploy Jekyll site to GitHub Pages` 运行成功。

线上地址：

```text
https://xuanxuanwuhh.github.io/ai-resume-generator.github.io/
```

工作流会在 GitHub Pages 上自动使用仓库名作为 `baseurl`，本地 Docker 运行仍然使用 `http://127.0.0.1:4000/`。
