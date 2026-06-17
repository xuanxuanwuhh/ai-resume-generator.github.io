import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'printing/print_helper.dart' as print_helper;

class ResumeWorkbenchApp extends StatelessWidget {
  const ResumeWorkbenchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resume Workbench',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        scaffoldBackgroundColor: const Color(0xFFF3F6FB),
      ),
      home: const ResumeWorkbenchPage(),
    );
  }
}

class ResumeWorkbenchPage extends StatefulWidget {
  const ResumeWorkbenchPage({super.key});

  @override
  State<ResumeWorkbenchPage> createState() => _ResumeWorkbenchPageState();
}

class _ResumeWorkbenchPageState extends State<ResumeWorkbenchPage> {
  final ResumeData _resume = ResumeData.sample();
  late final TextEditingController _apiBaseController;

  bool _ocrBusy = false;
  String _ocrStatus =
      '成绩单 OCR 通过后端接口调用。阿里云密钥只放在后端 .env，不放在 Jekyll 或 Flutter 前端。';
  String _ocrRawText = '';
  List<CourseCandidate> _ocrCandidates = const [];

  bool get _needsHttpsBackend => kIsWeb && Uri.base.scheme == 'https';

  @override
  void initState() {
    super.initState();
    _apiBaseController = TextEditingController(text: _defaultApiBase());
  }

  @override
  void dispose() {
    _apiBaseController.dispose();
    super.dispose();
  }

  String _defaultApiBase() {
    if (_needsHttpsBackend) {
      return 'https://your-ocr-backend.example.com';
    }
    return 'http://127.0.0.1:8000';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _exportPdf() {
    final didTrigger = print_helper.triggerPrint();
    if (!didTrigger) {
      _showMessage('当前平台不支持浏览器打印。');
    }
  }

  String? _normalizedApiBase() {
    final raw = _apiBaseController.text.trim();
    if (raw.isEmpty) return null;
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  Future<void> _pickTranscriptFile() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg', 'webp'],
    );

    if (picked == null || picked.files.isEmpty) {
      return;
    }

    final file = picked.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      setState(() {
        _ocrStatus = '没有读取到文件内容，请重新选择文件。';
      });
      return;
    }

    final apiBase = _normalizedApiBase();
    if (apiBase == null) {
      setState(() {
        _ocrStatus = '请先填写 OCR 后端地址。';
      });
      return;
    }

    setState(() {
      _ocrBusy = true;
      _ocrStatus = '正在上传成绩单并调用 OCR 接口...';
      _ocrRawText = '';
      _ocrCandidates = const [];
    });

