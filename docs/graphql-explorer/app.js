const STORAGE_KEY = "bo-nomenclature-graphql-explorer";

const examples = {
  domains: {
    title: "Domains collection",
    referenceTitle: "domainsCollection",
    kind: "Query",
    overview:
      "Lists the current domain tree exposed through the live Supabase pg_graphql schema. This is the quickest way to verify the loaded Disney destination hierarchy.",
    arguments: [
      { name: "first", type: "Int", description: "Limits the result set to the first 10 domain rows." },
      { name: "orderBy", type: "[domainsOrderBy!]", description: "Sorts by created_at ascending so the root domain appears first." }
    ],
    returns: [
      { name: "edges.node.id", type: "UUID", description: "Stable domain identifier." },
      { name: "edges.node.name", type: "String", description: "Display name for the domain." },
      { name: "edges.node.domain_type", type: "String", description: "Brand, category, or destination classification." }
    ],
    notes: [
      "Uses the real live GraphQL collection shape returned by pg_graphql.",
      "Works best with the service-role key because anon access is constrained by RLS."
    ],
    sampleResponse: {
      data: {
        domainsCollection: {
          edges: [
            {
              node: {
                id: "72000000-0000-0000-0000-000000000001",
                name: "Disney Destinations",
                slug: "disney-destinations",
                status: "active",
                parent_id: null,
                domain_type: "brand"
              }
            },
            {
              node: {
                id: "72000000-0000-0000-0000-000000000002",
                name: "Disney Characters",
                slug: "disney-characters",
                status: "active",
                parent_id: "72000000-0000-0000-0000-000000000001",
                domain_type: "category"
              }
            },
            {
              node: {
                id: "72000000-0000-0000-0000-000000000003",
                name: "Disneyland Paris",
                slug: "disneyland-paris",
                status: "active",
                parent_id: "72000000-0000-0000-0000-000000000001",
                domain_type: "destination"
              }
            },
            {
              node: {
                id: "72000000-0000-0000-0000-000000000004",
                name: "Walt Disney World Resort",
                slug: "walt-disney-world-resort",
                status: "active",
                parent_id: "72000000-0000-0000-0000-000000000001",
                domain_type: "destination"
              }
            },
            {
              node: {
                id: "72000000-0000-0000-0000-000000000005",
                name: "Disney Cruise Line",
                slug: "disney-cruise-line",
                status: "active",
                parent_id: "72000000-0000-0000-0000-000000000001",
                domain_type: "destination"
              }
            }
          ]
        }
      }
    },
    query: `query GetDomains {
  domainsCollection(first: 10, orderBy: [{created_at: AscNullsLast}]) {
    edges {
      node {
        id
        name
        slug
        domain_type
        status
        parent_id
      }
    }
  }
}`,
    variables: {}
  },
  hotelTerm: {
    title: "Imported hotel term",
    referenceTitle: "termsCollection → Disney Hotel New York – The Art of Marvel",
    kind: "Query",
    overview:
      "Fetches a single imported Disneyland Paris hotel term with nested approved variants and approval events, similar to a typed reference page for one concrete object.",
    arguments: [
      { name: "$termId", type: "UUID!", description: "Filters the collection to the imported hotel term." },
      { name: "$variantLimit", type: "Int!", description: "Loads a bounded set of associated variants." },
      { name: "$approvalLimit", type: "Int!", description: "Loads a bounded set of approval records." }
    ],
    returns: [
      { name: "canonical_text", type: "String", description: "Governed term text." },
      { name: "source_reference", type: "String", description: "PDF provenance for the imported record." },
      { name: "variantsCollection.edges.node", type: "Variant row", description: "Nested approved or prohibited variants." },
      { name: "approvalsCollection.edges.node", type: "Approval row", description: "Destination-scoped approval state." }
    ],
    notes: [
      "This mirrors the most useful part of a type page: one object plus its nested edges.",
      "Good sanity check after dataset imports."
    ],
    sampleResponse: {
      data: {
        termsCollection: {
          edges: [
            {
              node: {
                id: "12b8e98b-7593-5b51-b8cc-3c9084cbcb32",
                category: "hotels",
                canonical_text: "Disney Hotel New York – The Art of Marvel",
                source_reference: "BrandBook_2026_UKI.pdf#page=46",
                variantsCollection: {
                  edges: [
                    {
                      node: {
                        locale_code: "en-GB",
                        variant_text: "Disney Hotel New York – The Art of Marvel",
                        variant_type: "approved"
                      }
                    }
                  ]
                },
                approvalsCollection: {
                  edges: [
                    {
                      node: {
                        status: "approved",
                        comment: "Imported from BrandBook_2026_UKI.pdf",
                        destination_code: "disneyland_paris"
                      }
                    }
                  ]
                }
              }
            }
          ]
        }
      }
    },
    query: `query GetDisneyHotelTerm($termId: UUID!, $variantLimit: Int!, $approvalLimit: Int!) {
  termsCollection(
    first: 1
    filter: {id: {eq: $termId}}
  ) {
    edges {
      node {
        id
        canonical_text
        category
        source_reference
        variantsCollection(first: $variantLimit) {
          edges {
            node {
              variant_text
              variant_type
              locale_code
            }
          }
        }
        approvalsCollection(first: $approvalLimit) {
          edges {
            node {
              destination_code
              status
              comment
            }
          }
        }
      }
    }
  }
}`,
    variables: {
      termId: "12b8e98b-7593-5b51-b8cc-3c9084cbcb32",
      variantLimit: 10,
      approvalLimit: 10
    }
  },
  wdwTerms: {
    title: "Walt Disney World sample terms",
    referenceTitle: "termsCollection",
    kind: "Query",
    overview:
      "Retrieves a small alphabetized slice of Walt Disney World Resort terms to inspect imported category coverage and naming quality.",
    arguments: [
      { name: "$domainId", type: "UUID!", description: "Scopes the query to the Walt Disney World Resort domain." },
      { name: "$limit", type: "Int!", description: "Limits the sample to a manageable slice." },
      { name: "orderBy", type: "[termsOrderBy!]", description: "Sorts by canonical_text ascending." }
    ],
    returns: [
      { name: "id", type: "UUID", description: "Stable term identifier." },
      { name: "canonical_text", type: "String", description: "Imported governed wording." },
      { name: "category", type: "String", description: "Term category from the dataset." }
    ],
    notes: [
      "Useful for quick browsing without loading the full collection.",
      "This example exposes any obvious import artifacts early."
    ],
    sampleResponse: {
      data: {
        termsCollection: {
          edges: [
            { node: { id: "45bc0667-2834-54a4-a18c-d465a5aa8b82", category: "dining", canonical_text: "‘Ohana" } },
            { node: { id: "8548a235-8d8c-59bc-8abd-732182938ba1", category: "parks_and_attractions", canonical_text: "“it’s a small world”" } },
            { node: { id: "9103026e-79df-5dd9-ac57-41e8a6baaf68", category: "dining", canonical_text: "1900 Park Fare" } },
            { node: { id: "95c508ee-547d-51b5-8cf4-31c161fb6398", category: "dining", canonical_text: "50’s Prime Time Café" } },
            { node: { id: "37f50c13-59ae-5f8a-8e0c-846f72a995b4", category: "dining", canonical_text: "A Buffet with Character at The Crystal Palace" } },
            { node: { id: "8342c60e-1fa0-57ee-983a-bc33191ef990", category: "parks_and_attractions", canonical_text: "A Pirate’s Adventure: Treasures of the Seven Seas" } },
            { node: { id: "7d948351-e639-5184-9224-23009c71ca0d", category: "dining", canonical_text: "ABC Commissary" } },
            { node: { id: "3fd27ce3-04c8-589a-9fdb-018fe2714a50", category: "parks_and_attractions", canonical_text: "Adventureland" } }
          ]
        }
      }
    },
    query: `query GetWDWSampleTerms($domainId: UUID!, $limit: Int!) {
  termsCollection(
    first: $limit
    filter: {domain_id: {eq: $domainId}}
    orderBy: [{canonical_text: AscNullsLast}]
  ) {
    edges {
      node {
        id
        canonical_text
        category
      }
    }
  }
}`,
    variables: {
      domainId: "72000000-0000-0000-0000-000000000004",
      limit: 8
    }
  },
  auditTrail: {
    title: "Audit trail",
    referenceTitle: "audit_entriesCollection",
    kind: "Query",
    overview:
      "Looks up immutable audit rows for a single imported term so you can verify create-time lineage and mutation traceability.",
    arguments: [
      { name: "$entityId", type: "UUID!", description: "Matches the imported hotel term ID in the audit feed." },
      { name: "orderBy", type: "[audit_entriesOrderBy!]", description: "Sorts by occurred_at descending." },
      { name: "$limit", type: "Int!", description: "Limits the result to the newest audit rows." }
    ],
    returns: [
      { name: "entity_type", type: "String", description: "Audited table or entity class." },
      { name: "action", type: "String", description: "create, update, or delete action." },
      { name: "occurred_at", type: "Datetime", description: "Timestamp of the audit event." }
    ],
    notes: [
      "A good operational check after refreshes or manual fixes.",
      "The underlying table is immutable application history, not a derived view."
    ],
    sampleResponse: {
      data: {
        audit_entriesCollection: {
          edges: [
            {
              node: {
                id: "91c5fa39-cbf5-4597-ac2f-a802457885b3",
                action: "create",
                entity_id: "12b8e98b-7593-5b51-b8cc-3c9084cbcb32",
                entity_type: "terms",
                occurred_at: "2026-07-18T16:52:25.486745+00:00"
              }
            }
          ]
        }
      }
    },
    query: `query GetAuditEntriesForHotelTerm($entityId: UUID!, $limit: Int!) {
  audit_entriesCollection(
    first: $limit
    filter: {entity_id: {eq: $entityId}}
    orderBy: [{occurred_at: DescNullsLast}]
  ) {
    edges {
      node {
        id
        entity_type
        entity_id
        action
        occurred_at
      }
    }
  }
}`,
    variables: {
      entityId: "12b8e98b-7593-5b51-b8cc-3c9084cbcb32",
      limit: 10
    }
  },
  approvalState: {
    title: "Approval state function",
    referenceTitle: "term_active_approval_state",
    kind: "Function",
    overview:
      "Calls the SQL helper exposed through GraphQL to resolve the current effective approval state for one term and destination.",
    arguments: [
      { name: "$termId", type: "UUID!", description: "The governed term being evaluated." },
      { name: "$destinationCode", type: "String!", description: "Destination scope for approval resolution." }
    ],
    returns: [
      { name: "term_active_approval_state", type: "String", description: "Derived state such as approved, revoked, or expired." }
    ],
    notes: [
      "This is the closest live GraphQL equivalent to an explicit approval-status endpoint.",
      "Useful for debugging approval behavior independently of the validation function."
    ],
    sampleResponse: {
      data: {
        term_active_approval_state: "approved"
      }
    },
    query: `query GetApprovalState($termId: UUID!, $destinationCode: String!) {
  term_active_approval_state(
    input_term_id: $termId
    input_destination_code: $destinationCode
  )
}`,
    variables: {
      termId: "12b8e98b-7593-5b51-b8cc-3c9084cbcb32",
      destinationCode: "disneyland_paris"
    }
  },
  introspection: {
    title: "Schema introspection",
    referenceTitle: "__schema",
    kind: "Introspection",
    overview:
      "Lists top-level query and mutation fields currently exposed by the live GraphQL endpoint, useful when the deployed schema differs from contract expectations.",
    arguments: [
      { name: "__schema.queryType.fields", type: "[__Field!]", description: "Enumerates top-level queries." },
      { name: "__schema.mutationType.fields", type: "[__Field!]", description: "Enumerates top-level mutations." }
    ],
    returns: [
      { name: "queryType.fields.name", type: "String", description: "Available top-level query field names." },
      { name: "mutationType.fields.name", type: "String", description: "Available top-level mutation field names." }
    ],
    notes: [
      "Helpful when the endpoint is native pg_graphql instead of a custom GraphQL resolver layer."
    ],
    sampleResponse: {
      data: {
        __schema: {
          queryType: {
            fields: [
              { name: "approvalsCollection" },
              { name: "audit_entriesCollection" },
              { name: "authorization_codesCollection" },
              { name: "client_infosCollection" },
              { name: "current_actor_id" },
              { name: "current_request_id" },
              { name: "current_request_reason" },
              { name: "current_user_can_manage_tenant" },
              { name: "current_user_can_write_tenant" },
              { name: "current_user_role_for_tenant" },
              { name: "domainsCollection" },
              { name: "examplesCollection" },
              { name: "grantsCollection" },
              { name: "is_active_approval" },
              { name: "node" },
              { name: "rule_destinationsCollection" },
              { name: "rulesCollection" },
              { name: "stored_auth_requestsCollection" },
              { name: "tenant_membershipsCollection" },
              { name: "tenantsCollection" },
              { name: "term_active_approval_state" },
              { name: "termsCollection" },
              { name: "token_dataCollection" },
              { name: "variant_destinationsCollection" },
              { name: "variantsCollection" }
            ]
          },
          mutationType: {
            fields: [
              { name: "deleteFromapprovalsCollection" },
              { name: "deleteFromaudit_entriesCollection" },
              { name: "deleteFromauthorization_codesCollection" },
              { name: "deleteFromclient_infosCollection" },
              { name: "deleteFromdomainsCollection" },
              { name: "deleteFromexamplesCollection" },
              { name: "deleteFromgrantsCollection" },
              { name: "deleteFromrule_destinationsCollection" },
              { name: "deleteFromrulesCollection" },
              { name: "deleteFromstored_auth_requestsCollection" },
              { name: "deleteFromtenant_membershipsCollection" },
              { name: "deleteFromtenantsCollection" },
              { name: "deleteFromtermsCollection" },
              { name: "deleteFromtoken_dataCollection" },
              { name: "deleteFromvariant_destinationsCollection" },
              { name: "deleteFromvariantsCollection" },
              { name: "insertIntoapprovalsCollection" },
              { name: "insertIntoaudit_entriesCollection" },
              { name: "insertIntoauthorization_codesCollection" },
              { name: "insertIntoclient_infosCollection" },
              { name: "insertIntodomainsCollection" },
              { name: "insertIntoexamplesCollection" },
              { name: "insertIntograntsCollection" },
              { name: "insertIntorule_destinationsCollection" },
              { name: "insertIntorulesCollection" },
              { name: "insertIntostored_auth_requestsCollection" },
              { name: "insertIntotenant_membershipsCollection" },
              { name: "insertIntotenantsCollection" },
              { name: "insertIntotermsCollection" },
              { name: "insertIntotoken_dataCollection" },
              { name: "insertIntovariant_destinationsCollection" },
              { name: "insertIntovariantsCollection" },
              { name: "record_term_approval" },
              { name: "refresh_term_approval_state" },
              { name: "updateapprovalsCollection" },
              { name: "updateaudit_entriesCollection" },
              { name: "updateauthorization_codesCollection" },
              { name: "updateclient_infosCollection" },
              { name: "updatedomainsCollection" },
              { name: "updateexamplesCollection" },
              { name: "updategrantsCollection" },
              { name: "updaterule_destinationsCollection" },
              { name: "updaterulesCollection" },
              { name: "updatestored_auth_requestsCollection" },
              { name: "updatetenant_membershipsCollection" },
              { name: "updatetenantsCollection" },
              { name: "updatetermsCollection" },
              { name: "updatetoken_dataCollection" },
              { name: "updatevariant_destinationsCollection" },
              { name: "updatevariantsCollection" },
              { name: "validate_approval_event" }
            ]
          }
        }
      }
    },
    query: `query IntrospectionOverview {
  __schema {
    queryType {
      fields {
        name
      }
    }
    mutationType {
      fields {
        name
      }
    }
  }
}`,
    variables: {}
  }
};

