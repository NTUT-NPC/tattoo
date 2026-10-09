import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/preferences_repository.dart';
import 'package:tattoo/screens/main/home/link_set_screen.dart';
import 'package:tattoo/screens/main/profile/preference_providers.dart';
import 'package:tattoo/utils/link_url_overrides.dart';

class StudentUnionScreen extends ConsumerWidget {
  const StudentUnionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => LinkSetScreen(
    logo: SvgPicture.asset('assets/student_union_simple.svg'),
    title: t.studentUnion.title,
    description: t.studentUnion.description,
    links: [
      (
        id: 'campus_affairs_feedback',
        title: t.studentUnion.campusAffairsFeedback,
        icon: null,
        url: 'https://docs.google.com/forms/d/e/1FAIpQLSee6Vp1wFUWUzZEs-ov1ZtSacQdJ97BC2LF3EOhQr5mPhiBeA/viewform',
      ),
      (
        id: 'student_rights_case_tracker',
        title: t.studentUnion.studentRightsCaseTracker,
        icon: null,
        url: 'https://script.google.com/macros/s/AKfycbznygYbYThagK-qaBHgItduEiDU8MijkQDlPeMmUbexBAIF27YTaDTDCNUvkO_-_ddrQA/exec',
      ),
      (
        id: 'student_council_meeting_documents',
        title: t.studentUnion.studentCouncilMeetingDocuments,
        icon: null,
        url: null,
      ),
      (
        id: 'upcoming_school_policies',
        title: t.studentUnion.upcomingSchoolPolicies,
        icon: null,
        url: null,
      ),
    ],
    urlOverrides: parseLinkUrlOverrides(
      ref.pref(PrefKey.studentUnionLinks),
    ),
  );
}
