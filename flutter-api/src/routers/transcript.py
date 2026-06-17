import json
import os
import re
import uuid
import zipfile
from collections import defaultdict
from io import BytesIO
from typing import Any
from xml.etree import ElementTree

import fitz
from alibabacloud_ocr_api20210707 import models as ocr_models
from alibabacloud_ocr_api20210707.client import Client as OcrClient
from alibabacloud_tea_openapi import models as open_api_models
from fastapi import APIRouter, File, UploadFile
from PIL import Image, ImageOps
from pydantic import BaseModel, Field

router = APIRouter()

IMAGE_CONTENT_TYPES = {
    "image/png",
    "image/jpeg",
    "image/jpg",
    "image/bmp",
    "image/gif",
    "image/tiff",
    "image/webp",
}
GRADE_WORDS = {"优秀", "良好", "中等", "及格", "合格", "通过"}
HEADER_TOKENS = {
    "课程",
    "课程名称",
    "科目",
    "科目名称",
    "名称",
    "成绩",
    "分数",
    "总评",
    "学分",
    "绩点",
    "类别",
    "性质",
    "学年",
    "学期",
    "课程代码",
    "代码",
    "编号",
}
MAX_IMAGE_BYTES = 9_500_000


class CourseCandidate(BaseModel):
    id: str
    name: str
    score: str
    credit: str = ""


class TranscriptParseResponse(BaseModel):
    success: bool
    message: str
    courses: list[CourseCandidate] = Field(default_factory=list)
    rawText: str = ""
    source: str = "aliyun"


def make_id() -> str:
    return uuid.uuid4().hex


def get_aliyun_client() -> OcrClient:
    access_key_id = os.getenv("ALIBABA_CLOUD_ACCESS_KEY_ID") or os.getenv("ALIYUN_ACCESS_KEY_ID")
    access_key_secret = os.getenv("ALIBABA_CLOUD_ACCESS_KEY_SECRET") or os.getenv("ALIYUN_ACCESS_KEY_SECRET")
    endpoint = os.getenv("ALIYUN_OCR_ENDPOINT", "ocr-api.cn-hangzhou.aliyuncs.com")

    if not access_key_id or not access_key_secret:
        raise RuntimeError("缺少阿里云 OCR AccessKey，请检查后端 .env 配置。")

    config = open_api_models.Config(
        access_key_id=access_key_id,
        access_key_secret=access_key_secret,
        endpoint=endpoint,
    )
    return OcrClient(config)


def compress_image(image_bytes: bytes, max_side: int = 2200) -> bytes:
    with Image.open(BytesIO(image_bytes)) as image:
        image = ImageOps.exif_transpose(image)
        image.thumbnail((max_side, max_side))
        if image.mode not in ("RGB", "L"):
            image = image.convert("RGB")

        quality = 90
        while quality >= 60:
            output = BytesIO()
            image.save(output, format="JPEG", quality=quality, optimize=True)
            data = output.getvalue()
            if len(data) <= MAX_IMAGE_BYTES:
                return data
            quality -= 10

        return data


def pdf_to_images(file_bytes: bytes) -> list[bytes]:
    doc = fitz.open(stream=file_bytes, filetype="pdf")
    try:
        images: list[bytes] = []
        for page_index in range(doc.page_count):
            page = doc.load_page(page_index)
            pixmap = page.get_pixmap(matrix=fitz.Matrix(2, 2), alpha=False)
            images.append(compress_image(pixmap.tobytes("png")))
        return images
    finally:
        doc.close()


def file_to_images(filename: str, content_type: str | None, file_bytes: bytes) -> list[bytes]:
    name = filename.lower()
    if content_type in IMAGE_CONTENT_TYPES or name.endswith((".png", ".jpg", ".jpeg", ".bmp", ".gif", ".tif", ".tiff", ".webp")):
        return [compress_image(file_bytes)]

    if content_type == "application/pdf" or name.endswith(".pdf"):
        return pdf_to_images(file_bytes)

    if name.endswith((".doc", ".docx")):
        raise ValueError("Word 成绩单已改走文本解析；如果是扫描版 Word，请先导出为 PDF 或图片。")

    raise ValueError("仅支持 PDF、docx 和常见图片格式。")


def to_plain(value: Any) -> Any:
    if hasattr(value, "to_map"):
        value = value.to_map()
    if isinstance(value, dict):
        return {key: to_plain(item) for key, item in value.items()}
    if isinstance(value, list):
        return [to_plain(item) for item in value]
    return value


