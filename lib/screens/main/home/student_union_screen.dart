import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/screens/main/home/link_set_screen.dart';

class StudentUnionScreen extends StatelessWidget {
  const StudentUnionScreen({super.key});

  @override
  Widget build(BuildContext context) => LinkSetScreen(
    logo: SvgPicture.asset('assets/student_union_simple.svg'),
    title: t.$wip('學生會專區'),
    description: t.$wip('學生權益相關連結'),
    links: [
      (
        id: 'campus_affairs_feedback',
        title: t.$wip('校園事務轉達單'),
        icon: null,
        url: 'https://docs.google.com/forms/d/e/1FAIpQLSee6Vp1wFUWUzZEs-ov1ZtSacQdJ97BC2LF3EOhQr5mPhiBeA/viewform',
      ),
      (
        id: 'student_rights_case_tracker',
        title: t.$wip('學權部案件追蹤系統'),
        icon: null,
        url: 'https://script.google.com/macros/s/AKfycbznygYbYThagK-qaBHgItduEiDU8MijkQDlPeMmUbexBAIF27YTaDTDCNUvkO_-_ddrQA/exec',
      ),
      (
        id: 'student_council_meeting_documents',
        title: t.$wip('學生議會會議文件'),
        icon: null,
        url: null,
      ),
      (
        id: 'upcoming_school_policies',
        title: t.$wip('學校預計推出政策'),
        icon: null,
        url: null,
      ),
    ],
  );
}
