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

4. Read the commented metadata block at the top of the fetched HTML/XML. Ignore any TODO about future HTML-based test expectations; that TODO may stay until the test code exists. Require only the `message` field to contain a meaningful short English reason that describes the sample's distinctive state. If the message has usable content, rewrite it into concise English and fix grammar, spelling, or Chinese wording. Ask the user what special state this snapshot represents only when the message has no usable information, then summarize the answer into the metadata `message`. Only write a usual-page message, such as `This is a usual graduation check page.`, when the user explicitly says the snapshot is a normal case.

## De-identify

- Review the whole file, including metadata, `request_url`, hidden inputs, scripts, comments, links, and visible text.
- Replace each sensitive value consistently across the entire file with search-and-replace tooling.
- Remove or replace names, student IDs, accounts, emails, phone numbers, ID numbers, birth dates, addresses, avatar/file names, classmates, grades, rankings, course-private materials, and personal academic records.
- Prefer realistic fake values from `lib/services/*/mock_*.dart`, including course names, course numbers, teacher names, student names, and IDs. Do not use placeholder-like fake data such as `Course ABCD`, `Teacher A`, `Test Department`, or sequential dummy names.
- If no mock value fits, synthesize realistic format-preserving fake values: invent plausible departments, teacher names, course names, and IDs that match the original style.
- Replace department/program names only when they are not part of the page's meaningful scenario. Keep them when department-specific differences may affect the snapshot, such as course-table pages. Replace them on generic personal-profile pages.
- For course-table snapshots, replace course names, course numbers, and teacher names unless the user asks otherwise. Preserve credits, class times, classrooms, periods, hours, department/program context, and other course metadata. Keep the teacher count unchanged.

## Preserve

- Preserve DOM structure, table columns, element attributes, CSS selectors, form shape, parser anchors, status text, and error messages.
- Preserve non-personal test metadata such as classrooms, periods, credits, hours, teacher count, semester markers, and system-state wording.
- Do not prettify, reformat, translate, or rewrite unrelated HTML.

## Promote

1. Remove only the raw-capture warning line from the metadata header.
2. Keep de-identified `preset`, `request_url`, `fetchtime`, and the meaningful English `message`.
3. Move the sanitized file to:

   ```text
   test/fixtures/<service>/<query_item>_<serial>_<short_message>.html
   ```

   Use the queried item/page name for `<query_item>`, a three-digit serial such as `001`, and a very short English `<short_message>` of a few words. Choose the serial by checking the target `<service>` folder for existing files with the same `<query_item>_` prefix, then use the next number. Use `usual` only when the user explicitly says the snapshot is a normal case. Example: `test/fixtures/student_query/graduation_check_001_graduate_eligible.html`.
4. Re-scan the promoted file for sensitive data before staging. Do not stage raw files from `tmp/html_snapshot/`.
5. After promotion is complete, the only allowed closing question is whether to delete the just-processed raw source file in `tmp/html_snapshot/`. Do not ask about or suggest anything else. Do not delete the original file without explicit user authorization. Never delete the raw file unless the user explicitly confirms deletion, and never delete the whole `tmp/html_snapshot/` folder.
