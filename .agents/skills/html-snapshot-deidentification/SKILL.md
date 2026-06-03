---
name: html-snapshot-deidentification
description: De-identify NTUT HTML/XML snapshots before promoting them from tmp/html_snapshot into test fixtures. Use when working with browser snapshots, raw campus-system captures, HTML parser samples, fixture promotion, or requests to remove personal data while preserving DOM structure for tests.
---

# HTML Snapshot De-identification

## Scope

Use this skill only to de-identify the selected snapshot and perform the required promotion steps. Do not propose unrelated code changes, tests, parser work, documentation updates, workflow improvements, or other recommendations unless the user explicitly asks for them. At the end, do not add follow-up suggestions or extra closing recommendations.

## Workflow

1. Inspect `tmp/html_snapshot/` for existing raw captures. If the user does not name specific files, process all files in that folder.
2. If no usable capture exists, ask which NTUT system/page to capture and why the sample matters.
3. Run `dart run tool/html_snapshot.dart list` and choose the closest preset. If needed, guide capture with:

   ```sh
   dart run tool/html_snapshot.dart capture <preset> -m "<short English reason>"
   ```

4. Resolve the metadata `message` before de-identifying:
   - Read the commented metadata block at the top of the fetched HTML/XML.
   - Ignore any TODO about future HTML-based test expectations; that TODO may stay until the test code exists.
   - Require only the `message` field to contain a meaningful short English reason that describes the sample's state.
   - If the message has usable content, rewrite it into concise English and fix grammar, spelling, or Chinese wording.
   - Treat the snapshot as usual only when the message itself says this is a standard, normal, common, typical, usual, regular, or general page, unless the message also describes an error, edge case, unusual state, or other abnormal condition.
   - If the message is empty, TODO-only, placeholder-only, or otherwise has no usable information, inspect the page body for obvious states such as blocking notices, required questionnaire warnings, empty results, errors, redirects, or login/session failures, then write a concise English message for that observed state.
   - If the state is not obvious after inspecting the page, ask the user what state this snapshot represents and summarize the answer into the metadata `message`.
   - Never turn a missing, empty, TODO-only, placeholder-only, or weak message into a usual-page message.
   - For confirmed usual pages, write a usual-page message, such as `This is a usual graduation check page.`

## De-identify

- Before editing, build a private replacement ledger of exact original sensitive values found in the whole file, including metadata, `request_url`, hidden fields, scripts, comments, and roster tables. Include variant forms such as URL-encoded IDs or repeated address fragments.
- Review the whole file, including metadata, `request_url`, hidden inputs, scripts, comments, links, and visible text.
- Replace each sensitive value consistently across the entire file with search-and-replace tooling.
- Prefer realistic fake values from `lib/services/*/mock_*.dart`, including course names, course numbers, teacher names, student names, and IDs. Do not use placeholder-like fake data such as `Course ABCD`, `Teacher A`, `Test Department`, or sequential dummy names.
- If no mock value fits, synthesize realistic format-preserving fake values: invent plausible departments, teacher names, course names, and IDs that match the original style.
- Replace department/program names only when they are not part of the page's meaningful scenario. Keep them when department-specific differences may affect the snapshot, such as course-table pages. Replace them on generic personal-profile pages.
- For course-table snapshots, replace course names, course numbers, and teacher names unless the user asks otherwise. Preserve credits, class times, classrooms, periods, hours, department/program context, and other course metadata. Keep the teacher count unchanged.

## Sensitive Data

Remove or replace these when present:

- Identity: names, English names, aliases, usernames, accounts, student IDs, roster IDs, national ID numbers, user/profile/internal person IDs, teacher/employee IDs.
- Contact and address: emails, phone numbers, postal codes, addresses, address fragments, household-registration fields, guardian/emergency-contact fields.
- Auth and hidden state: cookies, SSO/OAuth codes, session tickets, CSRF tokens, hidden auth fields, IDs embedded in URLs, query strings, forms, scripts, comments, or metadata.
- Academic private data: grades, GPA, rankings, graduation eligibility, missing credits, failed/retaken courses, academic warnings, enrollment status, registration history, conduct scores.
- Course-private data: classmates, rosters, attendance, assignment/exam links, material titles, material URLs/tokens, file IDs, avatar/file names.
- Administrative or sensitive status: tuition/payment records, scholarship/aid/refund status, dormitory, leave, discipline, counseling, disability accommodations, military-service records.

## Preserve

- Preserve DOM structure, table columns, element attributes, CSS selectors, form shape, parser anchors, status text, and error messages.
- Preserve non-personal test metadata such as classrooms, periods, credits, hours, teacher count, semester markers, and system-state wording.
- Do not prettify, reformat, translate, or rewrite unrelated HTML.
- After editing, search for every original sensitive value from the replacement ledger. If any remain, replace them and search again before promotion.

## Promote

1. Remove only the raw-capture warning line from the metadata header.
2. Keep de-identified `preset`, `request_url`, `fetchtime`, and the meaningful English `message`.
3. Move the sanitized file to:

   ```text
   test/fixtures/<service>/<query_item>_<serial>_<short_message>.html
   ```

   Derive `<service>` from the snapshot preset/request context and repo naming, checking `lib/services/` and existing `test/fixtures/` folders when needed. Do not invent abbreviations or alternate service folder names.

   Use the queried item/page name for `<query_item>`, a three-digit serial such as `001`, and a very short English `<short_message>` of a few words. Choose the serial by checking the target `<service>` folder for existing files with the same `<query_item>_` prefix, then use the next number. Use `usual` when the metadata message says this is a standard, normal, common, typical, usual, regular, or general page, unless it also describes an abnormal condition. Never infer `usual` from a missing or weak message. Example: `test/fixtures/student_query/graduation_check_001_graduate_eligible.html`.
4. Re-scan the promoted file for sensitive data and every ledger value before staging. Do not stage raw files from `tmp/html_snapshot/`.
5. Resolve raw source cleanup after promotion:
   - Always ask whether to delete the just-processed raw source file in `tmp/html_snapshot/` or leave it in place.
   - This is the only allowed closing question; do not ask about or suggest anything else.
   - Default to leaving the raw file untouched when the user does not answer or gives an unclear answer.
   - It is strictly forbidden to delete any raw source file without explicit user confirmation.
   - Never delete the whole `tmp/html_snapshot/` folder.
