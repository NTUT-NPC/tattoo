import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:intl/intl.dart';
import 'package:tattoo/services/postman/postman_service.dart';
import 'package:tattoo/utils/http.dart';

class NtutPostmanService implements PostmanService {
  final Dio _dio;
  static final _pagination = RegExp(r'第\s*(\d+)\s*頁\s*/\s*共\s*(\d+)\s*頁');
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  NtutPostmanService({Dio? dio}) : _dio = dio ?? createDio() {
    _dio.options.baseUrl = 'https://postman.ntut.edu.tw/CI/';
  }

  @override
  Future<PostmanAnnouncementPageDto> getAnnouncements({int page = 1}) async {
    if (page < 1) throw RangeError.range(page, 1, null, 'page');

    final document = await _getDocument('home/$page');

    if (document.querySelector('ul.pager')?.text.contains('無資料') == true) {
      throw RangeError('Postman page $page has no data');
    }

    final pagination = _pagination.firstMatch(
      document.querySelector('ul.pager')?.text ?? '',
    );
    if (pagination == null || document.querySelector('.mcontents') == null) {
      throw const FormatException('Postman announcement list is missing');
    }

    final announcements = <PostmanAnnouncementDto>[];

    for (final row in document.querySelectorAll('.mcontents .showmsg[no]')) {
      final cells = row.querySelectorAll('.msg');
      final id = row.attributes['no']!;
      if (cells.length != 3 || id.isEmpty) {
        throw const FormatException('Invalid Postman announcement row');
      }

      final categoryElement = cells[0].querySelector('b.text-primary');
      if (categoryElement == null) {
        throw const FormatException('Postman announcement category is missing');
      }

      final category = categoryElement.text.trim();
      categoryElement.remove();

      announcements.add((
        id: id,
        category: category,
        title: cells[0].text.trim(),
        department: cells[1].text.trim(),
        publishedAt: _dateFormat.parseStrict(cells[2].text.trim()),
      ));
    }

    return (
      announcements: announcements,
      page: int.parse(pagination.group(1)!),
      totalPages: int.parse(pagination.group(2)!),
    );
  }

  @override
  Future<PostmanAnnouncementDetailDto> getAnnouncement(String id) async {
    final Document document;
    try {
      document = await _getDocument('ajax/msghtml/${Uri.encodeComponent(id)}');
    } on DioException catch (error) {
      // Postman's AJAX controller masks an unauthenticated session as HTTP 404.
      if (error.response?.statusCode == 404) {
        throw const SessionExpiredException('Postman requires portal SSO');
      }
      rethrow;
    }

    final category = document.querySelector('.modal-header .text-primary b');
    final title = document.querySelector('.modal-header .modal-title > small');
    final summary = document.querySelector('.modal-body > h4 > small');
    final content = document.querySelector('.modal-body > div.ab');
    final contact = document.querySelector('.modal-footer > h5');
    if (category == null ||
        title == null ||
        summary == null ||
        content == null ||
        contact == null) {
      throw const FormatException('Postman announcement details are missing');
    }

    for (final br in contact.querySelectorAll('br')) {
      br.replaceWith(Text('\n'));
    }

    return (
      id: id,
      category: category.text.trim(),
      title: title.text.trim(),
      summary: summary.text.trim(),
      contentHtml: content.innerHtml,
      attachments: [
        for (final link in document.querySelectorAll('.modal-body > p a[href]'))
          (
            name: link.text.trim(),
            url: Uri.parse(_dio.options.baseUrl)
                .resolve(link.attributes['href']!),
          ),
      ],
      contact: contact.text.trim(),
    );
  }

  Future<Document> _getDocument(String path) async {
    final response = await _dio.get<String>(
      path,
      options: Options(responseType: .plain),
    );

    final document = parse(response.data);

    if (response.realUri.path.endsWith('/showmsg/loginmsg') ||
        document.body?.text.contains('請由校園入口網站') == true) {
      throw const SessionExpiredException('Postman requires portal SSO');
    }

    return document;
  }
}
