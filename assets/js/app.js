(function () {
  const cases = {
    job: {
      zh: { title: "岗位投递版" },
      en: { title: "Job Application" }
    },
    postgraduate: {
      zh: { title: "考研复试版" },
      en: { title: "Postgraduate Interview" }
    },
    recommendation: {
      zh: { title: "保研申请版" },
      en: { title: "Recommendation Track" }
    },
    admission: {
      zh: { title: "升学申请版" },
      en: { title: "Admission Portfolio" }
    }
  };

  const uiText = {
    zh: {
      entryTitle: "简历生成与优化工作台",
      entryLead: "先选择材料场景、视觉模板、主题色和界面语言，再进入简历生成界面。静态站默认使用本地规则建议，不伪装成真实大模型。",
      entrySections: ["材料场景", "模板与主题", "语言"],
      start: "进入工作台",
      brandTitle: "简历生成与优化工作台",
      brandSub: "Jekyll 静态网站 · 本地多条目编辑",
      privacyTitle: "演示数据",
      privacyText: "页面示例不使用真实个人信息。头像仅在当前浏览器本地预览，不会上传到服务器。",
      caseHeading: "选择材料场景",
      personalHeading: "个人信息",
      educationHeading: "教育经历",
      projectHeading: "项目经历",
      experienceHeading: "实习 / 校园经历",
      skillHeading: "技能清单",
      awardHeading: "奖项 / 证书",
      addEducation: "新增教育",
      addProject: "新增项目",
      addExperience: "新增经历",
      addSkill: "新增技能",
      addAward: "新增奖项",
      preview: "实时预览",
      toolbarTemplate: "模板",
      toolbarTheme: "主题",
      toolbarLanguage: "语言",
      print: "导出 PDF",
      cases: {
        job: "求职",
        postgraduate: "考研",
        recommendation: "保研",
        admission: "升学"
      },
      templates: {
        modern: "现代通用",
        blue: "蓝金正式",
        sidebar: "侧栏信息",
        gray: "蓝灰团队",
        classic: "经典单栏",
        minimal: "极简投递",
        timeline: "时间线项目",
        professional: "专业沉稳",
        compact: "紧凑信息"
      },
      themes: {
        aurora: "极光蓝",
        forest: "森林绿",
        ember: "琥珀橙",
        violet: "学院紫"
      },
      personalFields: {
        name: "姓名",
        title: "定位",
        email: "邮箱",
        phone: "电话",
        location: "所在地",
        avatar: "头像上传",
        summary: "个人简介"
      },
      educationFields: {
        school: "学校",
        major: "专业",
        degree: "学位",
        period: "时间",
        summary: "亮点说明"
      },
      projectFields: {
        name: "项目名称",
        role: "角色",
        period: "时间",
        summary: "项目说明"
      },
      experienceFields: {
        organization: "组织 / 单位",
        role: "岗位",
        period: "时间",
        summary: "经历说明"
      },
      skillFields: {
        name: "技能名称",
        level: "掌握程度"
      },
      awardFields: {
        name: "名称",
        issuer: "颁发方",
        date: "时间",
        summary: "说明"
      },
      emptyEducation: "暂无教育经历。",
      emptyProject: "暂无项目经历。",
      emptyExperience: "暂无实习 / 校园经历。",
      emptySkill: "暂无技能。",
      emptyAward: "暂无奖项 / 证书。",
      emptyEditor: "暂无条目，可点击上方新增。",
      remove: "删除"
    },
    en: {
      entryTitle: "Resume Builder Workspace",
      entryLead: "Choose a scenario, visual template, theme color and interface language before entering the builder. The static site focuses on local editing and print output.",
      entrySections: ["Scenario", "Template & Theme", "Language"],
      start: "Enter Workspace",
      brandTitle: "Resume Builder Workspace",
      brandSub: "Jekyll static site · local multi-entry editing",
      privacyTitle: "Demo Data",
      privacyText: "This page uses demo data. Avatar preview stays in the current browser only.",
      caseHeading: "Choose Scenario",
      personalHeading: "Personal Info",
      educationHeading: "Education",
      projectHeading: "Projects",
      experienceHeading: "Experience",
      skillHeading: "Skills",
      awardHeading: "Awards",
      addEducation: "Add Education",
      addProject: "Add Project",
      addExperience: "Add Experience",
      addSkill: "Add Skill",
      addAward: "Add Award",
      preview: "Live Preview",
      toolbarTemplate: "Template",
      toolbarTheme: "Theme",
      toolbarLanguage: "Language",
      print: "Export PDF",
      cases: {
        job: "Job",
        postgraduate: "Interview",
        recommendation: "Recommendation",
        admission: "Admission"
      },
      templates: {
        modern: "General",
        blue: "Blue-Gold",
        sidebar: "Sidebar",
        gray: "Blue-Gray",
        classic: "Classic",
        minimal: "Minimal",
        timeline: "Timeline",
        professional: "Professional",
        compact: "Compact"
      },
      themes: {
        aurora: "Aurora Blue",
        forest: "Forest Green",
        ember: "Amber",
        violet: "Academic Purple"
      },
      personalFields: {
        name: "Name",
        title: "Target",
        email: "Email",
        phone: "Phone",
        location: "Location",
        avatar: "Avatar Upload",
        summary: "Summary"
      },
      educationFields: {
        school: "School",
        major: "Major",
        degree: "Degree",
        period: "Period",
        summary: "Highlights"
      },
      projectFields: {
        name: "Project",
        role: "Role",
        period: "Period",
        summary: "Description"
      },
      experienceFields: {
        organization: "Organization",
        role: "Role",
        period: "Period",
        summary: "Description"
      },
      skillFields: {
        name: "Skill",
        level: "Level"
      },
      awardFields: {
        name: "Name",
        issuer: "Issuer",
        date: "Date",
        summary: "Description"
      },
      emptyEducation: "No education entries yet.",
      emptyProject: "No project entries yet.",
      emptyExperience: "No experience entries yet.",
      emptySkill: "No skills yet.",
      emptyAward: "No awards yet.",
      emptyEditor: "No entries yet. Use the add button above.",
      remove: "Delete"
    }
  };

  const state = {
    activeCase: "job",
    activeLang: "zh",
    activeTheme: "aurora",
    activeTemplate: "modern",
    avatarUrl: "",
    personal: {
      name: "示例学生",
      title: "计算机方向申请者 / Web 项目实践者",
      email: "demo@example.com",
      phone: "000-0000-0000",
      location: "上海",
      summary:
        "具备 Web 前端、静态网站构建和项目文档整理基础，能够完成从需求分析、界面设计、交互实现到运行验证的完整实践流程。关注材料结构化表达、用户体验、隐私保护和可复现交付。"
    },
    educations: [
      {
        id: nextId(),
        school: "示例大学",
        major: "计算机类专业",
        degree: "本科",
        period: "2021.09 - 2025.06",
        summary: "核心课程覆盖数据结构、操作系统、数据库与软件工程。"
      }
    ],
    projects: [
      {
        id: nextId(),
        name: "Jekyll 简历生成与优化工作台",
        role: "项目改造",
        period: "2026.06",
        summary:
          "基于静态网站技术完成简历工作台重构，支持多条教育、项目、经历、技能和奖项编辑，保留模板切换与 PDF 打印。"
      }
    ],
    experiences: [
      {
        id: nextId(),
        organization: "创新实验课程项目组",
        role: "前端开发",
        period: "2024.03 - 2024.06",
        summary: "负责工作台界面实现、表单交互与静态部署，输出运行说明和功能复现文档。"
      }
    ],
    skills: [
      { id: nextId(), name: "HTML / CSS / JavaScript", level: "熟练" },
      { id: nextId(), name: "Jekyll", level: "熟练" },
      { id: nextId(), name: "文档写作", level: "良好" }
    ],
    awards: [
      {
        id: nextId(),
        name: "创新实验课程项目实践",
        issuer: "课程项目组",
        date: "2026",
        summary: "完成静态站点升级、在线部署与本地交互改造。"
      }
    ]
  };

  const appShell = document.querySelector("#appShell");
  const entryScreen = document.querySelector("#entryScreen");
  const startBtn = document.querySelector("#startBtn");
  const entryCaseButtons = Array.from(document.querySelectorAll("[data-entry-case]"));
  const caseButtons = Array.from(document.querySelectorAll("[data-case]"));
  const themeDots = Array.from(document.querySelectorAll("[data-theme-choice]"));
  const langButtons = Array.from(document.querySelectorAll("[data-lang-choice]"));
  const entryTemplate = document.querySelector("#entryTemplate");
  const templateSelect = document.querySelector("#templateSelect");
  const themeSelect = document.querySelector("#themeSelect");
  const languageSelect = document.querySelector("#languageSelect");
  const printBtn = document.querySelector("#printBtn");

  const personalInputs = {
    name: document.querySelector("#nameInput"),
    title: document.querySelector("#titleInput"),
    email: document.querySelector("#emailInput"),
    phone: document.querySelector("#phoneInput"),
    location: document.querySelector("#locationInput"),
    summary: document.querySelector("#summaryInput"),
    avatar: document.querySelector("#avatarInput")
  };

  const previewNodes = {
    name: document.querySelector("#previewName"),
    title: document.querySelector("#previewTitle"),
    email: document.querySelector("#previewEmail"),
    phone: document.querySelector("#previewPhone"),
    location: document.querySelector("#previewLocation"),
    summary: document.querySelector("#previewSummary"),
    avatar: document.querySelector("#avatarPreview"),
    educations: document.querySelector("#previewEducations"),
    projects: document.querySelector("#previewProjects"),
    experiences: document.querySelector("#previewExperiences"),
    skills: document.querySelector("#previewSkills"),
    awards: document.querySelector("#previewAwards"),
    caseTitle: document.querySelector("#caseTitle"),
    paper: document.querySelector("#resumePaper")
  };

  const listMounts = {
    educations: document.querySelector("#educationList"),
    projects: document.querySelector("#projectList"),
    experiences: document.querySelector("#experienceList"),
    skills: document.querySelector("#skillList"),
    awards: document.querySelector("#awardList")
  };

  const addButtons = {
    educations: document.querySelector("#addEducationBtn"),
    projects: document.querySelector("#addProjectBtn"),
    experiences: document.querySelector("#addExperienceBtn"),
    skills: document.querySelector("#addSkillBtn"),
    awards: document.querySelector("#addAwardBtn")
  };

  const sectionConfig = {
    educations: {
      title: (item) => item.school || ui().educationHeading,
      fields: ["school", "major", "degree", "period", "summary"]
    },
    projects: {
      title: (item) => item.name || ui().projectHeading,
      fields: ["name", "role", "period", "summary"]
    },
    experiences: {
      title: (item) => item.organization || ui().experienceHeading,
      fields: ["organization", "role", "period", "summary"]
    },
    skills: {
      title: (item) => item.name || ui().skillHeading,
      fields: ["name", "level"]
    },
    awards: {
      title: (item) => item.name || ui().awardHeading,
      fields: ["name", "issuer", "date", "summary"]
    }
  };

  function nextId() {
    return `item-${Date.now()}-${Math.random().toString(16).slice(2, 8)}`;
  }

  function ui() {
    return uiText[state.activeLang];
  }

  function emptyEducation() {
    return { id: nextId(), school: "", major: "", degree: "", period: "", summary: "" };
  }

  function emptyProject() {
    return { id: nextId(), name: "", role: "", period: "", summary: "" };
  }

  function emptyExperience() {
    return { id: nextId(), organization: "", role: "", period: "", summary: "" };
  }

  function emptySkill() {
    return { id: nextId(), name: "", level: "" };
  }

  function emptyAward() {
    return { id: nextId(), name: "", issuer: "", date: "", summary: "" };
  }

  function setTheme(theme) {
    state.activeTheme = ["aurora", "forest", "ember", "violet"].includes(theme) ? theme : "aurora";
    document.body.dataset.theme = state.activeTheme;
    themeDots.forEach((button) => {
      button.classList.toggle("active", button.dataset.themeChoice === state.activeTheme);
    });
    themeSelect.value = state.activeTheme;
  }

  function setLanguage(lang) {
    state.activeLang = lang === "en" ? "en" : "zh";
    document.body.dataset.lang = state.activeLang;
    languageSelect.value = state.activeLang;
    langButtons.forEach((button) => {
      button.classList.toggle("active", button.dataset.langChoice === state.activeLang);
    });
    applyUiLanguage();
    renderEditor();
    renderPreview();
  }

  function setTemplate(template) {
    const supported = ["modern", "blue", "sidebar", "gray", "classic", "minimal", "timeline", "professional", "compact"];
    state.activeTemplate = supported.includes(template) ? template : "modern";
    templateSelect.value = state.activeTemplate;
    entryTemplate.value = state.activeTemplate;
    previewNodes.paper.className = `resume-paper template-${state.activeTemplate}`;
  }

  function setCase(nextCase) {
    state.activeCase = cases[nextCase] ? nextCase : "job";
    caseButtons.forEach((button) => {
      button.classList.toggle("active", button.dataset.case === state.activeCase);
    });
    entryCaseButtons.forEach((button) => {
      button.classList.toggle("active", button.dataset.entryCase === state.activeCase);
    });
    renderPreview();
  }

  function applyUiLanguage() {
    const text = ui();
    document.documentElement.lang = state.activeLang === "en" ? "en" : "zh-CN";
    document.querySelector(".entry-copy h1").textContent = text.entryTitle;
    document.querySelector(".entry-copy p").textContent = text.entryLead;
    document.querySelectorAll(".entry-section h2").forEach((node, index) => {
      node.textContent = text.entrySections[index] || node.textContent;
    });
    document.querySelector(".brand h1").textContent = text.brandTitle;
    document.querySelector(".brand p").textContent = text.brandSub;
    document.querySelector(".privacy-note strong").textContent = text.privacyTitle;
    document.querySelector(".privacy-note span").textContent = text.privacyText;
    document.querySelectorAll(".control-pane .panel-title h2")[0].textContent = text.caseHeading;
    document.querySelectorAll(".control-pane .panel-title h2")[1].textContent = text.personalHeading;
    document.querySelectorAll(".control-pane .panel-title h2")[2].textContent = text.educationHeading;
    document.querySelectorAll(".control-pane .panel-title h2")[3].textContent = text.projectHeading;
    document.querySelectorAll(".control-pane .panel-title h2")[4].textContent = text.experienceHeading;
    document.querySelectorAll(".control-pane .panel-title h2")[5].textContent = text.skillHeading;
    document.querySelectorAll(".control-pane .panel-title h2")[6].textContent = text.awardHeading;
    document.querySelector(".eyebrow").textContent = text.preview;
    printBtn.textContent = text.print;
    startBtn.textContent = text.start;
    addButtons.educations.textContent = text.addEducation;
    addButtons.projects.textContent = text.addProject;
    addButtons.experiences.textContent = text.addExperience;
    addButtons.skills.textContent = text.addSkill;
    addButtons.awards.textContent = text.addAward;
    entryCaseButtons.forEach((button) => {
      button.textContent = text.cases[button.dataset.entryCase];
    });
    caseButtons.forEach((button) => {
      button.textContent = text.cases[button.dataset.case];
    });

    setOptionText(entryTemplate, text.templates);
    setOptionText(templateSelect, text.templates);
    setOptionText(themeSelect, text.themes);

    const personalLabels = document.querySelectorAll("#nameInput, #titleInput, #emailInput, #phoneInput, #locationInput, #avatarInput, #summaryInput");
    personalLabels.forEach((input) => {
      const label = input.closest("label");
      if (!label) return;
      const mapping = {
        nameInput: text.personalFields.name,
        titleInput: text.personalFields.title,
        emailInput: text.personalFields.email,
        phoneInput: text.personalFields.phone,
        locationInput: text.personalFields.location,
        avatarInput: text.personalFields.avatar,
        summaryInput: text.personalFields.summary
      };
      replaceLabelText(label, mapping[input.id]);
    });
  }

  function replaceLabelText(label, value) {
    const textNode = Array.from(label.childNodes).find((node) => node.nodeType === Node.TEXT_NODE && node.textContent.trim());
    if (textNode) {
      textNode.textContent = `\n            ${value}\n            `;
    }
  }

  function setOptionText(select, labels) {
    Array.from(select.options).forEach((option) => {
      if (labels[option.value]) {
        option.textContent = labels[option.value];
      }
    });
  }

  function renderEditor() {
    renderSectionList("educations", ui().educationFields);
    renderSectionList("projects", ui().projectFields);
    renderSectionList("experiences", ui().experienceFields);
    renderSectionList("skills", ui().skillFields);
    renderSectionList("awards", ui().awardFields);
  }

  function renderSectionList(sectionName, labels) {
    const mount = listMounts[sectionName];
    const items = state[sectionName];
    mount.innerHTML = "";

    if (!items.length) {
      const empty = document.createElement("div");
      empty.className = "entry-empty";
      empty.textContent = ui().emptyEditor;
      mount.appendChild(empty);
      return;
    }

    items.forEach((item, index) => {
      const wrapper = document.createElement("div");
      wrapper.className = "entry-item";
      wrapper.innerHTML = `
        <div class="entry-item-head">
          <strong>${escapeHtml(sectionConfig[sectionName].title(item))}</strong>
          <button class="entry-item-remove" type="button" data-section="${sectionName}" data-id="${item.id}" aria-label="${ui().remove}">&times;</button>
        </div>
        <div class="entry-item-grid"></div>
      `;

      const grid = wrapper.querySelector(".entry-item-grid");
      sectionConfig[sectionName].fields.forEach((field) => {
        const label = document.createElement("label");
        if (field === "summary") {
          label.className = "wide";
        }
        label.innerHTML = `${labels[field]}
          ${field === "summary"
            ? `<textarea rows="4" data-section="${sectionName}" data-id="${item.id}" data-field="${field}">${escapeHtml(item[field] || "")}</textarea>`
            : `<input value="${escapeAttribute(item[field] || "")}" data-section="${sectionName}" data-id="${item.id}" data-field="${field}">`
          }`;
        grid.appendChild(label);
      });

      mount.appendChild(wrapper);
    });
  }

  function renderPreview() {
    previewNodes.name.textContent = state.personal.name || "";
    previewNodes.title.textContent = state.personal.title || "";
    previewNodes.email.textContent = state.personal.email || "";
    previewNodes.phone.textContent = state.personal.phone || "";
    previewNodes.location.textContent = state.personal.location || "";
    previewNodes.summary.textContent = state.personal.summary || "";
    previewNodes.caseTitle.textContent = cases[state.activeCase][state.activeLang].title;

    if (state.avatarUrl) {
      previewNodes.avatar.style.backgroundImage = `url("${state.avatarUrl}")`;
      previewNodes.avatar.classList.remove("is-hidden");
    } else {
      previewNodes.avatar.style.backgroundImage = "";
      previewNodes.avatar.classList.add("is-hidden");
    }

    renderPreviewCards(previewNodes.educations, state.educations, ui().emptyEducation, (item) => `
      <strong>${escapeHtml(item.school || "")}</strong>
      <small>${escapeHtml([item.degree, item.major, item.period].filter(Boolean).join(" · "))}</small>
      <div>${escapeHtml(item.summary || "")}</div>
    `);
    renderPreviewCards(previewNodes.projects, state.projects, ui().emptyProject, (item) => `
      <strong>${escapeHtml(item.name || "")}</strong>
      <small>${escapeHtml([item.role, item.period].filter(Boolean).join(" · "))}</small>
      <div>${escapeHtml(item.summary || "")}</div>
    `);
    renderPreviewCards(previewNodes.experiences, state.experiences, ui().emptyExperience, (item) => `
      <strong>${escapeHtml(item.organization || "")}</strong>
      <small>${escapeHtml([item.role, item.period].filter(Boolean).join(" · "))}</small>
      <div>${escapeHtml(item.summary || "")}</div>
    `);
    renderPreviewCards(previewNodes.awards, state.awards, ui().emptyAward, (item) => `
      <strong>${escapeHtml(item.name || "")}</strong>
      <small>${escapeHtml([item.issuer, item.date].filter(Boolean).join(" · "))}</small>
      <div>${escapeHtml(item.summary || "")}</div>
    `);

    previewNodes.skills.innerHTML = "";
    if (state.skills.length === 0) {
      previewNodes.skills.textContent = ui().emptySkill;
    } else {
      state.skills.forEach((item) => {
        const tag = document.createElement("span");
        tag.textContent = [item.name, item.level].filter(Boolean).join(" · ");
        previewNodes.skills.appendChild(tag);
      });
    }
  }

  function renderPreviewCards(mount, items, emptyText, template) {
    mount.innerHTML = "";
    if (!items.length) {
      mount.textContent = emptyText;
      return;
    }
    items.forEach((item) => {
      const card = document.createElement("article");
      card.className = "preview-card";
      card.innerHTML = template(item);
      mount.appendChild(card);
    });
  }

  function escapeHtml(value) {
    return String(value)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;");
  }

  function escapeAttribute(value) {
    return escapeHtml(value).replaceAll('"', "&quot;");
  }

  function enterWorkspace() {
    entryScreen.classList.add("is-hidden");
    appShell.classList.remove("is-hidden");
    setCase(state.activeCase);
    setTheme(state.activeTheme);
    setTemplate(state.activeTemplate);
    setLanguage(state.activeLang);
    renderEditor();
    renderPreview();
  }

  function bindEvents() {
    entryCaseButtons.forEach((button) => {
      button.addEventListener("click", () => setCase(button.dataset.entryCase));
    });
    caseButtons.forEach((button) => {
      button.addEventListener("click", () => setCase(button.dataset.case));
    });
    themeDots.forEach((button) => {
      button.addEventListener("click", () => setTheme(button.dataset.themeChoice));
    });
    langButtons.forEach((button) => {
      button.addEventListener("click", () => setLanguage(button.dataset.langChoice));
    });

    entryTemplate.addEventListener("change", () => setTemplate(entryTemplate.value));
    templateSelect.addEventListener("change", () => setTemplate(templateSelect.value));
    themeSelect.addEventListener("change", () => setTheme(themeSelect.value));
    languageSelect.addEventListener("change", () => setLanguage(languageSelect.value));
    startBtn.addEventListener("click", enterWorkspace);
    printBtn.addEventListener("click", () => window.print());

    Object.entries(personalInputs).forEach(([key, input]) => {
      if (key === "avatar") {
        input.addEventListener("change", onAvatarChange);
        return;
      }
      input.addEventListener("input", () => {
        state.personal[key] = input.value;
        renderPreview();
      });
    });

    listMounts.educations.addEventListener("input", onSectionInput);
    listMounts.projects.addEventListener("input", onSectionInput);
    listMounts.experiences.addEventListener("input", onSectionInput);
    listMounts.skills.addEventListener("input", onSectionInput);
    listMounts.awards.addEventListener("input", onSectionInput);

    Object.values(listMounts).forEach((mount) => {
      mount.addEventListener("click", onRemoveEntry);
    });

    addButtons.educations.addEventListener("click", () => {
      state.educations.push(emptyEducation());
      renderEditor();
      renderPreview();
    });
    addButtons.projects.addEventListener("click", () => {
      state.projects.push(emptyProject());
      renderEditor();
      renderPreview();
    });
    addButtons.experiences.addEventListener("click", () => {
      state.experiences.push(emptyExperience());
      renderEditor();
      renderPreview();
    });
    addButtons.skills.addEventListener("click", () => {
      state.skills.push(emptySkill());
      renderEditor();
      renderPreview();
    });
    addButtons.awards.addEventListener("click", () => {
      state.awards.push(emptyAward());
      renderEditor();
      renderPreview();
    });
  }

  function onSectionInput(event) {
    const target = event.target;
    if (!target.matches("[data-section][data-id][data-field]")) return;
    const section = target.dataset.section;
    const id = target.dataset.id;
    const field = target.dataset.field;
    const item = state[section].find((entry) => entry.id === id);
    if (!item) return;
    item[field] = target.value;
    const titleNode = target.closest(".entry-item")?.querySelector(".entry-item-head strong");
    if (titleNode) {
      titleNode.textContent = sectionConfig[section].title(item);
    }
    renderPreview();
  }

  function onRemoveEntry(event) {
    const button = event.target.closest(".entry-item-remove");
    if (!button) return;
    const section = button.dataset.section;
    const id = button.dataset.id;
    if (!state[section]) return;
    state[section] = state[section].filter((item) => item.id !== id);
    renderEditor();
    renderPreview();
  }

  function onAvatarChange(event) {
    const file = event.target.files && event.target.files[0];
    if (!file) {
      state.avatarUrl = "";
      renderPreview();
      return;
    }
    const reader = new FileReader();
    reader.onload = () => {
      state.avatarUrl = reader.result;
      renderPreview();
    };
    reader.readAsDataURL(file);
  }

  function syncInputsFromState() {
    personalInputs.name.value = state.personal.name;
    personalInputs.title.value = state.personal.title;
    personalInputs.email.value = state.personal.email;
    personalInputs.phone.value = state.personal.phone;
    personalInputs.location.value = state.personal.location;
    personalInputs.summary.value = state.personal.summary;
  }

  function init() {
    bindEvents();
    syncInputsFromState();

    const params = new URLSearchParams(window.location.search);
    const initialCase = params.get("case");
    const initialTemplate = params.get("template");
    const initialTheme = params.get("theme");
    const initialLang = params.get("lang");

    if (initialCase && cases[initialCase]) state.activeCase = initialCase;
    if (initialTemplate) state.activeTemplate = initialTemplate;
    if (initialTheme) state.activeTheme = initialTheme;
    if (initialLang === "en" || initialLang === "zh") state.activeLang = initialLang;

    applyUiLanguage();
    renderEditor();
    renderPreview();

    if (window.location.search) {
      enterWorkspace();
    }
  }

  init();
})();
