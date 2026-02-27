const calendarId = 'docfuhim9b22fqvp2tk842ak3c@group.calendar.google.com';
const calendarTimeZone = 'Asia/Taipei';

Uri buildCalendarPublicIcsUri(String id) {
    return Uri.https(
        'calendar.google.com',
        '/calendar/ical/$id/public/basic.ics',
    );
}

Uri buildCalendarEmbedUri(String id, {String timeZone = calendarTimeZone}) {
    return Uri.https('calendar.google.com', '/calendar/embed', {
        'src': id,
        'ctz': timeZone,
    });
}

String get calendarPublicIcsUrl => buildCalendarPublicIcsUri(calendarId).toString();
String get calendarEmbedUrl => buildCalendarEmbedUri(calendarId).toString();