const endpointInput = document.getElementById("endpoint");
const apiKeyInput = document.getElementById("apiKey");
const bearerTokenInput = document.getElementById("bearerToken");
const queryEditor = document.getElementById("queryEditor");
const variablesEditor = document.getElementById("variablesEditor");
const responseViewer = document.getElementById("responseViewer");
const responseMeta = document.getElementById("responseMeta");
const requestViewer = document.getElementById("requestViewer");
const statusBadge = document.getElementById("statusBadge");
const titleNode = document.getElementById("activeExampleTitle");
const referenceTitleNode = document.getElementById("referenceTitle");
const referenceKindNode = document.getElementById("referenceKind");
const referenceOverviewNode = document.getElementById("referenceOverview");
const referenceArgumentsNode = document.getElementById("referenceArguments");
const referenceReturnsNode = document.getElementById("referenceReturns");
const referenceNotesNode = document.getElementById("referenceNotes");

const exampleButtons = [...document.querySelectorAll(".example-item")];

let activeExample = "domains";

function setStatus(kind, label) {
  statusBadge.className = `status-badge ${kind}`;
  statusBadge.textContent = label;
}

function renderRequestPreview() {
  let variables = {};
  try {
    variables = JSON.parse(variablesEditor.value || "{}");
  } catch {
    variables = "__invalid_json__";
  }

  requestViewer.textContent = JSON.stringify(
    {
      query: queryEditor.value,
      variables
    },
    null,
    2
  );
}

