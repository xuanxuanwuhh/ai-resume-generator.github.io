import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ResumeWorkbenchApp extends StatelessWidget {
  const ResumeWorkbenchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Resume Workbench',
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
  final ImagePicker _imagePicker = ImagePicker();
  ResumeTemplate _template = ResumeTemplate.modern;
  int _mobileTabIndex = 0;
  bool _isExportingPdf = false;
  bool _isLocating = false;

  Future<void> _exportPdf() async {
    if (_isExportingPdf) return;

    setState(() {
      _isExportingPdf = true;
    });

    try {
      final bytes = await _buildPdfDocument();
      await Printing.layoutPdf(onLayout: (_) async => bytes);
      if (!mounted) return;
      _showMessage('已打开 PDF 导出 / 打印面板。');
    } catch (error) {
      if (!mounted) return;
      _showMessage('导出 PDF 失败：$error');
    } finally {
      if (mounted) {
        setState(() {
          _isExportingPdf = false;
        });
      }
    }
  }

  Future<void> _sharePdf() async {
    try {
      final bytes = await _buildPdfDocument();
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${_resume.personal.name.trim().isEmpty ? 'resume' : _resume.personal.name.trim()}-resume.pdf',
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage('分享 PDF 失败：$error');
    }
  }

  Future<void> _fillCurrentLocation() async {
    if (_isLocating) return;

    setState(() {
      _isLocating = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('请先打开系统定位服务。');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage('未获得定位权限，已保留手动填写地址方式。');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final mark = placemarks.isNotEmpty ? placemarks.first : null;
      final administrativeArea = mark?.administrativeArea?.trim();
      final locality = mark?.locality?.trim();
      final subLocality = mark?.subLocality?.trim();
      final pieces = <String>[];
      if (administrativeArea != null && administrativeArea.isNotEmpty) {
        pieces.add(administrativeArea);
      }
      if (locality != null && locality.isNotEmpty && locality != administrativeArea) {
        pieces.add(locality);
      }
      if (subLocality != null && subLocality.isNotEmpty) {
        pieces.add(subLocality);
      }

      final text = pieces.isEmpty ? '当前位置' : pieces.join(' ');

      setState(() {
        _resume.personal.location = text;
      });

      _showMessage('已填入当前位置：$text');
    } catch (error) {
      _showMessage('获取当前位置失败，请手动填写地址。');
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1600,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      setState(() {
        _resume.personal.avatarBytes = bytes;
      });
    } catch (error) {
      if (!mounted) return;
      _showMessage('头像读取失败：$error');
    }
  }

  void _removeAvatar() {
    setState(() {
      _resume.personal.avatarBytes = null;
    });
  }

  void _showAvatarOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('拍照上传'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickAvatar(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('从相册选择'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickAvatar(ImageSource.gallery);
                  },
                ),
                if (_resume.personal.avatarBytes != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('移除头像'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _removeAvatar();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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

  Future<Uint8List> _buildPdfDocument() async {
    final pdf = pw.Document();
    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    pw.TextStyle sectionStyle() => pw.TextStyle(
          font: boldFont,
          fontSize: 14,
          color: PdfColor.fromInt(_template.theme.sectionColor.toARGB32()),
        );

    pw.TextStyle bodyStyle() => pw.TextStyle(
          font: baseFont,
          fontSize: 10.5,
          lineSpacing: 4,
          color: PdfColor.fromInt(_template.theme.bodyColor.toARGB32()),
        );

    pw.Widget sectionTitle(String title) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(top: 14, bottom: 8),
        child: pw.Text(title, style: sectionStyle()),
      );
    }

    pw.Widget timelineCard({
      required String title,
      required String meta,
      required String body,
    }) {
      return pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(bottom: 8),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(_template.theme.surfaceColor.toARGB32()),
          border: pw.Border.all(
            color: PdfColor.fromInt(_template.theme.borderColor.toARGB32()),
          ),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(font: boldFont, fontSize: 11.5),
            ),
            if (meta.trim().isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 3),
                child: pw.Text(
                  meta,
                  style: pw.TextStyle(
                    font: baseFont,
                    fontSize: 9.2,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            if (body.trim().isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 6),
                child: pw.Text(body, style: bodyStyle()),
              ),
          ],
        ),
      );
    }

    final avatarProvider = _resume.personal.avatarBytes == null
        ? null
        : pw.MemoryImage(_resume.personal.avatarBytes!);

    final contactItems = [
      _resume.personal.email,
      _resume.personal.phone,
      _resume.personal.location,
    ].where((value) => value.trim().isNotEmpty).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(34, 30, 34, 32),
        build: (context) {
          return [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (avatarProvider != null)
                  pw.Container(
                    width: 72,
                    height: 72,
                    margin: const pw.EdgeInsets.only(right: 16),
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(16),
                      image: pw.DecorationImage(
                        image: avatarProvider,
                        fit: pw.BoxFit.cover,
                      ),
                    ),
                  ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _resume.personal.name.trim().isEmpty ? '你的姓名' : _resume.personal.name,
                        style: pw.TextStyle(font: boldFont, fontSize: 24),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        _resume.personal.title.trim().isEmpty
                            ? '你的定位标题'
                            : _resume.personal.title,
                        style: pw.TextStyle(
                          font: baseFont,
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (contactItems.isNotEmpty)
                  pw.Container(
                    width: 160,
                    alignment: pw.Alignment.topRight,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        for (final item in contactItems)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 4),
                            child: pw.Text(
                              item,
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                font: baseFont,
                                fontSize: 9.5,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              height: 3,
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(_template.theme.accentColor.toARGB32()),
                borderRadius: pw.BorderRadius.circular(999),
              ),
            ),
            sectionTitle('个人简介'),
            pw.Text(
              _resume.personal.summary.trim().isEmpty ? '请补充个人简介。' : _resume.personal.summary,
              style: bodyStyle(),
            ),
            sectionTitle('教育经历'),
            if (_resume.educations.isEmpty)
              pw.Text('暂无教育经历。', style: bodyStyle())
            else
              ..._resume.educations.map(
                (item) => timelineCard(
                  title: item.school.isEmpty ? '未填写学校' : item.school,
                  meta: [
                    item.degree,
                    item.major,
                    item.period,
                  ].where((value) => value.trim().isNotEmpty).join(' · '),
                  body: item.summary,
                ),
              ),
            sectionTitle('课程 / 成绩亮点'),
            if (_resume.courses.isEmpty)
              pw.Text('暂无课程成绩亮点。', style: bodyStyle())
            else
              pw.Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in _resume.courses)
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(_template.theme.chipColor.toARGB32()),
                        borderRadius: pw.BorderRadius.circular(16),
                      ),
                      child: pw.Text(
                        [
                          item.name,
                          if (item.score.trim().isNotEmpty) '成绩 ${item.score}',
                          if (item.credit.trim().isNotEmpty) '学分 ${item.credit}',
                          if (item.note.trim().isNotEmpty) item.note,
                        ].where((value) => value.trim().isNotEmpty).join(' · '),
                        style: pw.TextStyle(font: baseFont, fontSize: 9.3),
                      ),
                    ),
                ],
              ),
            sectionTitle('实习 / 校园经历'),
            if (_resume.experiences.isEmpty)
              pw.Text('暂无经历。', style: bodyStyle())
            else
              ..._resume.experiences.map(
                (item) => timelineCard(
                  title: item.organization.isEmpty ? '未填写组织' : item.organization,
                  meta: [item.role, item.period]
                      .where((value) => value.trim().isNotEmpty)
                      .join(' · '),
                  body: item.description,
                ),
              ),
            sectionTitle('项目经历'),
            if (_resume.projects.isEmpty)
              pw.Text('暂无项目经历。', style: bodyStyle())
            else
              ..._resume.projects.map(
                (item) => timelineCard(
                  title: item.name.isEmpty ? '未填写项目名称' : item.name,
                  meta: [item.role, item.period, item.stack]
                      .where((value) => value.trim().isNotEmpty)
                      .join(' · '),
                  body: item.description,
                ),
              ),
            sectionTitle('技能清单'),
            if (_resume.skills.isEmpty)
              pw.Text('暂无技能。', style: bodyStyle())
            else
              pw.Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in _resume.skills)
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(_template.theme.surfaceColor.toARGB32()),
                        border: pw.Border.all(
                          color: PdfColor.fromInt(_template.theme.borderColor.toARGB32()),
                        ),
                        borderRadius: pw.BorderRadius.circular(16),
                      ),
                      child: pw.Text(
                        [item.name, item.level, item.note]
                            .where((value) => value.trim().isNotEmpty)
                            .join(' · '),
                        style: pw.TextStyle(font: baseFont, fontSize: 9.3),
                      ),
                    ),
                ],
              ),
            sectionTitle('奖项 / 证书'),
            if (_resume.awards.isEmpty)
              pw.Text('暂无奖项与证书。', style: bodyStyle())
            else
              ..._resume.awards.map(
                (item) => timelineCard(
                  title: item.name.isEmpty ? '未填写名称' : item.name,
                  meta: [item.issuer, item.date]
                      .where((value) => value.trim().isNotEmpty)
                      .join(' · '),
                  body: item.description,
                ),
              ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        titleSpacing: 18,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'AI 简历工作台',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 2),
            Text(
              '移动端优先的结构化编辑与实时简历预览',
              style: TextStyle(fontSize: 13, color: Color(0xFF5B6472)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _buildTemplatePicker(),
          ),
          PopupMenuButton<String>(
            tooltip: '导出选项',
            onSelected: (value) {
              if (value == 'pdf') _exportPdf();
              if (value == 'share') _sharePdf();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'pdf', child: Text('导出 / 打印 PDF')),
              PopupMenuItem(value: 'share', child: Text('分享 PDF')),
            ],
            icon: const Icon(Icons.more_horiz_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 980;
          final editor = _buildEditorPane(isMobile: isMobile);
          final preview = _buildPreviewPane(isMobile: isMobile);

          if (isMobile) {
            final pages = [editor, preview];
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment<int>(
                        value: 0,
                        icon: Icon(Icons.edit_outlined),
                        label: Text('编辑'),
                      ),
                      ButtonSegment<int>(
                        value: 1,
                        icon: Icon(Icons.article_outlined),
                        label: Text('预览'),
                      ),
                    ],
                    selected: {_mobileTabIndex},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _mobileTabIndex = selection.first;
                      });
                    },
                  ),
                ),
                Expanded(child: pages[_mobileTabIndex]),
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
      floatingActionButton: MediaQuery.of(context).size.width < 980
          ? FloatingActionButton.extended(
              onPressed: _isExportingPdf ? null : _exportPdf,
              icon: _isExportingPdf
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('导出 PDF'),
            )
          : null,
    );
  }

  Widget _buildEditorPane({required bool isMobile}) {
    return Container(
      color: const Color(0xFFF7F9FC),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(isMobile ? 16 : 20, 8, isMobile ? 16 : 20, 24),
          child: Column(
            children: [
              _buildMobileEnhancementSection(),
              const SizedBox(height: 16),
              _buildTemplateSection(),
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

  Widget _buildMobileEnhancementSection() {
    return _sectionCard(
      title: '移动端增强',
      subtitle: '针对手机补充拍照头像、当前位置填充与 PDF 分享能力。',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: const [
          _CapabilityChip(icon: Icons.camera_alt_outlined, label: '拍照头像'),
          _CapabilityChip(icon: Icons.photo_library_outlined, label: '相册选择'),
          _CapabilityChip(icon: Icons.near_me_outlined, label: '当前位置'),
          _CapabilityChip(icon: Icons.share_outlined, label: '分享 PDF'),
        ],
      ),
    );
  }

  Widget _buildTemplatePicker() {
    return DropdownButtonHideUnderline(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD7E0EC)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButton<ResumeTemplate>(
            value: _template,
            borderRadius: BorderRadius.circular(12),
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            items: [
              for (final template in ResumeTemplate.values)
                DropdownMenuItem(
                  value: template,
                  child: Text(template.label),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _template = value;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateSection() {
    return _sectionCard(
      title: '预览模板',
      subtitle: '切换简历视觉风格，移动端与 Web 共用同一套模板。',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final template in ResumeTemplate.values)
            ChoiceChip(
              label: Text(template.label),
              selected: _template == template,
              onSelected: (_) {
                setState(() {
                  _template = template;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalSection() {
    return _sectionCard(
      title: '个人信息',
      subtitle: '基础资料、头像和定位标题会在预览与 PDF 中同步呈现。',
      child: Column(
        children: [
          Row(
            children: [
              _buildAvatarPreview(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    FilledButton.icon(
                      onPressed: _showAvatarOptions,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: const Text('上传头像'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '支持拍照上传、相册选择和即时预览，更适合手机端完善简历头像。',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) => setState(() => _resume.personal.email = value),
            ),
            _textField(
              label: '电话',
              initialValue: _resume.personal.phone,
              keyboardType: TextInputType.phone,
              onChanged: (value) => setState(() => _resume.personal.phone = value),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _textField(
                  label: '所在地',
                  initialValue: _resume.personal.location,
                  onChanged: (value) => setState(() => _resume.personal.location = value),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: OutlinedButton.icon(
                  onPressed: _isLocating ? null : _fillCurrentLocation,
                  icon: _isLocating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_outlined),
                  label: const Text('当前位置'),
                ),
              ),
            ],
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
      subtitle: '支持多条教育背景，用于本科、交换、辅修或升学申请场景。',
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
      title: '课程 / 成绩亮点',
      subtitle: '保留手动录入方式，适配静态部署与移动端编辑场景。',
      actionLabel: '新增课程',
      onAction: _addCourse,
      child: Column(
        children: [
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
      ),
    );
  }

  Widget _buildExperienceSection() {
    return _sectionCard(
      title: '实习 / 校园经历',
      subtitle: '支持多条经历录入，适合手机上碎片化补充和调整。',
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
      subtitle: '支持多条项目输入，适合课程项目、竞赛项目和实习项目并存。',
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
      subtitle: '支持按条目维护技能、熟练度与补充说明。',
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
      subtitle: '用于补充荣誉、奖学金、竞赛成绩和资格证书。',
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

  Widget _buildPreviewPane({required bool isMobile}) {
    final theme = _template.theme;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 12, isMobile ? 16 : 24, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: AspectRatio(
              aspectRatio: isMobile ? 0.74 : 0.78,
              child: Container(
                padding: EdgeInsets.fromLTRB(isMobile ? 24 : 38, isMobile ? 24 : 34, isMobile ? 24 : 38, isMobile ? 26 : 40),
                decoration: BoxDecoration(
                  color: theme.paperColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.borderColor),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 28,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPreviewHeader(theme, isMobile: isMobile),
                      const SizedBox(height: 24),
                      _previewSection(
                        '个人简介',
                        _resume.personal.summary.trim().isEmpty
                            ? const Text('请在左侧补充个人简介。')
                            : Text(
                                _resume.personal.summary,
                                style: TextStyle(
                                  height: 1.6,
                                  color: theme.bodyColor,
                                ),
                              ),
                      ),
                      _previewSection(
                        '教育经历',
                        _resume.educations.isEmpty
                            ? Text('暂无教育经历。', style: TextStyle(color: theme.mutedColor))
                            : Column(
                                children: [
                                  for (final item in _resume.educations)
                                    _previewTimelineCard(
                                      theme: theme,
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
                            ? Text('暂无课程成绩亮点。', style: TextStyle(color: theme.mutedColor))
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
                                        color: theme.surfaceColor,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: theme.borderColor),
                                      ),
                                      child: Text(
                                        [
                                          item.name,
                                          if (item.score.trim().isNotEmpty) '成绩 ${item.score}',
                                          if (item.credit.trim().isNotEmpty) '学分 ${item.credit}',
                                          if (item.note.trim().isNotEmpty) item.note,
                                        ].join(' · '),
                                        style: TextStyle(color: theme.bodyColor),
                                      ),
                                    ),
                                ],
                              ),
                      ),
                      _previewSection(
                        '实习 / 校园经历',
                        _resume.experiences.isEmpty
                            ? Text('暂无经历。', style: TextStyle(color: theme.mutedColor))
                            : Column(
                                children: [
                                  for (final item in _resume.experiences)
                                    _previewTimelineCard(
                                      theme: theme,
                                      title: item.organization.isEmpty ? '未填写组织' : item.organization,
                                      meta: [item.role, item.period]
                                          .where((value) => value.trim().isNotEmpty)
                                          .join(' · '),
                                      body: item.description,
                                    ),
                                ],
                              ),
                      ),
                      _previewSection(
                        '项目经历',
                        _resume.projects.isEmpty
                            ? Text('暂无项目经历。', style: TextStyle(color: theme.mutedColor))
                            : Column(
                                children: [
                                  for (final item in _resume.projects)
                                    _previewTimelineCard(
                                      theme: theme,
                                      title: item.name.isEmpty ? '未填写项目名称' : item.name,
                                      meta: [item.role, item.period, item.stack]
                                          .where((value) => value.trim().isNotEmpty)
                                          .join(' · '),
                                      body: item.description,
                                    ),
                                ],
                              ),
                      ),
                      _previewSection(
                        '技能清单',
                        _resume.skills.isEmpty
                            ? Text('暂无技能。', style: TextStyle(color: theme.mutedColor))
                            : Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  for (final item in _resume.skills)
                                    Chip(
                                      label: Text(
                                        [item.name, item.level, item.note]
                                            .where((value) => value.trim().isNotEmpty)
                                            .join(' · '),
                                        style: TextStyle(color: theme.bodyColor),
                                      ),
                                      backgroundColor: theme.chipColor,
                                      side: BorderSide(color: theme.borderColor),
                                    ),
                                ],
                              ),
                      ),
                      _previewSection(
                        '奖项 / 证书',
                        _resume.awards.isEmpty
                            ? Text('暂无奖项与证书。', style: TextStyle(color: theme.mutedColor))
                            : Column(
                                children: [
                                  for (final item in _resume.awards)
                                    _previewTimelineCard(
                                      theme: theme,
                                      title: item.name.isEmpty ? '未填写名称' : item.name,
                                      meta: [item.issuer, item.date]
                                          .where((value) => value.trim().isNotEmpty)
                                          .join(' · '),
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
        ),
      ),
    );
  }

  Widget _buildPreviewHeader(ResumeTemplateTheme theme, {required bool isMobile}) {
    final contactItems = [
      _resume.personal.email,
      _resume.personal.phone,
      _resume.personal.location,
    ].where((value) => value.trim().isNotEmpty).toList();

    final headerText = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _resume.personal.name.trim().isEmpty ? '你的姓名' : _resume.personal.name,
          style: TextStyle(
            fontSize: isMobile ? 28 : 34,
            fontWeight: FontWeight.w800,
            color: theme.headerColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _resume.personal.title.trim().isEmpty ? '你的定位标题' : _resume.personal.title,
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            color: theme.mutedColor,
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_resume.personal.avatarBytes != null) ...[
                    _buildPreviewAvatar(size: 68),
                    const SizedBox(width: 14),
                  ],
                  Expanded(child: headerText),
                ],
              ),
              if (contactItems.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in contactItems)
                      _buildContactPill(theme, item),
                  ],
                ),
              ],
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_resume.personal.avatarBytes != null) ...[
                _buildPreviewAvatar(size: 88),
                const SizedBox(width: 18),
              ],
              Expanded(child: headerText),
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
                            style: TextStyle(color: theme.mutedColor),
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
            color: theme.accentColor,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }

  Widget _buildContactPill(ResumeTemplateTheme theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.mutedColor,
          fontSize: 12.5,
        ),
      ),
    );
  }

  Widget _previewSection(String title, Widget child) {
    final theme = _template.theme;
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: theme.sectionColor,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _previewTimelineCard({
    required ResumeTemplateTheme theme,
    required String title,
    required String meta,
    required String body,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.headerColor,
            ),
          ),
          if (meta.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              meta,
              style: TextStyle(color: theme.mutedColor),
            ),
          ],
          if (body.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              body,
              style: TextStyle(
                height: 1.6,
                color: theme.bodyColor,
              ),
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
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: initialValue,
        maxLines: maxLines,
        keyboardType: keyboardType,
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
        if (constraints.maxWidth < 420) {
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

  Widget _buildAvatarPreview() {
    final bytes = _resume.personal.avatarBytes;
    return Container(
      width: 88,
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE4EF)),
        image: bytes == null
            ? null
            : DecorationImage(
                image: MemoryImage(bytes),
                fit: BoxFit.cover,
              ),
      ),
      child: bytes == null
          ? const Center(
              child: Icon(
                Icons.account_circle_outlined,
                size: 42,
                color: Color(0xFF8A94A6),
              ),
            )
          : null,
    );
  }

  Widget _buildPreviewAvatar({required double size}) {
    final bytes = _resume.personal.avatarBytes;
    if (bytes == null) return const SizedBox.shrink();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.24),
        image: DecorationImage(
          image: MemoryImage(bytes),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _CapabilityChip extends StatelessWidget {
  const _CapabilityChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDCE4EF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
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
        title: '计算机方向申请者 / 移动端项目实践者',
        email: 'demo@example.com',
        phone: '138-0000-0000',
        location: '上海',
        summary:
            '具备 Flutter、静态部署与课程项目整理经验，能独立完成移动端信息录入、界面实现、导出交付和版本发布，关注简历内容结构化表达与实际投递效率。',
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
          description: '负责移动端工作台界面实现、表单交互、真机调试和静态部署说明整理。',
        ),
      ],
      projects: [
        ProjectEntry(
          id: IdFactory.next(),
          name: 'AI Resume Generator',
          role: 'Flutter 改造',
          period: '2026.06',
          stack: 'Flutter / GitHub Pages / Jekyll',
          description:
              '在保留 Jekyll 经典版的同时，补充 Flutter 工作台的移动端布局、头像上传、当前位置填充和统一 PDF 导出能力。',
        ),
      ],
      skills: [
        SkillEntry(
          id: IdFactory.next(),
          name: 'Flutter',
          level: '熟练',
          note: '移动端适配与真机调试',
        ),
        SkillEntry(
          id: IdFactory.next(),
          name: 'Jekyll',
          level: '熟练',
          note: '静态页面维护与 GitHub Pages 发布',
        ),
      ],
      awards: [
        AwardEntry(
          id: IdFactory.next(),
          name: '课程项目实践',
          issuer: '创新实验课程',
          date: '2026',
          description: '完成静态站升级、双版本保留、真机调试与在线部署。 ',
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
    this.avatarBytes,
  });

  String name;
  String title;
  String email;
  String phone;
  String location;
  String summary;
  Uint8List? avatarBytes;
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

class IdFactory {
  static int _counter = 0;

  static String next() {
    _counter += 1;
    return 'item-${DateTime.now().microsecondsSinceEpoch}-$_counter';
  }
}

enum ResumeTemplate {
  modern('现代通用'),
  blue('蓝金正式'),
  sidebar('侧栏信息'),
  gray('蓝灰团队'),
  classic('经典单栏');

  const ResumeTemplate(this.label);

  final String label;

  ResumeTemplateTheme get theme {
    switch (this) {
      case ResumeTemplate.modern:
        return const ResumeTemplateTheme(
          paperColor: Colors.white,
          surfaceColor: Color(0xFFF8FAFD),
          chipColor: Color(0xFFEFF4FF),
          borderColor: Color(0xFFDCE4EF),
          accentColor: Color(0xFF2F6BFF),
          sectionColor: Color(0xFF2F6BFF),
          headerColor: Color(0xFF1A2433),
          bodyColor: Color(0xFF334155),
          mutedColor: Color(0xFF5A6778),
        );
      case ResumeTemplate.blue:
        return const ResumeTemplateTheme(
          paperColor: Color(0xFFFCFDFE),
          surfaceColor: Color(0xFFF4F7FB),
          chipColor: Color(0xFFFFF1D6),
          borderColor: Color(0xFFD7E1EC),
          accentColor: Color(0xFFB8891B),
          sectionColor: Color(0xFF132238),
          headerColor: Color(0xFF132238),
          bodyColor: Color(0xFF263648),
          mutedColor: Color(0xFF5B6D82),
        );
      case ResumeTemplate.sidebar:
        return const ResumeTemplateTheme(
          paperColor: Color(0xFFFDFEFF),
          surfaceColor: Color(0xFFF0F4F8),
          chipColor: Color(0xFFE5EEF9),
          borderColor: Color(0xFFD6E1EC),
          accentColor: Color(0xFF233D63),
          sectionColor: Color(0xFF233D63),
          headerColor: Color(0xFF18283D),
          bodyColor: Color(0xFF334155),
          mutedColor: Color(0xFF607080),
        );
      case ResumeTemplate.gray:
        return const ResumeTemplateTheme(
          paperColor: Color(0xFFFBFCFD),
          surfaceColor: Color(0xFFF2F4F7),
          chipColor: Color(0xFFE8EDF4),
          borderColor: Color(0xFFD7DEE7),
          accentColor: Color(0xFF475569),
          sectionColor: Color(0xFF334155),
          headerColor: Color(0xFF1F2937),
          bodyColor: Color(0xFF374151),
          mutedColor: Color(0xFF667085),
        );
      case ResumeTemplate.classic:
        return const ResumeTemplateTheme(
          paperColor: Color(0xFFFFFEFC),
          surfaceColor: Color(0xFFFBF8F1),
          chipColor: Color(0xFFF6EFE1),
          borderColor: Color(0xFFE7DDC8),
          accentColor: Color(0xFF7C5A2A),
          sectionColor: Color(0xFF6B4C21),
          headerColor: Color(0xFF2B2114),
          bodyColor: Color(0xFF463728),
          mutedColor: Color(0xFF77624B),
        );
    }
  }
}

class ResumeTemplateTheme {
  const ResumeTemplateTheme({
    required this.paperColor,
    required this.surfaceColor,
    required this.chipColor,
    required this.borderColor,
    required this.accentColor,
    required this.sectionColor,
    required this.headerColor,
    required this.bodyColor,
    required this.mutedColor,
  });

  final Color paperColor;
  final Color surfaceColor;
  final Color chipColor;
  final Color borderColor;
  final Color accentColor;
  final Color sectionColor;
  final Color headerColor;
  final Color bodyColor;
  final Color mutedColor;
}