def as_list(value: Any) -> list[Any]:
    if value is None:
        return []
    return value if isinstance(value, list) else [value]


def get_any(data: dict[str, Any], *keys: str, default: Any = None) -> Any:
    for key in keys:
        if key in data:
            return data[key]
    lower = {str(key).lower(): value for key, value in data.items()}
    for key in keys:
        lowered = key.lower()
        if lowered in lower:
            return lower[lowered]
    return default


def to_int(value: Any, default: int = 0) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def call_table_ocr(client: OcrClient, image_bytes: bytes) -> dict[str, Any]:
    request = ocr_models.RecognizeAllTextRequest(
        type="Table",
        body=BytesIO(image_bytes),
        table_config=ocr_models.RecognizeAllTextRequestTableConfig(
            is_line_less_table=True,
            output_table_html=True,
        ),
    )
    response = client.recognize_all_text(request)
    body = response.body

    if body.code and str(body.code) not in {"200", "OK", "Success"}:
        raise RuntimeError(body.message or body.code)

    data = to_plain(body.data)
    if not data:
        return {}
    if isinstance(data, str):
        return json.loads(data)
    if isinstance(data, dict):
        return data
    return {}


def cell_text(cell: dict[str, Any]) -> str:
    text = get_any(
        cell,
        "CellContent",
        "cellContent",
        "BlockContent",
        "blockContent",
        "word",
        "text",
        "content",
        "Text",
        "Content",
        default="",
    )
    return re.sub(r"\s+", " ", str(text)).strip()


def cell_col(cell: dict[str, Any]) -> int:
    return to_int(get_any(cell, "ColumnStart", "columnStart", "ColStart", "col", "column", "xsc", "startCol"), 0)


def cell_row(cell: dict[str, Any]) -> int:
    return to_int(get_any(cell, "RowStart", "rowStart", "Row", "row", "ysc", "startRow"), 0)


def rows_from_cells(cells: list[dict[str, Any]]) -> list[list[str]]:
    grouped: dict[int, list[tuple[int, str]]] = defaultdict(list)
    for cell in cells:
        text = cell_text(cell)
        if text:
            grouped[cell_row(cell)].append((cell_col(cell), text))

    rows: list[list[str]] = []
    for row_index in sorted(grouped):
        row = [text for _, text in sorted(grouped[row_index], key=lambda item: item[0])]
        if row:
            rows.append(row)
    return rows


def table_rows_from_old_table_ocr(result: dict[str, Any]) -> list[list[str]]:
    rows: list[list[str]] = []
    for table in result.get("prism_tablesInfo", []) or []:
        rows.extend(rows_from_cells(table.get("cellInfos", []) or []))
    return rows


def table_rows_from_all_text(result: dict[str, Any]) -> list[list[str]]:
    rows: list[list[str]] = []
    for sub_image in as_list(get_any(result, "SubImages", "subImages", default=[])):
        if not isinstance(sub_image, dict):
            continue

        table_info = get_any(sub_image, "TableInfo", "tableInfo", default={}) or {}
        table_details = get_any(table_info, "TableDetails", "tableDetails", "Tables", "tables", default=[]) or []
        for table in as_list(table_details):
            if not isinstance(table, dict):
                continue
            cells = get_any(table, "CellDetails", "cellDetails", "CellInfos", "cellInfos", "Cells", "cells", default=[]) or []
            rows.extend(rows_from_cells([cell for cell in as_list(cells) if isinstance(cell, dict)]))

        cells = get_any(table_info, "CellDetails", "cellDetails", "CellInfos", "cellInfos", default=[]) or []
        rows.extend(rows_from_cells([cell for cell in as_list(cells) if isinstance(cell, dict)]))

    return rows


def block_tokens_from_result(result: dict[str, Any]) -> list[str]:
    tokens: list[str] = []
    for sub_image in as_list(get_any(result, "SubImages", "subImages", default=[])):
        if not isinstance(sub_image, dict):
            continue
        block_info = get_any(sub_image, "BlockInfo", "blockInfo", default={}) or {}
        for block in as_list(get_any(block_info, "BlockDetails", "blockDetails", default=[])):
            if not isinstance(block, dict):
                continue
            text = cell_text(block)
            if text:
                tokens.append(text)
    return tokens


def table_rows(result: dict[str, Any]) -> list[list[str]]:
    rows = table_rows_from_all_text(result)
    if rows:
        return rows
    return table_rows_from_old_table_ocr(result)