    try {
      final result = await _parseTranscriptWithBackend(
        apiBase: apiBase,
        fileName: file.name,
        bytes: bytes,
      );

      final courses = _sortCourses(result.courses);
      setState(() {
        _ocrBusy = false;
        _ocrStatus = result.message.isEmpty
            ? '识别完成，已按成绩和学分排序。'
            : result.message;
        _ocrRawText = result.rawText;
        _ocrCandidates = [
          for (var i = 0; i < courses.length; i += 1)
            CourseCandidate.fromCourse(
              courses[i],
              selected: i < 6,
            ),
        ];
      });
    } catch (error) {
      setState(() {
        _ocrBusy = false;
        _ocrStatus = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<TranscriptParseResult> _parseTranscriptWithBackend({
    required String apiBase,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final uri = Uri.parse('$apiBase/api/transcript/parse');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'OCR 接口失败 ${response.statusCode}：${body.isEmpty ? '空响应' : body}',
      );
    }

    final decoded = json.decode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('OCR 接口返回格式不正确。');
    }

    return TranscriptParseResult.fromJson(decoded);
  }

  List<CourseEntry> _sortCourses(List<CourseEntry> items) {
    final sorted = [...items];
    sorted.sort((a, b) {
      final scoreDelta = _scoreRank(b.score).compareTo(_scoreRank(a.score));
      if (scoreDelta != 0) return scoreDelta;
      final creditDelta = _creditRank(b.credit).compareTo(_creditRank(a.credit));
      if (creditDelta != 0) return creditDelta;
      return a.name.compareTo(b.name);
    });
    return sorted;
  }

  double _scoreRank(String value) {
    const gradeMap = {
      '优秀': 95.0,
      '良好': 85.0,
      '中等': 75.0,
      '及格': 65.0,
      '合格': 60.0,
      '通过': 60.0,
    };
    if (gradeMap.containsKey(value)) {
      return gradeMap[value]!;
    }
    return double.tryParse(value) ?? 0;
  }

  double _creditRank(String value) {
    return double.tryParse(value) ?? 0;
  }

  void _selectRecommendedCourses() {
    setState(() {
      _ocrCandidates = [
        for (var i = 0; i < _ocrCandidates.length; i += 1)
          _ocrCandidates[i].copyWith(selected: i < 6),
      ];
    });
  }

  void _toggleCandidate(String id, bool selected) {
    setState(() {
      _ocrCandidates = [
        for (final item in _ocrCandidates)
          item.id == id ? item.copyWith(selected: selected) : item,
      ];
    });
  }

  void _appendSelectedCourses() {
    final selected = _ocrCandidates.where((item) => item.selected).toList();
    if (selected.isEmpty) {
      _showMessage('请先勾选要加入简历的课程。');
      return;
    }

    final existingKeys = _resume.courses
        .map((item) => '${item.name}|${item.score}|${item.credit}')
        .toSet();
    var addedCount = 0;

    setState(() {
      for (final item in selected) {
        final key = '${item.name}|${item.score}|${item.credit}';
        if (existingKeys.contains(key)) {
          continue;
        }
        _resume.courses.add(
          CourseEntry(
            id: IdFactory.next(),
            name: item.name,
            score: item.score,
            credit: item.credit,
            note: '',
          ),
        );
        existingKeys.add(key);
        addedCount += 1;
      }
      _ocrCandidates = const [];
    });

    _showMessage('已加入 $addedCount 门课程。');
  }

  void _addEducation() {
    setState(() {
      _resume.educations.add(EducationEntry.empty());
    });
  }

  void _addCourse() {
    setState(() {
      _resume.courses.add(CourseEntry.empty());
    });
  }

  void _addExperience() {
    setState(() {
      _resume.experiences.add(ExperienceEntry.empty());
    });
  }

  void _addProject() {
    setState(() {
      _resume.projects.add(ProjectEntry.empty());
    });
  }

  void _addSkill() {
    setState(() {
      _resume.skills.add(SkillEntry.empty());
    });
  }

  void _addAward() {
    setState(() {
      _resume.awards.add(AwardEntry.empty());
    });
  }

  void _removeById<T extends Identifiable>(List<T> items, String id) {
    setState(() {
      items.removeWhere((item) => item.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'AI 简历工作台',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 2),
            Text(
              'Flutter Web 版：多条经历编辑 + 成绩单 OCR 导入',
              style: TextStyle(fontSize: 13, color: Color(0xFF5B6472)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: FilledButton.icon(
              onPressed: _exportPdf,
              icon: const Icon(Icons.download_outlined),
              label: const Text('导出 PDF'),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 1180;
          final editor = _buildEditorPane();
          final preview = _buildPreviewPane();

          if (stacked) {
            return Column(
              children: [
                Expanded(child: editor),
                const Divider(height: 1),
                Expanded(child: preview),
              ],
            );
          }

          return Row(
            children: [
              SizedBox(width: 460, child: editor),
              const VerticalDivider(width: 1),
              Expanded(child: preview),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEditorPane() {
    return Container(
      color: const Color(0xFFF7F9FC),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              _buildIntroCard(),
              const SizedBox(height: 16),
              _buildPersonalSection(),
              const SizedBox(height: 16),
              _buildEducationSection(),
              const SizedBox(height: 16),
              _buildCourseSection(),
              const SizedBox(height: 16),
              _buildExperienceSection(),
              const SizedBox(height: 16),
              _buildProjectSection(),
              const SizedBox(height: 16),
              _buildSkillSection(),
              const SizedBox(height: 16),
              _buildAwardSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return _surfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '改造说明',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const Text(
            '1. 左侧所有板块都支持新增和删除条目。\n'
            '2. 右侧只保留简历预览，不再显示本地建议和评分。\n'
            '3. 成绩单 OCR 统一走后端接口，前端不保存阿里云密钥。',
            style: TextStyle(height: 1.6, color: Color(0xFF516072)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _needsHttpsBackend
                  ? '当前是 GitHub Pages 在线页面。OCR 后端必须提供 HTTPS 地址，并配置 CORS；本地 http://127.0.0.1:8000 不能直接被线上 https 页面调用。参考密钥配置：D:\\BiographicalNotes\\ai-resume-backend\\.env.example'
                  : '本地调试可直接连接 D:\\BiographicalNotes\\ai-resume-backend，对应密钥配置参考 .env.example。',
              style: const TextStyle(
                color: Color(0xFF214C9A),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalSection() {
    return _sectionCard(
      title: '个人信息',
      subtitle: '单条基础信息，右侧实时预览',
      child: Column(
        children: [
          _textField(
            label: '姓名',
            initialValue: _resume.personal.name,
            onChanged: (value) => setState(() => _resume.personal.name = value),
          ),
          _textField(
            label: '定位标题',
            initialValue: _resume.personal.title,
            onChanged: (value) => setState(() => _resume.personal.title = value),
          ),
          _twoColumns(
            _textField(
              label: '邮箱',
              initialValue: _resume.personal.email,
              onChanged: (value) => setState(() => _resume.personal.email = value),
            ),
            _textField(
              label: '电话',
              initialValue: _resume.personal.phone,
              onChanged: (value) => setState(() => _resume.personal.phone = value),
            ),
          ),
          _textField(
            label: '所在地',
            initialValue: _resume.personal.location,
            onChanged: (value) => setState(() => _resume.personal.location = value),
          ),
          _textField(
            label: '个人简介',
            initialValue: _resume.personal.summary,
            maxLines: 5,
            onChanged: (value) => setState(() => _resume.personal.summary = value),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationSection() {
    return _sectionCard(
      title: '教育经历',
      subtitle: '支持多条教育背景',
      actionLabel: '新增教育',
      onAction: _addEducation,
      child: Column(
        children: [
          for (final item in _resume.educations)
            _entryCard(
              keyValue: item.id,
              title: item.school.isEmpty ? '未命名教育经历' : item.school,
              onRemove: () => _removeById(_resume.educations, item.id),
              child: Column(
                children: [
                  _twoColumns(
                    _textField(
                      label: '学校',
                      initialValue: item.school,
                      onChanged: (value) => setState(() => item.school = value),
                    ),
                    _textField(
                      label: '时间',
                      initialValue: item.period,
                      onChanged: (value) => setState(() => item.period = value),
                    ),
                  ),
                  _twoColumns(
                    _textField(
                      label: '学位',
                      initialValue: item.degree,
                      onChanged: (value) => setState(() => item.degree = value),
                    ),
                    _textField(
                      label: '专业',
                      initialValue: item.major,
                      onChanged: (value) => setState(() => item.major = value),
                    ),
                  ),
                  _textField(
                    label: '亮点说明',
                    initialValue: item.summary,
                    maxLines: 4,
                    onChanged: (value) => setState(() => item.summary = value),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCourseSection() {
    return _sectionCard(
      title: '成绩亮点 / OCR 导入',
      subtitle: '支持手动录入，也支持调用参考项目的成绩单 OCR 接口',
      actionLabel: '新增课程',
      onAction: _addCourse,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: _apiBaseController,
              decoration: InputDecoration(
                labelText: 'OCR 后端地址',
                hintText: _needsHttpsBackend
                    ? 'https://your-ocr-backend.example.com'
                    : 'http://127.0.0.1:8000',
                filled: true,
                fillColor: const Color(0xFFFCFDFE),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: _ocrBusy ? null : _pickTranscriptFile,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(_ocrBusy ? '识别中...' : '上传成绩单'),
              ),
              OutlinedButton.icon(
                onPressed: _ocrCandidates.isEmpty ? null : _selectRecommendedCourses,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('推荐前 6 门'),
              ),
              OutlinedButton.icon(
                onPressed: _ocrCandidates.isEmpty ? null : _appendSelectedCourses,
                icon: const Icon(Icons.playlist_add_outlined),
                label: const Text('加入已选课程'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _ocrStatus,
            style: const TextStyle(color: Color(0xFF516072), height: 1.5),
          ),
          if (_ocrCandidates.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD6DEEA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '识别候选课程',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  for (final item in _ocrCandidates)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: item.selected,
                      onChanged: (value) => _toggleCandidate(item.id, value ?? false),
                      title: Text(item.name),
                      subtitle: Text(
                        '成绩 ${item.score.isEmpty ? "-" : item.score} / 学分 ${item.credit.isEmpty ? "-" : item.credit}',
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (_ocrRawText.isNotEmpty) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: const Text('查看 OCR 原始文本'),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F8FC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD6DEEA)),
                  ),
                  child: SelectableText(
                    _ocrRawText,
                    style: const TextStyle(height: 1.5),
                  ),
                ),
              ],
            ),
          ],
          if (_resume.courses.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final item in _resume.courses)
              _entryCard(
                keyValue: item.id,
                title: item.name.isEmpty ? '未命名课程' : item.name,
                onRemove: () => _removeById(_resume.courses, item.id),
                child: Column(
                  children: [
                    _twoColumns(
                      _textField(
                        label: '课程名称',
                        initialValue: item.name,
                        onChanged: (value) => setState(() => item.name = value),
                      ),
                      _textField(
                        label: '成绩',
                        initialValue: item.score,
                        onChanged: (value) => setState(() => item.score = value),
                      ),
                    ),
                    _twoColumns(
                      _textField(
                        label: '学分',
                        initialValue: item.credit,
                        onChanged: (value) => setState(() => item.credit = value),
                      ),
                      _textField(
                        label: '备注',
                        initialValue: item.note,
                        onChanged: (value) => setState(() => item.note = value),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildExperienceSection() {
    return _sectionCard(
      title: '实习 / 校园经历',
      subtitle: '支持多条经历录入',
      actionLabel: '新增经历',
      onAction: _addExperience,
      child: Column(
        children: [
          for (final item in _resume.experiences)
            _entryCard(
              keyValue: item.id,
              title: item.organization.isEmpty ? '未命名经历' : item.organization,
              onRemove: () => _removeById(_resume.experiences, item.id),
              child: Column(
                children: [
                  _twoColumns(
                    _textField(
                      label: '单位 / 组织',
                      initialValue: item.organization,
                      onChanged: (value) => setState(() => item.organization = value),
                    ),
                    _textField(
                      label: '角色',
                      initialValue: item.role,
                      onChanged: (value) => setState(() => item.role = value),
                    ),
                  ),
                  _textField(
                    label: '时间',
                    initialValue: item.period,
                    onChanged: (value) => setState(() => item.period = value),
                  ),
                  _textField(
                    label: '内容说明',
                    initialValue: item.description,
                    maxLines: 5,
                    onChanged: (value) => setState(() => item.description = value),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectSection() {
    return _sectionCard(
      title: '项目经历',
      subtitle: '支持多条项目输入',
      actionLabel: '新增项目',
      onAction: _addProject,
      child: Column(
        children: [
          for (final item in _resume.projects)
            _entryCard(
              keyValue: item.id,
              title: item.name.isEmpty ? '未命名项目' : item.name,
              onRemove: () => _removeById(_resume.projects, item.id),
              child: Column(
                children: [
                  _twoColumns(
                    _textField(
                      label: '项目名称',
                      initialValue: item.name,
                      onChanged: (value) => setState(() => item.name = value),
                    ),
                    _textField(
                      label: '角色',
                      initialValue: item.role,
                      onChanged: (value) => setState(() => item.role = value),
                    ),
                  ),
                  _textField(
                    label: '时间',
                    initialValue: item.period,
                    onChanged: (value) => setState(() => item.period = value),
                  ),
                  _textField(
                    label: '技术栈 / 关键词',
                    initialValue: item.stack,
                    onChanged: (value) => setState(() => item.stack = value),
                  ),
                  _textField(
                    label: '项目说明',
                    initialValue: item.description,
                    maxLines: 5,
                    onChanged: (value) => setState(() => item.description = value),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSkillSection() {
    return _sectionCard(
      title: '技能清单',
      subtitle: '支持多条技能条目',
      actionLabel: '新增技能',
      onAction: _addSkill,
      child: Column(
        children: [
          for (final item in _resume.skills)
            _entryCard(
              keyValue: item.id,
              title: item.name.isEmpty ? '未命名技能' : item.name,
              onRemove: () => _removeById(_resume.skills, item.id),
              child: Column(
                children: [
                  _twoColumns(
                    _textField(
                      label: '技能名称',
                      initialValue: item.name,
                      onChanged: (value) => setState(() => item.name = value),
                    ),
                    _textField(
                      label: '熟练度',
                      initialValue: item.level,
                      onChanged: (value) => setState(() => item.level = value),
                    ),
                  ),
                  _textField(
                    label: '补充说明',
                    initialValue: item.note,
                    onChanged: (value) => setState(() => item.note = value),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAwardSection() {
    return _sectionCard(
      title: '奖项 / 证书',
      subtitle: '支持多条奖项与证书',
      actionLabel: '新增奖项',
      onAction: _addAward,
      child: Column(
        children: [
          for (final item in _resume.awards)
            _entryCard(
              keyValue: item.id,
              title: item.name.isEmpty ? '未命名奖项' : item.name,
              onRemove: () => _removeById(_resume.awards, item.id),
              child: Column(
                children: [
                  _twoColumns(
                    _textField(
                      label: '名称',
                      initialValue: item.name,
                      onChanged: (value) => setState(() => item.name = value),
                    ),
                    _textField(
                      label: '时间',
                      initialValue: item.date,
                      onChanged: (value) => setState(() => item.date = value),
                    ),
                  ),
                  _textField(
                    label: '颁发方',
                    initialValue: item.issuer,
                    onChanged: (value) => setState(() => item.issuer = value),
                  ),
                  _textField(
                    label: '说明',
                    initialValue: item.description,
                    maxLines: 4,
                    onChanged: (value) => setState(() => item.description = value),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewPane() {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Container(
              padding: const EdgeInsets.fromLTRB(38, 34, 38, 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD8E0EB)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 28,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPreviewHeader(),
                  const SizedBox(height: 24),
                  _previewSection(
                    '个人简介',
                    _resume.personal.summary.trim().isEmpty
                        ? const Text('请在左侧补充个人简介。')
                        : Text(
                            _resume.personal.summary,
                            style: const TextStyle(height: 1.6),
                          ),
                  ),
                  _previewSection(
                    '教育经历',
                    _resume.educations.isEmpty
                        ? const Text('暂无教育经历。')
                        : Column(
                            children: [
                              for (final item in _resume.educations)
                                _previewTimelineCard(
                                  title: item.school.isEmpty ? '未填写学校' : item.school,
                                  meta: [
                                    item.degree,
                                    item.major,
                                    item.period,
                                  ].where((value) => value.trim().isNotEmpty).join(' · '),
                                  body: item.summary,
                                ),
                            ],
                          ),
                  ),
                  _previewSection(
                    '成绩亮点',
                    _resume.courses.isEmpty
                        ? const Text('暂无课程成绩亮点。')
                        : Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final item in _resume.courses)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F7FB),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFD8E0EB)),
                                  ),
                                  child: Text(
                                    [
                                      item.name,
                                      if (item.score.trim().isNotEmpty) '成绩 ${item.score}',
                                      if (item.credit.trim().isNotEmpty) '学分 ${item.credit}',
                                      if (item.note.trim().isNotEmpty) item.note,
                                    ].join(' · '),
                                  ),
                                ),
                            ],
                          ),
                  ),
                  _previewSection(
                    '实习 / 校园经历',
                    _resume.experiences.isEmpty
                        ? const Text('暂无经历。')
                        : Column(
                            children: [
                              for (final item in _resume.experiences)
                                _previewTimelineCard(
                                  title: item.organization.isEmpty ? '未填写组织' : item.organization,
                                  meta: [
                                    item.role,
                                    item.period,
                                  ].where((value) => value.trim().isNotEmpty).join(' · '),
                                  body: item.description,
                                ),
                            ],
                          ),
                  ),
                  _previewSection(
                    '项目经历',
                    _resume.projects.isEmpty
                        ? const Text('暂无项目经历。')
                        : Column(
                            children: [
                              for (final item in _resume.projects)
                                _previewTimelineCard(
                                  title: item.name.isEmpty ? '未填写项目名称' : item.name,
                                  meta: [
                                    item.role,
                                    item.period,
                                    item.stack,
                                  ].where((value) => value.trim().isNotEmpty).join(' · '),
                                  body: item.description,
                                ),
                            ],
                          ),
                  ),
                  _previewSection(
                    '技能清单',
                    _resume.skills.isEmpty
                        ? const Text('暂无技能。')
                        : Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final item in _resume.skills)
                                Chip(
                                  label: Text(
                                    [
                                      item.name,
                                      if (item.level.trim().isNotEmpty) item.level,
                                      if (item.note.trim().isNotEmpty) item.note,
                                    ].where((value) => value.trim().isNotEmpty).join(' · '),
                                  ),
                                  backgroundColor: const Color(0xFFEFF4FF),
                                  side: const BorderSide(color: Color(0xFFD5E1FF)),
                                ),
                            ],
                          ),
                  ),
                  _previewSection(
                    '奖项 / 证书',
                    _resume.awards.isEmpty
                        ? const Text('暂无奖项与证书。')
                        : Column(
                            children: [
                              for (final item in _resume.awards)
                                _previewTimelineCard(
                                  title: item.name.isEmpty ? '未填写名称' : item.name,
                                  meta: [
                                    item.issuer,
                                    item.date,
                                  ].where((value) => value.trim().isNotEmpty).join(' · '),
                                  body: item.description,
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewHeader() {
    final contactItems = [
      _resume.personal.email,
      _resume.personal.phone,
      _resume.personal.location,
    ].where((value) => value.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _resume.personal.name.trim().isEmpty ? '你的姓名' : _resume.personal.name,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A2433),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _resume.personal.title.trim().isEmpty
                        ? '你的定位标题'
                        : _resume.personal.title,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF455468),
                    ),
                  ),
                ],
              ),
            ),
            if (contactItems.isNotEmpty)
              SizedBox(
                width: 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final item in contactItems)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          item,
                          textAlign: TextAlign.right,
                          style: const TextStyle(color: Color(0xFF455468)),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF2F6BFF),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }

  Widget _previewSection(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2F6BFF),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _previewTimelineCard({
    required String title,
    required String meta,
    required String body,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCE4EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (meta.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              meta,
              style: const TextStyle(color: Color(0xFF5A6778)),
            ),
          ],
          if (body.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              body,
              style: const TextStyle(height: 1.6),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required Widget child,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return _surfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF657487),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (actionLabel != null && onAction != null)
                OutlinedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add),
                  label: Text(actionLabel),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _surfaceCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE4EF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _entryCard({
    required String keyValue,
    required String title,
    required VoidCallback onRemove,
    required Widget child,
  }) {
    return Container(
      key: ValueKey(keyValue),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCE4EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                tooltip: '删除',
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }

  Widget _textField({
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: initialValue,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          filled: true,
          fillColor: const Color(0xFFFCFDFE),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _twoColumns(Widget left, Widget right) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(children: [left, right]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

abstract class Identifiable {
  String get id;
}

class ResumeData {
  ResumeData({
    required this.personal,
    required this.educations,
    required this.courses,
    required this.experiences,
    required this.projects,
    required this.skills,
    required this.awards,
  });

  PersonalInfo personal;
  List<EducationEntry> educations;
  List<CourseEntry> courses;
  List<ExperienceEntry> experiences;
  List<ProjectEntry> projects;
  List<SkillEntry> skills;
  List<AwardEntry> awards;

  factory ResumeData.sample() {
    return ResumeData(
      personal: PersonalInfo(
        name: '示例学生',
        title: '计算机方向申请者 / Web 项目实践者',
        email: 'demo@example.com',
        phone: '000-0000-0000',
        location: '上海',
        summary:
            '具备前端开发、静态网站部署和课程项目整理基础，能独立完成需求分析、界面实现、联调验证与交付说明编写，关注结构化表达与可复现交付。',
      ),
      educations: [
        EducationEntry(
          id: IdFactory.next(),
          school: '示例大学',
          degree: '本科',
          major: '计算机类专业',
          period: '2021.09 - 2025.06',
          summary: '核心课程覆盖数据结构、操作系统、数据库与软件工程。',
        ),
      ],
      courses: [
        CourseEntry(
          id: IdFactory.next(),
          name: '数据结构',
          score: '92',
          credit: '4',
          note: '专业核心课',
        ),
      ],
      experiences: [
        ExperienceEntry(
          id: IdFactory.next(),
          organization: '创新实验课程项目组',
          role: '前端开发',
          period: '2024.03 - 2024.06',
          description:
              '负责工作台界面实现、表单交互与静态部署，输出运行说明和功能复现文档。',
        ),
      ],
      projects: [
        ProjectEntry(
          id: IdFactory.next(),
          name: 'AI Resume Generator',
          role: '项目改造',
          period: '2026.06',
          stack: 'Flutter Web / GitHub Pages / FastAPI OCR',
          description:
              '将旧的 Jekyll 静态页升级为 Flutter Web 编辑器，支持多条经历维护、右侧简历预览与成绩单 OCR 导入。',
        ),
      ],
      skills: [
        SkillEntry(
          id: IdFactory.next(),
          name: 'Flutter Web',
          level: '熟练',
          note: '界面搭建与 GitHub Pages 部署',
        ),
        SkillEntry(
          id: IdFactory.next(),
          name: 'FastAPI',
          level: '了解',
          note: '接口联调与 OCR 上传',
        ),
      ],
      awards: [
        AwardEntry(
          id: IdFactory.next(),
          name: '课程项目实践',
          issuer: '创新实验课程',
          date: '2026',
          description: '完成静态站点升级、在线部署与前后端联调。',
        ),
      ],
    );
  }
}

class PersonalInfo {
  PersonalInfo({
    required this.name,
    required this.title,
    required this.email,
    required this.phone,
    required this.location,
    required this.summary,
  });

  String name;
  String title;
  String email;
  String phone;
  String location;
  String summary;
}

class EducationEntry implements Identifiable {
  EducationEntry({
    required this.id,
    required this.school,
    required this.degree,
    required this.major,
    required this.period,
    required this.summary,
  });

  @override
  final String id;
  String school;
  String degree;
  String major;
  String period;
  String summary;

  factory EducationEntry.empty() {
    return EducationEntry(
      id: IdFactory.next(),
      school: '',
      degree: '',
      major: '',
      period: '',
      summary: '',
    );
  }
}

class CourseEntry implements Identifiable {
  CourseEntry({
    required this.id,
    required this.name,
    required this.score,
    required this.credit,
    required this.note,
  });

  @override
  final String id;
  String name;
  String score;
  String credit;
  String note;

  factory CourseEntry.empty() {
    return CourseEntry(
      id: IdFactory.next(),
      name: '',
      score: '',
      credit: '',
      note: '',
    );
  }
}

class ExperienceEntry implements Identifiable {
  ExperienceEntry({
    required this.id,
    required this.organization,
    required this.role,
    required this.period,
    required this.description,
  });

  @override
  final String id;
  String organization;
  String role;
  String period;
  String description;

  factory ExperienceEntry.empty() {
    return ExperienceEntry(
      id: IdFactory.next(),
      organization: '',
      role: '',
      period: '',
      description: '',
    );
  }
}

class ProjectEntry implements Identifiable {
  ProjectEntry({
    required this.id,
    required this.name,
    required this.role,
    required this.period,
    required this.stack,
    required this.description,
  });

  @override
  final String id;
  String name;
  String role;
  String period;
  String stack;
  String description;

  factory ProjectEntry.empty() {
    return ProjectEntry(
      id: IdFactory.next(),
      name: '',
      role: '',
      period: '',
      stack: '',
      description: '',
    );
  }
}

class SkillEntry implements Identifiable {
  SkillEntry({
    required this.id,
    required this.name,
    required this.level,
    required this.note,
  });

  @override
  final String id;
  String name;
  String level;
  String note;

  factory SkillEntry.empty() {
    return SkillEntry(
      id: IdFactory.next(),
      name: '',
      level: '',
      note: '',
    );
  }
}

class AwardEntry implements Identifiable {
  AwardEntry({
    required this.id,
    required this.name,
    required this.issuer,
    required this.date,
    required this.description,
  });

  @override
  final String id;
  String name;
  String issuer;
  String date;
  String description;

  factory AwardEntry.empty() {
    return AwardEntry(
      id: IdFactory.next(),
      name: '',
      issuer: '',
      date: '',
      description: '',
    );
  }
}

class CourseCandidate implements Identifiable {
  const CourseCandidate({
    required this.id,
    required this.name,
    required this.score,
    required this.credit,
    required this.selected,
  });

  factory CourseCandidate.fromCourse(CourseEntry entry, {required bool selected}) {
    return CourseCandidate(
      id: IdFactory.next(),
      name: entry.name,
      score: entry.score,
      credit: entry.credit,
      selected: selected,
    );
  }

  @override
  final String id;
  final String name;
  final String score;
  final String credit;
  final bool selected;

  CourseCandidate copyWith({bool? selected}) {
    return CourseCandidate(
      id: id,
      name: name,
      score: score,
      credit: credit,
      selected: selected ?? this.selected,
    );
  }
}

class TranscriptParseResult {
  TranscriptParseResult({
    required this.message,
    required this.rawText,
    required this.courses,
  });

  final String message;
  final String rawText;
  final List<CourseEntry> courses;

  factory TranscriptParseResult.fromJson(Map<String, dynamic> json) {
    final rawCourses = json['courses'];
    final courses = <CourseEntry>[];

    if (rawCourses is List) {
      for (final item in rawCourses) {
        if (item is! Map) continue;
        final map = item.map((key, value) => MapEntry('$key', value));
        final name = (map['name'] ?? '').toString();
        if (name.trim().isEmpty) continue;
        courses.add(
          CourseEntry(
            id: IdFactory.next(),
            name: name,
            score: (map['score'] ?? '').toString(),
            credit: (map['credit'] ?? '').toString(),
            note: '',
          ),
        );
      }
    }

    return TranscriptParseResult(
      message: (json['message'] ?? '').toString(),
      rawText: (json['rawText'] ?? '').toString(),
      courses: courses,
    );
  }
}

class IdFactory {
  static int _counter = 0;

  static String next() {
    _counter += 1;
    return 'item-${DateTime.now().microsecondsSinceEpoch}-$_counter';
  }
}
