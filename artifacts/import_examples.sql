-- Function to import examples from JSON
CREATE OR REPLACE FUNCTION import_htmx_example(example_json JSONB)
RETURNS VOID AS $$
BEGIN
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
        example_json->>'id',
        example_json->>'title',
        example_json->>'category',
        example_json->>'url',
        example_json->>'description',
        example_json->'html_snippets',
        example_json->'javascript_snippets',
        (SELECT array_agg(jsonb_array_elements_text(example_json->'key_concepts'))),
        (SELECT array_agg(jsonb_array_elements_text(example_json->'htmx_attributes'))),
        example_json->>'demo_explanation',
        example_json->>'complexity_level',
        (SELECT array_agg(jsonb_array_elements_text(example_json->'use_cases')))
    )
    ON CONFLICT (id) DO UPDATE SET
        title = EXCLUDED.title,
        category = EXCLUDED.category,
        url = EXCLUDED.url,
        description = EXCLUDED.description,
        html_snippets = EXCLUDED.html_snippets,
        javascript_snippets = EXCLUDED.javascript_snippets,
        key_concepts = EXCLUDED.key_concepts,
        htmx_attributes = EXCLUDED.htmx_attributes,
        demo_explanation = EXCLUDED.demo_explanation,
        complexity_level = EXCLUDED.complexity_level,
        use_cases = EXCLUDED.use_cases,
        updated_at = CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;