def raw_text_from_result(result: dict[str, Any]) -> str:
    rows = table_rows(result)
    if rows:
        return "\n".join("\t".join(row) for row in rows)

    content = get_any(result, "Content", "content", default="")
    if content:
        return str(content)

    tokens = block_tokens_from_result(result)
    if tokens:
        return "\n".join(tokens)

    words = []
    for item in result.get("prism_wordsInfo", []) or []:
        text = cell_text(item)
        if text:
            words.append(text)
    return "\n".join(words)


def normalize_course_name(name: str) -> str:
    replacements = [
        "课程名称",
        "科目名称",
        "科目",
        "成绩",
        "分数",
        "总评",
        "学分",
        "绩点",
        "必修",
        "选修",
        "考试",
        "考查",
        "公共课",
        "专业课",
        "课程性质",
        "类别",
        "性质",
        "学年",
        "学期",
        "课程代码",
        "代码",
        "编号",
    ]
    for item in replacements:
        name = name.replace(item, " ")
    return name


def clean_course_name(name: str) -> str:
    name = normalize_course_name(name)
    name = re.sub(r"\b[A-Z]{1,8}\d{2,}\b", " ", name, flags=re.I)
    name = re.sub(r"^\d+[\s.、-]*", " ", name)
    name = re.sub(r"(?<![A-Za-z])[0-9.]+(?![A-Za-z])", " ", name)
    name = re.sub(r"\s+", " ", name).strip(" -_/|,，:：;；")
    return name


def valid_course_name(name: str) -> bool:
    if not (2 <= len(name) <= 40):
        return False
    if name in HEADER_TOKENS:
        return False
    return bool(re.search(r"[\u4e00-\u9fa5A-Za-z]", name))


def extract_score(text: str) -> str:
    score = extract_score_with_position(text)
    return score[0] if score else ""


def extract_score_with_position(text: str) -> tuple[str, int] | None:
    pattern = r"(?:^|[^\d])((?:100(?:\.0)?|[5-9]\d(?:\.\d)?|优秀|良好|中等|及格|合格|通过))(?=$|[^\d])"
    matches = list(re.finditer(pattern, text))
    if not matches:
        return None
    match = matches[-1]
    return match.group(1), match.start(1)


def looks_like_credit(text: str) -> bool:
    try:
        value = float(text)
    except ValueError:
        return False
    return 0 < value <= 10


def parse_row_without_header(cells: list[str]) -> CourseCandidate | None:
    cells = [re.sub(r"\s+", " ", cell).strip() for cell in cells if str(cell).strip()]
    if not cells:
        return None

    score = ""
    score_index = -1
    score_position = -1
    for index in range(len(cells) - 1, -1, -1):
        score_match = extract_score_with_position(cells[index])
        if score_match:
            score, score_position = score_match
            score_index = index
            break

    if not score:
        return None

    credit = ""
    score_cell = cells[score_index] if score_index >= 0 else ""
    before_score = score_cell[:score_position] if score_position > 0 else ""
    after_score = score_cell[score_position + len(score) :] if score_position >= 0 else ""
    for credit_match in re.finditer(r"(?:^|[^\d])([1-9](?:\.\d)?)(?=$|[^\d])", before_score):
        if looks_like_credit(credit_match.group(1)):
            credit = credit_match.group(1)

    if not credit:
        for credit_match in re.finditer(r"(?:^|[^\d])([1-9](?:\.\d)?)(?=$|[^\d])", after_score):
            if looks_like_credit(credit_match.group(1)):
                credit = credit_match.group(1)
                break

    for cell in cells[:score_index]:
        compact = cell.strip()
        if looks_like_credit(compact):
            credit = compact

    ignored = re.compile(r"成绩|分数|总评|学分|绩点|课程性质|类别|考试|考查|必修|选修|学期|编号|代码")
    name = ""
    for index, cell in enumerate(cells):
        if index == score_index or ignored.fullmatch(cell):
            continue
        if looks_like_credit(cell):
            continue
        candidate = clean_course_name(cell)
        if valid_course_name(candidate):
            name = candidate
            break

    if not name:
        name_source = before_score if score_index == 0 else " ".join(cells[:score_index])
        name = clean_course_name(name_source)

    if not valid_course_name(name):
        return None

    return CourseCandidate(id=make_id(), name=name, score=score, credit=credit)


def header_map(cells: list[str]) -> dict[str, int]:
    mapping: dict[str, int] = {}
    for index, cell in enumerate(cells):
        compact = re.sub(r"\s+", "", cell)
        if any(word in compact for word in ("课程名称", "科目名称", "课程", "科目", "名称")):
            mapping.setdefault("name", index)
        if any(word in compact for word in ("成绩", "分数", "总评")):
            mapping.setdefault("score", index)
        if "学分" in compact:
            mapping.setdefault("credit", index)
    return mapping


