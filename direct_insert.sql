-- Insert directly without using the function
INSERT INTO htmx_examples (
    id,
    title,
    category,
    url,
    description,
    html_snippets,
    javascript_snippets,
    key_concepts,
    htmx_attributes,
    demo_explanation,
    complexity_level,
    use_cases
) VALUES (
    'click-to-edit',
    'Click to Edit',
    'UI Patterns',
    'https://htmx.org/examples/click-to-edit/',
    'The click to edit pattern provides a way to offer inline editing of all or part of a record without a page refresh.',
    '[{"code":"<div hx-target=\"this\" hx-swap=\"outerHTML\">\n    <div><label>First Name</label>: Joe</div>\n    <div><label>Last Name</label>: Blow</div>\n    <div><label>Email</label>: joe@blow.com</div>\n    <button hx-get=\"/contact/1/edit\" class=\"btn primary\">\n    Click To Edit\n    </button>\n</div>","description":"This snippet displays the contact details (first name, last name, and email) and includes a button that, when clicked, will fetch the editing UI for the contact."},{"code":"<form hx-put=\"/contact/1\" hx-target=\"this\" hx-swap=\"outerHTML\">\n  <div>\n    <label>First Name</label>\n    <input type=\"text\" name=\"firstName\" value=\"Joe\">\n  </div>\n  <div class=\"form-group\">\n    <label>Last Name</label>\n    <input type=\"text\" name=\"lastName\" value=\"Blow\">\n  </div>\n  <div class=\"form-group\">\n    <label>Email Address</label>\n    <input type=\"email\" name=\"email\" value=\"joe@blow.com\">\n  </div>\n  <button class=\"btn\">Submit</button>\n  <button class=\"btn\" hx-get=\"/contact/1\">Cancel</button>\n</form>","description":"This snippet represents the editing form that appears when the ''Click To Edit'' button is pressed. It allows users to update contact information and submit via a PUT request."}]',
    '[]',
    ARRAY['AJAX requests', 'Dynamic content loading', 'Inline editing', 'Form submission without page refresh'],
    ARRAY['hx-get', 'hx-put', 'hx-target', 'hx-swap'],
    'The demo allows users to click on a button to edit contact information directly on the page without needing to refresh. It uses HTMX attributes to fetch the edit form and update the content dynamically.',
    'beginner',
    ARRAY['Inline editing of user profiles', 'Dynamic form generation', 'Content management systems', 'Real-time data updates without page refreshes']
);