function applyExample(name) {
  const example = examples[name];
  if (!example) return;

  activeExample = name;
  titleNode.textContent = example.title;
  referenceTitleNode.textContent = example.referenceTitle || example.title;
  referenceKindNode.textContent = example.kind || "Query";
  referenceOverviewNode.textContent = example.overview || "";
  renderFieldList(referenceArgumentsNode, example.arguments || []);
  renderFieldList(referenceReturnsNode, example.returns || []);
  renderNotes(example.notes || []);
  queryEditor.value = example.query;
  variablesEditor.value = JSON.stringify(example.variables, null, 2);
  renderRequestPreview();
  if (example.sampleResponse) {
    responseViewer.textContent = JSON.stringify(example.sampleResponse, null, 2);
    responseMeta.textContent = "Showing a captured live sample from July 18, 2026. Run Query fetches fresh data.";
    setStatus("success", "Sample");
  } else {
    responseViewer.textContent = "Run a query to see the response.";
    responseMeta.textContent = "Run Query fetches a live response from the configured endpoint.";
    setStatus("idle", "Idle");
  }

  exampleButtons.forEach((button) => {
    button.classList.toggle("is-active", button.dataset.example === name);
  });
}

function renderFieldList(container, items) {
  container.innerHTML = "";
  if (items.length === 0) {
    container.innerHTML = '<p class="field-item-copy">No fields documented for this example.</p>';
    return;
  }

  for (const item of items) {
    const wrapper = document.createElement("div");
    wrapper.className = "field-item";

    const name = document.createElement("div");
    name.className = "field-item-name";
    name.textContent = item.name;

    const type = document.createElement("div");
    type.className = "field-item-type";
    type.textContent = item.type;

    const copy = document.createElement("p");
    copy.className = "field-item-copy";
    copy.textContent = item.description;

    wrapper.append(name, type, copy);
    container.appendChild(wrapper);
  }
}