def parse_rows(rows: list[list[str]]) -> list[CourseCandidate]:
    courses: list[CourseCandidate] = []
    active_header: dict[str, int] = {}

    for cells in rows:
        row_text = "".join(cells)
        current_header = header_map(cells)
        if current_header and ("name" in current_header or "score" in current_header):
            active_header = current_header
            continue

        course: CourseCandidate | None = None
        if {"name", "score"}.issubset(active_header):
            name_index = active_header["name"]
            score_index = active_header["score"]
            if name_index < len(cells) and score_index < len(cells):
                name = clean_course_name(cells[name_index])
                score = extract_score(cells[score_index]) or cells[score_index].strip()
                credit = ""
                credit_index = active_header.get("credit")
                if credit_index is not None and credit_index < len(cells):
                    credit = cells[credit_index].strip()
                if valid_course_name(name) and score:
                    course = CourseCandidate(id=make_id(), name=name, score=score, credit=credit)

        if not course and not re.search(r"姓名|学号|学院|平均|绩点|排名", row_text):
            course = parse_row_without_header(cells)
        if course:
            courses.append(course)

    return courses


def tokenize_text(text: str) -> list[str]:
    text = re.sub(r"[|｜,，;；:：]+", " ", text.replace("\r", "\n"))
    return [token.strip() for token in re.split(r"\s+", text) if token.strip()]


def is_header_token(token: str) -> bool:
    compact = re.sub(r"\s+", "", token)
    return compact in HEADER_TOKENS or compact in {"序号", "课程号", "课程名"}


def exact_score(token: str) -> str:
    if token in GRADE_WORDS:
        return token
    match = re.fullmatch(r"(100(?:\.0)?|[5-9]\d(?:\.\d)?)", token)
    return match.group(1) if match else ""


def parse_token_stream(tokens_or_text: list[str] | str) -> list[CourseCandidate]:
    tokens = tokenize_text(tokens_or_text) if isinstance(tokens_or_text, str) else tokens_or_text
    tokens = [token for token in tokens if token and not is_header_token(token)]
    courses: list[CourseCandidate] = []
    start = 0

    for index, token in enumerate(tokens):
        score = exact_score(token)
        if not score:
            continue

        credit_index = -1
        credit = ""
        for cursor in range(index - 1, start - 1, -1):
            if looks_like_credit(tokens[cursor]):
                credit_index = cursor
                credit = tokens[cursor]
                break

        name_end = credit_index
        next_start = index + 1
        if credit_index <= start:
            next_index = index + 1
            if next_index < len(tokens) and looks_like_credit(tokens[next_index]):
                credit_index = next_index
                credit = tokens[next_index]
                name_end = index
                next_start = next_index + 1
            else:
                name_end = index

        name_tokens = [item for item in tokens[start:name_end] if not is_header_token(item)]
        name = clean_course_name(" ".join(name_tokens[-6:]))
        if valid_course_name(name):
            courses.append(CourseCandidate(id=make_id(), name=name, score=score, credit=credit))
        start = next_start

    return courses


def parse_text_lines(text: str) -> list[CourseCandidate]:
    rows = [
        re.sub(r"\s+", " ", line).strip()
        for line in re.split(r"[\n;；]", text.replace("\r", "\n"))
        if line.strip()
    ]
    line_courses = [course for course in (parse_row_without_header([row]) for row in rows) if course]
    stream_courses = parse_token_stream(text)
    return line_courses + stream_courses


def parse_result_courses(result: dict[str, Any], raw_text: str) -> list[CourseCandidate]:
    rows = table_rows(result)
    courses: list[CourseCandidate] = []
    courses.extend(parse_rows(rows))

    block_tokens = block_tokens_from_result(result)
    if block_tokens:
        courses.extend(parse_token_stream(block_tokens))

    courses.extend(parse_text_lines(raw_text))
    return dedupe_courses(courses)


