-- Import click-to-edit example
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
    'active-search',
    'Active Search',
    'Search',
    'https://htmx.org/examples/active-search/',
    'This example actively searches a contacts database as the user enters text.',
    '[{"code":"<h3>\n  Search Contacts\n  <span class=\"htmx-indicator\">\n    <img src=\"/img/bars.svg\"/> Searching...\n   </span>\n</h3>\n<input class=\"form-control\" type=\"search\"\n       name=\"search\" placeholder=\"Begin Typing To Search Users...\"\n       hx-post=\"/search\"\n       hx-trigger=\"input changed delay:500ms, keyup[key==''Enter''], load\"\n       hx-target=\"#search-results\"\n       hx-indicator=\".htmx-indicator\">\n\n<table class=\"table\">\n    <thead>\n    <tr>\n      <th>First Name</th>\n      <th>Last Name</th>\n      <th>Email</th>\n    </tr>\n    </thead>\n    <tbody id=\"search-results\">\n    </tbody>\n</table>","description":"This snippet creates the UI for the search functionality, including a header, an input field for searching, and a table to display search results."}]',
    '[]',
    ARRAY['AJAX', 'Dynamic Content Loading', 'Input Handling', 'Event Triggers', 'Debouncing Input'],
    ARRAY['hx-post', 'hx-trigger', 'hx-target', 'hx-indicator'],
    'The active search example listens to user input in a search box, and triggers a POST request to the /search endpoint. Search results are displayed in a table as the user types, providing real-time feedback. The ht indicator shows a loading icon when the search is in progress, enhancing user experience.',
    'intermediate',
    ARRAY['Real-time search suggestions', 'Autocomplete features', 'Dynamic filtering of lists or tables', 'Improving user experience with instant feedback on searches']
);

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
    'infinite-scroll',
    'Infinite Scroll',
    'Scrolling Patterns',
    'https://htmx.org/examples/infinite-scroll/',
    'The infinite scroll pattern provides a way to load content dynamically on user scrolling action.',
    '[{"code":"<tr hx-get=\"/contacts/?page=2\"\nhx-trigger=\"revealed\"\nhx-swap=\"afterend\">\n  <td>Agent Smith</td>\n  <td>void29@null.org</td>\n  <td>55F49448C0</td>\n</tr>","explanation":"This table row element is set up to make an HTMX request to fetch the next page of contacts when it is revealed in the viewport. The new content will be appended right after this element when the request is resolved."}]',
    '[]',
    ARRAY['Dynamic content loading', 'User interaction with scroll events', 'Lazy loading of content'],
    ARRAY['hx-get', 'hx-trigger', 'hx-swap'],
    'The demo implements an infinite scroll functionality where the last element of the loaded content listens for the scroll event. When this element is brought into view, it triggers an HTMX request to fetch more data, appending the results to the DOM seamlessly.',
    'intermediate',
    ARRAY['Loading additional content in a feed (e.g., social media posts)', 'Displaying images in a gallery without pagination', 'Fetching more data in search results triggered by scrolling']
);

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
    'lazy-load',
    'Lazy Loading',
    'UI Patterns',
    'https://htmx.org/examples/lazy-load/',
    'The lazy loading pattern allows you to defer loading content until it is needed.',
    '[{"code":"<div hx-get=\"/graph\" hx-trigger=\"revealed\">
  <img class=\"htmx-indicator\" width=\"150\" src=\"/img/bars.svg\"/>
</div>","explanation":"This div element will trigger a GET request to /graph when it becomes visible in the viewport (revealed). While loading, it displays a loading indicator."}]',
    '[]',
    ARRAY['Lazy Loading', 'Performance Optimization', 'Progressive Enhancement'],
    ARRAY['hx-get', 'hx-trigger'],
    'The demo shows how content can be loaded only when it becomes visible to the user, improving initial page load performance. The revealed trigger fires when the element enters the viewport.',
    'beginner',
    ARRAY['Loading images only when they come into view', 'Deferring loading of below-the-fold content', 'Optimizing page load times for content-heavy pages']
);
