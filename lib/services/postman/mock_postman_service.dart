import 'package:tattoo/services/postman/postman_service.dart';

/// Fixed public announcements from October 2026, with original details.
class MockPostmanService implements PostmanService {
  static final _announcements = <PostmanAnnouncementDto>[
    (
      id: '116231793256386',
      category: '業務公告',
      title: '【系統恢復公告】郵件保存系統已完成資安修補，即日起恢復外網直接存取服務',
      department: '計算機與網路中心',
      publishedAt: DateTime(2026, 10, 30),
    ),
    (
      id: '109661793152625',
      category: '重要通知',
      title: '【無線網路平台系統】預定於115年11⽉3⽇(二)10:00~17:00進行停機維護作業',
      department: '計算機與網路中心',
      publishedAt: DateTime(2026, 10, 30),
    ),
    (
      id: '121641793174214',
      category: '活動訊息',
      title: '光華館二樓享聚餐廳為慶祝115年校慶，115年10月28日至11月2日期間熱炒特價7折，歡迎蒞臨用餐',
      department: '總務處',
      publishedAt: DateTime(2026, 10, 29),
    ),
  ];

  static final _details = <String, PostmanAnnouncementDetailDto>{
    '116231793256386': (
      id: '116231793256386',
      category: '業務公告',
      title: '【系統恢復公告】郵件保存系統已完成資安修補，即日起恢復外網直接存取服務',
      summary: '115年10月29日起恢復郵件保存系統之外網直接存取服務，系統環境更新修補與資安防禦測試，經評估確認系統運作安全無虞。',
      contentHtml: r'''<p>敬致全校教職員工生：</p>

<p><strong>一、 事由說明：</strong>先前因應 PHP 高危險安全漏洞（CVE-2026-109618、CVE-2026-109619），郵件保存系統已完成系統環境更新修補與資安防禦測試，經評估確認系統運作安全無虞。</p>

<p><strong>二、 服務調整：</strong>115年10月29日起恢復郵件保存系統之外網直接存取服務。 教職員生於校外使用郵件保存系統時，已無需先登入校內 VPN，即可直接連線使用。</p>

<p><strong>三、 注意事項：</strong>若您於外網連線時遇到網頁無法正常開啟或顯示舊頁面之情形，請先嘗試清除瀏覽器快取（Cache）或使用無痕模式重新開啟網頁。</p>

<p>&nbsp;</p>
''',
      attachments: [],
      contact: '計算機與網路中心/陳家苹/分機 #3223\nEmail: juicychen@ntut.edu.tw',
    ),
    '109661793152625': (
      id: '109661793152625',
      category: '重要通知',
      title: '【無線網路平台系統】預定於115年11⽉3⽇(二)10:00~17:00進行停機維護作業',
      summary: '網路組預定於115年11⽉3⽇(二)10:00~17:00無線網路平台系統進⾏多項無線網路設備維護作業。',
      contentHtml: r'''<p>網路組預定於115年11⽉3⽇(二)10:00~17:00無線網路平台系統進⾏無線控制器設備、無線NAT設備、無線頻寛管理設備及無線訪客系統主機之韌體升級更新作業。全校有線網路不影響使⽤，無線網路會不定時中斷，屆時若作業順利提早完成，將立即提供服務，如提早或延後將不再另⾏公告，造成不便敬請⾒諒。</p>

<p><strong>服務影響範圍：<br>
一、</strong>維護時間：115年11⽉3⽇(二)上午十點⾄下午五點整<br>
<strong>二、</strong>影響範圍：全校無線網路暫時無法上網使用</p>

<p>聯絡資訊：計網中⼼網路組 陳秋敏 分機：3228</p>
''',
      attachments: [],
      contact: '計算機與網路中心/陳秋敏/分機 #3228\nEmail: charming@ntut.edu.tw',
    ),
    '121641793174214': (
      id: '121641793174214',
      category: '活動訊息',
      title: '光華館二樓享聚餐廳為慶祝115年校慶，115年10月28日至11月2日期間熱炒特價7折，歡迎蒞臨用餐',
      summary: '光華館二樓享聚餐廳115年10月28日至11月2日期間熱炒特價7折，歡迎蒞臨用餐',
      contentHtml:
          r'''<p>光華館二樓享聚餐廳為慶祝115年校慶，115年10月28日至11月2日期間熱炒特價7折(不含辦桌、套餐、飲料、麵飯類)</p>

<p>優惠期間：115年10月28日至11月2日</p>

<p>活動優惠如有疑義，請以現場說明為準</p>

<p>如有訂餐問題，請洽詢享聚餐廳邱先生0958568608</p>
''',
      attachments: [
        (
          name: '附件1',
          url: Uri.parse(
            'https://postman.ntut.edu.tw/CI/showmsg/file?f=f8c9687ce2e759035f07d45cb2f9ef56.jpg',
          ),
        ),
        (
          name: '附件2',
          url: Uri.parse(
            'https://postman.ntut.edu.tw/CI/showmsg/file?f=bc4ee78a8cb1ed6101068d0f28c980cc.pdf',
          ),
        ),
      ],
      contact: '總務處/陳智斌/分機 #1343\nEmail: bingo328@ntut.edu.tw',
    ),
  };

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
    final detail = _details[id];
    if (detail == null) {
      throw const FormatException('Postman announcement details are missing');
    }
    return detail;
  }
}