function renderNotes(items) {
  referenceNotesNode.innerHTML = "";
  for (const item of items) {
    const li = document.createElement("li");
    li.textContent = item;
    referenceNotesNode.appendChild(li);
  }
}

function saveConnection() {
  const payload = {
    endpoint: endpointInput.value,
    apiKey: apiKeyInput.value,
    bearerToken: bearerTokenInput.value
  };

  localStorage.setItem(STORAGE_KEY, JSON.stringify(payload));
  setStatus("success", "Saved");
  setTimeout(() => setStatus("idle", "Idle"), 1000);
}

function loadConnection() {
  const raw = localStorage.getItem(STORAGE_KEY);
  if (!raw) return;
  try {
    const payload = JSON.parse(raw);
    endpointInput.value = payload.endpoint || endpointInput.value;
    apiKeyInput.value = payload.apiKey || "";
    bearerTokenInput.value = payload.bearerToken || "";
  } catch {
    localStorage.removeItem(STORAGE_KEY);
  }
}

async function runQuery() {
  let variables = {};
  try {
    variables = JSON.parse(variablesEditor.value || "{}");
  } catch (error) {
    setStatus("error", "Bad JSON");
    responseViewer.textContent = `Variables must be valid JSON.\n\n${String(error)}`;
    return;
  }

  const apiKey = apiKeyInput.value.trim();
  const bearerToken = (bearerTokenInput.value.trim() || apiKey).trim();

  if (!endpointInput.value.trim() || !apiKey) {
    setStatus("error", "Missing Auth");
    responseViewer.textContent = "Endpoint and API key are required.";
    return;
  }

  const payload = {
    query: queryEditor.value,
    variables
  };

  renderRequestPreview();
  setStatus("running", "Running");
  responseViewer.textContent = "Request in flight…";

  try {
    const response = await fetch(endpointInput.value.trim(), {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: apiKey,
        Authorization: `Bearer ${bearerToken}`
      },
      body: JSON.stringify(payload)
    });

    const text = await response.text();
    let body;
    try {
      body = JSON.parse(text);
    } catch {
      body = text;
    }

    responseViewer.textContent = typeof body === "string" ? body : JSON.stringify(body, null, 2);
    responseMeta.textContent = `Live response received on ${new Date().toLocaleString()}.`;
    setStatus(response.ok ? "success" : "error", response.ok ? "Success" : `HTTP ${response.status}`);
  } catch (error) {
    responseViewer.textContent = String(error);
    responseMeta.textContent = "Live request failed. Check endpoint, key, and network access.";
    setStatus("error", "Network");
  }
}

function copyText(value) {
  navigator.clipboard.writeText(value).catch(() => {});
}

document.getElementById("runQuery").addEventListener("click", runQuery);
document.getElementById("saveConnection").addEventListener("click", saveConnection);
document.getElementById("copyQuery").addEventListener("click", () => copyText(queryEditor.value));
document.getElementById("copyResponse").addEventListener("click", () => copyText(responseViewer.textContent));
document.getElementById("formatVariables").addEventListener("click", () => {
  try {
    const value = JSON.parse(variablesEditor.value || "{}");
    variablesEditor.value = JSON.stringify(value, null, 2);
    renderRequestPreview();
  } catch (error) {
    setStatus("error", "Bad JSON");
    responseViewer.textContent = `Variables must be valid JSON.\n\n${String(error)}`;
  }
});
document.getElementById("loadIntrospection").addEventListener("click", () => applyExample("introspection"));

queryEditor.addEventListener("input", renderRequestPreview);
variablesEditor.addEventListener("input", renderRequestPreview);

exampleButtons.forEach((button) => {
  button.addEventListener("click", () => applyExample(button.dataset.example));
});

loadConnection();
applyExample(activeExample);