def docx_rows_and_text(file_bytes: bytes) -> tuple[list[list[str]], str]:
    rows: list[list[str]] = []
    text_lines: list[str] = []
    namespace = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}

    with zipfile.ZipFile(BytesIO(file_bytes)) as archive:
        xml_bytes = archive.read("word/document.xml")

    root = ElementTree.fromstring(xml_bytes)

    for table in root.findall(".//w:tbl", namespace):
        for tr in table.findall(".//w:tr", namespace):
            row: list[str] = []
            for tc in tr.findall("./w:tc", namespace):
                cell = "".join(node.text or "" for node in tc.findall(".//w:t", namespace)).strip()
                if cell:
                    row.append(re.sub(r"\s+", " ", cell))
            if row:
                rows.append(row)
                text_lines.append("\t".join(row))

    for paragraph in root.findall(".//w:p", namespace):
        text = "".join(node.text or "" for node in paragraph.findall(".//w:t", namespace)).strip()
        if text:
            text_lines.append(re.sub(r"\s+", " ", text))

    return rows, "\n".join(dict.fromkeys(text_lines))


def dedupe_courses(courses: list[CourseCandidate]) -> list[CourseCandidate]:
    result: list[CourseCandidate] = []
    seen: set[str] = set()
    for course in courses:
        key = f"{course.name}-{course.score}"
        if key in seen:
            continue
        seen.add(key)
        result.append(course)
    return result[:60]


def score_value(score: str) -> float:
    grade_scores = {
        "优秀": 95,
        "良好": 85,
        "中等": 75,
        "及格": 65,
        "合格": 60,
        "通过": 60,
    }
    if score in grade_scores:
        return float(grade_scores[score])
    try:
        return float(score)
    except ValueError:
        return 0


def credit_value(credit: str) -> float:
    try:
        return float(credit)
    except ValueError:
        return 0


def sort_courses(courses: list[CourseCandidate]) -> list[CourseCandidate]:
    return sorted(courses, key=lambda course: (-score_value(course.score), -credit_value(course.credit), course.name))


def friendly_error_message(exc: Exception) -> str:
    message = str(exc)
    if "ocrServiceNotOpen" in message:
        return "阿里云 OCR 统一识别服务仍提示未开通：请确认 AccessKey 所属账号与控制台开通服务的账号一致，并给 RAM 用户授权 OCR API。"
    if any(key in message for key in ("InvalidAccessKeyId", "InvalidAccessKeySecret", "SignatureDoesNotMatch")):
        return "阿里云 AccessKey 无效或签名失败，请检查后端 .env 中的 AccessKeyId、AccessKeySecret 和系统时间。"
    if any(key in message for key in ("Forbidden", "NoPermission", "Unauthorized", "Forbidden.RAM")):
        return "阿里云账号缺少 OCR 调用权限，请给当前 AccessKey 对应的 RAM 用户授予 OCR 相关权限。"
    if any(key in message for key in ("QuotaExceeded", "Throttling", "InsufficientBalance")):
        return "阿里云 OCR 额度、余额或 QPS 受限，请检查按量付费/资源包/调用频率。"
    if "InvalidImage" in message or "InvalidFile" in message:
        return "文件格式或图片质量不符合阿里云 OCR 要求，请换清晰图片或 PDF 再试。"
    return message


@router.post("/parse", response_model=TranscriptParseResponse)
async def parse_transcript(file: UploadFile = File(...)):
    try:
        file_bytes = await file.read()
        filename = file.filename or ""
        lowered_name = filename.lower()

        if lowered_name.endswith(".docx"):
            rows, raw_text = docx_rows_and_text(file_bytes)
            courses = sort_courses(dedupe_courses(parse_rows(rows) or parse_text_lines(raw_text)))
            return {
                "success": True,
                "message": f"Word 成绩单解析完成，找到 {len(courses)} 门候选课程，已按成绩和学分排序，建议精选 6 门放入简历。",
                "courses": courses,
                "rawText": raw_text,
                "source": "docx",
            }

        images = file_to_images(filename, file.content_type, file_bytes)
        client = get_aliyun_client()

        raw_parts: list[str] = []
        courses: list[CourseCandidate] = []
        for image in images:
            result = call_table_ocr(client, image)
            raw_text = raw_text_from_result(result)
            raw_parts.append(raw_text)
            courses.extend(parse_result_courses(result, raw_text))

        courses = sort_courses(dedupe_courses(courses))
        raw_text = "\n\n".join(part for part in raw_parts if part.strip())
        return {
            "success": True,
            "message": f"阿里云统一识别完成，共识别 {len(images)} 页，找到 {len(courses)} 门候选课程，已按成绩和学分排序，建议精选 6 门放入简历。",
            "courses": courses,
            "rawText": raw_text,
            "source": "aliyun",
        }
    except Exception as exc:
        return {
            "success": False,
            "message": friendly_error_message(exc),
            "courses": [],
            "rawText": "",
            "source": "aliyun",
        }
