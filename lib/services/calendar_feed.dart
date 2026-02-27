/// Google Calendar ID used by the app calendar feature.
const calendarId = 'docfuhim9b22fqvp2tk842ak3c@group.calendar.google.com';

/// Default timezone passed to Google Calendar embed URL.
const calendarTimeZone = 'Asia/Taipei';

/// Builds a public ICS URI from a Google Calendar ID.
Uri buildCalendarPublicIcsUri(String id) {
  return Uri.https(
    'calendar.google.com',
    '/calendar/ical/$id/public/basic.ics',
  );
}

/// Builds a Google Calendar embed URI from a calendar ID and timezone.
Uri buildCalendarEmbedUri(String id, {String timeZone = calendarTimeZone}) {
  return Uri.https('calendar.google.com', '/calendar/embed', {
    'src': id,
    'ctz': timeZone,
  });
}

/// Public ICS URL for [calendarId].
String get calendarPublicIcsUrl =>
    buildCalendarPublicIcsUri(calendarId).toString();

/// Embed URL for [calendarId] with [calendarTimeZone].
String get calendarEmbedUrl => buildCalendarEmbedUri(calendarId).toString();
