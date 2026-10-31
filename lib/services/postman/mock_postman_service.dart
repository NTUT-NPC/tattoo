import 'package:tattoo/services/postman/postman_service.dart';

class MockPostmanService implements PostmanService {
  static final _announcements = <PostmanAnnouncementDto>[
    (
      id: 'demo-library',
      category: '業務公告',
      title: '期中考期間圖書館自習室延長開放',
      department: '圖書資訊處',
      publishedAt: DateTime(2026, 10, 30),
    ),
    (
      id: 'demo-workshop',
      category: '活動訊息',
      title: '職涯探索工作坊開放報名',
      department: '學生事務處',
      publishedAt: DateTime(2026, 10, 29),
    ),
    (
      id: 'demo-maintenance',
      category: '重要通知',
      title: '校園無線網路維護通知',
      department: '計算機與網路中心',
      publishedAt: DateTime(2026, 10, 28),
    ),
  ];

  @override
  Future<PostmanAnnouncementPageDto> getAnnouncements({int page = 1}) async {
    if (page < 1) throw RangeError.range(page, 1, null, 'page');
    const pageSize = 2;
    final start = (page - 1) * pageSize;
    if (start >= _announcements.length) {
      throw RangeError('Postman page $page has no data');
    }
    return (
      announcements: _announcements.skip(start).take(pageSize).toList(),
      page: page,
      totalPages: (_announcements.length / pageSize).ceil(),
    );
  }

  @override
  Future<PostmanAnnouncementDetailDto> getAnnouncement(String id) async {
    final announcement = _announcements
        .where((item) => item.id == id)
        .firstOrNull;
    if (announcement == null) {
      throw const FormatException('Postman announcement details are missing');
    }
    final (summary, contentHtml, contact) = switch (id) {
      'demo-library' => (
        '期中考期間提供延長開放服務。',
        '<p>期中考期間圖書館自習室延長開放，歡迎同學多加利用。</p>',
        '圖書資訊處\nEmail: library@example.com',
      ),
      'demo-workshop' => (
        '透過工作坊探索個人興趣與職涯方向。',
        '<p>職涯探索工作坊開放報名，請至學輔中心洽詢活動資訊。</p>',
        '學生事務處\nEmail: counseling@example.com',
      ),
      _ => (
        '校園無線網路將進行例行維護。',
        '<p>維護期間無線網路可能暫時中斷，造成不便敬請見諒。</p>',
        '計算機與網路中心\nEmail: network@example.com',
      ),
    };
    return (
      id: id,
      category: announcement.category,
      title: announcement.title,
      summary: summary,
      contentHtml: contentHtml,
      attachments: <PostmanAttachmentDto>[],
      contact: contact,
    );
  }
}
